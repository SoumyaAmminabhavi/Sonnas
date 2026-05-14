import type { IncomingMessage, WhatsAppConversation } from "./types";
import { GREETINGS } from "./constants";
import { validateAndSanitize } from "./validation";
import { updateState } from "./session";
import { sendTextMessage, sendInteractiveButtons, sendInteractiveList } from "~/server/whatsapp";
import { ConversationState } from "../../../../generated/prisma";
import { convoCache } from "./cache";
import { buildOrderSummary } from "./cart";

export async function reverseGeocode(lat: number, lon: number): Promise<string | undefined> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 5000);

  try {
    const response = await fetch(
      `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&zoom=18&addressdetails=1`,
      {
        signal: controller.signal,
        headers: { "User-Agent": "SonnasPatisserieBot/1.0" },
      }
    );
    const data = await response.json() as { display_name: string };
    return data.display_name ?? undefined;
  } catch (e) {
    console.error("[WhatsApp] reverseGeocode failed:", e);
    return undefined;
  } finally {
    clearTimeout(timeoutId);
  }
}

export function getAvailableSlots() {
  const slots: Array<{ id: string; title: string; description: string }> = [];
  const now = new Date();
  const today = new Date(now.getTime() + (5.5 * 60 * 60 * 1000));

  const windows = [
    { id: "slot1", title: "12 PM - 3 PM", time: "12 PM - 3 PM", startHour: 12 },
    { id: "slot2", title: "3 PM - 6 PM", time: "3 PM - 6 PM", startHour: 15 },
    { id: "slot3", title: "6 PM - 9 PM", time: "6 PM - 9 PM", startHour: 18 },
  ];

  for (let i = 0; i < 4; i++) {
    const d = new Date(today);
    d.setDate(d.getDate() + i);
    const dayLabel = i === 0 ? "Today" : i === 1 ? "Tomorrow" : d.toLocaleDateString("en-IN", { weekday: "short", day: "numeric" });
    const dateKey = `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, "0")}-${d.getDate().toString().padStart(2, "0")}`;

    for (const win of windows) {
      if (i === 0 && today.getHours() + 2 >= win.startHour) continue;
      slots.push({
        id: `slot_${dateKey}_${win.id}`,
        title: `${dayLabel} (${win.title})`,
        description: "Handcrafted fresh delivery"
      });
    }
  }
  return slots.slice(0, 10);
}

export async function sendDeliverySlotOptions(to: string) {
  const slots = getAvailableSlots();
  await sendInteractiveList(
    to,
    "🕒 Delivery Timing",
    "When should we bring your treats? 🧁\n\nPlease select a convenient delivery slot:",
    "View Slots",
    [{ title: "Available Slots", rows: slots }]
  );
}

export async function handleDeliverySlotSelection(
  msg: IncomingMessage,
  convo: WhatsAppConversation
) {
  let deliveryDate: Date | null = null;
  let deliveryTime = "";

  if (msg.interactiveId?.startsWith("slot_")) {
    const parts = msg.interactiveId.split("_");
    const datePart = parts[1];
    const timePart = parts[2];

    if (!datePart || !timePart) return;

    const [year, month, day] = datePart.split("-").map(Number);
    if (year === undefined || month === undefined || day === undefined) return;

    deliveryDate = new Date(year, month - 1, day);
    const windowMap: Record<string, string> = {
      slot1: "12 PM - 3 PM",
      slot2: "3 PM - 6 PM",
      slot3: "6 PM - 9 PM",
      morning: "10 AM - 1 PM",
      afternoon: "2 PM - 5 PM",
      evening: "6 PM - 9 PM",
    };
    deliveryTime = windowMap[timePart] ?? (timePart.charAt(0).toUpperCase() + timePart.slice(1));
  } else if (msg.text?.trim()) {
    deliveryDate = new Date();
    deliveryTime = msg.text.trim();
  } else {
    await sendTextMessage(msg.from, "Please select a delivery slot from the list.");
    return;
  }

  try {
    await updateState(msg.from, ConversationState.CONFIRMING_ORDER, {
      selectedDeliveryDate: deliveryDate,
      selectedDeliverySlot: deliveryTime,
    });

    const cart = convoCache.get(msg.from)?.cart ?? [];
    const currentConvo = convoCache.get(msg.from) ?? convo;

    await sendInteractiveButtons(
      msg.from,
      buildOrderSummary(cart, currentConvo),
      [
        { id: "btn_confirm", title: "✅ Confirm Order" },
        { id: "btn_back", title: "⬅️ Back" },
        { id: "btn_cancel", title: "❌ Cancel" },
      ]
    );
  } catch (err) {
    console.error("[WhatsApp] Error in handleDeliverySlotSelection:", err);
    await sendTextMessage(msg.from, "⚠️ Sorry, I encountered an error. Please try again.");
  }
}

