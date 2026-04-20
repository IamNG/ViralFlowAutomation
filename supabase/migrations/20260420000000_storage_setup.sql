-- Setup for Supabase Storage Buckets
-- Creates buckets and assigns RLS policies for authenticated users.

-- Create content-media bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('content-media', 'content-media', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies for content-media

-- 1. Allow public to READ (view/download) media
CREATE POLICY "Public media access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'content-media' );

-- 2. Allow authenticated users to INSERT (upload) media
CREATE POLICY "Users can upload media"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'content-media' AND auth.uid()::text = (storage.foldername(name))[1] );

-- 3. Allow authenticated users to DELETE their own media
CREATE POLICY "Users can delete own media"
ON storage.objects FOR DELETE
TO authenticated
USING ( bucket_id = 'content-media' AND auth.uid()::text = (storage.foldername(name))[1] );

-- 4. Allow authenticated users to UPDATE their own media
CREATE POLICY "Users can update own media"
ON storage.objects FOR UPDATE
TO authenticated
USING ( bucket_id = 'content-media' AND auth.uid()::text = (storage.foldername(name))[1] );
