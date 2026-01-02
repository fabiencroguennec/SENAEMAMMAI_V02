-- 1. Create or Update 'images' bucket to be PUBLIC
INSERT INTO storage.buckets (id, name, public)
VALUES ('images', 'images', true)
ON CONFLICT (id) DO UPDATE
SET public = true;

-- 2. Drop existing policies to start fresh
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Public Upload" ON storage.objects;
DROP POLICY IF EXISTS "Public Update" ON storage.objects;
DROP POLICY IF EXISTS "Public Delete" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Upload" ON storage.objects;

-- 3. Create SIMPLE and PERMISSIVE policies for Development
-- Allow ANYONE (inclusive of anonymous users) to SELECT
CREATE POLICY "Public Select"
ON storage.objects FOR SELECT
USING ( bucket_id = 'images' );

-- Allow ANYONE to INSERT
CREATE POLICY "Public Insert"
ON storage.objects FOR INSERT
WITH CHECK ( bucket_id = 'images' );

-- Allow ANYONE to UPDATE
CREATE POLICY "Public Update"
ON storage.objects FOR UPDATE
USING ( bucket_id = 'images' );

-- Allow ANYONE to DELETE
CREATE POLICY "Public Delete"
ON storage.objects FOR DELETE
USING ( bucket_id = 'images' );
