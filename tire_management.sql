-- ============================================================================
-- TeslaMate Tire Management System
-- Database Schema and Functions
-- ============================================================================
-- This script creates the necessary tables and functions for tracking tire
-- performance in TeslaMate. It calculates statistics from drive data including
-- distance, energy consumption, efficiency, and temperature.
-- ============================================================================

-- Drop existing objects if they exist (optional - remove if you don't want to reset data)
-- DROP TABLE IF EXISTS tire_set_statistics CASCADE;
-- DROP TABLE IF EXISTS tire_sets CASCADE;
-- DROP FUNCTION IF EXISTS update_tire_statistics();

-- ============================================================================
-- Table: tire_sets
-- Stores information about each set of tires installed on the vehicle
-- ============================================================================
CREATE TABLE IF NOT EXISTS tire_sets (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    brand VARCHAR(100),
    model VARCHAR(100),
    size VARCHAR(50),
    start_date DATE NOT NULL,
    end_date DATE,
    tire_type VARCHAR(20) CHECK (tire_type IN ('summer', 'winter')),
    initial_odometer INTEGER,
    final_odometer INTEGER,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create index for date range queries
CREATE INDEX IF NOT EXISTS idx_tire_sets_dates ON tire_sets(start_date, end_date);

-- ============================================================================
-- Table: tire_set_statistics
-- Stores calculated statistics for each tire set
-- This table is automatically populated by the update_tire_statistics() function
-- ============================================================================
CREATE TABLE IF NOT EXISTS tire_set_statistics (
    id SERIAL PRIMARY KEY,
    tire_set_id INTEGER REFERENCES tire_sets(id) ON DELETE CASCADE,
    total_km DECIMAL(10,2),
    total_kwh DECIMAL(10,2),
    avg_consumption_whkm DECIMAL(10,2),
    avg_efficiency DECIMAL(10,2),
    avg_temp DECIMAL(10,2),
    avg_outside_temp DECIMAL(10,2),
    total_drives INTEGER,
    last_updated TIMESTAMP DEFAULT NOW(),
    UNIQUE(tire_set_id)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_tire_statistics_tire_set ON tire_set_statistics(tire_set_id);

-- ============================================================================
-- Function: update_tire_statistics()
-- Recalculates statistics for all tire sets based on TeslaMate drive data
-- ============================================================================
-- This function should be run:
-- - After adding new tire sets
-- - After updating tire set dates
-- - Periodically to refresh statistics for active tires
-- 
-- Usage: SELECT update_tire_statistics();
-- ============================================================================
CREATE OR REPLACE FUNCTION update_tire_statistics()
RETURNS TABLE(tire_set_id INTEGER, tire_set_name VARCHAR, updated BOOLEAN) AS $$
DECLARE
    tire_rec RECORD;
    stats_rec RECORD;
BEGIN
    -- Loop through each tire set
    FOR tire_rec IN SELECT * FROM tire_sets ORDER BY start_date LOOP
        -- Calculate statistics from drives table
        SELECT 
            COALESCE(SUM(d.distance), 0) as total_distance,
            COALESCE(SUM(COALESCE(d.charge_energy_used, 0) - COALESCE(d.start_ideal_battery_range_km, 0) + COALESCE(d.end_ideal_battery_range_km, 0)), 0) as total_energy,
            COALESCE(AVG(d.outside_temp_avg), 0) as avg_temp,
            COUNT(*) as drive_count
        INTO stats_rec
        FROM drives d
        WHERE 
            d.start_date::date >= tire_rec.start_date
            AND (tire_rec.end_date IS NULL OR d.start_date::date <= tire_rec.end_date);
        
        -- Calculate derived metrics
        DECLARE
            calculated_consumption DECIMAL(10,2);
            calculated_efficiency DECIMAL(10,2);
        BEGIN
            IF stats_rec.total_distance > 0 THEN
                calculated_consumption := (stats_rec.total_energy * 1000) / stats_rec.total_distance;
                calculated_efficiency := 100.0;
            ELSE
                calculated_consumption := 0;
                calculated_efficiency := 0;
            END IF;
            
            -- Insert or update statistics
            INSERT INTO tire_set_statistics (
                tire_set_id,
                total_km,
                total_kwh,
                avg_consumption_whkm,
                avg_efficiency,
                avg_temp,
                avg_outside_temp,
                total_drives,
                last_updated
            ) VALUES (
                tire_rec.id,
                stats_rec.total_distance,
                stats_rec.total_energy,
                calculated_consumption,
                calculated_efficiency,
                stats_rec.avg_temp,
                stats_rec.avg_temp,
                stats_rec.drive_count,
                NOW()
            )
            ON CONFLICT (tire_set_id) DO UPDATE SET
                total_km = EXCLUDED.total_km,
                total_kwh = EXCLUDED.total_kwh,
                avg_consumption_whkm = EXCLUDED.avg_consumption_whkm,
                avg_efficiency = EXCLUDED.avg_efficiency,
                avg_temp = EXCLUDED.avg_temp,
                avg_outside_temp = EXCLUDED.avg_outside_temp,
                total_drives = EXCLUDED.total_drives,
                last_updated = NOW();
        END;
        
        -- Return result for this tire set
        RETURN QUERY SELECT tire_rec.id, tire_rec.name, TRUE;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Example Data (CUSTOMIZE THIS SECTION WITH YOUR TIRE HISTORY)
-- ============================================================================
-- Uncomment and modify the following INSERT statements with your own tire data
-- 
-- Notes:
-- - Replace dates with your actual tire installation/removal dates
-- - Replace odometer readings with your actual readings
-- - Set end_date and final_odometer to NULL for currently active tires
-- - Adjust brand, model, and size to match your tires
-- ============================================================================

-- Example: Summer Tires 2024
-- INSERT INTO tire_sets (name, brand, model, size, start_date, end_date, tire_type, initial_odometer, final_odometer) VALUES
-- ('Summer 2024', 'Michelin', 'PilotSport 3', '245/45 R19 102V XL', '2024-03-15', '2024-11-01', 'summer', 145000, 155000);

-- Example: Winter Tires 2024-2025 (currently active)
-- INSERT INTO tire_sets (name, brand, model, size, start_date, end_date, tire_type, initial_odometer, final_odometer) VALUES
-- ('Winter 2024-2025', 'Goodyear', 'UltraGrip Performance+', '245/45 R19 102V XL', '2024-11-01', NULL, 'winter', 155000, NULL);

-- ============================================================================
-- Initial Statistics Calculation
-- ============================================================================
-- Uncomment the following line after inserting your tire data to calculate
-- initial statistics:
-- 
-- SELECT update_tire_statistics();

-- ============================================================================
-- Verification Queries
-- ============================================================================
-- After running this script, you can verify the installation with:
-- 
-- Check tire sets:
-- SELECT * FROM tire_sets ORDER BY start_date DESC;
-- 
-- Check statistics:
-- SELECT 
--     ts.name,
--     ts.tire_type,
--     ts.start_date,
--     ts.end_date,
--     tss.total_km,
--     tss.avg_consumption_whkm,
--     tss.total_drives
-- FROM tire_sets ts
-- LEFT JOIN tire_set_statistics tss ON ts.id = tss.tire_set_id
-- ORDER BY ts.start_date DESC;
-- ============================================================================

-- End of script
