import { db } from "./prisma";
import type { 
  WhatsAppTemplate, 
  WhatsAppTemplateVersion, 
  WhatsAppButton, 
  WhatsAppListSection, 
  WhatsAppListRow 
} from "../../../../generated/prisma";

// Type definition for a template enriched with its active version and layout components
export interface EnrichedWhatsAppTemplate extends WhatsAppTemplate {
  activeVersion: (WhatsAppTemplateVersion & {
    buttons: WhatsAppButton[];
    listSections: (WhatsAppListSection & {
      rows: WhatsAppListRow[];
    })[];
  }) | null;
}

interface CacheEntry {
  value: EnrichedWhatsAppTemplate | null;
  expiresAt: number;
}

// In-Memory Cache (Simple, high-performance replacement for Redis as requested)
const localCache = new Map<string, CacheEntry>();
const CACHE_TTL = 60 * 1000; // 1 minute TTL

/**
 * Retrieves a WhatsApp message template from cache or PostgreSQL database.
 * Supports multi-language fallback logic.
 */
export async function getWhatsAppTemplate(
  code: string,
  language = "en"
): Promise<EnrichedWhatsAppTemplate | null> {
  const cacheKey = `${language}:${code}`;
  const now = Date.now();

  // 1. Check local cache
  const cached = localCache.get(cacheKey);
  if (cached && cached.expiresAt > now) {
    return cached.value;
  }

  try {
    // 2. Fetch from Database including version and rich components (ordered by sortOrder)
    const template = await db.whatsAppTemplate.findFirst({
      where: { code, language, isActive: true },
      include: {
        activeVersion: {
          include: {
            buttons: {
              orderBy: { sortOrder: "asc" },
            },
            listSections: {
              orderBy: { sortOrder: "asc" },
              include: {
                rows: {
                  orderBy: { sortOrder: "asc" },
                },
              },
            },
          },
        },
      },
    });

    const enriched = template as unknown as EnrichedWhatsAppTemplate;

    // 3. Cache the result (even null/missing values to avoid DB hammer on bad queries)
    localCache.set(cacheKey, {
      value: enriched ?? null,
      expiresAt: now + CACHE_TTL,
    });

    return enriched ?? null;
  } catch (error) {
    console.error(`[WhatsApp] Failed to load dynamic template "${code}":`, error);
    // If the database fails, return null immediately so caller can fall back cleanly
    return null;
  }
}

/**
 * Manually invalidates a cache entry (typically called when saving templates in the admin panel)
 */
export function invalidateTemplateCache(code: string, language = "en"): void {
  const cacheKey = `${language}:${code}`;
  localCache.delete(cacheKey);
  console.log(`[WhatsApp] Cache invalidated for template: ${cacheKey}`);
}

/**
 * Clear the entire template cache (administrative command)
 */
export function clearAllTemplateCache(): void {
  localCache.clear();
  console.log("[WhatsApp] Dynamic template local cache cleared.");
}
