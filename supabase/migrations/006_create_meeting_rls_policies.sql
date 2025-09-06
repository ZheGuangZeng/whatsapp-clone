-- Row Level Security policies for meeting tables
-- These policies ensure users can only access meetings they're authorized for

-- RLS Policies for meetings table
-- Users can view meetings they're hosting or participating in
CREATE POLICY "Users can view their meetings" ON meetings
  FOR SELECT 
  USING (
    host_id = auth.uid() OR
    id IN (
      SELECT meeting_id FROM meeting_participants 
      WHERE user_id = auth.uid()
    )
  );

-- Users can insert meetings they're hosting
CREATE POLICY "Users can create meetings as host" ON meetings
  FOR INSERT
  WITH CHECK (host_id = auth.uid());

-- Only hosts can update their meetings
CREATE POLICY "Hosts can update their meetings" ON meetings
  FOR UPDATE
  USING (host_id = auth.uid())
  WITH CHECK (host_id = auth.uid());

-- Only hosts can delete their meetings
CREATE POLICY "Hosts can delete their meetings" ON meetings
  FOR DELETE
  USING (host_id = auth.uid());

-- RLS Policies for meeting_participants table
-- Users can view participants in meetings they're part of
CREATE POLICY "Users can view participants in their meetings" ON meeting_participants
  FOR SELECT
  USING (
    meeting_id IN (
      SELECT id FROM meetings WHERE host_id = auth.uid()
    ) OR
    meeting_id IN (
      SELECT meeting_id FROM meeting_participants WHERE user_id = auth.uid()
    )
  );

-- Users can join meetings they're invited to
CREATE POLICY "Users can join meetings" ON meeting_participants
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid() AND (
      -- Self-insert if meeting exists and user is invited or meeting is in same room as user
      meeting_id IN (
        SELECT m.id FROM meetings m
        JOIN rooms r ON m.room_id = r.id
        JOIN room_participants rp ON r.id = rp.room_id
        WHERE rp.user_id = auth.uid() AND rp.is_active = true
      ) OR
      -- Or if there's an invitation
      meeting_id IN (
        SELECT meeting_id FROM meeting_invitations 
        WHERE invitee_id = auth.uid() AND status = 'accepted'
      )
    )
  );

-- Users can update their own participant status
CREATE POLICY "Users can update their participant status" ON meeting_participants
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Hosts and users themselves can remove participants
CREATE POLICY "Users can leave meetings or hosts can remove participants" ON meeting_participants
  FOR DELETE
  USING (
    user_id = auth.uid() OR
    meeting_id IN (SELECT id FROM meetings WHERE host_id = auth.uid())
  );

-- RLS Policies for meeting_invitations table
-- Users can view invitations sent to them or sent by them
CREATE POLICY "Users can view their invitations" ON meeting_invitations
  FOR SELECT
  USING (invitee_id = auth.uid() OR inviter_id = auth.uid());

-- Users can send invitations for meetings they host or participate in
CREATE POLICY "Users can send meeting invitations" ON meeting_invitations
  FOR INSERT
  WITH CHECK (
    inviter_id = auth.uid() AND (
      meeting_id IN (SELECT id FROM meetings WHERE host_id = auth.uid()) OR
      meeting_id IN (
        SELECT meeting_id FROM meeting_participants 
        WHERE user_id = auth.uid() AND role IN ('host', 'admin')
      )
    )
  );

-- Users can update invitations they received
CREATE POLICY "Users can respond to invitations" ON meeting_invitations
  FOR UPDATE
  USING (invitee_id = auth.uid())
  WITH CHECK (invitee_id = auth.uid());

-- Inviters can cancel their invitations
CREATE POLICY "Inviters can cancel invitations" ON meeting_invitations
  FOR DELETE
  USING (inviter_id = auth.uid());

-- RLS Policies for meeting_recordings table
-- Users can view recordings of meetings they participated in
CREATE POLICY "Users can view recordings of their meetings" ON meeting_recordings
  FOR SELECT
  USING (
    meeting_id IN (
      SELECT id FROM meetings WHERE host_id = auth.uid()
    ) OR
    meeting_id IN (
      SELECT meeting_id FROM meeting_participants WHERE user_id = auth.uid()
    )
  );

-- Only hosts can create recordings
CREATE POLICY "Hosts can create recordings" ON meeting_recordings
  FOR INSERT
  WITH CHECK (
    meeting_id IN (SELECT id FROM meetings WHERE host_id = auth.uid())
  );

-- Only hosts can update recording status
CREATE POLICY "Hosts can update recordings" ON meeting_recordings
  FOR UPDATE
  USING (
    meeting_id IN (SELECT id FROM meetings WHERE host_id = auth.uid())
  )
  WITH CHECK (
    meeting_id IN (SELECT id FROM meetings WHERE host_id = auth.uid())
  );

-- Only hosts can delete recordings
CREATE POLICY "Hosts can delete recordings" ON meeting_recordings
  FOR DELETE
  USING (
    meeting_id IN (SELECT id FROM meetings WHERE host_id = auth.uid())
  );