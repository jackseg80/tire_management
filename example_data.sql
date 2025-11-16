-- ============================================================================
-- TeslaMate Tire Management - Example Data
-- ============================================================================
-- This file contains example tire data for testing the system.
-- Customize these values with your actual tire history.
-- ============================================================================

-- ============================================================================
-- Example 1: Complete History for a Tesla Model S (2022-2025)
-- ============================================================================

-- Summer 2022
INSERT INTO tire_sets (name, brand, model, size, start_date, end_date, tire_type, initial_odometer, final_odometer, notes) VALUES
('Summer 2022', 'Michelin', 'PilotSport 3', '245/45 R19 102V XL', '2022-03-20', '2022-11-05', 'summer', 120000, 130500, 'First set of summer tires');

-- Winter 2022-2023
INSERT INTO tire_sets (name, brand, model, size, start_date, end_date, tire_type, initial_odometer, final_odometer, notes) VALUES
('Winter 2022-2023', 'Goodyear', 'UltraGrip Performance+', '245/45 R19 102V XL', '2022-11-05', '2023-03-15', 'winter', 130500, 137000, 'Excellent winter performance');

-- Summer 2023
INSERT INTO tire_sets (name, brand, model, size, start_date, end_date, tire_type, initial_odometer, final_odometer, notes) VALUES
('Summer 2023', 'Michelin', 'PilotSport 3', '245/45 R19 102V XL', '2023-03-15', '2023-11-10', 'summer', 137000, 149500, 'Returned to summer tires');

-- Winter 2023-2024
INSERT INTO tire_sets (name, brand, model, size, start_date, end_date, tire_type, initial_odometer, final_odometer, notes) VALUES
('Winter 2023-2024', 'Goodyear', 'UltraGrip Performance+', '245/45 R19 102V XL', '2023-11-10', '2024-03-18', 'winter', 149500, 156800, 'Very cold winter this year');

-- Summer 2024
INSERT INTO tire_sets (name, brand, model, size, start_date, end_date, tire_type, initial_odometer, final_odometer, notes) VALUES
('Summer 2024', 'Hankook', 'Ventus iOn S IK01', '245/45 R19 102V XL', '2024-03-18', '2024-11-01', 'summer', 156800, 168000, 'Trying Hankook for better efficiency');

-- Winter 2024-2025
INSERT INTO tire_sets (name, brand, model, size, start_date, end_date, tire_type, initial_odometer, final_odometer, notes) VALUES
('Winter 2024-2025', 'Goodyear', 'UltraGrip Performance+', '245/45 R19 102V XL', '2024-11-01', '2025-03-20', 'winter', 168000, 175000, 'Mild winter with less snow');

-- Summer 2025 (Currently Active)
INSERT INTO tire_sets (name, brand, model, size, start_date, end_date, tire_type, initial_odometer, final_odometer, notes) VALUES
('Summer 2025', 'Hankook', 'Ventus iOn S IK01', '245/45 R19 102V XL', '2025-03-20', NULL, 'summer', 175000, NULL, 'Currently in use - excellent performance');

-- ============================================================================
-- Calculate Statistics for All Tire Sets
-- ============================================================================
-- After inserting your tire data, run this to calculate statistics:
SELECT update_tire_statistics();

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- View all tire sets with their statistics
SELECT 
    ts.name,
    ts.tire_type,
    ts.start_date,
    ts.end_date,
    ROUND(tss.total_km::numeric, 0) as total_km,
    ROUND(tss.avg_consumption_whkm::numeric, 1) as avg_whkm,
    ROUND(tss.avg_outside_temp::numeric, 1) as avg_temp,
    tss.total_drives
FROM tire_sets ts
LEFT JOIN tire_set_statistics tss ON ts.id = tss.tire_set_id
ORDER BY ts.start_date DESC;

-- View current tire set only
SELECT 
    ts.name as "Current Tire Set",
    ts.brand || ' ' || ts.model as "Model",
    ROUND(tss.total_km::numeric, 0) as "Distance (km)",
    ROUND(tss.avg_consumption_whkm::numeric, 1) as "Consumption (Wh/km)",
    ROUND(tss.avg_outside_temp::numeric, 1) as "Avg Temp (°C)"
FROM tire_sets ts
LEFT JOIN tire_set_statistics tss ON ts.id = tss.tire_set_id
WHERE ts.end_date IS NULL;

-- Compare summer vs winter performance
SELECT 
    ts.tire_type as "Season",
    COUNT(*) as "Number of Sets",
    ROUND(AVG(tss.total_km)::numeric, 0) as "Avg Distance (km)",
    ROUND(AVG(tss.avg_consumption_whkm)::numeric, 1) as "Avg Consumption (Wh/km)",
    ROUND(AVG(tss.avg_outside_temp)::numeric, 1) as "Avg Temperature (°C)"
FROM tire_sets ts
LEFT JOIN tire_set_statistics tss ON ts.id = tss.tire_set_id
WHERE tss.total_km IS NOT NULL
GROUP BY ts.tire_type
ORDER BY ts.tire_type;

-- ============================================================================
-- Notes for Customization
-- ============================================================================
-- 
-- 1. Dates: Replace with your actual tire change dates
-- 2. Odometer: Use your vehicle's odometer readings
-- 3. Brands/Models: Update to match your tires
-- 4. Size: Verify tire size matches your vehicle
-- 5. Notes: Add any relevant observations
-- 
-- Tips:
-- - Set end_date to NULL for currently active tires
-- - Set final_odometer to NULL for currently active tires
-- - Keep consistent date formats (YYYY-MM-DD)
-- - Document tire rotations in the notes field
-- - Track any unusual wear patterns or issues
-- 
-- ============================================================================
