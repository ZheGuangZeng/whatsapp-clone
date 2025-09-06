# Supabase Storage Setup for File Storage System

This document provides instructions for setting up Supabase Storage buckets and security policies for the WhatsApp Clone file storage system.

## Required Storage Buckets

The file storage system requires the following buckets to be created in Supabase Storage:

### 1. `user-avatars` Bucket
- **Purpose**: Store user profile pictures
- **File size limit**: 2MB
- **Allowed file types**: JPEG, PNG, WebP, GIF

### 2. `chat-media` Bucket  
- **Purpose**: Store images and videos shared in chats
- **File size limit**: 100MB
- **Allowed file types**: Images (JPEG, PNG, WebP, GIF), Videos (MP4, MOV, AVI, WebM)

### 3. `message-attachments` Bucket
- **Purpose**: Store document attachments shared in messages
- **File size limit**: 50MB
- **Allowed file types**: PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX, TXT

### 4. `thumbnails` Bucket
- **Purpose**: Store auto-generated thumbnails for images and videos
- **File size limit**: 1MB
- **Allowed file types**: JPEG

## Creating Storage Buckets

### Using Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to **Storage** in the left sidebar
3. Click **New Bucket** for each bucket needed
4. Configure each bucket with:
   - **Name**: Use exact names from above (`user-avatars`, `chat-media`, etc.)
   - **Public**: Enable for all buckets
   - **File size limit**: Set according to specifications above
   - **Allowed MIME types**: Configure based on file types listed above

### Using SQL Commands

Execute the following SQL commands in your Supabase SQL Editor:

```sql
-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('user-avatars', 'user-avatars', true, 2097152, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']),
  ('chat-media', 'chat-media', true, 104857600, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/webm']),
  ('message-attachments', 'message-attachments', true, 52428800, ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation', 'text/plain']),
  ('thumbnails', 'thumbnails', true, 1048576, ARRAY['image/jpeg']);
```

## Row Level Security (RLS) Policies

### Basic Security Policies

Apply these RLS policies to control access to file storage:

```sql
-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy for user-avatars bucket
-- Users can upload/update their own avatar
CREATE POLICY "Users can upload own avatar" ON storage.objects
FOR INSERT 
TO authenticated
WITH CHECK (
  bucket_id = 'user-avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update own avatar" ON storage.objects
FOR UPDATE 
TO authenticated
USING (
  bucket_id = 'user-avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Everyone can view avatars
CREATE POLICY "Anyone can view avatars" ON storage.objects
FOR SELECT 
TO public
USING (bucket_id = 'user-avatars');

-- Policy for chat-media bucket
-- Users can upload media to chats they participate in
CREATE POLICY "Users can upload chat media" ON storage.objects
FOR INSERT 
TO authenticated
WITH CHECK (
  bucket_id = 'chat-media'
  -- Additional check for room participation should be added based on your rooms table structure
);

-- Users can view media from chats they participate in
CREATE POLICY "Users can view chat media" ON storage.objects
FOR SELECT 
TO authenticated
USING (
  bucket_id = 'chat-media'
  -- Additional check for room participation should be added based on your rooms table structure
);

-- Policy for message-attachments bucket
-- Similar to chat-media but for document attachments
CREATE POLICY "Users can upload message attachments" ON storage.objects
FOR INSERT 
TO authenticated
WITH CHECK (bucket_id = 'message-attachments');

CREATE POLICY "Users can view message attachments" ON storage.objects
FOR SELECT 
TO authenticated
USING (bucket_id = 'message-attachments');

-- Policy for thumbnails bucket
-- System-generated thumbnails
CREATE POLICY "Service can manage thumbnails" ON storage.objects
FOR ALL 
TO authenticated
USING (bucket_id = 'thumbnails');

CREATE POLICY "Anyone can view thumbnails" ON storage.objects
FOR SELECT 
TO public
USING (bucket_id = 'thumbnails');
```

### Advanced Security Policies (Optional)

For enhanced security, you can add more restrictive policies:

```sql
-- Function to check if user is participant in a chat room
CREATE OR REPLACE FUNCTION auth.user_in_room(room_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM room_participants 
    WHERE room_participants.room_id = $1 
    AND room_participants.user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- More restrictive chat media policy
CREATE POLICY "Users can upload to participated rooms only" ON storage.objects
FOR INSERT 
TO authenticated
WITH CHECK (
  bucket_id = 'chat-media'
  AND auth.user_in_room(
    (regexp_match(name, '^([^/]+)/'))[1]::uuid
  )
);
```

