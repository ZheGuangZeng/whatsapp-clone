# Multi-Region Supabase Setup for WhatsApp Clone

This document outlines the configuration for deploying Supabase instances across multiple regions (Singapore and Japan) with optimizations for China network access.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐
│   Singapore     │    │     Japan       │
│   (Primary)     │    │  (Secondary)    │
│                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │  Supabase   │ │    │ │  Supabase   │ │
│ │  Instance   │◄├────┤►│  Instance   │ │
│ └─────────────┘ │    │ └─────────────┘ │
│                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ PostgreSQL  │ │    │ │ PostgreSQL  │ │
│ │ (Read/Write)│ │    │ │ (Read Only) │ │
│ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘
         │                       │
         └───────────┬───────────┘
                     │
         ┌─────────────────────┐
         │    Global CDN       │
         │  (China Optimized)  │
         └─────────────────────┘
```

## Supabase Project Configuration

### 1. Singapore Instance (Primary)

**Project Details:**
- Region: Singapore (ap-southeast-1)
- Project Name: whatsapp-clone-production-sg
- Database: PostgreSQL 15 with extensions
- Storage: Regional buckets for file storage
- Real-time: WebSocket connections for messaging
- Auth: Primary authentication provider

**Configuration:**
```bash
# Create Singapore project
supabase projects create whatsapp-clone-production-sg \
  --org-id YOUR_ORG_ID \
  --region ap-southeast-1 \
  --plan pro

# Configure database
supabase db remote set postgresql://postgres:YOUR_PASSWORD@db.YOUR_PROJECT_REF.supabase.co:5432/postgres

# Apply schema
supabase db push --project-ref YOUR_SINGAPORE_PROJECT_REF

# Configure storage buckets
supabase storage create user-avatars --public=false --project-ref YOUR_SINGAPORE_PROJECT_REF
supabase storage create chat-media --public=false --project-ref YOUR_SINGAPORE_PROJECT_REF
supabase storage create message-attachments --public=false --project-ref YOUR_SINGAPORE_PROJECT_REF
supabase storage create thumbnails --public=true --project-ref YOUR_SINGAPORE_PROJECT_REF
```

### 2. Japan Instance (Secondary)

**Project Details:**
- Region: Japan (ap-northeast-1)  
- Project Name: whatsapp-clone-production-jp
- Database: PostgreSQL 15 (read replica configuration)
- Storage: Regional buckets with cross-region sync
- Real-time: Regional WebSocket endpoint
- Auth: Synchronized with primary

**Configuration:**
```bash
# Create Japan project
supabase projects create whatsapp-clone-production-jp \
  --org-id YOUR_ORG_ID \
  --region ap-northeast-1 \
  --plan pro

# Configure as read replica
supabase db remote set postgresql://postgres:YOUR_PASSWORD@db.YOUR_JAPAN_PROJECT_REF.supabase.co:5432/postgres

# Apply same schema
supabase db push --project-ref YOUR_JAPAN_PROJECT_REF

# Create storage buckets (synchronized with primary)
supabase storage create user-avatars --public=false --project-ref YOUR_JAPAN_PROJECT_REF
supabase storage create chat-media --public=false --project-ref YOUR_JAPAN_PROJECT_REF
supabase storage create message-attachments --public=false --project-ref YOUR_JAPAN_PROJECT_REF
supabase storage create thumbnails --public=true --project-ref YOUR_JAPAN_PROJECT_REF
```

## Database Replication Setup

### Primary-Secondary Configuration

```sql
-- On Singapore instance (Primary)
-- Configure logical replication for real-time sync

-- Create publication for all tables
CREATE PUBLICATION whatsapp_clone_publication FOR ALL TABLES;

-- Configure replication user
CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'secure_replication_password';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO replicator;
GRANT USAGE ON SCHEMA public TO replicator;

-- On Japan instance (Secondary)
-- Create subscription to Singapore instance
CREATE SUBSCRIPTION whatsapp_clone_subscription 
CONNECTION 'host=db.YOUR_SINGAPORE_PROJECT_REF.supabase.co port=5432 user=replicator password=secure_replication_password dbname=postgres sslmode=require'
PUBLICATION whatsapp_clone_publication;
```

### Automated Failover Configuration

```sql
-- Create health check function
CREATE OR REPLACE FUNCTION check_primary_health()
RETURNS boolean AS $$
DECLARE
    result boolean;
