-- Row Level Security (RLS) policies for messaging tables
-- This ensures users can only access data they're authorized to see

-- Enable RLS on all messaging tables
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_presence ENABLE ROW LEVEL SECURITY;

-- ========================================
-- ROOMS TABLE POLICIES
-- ========================================

-- Users can view rooms they participate in
CREATE POLICY "Users can view rooms they participate in" ON rooms
FOR SELECT USING (
    auth.uid() IN (
        SELECT user_id FROM room_participants 
        WHERE room_id = rooms.id AND is_active = true
    )
);

-- Users can create new rooms
CREATE POLICY "Users can create rooms" ON rooms
FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Room creators and admins can update rooms
CREATE POLICY "Room admins can update rooms" ON rooms
FOR UPDATE USING (
    auth.uid() = created_by OR
    auth.uid() IN (
        SELECT user_id FROM room_participants 
        WHERE room_id = rooms.id AND role = 'admin' AND is_active = true
    )
);

-- Room creators can delete rooms
CREATE POLICY "Room creators can delete rooms" ON rooms
FOR DELETE USING (auth.uid() = created_by);

-- ========================================
-- ROOM_PARTICIPANTS TABLE POLICIES
-- ========================================

-- Users can view participants of rooms they're in
CREATE POLICY "Users can view room participants" ON room_participants
FOR SELECT USING (
    room_id IN (
        SELECT room_id FROM room_participants rp2 
        WHERE rp2.user_id = auth.uid() AND rp2.is_active = true
    )
);

-- Room admins and creators can add participants
CREATE POLICY "Room admins can add participants" ON room_participants
FOR INSERT WITH CHECK (
    room_id IN (
        SELECT r.id FROM rooms r
        LEFT JOIN room_participants rp ON r.id = rp.room_id
        WHERE (r.created_by = auth.uid() OR (rp.user_id = auth.uid() AND rp.role = 'admin'))
        AND rp.is_active = true
    )
);

-- Room admins and participants themselves can update participation
CREATE POLICY "Room admins and self can update participation" ON room_participants
FOR UPDATE USING (
    user_id = auth.uid() OR
    room_id IN (
        SELECT r.id FROM rooms r
        LEFT JOIN room_participants rp ON r.id = rp.room_id
        WHERE (r.created_by = auth.uid() OR (rp.user_id = auth.uid() AND rp.role = 'admin'))
        AND rp.is_active = true
    )
);

-- Room admins and participants themselves can remove participation
CREATE POLICY "Room admins and self can remove participation" ON room_participants
FOR DELETE USING (
    user_id = auth.uid() OR
    room_id IN (
        SELECT r.id FROM rooms r
        LEFT JOIN room_participants rp ON r.id = rp.room_id
        WHERE (r.created_by = auth.uid() OR (rp.user_id = auth.uid() AND rp.role = 'admin'))
        AND rp.is_active = true
    )
);

-- ========================================
-- MESSAGES TABLE POLICIES
-- ========================================

-- Users can view messages from rooms they participate in
CREATE POLICY "Users can view messages from their rooms" ON messages
FOR SELECT USING (
    room_id IN (
        SELECT room_id FROM room_participants 
        WHERE user_id = auth.uid() AND is_active = true
    )
);

-- Users can send messages to rooms they participate in
CREATE POLICY "Users can send messages to their rooms" ON messages
FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    room_id IN (
        SELECT room_id FROM room_participants 
        WHERE user_id = auth.uid() AND is_active = true
    )
);

-- Users can edit their own messages (for editing functionality)
CREATE POLICY "Users can edit their own messages" ON messages
FOR UPDATE USING (auth.uid() = user_id);

-- Users can soft-delete their own messages
CREATE POLICY "Users can delete their own messages" ON messages
FOR DELETE USING (auth.uid() = user_id);

-- ========================================
-- MESSAGE_STATUS TABLE POLICIES
-- ========================================

-- Users can view message status for messages in their rooms
CREATE POLICY "Users can view message status" ON message_status
FOR SELECT USING (
    message_id IN (
        SELECT m.id FROM messages m
        JOIN room_participants rp ON m.room_id = rp.room_id
        WHERE rp.user_id = auth.uid() AND rp.is_active = true
    )
);

-- System can create message status entries (handled by trigger)
CREATE POLICY "System can create message status" ON message_status
FOR INSERT WITH CHECK (true);

-- Users can update their own message status
CREATE POLICY "Users can update their own message status" ON message_status
FOR UPDATE USING (auth.uid() = user_id);

-- ========================================
-- MESSAGE_REACTIONS TABLE POLICIES
-- ========================================

-- Users can view reactions on messages in their rooms
CREATE POLICY "Users can view message reactions" ON message_reactions
FOR SELECT USING (
    message_id IN (
        SELECT m.id FROM messages m
        JOIN room_participants rp ON m.room_id = rp.room_id
        WHERE rp.user_id = auth.uid() AND rp.is_active = true
    )
);

-- Users can add reactions to messages in their rooms
CREATE POLICY "Users can add reactions" ON message_reactions
FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    message_id IN (
        SELECT m.id FROM messages m
        JOIN room_participants rp ON m.room_id = rp.room_id
        WHERE rp.user_id = auth.uid() AND rp.is_active = true
    )
);

-- Users can remove their own reactions
CREATE POLICY "Users can remove their own reactions" ON message_reactions
FOR DELETE USING (auth.uid() = user_id);

-- ========================================
-- TYPING_INDICATORS TABLE POLICIES
-- ========================================

-- Users can view typing indicators for rooms they participate in
CREATE POLICY "Users can view typing indicators" ON typing_indicators
FOR SELECT USING (
    room_id IN (
        SELECT room_id FROM room_participants 
        WHERE user_id = auth.uid() AND is_active = true
    )
);

-- Users can manage their own typing indicators
CREATE POLICY "Users can manage their own typing indicators" ON typing_indicators
FOR ALL USING (auth.uid() = user_id);

-- ========================================
-- USER_PRESENCE TABLE POLICIES
-- ========================================

-- All authenticated users can view user presence
CREATE POLICY "Authenticated users can view presence" ON user_presence
FOR SELECT USING (auth.role() = 'authenticated');

-- Users can update their own presence
CREATE POLICY "Users can update their own presence" ON user_presence
FOR ALL USING (auth.uid() = user_id);

-- ========================================
-- REALTIME PUBLICATION
-- ========================================

-- Enable realtime for all messaging tables
ALTER PUBLICATION supabase_realtime ADD TABLE rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE room_participants;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE message_status;
ALTER PUBLICATION supabase_realtime ADD TABLE message_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE typing_indicators;
ALTER PUBLICATION supabase_realtime ADD TABLE user_presence;