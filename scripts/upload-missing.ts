
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';

dotenv.config();

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.WHATSAPP_TOKEN || '' // Using a token that might have permissions, but wait...
);

// Actually, I should use the SERVICE ROLE KEY if available for uploads
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';
const adminSupabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  serviceRoleKey
);

const BUCKET = 'cakes';
const IMAGES_DIR = path.join(process.cwd(), 'public/images');

async function uploadImage(filePath: string, destName: string) {
  const fileBuffer = fs.readFileSync(filePath);
  
  const { data, error } = await adminSupabase.storage
    .from(BUCKET)
    .upload(destName, fileBuffer, {
      contentType: 'image/png',
      upsert: true
    });

  if (error) {
    console.error(`❌ Failed to upload ${destName}:`, error.message);
    return null;
  }

  const { data: publicUrl } = adminSupabase.storage
    .from(BUCKET)
    .getPublicUrl(destName);

  console.log(`✅ Uploaded ${destName} -> ${publicUrl.publicUrl}`);
  return publicUrl.publicUrl;
}

async function main() {
  console.log('🚀 Starting image upload to Supabase from public/images...');
  
  const files = [
    'mini-cheesecake-blueberry.png',
    'mini-cheesecake-nutella.png',
    'mini-cheesecake-biscoff.png',
    'mini-cheesecake-mango.png',
    'slice-almond-brittle.png',
    'slice-chocolate-mousse.png',
    'slice-chocolate-orange.png',
    'slice-lemon-mousse.png',
    'slice-macaron.png',
    'slice-coconut-mango.png',
    'cat-mini-cheesecakes.png',
    'cat-slices.png'
  ];

  for (const file of files) {
    const filePath = path.join(IMAGES_DIR, file);
    if (fs.existsSync(filePath)) {
      await uploadImage(filePath, file);
    } else {
      console.warn(`⚠️ File not found: ${filePath}`);
    }
  }
}

main();