BEGIN
    -- Check if primary is responsive
    SELECT true INTO result 
    FROM pg_stat_activity 
    WHERE state = 'active' 
    LIMIT 1;
    
    RETURN COALESCE(result, false);
EXCEPTION WHEN OTHERS THEN
    RETURN false;
END;
$$ LANGUAGE plpgsql;

-- Create automatic failover trigger
CREATE OR REPLACE FUNCTION promote_to_primary()
RETURNS void AS $$
BEGIN
    -- Promote secondary to primary
    -- This would typically involve Supabase API calls
    -- or infrastructure automation
    RAISE NOTICE 'Promoting Japan instance to primary';
END;
$$ LANGUAGE plpgsql;
```

## Environment Configuration

### Singapore Configuration (.env.singapore)

```bash
# Singapore Supabase Configuration
SUPABASE_URL=https://YOUR_SINGAPORE_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

# Database Direct Connection (for emergencies)
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@db.YOUR_SINGAPORE_PROJECT_REF.supabase.co:5432/postgres

# Real-time Configuration
REALTIME_URL=wss://YOUR_SINGAPORE_PROJECT_REF.supabase.co/realtime/v1/websocket

# Storage Configuration  
STORAGE_URL=https://YOUR_SINGAPORE_PROJECT_REF.supabase.co/storage/v1

# Region Settings
REGION=ap-southeast-1
TIMEZONE=Asia/Singapore
```

### Japan Configuration (.env.japan)

```bash
# Japan Supabase Configuration
SUPABASE_URL=https://YOUR_JAPAN_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

# Database Direct Connection
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@db.YOUR_JAPAN_PROJECT_REF.supabase.co:5432/postgres

# Real-time Configuration
REALTIME_URL=wss://YOUR_JAPAN_PROJECT_REF.supabase.co/realtime/v1/websocket

# Storage Configuration
STORAGE_URL=https://YOUR_JAPAN_PROJECT_REF.supabase.co/storage/v1

# Region Settings
REGION=ap-northeast-1  
TIMEZONE=Asia/Tokyo
```

## Row Level Security (RLS) Policies

Ensure consistent security policies across both instances:

```sql
-- Users table policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users  
  FOR UPDATE USING (auth.uid() = id);

-- Messages table policies
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view messages in their chats" ON messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_participants cp 
      WHERE cp.chat_id = messages.chat_id 
      AND cp.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert messages in their chats" ON messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
      SELECT 1 FROM chat_participants cp
      WHERE cp.chat_id = messages.chat_id
      AND cp.user_id = auth.uid()
    )
  );

-- Files table policies  
ALTER TABLE files ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view files they uploaded" ON files
  FOR SELECT USING (auth.uid() = uploaded_by);

CREATE POLICY "Users can upload files" ON files
  FOR INSERT WITH CHECK (auth.uid() = uploaded_by);
```

## Storage Bucket Policies

Configure bucket policies for both regions:

```sql
-- User avatars bucket (private)
INSERT INTO storage.buckets (id, name, public) VALUES ('user-avatars', 'user-avatars', false);

CREATE POLICY "Users can upload own avatar" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'user-avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view own avatar" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'user-avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Chat media bucket (private)
INSERT INTO storage.buckets (id, name, public) VALUES ('chat-media', 'chat-media', false);

CREATE POLICY "Users can upload chat media" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'chat-media' AND
    auth.uid() IS NOT NULL
  );

CREATE POLICY "Users can view chat media they have access to" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'chat-media' AND
    auth.uid() IS NOT NULL
  );

-- Thumbnails bucket (public)
INSERT INTO storage.buckets (id, name, public) VALUES ('thumbnails', 'thumbnails', true);
```

## Real-time Subscriptions Configuration

Configure real-time channels for both regions:

```javascript
// Primary region subscription (Singapore)
const supabasePrimary = createClient(
  process.env.SUPABASE_URL_SINGAPORE,
  process.env.SUPABASE_ANON_KEY_SINGAPORE
);

