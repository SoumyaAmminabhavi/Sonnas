/**
 * WhatsApp Cloud API Service Layer
 * Handles all outbound message types via Meta Graph API v18.0
 */
import { env } from "~/env";

const GRAPH_API = "https://graph.facebook.com/v18.0";

function getHeaders() {
  return {
    Authorization: `Bearer ${env.WHATSAPP_TOKEN}`,
    "Content-Type": "application/json",
  };
}

function getMessagesUrl() {
  return `${GRAPH_API}/${env.WHATSAPP_PHONE_ID}/messages`;
}

/**
 * Helper to perform fetch with a timeout
 */
async function fetchWithTimeout(url: string, options: RequestInit, timeoutMs = 10000) {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);
  
  try {
    return await fetch(url, {
      ...options,
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeoutId);
  }
}


// ─── Send plain text ────────────────────────────────────────────────────────

export async function sendTextMessage(to: string, message: string) {
  if (!env.WHATSAPP_TOKEN || !env.WHATSAPP_PHONE_ID) {
    console.warn("[WhatsApp] Env variables not configured! TOKEN:", !!env.WHATSAPP_TOKEN, "ID:", !!env.WHATSAPP_PHONE_ID);
    return;
  }

  try {
    const res = await fetchWithTimeout(getMessagesUrl(), {
      method: "POST",
      headers: getHeaders(),
      body: JSON.stringify({
        messaging_product: "whatsapp",
        to,
        type: "text",
        text: { body: message },
      }),
    });


    if (!res.ok) {
      const err = await res.text();
      const errorMsg = `[WhatsApp] Failed to send text: ${res.status} - ${err}`;
      console.error(errorMsg);
      throw new Error(errorMsg);
    }
  } catch (e) {
    console.error("[WhatsApp] sendTextMessage error:", e);
    throw e;
  }
}


// ─── Send image ─────────────────────────────────────────────────────────────

export async function sendImageMessage(to: string, imageUrl: string, caption?: string) {
  if (!env.WHATSAPP_TOKEN || !env.WHATSAPP_PHONE_ID) return;

  try {
    const res = await fetchWithTimeout(getMessagesUrl(), {
      method: "POST",
      headers: getHeaders(),
      body: JSON.stringify({
        messaging_product: "whatsapp",
        to,
        type: "image",
        image: {
          link: imageUrl,
          caption: caption,
        },
      }),
    });


    if (!res.ok) {
      const err = await res.text();
      const errorMsg = `[WhatsApp] Failed to send image: ${res.status} - ${err}`;
      console.error(errorMsg);
      throw new Error(errorMsg);
    }
  } catch (e) {
    console.error("[WhatsApp] sendImageMessage error:", e);
    throw e;
  }
}


// ─── Send interactive list (for menu browsing) ─────────────────────────────

interface ListSection {
  title: string;
  rows: Array<{
    id: string;
    title: string;
    description?: string;
  }>;
}

export async function sendInteractiveList(
  to: string,
  headerText: string,
  bodyText: string,
  buttonText: string,
  sections: ListSection[]
) {
  if (!env.WHATSAPP_TOKEN || !env.WHATSAPP_PHONE_ID) return;

  try {
    const res = await fetchWithTimeout(getMessagesUrl(), {
      method: "POST",
      headers: getHeaders(),
      body: JSON.stringify({
        messaging_product: "whatsapp",
        to,
        type: "interactive",
        interactive: {
          type: "list",
          header: { type: "text", text: headerText },
          body: { text: bodyText },
          action: {
            button: buttonText,
            sections,
          },
        },
      }),
    });


    if (!res.ok) {
      const err = await res.text();
      const errorMsg = `[WhatsApp] Failed to send list: ${res.status} - ${err}`;
      console.error(errorMsg);
      throw new Error(errorMsg);
    }
  } catch (e) {
    console.error("[WhatsApp] sendInteractiveList error:", e);
    throw e;
  }
}


// ─── Send interactive buttons (for confirmations) ──────────────────────────

interface ReplyButton {
  id: string;
  title: string;
}

export async function sendInteractiveButtons(
  to: string,
  bodyText: string,
  buttons: ReplyButton[]
) {
  if (!env.WHATSAPP_TOKEN || !env.WHATSAPP_PHONE_ID) return;

  try {
    const res = await fetchWithTimeout(getMessagesUrl(), {
      method: "POST",
      headers: getHeaders(),
      body: JSON.stringify({
        messaging_product: "whatsapp",
        to,
        type: "interactive",
        interactive: {
          type: "button",
          body: { text: bodyText },
          action: {
            buttons: buttons.map((b) => ({
              type: "reply",
              reply: { id: b.id, title: b.title },
            })),
          },
        },
      }),
    });


    if (!res.ok) {
      const err = await res.text();
      const errorMsg = `[WhatsApp] Failed to send buttons: ${res.status} - ${err}`;
      console.error(errorMsg);
      throw new Error(errorMsg);
    }
  } catch (e) {
    console.error("[WhatsApp] sendInteractiveButtons error:", e);
    throw e;
  }
}


// ─── Send interactive CTA URL button (for external links) ────────────────

export async function sendCTAUrlButton(
  to: string,
  bodyText: string,
  displayText: string,
  url: string
) {
  if (!env.WHATSAPP_TOKEN || !env.WHATSAPP_PHONE_ID) return;

  try {
    const res = await fetchWithTimeout(getMessagesUrl(), {
      method: "POST",
      headers: getHeaders(),
      body: JSON.stringify({
        messaging_product: "whatsapp",
        to,
        type: "interactive",
        interactive: {
          type: "cta_url",
          body: { text: bodyText },
          action: {
            name: "cta_url",
            parameters: {
              display_text: displayText,
              url,
            },
          },
        },
      }),
    });

    if (!res.ok) {
      const err = await res.text();
      const errorMsg = `[WhatsApp] Failed to send CTA URL button: ${res.status} - ${err}`;
      console.error(errorMsg);
      throw new Error(errorMsg);
    }
  } catch (e) {
    console.error("[WhatsApp] sendCTAUrlButton error:", e);
    throw e;
  }
}


// ─── Mark as read ──────────────────────────────────────────────────────────


export async function markAsRead(messageId: string) {
  if (!env.WHATSAPP_TOKEN || !env.WHATSAPP_PHONE_ID) return;

  try {
    await fetchWithTimeout(getMessagesUrl(), {
      method: "POST",
      headers: getHeaders(),
      body: JSON.stringify({
        messaging_product: "whatsapp",
        status: "read",
        message_id: messageId,
      }),
    });

  } catch (e) {
    console.error("[WhatsApp] markAsRead error:", e);
  }
}
