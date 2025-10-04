import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { Plus, Hash } from 'lucide-react';
import type { Database } from '../../lib/database.types';

type Server = Database['public']['Tables']['servers']['Row'];

interface ServerListProps {
  onServerSelect: (serverId: string) => void;
  selectedServerId: string | null;
  onCreateServer: () => void;
}

export function ServerList({ onServerSelect, selectedServerId, onCreateServer }: ServerListProps) {
  const [servers, setServers] = useState<Server[]>([]);
  const { user } = useAuth();

  useEffect(() => {
    if (!user) return;

    loadServers();

    const subscription = supabase
      .channel('server_changes')
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'servers'
      }, loadServers)
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, [user]);

  const loadServers = async () => {
    if (!user) return;

    const { data: memberData } = await supabase
      .from('server_members')
      .select('server_id')
      .eq('user_id', user.id);

    if (!memberData) return;

    const serverIds = memberData.map(m => m.server_id);

    if (serverIds.length === 0) {
      setServers([]);
      return;
    }

    const { data } = await supabase
      .from('servers')
      .select('*')
      .in('id', serverIds)
      .order('created_at', { ascending: true });

    if (data) {
      setServers(data);
    }
  };

  return (
    <div className="w-20 bg-gray-900 flex flex-col items-center py-3 space-y-2">
      <button
        onClick={onCreateServer}
        className="w-12 h-12 rounded-full bg-gray-700 hover:bg-blue-500 hover:rounded-2xl transition-all duration-200 flex items-center justify-center text-green-400 hover:text-white"
        title="Create Server"
      >
        <Plus className="w-6 h-6" />
      </button>

      <div className="w-8 h-0.5 bg-gray-700 rounded-full" />

      <div className="flex-1 overflow-y-auto space-y-2 scrollbar-thin scrollbar-thumb-gray-700">
        {servers.map((server) => (
          <button
            key={server.id}
            onClick={() => onServerSelect(server.id)}
            className={`w-12 h-12 rounded-full hover:rounded-2xl transition-all duration-200 flex items-center justify-center text-white font-semibold ${
              selectedServerId === server.id
                ? 'bg-blue-500 rounded-2xl'
                : 'bg-gray-700 hover:bg-gray-600'
            }`}
            title={server.name}
          >
            {server.icon_url ? (
              <img src={server.icon_url} alt={server.name} className="w-full h-full rounded-full" />
            ) : (
              <Hash className="w-6 h-6" />
            )}
          </button>
        ))}
      </div>
    </div>
  );
}
