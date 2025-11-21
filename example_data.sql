-- ============================================================================
-- TeslaMate Tire Management - Example Data
-- ============================================================================
-- This file contains example tire data for testing the system.
-- Customize these values with your actual tire history.
-- ============================================================================

-- ============================================================================
-- Step 1: Add Tire Models
-- ============================================================================
-- First, define the tire models you use
-- Add as many as you need - they can be reused across multiple tire sets
-- ============================================================================

INSERT INTO tire_models (brand, model, size, type, notes) VALUES
('Michelin', 'PilotSport 3', '245/45 R19 102V XL', 'Summer', 'Excellent grip and longevity'),
('Goodyear', 'UltraGrip Performance+', '245/45 R19 102V XL', 'Winter', 'Best winter tire tested'),
('Hankook', 'Ventus iOn S IK01', '245/45 R19 102V XL', 'Summer', 'EV-optimized, lower rolling resistance');

-- ============================================================================
-- Step 2: Add Tire Sets History
-- ============================================================================
-- Track each time you installed a set of tires
-- 
-- Important:
-- - Set date_end to NULL for currently active tires
-- - Use car_id from your TeslaMate cars table (usually 1)
-- - tire_model_id references the tire_models table above
-- ============================================================================

-- Example: Complete history for 2022-2025
INSERT INTO tire_sets (car_id, name, tire_model_id, date_start, date_end, notes) VALUES
(1, 'Summer 2022', 1, '2022-06-07', '2022-12-13', 'First set of Michelin'),
(1, 'Winter 2022-2023', 2, '2022-12-13', '2023-06-07', 'Excellent winter performance'),
(1, 'Summer 2023', 1, '2023-06-07', '2023-11-17', 'Second season with same tires'),
(1, 'Winter 2023-2024', 2, '2023-11-17', '2024-06-05', 'Very cold winter this year'),
(1, 'Summer 2024', 3, '2024-06-05', '2024-11-08', 'Trying Hankook for better efficiency'),
(1, 'Winter 2024-2025', 2, '2024-11-08', '2025-04-12', 'Mild winter, less snow'),
(1, 'Summer 2025', 3, '2025-04-12', NULL, 'Currently active - excellent performance');

-- ============================================================================
-- Step 3: Calculate Statistics
-- ============================================================================
-- After inserting your tire data, run this to calculate statistics from
-- your TeslaMate drive data
-- ============================================================================

SELECT update_current_tire_stats();

-- ============================================================================
-- Step 4: Verify Installation
-- ============================================================================
-- Check that everything was created correctly
-- ============================================================================

-- View all tire models
SELECT 
    id,
    brand,
    model,
    type,
    size
FROM tire_models
ORDER BY type, brand;

-- View all tire sets with statistics
SELECT 
    ts.name,
    tm.brand || ' ' || tm.model as tire,
    tm.type,
    ts.date_start,
    ts.date_end,
    ROUND(tss.kilometers::numeric, 0) as km,
    ROUND(tss.consumption_wh_km::numeric, 0) as wh_km,
    ROUND(tss.efficiency_percent::numeric, 1) as eff_pct,
    ROUND(tss.temperature_avg::numeric, 1) as temp,
    CASE 
        WHEN ts.date_end IS NULL THEN '🟢 Active'
        ELSE '⚪ Inactive'
    END as status
FROM tire_sets ts
LEFT JOIN tire_models tm ON ts.tire_model_id = tm.id
LEFT JOIN tire_set_statistics tss ON ts.id = tss.tire_set_id
ORDER BY ts.date_start DESC;

-- View current tire set only
SELECT 
    ts.name as "Current Tire Set",
    tm.brand || ' ' || tm.model as "Model",
    tm.type as "Type",
    ts.date_start as "Installed",
    ROUND(tss.kilometers::numeric, 0) as "Distance (km)",
    ROUND(tss.consumption_wh_km::numeric, 0) as "Consumption (Wh/km)",
    ROUND(tss.efficiency_percent::numeric, 1) as "Efficiency (%)",
    ROUND(tss.temperature_avg::numeric, 1) as "Avg Temp (°C)"
FROM tire_sets ts
LEFT JOIN tire_models tm ON ts.tire_model_id = tm.id
LEFT JOIN tire_set_statistics tss ON ts.id = tss.tire_set_id
WHERE ts.date_end IS NULL;

-- Compare summer vs winter performance
SELECT 
    tm.type as "Season",
    COUNT(DISTINCT ts.id) as "Number of Sets",
    ROUND(AVG(tss.kilometers)::numeric, 0) as "Avg Distance (km)",
    ROUND(AVG(tss.consumption_wh_km)::numeric, 1) as "Avg Consumption (Wh/km)",
    ROUND(AVG(tss.efficiency_percent)::numeric, 1) as "Avg Efficiency (%)",
    ROUND(AVG(tss.temperature_avg)::numeric, 1) as "Avg Temperature (°C)"
