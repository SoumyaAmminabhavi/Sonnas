/**
 * WhatsApp Webhook — Meta Cloud API
 * GET  → Webhook verification handshake
 * POST → Incoming messages (text + interactive responses)
 */
import { NextResponse } from "next/server";
import { env } from "~/env";
import { markAsRead, sendTextMessage } from "~/server/whatsapp";
import { handleIncomingMessage } from "~/server/whatsapp/conversation-handler";

import crypto from "crypto";

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
    const signature = request.headers.get("X-Hub-Signature-256");
    const rawBody = await request.text();

    // 1. Verify Signature if Secret is Configured
    if (env.WHATSAPP_APP_SECRET) {
      if (!signature) {
        console.warn("[WhatsApp] Missing X-Hub-Signature-256 header");
        return new NextResponse("Unauthorized", { status: 401 });
      }

      const expectedSignature = "sha256=" + crypto
        .createHmac("sha256", env.WHATSAPP_APP_SECRET)
        .update(rawBody)
        .digest("hex");

      try {
        const signatureBuffer = Buffer.from(signature);
        const expectedBuffer = Buffer.from(expectedSignature);
        
        if (signatureBuffer.length !== expectedBuffer.length || !crypto.timingSafeEqual(signatureBuffer, expectedBuffer)) {
          console.warn("[WhatsApp] Signature mismatch ❌");
          return new NextResponse("Unauthorized", { status: 401 });
        }
      } catch {
        return new NextResponse("Unauthorized", { status: 401 });
      }

    }

    const body = JSON.parse(rawBody) as WebhookPayload;


    if (body.object !== "whatsapp_business_account") {
      return new NextResponse("OK", { status: 200 });
    }

    for (const entry of body.entry ?? []) {
      for (const change of entry.changes ?? []) {
        const value = change.value;
        for (const message of value?.messages ?? []) {
          const maskedFrom = message.from.slice(-4).padStart(message.from.length, "*");
          console.log(`[WhatsApp] Webhook Received: type=${message.type}, from=${maskedFrom}`);

          // Get contact name
          const contactName = value?.contacts?.[0]?.profile?.name;

          // Mark as read immediately for good UX
          if (message.id) {
            void markAsRead(message.id).catch(() => null);
          }

          // Build the message object
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
            const replyId = interactive?.button_reply?.id ?? interactive?.list_reply?.id;
            const replyTitle = interactive?.button_reply?.title ?? interactive?.list_reply?.title;

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

          if (incomingMsg) {
            await handleIncomingMessage(incomingMsg);
          } else if (message.from) {
            await sendTextMessage(
              message.from,
              "I can read text messages, photos, and locations 📝\n\nPlease type your message or tap a button to continue! 🧁"
            ).catch(() => null);
          }
        }
      }
    }

    return new NextResponse("OK", { status: 200 });
  } catch (err) {
    console.error("[WhatsApp] Webhook error:", err);
    return new NextResponse("OK", { status: 200 }); // Always 200 to prevent retries
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
