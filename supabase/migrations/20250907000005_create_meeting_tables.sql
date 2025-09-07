-- Create meeting tables for LiveKit integration
-- This migration creates the tables needed for video/audio meetings

-- Create meetings table
CREATE TABLE IF NOT EXISTS meetings (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id uuid REFERENCES rooms(id) ON DELETE CASCADE,
  livekit_room_name text UNIQUE NOT NULL,
  host_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text,
  description text,
  scheduled_for timestamptz,
  started_at timestamptz,
  ended_at timestamptz,
  recording_url text,
  max_participants integer DEFAULT 100,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Create meeting_participants table
CREATE TABLE IF NOT EXISTS meeting_participants (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  meeting_id uuid NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  livekit_participant_id text,
  role text DEFAULT 'participant' CHECK (role IN ('host', 'admin', 'participant')),
  joined_at timestamptz DEFAULT now(),
  left_at timestamptz,
  connection_quality text CHECK (connection_quality IN ('excellent', 'good', 'poor', 'lost')) DEFAULT 'good',
  is_audio_enabled boolean DEFAULT true,
  is_video_enabled boolean DEFAULT true,
  is_screen_sharing boolean DEFAULT false,
  metadata jsonb DEFAULT '{}',
  UNIQUE(meeting_id, user_id)
);

-- Create meeting_invitations table
CREATE TABLE IF NOT EXISTS meeting_invitations (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  meeting_id uuid NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  inviter_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  invitee_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'cancelled')),
  invited_at timestamptz NOT NULL DEFAULT now(),
  responded_at timestamptz,
  UNIQUE(meeting_id, invitee_id)
);

-- Create meeting_recordings table
CREATE TABLE IF NOT EXISTS meeting_recordings (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  meeting_id uuid NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  livekit_egress_id text UNIQUE NOT NULL,
  file_url text,
  file_size bigint,
  duration_seconds integer,
  status text DEFAULT 'processing' CHECK (status IN ('processing', 'completed', 'failed')),
  started_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  metadata jsonb DEFAULT '{}'
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_meetings_room_id ON meetings(room_id);
CREATE INDEX IF NOT EXISTS idx_meetings_host_id ON meetings(host_id);
CREATE INDEX IF NOT EXISTS idx_meetings_livekit_room_name ON meetings(livekit_room_name);
CREATE INDEX IF NOT EXISTS idx_meetings_started_at ON meetings(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_meetings_scheduled_for ON meetings(scheduled_for);

CREATE INDEX IF NOT EXISTS idx_meeting_participants_meeting_id ON meeting_participants(meeting_id);
CREATE INDEX IF NOT EXISTS idx_meeting_participants_user_id ON meeting_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_meeting_participants_joined_at ON meeting_participants(joined_at);

CREATE INDEX IF NOT EXISTS idx_meeting_invitations_meeting_id ON meeting_invitations(meeting_id);
CREATE INDEX IF NOT EXISTS idx_meeting_invitations_invitee_id ON meeting_invitations(invitee_id);
CREATE INDEX IF NOT EXISTS idx_meeting_invitations_status ON meeting_invitations(status);

CREATE INDEX IF NOT EXISTS idx_meeting_recordings_meeting_id ON meeting_recordings(meeting_id);
CREATE INDEX IF NOT EXISTS idx_meeting_recordings_status ON meeting_recordings(status);

-- Add updated_at triggers
CREATE TRIGGER update_meetings_updated_at BEFORE UPDATE ON meetings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to generate unique LiveKit room names
CREATE OR REPLACE FUNCTION generate_livekit_room_name()
RETURNS text AS $$
BEGIN
    RETURN 'meeting_' || replace(gen_random_uuid()::text, '-', '');
END;
$$ LANGUAGE plpgsql;

-- Function to automatically set LiveKit room name if not provided
CREATE OR REPLACE FUNCTION set_livekit_room_name()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.livekit_room_name IS NULL OR NEW.livekit_room_name = '' THEN
        NEW.livekit_room_name = generate_livekit_room_name();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_livekit_room_name_trigger BEFORE INSERT ON meetings
    FOR EACH ROW EXECUTE FUNCTION set_livekit_room_name();

-- Function to automatically add host as participant when meeting is created
CREATE OR REPLACE FUNCTION add_host_as_participant()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO meeting_participants (meeting_id, user_id, role, joined_at)
    VALUES (NEW.id, NEW.host_id, 'host', NEW.created_at);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER add_host_as_participant_trigger AFTER INSERT ON meetings
    FOR EACH ROW EXECUTE FUNCTION add_host_as_participant();

-- Enable RLS on all meeting tables
ALTER TABLE meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE meeting_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE meeting_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE meeting_recordings ENABLE ROW LEVEL SECURITY;