export async function handleAddressInput(msg: IncomingMessage, _convo: WhatsAppConversation) {
  let address = msg.text?.trim() ?? "";

  if (msg.type === "location" && msg.location) {
    const { latitude, longitude, name, address: locAddress } = msg.location;
    const mapsUrl = `https://www.google.com/maps?q=${latitude},${longitude}`;
    let finalAddress = locAddress;

    if (!finalAddress || finalAddress.length < 5) {
      await sendTextMessage(msg.from, "📍 _Processing your location..._");
      finalAddress = await reverseGeocode(latitude, longitude);
    }

    address = finalAddress ? `${finalAddress}\n🔗 ${mapsUrl}` : `📍 GPS Location\n🔗 ${mapsUrl}`;
    if (name) address = `🏛️ ${name}\n${address}`;
  }

  if (!address || address.length < 5 || GREETINGS.includes(address.toLowerCase())) {
    await sendTextMessage(msg.from, "Could you share a bit more detail? 📍\n\nA full address with building name and landmark helps our delivery team find you perfectly! 🏠");
    return;
  }

  const validation = validateAndSanitize("address", address);
  if (!validation.success) {
    await sendTextMessage(msg.from, `⚠️ ${validation.error}`);
    return;
  }
  address = validation.data as string;

  await Promise.all([
    updateState(msg.from, ConversationState.ADDING_NOTES, { selectedAddress: address }),
    sendInteractiveButtons(
      msg.from,
      "✨ *Address saved!*\n\n✍️ *Personalize Your Cake*\n\nWhat message would you like on your cake?\n_(e.g., \"Happy Birthday Priya! 🎉\")_\n\nReply *Skip* if no message needed.",
      [{ id: "btn_back", title: "⬅️ Back" }]
    )
  ]);
}

export async function handleInstructionsInput(msg: IncomingMessage, _convo: WhatsAppConversation) {
  const input = msg.text?.trim() ?? "";
  const isSkip = ["none", "skip", "no"].includes(input.toLowerCase());

  if (!isSkip && (input.length < 2 || GREETINGS.includes(input.toLowerCase()))) {
    await sendTextMessage(msg.from, "What message would you like on your cake? ✍️\n\n_(e.g., \"Happy Birthday Priya!\")_\n\nReply *Skip*or *No*if none.");
    return;
  }

  let notes = isSkip ? null : input;
  if (notes) {
    const validation = validateAndSanitize("notes", notes);
    if (!validation.success) {
      await sendTextMessage(msg.from, `⚠️ ${validation.error}`);
      return;
    }
    notes = (validation.data as string) ?? null;
  }

  await Promise.all([
    updateState(msg.from, ConversationState.ASKING_DELIVERY_DATE, { selectedNotes: notes }),
    sendDeliverySlotOptions(msg.from)
  ]);

  await sendInteractiveButtons(msg.from, "_Need to change something?_", [{ id: "btn_back", title: "⬅️ Back" }]);
}
