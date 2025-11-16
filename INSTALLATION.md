# Installation Guide

Complete installation instructions for different setups.

## Table of Contents

1. [Standard Docker Installation](#standard-docker-installation)
2. [Manual PostgreSQL Installation](#manual-postgresql-installation)
3. [Remote Database Installation](#remote-database-installation)
4. [Troubleshooting Installation](#troubleshooting-installation)

---

## Standard Docker Installation

This is the recommended method if you're running TeslaMate with Docker Compose.

### Step 1: Locate Your Database Container

```bash
# List all containers
docker ps | grep postgres

# Common container names:
# - teslamate_database_1
# - teslamate-postgres-1
# - teslamate_postgres_1
```

### Step 2: Download Repository Files

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/teslamate-tire-management.git
cd teslamate-tire-management

# Or download specific files:
wget https://raw.githubusercontent.com/YOUR_USERNAME/teslamate-tire-management/main/tire_management.sql
wget https://raw.githubusercontent.com/YOUR_USERNAME/teslamate-tire-management/main/tire_dashboard.json
```

### Step 3: Install Database Schema

```bash
# Method 1: Direct file execution
docker exec -i teslamate_database_1 psql -U teslamate teslamate < tire_management.sql

# Method 2: Interactive session
docker exec -it teslamate_database_1 psql -U teslamate teslamate
# Then paste the contents of tire_management.sql
```

### Step 4: Add Your Tire Data

```bash
# Open interactive psql session
docker exec -it teslamate_database_1 psql -U teslamate teslamate

# Add your tire data
INSERT INTO tire_sets (name, brand, model, size, start_date, end_date, tire_type, initial_odometer, final_odometer)
VALUES ('Summer 2024', 'Michelin', 'PilotSport 4', '245/45 R19', '2024-03-20', NULL, 'summer', 150000, NULL);

# Calculate statistics
SELECT update_tire_statistics();

# Verify
SELECT * FROM tire_sets;
SELECT * FROM tire_set_statistics;

# Exit
\q
```

### Step 5: Import Grafana Dashboard

1. Open Grafana: `http://localhost:3000` (or your Grafana URL)
2. Login (default: admin/admin)
3. Navigate to: **☰ Menu** → **Dashboards** → **Import**
4. Click **Upload JSON file**
5. Select `tire_dashboard.json`
6. Choose your TeslaMate data source (usually "TeslaMate")
7. Click **Import**

---

## Manual PostgreSQL Installation

If you're not using Docker or prefer direct PostgreSQL access.

### Step 1: Connect to PostgreSQL

```bash
# Local connection
psql -U teslamate -d teslamate

# Remote connection
psql -h your-postgres-host -U teslamate -d teslamate

# With password prompt
psql -U teslamate -d teslamate -W
```

### Step 2: Execute SQL Script

```bash
# From command line
psql -U teslamate -d teslamate -f tire_management.sql

# Or within psql session
\i /path/to/tire_management.sql
```

### Step 3: Verify Installation

```sql
-- Check tables exist
\dt tire*

-- Expected output:
--  Schema |        Name         | Type  |  Owner
-- --------+---------------------+-------+----------
--  public | tire_sets          | table | teslamate
--  public | tire_set_statistics | table | teslamate

-- Check function exists
\df update_tire_statistics

-- Test the function
SELECT update_tire_statistics();
```

---

## Remote Database Installation

For TeslaMate hosted on a remote server or cloud service.

### Method 1: SSH Tunnel + Docker

```bash
# Create SSH tunnel to remote server
ssh -L 5432:localhost:5432 user@remote-server

# In another terminal, connect through tunnel
docker exec -i teslamate_database_1 psql -U teslamate teslamate < tire_management.sql
```

### Method 2: Direct Remote Connection

```bash
# Upload SQL file to server
scp tire_management.sql user@remote-server:/tmp/

# SSH to server and execute
ssh user@remote-server
docker exec -i teslamate_database_1 psql -U teslamate teslamate < /tmp/tire_management.sql
```

### Method 3: pgAdmin or DBeaver

1. Open your PostgreSQL GUI client
2. Connect to your TeslaMate database
3. Open `tire_management.sql` in the SQL editor
4. Execute the script
5. Verify tables and function were created

---

## Troubleshooting Installation

### Issue: "psql: command not found"

**Cause:** PostgreSQL client not installed.

**Solution:**
```bash
# Ubuntu/Debian
sudo apt-get install postgresql-client

# macOS
brew install postgresql

# Or use Docker method instead
docker exec -it teslamate_database_1 bash
# Then inside container: psql -U teslamate teslamate
```

### Issue: "FATAL: password authentication failed"

**Cause:** Incorrect password or user.

**Solution:**
```bash
# Check your TeslaMate docker-compose.yml for credentials
cat docker-compose.yml | grep POSTGRES

# Common defaults:
# User: teslamate
# Database: teslamate
# Password: (check POSTGRES_PASSWORD in docker-compose.yml)
```

### Issue: "permission denied for schema public"

**Cause:** User doesn't have CREATE privileges.

**Solution:**
```sql
-- Connect as postgres superuser
psql -U postgres -d teslamate

-- Grant privileges
GRANT ALL PRIVILEGES ON SCHEMA public TO teslamate;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO teslamate;

-- Try installation again
\q
```

### Issue: "relation already exists"

**Cause:** Tables already exist from previous installation attempt.

**Solution:**
```sql
-- Check existing tables
SELECT * FROM tire_sets;

-- If you want to keep data, skip this error
-- If you want to start fresh:
DROP TABLE tire_set_statistics CASCADE;
DROP TABLE tire_sets CASCADE;
DROP FUNCTION IF EXISTS update_tire_statistics();

-- Then re-run installation
```

### Issue: "ERROR: function update_tire_statistics() does not exist"

**Cause:** Function wasn't created properly.

**Solution:**
```sql
-- Check if function exists
\df update_tire_statistics

-- If not found, ensure tire_sets table exists first:
\dt tire_sets

-- Then recreate just the function by running the CREATE FUNCTION section from tire_management.sql
```

### Issue: Dashboard shows "No Data"

**Causes and Solutions:**

1. **Statistics not calculated:**
   ```sql
   SELECT update_tire_statistics();
   ```

2. **No tire data added:**
   ```sql
   SELECT * FROM tire_sets;
   -- If empty, add your tire data
   ```

3. **Wrong time range in Grafana:**
   - Click time picker (top right)
   - Select "Last 2 years" or appropriate range
   - Ensure range overlaps with your tire dates

4. **Data source not configured:**
   - Check dashboard settings
   - Verify TeslaMate data source is selected
   - Test data source connection

### Issue: "Container name not found"

**Solution:**
```bash
# Find correct container name
docker ps -a

# Try different variations:
docker exec -it teslamate_database_1 psql -U teslamate teslamate
docker exec -it teslamate-database-1 psql -U teslamate teslamate
docker exec -it teslamate-postgres-1 psql -U teslamate teslamate
docker exec -it teslamate_postgres_1 psql -U teslamate teslamate

# Or find by image name
docker ps --filter ancestor=postgres
```

---

## Post-Installation Verification

After installation, verify everything works:

### 1. Check Database Objects

```sql
-- Connect to database
docker exec -it teslamate_database_1 psql -U teslamate teslamate

-- Verify tables
\dt tire*

-- Verify function
\df update_tire_statistics

-- Check for data
SELECT COUNT(*) FROM tire_sets;
SELECT COUNT(*) FROM tire_set_statistics;
```

### 2. Test Function

```sql
-- Run update function
SELECT update_tire_statistics();

-- Should return:
--  tire_set_id | tire_set_name | updated
-- -------------+---------------+---------
--            1 | Summer 2024   | t
```

### 3. Test Dashboard

1. Open Grafana
2. Find "Tire Management" dashboard
3. Check all panels display data
4. Verify time range is appropriate
5. Test different time ranges

### 4. Test Data Updates

```sql
-- Add new drive data in TeslaMate
-- Then refresh statistics
SELECT update_tire_statistics();

-- Verify statistics updated
SELECT tire_set_id, total_km, last_updated 
FROM tire_set_statistics 
ORDER BY last_updated DESC;
```

---

## Next Steps

After successful installation:

1. **Import Historical Data** - Add all your previous tire sets
2. **Set Up Automation** - Configure periodic statistics refresh
3. **Customize Dashboard** - Adjust panels to your preferences
4. **Take Backups** - Export your tire data regularly

See [README.md](README.md) for usage instructions and [QUICKSTART.md](QUICKSTART.md) for a faster overview.

---

## Need More Help?

- Check [Troubleshooting](README.md#troubleshooting) in README
- Review TeslaMate documentation: https://docs.teslamate.org
- Open an issue on GitHub
- Join TeslaMate community forums
