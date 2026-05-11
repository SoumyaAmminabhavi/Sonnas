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

    
    // Create a unique filename 
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const filename = file.name.replace(/[^a-zA-Z0-9.-]/g, "_"); // sanitize
    const finalFilename = `${uniqueSuffix}-${filename}`;
    
    // Upload to Supabase Storage
    const { error } = await supabase.storage
      .from("cakes")
      .upload(finalFilename, buffer, {
        contentType: file.type,
        upsert: true
      });

    if (error) {
      console.error("Supabase storage error:", error);
      return NextResponse.json({ error: "Failed to upload to storage" }, { status: 500 });
    }

    // Get Public URL
    const { data: { publicUrl } } = supabase.storage
      .from("cakes")
      .getPublicUrl(finalFilename);

    return NextResponse.json({ 
      success: true, 
      imageUrl: publicUrl 
    });
  } catch (error) {
    console.error("Upload error:", error);
    return NextResponse.json({ error: "Failed to upload file" }, { status: 500 });
  }
}
