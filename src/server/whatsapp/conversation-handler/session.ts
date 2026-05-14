import { db } from "./prisma";
import { withTimeout } from "./helpers";
import { DB_TIMEOUT } from "./constants";
import { convoCache, updateConvoCache } from "./cache";
import type { WhatsAppConversation } from "./types";
import { ConversationState } from "../../../../generated/prisma";

export async function getConversation(phone: string, name?: string, force = false): Promise<WhatsAppConversation> {
  const cached = convoCache.get(phone);
  if (cached && !force) {
    if (name && !cached.name) {
      cached.name = name;
      convoCache.set(phone, cached);
      void db.whatsAppConversation.update({ where: { phone }, data: { name } }).catch(() => null);
    }
    return cached;
  }

  try {
    let convo = await withTimeout(
      db.whatsAppConversation.findUnique({
        where: { phone },
        include: { cart: true }
      }),
      DB_TIMEOUT
    );

    if (!convo) {
      convo = await withTimeout(
        db.whatsAppConversation.create({
          data: { phone, name },
          include: { cart: true }
        }),
        DB_TIMEOUT
      );
    } else if (name && !convo.name) {
      convo = await withTimeout(
        db.whatsAppConversation.update({
          where: { phone },
          data: { name },
          include: { cart: true }
        }),
        DB_TIMEOUT
      );
    }

    const result = convo as unknown as WhatsAppConversation;

    // Stale cart cleanup logic (older than 24 hours)
    if (result.cart && result.cart.length > 0) {
      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
      const hasStaleItems = result.cart.some((item) => {
        if (!item.createdAt) return false;
        return new Date(item.createdAt) < oneDayAgo;
      });

      if (hasStaleItems) {
        void db.whatsAppCartItem.deleteMany({
          where: {
            phone,
            createdAt: { lt: oneDayAgo }
          }
        }).catch(() => null);

        result.cart = result.cart.filter((item) => {
          if (!item.createdAt) return true;
          return new Date(item.createdAt) >= oneDayAgo;
        });
      }
    }

    convoCache.set(phone, result);
    return result;
  } catch {
    const fallback = { phone, state: ConversationState.IDLE, name: name ?? "Customer", cart: [] } as unknown as WhatsAppConversation;
    convoCache.set(phone, fallback);
    return fallback;
  }
}

export async function updateState(
  phone: string,
  state: ConversationState,
  extra: Partial<WhatsAppConversation> = {}
) {
  updateConvoCache(phone, { state, ...extra });

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const { cart, lastActivityAt: _, lastMessageAt: __, rateLimitCount, rateLimitWindowStart, selectedCake, ...otherExtra } = extra;

  // Filter out any undefined/null fields that might cause issues with strict types
  const data: any = { 
    state, 
    lastMessageAt: new Date(), 
    lastActivityAt: new Date(),
    ...otherExtra 
  };

  return withTimeout(
    db.whatsAppConversation.update({
      where: { phone },
      data,
    }),
    DB_TIMEOUT
  ).catch((e) => {
    console.error(`[WhatsApp] updateState DB write failed for ${phone}:`, e);
  });
}

export async function refreshActivity(phone: string) {
  void db.whatsAppConversation.update({
    where: { phone },
    data: { lastActivityAt: new Date() }
  }).catch(() => null);

  const cached = convoCache.get(phone);
  if (cached) {
    cached.lastActivityAt = new Date();
    convoCache.set(phone, cached);
  }
}

export async function getSessionTimeoutMins(): Promise<number> {
  try {
    const setting = await db.whatsAppSetting.findUnique({
      where: { key: "SESSION_TIMEOUT_MINS" }
    });
    return setting ? parseInt(setting.value) : 60;
  } catch {
    return 60;
  }
}
