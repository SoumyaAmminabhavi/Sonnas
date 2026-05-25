import { db, convoCache } from "./conversation-handler";

/**
 * Cleanup stale conversations that haven't had activity for a while.
 * - Reset state to IDLE after 1 hour of inactivity.
 * - Delete conversations after 7 days of total inactivity.
 */
export async function cleanupStaleConversations() {
  const oneHourAgo = new Date(Date.now() - 1 * 60 * 60 * 1000);
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

  console.log("[Cleanup] Starting session maintenance...");

  try {
    // 1. Delete very old conversations (7+ days inactive)
    const deleted = await db.whatsAppConversation.deleteMany({
      where: {
        lastActivityAt: { lt: sevenDaysAgo },
      },
    });
    if (deleted.count > 0) {
      console.log(`[Cleanup] Deleted ${deleted.count} conversations older than 7 days.`);
    }

    // 2. Reset stalled conversations (1h+ inactive)
    const stalled = await db.whatsAppConversation.updateMany({
      where: {
        lastActivityAt: { lt: oneHourAgo },
        NOT: { state: "IDLE" },
      },
      data: {
        state: "IDLE",
        selectedCakeId: null,
        selectedSize: null,
        selectedPrice: null,
        selectedQuantity: 1,
        selectedAddress: null,
        selectedNotes: null,
        selectedDeliveryDate: null,
        selectedDeliverySlot: null,
        customImageUrl: null,
      },
    });
    if (stalled.count > 0) {
      console.log(`[Cleanup] Reset ${stalled.count} stalled conversations to IDLE.`);
    }

    // 3. Clear memory cache for these phones
    // (Note: This only affects the current server instance)
    convoCache.clear(); 
    
    console.log("[Cleanup] Maintenance complete.");
    return { deleted: deleted.count, reset: stalled.count };
  } catch (error) {
    console.error("[Cleanup] Error during session maintenance:", error);
    throw error;
  }
}
