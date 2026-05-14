import { ConversationState } from "../../../../generated/prisma";

export const GREETINGS = ["hi", "hello", "hey", "hii", "hiii", "hey there", "good morning", "good evening"];

export const CACHE_TTL = 30 * 60 * 1000; // 30 minutes
export const DB_TIMEOUT = 15000; // 15 seconds
export const MAX_PROCESSED_IDS = 2000;

// Anti-Flood Constants
export const RATE_LIMIT_WINDOW_MS = 60000; // 1 minute
export const RATE_LIMIT_MAX_MSGS = 15;
export const RATE_LIMIT_COOLDOWN_MS = 1500;

export const RESET_STATE = {
  selectedCakeId: null,
  selectedSize: null,
  selectedPrice: null,
  selectedAddress: null,
  selectedNotes: null,
  selectedDeliveryDate: null,
  selectedDeliverySlot: null,
  customImageUrl: null,
  state: ConversationState.IDLE,
};
