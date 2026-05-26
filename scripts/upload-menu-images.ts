
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import { env } from '../src/env';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
);

const BUCKET = 'cakes';
const IMAGES_DIR = path.join(process.cwd(), 'public/images');

async function uploadImage(filePath: string, destName: string) {
  const fileBuffer = fs.readFileSync(filePath);
  
  const { data, error } = await supabase.storage
    .from(BUCKET)
    .upload(destName, fileBuffer, {
      contentType: 'image/png',
      upsert: true
    });

  if (error) {
    console.error(`❌ Failed to upload ${destName}:`, error.message);
    return null;
  }

  const { data: publicUrl } = supabase.storage
    .from(BUCKET)
    .getPublicUrl(destName);

  console.log(`✅ Uploaded ${destName} -> ${publicUrl.publicUrl}`);
  return publicUrl.publicUrl;
}

async function main() {
  console.log('🚀 Starting image upload to Supabase from public/images...');
  
  if (!fs.existsSync(IMAGES_DIR)) {
    console.error(`❌ Directory not found: ${IMAGES_DIR}`);
    return;
  }

  const files = fs.readdirSync(IMAGES_DIR);
  const results: any = { urls: {} };

  for (const file of files) {
    if (!file.match(/\.(png|jpg|jpeg|webp)$/i)) continue;

    const filePath = path.join(IMAGES_DIR, file);
    const url = await uploadImage(filePath, file);
    if (url) {
      results.urls[file] = url;
    }
  }

  console.log('\n📦 All Public URLs:');
  console.log(JSON.stringify(results, null, 2));
}

main();
