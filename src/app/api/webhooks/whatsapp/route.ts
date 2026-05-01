/**
 * WhatsApp Webhook — Meta Cloud API
 * GET  → Webhook verification handshake
 * POST → Incoming messages (text + interactive responses)
 */
import { NextResponse } from "next/server";
import { env } from "~/env";
import { markAsRead } from "~/server/whatsapp";
import { handleIncomingMessage } from "~/server/whatsapp/conversation-handler";

// ─── Webhook verification (GET) ────────────────────────────────────────────

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const mode = searchParams.get("hub.mode");
  const token = searchParams.get("hub.verify_token");
  const challenge = searchParams.get("hub.challenge");

  if (mode === "subscribe" && token === env.WHATSAPP_VERIFY_TOKEN) {
    console.log("[WhatsApp] Webhook verified ✅");
    return new NextResponse(challenge, { status: 200 });
  }

  return new NextResponse("Forbidden", { status: 403 });
}

// ─── Incoming messages (POST) ──────────────────────────────────────────────

export async function POST(request: Request) {
  try {
    const body = await request.json() as WebhookPayload;

    if (body.object !== "whatsapp_business_account") {
      return new NextResponse("OK", { status: 200 });
    }

    const entry = body.entry?.[0];
    const changes = entry?.changes?.[0];
    const value = changes?.value;
    const message = value?.messages?.[0];

    if (!message) {
      // Status update or other non-message event
      return new NextResponse("OK", { status: 200 });
    }

    console.log(`[WhatsApp] Webhook Received: type=${message.type}, from=${message.from}`);

    // Get contact name
    const contactName = value?.contacts?.[0]?.profile?.name;

    // Mark as read immediately for good UX
    if (message.id) {
      void markAsRead(message.id);
    }

    // Build the message object synchronously, then process in background
    let incomingMsg: Parameters<typeof handleIncomingMessage>[0] | null = null;

    if (message.type === "text") {
      incomingMsg = {
        from: message.from,
        name: contactName,
        type: "text",
        text: message.text?.body,
        messageId: message.id,
      };
    } else if (message.type === "interactive") {
      const interactive = message.interactive;
      const replyId =
        interactive?.button_reply?.id ?? interactive?.list_reply?.id;
      const replyTitle =
        interactive?.button_reply?.title ?? interactive?.list_reply?.title;

      incomingMsg = {
        from: message.from,
        name: contactName,
        type: "interactive",
        interactiveId: replyId,
        interactiveTitle: replyTitle,
        messageId: message.id,
      };
    } else if (message.type === "location" && message.location) {
      incomingMsg = {
        from: message.from,
        name: contactName,
        type: "location",
        location: {
          latitude: message.location.latitude,
          longitude: message.location.longitude,
          name: message.location.name,
          address: message.location.address,
        },
        messageId: message.id,
      };
    } else if (message.type === "image" && message.image) {
      incomingMsg = {
        from: message.from,
        name: contactName,
        type: "image",
        image: {
          id: message.image.id,
          caption: message.image.caption,
          mimeType: message.image.mime_type,
        },
        messageId: message.id,
      };
    }

    // 🚀 Process message and wait for it to finish (needed for serverless reliability)
    if (incomingMsg) {
      await handleIncomingMessage(incomingMsg).catch((err) =>
        console.error("[WhatsApp] Processing error:", err)
      );
    }

    // Return 200 immediately — Meta requires response within ~15s
    return new NextResponse("OK", { status: 200 });
  } catch (err) {
    console.error("[WhatsApp] Webhook error:", err);
    // Still return 200 to prevent Meta from retrying
    return new NextResponse("OK", { status: 200 });
  }
}

// ─── Type definitions for webhook payload ──────────────────────────────────

interface WebhookPayload {
  object: string;
  entry?: Array<{
    changes?: Array<{
      value?: {
        messages?: Array<{
          id: string;
          from: string;
          type: string;
          text?: { body: string };
            interactive?: {
              type: string;
              button_reply?: { id: string; title: string };
              list_reply?: { id: string; title: string };
            };
            location?: {
              latitude: number;
              longitude: number;
              name?: string;
              address?: string;
            };
            image?: {
              id: string;
              caption?: string;
              mime_type: string;
            };
          }>;
        contacts?: Array<{
          profile?: { name?: string };
        }>;
      };
    }>;
  }>;
}
