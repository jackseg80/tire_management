-- ============================================================================
-- TeslaMate Tire Management System
-- Version 1.0.0 - November 2025
-- ============================================================================
-- Complete tire tracking system with performance analytics for TeslaMate
-- 
-- Features:
-- - Track unlimited tire sets (summer/winter)
-- - Automatic statistics calculation from TeslaMate drive data
-- - Energy consumption tracking (Wh/km)
-- - Driving efficiency monitoring
-- - Temperature correlation
-- - Historical comparison
-- ============================================================================

-- ============================================================================
-- IMPORTANT NOTES
-- ============================================================================
-- 
-- CONVERSION FACTOR: 162 (not 187.5)
-- This factor is calibrated for Tesla Model S 75D using TeslaMate's 
-- ideal_range_km values. The theoretical factor (75 kWh / 400 km = 187.5) 
-- doesn't match real-world data because TeslaMate uses EPA range estimates.
-- 
-- The factor 162 was derived from comparing with historical TeslaFi data:
-- - TeslaFi reference (Summer 2024): 152 Wh/km
-- - TeslaMate with 187.5: 176 Wh/km (15% too high)
-- - TeslaMate with 162: 152 Wh/km (perfect match!)
-- 
-- Calibration formula: 187.5 × (152/176) = 162
-- 
-- DISTANCE FILTER: >= 5 km
-- Short trips (< 5 km) are excluded from consumption calculations because:
-- - Battery preheating can use 400-1000 Wh/km on 1-2 km trips
-- - HVAC usage is disproportionately high
-- - These outliers skew average consumption significantly
-- 
-- ============================================================================

-- ============================================================================
-- Table: tire_models
-- ============================================================================
-- Stores tire model information (brand, model, size, type)
-- Separates tire specifications from tire set usage tracking
-- ============================================================================

