import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { Hash, Volume2, Plus, Settings, ChevronDown } from 'lucide-react';
import type { Database } from '../../lib/database.types';

type Channel = Database['public']['Tables']['channels']['Row'];
type Server = Database['public']['Tables']['servers']['Row'];

interface ChannelSidebarProps {
  serverId: string | null;
  onChannelSelect: (channelId: string) => void;
  selectedChannelId: string | null;
  onCreateChannel: () => void;
}

export function ChannelSidebar({ serverId, onChannelSelect, selectedChannelId, onCreateChannel }: ChannelSidebarProps) {
  const [channels, setChannels] = useState<Channel[]>([]);
  const [server, setServer] = useState<Server | null>(null);
  const { user } = useAuth();

  useEffect(() => {
    if (!serverId) return;

    loadServerAndChannels();

    const subscription = supabase
      .channel('channel_changes')
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'channels',
        filter: `server_id=eq.${serverId}`
      }, loadServerAndChannels)
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, [serverId]);

  const loadServerAndChannels = async () => {
    if (!serverId) return;

    const { data: serverData } = await supabase
      .from('servers')
      .select('*')
      .eq('id', serverId)
      .maybeSingle();

    if (serverData) {
      setServer(serverData);
    }

    const { data } = await supabase
      .from('channels')
      .select('*')
      .eq('server_id', serverId)
      .order('position', { ascending: true });

    if (data) {
      setChannels(data);
      if (data.length > 0 && !selectedChannelId) {
        onChannelSelect(data[0].id);
      }
    }
  };

  if (!serverId || !server) {
    return (
      <div className="w-60 bg-gray-800 flex items-center justify-center text-gray-400">
        Select a server
      </div>
    );
  }

  const textChannels = channels.filter(c => c.type === 'text');
  const voiceChannels = channels.filter(c => c.type === 'voice');

  return (
    <div className="w-60 bg-gray-800 flex flex-col">
      <div className="h-12 px-4 flex items-center justify-between border-b border-gray-900 shadow-md">
        <h2 className="font-semibold text-white truncate">{server.name}</h2>
        <ChevronDown className="w-5 h-5 text-gray-400" />
      </div>

      <div className="flex-1 overflow-y-auto p-2 space-y-4">
        <div>
          <div className="flex items-center justify-between px-2 py-1 text-xs font-semibold text-gray-400 uppercase">
            <span>Text Channels</span>
            <button
              onClick={onCreateChannel}
              className="hover:text-white transition-colors"
              title="Create Channel"
            >
              <Plus className="w-4 h-4" />
            </button>
          </div>
          <div className="space-y-0.5">
            {textChannels.map((channel) => (
              <button
                key={channel.id}
                onClick={() => onChannelSelect(channel.id)}
                className={`w-full flex items-center space-x-2 px-2 py-1.5 rounded hover:bg-gray-700 transition-colors ${
                  selectedChannelId === channel.id ? 'bg-gray-700 text-white' : 'text-gray-400'
                }`}
              >
                <Hash className="w-5 h-5 flex-shrink-0" />
                <span className="truncate">{channel.name}</span>
              </button>
            ))}
          </div>
        </div>

        {voiceChannels.length > 0 && (
          <div>
            <div className="flex items-center justify-between px-2 py-1 text-xs font-semibold text-gray-400 uppercase">
              <span>Voice Channels</span>
            </div>
            <div className="space-y-0.5">
              {voiceChannels.map((channel) => (
                <button
                  key={channel.id}
                  onClick={() => onChannelSelect(channel.id)}
                  className={`w-full flex items-center space-x-2 px-2 py-1.5 rounded hover:bg-gray-700 transition-colors ${
                    selectedChannelId === channel.id ? 'bg-gray-700 text-white' : 'text-gray-400'
                  }`}
                >
                  <Volume2 className="w-5 h-5 flex-shrink-0" />
                  <span className="truncate">{channel.name}</span>
                </button>
              ))}
            </div>
          </div>
        )}
      </div>

      <div className="h-14 bg-gray-900 px-2 flex items-center justify-between">
        <div className="flex items-center space-x-2 min-w-0 flex-1">
          <div className="w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center text-white font-semibold flex-shrink-0">
            {user?.email?.[0].toUpperCase()}
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-sm font-medium text-white truncate">{user?.email?.split('@')[0]}</p>
            <p className="text-xs text-gray-400">online</p>
          </div>
        </div>
        <Settings className="w-5 h-5 text-gray-400 hover:text-white cursor-pointer flex-shrink-0" />
      </div>
    </div>
  );
}
