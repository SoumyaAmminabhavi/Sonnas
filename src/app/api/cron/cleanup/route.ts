import { NextResponse } from "next/server";
import { cleanupStaleConversations } from "~/server/whatsapp/cleanup";

/**
 * Vercel Cron Job endpoint for daily session maintenance.
 * Secured via CRON_SECRET header.
 */
export async function GET(request: Request) {
  // Security check for Vercel CRON
  const authHeader = request.headers.get('authorization');
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return new Response('Unauthorized', { status: 401 });
  }

  try {
    const result = await cleanupStaleConversations();
    return NextResponse.json({ 
      success: true, 
      message: "Cleanup complete", 
      result 
    });
  } catch (error) {
    console.error("[Cron] Session cleanup failed:", error);
    return NextResponse.json({ 
      success: false, 
      error: error instanceof Error ? error.message : "Unknown error" 
    }, { status: 500 });
  }
}
