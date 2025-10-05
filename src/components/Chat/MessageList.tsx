import { useEffect, useState, useRef } from 'react';
import { supabase } from '../../lib/supabase';
import type { Database } from '../../lib/database.types';

type Message = Database['public']['Tables']['messages']['Row'] & {
  profile: {
    username: string;
    avatar_url: string | null;
  };
};

interface MessageListProps {
  channelId: string | null;
}

export function MessageList({ channelId }: MessageListProps) {
  const [messages, setMessages] = useState<Message[]>([]);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!channelId) return;

    loadMessages();

    const subscription = supabase
      .channel(`messages:${channelId}`)
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
        filter: `channel_id=eq.${channelId}`
      }, async (payload) => {
        const { data } = await supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', payload.new.user_id)
          .maybeSingle();

        if (data) {
          const newMessage: Message = {
            ...(payload.new as Database['public']['Tables']['messages']['Row']),
            profile: data
          };
          setMessages(prev => [...prev, newMessage]);
        }
      })
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, [channelId]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const loadMessages = async () => {
    if (!channelId) return;

    const { data: messageData } = await supabase
      .from('messages')
      .select('*')
      .eq('channel_id', channelId)
      .order('created_at', { ascending: true });

    if (!messageData) return;

    const userIds = [...new Set(messageData.map(m => m.user_id))];

    const { data: profileData } = await supabase
      .from('profiles')
      .select('id, username, avatar_url')
      .in('id', userIds);

    if (profileData) {
      const profileMap = new Map(profileData.map(p => [p.id, p]));
      const messagesWithProfiles: Message[] = messageData.map(msg => ({
        ...msg,
        profile: {
          username: profileMap.get(msg.user_id)?.username || 'Unknown',
          avatar_url: profileMap.get(msg.user_id)?.avatar_url || null
        }
      }));
      setMessages(messagesWithProfiles);
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const formatTime = (timestamp: string) => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
  };

  if (!channelId) {
    return (
      <div className="flex-1 flex items-center justify-center text-gray-400">
        Select a channel to start chatting
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-y-auto p-4 space-y-4">
      {messages.map((message) => (
        <div key={message.id} className="flex space-x-3 hover:bg-gray-700/30 px-2 py-1 rounded">
          <div className="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center text-white font-semibold flex-shrink-0">
            {message.profile.avatar_url ? (
              <img
                src={message.profile.avatar_url}
                alt={message.profile.username}
                className="w-full h-full rounded-full"
              />
            ) : (
              message.profile.username[0].toUpperCase()
            )}
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-baseline space-x-2">
              <span className="font-semibold text-white">
                {message.profile.username}
              </span>
              <span className="text-xs text-gray-400">
                {formatTime(message.created_at)}
              </span>
            </div>
            <p className="text-gray-300 break-words">{message.content}</p>
          </div>
        </div>
      ))}
      <div ref={messagesEndRef} />
    </div>
  );
}