FROM tire_sets ts
LEFT JOIN tire_models tm ON ts.tire_model_id = tm.id
LEFT JOIN tire_set_statistics tss ON ts.id = tss.tire_set_id
WHERE tss.kilometers IS NOT NULL
GROUP BY tm.type
ORDER BY tm.type;

-- ============================================================================
-- Expected Results
-- ============================================================================
-- 
-- After running this script, you should see:
-- - 3 tire models in the tire_models table
-- - 7 tire sets in the tire_sets table
-- - Statistics calculated for all sets where TeslaMate has drive data
-- - The most recent set (Summer 2025) marked as active (date_end = NULL)
-- 
-- Expected consumption ranges:
-- - Summer tires: 150-170 Wh/km
-- - Winter tires: 180-220 Wh/km
-- 
-- Expected efficiency:
-- - Summer: 80-90%
-- - Winter: 60-70%
-- 
-- ============================================================================

-- ============================================================================
-- Customization Guide
-- ============================================================================
-- 
-- TO CUSTOMIZE FOR YOUR VEHICLE:
-- 
-- 1. TIRE MODELS
--    Replace with your actual tire brands, models, and sizes
--    You can find these on the tire sidewall
-- 
-- 2. TIRE SETS
--    Update dates to match when you actually changed tires
--    Format: 'YYYY-MM-DD'
-- 
-- 3. CAR ID
--    Most installations use car_id = 1
--    Check your cars table: SELECT id, name FROM cars;
-- 
-- 4. NOTES
--    Add observations about tire performance, wear, conditions, etc.
-- 
-- 5. CONVERSION FACTOR
--    The factor 162 is calibrated for Model S 75D
--    If you have different results, you may need to adjust it
--    See tire_management.sql for calibration explanation
-- 
-- ============================================================================

-- ============================================================================
-- Tips for Historical Data
-- ============================================================================
-- 
-- If you have historical data from other sources (TeslaFi, etc.):
-- 
-- 1. Create the tire sets with approximate dates
-- 2. Run update_current_tire_stats() to calculate from TeslaMate
-- 3. If needed, you can manually override statistics:
--    
--    INSERT INTO tire_set_statistics (tire_set_id, kilometers, consumption_wh_km, efficiency_percent)
--    VALUES (1, 6221, 167, 75.9)
--    ON CONFLICT (tire_set_id) DO UPDATE 
--    SET kilometers = EXCLUDED.kilometers,
--        consumption_wh_km = EXCLUDED.consumption_wh_km,
--        efficiency_percent = EXCLUDED.efficiency_percent;
-- 
-- 4. For future sets, let the function calculate automatically
-- 
-- ============================================================================

-- ============================================================================
-- Common Use Cases
-- ============================================================================

-- SCENARIO 1: You only remember the last 2 tire changes
/*
DELETE FROM tire_sets;
DELETE FROM tire_models;

INSERT INTO tire_models (brand, model, size, type) VALUES
('YourBrand', 'YourModel', 'YourSize', 'Summer');

INSERT INTO tire_sets (car_id, name, tire_model_id, date_start, date_end) VALUES
(1, 'My Last Tires', 1, '2024-03-01', '2024-11-01'),
(1, 'My Current Tires', 1, '2024-11-01', NULL);

SELECT update_current_tire_stats();
*/

-- SCENARIO 2: You want to track all-season tires
/*
INSERT INTO tire_models (brand, model, size, type) VALUES
('Michelin', 'CrossClimate+', '245/45 R19', 'All-Season');

INSERT INTO tire_sets (car_id, name, tire_model_id, date_start) VALUES
(1, 'All-Season 2025', (SELECT id FROM tire_models WHERE model = 'CrossClimate+'), CURRENT_DATE);

SELECT update_current_tire_stats();
*/

-- SCENARIO 3: You have very detailed notes
/*
INSERT INTO tire_sets (car_id, name, tire_model_id, date_start, date_end, notes) VALUES
(1, 'Winter 2024-2025', 2, '2024-11-08', '2025-04-12', 
'Installed at 155,000 km. Excellent grip in snow. Some road noise on dry pavement. Rotated at 157,500 km. Noticeable increase in consumption during cold snap in January (below -15°C). Overall very satisfied with winter performance.');
*/

-- ============================================================================
-- Troubleshooting
-- ============================================================================

-- If statistics are not calculating:

-- 1. Check if drives exist in date range
-- SELECT COUNT(*), MIN(start_date), MAX(start_date)
-- FROM drives 
-- WHERE car_id = 1 
--   AND start_date >= '2024-01-01';

-- 2. Check tire set dates
-- SELECT id, name, date_start, date_end 
-- FROM tire_sets 
-- ORDER BY date_start;

-- 3. Manually trigger calculation
-- SELECT update_current_tire_stats();

-- 4. Check for errors
-- SELECT * FROM tire_set_statistics;

-- If you see zeros or NULLs, your tire dates might not overlap with drive data

-- ============================================================================
-- End of Example Data
-- ============================================================================
