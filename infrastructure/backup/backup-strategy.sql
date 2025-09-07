-- WhatsApp Clone - Production Backup and Recovery Strategy
-- Comprehensive backup procedures for Supabase PostgreSQL database

-- =============================================================================
-- BACKUP CONFIGURATION
-- =============================================================================

-- Create backup schema for storing backup metadata
CREATE SCHEMA IF NOT EXISTS backup;

-- Create backup history table
CREATE TABLE IF NOT EXISTS backup.backup_history (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    backup_type text NOT NULL CHECK (backup_type IN ('full', 'incremental', 'schema', 'data')),
    backup_location text NOT NULL,
    backup_size_bytes bigint,
    start_time timestamptz NOT NULL DEFAULT now(),
    end_time timestamptz,
    status text NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'completed', 'failed')),
    error_message text,
    tables_backed_up text[],
    checksum text,
    compression_ratio numeric(5,2),
    created_by text DEFAULT current_user,
    backup_version text DEFAULT '1.0'
);

-- Create backup configuration table
CREATE TABLE IF NOT EXISTS backup.backup_config (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    config_name text UNIQUE NOT NULL,
    backup_type text NOT NULL,
    schedule_cron text,
    retention_days integer NOT NULL DEFAULT 30,
    compression_enabled boolean DEFAULT true,
    encryption_enabled boolean DEFAULT true,
    s3_bucket text,
    s3_prefix text,
    enabled boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Insert default backup configurations
INSERT INTO backup.backup_config (config_name, backup_type, schedule_cron, retention_days, s3_bucket, s3_prefix)
VALUES 
    ('daily_full', 'full', '0 2 * * *', 30, 'whatsapp-clone-prod-backups', 'daily/'),
    ('hourly_incremental', 'incremental', '0 * * * *', 7, 'whatsapp-clone-prod-backups', 'hourly/'),
    ('weekly_archive', 'full', '0 2 * * 0', 365, 'whatsapp-clone-prod-backups', 'weekly/'),
    ('schema_only', 'schema', '0 1 * * *', 90, 'whatsapp-clone-prod-backups', 'schema/')
ON CONFLICT (config_name) DO NOTHING;

-- =============================================================================
-- BACKUP PROCEDURES
-- =============================================================================

-- Function to create full database backup
CREATE OR REPLACE FUNCTION backup.create_full_backup(
    backup_name text DEFAULT NULL,
    s3_location text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    backup_id uuid;
    backup_start timestamptz;
    table_list text[];
    backup_file text;
    checksum_value text;
BEGIN
    -- Generate backup ID and start time
    backup_id := gen_random_uuid();
    backup_start := now();
    backup_file := COALESCE(backup_name, 'full_backup_' || to_char(backup_start, 'YYYY_MM_DD_HH24_MI_SS'));
    
    -- Get list of all tables to backup
    SELECT array_agg(schemaname || '.' || tablename)
    INTO table_list
    FROM pg_tables
    WHERE schemaname IN ('public', 'auth', 'storage');
    
    -- Insert backup record
    INSERT INTO backup.backup_history (
        id, backup_type, backup_location, start_time, tables_backed_up, status
    ) VALUES (
        backup_id, 'full', COALESCE(s3_location, backup_file), backup_start, table_list, 'running'
    );
    
    -- Log backup start
    RAISE NOTICE 'Starting full backup with ID: %', backup_id;
    
    -- Note: Actual backup logic would integrate with external tools
    -- This is a framework for tracking backup operations
    
    RETURN backup_id;
END;
$$;

-- Function to verify backup integrity
CREATE OR REPLACE FUNCTION backup.verify_backup_integrity(
    backup_id_param uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    backup_record RECORD;
    is_valid boolean := false;
BEGIN
    -- Get backup record
    SELECT * INTO backup_record
    FROM backup.backup_history
    WHERE id = backup_id_param;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Backup with ID % not found', backup_id_param;
    END IF;
    
    -- Verify backup exists and is accessible
    -- This would integrate with S3 or other storage systems
    
    -- For now, mark as valid if backup completed successfully
    is_valid := backup_record.status = 'completed' AND backup_record.end_time IS NOT NULL;
    
    -- Log verification result
    INSERT INTO backup.backup_history (backup_type, backup_location, start_time, status)
    VALUES ('verification', 'verify_' || backup_id_param::text, now(), 
            CASE WHEN is_valid THEN 'completed' ELSE 'failed' END);
    
    RETURN is_valid;
END;
$$;

-- Function to clean up old backups based on retention policy
CREATE OR REPLACE FUNCTION backup.cleanup_old_backups(
    config_name_param text DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    config_record RECORD;
    cleanup_count integer := 0;
    cutoff_date timestamptz;
BEGIN
    -- Process all configs if none specified
    FOR config_record IN 
        SELECT * FROM backup.backup_config 
        WHERE (config_name_param IS NULL OR config_name = config_name_param)
        AND enabled = true
    LOOP
        -- Calculate cutoff date
        cutoff_date := now() - (config_record.retention_days || ' days')::interval;
        
        -- Mark old backups for deletion
        UPDATE backup.backup_history
        SET status = 'expired'
        WHERE backup_type = config_record.backup_type
        AND start_time < cutoff_date
        AND status = 'completed';
        
        GET DIAGNOSTICS cleanup_count = ROW_COUNT;
        
        RAISE NOTICE 'Marked % old backups for cleanup (config: %)', cleanup_count, config_record.config_name;
    END LOOP;
    
    RETURN cleanup_count;
END;
$$;

-- =============================================================================
-- DISASTER RECOVERY PROCEDURES
-- =============================================================================

-- Function to initiate disaster recovery
CREATE OR REPLACE FUNCTION backup.initiate_disaster_recovery(
    backup_id_param uuid,
    recovery_target_time timestamptz DEFAULT NULL,
    recovery_mode text DEFAULT 'full'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    recovery_id uuid;
    backup_record RECORD;
    recovery_start timestamptz;
BEGIN
    recovery_id := gen_random_uuid();
    recovery_start := now();
    
    -- Validate backup exists and is valid
    SELECT * INTO backup_record
    FROM backup.backup_history
    WHERE id = backup_id_param AND status = 'completed';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Valid backup with ID % not found', backup_id_param;
    END IF;
    
    -- Create recovery tracking record
    INSERT INTO backup.backup_history (
        id, backup_type, backup_location, start_time, status
    ) VALUES (
        recovery_id, 'recovery', 'recovery_from_' || backup_id_param::text, recovery_start, 'running'
    );
    
    -- Log recovery initiation
    RAISE NOTICE 'Disaster recovery initiated with ID: %', recovery_id;
    RAISE NOTICE 'Recovering from backup: %', backup_id_param;
    RAISE NOTICE 'Recovery mode: %', recovery_mode;
    
    IF recovery_target_time IS NOT NULL THEN
        RAISE NOTICE 'Target recovery time: %', recovery_target_time;
    END IF;
    
    RETURN recovery_id;
END;
$$;

-- Function to validate database health after recovery
CREATE OR REPLACE FUNCTION backup.validate_recovery_health()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    health_result json;
    table_count integer;
    user_count integer;
    message_count integer;
    chat_count integer;
    index_issues integer;
BEGIN
    -- Count key tables
    SELECT count(*) INTO table_count FROM pg_tables WHERE schemaname = 'public';
    SELECT count(*) INTO user_count FROM public.users;
    SELECT count(*) INTO message_count FROM public.messages;
    SELECT count(*) INTO chat_count FROM public.chats;
    
    -- Check for index issues
    SELECT count(*) INTO index_issues
    FROM pg_stat_user_indexes
    WHERE idx_scan = 0 AND schemaname = 'public';
    
    -- Build health report
    health_result := json_build_object(
        'timestamp', now(),
        'table_count', table_count,
        'user_count', user_count,
        'message_count', message_count,
        'chat_count', chat_count,
        'index_issues', index_issues,
        'database_size', pg_database_size(current_database()),
        'status', CASE 
            WHEN table_count > 5 AND user_count > 0 THEN 'healthy'
            ELSE 'unhealthy'
        END
    );
    
    -- Log health check
    INSERT INTO backup.backup_history (backup_type, backup_location, start_time, status)
    VALUES ('health_check', health_result::text, now(), 'completed');
    
    RETURN health_result;
END;
$$;

-- =============================================================================
-- POINT-IN-TIME RECOVERY
-- =============================================================================

-- Function to create point-in-time recovery checkpoint
CREATE OR REPLACE FUNCTION backup.create_pitr_checkpoint(
    checkpoint_name text DEFAULT NULL
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    checkpoint_id text;
    current_lsn text;
BEGIN
    checkpoint_id := COALESCE(checkpoint_name, 'checkpoint_' || to_char(now(), 'YYYY_MM_DD_HH24_MI_SS'));
    
    -- Get current WAL LSN
    SELECT pg_current_wal_lsn()::text INTO current_lsn;
    
    -- Create checkpoint record
    INSERT INTO backup.backup_history (
        backup_type, backup_location, start_time, status, checksum
    ) VALUES (
        'checkpoint', checkpoint_id, now(), 'completed', current_lsn
    );
    
    RAISE NOTICE 'PITR checkpoint created: % at LSN: %', checkpoint_id, current_lsn;
    
    RETURN checkpoint_id;
END;
$$;

-- =============================================================================
-- MONITORING AND ALERTS
-- =============================================================================

-- View for backup monitoring dashboard
CREATE OR REPLACE VIEW backup.backup_dashboard AS
SELECT 
    DATE(start_time) as backup_date,
    backup_type,
    COUNT(*) as backup_count,
    COUNT(*) FILTER (WHERE status = 'completed') as successful_backups,
    COUNT(*) FILTER (WHERE status = 'failed') as failed_backups,
    AVG(EXTRACT(EPOCH FROM (end_time - start_time))/60) as avg_duration_minutes,
    SUM(backup_size_bytes) as total_backup_size,
    MAX(end_time) as last_backup_time
FROM backup.backup_history
WHERE start_time >= now() - interval '30 days'
GROUP BY DATE(start_time), backup_type
ORDER BY backup_date DESC, backup_type;

-- Function to check for backup failures and send alerts
CREATE OR REPLACE FUNCTION backup.check_backup_health()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    failed_backups integer;
    missing_backups integer;
    alert_message text := '';
    last_successful_backup timestamptz;
BEGIN
    -- Check for failed backups in last 24 hours
    SELECT COUNT(*) INTO failed_backups
    FROM backup.backup_history
    WHERE start_time >= now() - interval '24 hours'
    AND status = 'failed';
    
    -- Check for missing daily backups
    SELECT MAX(end_time) INTO last_successful_backup
    FROM backup.backup_history
    WHERE backup_type = 'full'
    AND status = 'completed';
    
    -- Build alert message
    IF failed_backups > 0 THEN
        alert_message := alert_message || failed_backups || ' failed backups in last 24 hours. ';
    END IF;
    
    IF last_successful_backup < now() - interval '36 hours' THEN
        alert_message := alert_message || 'No successful full backup in last 36 hours. ';
    END IF;
    
    IF alert_message = '' THEN
        alert_message := 'All backup systems healthy';
    END IF;
    
    -- Log health check
    INSERT INTO backup.backup_history (backup_type, backup_location, start_time, status, error_message)
    VALUES ('health_check', 'backup_health_check', now(), 
            CASE WHEN alert_message = 'All backup systems healthy' THEN 'completed' ELSE 'failed' END,
            CASE WHEN alert_message != 'All backup systems healthy' THEN alert_message ELSE NULL END);
    
    RETURN alert_message;
END;
$$;

-- =============================================================================
-- PERMISSIONS AND SECURITY
-- =============================================================================

-- Grant permissions to service role for automated backups
GRANT USAGE ON SCHEMA backup TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA backup TO service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA backup TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA backup TO service_role;

-- Grant read permissions to monitoring tools
GRANT SELECT ON backup.backup_dashboard TO authenticated;
GRANT EXECUTE ON FUNCTION backup.check_backup_health TO authenticated;

-- Create backup operator role
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'backup_operator') THEN
        CREATE ROLE backup_operator;
    END IF;
END
$$;

GRANT USAGE ON SCHEMA backup TO backup_operator;
GRANT ALL ON ALL TABLES IN SCHEMA backup TO backup_operator;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA backup TO backup_operator;