import { type NextRequest, NextResponse } from "next/server";
import { supabase } from "~/lib/supabase";

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const file = formData.get("file") as File | null;
    
    if (!file) {
      return NextResponse.json({ error: "No file uploaded" }, { status: 400 });
    }

    const buffer = await file.arrayBuffer();
    
    // Create a unique filename 
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const filename = file.name.replace(/[^a-zA-Z0-9.-]/g, "_"); // sanitize
    const finalFilename = `${uniqueSuffix}-${filename}`;
    
    // Upload to Supabase Storage
    const { error } = await supabase.storage
      .from("CAKES")
      .upload(finalFilename, buffer, {
        contentType: file.type,
        upsert: true
      });

    if (error) {
      console.error("Supabase storage error:", error);
      return NextResponse.json({ 
        error: "Supabase storage error", 
        message: error.message,
        details: error
      }, { status: 500 });
    }

    // Get Public URL
    const { data: { publicUrl } } = supabase.storage
      .from("CAKES")
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
