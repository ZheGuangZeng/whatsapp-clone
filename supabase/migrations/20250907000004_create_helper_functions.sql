-- Helper functions for chat operations
-- These functions provide efficient database operations for the chat system

-- Function to get shared rooms between two users (for direct messages)
CREATE OR REPLACE FUNCTION get_shared_rooms(user1 uuid, user2 uuid)
RETURNS TABLE(room_id uuid)
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT rp1.room_id
  FROM room_participants rp1
  JOIN room_participants rp2 ON rp1.room_id = rp2.room_id
  JOIN rooms r ON rp1.room_id = r.id
  WHERE rp1.user_id = user1 
    AND rp2.user_id = user2 
    AND rp1.is_active = true 
    AND rp2.is_active = true
    AND r.type = 'direct';
$$;

-- Function to mark all messages in a room as read for a user
CREATE OR REPLACE FUNCTION mark_room_messages_read(room_id_param uuid, user_id_param uuid)
RETURNS void
LANGUAGE SQL
SECURITY DEFINER
AS $$
  INSERT INTO message_status (message_id, user_id, status, timestamp)
  SELECT m.id, user_id_param, 'read', now()
  FROM messages m
  LEFT JOIN message_status ms ON m.id = ms.message_id AND ms.user_id = user_id_param
  WHERE m.room_id = room_id_param 
    AND m.user_id != user_id_param 
    AND m.deleted_at IS NULL
    AND (ms.status IS NULL OR ms.status != 'read')
  ON CONFLICT (message_id, user_id) 
  DO UPDATE SET status = 'read', timestamp = now();
$$;

-- Function to get unread message count for a room and user
CREATE OR REPLACE FUNCTION get_unread_count(room_id_param uuid, user_id_param uuid)
RETURNS integer
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT CAST(COUNT(*) AS integer)
  FROM messages m
  LEFT JOIN message_status ms ON m.id = ms.message_id AND ms.user_id = user_id_param
  WHERE m.room_id = room_id_param 
    AND m.user_id != user_id_param 
    AND m.deleted_at IS NULL
    AND (ms.status IS NULL OR ms.status != 'read');
$$;

-- Function to get room statistics
CREATE OR REPLACE FUNCTION get_room_stats(room_id_param uuid)
RETURNS TABLE(
  message_count bigint,
  participant_count bigint,
  last_activity timestamptz
)
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT 
    (SELECT COUNT(*) FROM messages WHERE room_id = room_id_param AND deleted_at IS NULL) as message_count,
    (SELECT COUNT(*) FROM room_participants WHERE room_id = room_id_param AND is_active = true) as participant_count,
    (SELECT MAX(created_at) FROM messages WHERE room_id = room_id_param AND deleted_at IS NULL) as last_activity;
$$;

-- Function to cleanup old typing indicators (remove stale typing status)
CREATE OR REPLACE FUNCTION cleanup_typing_indicators()
RETURNS void
LANGUAGE SQL
SECURITY DEFINER
AS $$
  UPDATE typing_indicators 
  SET is_typing = false 
  WHERE is_typing = true 
    AND updated_at < now() - interval '10 seconds';
$$;

-- Function to update user presence when they go offline
CREATE OR REPLACE FUNCTION update_user_offline_presence(user_id_param uuid)
RETURNS void
LANGUAGE SQL
SECURITY DEFINER
AS $$
  INSERT INTO user_presence (user_id, is_online, last_seen, status)
  VALUES (user_id_param, false, now(), 'available')
  ON CONFLICT (user_id)
  DO UPDATE SET 
    is_online = false,
    last_seen = now(),
    updated_at = now();
$$;

-- Function to get typing users in a room (excluding self)
CREATE OR REPLACE FUNCTION get_typing_users(room_id_param uuid, exclude_user_id uuid)
RETURNS TABLE(
  user_id uuid,
  display_name text,
  is_typing boolean,
  updated_at timestamptz
)
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT 
    ti.user_id,
    COALESCE(up.display_name, u.email, 'Unknown User') as display_name,
    ti.is_typing,
    ti.updated_at
  FROM typing_indicators ti
  JOIN auth.users u ON ti.user_id = u.id
  LEFT JOIN user_profiles up ON ti.user_id = up.id
  WHERE ti.room_id = room_id_param 
    AND ti.user_id != exclude_user_id
    AND ti.is_typing = true
    AND ti.updated_at > now() - interval '10 seconds';
$$;

-- Function to get user presence for multiple users
CREATE OR REPLACE FUNCTION get_users_presence(user_ids uuid[])
RETURNS TABLE(
  user_id uuid,
  is_online boolean,
  last_seen timestamptz,
  status text,
  updated_at timestamptz
)
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT 
    up.user_id,
    up.is_online,
    up.last_seen,
    up.status,
    up.updated_at
  FROM user_presence up
  WHERE up.user_id = ANY(user_ids);
$$;

-- Function to search messages across all user's rooms
CREATE OR REPLACE FUNCTION search_user_messages(search_user_id uuid, search_query text)
RETURNS TABLE(
  id uuid,
  room_id uuid,
  user_id uuid,
  content text,
  type text,
  reply_to uuid,
  metadata jsonb,
  edited_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz,
  room_name text,
  room_type text
)
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT 
    m.id,
    m.room_id,
    m.user_id,
    m.content,
    m.type,
    m.reply_to,
    m.metadata,
    m.edited_at,
    m.created_at,
    m.updated_at,
    r.name as room_name,
    r.type as room_type
  FROM messages m
  JOIN rooms r ON m.room_id = r.id
  JOIN room_participants rp ON r.id = rp.room_id
  WHERE rp.user_id = search_user_id 
    AND rp.is_active = true
    AND m.deleted_at IS NULL
    AND m.content ILIKE '%' || search_query || '%'
  ORDER BY m.created_at DESC;
$$;

-- Create a scheduled job to cleanup old typing indicators (if pg_cron is available)
-- This would typically be set up separately in the Supabase dashboard
-- SELECT cron.schedule('cleanup-typing', '*/30 * * * * *', 'SELECT cleanup_typing_indicators();');

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_shared_rooms(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION mark_room_messages_read(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_unread_count(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_room_stats(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_typing_indicators() TO authenticated;
GRANT EXECUTE ON FUNCTION update_user_offline_presence(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_typing_users(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_users_presence(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION search_user_messages(uuid, text) TO authenticated;