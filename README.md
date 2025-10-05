# MiniCord

A modern, real-time chat application inspired by Discord, built with React, TypeScript, Tailwind CSS, and Supabase.

![MiniCord](https://img.shields.io/badge/MiniCord-Chat%20App-blue)
![React](https://img.shields.io/badge/React-18.3-61dafb)
![TypeScript](https://img.shields.io/badge/TypeScript-5.5-3178c6)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ecf8e)

## Overview

MiniCord is a full-featured communication platform that enables users to create servers, organize channels, and engage in real-time conversations. Built with modern web technologies, it offers a seamless, Discord-like experience with robust authentication, real-time messaging, and a beautiful, responsive UI.

## Features

### Core Functionality

- **User Authentication**
  - Email/password registration and login
  - Secure session management with Supabase Auth
  - Automatic profile creation on signup
  - Online/offline status tracking

- **Server Management**
  - Create custom servers with names and descriptions
  - Server ownership and membership system
  - Role-based access control (Owner, Admin, Member)
  - Server list sidebar with visual indicators

- **Channel System**
  - Text and voice channel types
  - Create unlimited channels within servers
  - Channel organization and navigation
  - Automatic default "general" channel

- **Real-time Messaging**
  - Instant message delivery with Supabase Realtime
  - Message history and persistence
  - User avatars and timestamps
  - Smooth auto-scrolling to latest messages

- **User Interface**
  - Discord-inspired modern design
  - Dark/light theme toggle with persistence
  - Fully responsive layout (mobile, tablet, desktop)
  - Smooth animations and transitions
  - Custom scrollbar styling

### Technical Features

- **Security**
  - Row Level Security (RLS) on all database tables
  - Secure authentication flow
  - Protected routes and API calls
  - Environment variable management

- **Performance**
  - Optimized database queries with indexes
  - Efficient real-time subscriptions
  - Code splitting and lazy loading
  - Fast build times with Vite

- **Database Architecture**
  - PostgreSQL with Supabase
  - Comprehensive schema with 7 tables
  - Foreign key relationships
  - Automatic triggers and functions

## Tech Stack

### Frontend
- **React 18.3** - UI library
- **TypeScript 5.5** - Type safety
- **Vite 5.4** - Build tool and dev server
- **Tailwind CSS 3.4** - Utility-first CSS
- **Lucide React** - Icon library

### Backend
- **Supabase** - Backend as a Service
  - PostgreSQL database
  - Real-time subscriptions
  - Authentication
  - Row Level Security

### Development Tools
- **ESLint** - Code linting
- **TypeScript ESLint** - TS-specific linting
- **PostCSS** - CSS processing
- **Autoprefixer** - CSS vendor prefixes

## Database Schema

### Tables

1. **profiles** - Extended user information
   - `id` (uuid, FK to auth.users)
   - `username` (text, unique)
   - `avatar_url` (text)
   - `bio` (text)
   - `status` (enum: online, offline, away, dnd)

2. **servers** - Community spaces
   - `id` (uuid)
   - `name` (text)
   - `description` (text)
   - `icon_url` (text)
   - `owner_id` (uuid, FK to profiles)

3. **server_members** - Server membership tracking
   - `id` (uuid)
   - `server_id` (uuid, FK to servers)
   - `user_id` (uuid, FK to profiles)
   - `role` (enum: owner, admin, member)

4. **channels** - Communication channels
   - `id` (uuid)
   - `server_id` (uuid, FK to servers)
   - `name` (text)
   - `type` (enum: text, voice)
   - `position` (integer)

5. **messages** - Channel messages
   - `id` (uuid)
   - `channel_id` (uuid, FK to channels)
   - `user_id` (uuid, FK to profiles)
   - `content` (text)
   - `attachments` (jsonb)

6. **direct_messages** - Private conversations
   - `id` (uuid)
   - `sender_id` (uuid, FK to profiles)
   - `receiver_id` (uuid, FK to profiles)
   - `content` (text)
   - `read` (boolean)

7. **friendships** - User connections
   - `id` (uuid)
   - `user_id` (uuid, FK to profiles)
   - `friend_id` (uuid, FK to profiles)
   - `status` (enum: pending, accepted, blocked)

### Security

All tables are protected with Row Level Security policies:
- Users can only access servers they're members of
- Messages are restricted to channel/server members
- Profiles are publicly viewable but only editable by owner
- Server management restricted to owners/admins

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- A Supabase account and project
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/minicord.git
   cd minicord
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up Supabase**
   - Create a new project at [supabase.com](https://supabase.com)
   - Copy your project URL and anon key
   - Run the migrations in `supabase/migrations/` in order

4. **Configure environment variables**

   Create a `.env` file in the root directory:
   ```env
   VITE_SUPABASE_URL=your_supabase_project_url
   VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

5. **Start the development server**
   ```bash
   npm run dev
   ```

   The app will be available at `http://localhost:5173`

### Building for Production

```bash
npm run build
```

The built files will be in the `dist/` directory.

### Type Checking

```bash
npm run typecheck
```

### Linting

```bash
npm run lint
```

## Deployment

### GitHub Pages

This project includes a GitHub Actions workflow for automatic deployment to GitHub Pages.

#### Setup

1. **Enable GitHub Pages**
   - Go to your repository Settings → Pages
   - Source: GitHub Actions

2. **Add Secrets**
   - Go to Settings → Secrets and variables → Actions
   - Add two secrets:
     - `VITE_SUPABASE_URL`: Your Supabase project URL
     - `VITE_SUPABASE_ANON_KEY`: Your Supabase anon key

3. **Deploy**
   - Push to the `main` branch
   - The workflow will automatically build and deploy
   - Your app will be available at `https://yourusername.github.io/minicord/`

#### Manual Deployment

```bash
npm run build
# Deploy the dist/ directory to your hosting provider
```

### Other Platforms

**Vercel**
```bash
npm i -g vercel
vercel --prod
```

**Netlify**
```bash
npm i -g netlify-cli
netlify deploy --prod --dir=dist
```

## Project Structure

```
minicord/
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Pages deployment
├── src/
│   ├── components/
│   │   ├── Auth/               # Authentication components
│   │   │   ├── AuthPage.tsx
│   │   │   ├── LoginForm.tsx
│   │   │   └── SignUpForm.tsx
│   │   ├── Chat/               # Messaging components
│   │   │   ├── ChatArea.tsx
│   │   │   ├── MessageInput.tsx
│   │   │   └── MessageList.tsx
│   │   ├── Dashboard/          # Main app layout
│   │   │   └── MainDashboard.tsx
│   │   ├── Layout/             # Navigation components
│   │   │   ├── ChannelSidebar.tsx
│   │   │   └── ServerList.tsx
│   │   └── Modals/             # Dialog components
│   │       ├── CreateChannelModal.tsx
│   │       └── CreateServerModal.tsx
│   ├── contexts/
│   │   ├── AuthContext.tsx     # Authentication state
│   │   └── ThemeContext.tsx    # Theme management
│   ├── lib/
│   │   ├── database.types.ts   # TypeScript types
│   │   └── supabase.ts         # Supabase client
│   ├── App.tsx                 # Main app component
│   ├── main.tsx                # App entry point
│   └── index.css               # Global styles
├── supabase/
│   └── migrations/             # Database migrations
├── .env                        # Environment variables
├── package.json
├── vite.config.ts
├── tailwind.config.js
└── README.md
```

## Usage Guide

### Getting Started

1. **Create an Account**
   - Click "Sign up" on the auth page
   - Enter your username, email, and password
   - You'll be automatically logged in

2. **Create a Server**
   - Click the "+" button in the server list
   - Enter a server name and optional description
   - Your server will be created with a default "general" channel

3. **Create Channels**
   - Click the "+" next to "Text Channels" or "Voice Channels"
   - Choose channel type (text or voice)
   - Enter a channel name

4. **Start Chatting**
   - Select a channel from the sidebar
   - Type your message and press Enter or click Send
   - Messages appear in real-time for all server members

5. **Customize Experience**
   - Toggle between dark and light themes
   - Update your profile and status
   - Manage your servers and channels

### Keyboard Shortcuts

- `Enter` - Send message
- `Esc` - Close modals

## Roadmap

Future features planned for MiniCord:

- [ ] Voice and video calling with WebRTC
- [ ] File upload and sharing
- [ ] Image attachments and embeds
- [ ] User profile customization
- [ ] Friend system implementation
- [ ] Direct messaging
- [ ] Message editing and deletion
- [ ] Server invites and invite links
- [ ] User mentions and notifications
- [ ] Emoji reactions
- [ ] Rich text formatting
- [ ] Server roles and permissions
- [ ] Moderation tools
- [ ] Message search
- [ ] User presence indicators
- [ ] Typing indicators
- [ ] Read receipts
- [ ] Custom server emojis
- [ ] Server discovery

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow the existing code style
- Add TypeScript types for all new code
- Test your changes thoroughly
- Update documentation as needed
- Keep commits focused and descriptive

## Troubleshooting

### Common Issues

**RLS Policy Errors**
- Ensure all database migrations have been applied
- Check that your Supabase policies are correctly configured
- Verify user authentication status

**Real-time Not Working**
- Check your Supabase project has Realtime enabled
- Verify the channel subscriptions are properly set up
- Check browser console for WebSocket errors

**Build Failures**
- Clear node_modules and reinstall: `rm -rf node_modules && npm install`
- Check that all environment variables are set
- Run type checking: `npm run typecheck`

**Authentication Issues**
- Verify Supabase credentials in `.env`
- Check that email confirmation is disabled in Supabase settings
- Clear browser storage and try again

## Security Considerations

- Never commit `.env` files to version control
- Use environment variables for all sensitive data
- Keep Supabase anon key public but service role key private
- RLS policies provide database-level security
- Always sanitize user input
- Keep dependencies updated

## Performance Tips

- Messages are loaded in batches for better performance
- Real-time subscriptions are cleaned up on unmount
- Indexes are added to frequently queried columns
- Lazy loading can be added for large server lists
- Consider implementing message pagination

## Browser Support

MiniCord supports all modern browsers:
- Chrome/Edge 90+
- Firefox 88+
- Safari 14+
- Opera 76+

## License

This project is open source and available under the [MIT License](LICENSE).

## Acknowledgments

- Inspired by [Discord](https://discord.com)
- Built with [Supabase](https://supabase.com)
- Icons from [Lucide](https://lucide.dev)
- Styled with [Tailwind CSS](https://tailwindcss.com)

## Contact

Project Link: [https://github.com/yourusername/minicord](https://github.com/yourusername/minicord)

---

**Note**: This is an educational project built to demonstrate modern web development practices with React, TypeScript, and Supabase. It is not affiliated with Discord, Inc.
