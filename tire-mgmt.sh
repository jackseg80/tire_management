#!/bin/bash
# ============================================================================
# TeslaMate Tire Management - Utility Scripts
# ============================================================================
# This script provides convenient commands for managing tire data
# ============================================================================

set -e  # Exit on error

# Configuration
CONTAINER_NAME="${POSTGRES_CONTAINER:-teslamate_database_1}"
DB_USER="${DB_USER:-teslamate}"
DB_NAME="${DB_NAME:-teslamate}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "ℹ $1"
}

# Check if container exists
check_container() {
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        print_error "Container '$CONTAINER_NAME' not found or not running"
        echo ""
        echo "Available PostgreSQL containers:"
        docker ps | grep postgres || echo "No PostgreSQL containers found"
        echo ""
        echo "Set the correct container name:"
        echo "  export POSTGRES_CONTAINER=your_container_name"
        exit 1
    fi
}

# Execute SQL command
exec_sql() {
    docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" "$DB_NAME" -c "$1"
}

# Execute SQL file
exec_sql_file() {
    docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" "$DB_NAME" < "$1"
}

# ============================================================================
# Commands
# ============================================================================

cmd_install() {
    print_info "Installing TeslaMate Tire Management schema..."
    check_container
    
    if [ ! -f "tire_management.sql" ]; then
        print_error "tire_management.sql not found in current directory"
        exit 1
    fi
    
    exec_sql_file "tire_management.sql"
    print_success "Schema installed successfully"
}

cmd_update_stats() {
    print_info "Updating tire statistics..."
    check_container
    
    exec_sql "SELECT update_tire_statistics();" | grep -v "^(" | grep -v "rows)"
    print_success "Statistics updated successfully"
}

cmd_list_tires() {
    print_info "Listing all tire sets..."
    check_container
    
    exec_sql "SELECT ts.name, ts.tire_type, ts.start_date, ts.end_date, ROUND(tss.total_km::numeric, 0) as total_km, ROUND(tss.avg_consumption_whkm::numeric, 1) as avg_whkm FROM tire_sets ts LEFT JOIN tire_set_statistics tss ON ts.id = tss.tire_set_id ORDER BY ts.start_date DESC;"
}

cmd_current_tire() {
    print_info "Current tire set information..."
    check_container
    
    exec_sql "SELECT ts.name, ts.brand || ' ' || ts.model as model, ROUND(tss.total_km::numeric, 0) as total_km, ROUND(tss.avg_consumption_whkm::numeric, 1) as avg_whkm, ROUND(tss.avg_outside_temp::numeric, 1) as avg_temp, tss.total_drives FROM tire_sets ts LEFT JOIN tire_set_statistics tss ON ts.id = tss.tire_set_id WHERE ts.end_date IS NULL;"
}

cmd_add_tire() {
    print_info "Add a new tire set (interactive mode)..."
    check_container
    
    echo ""
    read -p "Tire set name (e.g., 'Summer 2024'): " name
    read -p "Brand (e.g., 'Michelin'): " brand
    read -p "Model (e.g., 'PilotSport 4'): " model
    read -p "Size (e.g., '245/45 R19 102V XL'): " size
    read -p "Start date (YYYY-MM-DD): " start_date
    read -p "Type (summer/winter): " tire_type
    read -p "Initial odometer reading: " initial_odometer
    
    echo ""
    print_warning "Ending current tire set (if any)..."
    exec_sql "UPDATE tire_sets SET end_date = '$start_date', final_odometer = $initial_odometer WHERE end_date IS NULL;"
    
    print_info "Adding new tire set..."
    exec_sql "INSERT INTO tire_sets (name, brand, model, size, start_date, tire_type, initial_odometer) VALUES ('$name', '$brand', '$model', '$size', '$start_date', '$tire_type', $initial_odometer);"
    
    print_info "Updating statistics..."
    exec_sql "SELECT update_tire_statistics();" > /dev/null
    
    print_success "Tire set added successfully"
}

cmd_verify() {
    print_info "Verifying installation..."
    check_container
    
    echo ""
    echo "Checking tables..."
    if exec_sql "\dt tire*" | grep -q "tire_sets"; then
        print_success "Tables exist"
    else
        print_error "Tables not found"
        exit 1
    fi
    
    echo ""
    echo "Checking function..."
    if exec_sql "\df update_tire_statistics" | grep -q "update_tire_statistics"; then
        print_success "Function exists"
    else
        print_error "Function not found"
        exit 1
    fi
    
    echo ""
    echo "Checking data..."
    tire_count=$(exec_sql "SELECT COUNT(*) FROM tire_sets;" | grep -o '[0-9]*' | head -1)
    if [ "$tire_count" -gt 0 ]; then
        print_success "Found $tire_count tire set(s)"
    else
        print_warning "No tire sets found - you may want to add some data"
    fi
    
    echo ""
    print_success "Verification complete"
}

cmd_backup() {
    print_info "Backing up tire data..."
    check_container
    
    backup_file="tire_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    echo "-- TeslaMate Tire Management Backup" > "$backup_file"
    echo "-- Generated: $(date)" >> "$backup_file"
    echo "" >> "$backup_file"
    
    docker exec "$CONTAINER_NAME" pg_dump -U "$DB_USER" -d "$DB_NAME" -t tire_sets -t tire_set_statistics >> "$backup_file"
    
    print_success "Backup saved to: $backup_file"
}

cmd_help() {
    cat << EOF
TeslaMate Tire Management - Utility Script

Usage: $0 <command> [options]

Commands:
  install          Install the database schema
  update-stats     Update tire statistics from TeslaMate data
  list             List all tire sets with statistics
  current          Show current tire set information
  add              Add a new tire set (interactive)
  verify           Verify installation is complete
  backup           Backup tire data to SQL file
  help             Show this help message

Environment Variables:
  POSTGRES_CONTAINER   PostgreSQL container name (default: teslamate_database_1)
  DB_USER             Database user (default: teslamate)
  DB_NAME             Database name (default: teslamate)

Examples:
  # Install schema
  $0 install

  # Update statistics
  $0 update-stats

  # List all tires
  $0 list

  # Show current tire
  $0 current

  # Add new tire set
  $0 add

  # Verify everything is working
  $0 verify

  # Create backup
  $0 backup

  # Use custom container name
  POSTGRES_CONTAINER=my_postgres_container $0 update-stats

EOF
}

# ============================================================================
# Main
# ============================================================================

case "${1:-help}" in
    install)
        cmd_install
        ;;
    update-stats)
        cmd_update_stats
        ;;
    list)
        cmd_list_tires
        ;;
    current)
        cmd_current_tire
        ;;
    add)
        cmd_add_tire
        ;;
    verify)
        cmd_verify
        ;;
    backup)
        cmd_backup
        ;;
    help|--help|-h)
        cmd_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        cmd_help
        exit 1
        ;;
esac
