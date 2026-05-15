import { type NextRequest, NextResponse } from "next/server";
import { supabase } from "~/lib/supabase";
import { auth } from "~/server/auth";

const ALLOWED_TYPES = new Set(["image/jpeg", "image/png", "image/webp"]);
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

export async function POST(request: NextRequest) {
  try {
    // 1. Auth check
    const session = await auth();
    const adminKey = request.headers.get("x-admin-key");
    const bypassKey = process.env.ADMIN_BYPASS_KEY;
    
    const isAuthorized = 
      !!session?.user || 
      (bypassKey && adminKey === bypassKey);


    if (!isAuthorized) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }


    const formData = await request.formData();
    const file = formData.get("file") as File | null;
    
    if (!file) {
      return NextResponse.json({ error: "No file uploaded" }, { status: 400 });
    }

    // 2. Strict file validation
    if (!ALLOWED_TYPES.has(file.type)) {
      return NextResponse.json(
        { error: "Unsupported file type. Please upload JPEG, PNG, or WEBP." }, 
        { status: 415 }
      );
    }

    if (file.size > MAX_FILE_SIZE) {
      return NextResponse.json(
        { error: "File too large. Maximum size allowed is 5MB." }, 
        { status: 413 }
      );
    }

    const buffer = await file.arrayBuffer();

    // ── Determine stable filename ─────────────────────────────────────────
    // If a slug is provided (e.g. ?slug=chocolate-indulgence), use it as a
    // deterministic filename so the Supabase public URL never changes when
    // the image is replaced. The WhatsApp bot always fetches the latest image
    // from the same URL automatically.
    const slug = request.nextUrl.searchParams.get("slug");
    const ext = file.type === "image/png" ? "png" : file.type === "image/webp" ? "webp" : "jpg";

    let finalFilename: string;
    if (slug) {
      // Sanitize slug to be safe for storage paths
      const safeSlug = slug.replace(/[^a-zA-Z0-9-_]/g, "-").toLowerCase();
      finalFilename = `${safeSlug}.${ext}`;
    } else {
      // Fallback: unique suffix (used when adding a new cake before slug is known)
      const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
      const filename = file.name.replace(/[^a-zA-Z0-9.-]/g, "_");
      finalFilename = `${uniqueSuffix}-${filename}`;
    }

    // Upload to Supabase Storage (upsert=true replaces existing file at same path)
    const { error } = await supabase.storage
      .from("cakes")
      .upload(finalFilename, buffer, {
        contentType: file.type,
        upsert: true,
      });

    if (error) {
      console.error("Supabase storage error:", error);
      return NextResponse.json({ error: "Failed to upload to storage" }, { status: 500 });
    }

    // Get Public URL (same URL every time for slug-based uploads)
    const { data: { publicUrl } } = supabase.storage
      .from("cakes")
      .getPublicUrl(finalFilename);

    console.log(`[Upload] Stored as "${finalFilename}" (${slug ? "stable slug" : "unique"}): ${publicUrl}`);

    return NextResponse.json({ 
      success: true, 
      imageUrl: publicUrl,
    });
  } catch (error) {
    console.error("Upload error:", error);
    return NextResponse.json({ error: "Failed to upload file" }, { status: 500 });
  }
}
