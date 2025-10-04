import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { MessageList } from './MessageList';
import { MessageInput } from './MessageInput';
import { Hash, Users, Bell, Pin, Search } from 'lucide-react';
import type { Database } from '../../lib/database.types';

type Channel = Database['public']['Tables']['channels']['Row'];

interface ChatAreaProps {
  channelId: string | null;
}

export function ChatArea({ channelId }: ChatAreaProps) {
  const [channel, setChannel] = useState<Channel | null>(null);

  useEffect(() => {
    if (!channelId) return;

    loadChannel();
  }, [channelId]);

  const loadChannel = async () => {
    if (!channelId) return;

    const { data } = await supabase
      .from('channels')
      .select('*')
      .eq('id', channelId)
      .maybeSingle();

    if (data) {
      setChannel(data);
    }
  };

  if (!channelId || !channel) {
    return (
      <div className="flex-1 flex items-center justify-center bg-gray-700 text-gray-400">
        <div className="text-center">
          <Hash className="w-16 h-16 mx-auto mb-4 text-gray-500" />
          <h2 className="text-xl font-semibold mb-2">Welcome!</h2>
          <p>Select a channel to start messaging</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 flex flex-col bg-gray-700">
      <div className="h-12 px-4 flex items-center justify-between border-b border-gray-800 shadow-md">
        <div className="flex items-center space-x-2">
          <Hash className="w-6 h-6 text-gray-400" />
          <span className="font-semibold text-white">{channel.name}</span>
        </div>
        <div className="flex items-center space-x-4 text-gray-400">
          <Bell className="w-5 h-5 hover:text-white cursor-pointer" />
          <Pin className="w-5 h-5 hover:text-white cursor-pointer" />
          <Users className="w-5 h-5 hover:text-white cursor-pointer" />
          <Search className="w-5 h-5 hover:text-white cursor-pointer" />
        </div>
      </div>

      <MessageList channelId={channelId} />
      <MessageInput channelId={channelId} />
    </div>
  );
}
