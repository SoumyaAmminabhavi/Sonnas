
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';
import { env } from '../src/env';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
);

const BUCKET = 'cakes';
const BRAIN_DIR = 'C:/Users/israr/.gemini/antigravity/brain/11fcb57f-1921-4bcd-aa44-86209cc673c9';

const imageMap = [
  { id: 1, file: 'classic_chocolate_cake_1777276295602.png', name: 'classic-chocolate.png' },
  { id: 2, file: 'almond_brittle_cake_1777276310338.png', name: 'almond-brittle.png' },
  { id: 3, file: 'orange_chocolate_cake_1777276325072.png', name: 'orange-chocolate.png' },
  { id: 4, file: 'hazelnut_chocolate_cake_1777276345329.png', name: 'hazelnut-chocolate.png' },
  { id: 5, file: 'coffee_chocolate_cake_1777276361292.png', name: 'coffee-chocolate.png' },
  { id: 6, file: 'white_chocolate_cake_1777276376977.png', name: 'white-chocolate.png' },
  { id: 7, file: 'pina_colada_cake_1777276398374.png', name: 'pina-colada.png' },
  { id: 8, file: 'pineapple_cake_1777276417072.png', name: 'pineapple.png' },
  { id: 9, file: 'rich_mawa_cake_1777276433965.png', name: 'rich-mawa.png' },
  { id: 10, file: 'persian_cake_image_1777276454219.png', name: 'persian-cake.png' },
  { id: 11, file: 'butter_cake_image_1777276467887.png', name: 'butter-cake.png' },
  { id: 12, file: 'strawberry_chocolate_cake_1777276481350.png', name: 'strawberry-chocolate.png' },
  { id: 13, file: 'strawberry_vanilla_cake_1777276497606.png', name: 'strawberry-vanilla.png' },
  { cat: 'chocolate', file: 'chocolate_category_image_1777276533684.png', name: 'cat-chocolate.png' },
  { cat: 'vanilla', file: 'vanilla_category_image_1777276550037.png', name: 'cat-vanilla.png' },
  { cat: 'tea', file: 'tea_category_image_1777276563350.png', name: 'cat-tea.png' },
  { cat: 'seasonal', file: 'strawberry_vanilla_cake_1777276497606.png', name: 'cat-seasonal.png' },
];

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
  console.log('🚀 Starting image upload to Supabase...');
  
  const results: any = { products: {}, categories: {} };

  for (const item of imageMap) {
    const filePath = path.join(BRAIN_DIR, item.file);
    if (!fs.existsSync(filePath)) {
      console.warn(`⚠️ File not found: ${filePath}`);
      continue;
    }

    const url = await uploadImage(filePath, item.name);
    if (url) {
      if ('id' in item) {
        results.products[item.id] = url;
      } else if ('cat' in item) {
        results.categories[item.cat] = url;
      }
    }
  }

  console.log('\n📦 Resulting URLs for update:');
  console.log(JSON.stringify(results, null, 2));
}

main();
