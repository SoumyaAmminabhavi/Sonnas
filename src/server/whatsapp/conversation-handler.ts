/**
 * WhatsApp Conversation Handler (Modular Re-export)
 * Handles the full ordering flow: IDLE → BROWSING → SELECTING_SIZE → CONFIRMING → COMPLETE
 */

export { handleIncomingMessage } from "./conversation-handler/index";
export { clearMenuCache } from "./conversation-handler/cache";
export { convoCache } from "./conversation-handler/cache";
export { db } from "./conversation-handler/prisma";

// Re-export types for backward compatibility if needed
export type { IncomingMessage, WhatsAppConversation } from "./conversation-handler/types";
