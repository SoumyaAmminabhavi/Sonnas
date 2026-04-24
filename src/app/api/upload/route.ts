import { type NextRequest, NextResponse } from "next/server";
import { promises as fs } from "fs";
import path from "path";

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const file = formData.get("file") as File | null;
    
    if (!file) {
      return NextResponse.json({ error: "No file uploaded" }, { status: 400 });
    }

    const buffer = Buffer.from(await file.arrayBuffer());
    
    // Create a unique filename 
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const filename = file.name.replace(/[^a-zA-Z0-9.-]/g, "_"); // sanitize
    const finalFilename = `${uniqueSuffix}-${filename}`;
    
    const publicImagesPath = path.join(process.cwd(), "public", "images");
    
    // Ensure dir exists
    await fs.mkdir(publicImagesPath, { recursive: true });
    
    const filePath = path.join(publicImagesPath, finalFilename);
    await fs.writeFile(filePath, buffer);

    return NextResponse.json({ 
      success: true, 
      imageUrl: `/images/${finalFilename}` 
    });
  } catch (error) {
    console.error("Upload error:", error);
    return NextResponse.json({ error: "Failed to upload file" }, { status: 500 });
  }
}
