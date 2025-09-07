#!/bin/bash
set -e

# WhatsApp Clone - Production Supabase Setup Script
# This script configures Supabase for production deployment with security and performance optimizations

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PRIMARY_PROJECT_REF="${SUPABASE_PRIMARY_PROJECT_REF:-}"
SECONDARY_PROJECT_REF="${SUPABASE_SECONDARY_PROJECT_REF:-}"
DATABASE_PASSWORD="${SUPABASE_DB_PASSWORD:-}"

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

check_requirements() {
    log "Checking requirements..."
    
    # Check if Supabase CLI is installed
    if ! command -v supabase &> /dev/null; then
        error "Supabase CLI is not installed. Please install it first: https://supabase.com/docs/guides/cli"
    fi
    
    # Check if required environment variables are set
    if [[ -z "$PRIMARY_PROJECT_REF" ]]; then
        error "SUPABASE_PRIMARY_PROJECT_REF environment variable is required"
    fi
    
    if [[ -z "$DATABASE_PASSWORD" ]]; then
        error "SUPABASE_DB_PASSWORD environment variable is required"
    fi
    
    success "Requirements check passed"
}

setup_primary_region() {
    log "Setting up primary region (Singapore)..."
    
    # Link to primary project
    if ! supabase link --project-ref "$PRIMARY_PROJECT_REF"; then
        error "Failed to link to primary Supabase project"
    fi
    
    # Run database migrations
    log "Running database migrations on primary region..."
    if ! supabase db push; then
        error "Failed to push database schema to primary region"
    fi
    
    # Apply production security configuration
    log "Applying production security configuration..."
    if ! supabase db reset --db-url "postgresql://postgres:$DATABASE_PASSWORD@db.$PRIMARY_PROJECT_REF.supabase.co:5432/postgres" --linked; then
        warning "Failed to reset database, continuing with manual configuration..."
    fi
    
    # Execute production configuration SQL
    log "Executing production configuration..."
    if ! psql "postgresql://postgres:$DATABASE_PASSWORD@db.$PRIMARY_PROJECT_REF.supabase.co:5432/postgres" -f infrastructure/supabase/production-config.sql; then
        error "Failed to execute production configuration SQL"
    fi
    
    success "Primary region setup completed"
}

setup_secondary_region() {
    if [[ -z "$SECONDARY_PROJECT_REF" ]]; then
        warning "Secondary project ref not provided, skipping secondary region setup"
        return 0
    fi
    
    log "Setting up secondary region (Japan)..."
    
    # Link to secondary project
    if ! supabase link --project-ref "$SECONDARY_PROJECT_REF"; then
        error "Failed to link to secondary Supabase project"
    fi
    
    # Run database migrations
    log "Running database migrations on secondary region..."
    if ! supabase db push; then
        error "Failed to push database schema to secondary region"
    fi
    
    # Apply production security configuration
    log "Applying production security configuration to secondary region..."
    if ! psql "postgresql://postgres:$DATABASE_PASSWORD@db.$SECONDARY_PROJECT_REF.supabase.co:5432/postgres" -f infrastructure/supabase/production-config.sql; then
        error "Failed to execute production configuration SQL on secondary region"
    fi
    
    success "Secondary region setup completed"
}

create_storage_buckets() {
    log "Creating storage buckets..."
    
    # Create storage buckets using Supabase CLI or SQL commands
    buckets=("user-avatars" "chat-media" "message-attachments" "thumbnails")
    
    for bucket in "${buckets[@]}"; do
        log "Creating bucket: $bucket"
        
        # Create bucket SQL
        cat << EOF | psql "postgresql://postgres:$DATABASE_PASSWORD@db.$PRIMARY_PROJECT_REF.supabase.co:5432/postgres"
INSERT INTO storage.buckets (id, name, public)
VALUES ('$bucket', '$bucket', true)
ON CONFLICT (id) DO NOTHING;
EOF
        
        if [[ -n "$SECONDARY_PROJECT_REF" ]]; then
            cat << EOF | psql "postgresql://postgres:$DATABASE_PASSWORD@db.$SECONDARY_PROJECT_REF.supabase.co:5432/postgres"
INSERT INTO storage.buckets (id, name, public)
VALUES ('$bucket', '$bucket', true)
ON CONFLICT (id) DO NOTHING;
EOF
        fi
    done
    
    success "Storage buckets created"
}

