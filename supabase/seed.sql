-- Comprehensive seed data for WhatsApp Clone testing
-- This script creates realistic test data for all features
-- Run this after migrations are complete

-- Clear existing data (in reverse dependency order)
DELETE FROM message_reactions;
DELETE FROM message_status;
DELETE FROM messages;
DELETE FROM typing_indicators;
DELETE FROM user_presence;
DELETE FROM room_participants;
DELETE FROM rooms;
DELETE FROM meeting_recordings;
DELETE FROM meeting_invitations;
DELETE FROM meeting_participants;
DELETE FROM meetings;
DELETE FROM user_profiles;

-- Reset sequences (if any auto-increment columns exist)
-- This helps ensure consistent test data across runs

-- Create test users (these will be created in auth.users by the application)
-- We'll reference these UUIDs in our seed data
-- User IDs are deterministic for consistent testing

-- Test Users Data
INSERT INTO user_profiles (id, display_name, avatar_url, phone_number, status_message, is_online, last_seen, notification_preferences, privacy_settings) VALUES
-- Active users for testing
('00000000-0000-0000-0000-000000000001', 'Alice Johnson', 'https://i.pravatar.cc/150?u=alice', '+1234567890', 'Available for chat!', true, now() - interval '5 minutes', '{"push_notifications": true, "email_notifications": true, "message_preview": true, "sound_enabled": true}', '{"last_seen": "everyone", "profile_photo": "everyone", "status": "everyone"}'),
('00000000-0000-0000-0000-000000000002', 'Bob Smith', 'https://i.pravatar.cc/150?u=bob', '+1234567891', 'Working from home', true, now() - interval '2 minutes', '{"push_notifications": true, "email_notifications": false, "message_preview": true, "sound_enabled": true}', '{"last_seen": "contacts", "profile_photo": "everyone", "status": "everyone"}'),
('00000000-0000-0000-0000-000000000003', 'Carol Davis', 'https://i.pravatar.cc/150?u=carol', '+1234567892', 'In a meeting', false, now() - interval '1 hour', '{"push_notifications": false, "email_notifications": true, "message_preview": false, "sound_enabled": false}', '{"last_seen": "nobody", "profile_photo": "contacts", "status": "contacts"}'),
('00000000-0000-0000-0000-000000000004', 'David Wilson', 'https://i.pravatar.cc/150?u=david', '+1234567893', 'On vacation 🏖️', false, now() - interval '3 hours', '{"push_notifications": true, "email_notifications": true, "message_preview": true, "sound_enabled": true}', '{"last_seen": "everyone", "profile_photo": "everyone", "status": "everyone"}'),
('00000000-0000-0000-0000-000000000005', 'Emma Brown', 'https://i.pravatar.cc/150?u=emma', '+1234567894', 'Love coffee ☕', true, now() - interval '10 minutes', '{"push_notifications": true, "email_notifications": true, "message_preview": true, "sound_enabled": true}', '{"last_seen": "everyone", "profile_photo": "everyone", "status": "everyone"}'),
('00000000-0000-0000-0000-000000000006', 'Frank Miller', 'https://i.pravatar.cc/150?u=frank', '+1234567895', 'Gym time 💪', false, now() - interval '30 minutes', '{"push_notifications": true, "email_notifications": false, "message_preview": true, "sound_enabled": false}', '{"last_seen": "everyone", "profile_photo": "everyone", "status": "everyone"}'),
-- Additional users for group testing
('00000000-0000-0000-0000-000000000007', 'Grace Lee', 'https://i.pravatar.cc/150?u=grace', '+1234567896', 'Always learning 📚', true, now() - interval '1 minute', '{"push_notifications": true, "email_notifications": true, "message_preview": true, "sound_enabled": true}', '{"last_seen": "everyone", "profile_photo": "everyone", "status": "everyone"}'),
('00000000-0000-0000-0000-000000000008', 'Henry Chen', 'https://i.pravatar.cc/150?u=henry', '+1234567897', 'Code & Coffee', false, now() - interval '2 hours', '{"push_notifications": true, "email_notifications": true, "message_preview": false, "sound_enabled": true}', '{"last_seen": "contacts", "profile_photo": "everyone", "status": "contacts"}');

-- Create user presence entries
INSERT INTO user_presence (user_id, is_online, last_seen, status) VALUES
('00000000-0000-0000-0000-000000000001', true, now() - interval '5 minutes', 'available'),
('00000000-0000-0000-0000-000000000002', true, now() - interval '2 minutes', 'available'),
('00000000-0000-0000-0000-000000000003', false, now() - interval '1 hour', 'busy'),
('00000000-0000-0000-0000-000000000004', false, now() - interval '3 hours', 'away'),
('00000000-0000-0000-0000-000000000005', true, now() - interval '10 minutes', 'available'),
('00000000-0000-0000-0000-000000000006', false, now() - interval '30 minutes', 'available'),
('00000000-0000-0000-0000-000000000007', true, now() - interval '1 minute', 'available'),
('00000000-0000-0000-0000-000000000008', false, now() - interval '2 hours', 'busy');

