-- WhatsApp Clone Production Supabase Configuration
-- Security hardening and performance optimizations for production deployment

-- =============================================================================
-- SECURITY CONFIGURATION
-- =============================================================================

-- Enable Row Level Security (RLS) on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.files ENABLE ROW LEVEL SECURITY;

-- Create security policies for users table
CREATE POLICY "Users can only view their own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can only update their own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

-- Create security policies for chats table
CREATE POLICY "Users can only access their chats" ON public.chats
  FOR ALL USING (
    auth.uid() IN (
      SELECT unnest(participant_ids) FROM public.chats WHERE id = chats.id
    )
  );

-- Create security policies for messages table
CREATE POLICY "Users can only access messages from their chats" ON public.messages
  FOR ALL USING (
    chat_id IN (
      SELECT id FROM public.chats 
      WHERE auth.uid() = ANY(participant_ids)
    )
  );

-- Create security policies for groups table
CREATE POLICY "Users can only access groups they belong to" ON public.groups
  FOR ALL USING (
    auth.uid() IN (
      SELECT unnest(member_ids) FROM public.groups WHERE id = groups.id
    )
    OR auth.uid() = admin_id
  );

-- Create security policies for communities table
CREATE POLICY "Users can only access communities they belong to" ON public.communities
  FOR ALL USING (
    auth.uid() IN (
      SELECT unnest(member_ids) FROM public.communities WHERE id = communities.id
    )
    OR auth.uid() = admin_id
  );

-- Create security policies for files table
CREATE POLICY "Users can only access their own files" ON public.files
  FOR ALL USING (auth.uid() = user_id);

-- =============================================================================
-- STORAGE BUCKET SECURITY
-- =============================================================================

-- Create secure storage policies for user avatars bucket
CREATE POLICY "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'user-avatars' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view all avatars"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'user-avatars');

CREATE POLICY "Users can update their own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'user-avatars' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own avatar"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'user-avatars' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Create secure storage policies for chat media bucket
CREATE POLICY "Users can upload media to their chats"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'chat-media' 
    AND EXISTS (
      SELECT 1 FROM public.chats 
      WHERE id::text = (storage.foldername(name))[1]
      AND auth.uid() = ANY(participant_ids)
    )
  );

CREATE POLICY "Users can view media from their chats"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'chat-media' 
    AND EXISTS (
      SELECT 1 FROM public.chats 
      WHERE id::text = (storage.foldername(name))[1]
      AND auth.uid() = ANY(participant_ids)
    )
  );

-- =============================================================================
-- PERFORMANCE OPTIMIZATION
-- =============================================================================

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone_number);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON public.users(created_at);

CREATE INDEX IF NOT EXISTS idx_chats_participants ON public.chats USING GIN(participant_ids);
CREATE INDEX IF NOT EXISTS idx_chats_updated_at ON public.chats(updated_at);

CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON public.messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);
CREATE INDEX IF NOT EXISTS idx_messages_chat_created ON public.messages(chat_id, created_at);

CREATE INDEX IF NOT EXISTS idx_groups_members ON public.groups USING GIN(member_ids);
CREATE INDEX IF NOT EXISTS idx_groups_admin ON public.groups(admin_id);

CREATE INDEX IF NOT EXISTS idx_communities_members ON public.communities USING GIN(member_ids);
CREATE INDEX IF NOT EXISTS idx_communities_admin ON public.communities(admin_id);

CREATE INDEX IF NOT EXISTS idx_files_user_id ON public.files(user_id);
CREATE INDEX IF NOT EXISTS idx_files_chat_id ON public.files(chat_id);
CREATE INDEX IF NOT EXISTS idx_files_created_at ON public.files(created_at);

-- =============================================================================
-- CONNECTION POOLING CONFIGURATION
-- =============================================================================

-- Configure connection pooling for production workload
-- These settings should be applied to the database configuration

/*
PostgreSQL Configuration for Production:

# Connection Settings
max_connections = 200
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# Write Ahead Logging
wal_level = replica
max_wal_senders = 3
wal_keep_segments = 32
checkpoint_completion_target = 0.7

# Query Planner
random_page_cost = 1.1
effective_io_concurrency = 200

# Logging
log_statement = 'mod'
log_min_duration_statement = 1000
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
*/

-- =============================================================================
-- DATABASE FUNCTIONS FOR PERFORMANCE
-- =============================================================================