CREATE TABLE IF NOT EXISTS tire_models (
    id SERIAL PRIMARY KEY,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(100) NOT NULL,
    size VARCHAR(30) NOT NULL,
    type VARCHAR(10) CHECK (type IN ('Summer', 'Winter', 'All-Season')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(brand, model, size)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_tire_models_type ON tire_models(type);

COMMENT ON TABLE tire_models IS 'Tire specifications and models catalog';
COMMENT ON COLUMN tire_models.type IS 'Tire type: Summer, Winter, or All-Season';

-- ============================================================================
-- Table: tire_sets
-- ============================================================================
-- Tracks each installation period of a tire set
-- Links to tire_models for specifications
-- ============================================================================

CREATE TABLE IF NOT EXISTS tire_sets (
    id SERIAL PRIMARY KEY,
    car_id INTEGER NOT NULL DEFAULT 1,
    name VARCHAR(50) NOT NULL,
    tire_model_id INTEGER REFERENCES tire_models(id),
    date_start DATE NOT NULL,
    date_end DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT tire_sets_car_id_fkey FOREIGN KEY (car_id) REFERENCES cars(id)
);

-- Create indexes for date range queries
CREATE INDEX IF NOT EXISTS idx_tire_sets_dates ON tire_sets(date_start, date_end);
CREATE INDEX IF NOT EXISTS idx_tire_sets_car_id ON tire_sets(car_id);

COMMENT ON TABLE tire_sets IS 'Tire installation periods and active usage tracking';
COMMENT ON COLUMN tire_sets.date_end IS 'NULL indicates currently active tire set';

-- ============================================================================
-- Table: tire_set_statistics
-- ============================================================================
-- Calculated statistics for each tire set
-- Automatically populated by update_current_tire_stats() function
-- ============================================================================

CREATE TABLE IF NOT EXISTS tire_set_statistics (
    id SERIAL PRIMARY KEY,
    tire_set_id INTEGER UNIQUE REFERENCES tire_sets(id) ON DELETE CASCADE,
    kilometers DECIMAL(10,2),
    consumption_wh_km DECIMAL(10,2),
    efficiency_percent DECIMAL(10,2),
    temperature_avg DECIMAL(10,2),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster joins
CREATE INDEX IF NOT EXISTS idx_tire_set_statistics_tire_set_id ON tire_set_statistics(tire_set_id);

COMMENT ON TABLE tire_set_statistics IS 'Calculated performance statistics per tire set';
COMMENT ON COLUMN tire_set_statistics.consumption_wh_km IS 'Average energy consumption in Wh/km using factor 162';
COMMENT ON COLUMN tire_set_statistics.efficiency_percent IS 'Driving efficiency: (distance / rated_range_used) × 100';

-- ============================================================================
-- View: tire_sets_with_stats
-- ============================================================================
-- Convenient view joining tire sets with their models and statistics
-- ============================================================================

CREATE OR REPLACE VIEW tire_sets_with_stats AS
SELECT 
    ts.id,
    ts.name,
    ts.car_id,
    ts.date_start,
    ts.date_end,
    tm.brand,
    tm.model AS tire_model,
    tm.size,
    tm.type,
    tss.kilometers,
    tss.consumption_wh_km,
    tss.efficiency_percent,
    tss.temperature_avg,
    tss.updated_at
FROM tire_sets ts
LEFT JOIN tire_models tm ON ts.tire_model_id = tm.id
LEFT JOIN tire_set_statistics tss ON ts.id = tss.tire_set_id;

COMMENT ON VIEW tire_sets_with_stats IS 'Complete tire information with statistics for dashboard queries';

-- ============================================================================
-- Function: update_current_tire_stats()
-- ============================================================================
-- Recalculates statistics for active tire sets (date_end = NULL)
-- Should be run after tire changes or periodically to refresh current data
--
-- Features:
-- - Automatically creates missing tire_set_statistics entries
-- - Uses factor 162 for consumption calculation
-- - Filters trips < 5 km to avoid outliers
-- - Calculates true weighted average (SUM/SUM not AVG)
-- - Computes driving efficiency from rated_range
--
-- Usage: SELECT update_current_tire_stats();
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_current_tire_stats()
RETURNS void
LANGUAGE plpgsql
AS $function$
BEGIN
    -- Step 1: Create missing entries for new tire sets
    INSERT INTO tire_set_statistics (tire_set_id, kilometers, consumption_wh_km, efficiency_percent, temperature_avg)
    SELECT ts.id, 0, NULL, NULL, 0
    FROM tire_sets ts
    WHERE ts.date_end IS NULL
      AND NOT EXISTS (SELECT 1 FROM tire_set_statistics tss WHERE tss.tire_set_id = ts.id)
    ON CONFLICT (tire_set_id) DO NOTHING;

    -- Step 2: Update statistics for active tire sets
    UPDATE tire_set_statistics tss
    SET
        -- Total kilometers driven (all trips > 1 km)
        kilometers = (
            SELECT COALESCE(SUM(d.distance), 0)
            FROM drives d
            JOIN tire_sets ts ON ts.id = tss.tire_set_id
            WHERE d.car_id = ts.car_id
              AND d.start_date >= ts.date_start
              AND (ts.date_end IS NULL OR d.start_date <= ts.date_end)
              AND d.distance > 1
        ),
        
        -- Average consumption in Wh/km using factor 162
        -- Only trips >= 5 km to avoid short trip outliers
        consumption_wh_km = (
            SELECT 
                CASE 
                    WHEN SUM(d.distance) > 0 
                    THEN SUM(d.start_ideal_range_km - d.end_ideal_range_km) * 162 / SUM(d.distance)
                    ELSE NULL
                END
            FROM drives d
            JOIN tire_sets ts ON ts.id = tss.tire_set_id
            WHERE d.car_id = ts.car_id
              AND d.start_date >= ts.date_start
              AND (ts.date_end IS NULL OR d.start_date <= ts.date_end)
              AND d.distance >= 5  -- Filter short trips
              AND d.start_ideal_range_km > d.end_ideal_range_km
        ),
        
        -- Average outside temperature
        temperature_avg = (
            SELECT AVG(d.outside_temp_avg)
            FROM drives d
            JOIN tire_sets ts ON ts.id = tss.tire_set_id
            WHERE d.car_id = ts.car_id
              AND d.start_date >= ts.date_start
              AND (ts.date_end IS NULL OR d.start_date <= ts.date_end)
              AND d.distance > 1
              AND d.outside_temp_avg IS NOT NULL
        ),
        
        -- Driving efficiency: (distance / rated_range_used) × 100
        -- Based on Grafana dashboard formula
        efficiency_percent = (
            SELECT 
                CASE 
                    WHEN SUM(d.start_rated_range_km - d.end_rated_range_km) > 0 
                    THEN (SUM(d.distance) / SUM(d.start_rated_range_km - d.end_rated_range_km)) * 100
                    ELSE NULL
                END
            FROM drives d
            JOIN tire_sets ts ON ts.id = tss.tire_set_id
            WHERE d.car_id = ts.car_id
              AND d.start_date >= ts.date_start
              AND (ts.date_end IS NULL OR d.start_date <= ts.date_end)
              AND d.distance >= 5
              AND d.start_rated_range_km > d.end_rated_range_km
        ),
        
        updated_at = CURRENT_TIMESTAMP
        
    WHERE tire_set_id IN (
        SELECT id FROM tire_sets WHERE date_end IS NULL
    );
END;
$function$;

COMMENT ON FUNCTION update_current_tire_stats() IS 'Updates statistics for active tire sets from TeslaMate drive data';

-- ============================================================================
-- Example Data
-- ============================================================================
-- Customize this section with your actual tire history
-- Remove the /* and */ to uncomment
-- ============================================================================

/*
-- Example: Add tire models
INSERT INTO tire_models (brand, model, size, type) VALUES
('Michelin', 'PilotSport 3', '245/45 R19 102V XL', 'Summer'),
('Goodyear', 'UltraGrip Performance+', '245/45 R19 102V XL', 'Winter'),
('Hankook', 'Ventus iOn S IK01', '245/45 R19 102V XL', 'Summer');

-- Example: Add tire sets history
INSERT INTO tire_sets (car_id, name, tire_model_id, date_start, date_end, notes) VALUES
(1, 'Summer 2022', 1, '2022-06-07', '2022-12-13', 'First summer set'),
(1, 'Winter 2022-2023', 2, '2022-12-13', '2023-06-07', 'Good winter performance'),
(1, 'Summer 2023', 1, '2023-06-07', '2023-11-17', 'Second season'),
(1, 'Winter 2023-2024', 2, '2023-11-17', '2024-06-05', 'Very cold winter'),
(1, 'Summer 2024', 3, '2024-06-05', '2024-11-08', 'Testing Hankook'),
(1, 'Winter 2024-2025', 2, '2024-11-08', '2025-04-12', 'Mild winter'),
(1, 'Summer 2025', 3, '2025-04-12', NULL, 'Currently active');

-- Calculate initial statistics
SELECT update_current_tire_stats();
*/

-- ============================================================================
-- Verification Queries
-- ============================================================================
-- After installation, verify everything works:
-- ============================================================================

-- Check tire models
-- SELECT * FROM tire_models ORDER BY type, brand;

-- Check tire sets with statistics
-- SELECT 
--     name,
--     type,
--     date_start,
--     date_end,
--     ROUND(kilometers, 0) as km,
--     ROUND(consumption_wh_km, 0) as wh_km,
--     ROUND(efficiency_percent, 1) as eff_pct,
--     ROUND(temperature_avg, 1) as temp_avg,
--     CASE WHEN date_end IS NULL THEN '🟢 Active' ELSE '⚪ Inactive' END as status
-- FROM tire_sets_with_stats
-- ORDER BY date_start DESC;

-- Check current tire set only
-- SELECT 
--     name as "Current Tire",
--     brand || ' ' || tire_model as "Model",
--     ROUND(kilometers, 0) as "Distance (km)",
--     ROUND(consumption_wh_km, 0) as "Consumption (Wh/km)",
--     ROUND(efficiency_percent, 1) as "Efficiency (%)",
--     ROUND(temperature_avg, 1) as "Avg Temp (°C)"
-- FROM tire_sets_with_stats
-- WHERE date_end IS NULL;

-- Compare summer vs winter performance
-- SELECT 
--     type as "Season",
--     COUNT(*) as "Sets",
--     ROUND(AVG(kilometers), 0) as "Avg Distance",
--     ROUND(AVG(consumption_wh_km), 0) as "Avg Consumption",
--     ROUND(AVG(efficiency_percent), 1) as "Avg Efficiency",
--     ROUND(AVG(temperature_avg), 1) as "Avg Temperature"
-- FROM tire_sets_with_stats
-- WHERE kilometers > 0
-- GROUP BY type
-- ORDER BY type;

-- ============================================================================
-- Maintenance Notes
-- ============================================================================
--
-- ADDING A NEW TIRE SET:
-- 1. Close current tire set:
--    UPDATE tire_sets SET date_end = CURRENT_DATE WHERE date_end IS NULL;
--
-- 2. Add new tire set:
--    INSERT INTO tire_sets (car_id, name, tire_model_id, date_start)
--    VALUES (1, 'Winter 2025-2026', 2, CURRENT_DATE);
--
-- 3. Update statistics:
--    SELECT update_current_tire_stats();
--
-- PERIODIC UPDATES:
-- Run this query daily or after significant driving:
--    SELECT update_current_tire_stats();
--
-- Or set up a cron job:
--    0 2 * * * docker exec teslamate-database-1 psql -U teslamate -d teslamate -c "SELECT update_current_tire_stats();"
--
-- BACKUP:
-- Regular backups recommended:
--    docker exec teslamate-database-1 pg_dump -U teslamate teslamate > backup.sql
--
-- ============================================================================
-- End of Script
-- ============================================================================