configure_realtime() {
    log "Configuring realtime subscriptions..."
    
    # Enable realtime for specific tables
    tables=("users" "chats" "messages" "groups" "communities")
    
    for table in "${tables[@]}"; do
        log "Enabling realtime for table: $table"
        
        cat << EOF | psql "postgresql://postgres:$DATABASE_PASSWORD@db.$PRIMARY_PROJECT_REF.supabase.co:5432/postgres"
-- Enable realtime for $table
ALTER PUBLICATION supabase_realtime ADD TABLE public.$table;
EOF
        
        if [[ -n "$SECONDARY_PROJECT_REF" ]]; then
            cat << EOF | psql "postgresql://postgres:$DATABASE_PASSWORD@db.$SECONDARY_PROJECT_REF.supabase.co:5432/postgres"
-- Enable realtime for $table
ALTER PUBLICATION supabase_realtime ADD TABLE public.$table;
EOF
        fi
    done
    
    success "Realtime configuration completed"
}

setup_edge_functions() {
    log "Deploying edge functions..."
    
    # Deploy edge functions if they exist
    if [[ -d "supabase/functions" ]]; then
        if ! supabase functions deploy; then
            warning "Failed to deploy some edge functions, continuing..."
        else
            success "Edge functions deployed successfully"
        fi
    else
        warning "No edge functions directory found, skipping..."
    fi
}

verify_setup() {
    log "Verifying production setup..."
    
    # Test database connection
    if ! psql "postgresql://postgres:$DATABASE_PASSWORD@db.$PRIMARY_PROJECT_REF.supabase.co:5432/postgres" -c "SELECT 1;" > /dev/null; then
        error "Failed to connect to primary database"
    fi
    
    if [[ -n "$SECONDARY_PROJECT_REF" ]]; then
        if ! psql "postgresql://postgres:$DATABASE_PASSWORD@db.$SECONDARY_PROJECT_REF.supabase.co:5432/postgres" -c "SELECT 1;" > /dev/null; then
            error "Failed to connect to secondary database"
        fi
    fi
    
    # Test basic functionality
    log "Running database health check..."
    cat << 'EOF' | psql "postgresql://postgres:$DATABASE_PASSWORD@db.$PRIMARY_PROJECT_REF.supabase.co:5432/postgres"
SELECT database_health_check();
EOF
    
    success "Production setup verification completed"
}

setup_monitoring() {
    log "Setting up production monitoring..."
    
    # Create monitoring views and functions
    cat << 'EOF' | psql "postgresql://postgres:$DATABASE_PASSWORD@db.$PRIMARY_PROJECT_REF.supabase.co:5432/postgres"
-- Create maintenance log table
CREATE TABLE IF NOT EXISTS public.maintenance_log (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    action text NOT NULL,
    details text,
    created_at timestamptz DEFAULT now()
);

-- Create performance monitoring view
CREATE OR REPLACE VIEW performance_metrics AS
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    CASE 
        WHEN seq_scan + idx_scan > 0 
        THEN round(100.0 * idx_scan / (seq_scan + idx_scan), 2)
        ELSE 0 
    END as index_usage_percent
FROM pg_stat_user_tables
ORDER BY seq_scan + idx_scan DESC;
EOF
    
    success "Monitoring setup completed"
}

main() {
    log "Starting WhatsApp Clone production Supabase setup..."
    
    check_requirements
    setup_primary_region
    setup_secondary_region
    create_storage_buckets
    configure_realtime
    setup_edge_functions
    setup_monitoring
    verify_setup
    
    success "Production Supabase setup completed successfully!"
    
    log "Next steps:"
    log "1. Update your environment variables with the production credentials"
    log "2. Configure your CDN to point to the Supabase storage URLs"
    log "3. Set up monitoring and alerting for the database"
    log "4. Schedule regular backups using the cleanup_old_data function"
    
    log "Production URLs:"
    log "Primary (Singapore): https://$PRIMARY_PROJECT_REF.supabase.co"
    if [[ -n "$SECONDARY_PROJECT_REF" ]]; then
        log "Secondary (Japan): https://$SECONDARY_PROJECT_REF.supabase.co"
    fi
}

# Run the main function
main "$@"