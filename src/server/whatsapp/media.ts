
import { env } from "~/env";
import { createClient } from "@supabase/supabase-js";

// Initialize Supabase Client with Service Role for backend uploads
// Note: You must add SUPABASE_SERVICE_ROLE_KEY to your .env
const supabase = createClient(
  env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY ?? env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

/**
 * Downloads an image from WhatsApp and uploads it to Supabase Storage
 * Returns the public URL of the uploaded image
 */
export async function downloadAndUploadImage(mediaId: string): Promise<string | null> {
  try {
    if (!env.WHATSAPP_TOKEN) return null;

    // 1. Get the media URL from Meta
    const metaResponse = await fetch(`https://graph.facebook.com/v18.0/${mediaId}`, {
      headers: { Authorization: `Bearer ${env.WHATSAPP_TOKEN}` },
    });

    if (!metaResponse.ok) {
      console.error("[WhatsApp Media] Failed to get media URL:", await metaResponse.text());
      return null;
    }

    const { url } = (await metaResponse.json()) as { url: string };

    // 2. Download the actual image bytes
    const imageResponse = await fetch(url, {
      headers: { Authorization: `Bearer ${env.WHATSAPP_TOKEN}` },
    });

    if (!imageResponse.ok) {
      console.error("[WhatsApp Media] Failed to download image:", await imageResponse.text());
      return null;
    }

    const blob = await imageResponse.blob();
    const fileName = `custom_${mediaId}_${Date.now()}.jpg`;

    // 3. Upload to Supabase Storage (bucket: "cakes")
    // Note: Ensure the "cakes" bucket exists and has public access
    const { data, error } = await supabase.storage
      .from("cakes")
      .upload(`custom-requests/${fileName}`, blob, {
        contentType: blob.type,
        upsert: true,
      });

    if (error) {
      console.error("[WhatsApp Media] Supabase upload failed:", error);
      return null;
    }

    // 4. Get the public URL
    const { data: { publicUrl } } = supabase.storage
      .from("cakes")
      .getPublicUrl(data.path);

    return publicUrl;
  } catch (e) {
    console.error("[WhatsApp Media] Error in media pipeline:", e);
    return null;
  }
}