-- Function to get user's recent chats with pagination
CREATE OR REPLACE FUNCTION get_user_chats(
  user_uuid uuid,
  page_offset integer DEFAULT 0,
  page_limit integer DEFAULT 20
)
RETURNS TABLE(
  chat_id uuid,
  chat_type text,
  last_message_content text,
  last_message_time timestamptz,
  unread_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id as chat_id,
    c.type as chat_type,
    m.content as last_message_content,
    m.created_at as last_message_time,
    COUNT(unread.id) as unread_count
  FROM public.chats c
  LEFT JOIN public.messages m ON c.last_message_id = m.id
  LEFT JOIN public.messages unread ON unread.chat_id = c.id 
    AND unread.created_at > COALESCE(c.last_read_at, '1970-01-01'::timestamptz)
    AND unread.sender_id != user_uuid
  WHERE user_uuid = ANY(c.participant_ids)
  GROUP BY c.id, c.type, m.content, m.created_at
  ORDER BY c.updated_at DESC
  LIMIT page_limit
  OFFSET page_offset;
END;
$$;

-- Function to get messages for a chat with pagination
CREATE OR REPLACE FUNCTION get_chat_messages(
  chat_uuid uuid,
  user_uuid uuid,
  page_offset integer DEFAULT 0,
  page_limit integer DEFAULT 50
)
RETURNS TABLE(
  message_id uuid,
  sender_id uuid,
  content text,
  message_type text,
  file_url text,
  created_at timestamptz,
  updated_at timestamptz,
  is_edited boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if user has access to this chat
  IF NOT EXISTS (
    SELECT 1 FROM public.chats 
    WHERE id = chat_uuid AND user_uuid = ANY(participant_ids)
  ) THEN
    RAISE EXCEPTION 'Access denied to chat %', chat_uuid;
  END IF;

  RETURN QUERY
  SELECT 
    m.id as message_id,
    m.sender_id,
    m.content,
    m.type as message_type,
    f.file_url,
    m.created_at,
    m.updated_at,
    (m.updated_at > m.created_at) as is_edited
  FROM public.messages m
  LEFT JOIN public.files f ON m.file_id = f.id
  WHERE m.chat_id = chat_uuid
  ORDER BY m.created_at DESC
  LIMIT page_limit
  OFFSET page_offset;
END;
$$;

-- =============================================================================
-- REALTIME CONFIGURATION
-- =============================================================================

-- Enable realtime for critical tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chats;
ALTER PUBLICATION supabase_realtime ADD TABLE public.users;

-- =============================================================================
-- BACKUP AND MAINTENANCE
-- =============================================================================

-- Create a view for monitoring table sizes
CREATE OR REPLACE VIEW table_sizes AS
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
  pg_total_relation_size(schemaname||'.'||tablename) as size_bytes
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Function to clean up old files and messages (for maintenance)
CREATE OR REPLACE FUNCTION cleanup_old_data(
  days_threshold integer DEFAULT 90
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Clean up old temporary files
  DELETE FROM public.files 
  WHERE created_at < NOW() - INTERVAL '1 day' * days_threshold
  AND file_type = 'temporary';
  
  -- Archive old messages (move to archive table instead of deleting)
  -- This would require an archive table to be created first
  
  -- Log the cleanup
  INSERT INTO public.maintenance_log (action, details, created_at)
  VALUES ('cleanup_old_data', 'Cleaned up data older than ' || days_threshold || ' days', NOW());
END;
$$;

-- =============================================================================
-- MONITORING AND ALERTING
-- =============================================================================

-- Create a function to monitor database health
CREATE OR REPLACE FUNCTION database_health_check()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result json;
  connection_count integer;
  active_queries integer;
  slow_queries integer;
  table_count integer;
  index_usage numeric;
BEGIN
  -- Get connection count
  SELECT count(*) INTO connection_count FROM pg_stat_activity;
  
  -- Get active queries count
  SELECT count(*) INTO active_queries 
  FROM pg_stat_activity 
  WHERE state = 'active' AND query NOT ILIKE '%pg_stat_activity%';
  
  -- Get slow queries count (running > 30 seconds)
  SELECT count(*) INTO slow_queries 
  FROM pg_stat_activity 
  WHERE state = 'active' 
  AND now() - query_start > interval '30 seconds'
  AND query NOT ILIKE '%pg_stat_activity%';
  
  -- Get table count
  SELECT count(*) INTO table_count FROM pg_tables WHERE schemaname = 'public';
  
  -- Calculate index usage ratio
  SELECT 
    COALESCE(
      100 * sum(idx_scan) / NULLIF(sum(seq_scan + idx_scan), 0), 
      0
    ) INTO index_usage
  FROM pg_stat_user_tables;
  
  -- Build result JSON
  result := json_build_object(
    'timestamp', NOW(),
    'connection_count', connection_count,
    'active_queries', active_queries,
    'slow_queries', slow_queries,
    'table_count', table_count,
    'index_usage_percent', index_usage,
    'status', CASE 
      WHEN slow_queries > 5 THEN 'warning'
      WHEN connection_count > 150 THEN 'warning'
      WHEN index_usage < 80 THEN 'warning'
      ELSE 'healthy'
    END
  );
  
  RETURN result;
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_user_chats TO authenticated;
GRANT EXECUTE ON FUNCTION get_chat_messages TO authenticated;
GRANT EXECUTE ON FUNCTION database_health_check TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_old_data TO service_role;