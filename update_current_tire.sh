#!/bin/bash
# ============================================================================
# TeslaMate Tire Management - Update Script
# ============================================================================
# Updates current tire statistics from TeslaMate drive data
# Can be run manually or via cron job
# ============================================================================

set -e  # Exit on error

# Configuration
CONTAINER_NAME="${POSTGRES_CONTAINER:-teslamate-database-1}"
DB_USER="${DB_USER:-teslamate}"
DB_NAME="${DB_NAME:-teslamate}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display header
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}🔄 TeslaMate Tire Management - Statistics Update${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if container exists
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}❌ Container '$CONTAINER_NAME' not found or not running${NC}"
    echo ""
    echo "Available PostgreSQL containers:"
    docker ps | grep postgres || echo "No PostgreSQL containers found"
    echo ""
    echo "Set the correct container name:"
    echo "  export POSTGRES_CONTAINER=your_container_name"
    exit 1
fi

# Update statistics
echo -e "${GREEN}✅ Updating tire statistics...${NC}"
echo ""
docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT update_current_tire_stats();" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Statistics updated successfully!${NC}"
    echo ""
    echo "📊 Current Tire Status:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Display current tire status
    docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c "
    SELECT
        ts.name AS \"Set\",
        COALESCE(ROUND(tss.kilometers::numeric, 0), 0) AS \"Km\",
        COALESCE(ROUND(tss.consumption_wh_km::numeric, 0), 0) AS \"wH/km\",
        COALESCE(ROUND(tss.efficiency_percent::numeric, 1), 0) AS \"Eff%\",
        CASE
            WHEN ts.date_end IS NULL THEN '🟢 Actuel'
            ELSE '⚪ Ancien'
        END AS \"Status\"
    FROM tire_sets ts
    LEFT JOIN tire_set_statistics tss ON ts.id = tss.tire_set_id
    WHERE ts.car_id = 1
    ORDER BY ts.date_start DESC
    LIMIT 4;
    "
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}✅ Dashboard Grafana is up to date!${NC}"
    echo ""
else
    echo -e "${RED}❌ Error updating statistics${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check container name: docker ps | grep postgres"
    echo "2. Verify database connection"
    echo "3. Check logs: docker logs $CONTAINER_NAME"
    exit 1
fi
