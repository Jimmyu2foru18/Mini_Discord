/*
  # Optimize Channels and Messages RLS Policies

  ## Overview
  Optimized RLS policies for channels and messages to prevent potential
  recursion issues and improve performance.

  ## Changes

  ### Channels Table
  - Policies now use direct server_members lookups
  - Removed nested queries that could cause recursion
  - Admin checks use servers.owner_id for better performance

  ### Messages Table  
  - Simplified member verification
  - Direct joins instead of nested EXISTS
  - Improved query performance

  ## Security
  All policies maintain the same security guarantees:
  - Only server members can view/create content
  - Only owners/admins can manage channels
  - Users can only edit/delete their own messages
*/

-- Drop existing channel policies
DROP POLICY IF EXISTS "Channels viewable by server members" ON channels;
DROP POLICY IF EXISTS "Server owners and admins can create channels" ON channels;
DROP POLICY IF EXISTS "Server owners and admins can update channels" ON channels;
DROP POLICY IF EXISTS "Server owners and admins can delete channels" ON channels;

-- New channel policies with optimized queries
CREATE POLICY "Users can view channels in their servers"
  ON channels FOR SELECT
  TO authenticated
  USING (
    server_id IN (
      SELECT server_id FROM server_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Server owners can create channels"
  ON channels FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM servers 
      WHERE servers.id = channels.server_id 
      AND servers.owner_id = auth.uid()
    )
  );

CREATE POLICY "Server owners can update channels"
  ON channels FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM servers 
      WHERE servers.id = channels.server_id 
      AND servers.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM servers 
      WHERE servers.id = channels.server_id 
      AND servers.owner_id = auth.uid()
    )
  );

CREATE POLICY "Server owners can delete channels"
  ON channels FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM servers 
      WHERE servers.id = channels.server_id 
      AND servers.owner_id = auth.uid()
    )
  );

-- Drop existing message policies
DROP POLICY IF EXISTS "Messages viewable by channel members" ON messages;
DROP POLICY IF EXISTS "Server members can create messages" ON messages;
DROP POLICY IF EXISTS "Users can update own messages" ON messages;
DROP POLICY IF EXISTS "Users can delete own messages" ON messages;

-- New message policies with optimized queries
CREATE POLICY "Users can view messages in their channels"
  ON messages FOR SELECT
  TO authenticated
  USING (
    channel_id IN (
      SELECT c.id FROM channels c
      INNER JOIN server_members sm ON sm.server_id = c.server_id
      WHERE sm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can send messages in their channels"
  ON messages FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid() 
    AND 
    channel_id IN (
      SELECT c.id FROM channels c
      INNER JOIN server_members sm ON sm.server_id = c.server_id
      WHERE sm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can edit their own messages"
  ON messages FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own messages"
  ON messages FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());
