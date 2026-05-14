import { WhatsAppConversation, Cake, DBCategory } from "./types";
import { MAX_PROCESSED_IDS } from "./constants";

// Conversation state cache
export const convoCache = new Map<string, WhatsAppConversation>();

// Processing locks for concurrency safety
export const processingLocks = new Map<string, Promise<void>>();

// Message Deduplication
export const processedMessages = new Set<string>();
export const inFlightMessages = new Set<string>();

// Menu Caches
export let cakeCache: Cake[] | null = null;
export let categoryCache: DBCategory[] | null = null;
export let lastCacheUpdate = 0;

export function clearMenuCache() {
  cakeCache = null;
  categoryCache = null;
  lastCacheUpdate = 0;
  console.log("[WhatsApp] Menu & Category cache cleared.");
}

export function updateConvoCache(phone: string, data: Partial<WhatsAppConversation>) {
  const current = convoCache.get(phone) || { phone, state: "IDLE" } as unknown as WhatsAppConversation;
  convoCache.set(phone, { ...current, ...data } as WhatsAppConversation);
}

export function beginMessageProcessing(messageId: string): boolean {
  if (processedMessages.has(messageId) || inFlightMessages.has(messageId)) return false;
  inFlightMessages.add(messageId);
  return true;
}

export function markMessageProcessed(messageId: string) {
  processedMessages.add(messageId);
  // Evict oldest entries when set grows too large
  if (processedMessages.size > MAX_PROCESSED_IDS) {
    const first = processedMessages.values().next().value;
    if (first) processedMessages.delete(first);
  }
}

export function setCaches(cakes: Cake[] | null, categories: DBCategory[] | null, timestamp: number) {
  cakeCache = cakes;
  categoryCache = categories;
  lastCacheUpdate = timestamp;
}
