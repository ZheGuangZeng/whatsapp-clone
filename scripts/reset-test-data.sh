#!/bin/bash

# Data Reset and Refresh Script for Testing
# This script provides capabilities to reset and refresh test data
# for comprehensive testing scenarios.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_COMPOSE_FILE="$PROJECT_ROOT/docker-compose.local.yml"
SEED_FILE="$PROJECT_ROOT/supabase/seed.sql"

# Function to print status
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️ $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️ $message${NC}"
            ;;
    esac
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to show usage
show_usage() {
    echo -e "${BLUE}Usage: $0 [OPTION]${NC}"
    echo -e "${BLUE}Reset and refresh test data for the WhatsApp Clone project${NC}"
    echo ""
    echo "Options:"
    echo "  --full-reset      Completely reset database and reseed"
    echo "  --quick-seed      Just run the seed script (fast refresh)"
    echo "  --backup-current  Backup current data before reset"
    echo "  --restore-backup  Restore from backup"
    echo "  --clean-all       Remove all data including backups"
    echo "  --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --full-reset      # Complete database reset"
    echo "  $0 --quick-seed      # Fast data refresh"
    echo "  $0 --backup-current --full-reset  # Backup then reset"
}

# Function to backup current data
backup_current_data() {
    print_status "INFO" "Creating backup of current data..."
    
    local backup_dir="$PROJECT_ROOT/backups"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$backup_dir/backup_$timestamp.sql"
    
    mkdir -p "$backup_dir"
    
    if command_exists pg_dump; then
        if PGPASSWORD=postgres pg_dump -h localhost -p 54322 -U postgres -d postgres > "$backup_file" 2>/dev/null; then
            print_status "SUCCESS" "Data backed up to $backup_file"
            echo "$backup_file" > "$backup_dir/latest_backup.txt"
            return 0
        else
            print_status "WARNING" "pg_dump backup failed"
            return 1
        fi
    else
        print_status "WARNING" "pg_dump not available for backup"
        return 1
    fi
}

# Function to restore from backup
restore_from_backup() {
    print_status "INFO" "Restoring from backup..."
    
    local backup_dir="$PROJECT_ROOT/backups"
    local latest_backup_file
    
    if [ -f "$backup_dir/latest_backup.txt" ]; then
        latest_backup_file=$(cat "$backup_dir/latest_backup.txt")
        
        if [ -f "$latest_backup_file" ]; then
            if command_exists psql; then
                # First drop and recreate database
                PGPASSWORD=postgres psql -h localhost -p 54322 -U postgres -d postgres -c "DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;" >/dev/null 2>&1
                
                # Restore from backup
                if PGPASSWORD=postgres psql -h localhost -p 54322 -U postgres -d postgres < "$latest_backup_file" >/dev/null 2>&1; then
                    print_status "SUCCESS" "Data restored from $latest_backup_file"
                    return 0
                else
                    print_status "ERROR" "Failed to restore from backup"
                    return 1
                fi
            else
                print_status "ERROR" "psql not available for restore"
                return 1
            fi
        else
            print_status "ERROR" "Backup file not found: $latest_backup_file"
            return 1
        fi
    else
        print_status "ERROR" "No backup available to restore"
        return 1
    fi
}

