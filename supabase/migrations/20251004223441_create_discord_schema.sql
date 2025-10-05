/*
  # Discord-like Application Schema

  ## Overview
  This migration creates the complete database schema for a Discord-like communication platform
  with support for users, servers, channels, messages, friendships, and real-time features.

  ## Tables Created

  ### 1. profiles
  Extended user profiles linked to auth.users
  - `id` (uuid, FK to auth.users) - User identifier
  - `username` (text, unique) - Display name
  - `avatar_url` (text) - Profile picture URL
  - `bio` (text) - User biography
  - `status` (text) - Current status (online, offline, away, dnd)
  - `created_at` (timestamptz) - Account creation timestamp
  - `updated_at` (timestamptz) - Last profile update

  ### 2. servers
  Communities that users can create and join
  - `id` (uuid, PK) - Server identifier
  - `name` (text) - Server name
  - `description` (text) - Server description
  - `icon_url` (text) - Server icon
  - `owner_id` (uuid, FK to profiles) - Server creator
  - `created_at` (timestamptz) - Server creation timestamp

  ### 3. server_members
  Junction table for users in servers with roles
  - `id` (uuid, PK) - Membership identifier
  - `server_id` (uuid, FK to servers) - Associated server
  - `user_id` (uuid, FK to profiles) - Associated user
  - `role` (text) - User role (owner, admin, member)
  - `joined_at` (timestamptz) - Join timestamp

  ### 4. channels
  Text and voice channels within servers
  - `id` (uuid, PK) - Channel identifier
  - `server_id` (uuid, FK to servers) - Parent server
  - `name` (text) - Channel name
  - `type` (text) - Channel type (text, voice)
  - `position` (int) - Display order
  - `created_at` (timestamptz) - Creation timestamp

  ### 5. messages
  Chat messages in channels
  - `id` (uuid, PK) - Message identifier
  - `channel_id` (uuid, FK to channels) - Target channel
  - `user_id` (uuid, FK to profiles) - Message author
  - `content` (text) - Message content
  - `attachments` (jsonb) - File attachments metadata
  - `created_at` (timestamptz) - Send timestamp
  - `updated_at` (timestamptz) - Edit timestamp

  ### 6. direct_messages
  Private messages between users
  - `id` (uuid, PK) - Message identifier
  - `sender_id` (uuid, FK to profiles) - Sender
  - `receiver_id` (uuid, FK to profiles) - Receiver
  - `content` (text) - Message content
  - `attachments` (jsonb) - File attachments metadata
  - `read` (boolean) - Read status
  - `created_at` (timestamptz) - Send timestamp

  ### 7. friendships
  Friend connections between users
  - `id` (uuid, PK) - Friendship identifier
  - `user_id` (uuid, FK to profiles) - Requesting user
  - `friend_id` (uuid, FK to profiles) - Target user
  - `status` (text) - Relationship status (pending, accepted, blocked)
  - `created_at` (timestamptz) - Request timestamp
  - `updated_at` (timestamptz) - Status change timestamp

  ## Security
  - Row Level Security (RLS) enabled on all tables
  - Policies restrict access based on authentication and membership
  - Users can only access servers they're members of
  - Messages only visible to channel/server members
  - Friend requests and DMs respect privacy settings

  ## Indexes
  - Performance indexes on foreign keys and frequently queried columns
  - Composite indexes for common query patterns
*/

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username text UNIQUE NOT NULL,
  avatar_url text,
  bio text DEFAULT '',
  status text DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'away', 'dnd')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Servers table