-- Create test rooms (direct and group chats)
INSERT INTO rooms (id, name, description, type, created_by, avatar_url, last_message_at, created_at) VALUES
-- Direct message rooms
('10000000-0000-0000-0000-000000000001', NULL, NULL, 'direct', '00000000-0000-0000-0000-000000000001', NULL, now() - interval '5 minutes', now() - interval '2 days'),
('10000000-0000-0000-0000-000000000002', NULL, NULL, 'direct', '00000000-0000-0000-0000-000000000001', NULL, now() - interval '1 hour', now() - interval '1 day'),
('10000000-0000-0000-0000-000000000003', NULL, NULL, 'direct', '00000000-0000-0000-0000-000000000002', NULL, now() - interval '30 minutes', now() - interval '3 hours'),
-- Group rooms
('10000000-0000-0000-0000-000000000004', 'Development Team', 'Our awesome dev team chat', 'group', '00000000-0000-0000-0000-000000000001', 'https://i.pravatar.cc/150?u=devteam', now() - interval '2 minutes', now() - interval '1 week'),
('10000000-0000-0000-0000-000000000005', 'Coffee Lovers ☕', 'For all the coffee enthusiasts', 'group', '00000000-0000-0000-0000-000000000005', 'https://i.pravatar.cc/150?u=coffee', now() - interval '15 minutes', now() - interval '3 days'),
('10000000-0000-0000-0000-000000000006', 'Weekend Plans', 'Planning fun weekend activities', 'group', '00000000-0000-0000-0000-000000000003', 'https://i.pravatar.cc/150?u=weekend', now() - interval '45 minutes', now() - interval '2 days');

