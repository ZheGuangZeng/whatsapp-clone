-- Initial schema setup for user profiles and basic auth extensions
-- This migration creates the foundation for user management

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create user profiles table to extend auth.users
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  display_name text,
  avatar_url text,
  phone_number text,
  status_message text DEFAULT 'Available',
  is_online boolean DEFAULT false,
  last_seen timestamptz DEFAULT now(),
  notification_preferences jsonb DEFAULT '{
    "push_notifications": true,
    "email_notifications": true,
    "message_preview": true,
    "sound_enabled": true
  }'::jsonb,
  privacy_settings jsonb DEFAULT '{
    "last_seen": "everyone",
    "profile_photo": "everyone",
    "status": "everyone"
  }'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_display_name ON user_profiles(display_name);
CREATE INDEX IF NOT EXISTS idx_user_profiles_phone_number ON user_profiles(phone_number);
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_online ON user_profiles(is_online);
CREATE INDEX IF NOT EXISTS idx_user_profiles_last_seen ON user_profiles(last_seen DESC);

-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_profiles
-- Users can view all profiles (needed for chat participants)
CREATE POLICY "Users can view all profiles" ON user_profiles
  FOR SELECT USING (auth.role() = 'authenticated');

-- Users can insert their own profile
CREATE POLICY "Users can create their own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Users can delete their own profile
CREATE POLICY "Users can delete their own profile" ON user_profiles
  FOR DELETE USING (auth.uid() = id);

-- Function to handle updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- Create trigger for updated_at
CREATE TRIGGER update_user_profiles_updated_at 
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically create user profile when auth.user is created
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (
    id,
    display_name,
    avatar_url
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Enable realtime for user_profiles
ALTER PUBLICATION supabase_realtime ADD TABLE user_profiles;