# Function to perform full database reset
full_database_reset() {
    print_status "INFO" "Performing full database reset..."
    
    cd "$PROJECT_ROOT"
    
    # Method 1: Use Supabase CLI if available
    if command_exists supabase; then
        print_status "INFO" "Using Supabase CLI for reset..."
        if supabase db reset --local; then
            print_status "SUCCESS" "Database reset completed via Supabase CLI"
            
            # Apply seed data
            if supabase db seed --local; then
                print_status "SUCCESS" "Seed data applied via Supabase CLI"
                return 0
            else
                print_status "WARNING" "Seed data application failed, trying manual seed"
                quick_seed
                return $?
            fi
        else
            print_status "WARNING" "Supabase CLI reset failed, trying manual method"
        fi
    fi
    
    # Method 2: Manual reset using Docker and psql
    print_status "INFO" "Using manual reset method..."
    
    if ! docker-compose -f "$DOCKER_COMPOSE_FILE" ps | grep -q "db.*Up"; then
        print_status "INFO" "Starting database container..."
        docker-compose -f "$DOCKER_COMPOSE_FILE" up -d db
        sleep 10
    fi
    
    if command_exists psql; then
        # Drop and recreate schema
        if PGPASSWORD=postgres psql -h localhost -p 54322 -U postgres -d postgres -c "
            DROP SCHEMA IF EXISTS public CASCADE;
            CREATE SCHEMA public;
            GRANT ALL ON SCHEMA public TO postgres;
            GRANT ALL ON SCHEMA public TO public;
        " >/dev/null 2>&1; then
            print_status "SUCCESS" "Database schema reset"
            
            # Apply migrations if available
            if [ -d "$PROJECT_ROOT/supabase/migrations" ]; then
                print_status "INFO" "Applying migrations..."
                for migration_file in "$PROJECT_ROOT/supabase/migrations"/*.sql; do
                    if [ -f "$migration_file" ]; then
                        if PGPASSWORD=postgres psql -h localhost -p 54322 -U postgres -d postgres -f "$migration_file" >/dev/null 2>&1; then
                            print_status "SUCCESS" "Applied migration: $(basename "$migration_file")"
                        else
                            print_status "WARNING" "Failed to apply migration: $(basename "$migration_file")"
                        fi
                    fi
                done
            fi
            
            # Apply seed data
            quick_seed
            return $?
        else
            print_status "ERROR" "Failed to reset database schema"
            return 1
        fi
    else
        print_status "ERROR" "psql not available for manual reset"
        return 1
    fi
}

# Function to perform quick seed
quick_seed() {
    print_status "INFO" "Applying seed data..."
    
    if [ ! -f "$SEED_FILE" ]; then
        print_status "ERROR" "Seed file not found: $SEED_FILE"
        return 1
    fi
    
    if command_exists psql; then
        if PGPASSWORD=postgres psql -h localhost -p 54322 -U postgres -d postgres -f "$SEED_FILE" >/dev/null 2>&1; then
            print_status "SUCCESS" "Seed data applied successfully"
            
            # Verify seed data
            local user_count
            user_count=$(PGPASSWORD=postgres psql -h localhost -p 54322 -U postgres -d postgres -t -c "SELECT COUNT(*) FROM user_profiles;" 2>/dev/null | xargs)
            
            if [ "$user_count" -gt 0 ]; then
                print_status "SUCCESS" "Seed verification: $user_count users created"
            else
                print_status "WARNING" "Seed verification: No users found"
            fi
            
            return 0
        else
            print_status "ERROR" "Failed to apply seed data"
            return 1
        fi
    else
        print_status "ERROR" "psql not available for seeding"
        return 1
    fi
}

# Function to clean all data and backups
clean_all_data() {
    print_status "WARNING" "This will remove ALL data and backups!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "INFO" "Cleaning all data..."
        
        # Stop all services
        docker-compose -f "$DOCKER_COMPOSE_FILE" down -v
        
        # Remove volumes
        docker volume rm $(docker volume ls -q | grep "whatsapp-clone") 2>/dev/null || true
        
        # Remove backups
        rm -rf "$PROJECT_ROOT/backups"
        
        # Remove logs
        rm -rf "$PROJECT_ROOT/logs"
        
        print_status "SUCCESS" "All data and backups removed"
    else
        print_status "INFO" "Operation cancelled"
    fi
}

# Main execution logic
main() {
    echo -e "${BLUE}🗄️ Data Reset and Refresh Tool${NC}"
    echo -e "${BLUE}Project Root: $PROJECT_ROOT${NC}"
    
    # Check if docker services are running
    if ! docker-compose -f "$DOCKER_COMPOSE_FILE" ps | grep -q "Up"; then
        print_status "WARNING" "Docker services don't appear to be running"
        print_status "INFO" "Starting services..."
        docker-compose -f "$DOCKER_COMPOSE_FILE" up -d
        sleep 15
    fi
    
    case "${1:-}" in
        --full-reset)
            full_database_reset
            ;;
        --quick-seed)
            quick_seed
            ;;
        --backup-current)
            backup_current_data
            if [ "${2:-}" = "--full-reset" ]; then
                full_database_reset
            fi
            ;;
        --restore-backup)
            restore_from_backup
            ;;
        --clean-all)
            clean_all_data
            ;;
        --help)
            show_usage
            ;;
        "")
            # No arguments - show interactive menu
            echo -e "\n${YELLOW}Select an option:${NC}"
            echo "1) Full database reset"
            echo "2) Quick seed data refresh"
            echo "3) Backup current data"
            echo "4) Restore from backup"
            echo "5) Clean all data"
            echo "6) Exit"
            
            read -p "Enter your choice (1-6): " choice
            
            case $choice in
                1) full_database_reset ;;
                2) quick_seed ;;
                3) backup_current_data ;;
                4) restore_from_backup ;;
                5) clean_all_data ;;
                6) print_status "INFO" "Exiting..." ; exit 0 ;;
                *) print_status "ERROR" "Invalid choice" ; exit 1 ;;
            esac
            ;;
        *)
            print_status "ERROR" "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_status "SUCCESS" "Operation completed successfully!"
    else
        print_status "ERROR" "Operation failed!"
    fi
    
    exit $exit_code
}

# Run main function with all arguments
main "$@"