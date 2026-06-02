import type { WhatsAppConversation } from "./types";
import { 
  RATE_LIMIT_WINDOW_MS, 
  RATE_LIMIT_MAX_MSGS, 
  RATE_LIMIT_COOLDOWN_MS 
} from "./constants";
import { updateConvoCache } from "./cache";
import { sendTextMessage } from "~/server/whatsapp";

export async function checkRateLimit(phone: string, convo: WhatsAppConversation): Promise<boolean> {
  const NOW = Date.now();

  // 1. Sliding Cooldown
  if (convo.lastActivityAt) {
    const lastActivity = new Date(convo.lastActivityAt).getTime();
    if (NOW - lastActivity < RATE_LIMIT_COOLDOWN_MS) {
      console.warn(`[WhatsApp] 🛡️ Cooldown: ${phone} ignored (too fast).`);
      return false;
    }
  }

  // 2. Rolling Window
  let currentCount = convo.rateLimitCount ?? 0;
  let windowStart = convo.rateLimitWindowStart ?? NOW;

  if (NOW - windowStart > RATE_LIMIT_WINDOW_MS) {
    windowStart = NOW;
    currentCount = 1;
  } else {
    currentCount += 1;
    if (currentCount > RATE_LIMIT_MAX_MSGS) {
      console.warn(`[WhatsApp] 🛡️ Rate limit: ${phone} (${currentCount} msgs/min).`);
      if (currentCount === RATE_LIMIT_MAX_MSGS + 1) {
        await sendTextMessage(phone, "⚠️ *Slow down!* You've reached the message limit. Please wait a minute.");
      }
      updateConvoCache(phone, {
        rateLimitCount: currentCount,
        rateLimitWindowStart: windowStart
      });
      return false;
    }
  }

  updateConvoCache(phone, {
    rateLimitCount: currentCount,
    rateLimitWindowStart: windowStart
  });

  return true;
}
