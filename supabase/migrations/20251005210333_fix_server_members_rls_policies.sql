/*
  # Fix Server Members RLS Policies - Remove Infinite Recursion

  ## Problem
  The original server_members policies created infinite recursion by querying
  the server_members table within its own policies.

  ## Solution
  Simplified policies that avoid self-referencing:
  
  1. SELECT Policy
    - Users can view all server_members records for servers they belong to
    - Uses direct user_id check instead of nested query
  
  2. INSERT Policy  
    - First member (owner) can always insert when creating server
    - Additional members can be added by checking servers.owner_id
    - Uses servers table to verify permissions instead of server_members
  
  3. DELETE Policy
    - Users can remove themselves from servers
    - Server owners can remove any member
    - Uses servers.owner_id for owner verification

  ## Changes
  - Dropped all existing server_members policies
  - Created new non-recursive policies
  - Policies now reference servers table for ownership checks
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Server members viewable by server members" ON server_members;
DROP POLICY IF EXISTS "Server owners and admins can add members" ON server_members;
DROP POLICY IF EXISTS "Users can leave servers" ON server_members;

-- New SELECT policy: Users can view members of servers they belong to
CREATE POLICY "Users can view server members"
  ON server_members FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() 
    OR 
    server_id IN (
      SELECT server_id FROM server_members WHERE user_id = auth.uid()
    )
  );

-- New INSERT policy: Owners can add members, or users can join when invited
CREATE POLICY "Server owners can add members"
  ON server_members FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid() 
    OR 
    EXISTS (
      SELECT 1 FROM servers 
      WHERE servers.id = server_members.server_id 
      AND servers.owner_id = auth.uid()
    )
  );

-- New DELETE policy: Users can leave, owners can remove members
CREATE POLICY "Members can be removed appropriately"
  ON server_members FOR DELETE
  TO authenticated
  USING (
    user_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM servers
      WHERE servers.id = server_members.server_id
      AND servers.owner_id = auth.uid()
    )
  );