CREATE TABLE IF NOT EXISTS servers (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  description text DEFAULT '',
  icon_url text,
  owner_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

-- Server members table
CREATE TABLE IF NOT EXISTS server_members (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  server_id uuid NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role text DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
  joined_at timestamptz DEFAULT now(),
  UNIQUE(server_id, user_id)
);

-- Channels table
CREATE TABLE IF NOT EXISTS channels (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  server_id uuid NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
  name text NOT NULL,
  type text DEFAULT 'text' CHECK (type IN ('text', 'voice')),
  position int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  channel_id uuid NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content text NOT NULL,
  attachments jsonb DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Direct messages table
CREATE TABLE IF NOT EXISTS direct_messages (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content text NOT NULL,
  attachments jsonb DEFAULT '[]'::jsonb,
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Friendships table
CREATE TABLE IF NOT EXISTS friendships (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  friend_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, friend_id),
  CHECK (user_id != friend_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_server_members_server_id ON server_members(server_id);
CREATE INDEX IF NOT EXISTS idx_server_members_user_id ON server_members(user_id);
CREATE INDEX IF NOT EXISTS idx_channels_server_id ON channels(server_id);
CREATE INDEX IF NOT EXISTS idx_messages_channel_id ON messages(channel_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_direct_messages_sender_receiver ON direct_messages(sender_id, receiver_id);
CREATE INDEX IF NOT EXISTS idx_direct_messages_created_at ON direct_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_friendships_user_id ON friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_friend_id ON friendships(friend_id);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE servers ENABLE ROW LEVEL SECURITY;
ALTER TABLE server_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE direct_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Profiles are viewable by everyone"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Servers policies
CREATE POLICY "Servers viewable by members"
  ON servers FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM server_members
      WHERE server_members.server_id = servers.id
      AND server_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create servers"
  ON servers FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Server owners can update their servers"
  ON servers FOR UPDATE
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Server owners can delete their servers"
  ON servers FOR DELETE
  TO authenticated
  USING (auth.uid() = owner_id);

-- Server members policies
CREATE POLICY "Server members viewable by server members"
  ON server_members FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM server_members sm
      WHERE sm.server_id = server_members.server_id
      AND sm.user_id = auth.uid()
    )
  );

CREATE POLICY "Server owners and admins can add members"
  ON server_members FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM server_members
      WHERE server_members.server_id = server_members.server_id
      AND server_members.user_id = auth.uid()
      AND server_members.role IN ('owner', 'admin')
    )
  );

CREATE POLICY "Users can leave servers"
  ON server_members FOR DELETE
  TO authenticated
  USING (user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM server_members sm
    WHERE sm.server_id = server_members.server_id
    AND sm.user_id = auth.uid()
    AND sm.role IN ('owner', 'admin')
  ));

-- Channels policies
CREATE POLICY "Channels viewable by server members"
  ON channels FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM server_members
      WHERE server_members.server_id = channels.server_id
      AND server_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Server owners and admins can create channels"
  ON channels FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM server_members
      WHERE server_members.server_id = channels.server_id
      AND server_members.user_id = auth.uid()
      AND server_members.role IN ('owner', 'admin')
    )
  );

CREATE POLICY "Server owners and admins can update channels"
  ON channels FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM server_members
      WHERE server_members.server_id = channels.server_id
      AND server_members.user_id = auth.uid()
      AND server_members.role IN ('owner', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM server_members
      WHERE server_members.server_id = channels.server_id
      AND server_members.user_id = auth.uid()
      AND server_members.role IN ('owner', 'admin')
    )
  );

CREATE POLICY "Server owners and admins can delete channels"
  ON channels FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM server_members
      WHERE server_members.server_id = channels.server_id
      AND server_members.user_id = auth.uid()
      AND server_members.role IN ('owner', 'admin')
    )
  );

-- Messages policies
CREATE POLICY "Messages viewable by channel members"
  ON messages FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM channels
      JOIN server_members ON server_members.server_id = channels.server_id
      WHERE channels.id = messages.channel_id
      AND server_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Server members can create messages"
  ON messages FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM channels
      JOIN server_members ON server_members.server_id = channels.server_id
      WHERE channels.id = messages.channel_id
      AND server_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own messages"
  ON messages FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own messages"
  ON messages FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Direct messages policies
CREATE POLICY "Users can view their direct messages"
  ON direct_messages FOR SELECT
  TO authenticated
  USING (
    auth.uid() = sender_id OR auth.uid() = receiver_id
  );

CREATE POLICY "Users can send direct messages"
  ON direct_messages FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update their sent messages"
  ON direct_messages FOR UPDATE
  TO authenticated
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id)
  WITH CHECK (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Friendships policies
CREATE POLICY "Users can view their friendships"
  ON friendships FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id OR auth.uid() = friend_id
  );

CREATE POLICY "Users can create friend requests"
  ON friendships FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update friendship status"
  ON friendships FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id OR auth.uid() = friend_id)
  WITH CHECK (auth.uid() = user_id OR auth.uid() = friend_id);

CREATE POLICY "Users can delete friendships"
  ON friendships FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Function to automatically create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, username, avatar_url)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'avatar_url'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON messages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_friendships_updated_at BEFORE UPDATE ON friendships
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
