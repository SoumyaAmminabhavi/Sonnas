import type { IncomingMessage } from "./types";
import { 
  beginMessageProcessing, 
  markMessageProcessed,
  processingLocks,
  inFlightMessages
} from "./cache";
import { db } from "./prisma";
import { getConversation, refreshActivity, getWhatsAppSetting } from "./session";
import { checkRateLimit } from "./rate-limit";
import { _internalHandleMessage } from "./state-machine";
import { sendTextMessage, sendTypingIndicator } from "~/server/whatsapp";

async function isBotPaused(): Promise<boolean> {
  try {
    const setting = await db.whatsAppSetting.findUnique({
      where: { key: "MAINTENANCE_MODE" }
    });
    return setting?.value === "true";
  } catch {
    return false;
  }
}

export async function handleIncomingMessage(msg: IncomingMessage) {
  const phone = msg.from;

  // 1. Deduplication
  if (!beginMessageProcessing(msg.messageId)) {
    console.log(`[WhatsApp] ⚡ Duplicate or In-Flight message ${msg.messageId} skipped.`);
    return;
  }

  // 2. Concurrency Locking
  const existingLock = processingLocks.get(phone) ?? Promise.resolve();
  const processPromise = existingLock.then(async () => {
    try {
      // 3. Maintenance Mode Check
      const normalizedText = msg.text?.trim().toLowerCase();
      const isStatusRequest = [
        "status", "my order", "order status"
      ].includes(normalizedText ?? "") || msg.interactiveId === "btn_status";

      if (await isBotPaused() && !isStatusRequest) {
        const maintenanceMessage = await getWhatsAppSetting("MAINTENANCE_MESSAGE", "🌸 *Sonnas is currently resting.*\n\nOur artisan kitchen is taking a short break to prepare for upcoming collections. We'll be back shortly to delight you! ✨\n\n_If you have an existing order, don't worry — our team is still working on it!_");
        await sendTextMessage(
          msg.from,
          maintenanceMessage
        );
        return;
      }

      const convo = await getConversation(phone);

      // 4. Rate Limiting
      if (!(await checkRateLimit(phone, convo))) {
        return;
      }

      await refreshActivity(phone);

      // Trigger typing indicator (best effort, async)
      void sendTypingIndicator(phone).catch(() => null);

      // 5. Core Handling
      await _internalHandleMessage(msg);

      // 6. Mark Processed
      markMessageProcessed(msg.messageId);
    } catch (err) {
      console.error(`[WhatsApp] Processing error for ${phone}:`, err);
    } finally {
      inFlightMessages.delete(msg.messageId);
    }
  });

  processingLocks.set(phone, processPromise);

  // Clean up lock after chain completes
  void processPromise.then(() => {
    if (processingLocks.get(phone) === processPromise) {
      processingLocks.delete(phone);
    }
  });

  return processPromise;
}
