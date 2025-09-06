-- Create messaging tables for real-time chat functionality
-- This migration creates the core tables needed for messaging system

-- Enable RLS for all tables
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- Create rooms table for chat rooms (1-on-1 and group)
CREATE TABLE IF NOT EXISTS rooms (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  name text,
  description text,
  type text NOT NULL CHECK (type IN ('direct', 'group')) DEFAULT 'direct',
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  avatar_url text,
  last_message_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Create room_participants table for managing room membership
CREATE TABLE IF NOT EXISTS room_participants (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id uuid NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('admin', 'member')) DEFAULT 'member',
  joined_at timestamptz NOT NULL DEFAULT now(),
  left_at timestamptz,
  is_active boolean NOT NULL DEFAULT true,
  UNIQUE(room_id, user_id)
);

-- Create messages table for storing all messages
CREATE TABLE IF NOT EXISTS messages (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id uuid NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content text NOT NULL,
  type text NOT NULL CHECK (type IN ('text', 'image', 'file', 'audio', 'video', 'system')) DEFAULT 'text',
  reply_to uuid REFERENCES messages(id) ON DELETE SET NULL,
  metadata jsonb DEFAULT '{}',
  edited_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Create message_status table for tracking message delivery status
CREATE TABLE IF NOT EXISTS message_status (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  message_id uuid NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status text NOT NULL CHECK (status IN ('sent', 'delivered', 'read')) DEFAULT 'sent',
  timestamp timestamptz NOT NULL DEFAULT now(),
  UNIQUE(message_id, user_id)
);

-- Create message_reactions table for message reactions
CREATE TABLE IF NOT EXISTS message_reactions (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  message_id uuid NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  emoji text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(message_id, user_id, emoji)
);

-- Create typing_indicators table for real-time typing status
CREATE TABLE IF NOT EXISTS typing_indicators (
  room_id uuid NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  is_typing boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(room_id, user_id)
);

-- Create user_presence table for online status
CREATE TABLE IF NOT EXISTS user_presence (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  is_online boolean NOT NULL DEFAULT false,
  last_seen timestamptz NOT NULL DEFAULT now(),
  status text CHECK (status IN ('available', 'away', 'busy', 'invisible')) DEFAULT 'available',
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Create indexes for performance optimization
CREATE INDEX IF NOT EXISTS idx_rooms_created_by ON rooms(created_by);
CREATE INDEX IF NOT EXISTS idx_rooms_type ON rooms(type);
CREATE INDEX IF NOT EXISTS idx_rooms_last_message_at ON rooms(last_message_at DESC);

CREATE INDEX IF NOT EXISTS idx_room_participants_room_id ON room_participants(room_id);
CREATE INDEX IF NOT EXISTS idx_room_participants_user_id ON room_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_room_participants_active ON room_participants(is_active, room_id);

CREATE INDEX IF NOT EXISTS idx_messages_room_id ON messages(room_id);
CREATE INDEX IF NOT EXISTS idx_messages_user_id ON messages(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_room_created ON messages(room_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_reply_to ON messages(reply_to);

CREATE INDEX IF NOT EXISTS idx_message_status_message_id ON message_status(message_id);
CREATE INDEX IF NOT EXISTS idx_message_status_user_id ON message_status(user_id);

CREATE INDEX IF NOT EXISTS idx_message_reactions_message_id ON message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_user_id ON message_reactions(user_id);

CREATE INDEX IF NOT EXISTS idx_typing_indicators_room_id ON typing_indicators(room_id);
CREATE INDEX IF NOT EXISTS idx_typing_indicators_updated ON typing_indicators(updated_at);

-- Create triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_rooms_updated_at BEFORE UPDATE ON rooms
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON messages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_presence_updated_at BEFORE UPDATE ON user_presence
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_typing_indicators_updated_at BEFORE UPDATE ON typing_indicators
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update room's last_message_at when new message is added
CREATE OR REPLACE FUNCTION update_room_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE rooms 
    SET last_message_at = NEW.created_at 
    WHERE id = NEW.room_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_room_last_message_trigger AFTER INSERT ON messages
    FOR EACH ROW EXECUTE FUNCTION update_room_last_message();

-- Function to automatically create message status entries for all room participants
CREATE OR REPLACE FUNCTION create_message_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Create status entries for all active participants except the sender
    INSERT INTO message_status (message_id, user_id, status)
    SELECT NEW.id, rp.user_id, 'sent'
    FROM room_participants rp
    WHERE rp.room_id = NEW.room_id 
    AND rp.user_id != NEW.user_id 
    AND rp.is_active = true;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER create_message_status_trigger AFTER INSERT ON messages
    FOR EACH ROW EXECUTE FUNCTION create_message_status();