// Secondary region subscription (Japan)  
const supabaseSecondary = createClient(
  process.env.SUPABASE_URL_JAPAN,
  process.env.SUPABASE_ANON_KEY_JAPAN
);

// Intelligent routing based on user location
function getOptimalSupabaseClient(userLocation) {
  // For China users, prefer Japan region (better connectivity)
  if (userLocation.country === 'CN') {
    return supabaseSecondary;
  }
  
  // For other Asian countries, prefer Singapore
  return supabasePrimary;
}
```

## Monitoring and Health Checks

### Health Check Endpoints

```sql
-- Create health check function
CREATE OR REPLACE FUNCTION health_check()
RETURNS json AS $$
DECLARE
  result json;
BEGIN
  SELECT json_build_object(
    'status', 'healthy',
    'timestamp', now(),
    'region', current_setting('cluster_name', true),
    'database_size', pg_database_size(current_database()),
    'active_connections', count(*)
  ) INTO result
  FROM pg_stat_activity
  WHERE state = 'active';
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Create monitoring view
CREATE OR REPLACE VIEW system_metrics AS
SELECT 
  'database_connections' as metric,
  count(*) as value,
  now() as timestamp
FROM pg_stat_activity
UNION ALL
SELECT 
  'database_size_mb' as metric,
  round(pg_database_size(current_database()) / 1024 / 1024) as value,
  now() as timestamp
UNION ALL  
SELECT
  'replication_lag_seconds' as metric,
  extract(epoch from (now() - pg_last_xact_replay_timestamp()))::int as value,
  now() as timestamp;
```

## Deployment Commands

### Initial Setup

```bash
#!/bin/bash

# 1. Create both Supabase projects
echo "Creating Singapore project..."
supabase projects create whatsapp-clone-production-sg --org-id $ORG_ID --region ap-southeast-1 --plan pro

echo "Creating Japan project..."  
supabase projects create whatsapp-clone-production-jp --org-id $ORG_ID --region ap-northeast-1 --plan pro

# 2. Apply database schema to both
echo "Applying schema to Singapore..."
supabase db push --project-ref $SINGAPORE_PROJECT_REF

echo "Applying schema to Japan..."
supabase db push --project-ref $JAPAN_PROJECT_REF

# 3. Configure storage buckets
echo "Setting up storage buckets..."
supabase storage create user-avatars --project-ref $SINGAPORE_PROJECT_REF
supabase storage create chat-media --project-ref $SINGAPORE_PROJECT_REF
supabase storage create message-attachments --project-ref $SINGAPORE_PROJECT_REF
supabase storage create thumbnails --public --project-ref $SINGAPORE_PROJECT_REF

supabase storage create user-avatars --project-ref $JAPAN_PROJECT_REF  
supabase storage create chat-media --project-ref $JAPAN_PROJECT_REF
supabase storage create message-attachments --project-ref $JAPAN_PROJECT_REF
supabase storage create thumbnails --public --project-ref $JAPAN_PROJECT_REF

# 4. Configure replication
echo "Setting up database replication..."
# This would involve SQL commands to set up logical replication

echo "Multi-region Supabase setup completed!"
```

## Disaster Recovery Procedures

### Automatic Failover

```bash
#!/bin/bash

# Monitor primary region health
monitor_primary_health() {
  while true; do
    if ! curl -sf "https://$SINGAPORE_PROJECT_REF.supabase.co/rest/v1/rpc/health_check" > /dev/null; then
      echo "Primary region unhealthy, initiating failover..."
      failover_to_secondary
      break
    fi
    sleep 30
  done
}

# Failover to Japan region
failover_to_secondary() {
  # Update DNS records to point to Japan instance
  aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://failover-changeset.json
  
  # Promote Japan instance to primary (manual intervention required for Supabase)
  echo "Manual intervention required: Promote Japan Supabase instance to primary"
  
  # Update application configuration
  kubectl patch configmap whatsapp-clone-config -p '{"data":{"SUPABASE_URL":"'$JAPAN_SUPABASE_URL'"}}'
  kubectl rollout restart deployment/whatsapp-clone-web
}
```

This multi-region setup provides high availability, disaster recovery, and optimized performance for users across Asia-Pacific, including China.