## Database Tables

The file storage system requires a `files` table to store metadata:

```sql
-- Create files table for metadata
CREATE TABLE files (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  filename text NOT NULL,
  original_name text NOT NULL,
  file_type text NOT NULL,
  file_size bigint NOT NULL,
  storage_path text NOT NULL,
  thumbnail_path text,
  uploaded_by uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  uploaded_at timestamptz DEFAULT now(),
  metadata jsonb DEFAULT '{}',
  mime_type text,
  checksum text,
  compression_ratio real,
  upload_status text DEFAULT 'completed',
  upload_progress real DEFAULT 100.0,
  
  CONSTRAINT valid_file_type CHECK (file_type IN ('image', 'video', 'audio', 'document', 'other')),
  CONSTRAINT valid_upload_status CHECK (upload_status IN ('pending', 'uploading', 'processing', 'completed', 'failed', 'cancelled')),
  CONSTRAINT valid_upload_progress CHECK (upload_progress >= 0 AND upload_progress <= 100)
);

-- Create indexes for better performance
CREATE INDEX idx_files_uploaded_by ON files(uploaded_by);
CREATE INDEX idx_files_file_type ON files(file_type);
CREATE INDEX idx_files_uploaded_at ON files(uploaded_at);
CREATE INDEX idx_files_upload_status ON files(upload_status);

-- Enable RLS on files table
ALTER TABLE files ENABLE ROW LEVEL SECURITY;

-- RLS policies for files table
CREATE POLICY "Users can insert own files" ON files
FOR INSERT 
TO authenticated
WITH CHECK (auth.uid() = uploaded_by);

CREATE POLICY "Users can view files they uploaded" ON files
FOR SELECT 
TO authenticated
USING (auth.uid() = uploaded_by);

CREATE POLICY "Users can update own files" ON files
FOR UPDATE 
TO authenticated
USING (auth.uid() = uploaded_by);

-- Add file_id column to messages table to link files with messages
ALTER TABLE messages ADD COLUMN file_id uuid REFERENCES files(id) ON DELETE SET NULL;
CREATE INDEX idx_messages_file_id ON messages(file_id);
```

## Environment Configuration

Update your Supabase environment variables:

```env
# In your .env file
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key # For server-side operations

# Update lib/core/constants/app_constants.dart
static const String supabaseUrl = 'https://your-project-id.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
```

## Testing Storage Setup

You can test your storage setup using the following SQL queries:

```sql
-- Test bucket creation
SELECT * FROM storage.buckets;

-- Test RLS policies
SELECT * FROM pg_policies WHERE tablename = 'objects';

-- Test files table
SELECT * FROM files LIMIT 1;
```

## CDN Configuration (Optional)

For global CDN distribution, configure Supabase Edge Functions or use a service like CloudFlare:

1. Set up CloudFlare in front of your Supabase Storage URLs
2. Configure cache rules for different file types:
   - Images/Videos: Cache for 7 days
   - Documents: Cache for 1 day
   - Thumbnails: Cache for 30 days

## Troubleshooting

### Common Issues

1. **Upload fails with permission error**
   - Check RLS policies are correctly set
   - Verify user is authenticated
   - Check bucket permissions

2. **File size limit exceeded**
   - Verify bucket file size limits
   - Check client-side validation

3. **MIME type not allowed**
   - Update bucket allowed MIME types
   - Check file type detection logic

4. **Thumbnails not generating**
   - Check Edge Function deployment
   - Verify image processing dependencies

### Debug Commands

```sql
-- Check storage usage
SELECT bucket_id, count(*), sum(metadata->>'size')::bigint as total_size 
FROM storage.objects 
GROUP BY bucket_id;

-- Check recent uploads
SELECT * FROM storage.objects 
WHERE created_at > now() - interval '1 hour'
ORDER BY created_at DESC;

-- Check files without storage objects
SELECT f.* FROM files f 
LEFT JOIN storage.objects o ON o.name = f.storage_path 
WHERE o.name IS NULL;
```

This completes the Supabase Storage setup for the file storage system. Make sure to test all functionality after setup and adjust security policies based on your specific requirements.