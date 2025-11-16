# Quick Start Guide

Get up and running with TeslaMate Tire Management in 5 minutes!

## Prerequisites Check

Before starting, ensure you have:
- ✅ TeslaMate installed and running
- ✅ Access to TeslaMate's PostgreSQL database
- ✅ Grafana installed and configured
- ✅ Docker (recommended) or direct PostgreSQL access

## Step 1: Database Setup (2 minutes)

### Find Your Database Container

```bash
docker ps | grep postgres
```

Look for a container name like `teslamate_database_1` or `teslamate-postgres-1`.

### Install the Schema

```bash
# Replace 'teslamate_database_1' with your actual container name
docker exec -i teslamate_database_1 psql -U teslamate teslamate < tire_management.sql
```

Expected output: `CREATE TABLE` messages for both tables.

## Step 2: Add Your Tire Data (2 minutes)

### Edit the SQL File

Open `tire_management.sql` in a text editor and find the example data section (around line 150).

### Add Your First Tire Set

```sql
INSERT INTO tire_sets (name, brand, model, size, start_date, end_date, tire_type, initial_odometer, final_odometer)
VALUES 
('My Current Tires', 'Michelin', 'PilotSport 4', '245/45 R19', '2024-03-20', NULL, 'summer', 150000, NULL);
```

### Load Your Data

```bash
docker exec -it teslamate_database_1 psql -U teslamate teslamate
```

Then paste your INSERT statement and press Enter.

### Calculate Statistics

Still in the psql prompt:

```sql
SELECT update_tire_statistics();
```

You should see output showing your tire set was processed.

Type `\q` to exit psql.

## Step 3: Import Dashboard (1 minute)

1. Open Grafana: http://localhost:3000
2. Click **☰** (menu) → **Dashboards** → **Import**
3. Click **Upload JSON file**
4. Select `tire_dashboard.json`
5. Select your **TeslaMate** data source
6. Click **Import**

Done! Your dashboard is ready! 🎉

## Step 4: Verify Everything Works

### Check Your Dashboard

You should see:
- Your tire set in the overview table
- Statistics in the gauges (distance, consumption, temperature)
- Data in the charts

### If You See No Data

Run this query in psql to verify:

```sql
SELECT * FROM tire_sets;
SELECT * FROM tire_set_statistics;
```

If tire_set_statistics is empty, run:

```sql
SELECT update_tire_statistics();
```

## Common Issues

### Issue: "relation tire_sets does not exist"

**Solution:** The schema wasn't created. Re-run:
```bash
docker exec -i teslamate_database_1 psql -U teslamate teslamate < tire_management.sql
```

### Issue: "No data in dashboard"

**Solutions:**
1. Check time range in Grafana (top right) - try "Last 2 years"
2. Verify tire dates overlap with your TeslaMate data
3. Run `SELECT update_tire_statistics();`
4. Check data source is correctly configured in Grafana

### Issue: "Container not found"

**Solution:** Find the correct container name:
```bash
docker ps -a | grep postgres
```

## Next Steps

Now that you're set up:

1. **Add Historical Tire Data** - Add all your previous tire sets for complete history
2. **Automate Updates** - Set up periodic statistics refresh (see README.md)
3. **Customize Dashboard** - Adjust panels to your preferences
4. **Take Screenshots** - Document your setup for future reference

## Need Help?

- Check the full [README.md](README.md) for detailed documentation
- Review [Troubleshooting](README.md#troubleshooting) section
- Open an issue on GitHub if you encounter problems

---

**Time to first data: ~5 minutes** ⏱️

Happy tracking! 🚗💨