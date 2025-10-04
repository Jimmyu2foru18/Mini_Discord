import { useState } from 'react';
import { supabase } from '../../lib/supabase';
import { X, Hash, Volume2 } from 'lucide-react';

interface CreateChannelModalProps {
  serverId: string;
  onClose: () => void;
}

export function CreateChannelModal({ serverId, onClose }: CreateChannelModalProps) {
  const [name, setName] = useState('');
  const [type, setType] = useState<'text' | 'voice'>('text');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    setLoading(true);
    setError('');

    const { error: channelError } = await supabase
      .from('channels')
      .insert({
        server_id: serverId,
        name: name.trim().toLowerCase().replace(/\s+/g, '-'),
        type,
      });

    if (channelError) {
      setError(channelError.message);
      setLoading(false);
      return;
    }

    setLoading(false);
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-xl w-full max-w-md">
        <div className="flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-700">
          <h2 className="text-xl font-bold text-gray-900 dark:text-white">Create Channel</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-4 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
              Channel Type
            </label>
            <div className="grid grid-cols-2 gap-3">
              <button
                type="button"
                onClick={() => setType('text')}
                className={`p-4 border-2 rounded-lg transition-colors ${
                  type === 'text'
                    ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                    : 'border-gray-300 dark:border-gray-600 hover:border-gray-400 dark:hover:border-gray-500'
                }`}
              >
                <Hash className={`w-8 h-8 mx-auto mb-2 ${type === 'text' ? 'text-blue-500' : 'text-gray-400'}`} />
                <span className="text-sm font-medium text-gray-900 dark:text-white">Text</span>
              </button>
              <button
                type="button"
                onClick={() => setType('voice')}
                className={`p-4 border-2 rounded-lg transition-colors ${
                  type === 'voice'
                    ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                    : 'border-gray-300 dark:border-gray-600 hover:border-gray-400 dark:hover:border-gray-500'
                }`}
              >
                <Volume2 className={`w-8 h-8 mx-auto mb-2 ${type === 'voice' ? 'text-blue-500' : 'text-gray-400'}`} />
                <span className="text-sm font-medium text-gray-900 dark:text-white">Voice</span>
              </button>
            </div>
          </div>

          <div>
            <label htmlFor="channel-name" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Channel Name
            </label>
            <input
              id="channel-name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
              maxLength={100}
              className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
              placeholder="general"
            />
            <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
              Spaces will be converted to dashes
            </p>
          </div>

          {error && (
            <div className="p-3 bg-red-100 dark:bg-red-900/30 border border-red-400 dark:border-red-700 text-red-700 dark:text-red-400 rounded-lg text-sm">
              {error}
            </div>
          )}

          <div className="flex space-x-3">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2 px-4 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading || !name.trim()}
              className="flex-1 py-2 px-4 bg-blue-500 hover:bg-blue-600 text-white rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Creating...' : 'Create'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
