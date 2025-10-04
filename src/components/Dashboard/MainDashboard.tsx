import { useState } from 'react';
import { ServerList } from '../Layout/ServerList';
import { ChannelSidebar } from '../Layout/ChannelSidebar';
import { ChatArea } from '../Chat/ChatArea';
import { CreateServerModal } from '../Modals/CreateServerModal';
import { CreateChannelModal } from '../Modals/CreateChannelModal';
import { useTheme } from '../../contexts/ThemeContext';
import { useAuth } from '../../contexts/AuthContext';
import { Moon, Sun, LogOut } from 'lucide-react';

export function MainDashboard() {
  const [selectedServerId, setSelectedServerId] = useState<string | null>(null);
  const [selectedChannelId, setSelectedChannelId] = useState<string | null>(null);
  const [showCreateServer, setShowCreateServer] = useState(false);
  const [showCreateChannel, setShowCreateChannel] = useState(false);
  const { theme, toggleTheme } = useTheme();
  const { signOut } = useAuth();

  const handleServerSelect = (serverId: string) => {
    setSelectedServerId(serverId);
    setSelectedChannelId(null);
  };

  const handleServerCreated = (serverId: string) => {
    setShowCreateServer(false);
    setSelectedServerId(serverId);
    setSelectedChannelId(null);
  };

  const handleSignOut = async () => {
    await signOut();
  };

  return (
    <div className="flex h-screen bg-gray-900">
      <ServerList
        onServerSelect={handleServerSelect}
        selectedServerId={selectedServerId}
        onCreateServer={() => setShowCreateServer(true)}
      />

      <ChannelSidebar
        serverId={selectedServerId}
        onChannelSelect={setSelectedChannelId}
        selectedChannelId={selectedChannelId}
        onCreateChannel={() => setShowCreateChannel(true)}
      />

      <div className="flex-1 flex flex-col">
        <div className="h-12 bg-gray-800 border-b border-gray-900 flex items-center justify-end px-4 space-x-3">
          <button
            onClick={toggleTheme}
            className="p-2 hover:bg-gray-700 rounded-lg transition-colors text-gray-400 hover:text-white"
            title={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`}
          >
            {theme === 'dark' ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
          </button>
          <button
            onClick={handleSignOut}
            className="p-2 hover:bg-gray-700 rounded-lg transition-colors text-gray-400 hover:text-white"
            title="Sign out"
          >
            <LogOut className="w-5 h-5" />
          </button>
        </div>

        <ChatArea channelId={selectedChannelId} />
      </div>

      {showCreateServer && (
        <CreateServerModal
          onClose={() => setShowCreateServer(false)}
          onSuccess={handleServerCreated}
        />
      )}

      {showCreateChannel && selectedServerId && (
        <CreateChannelModal
          serverId={selectedServerId}
          onClose={() => setShowCreateChannel(false)}
        />
      )}
    </div>
  );
}
