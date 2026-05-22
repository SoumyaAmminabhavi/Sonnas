import type { ConversationState } from "../../../../generated/prisma";

export interface CakeOption {
  id?: string;
  size: string;
  serves: string;
  price: number;
}

export interface Cake {
  id: string | number;
  name: string;
  slug?: string;
  description?: string | null;
  image: string;
  category?: string;
  categoryId?: string | null;
  categoryName?: string | null;
  isAvailable?: boolean;
  sortOrder?: number;
  options: CakeOption[];
}

export interface DBCategory {
  id: string;
  name: string;
  slug: string | null;
  image: string | null;
  sortOrder: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface DBCake {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  image: string;
  categoryId: string | null;
  categoryName: string | null;
  isAvailable: boolean;
  sortOrder: number;
  createdAt: Date;
  updatedAt: Date;
  options: CakeOption[];
  category: DBCategory | null;
}

export interface CartItem {
  id: string;
  cakeName: string;
  size: string;
  price: number;
  quantity: number;
  createdAt: Date | string;
}

export interface WhatsAppConversation {
  id?: string;
  phone: string;
  name?: string | null;
  state: ConversationState;
  selectedCakeId?: string | null;
  selectedCake?: string | null; // Used in re-prompt
  selectedSize?: string | null;
  selectedPrice?: number | null;
  selectedAddress?: string | null;
  selectedNotes?: string | null;
  selectedQuantity?: number | null;
  selectedDeliveryDate?: Date | string | null;
  selectedDeliverySlot?: string | null;
  customImageUrl?: string | null;
  cart?: CartItem[];
  lastActivityAt?: Date | string | null;
  lastMessageAt?: Date | string | null;
  rateLimitCount?: number;
  rateLimitWindowStart?: number;
  menuOffset?: number;
}

export interface IncomingMessage {
  from: string;
  name?: string;
  type: "text" | "interactive" | "location" | "image";
  text?: string;
  interactiveId?: string;
  interactiveTitle?: string;
  messageId: string;
  location?: {
    latitude: number;
    longitude: number;
    name?: string;
    address?: string;
  };
  image?: {
    id: string;
    caption?: string;
    mimeType: string;
  };
}
