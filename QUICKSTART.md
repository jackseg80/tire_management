# Quick Start Guide

Get your TeslaMate Tire Management system running in **5 minutes**!

## Prerequisites Check

Before starting:
- [x] TeslaMate installed and running
- [x] Docker access
- [x] Grafana accessible (usually http://localhost:3000)

## Installation Steps

### Step 1: Find Your Database Container (30 seconds)

```bash
docker ps | grep postgres
```

Look for a container name like:
- `teslamate-database-1` ✅
- `teslamate_database_1`
- `teslamate-postgres-1`

### Step 2: Install Database Schema (1 minute)

```bash
# Download files
git clone https://github.com/YOUR_USERNAME/teslamate-tire-management.git
cd teslamate-tire-management

# Install schema (replace container name if different)
docker exec -i teslamate-database-1 psql -U teslamate teslamate < tire_management.sql
```

**Expected output:** Several `CREATE TABLE` and `CREATE FUNCTION` messages.

### Step 3: Add Your First Tire Set (2 minutes)

```bash
# Open PostgreSQL
docker exec -it teslamate-database-1 psql -U teslamate teslamate
```

Then paste this (customize with your data):

```sql
-- Add your tire model
INSERT INTO tire_models (brand, model, size, type) VALUES
('Michelin', 'PilotSport 4', '245/45 R19 102V XL', 'Summer');

-- Add your current tire set
-- Change the date to when you installed these tires
INSERT INTO tire_sets (car_id, name, tire_model_id, date_start) VALUES
(1, 'My Summer Tires', 1, '2024-03-20');

-- Calculate statistics
SELECT update_current_tire_stats();
```

You should see: `(1 row)` confirming the update.

Type `\q` to exit.

### Step 4: Import Grafana Dashboard (1 minute)

1. Open Grafana: http://localhost:3000
2. Click **☰** → **Dashboards** → **Import**
3. Click **Upload JSON file**
4. Select `tire_dashboard.json`
5. Choose **TeslaMate** as data source
6. Click **Import**

### Step 5: Verify Everything Works (30 seconds)

Your dashboard should now show:
- ✅ Your tire set in the overview table
- ✅ Distance, consumption, and efficiency gauges
- ✅ Charts with your tire data

## 🎉 Success!

You're all set! Your tire management system is now tracking your tire performance.

## What Now?

### Add Historical Tire Data

If you want to track previous tire sets:

```sql
-- Example: Add your winter tires from last year
INSERT INTO tire_models (brand, model, size, type) VALUES
('Goodyear', 'UltraGrip Performance+', '245/45 R19 102V XL', 'Winter');

INSERT INTO tire_sets (car_id, name, tire_model_id, date_start, date_end) VALUES
(1, 'Winter 2023-2024', 2, '2023-11-15', '2024-03-20');

SELECT update_current_tire_stats();
```

### Automate Statistics Updates

Set up automatic daily updates:

```bash
# Make script executable
chmod +x update_current_tire.sh

# Edit crontab
crontab -e

# Add this line (updates at 2 AM daily)
0 2 * * * cd /path/to/teslamate-tire-management && ./update_current_tire.sh >> tire_update.log 2>&1
```

### Customize the Dashboard

In Grafana:
- Click panel title → **Edit** to modify queries
- **Dashboard settings** → adjust time ranges
- Add new panels for custom metrics

## Common Issues

### Issue: "Container not found"

**Solution:** Check your actual container name:
```bash
docker ps | grep postgres
```
Use the correct name in all commands.

### Issue: "No data in dashboard"

**Solutions:**
1. Check time range (top right) - try "Last 2 years"
2. Verify tire dates match your TeslaMate data
3. Run: `SELECT update_current_tire_stats();`

### Issue: "Statistics are 0 or NULL"

**Solution:** Make sure your tire dates overlap with drive data:
```sql
-- Check drives exist
SELECT COUNT(*), MIN(start_date), MAX(start_date) 
FROM drives WHERE car_id = 1;

-- Check tire dates
SELECT name, date_start, date_end FROM tire_sets;
```

If dates don't overlap, adjust tire dates accordingly.

### Issue: "Function does not exist"

**Solution:** Schema wasn't installed properly. Re-run:
```bash
docker exec -i teslamate-database-1 psql -U teslamate teslamate < tire_management.sql
```

## Next Steps

Now that you're set up:

1. **Read the [README](README.md)** for detailed documentation
2. **Explore the dashboard** - try different time ranges
3. **Add more tire history** if you have it
4. **Set up automation** for hands-free operation

## Pro Tips

- Run `./update_current_tire.sh` after each drive for real-time updates
- Take notes in the tire set `notes` field for future reference
- Compare summer vs winter performance in the dashboard
- Use the temperature panels to understand consumption variations

---

**Total Time:** ~5 minutes ⏱️

**Questions?** Check the [README](README.md) or open an [issue](https://github.com/YOUR_USERNAME/teslamate-tire-management/issues)!

Happy tracking!