-- Create room participants
INSERT INTO room_participants (room_id, user_id, role, joined_at, is_active) VALUES
-- Direct room 1: Alice & Bob
('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'member', now() - interval '2 days', true),
('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'member', now() - interval '2 days', true),
-- Direct room 2: Alice & Carol
('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'member', now() - interval '1 day', true),
('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000003', 'member', now() - interval '1 day', true),
-- Direct room 3: Bob & David
('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000002', 'member', now() - interval '3 hours', true),
('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000004', 'member', now() - interval '3 hours', true),
-- Group room 4: Development Team
('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'admin', now() - interval '1 week', true),
('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000002', 'member', now() - interval '1 week', true),
('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000007', 'member', now() - interval '6 days', true),
('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000008', 'member', now() - interval '5 days', true),
-- Group room 5: Coffee Lovers
('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000005', 'admin', now() - interval '3 days', true),
('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 'member', now() - interval '3 days', true),
('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000007', 'member', now() - interval '2 days', true),
-- Group room 6: Weekend Plans
('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000003', 'admin', now() - interval '2 days', true),
('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000004', 'member', now() - interval '2 days', true),
('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000005', 'member', now() - interval '2 days', true),
('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000006', 'member', now() - interval '1 day', true);

-- Create test messages with various types and realistic conversation flow
INSERT INTO messages (id, room_id, user_id, content, type, reply_to, metadata, created_at) VALUES
-- Direct messages: Alice & Bob (recent active conversation)
('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Hey Bob! How are you doing?', 'text', NULL, '{}', now() - interval '2 hours'),
('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'Hi Alice! I''m doing great, thanks for asking 😊', 'text', '20000000-0000-0000-0000-000000000001', '{}', now() - interval '2 hours' + interval '2 minutes'),
('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'That''s wonderful to hear!', 'text', NULL, '{}', now() - interval '2 hours' + interval '3 minutes'),
('20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'Are we still on for the meeting tomorrow?', 'text', NULL, '{}', now() - interval '1 hour'),
('20000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Absolutely! Looking forward to it 🚀', 'text', '20000000-0000-0000-0000-000000000004', '{}', now() - interval '5 minutes'),

-- Direct messages: Alice & Carol (less recent)
('20000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Carol, do you have time for a quick call?', 'text', NULL, '{}', now() - interval '3 hours'),
('20000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000003', 'Sorry, I''m in a meeting until 5 PM', 'text', '20000000-0000-0000-0000-000000000006', '{}', now() - interval '1 hour'),

-- Direct messages: Bob & David
('20000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000002', 'David! How''s the vacation going?', 'text', NULL, '{}', now() - interval '45 minutes'),
('20000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000004', 'Amazing! The weather is perfect ☀️🏖️', 'text', '20000000-0000-0000-0000-000000000008', '{}', now() - interval '30 minutes'),

-- Group messages: Development Team (active discussion)
('20000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Good morning team! Ready for today''s sprint?', 'text', NULL, '{}', now() - interval '3 hours'),
('20000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000002', 'Morning Alice! Yes, excited to tackle those bugs 🐛', 'text', '20000000-0000-0000-0000-000000000010', '{}', now() - interval '2 hours 50 minutes'),
('20000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000007', 'I''ve finished the authentication module testing', 'text', NULL, '{}', now() - interval '2 hours 30 minutes'),
('20000000-0000-0000-0000-000000000013', '10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000008', 'Great work Grace! 👏', 'text', '20000000-0000-0000-0000-000000000012', '{}', now() - interval '2 hours 25 minutes'),
('20000000-0000-0000-0000-000000000014', '10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Let''s schedule a quick standup at 2 PM', 'text', NULL, '{}', now() - interval '2 minutes'),

-- Group messages: Coffee Lovers (casual chat)
('20000000-0000-0000-0000-000000000015', '10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000005', 'Just tried the new Ethiopian blend ☕', 'text', NULL, '{}', now() - interval '1 hour'),
('20000000-0000-0000-0000-000000000016', '10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 'How was it? I''ve been meaning to try it!', 'text', '20000000-0000-0000-0000-000000000015', '{}', now() - interval '50 minutes'),
('20000000-0000-0000-0000-000000000017', '10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000007', 'I love Ethiopian coffee! So floral 🌸', 'text', '20000000-0000-0000-0000-000000000015', '{}', now() - interval '45 minutes'),
('20000000-0000-0000-0000-000000000018', '10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000005', 'Exactly! Perfect for morning coding sessions', 'text', NULL, '{}', now() - interval '15 minutes'),

-- Group messages: Weekend Plans
('20000000-0000-0000-0000-000000000019', '10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000003', 'Anyone up for hiking this Saturday?', 'text', NULL, '{}', now() - interval '2 hours'),
('20000000-0000-0000-0000-000000000020', '10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000004', 'I''m still on vacation, sorry! Next time for sure', 'text', '20000000-0000-0000-0000-000000000019', '{}', now() - interval '1 hour 50 minutes'),
('20000000-0000-0000-0000-000000000021', '10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000005', 'I''m in! What trail are you thinking?', 'text', '20000000-0000-0000-0000-000000000019', '{}', now() - interval '1 hour 30 minutes'),
('20000000-0000-0000-0000-000000000022', '10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000006', 'Count me in too! 🥾', 'text', '20000000-0000-0000-0000-000000000019', '{}', now() - interval '1 hour'),
('20000000-0000-0000-0000-000000000023', '10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000003', 'How about the Blue Ridge trail? It''s beautiful this time of year', 'text', NULL, '{}', now() - interval '45 minutes');

-- Create message reactions for some messages
INSERT INTO message_reactions (message_id, user_id, emoji) VALUES
('20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '❤️'),
('20000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000002', '🎉'),
('20000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000002', '😍'),
('20000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000001', '👍'),
('20000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000007', '😊'),
('20000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000001', '☕'),
('20000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000007', '👌'),
('20000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000003', '💪'),
('20000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000005', '🌲');

-- Create message status entries (automatically handled by trigger, but let's ensure some specific states)
-- Update some message statuses to show read states
UPDATE message_status SET status = 'read', timestamp = now() - interval '10 minutes'
WHERE message_id IN ('20000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002');

UPDATE message_status SET status = 'delivered', timestamp = now() - interval '5 minutes'
WHERE message_id = '20000000-0000-0000-0000-000000000005';

-- Create test meetings with various states
INSERT INTO meetings (id, room_id, livekit_room_name, host_id, title, description, scheduled_for, started_at, ended_at, max_participants, metadata) VALUES
-- Upcoming scheduled meeting
('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000004', 'meeting_upcoming_standup_001', '00000000-0000-0000-0000-000000000001', 'Daily Standup', 'Team daily standup meeting', now() + interval '2 hours', NULL, NULL, 10, '{"recurring": "daily", "agenda": "Sprint progress review"}'),
-- Currently active meeting
('30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000005', 'meeting_coffee_chat_002', '00000000-0000-0000-0000-000000000005', 'Coffee Chat', 'Casual coffee break chat', now() - interval '30 minutes', now() - interval '30 minutes', NULL, 5, '{"casual": true, "break_time": true}'),
-- Completed meeting
('30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000006', 'meeting_weekend_planning_003', '00000000-0000-0000-0000-000000000003', 'Weekend Planning', 'Planning our weekend activities', now() - interval '2 days', now() - interval '2 days', now() - interval '2 days' + interval '45 minutes', 8, '{"duration_minutes": 45, "decisions_made": ["Blue Ridge trail", "Saturday 9 AM"]}'),
-- Meeting with recording
('30000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000004', 'meeting_retrospective_004', '00000000-0000-0000-0000-000000000001', 'Sprint Retrospective', 'Review of completed sprint', now() - interval '1 week', now() - interval '1 week', now() - interval '1 week' + interval '1 hour 30 minutes', 15, '{"sprint_number": 12, "recorded": true}');

-- Create meeting participants
INSERT INTO meeting_participants (meeting_id, user_id, role, joined_at, left_at, is_audio_enabled, is_video_enabled, connection_quality) VALUES
-- Upcoming meeting participants (invited but not joined yet)
('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'host', now() - interval '1 day', NULL, true, true, 'excellent'),
('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'participant', NULL, NULL, true, true, 'good'),
('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000007', 'participant', NULL, NULL, true, false, 'good'),
('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000008', 'participant', NULL, NULL, false, true, 'excellent'),

-- Currently active meeting participants
('30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000005', 'host', now() - interval '30 minutes', NULL, true, true, 'excellent'),
('30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'participant', now() - interval '25 minutes', NULL, true, true, 'good'),
('30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000007', 'participant', now() - interval '20 minutes', NULL, true, false, 'poor'),

-- Completed meeting participants
('30000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', 'host', now() - interval '2 days', now() - interval '2 days' + interval '45 minutes', true, true, 'excellent'),
('30000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000004', 'participant', now() - interval '2 days', now() - interval '2 days' + interval '45 minutes', true, true, 'good'),
('30000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000005', 'participant', now() - interval '2 days', now() - interval '2 days' + interval '40 minutes', true, true, 'excellent'),
('30000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000006', 'participant', now() - interval '2 days' + interval '5 minutes', now() - interval '2 days' + interval '45 minutes', false, true, 'good'),

-- Retrospective meeting participants (recorded meeting)
('30000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'host', now() - interval '1 week', now() - interval '1 week' + interval '1 hour 30 minutes', true, true, 'excellent'),
('30000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000002', 'participant', now() - interval '1 week', now() - interval '1 week' + interval '1 hour 30 minutes', true, false, 'good'),
('30000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000007', 'participant', now() - interval '1 week' + interval '2 minutes', now() - interval '1 week' + interval '1 hour 30 minutes', true, true, 'excellent'),
('30000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000008', 'participant', now() - interval '1 week' + interval '5 minutes', now() - interval '1 week' + interval '1 hour 25 minutes', true, true, 'poor');

-- Create meeting invitations
INSERT INTO meeting_invitations (meeting_id, inviter_id, invitee_id, status, invited_at, responded_at) VALUES
-- Upcoming meeting invitations
('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'accepted', now() - interval '1 day', now() - interval '23 hours'),
('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000007', 'accepted', now() - interval '1 day', now() - interval '22 hours'),
('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000008', 'pending', now() - interval '1 day', NULL),

-- Active meeting invitations (some joined, some pending)
('30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 'accepted', now() - interval '1 hour', now() - interval '45 minutes'),
('30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000007', 'accepted', now() - interval '1 hour', now() - interval '50 minutes'),

-- Past meeting invitations
('30000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000004', 'accepted', now() - interval '3 days', now() - interval '2 days 12 hours'),
('30000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000005', 'accepted', now() - interval '3 days', now() - interval '2 days 10 hours'),
('30000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000006', 'accepted', now() - interval '3 days', now() - interval '2 days 8 hours');

-- Create meeting recordings (for completed meetings)
INSERT INTO meeting_recordings (meeting_id, livekit_egress_id, file_url, file_size, duration_seconds, status, started_at, completed_at, metadata) VALUES
('30000000-0000-0000-0000-000000000004', 'egress_retrospective_sprint12_001', 'https://recordings.example.com/sprint12_retrospective.mp4', 524288000, 5400, 'completed', now() - interval '1 week', now() - interval '1 week' + interval '2 hours', '{"resolution": "1080p", "audio_bitrate": "128kbps", "video_bitrate": "2mbps"}');

-- Create some typing indicators for active conversations
INSERT INTO typing_indicators (room_id, user_id, is_typing, updated_at) VALUES
('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', true, now() - interval '5 seconds'),
('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000007', true, now() - interval '10 seconds');

-- Final verification: Show summary of created test data
SELECT 'Test data seed completed successfully!' as status;
SELECT 
    'Users' as entity_type,
    count(*) as count
FROM user_profiles
UNION ALL
SELECT 
    'Rooms' as entity_type,
    count(*) as count
FROM rooms
UNION ALL
SELECT 
    'Messages' as entity_type,
    count(*) as count
FROM messages
UNION ALL
SELECT 
    'Meetings' as entity_type,
    count(*) as count
FROM meetings
UNION ALL
SELECT 
    'Active typing users' as entity_type,
    count(*) as count
FROM typing_indicators
WHERE is_typing = true;