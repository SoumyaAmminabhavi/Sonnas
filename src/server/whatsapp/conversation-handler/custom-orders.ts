import { IncomingMessage, WhatsAppConversation } from "./types";
import { updateState } from "./session";
import { sendTextMessage, sendInteractiveButtons } from "~/server/whatsapp";
import { validateAndSanitize } from "./validation";
import { createCustomOrder } from "./orders";
import { ConversationState } from "../../../generated/prisma";

export async function handleCustomRequest(
  msg: IncomingMessage,
  convo: WhatsAppConversation
) {
  if (msg.type === "image" && msg.image) {
    const { downloadAndUploadImage } = await import("../media");
    const publicUrl = await downloadAndUploadImage(msg.image.id);

    const orderNumber = await createCustomOrder(msg, convo, publicUrl ?? undefined, msg.image.id, msg.image.caption ?? "");

    await sendInteractiveButtons(
      msg.from,
      `📸 *Reference Photo Received!* 🍰\n\nYour request has been logged as *#${orderNumber}*.\n\nOur team will review your design and call you shortly to provide a quote and confirm details. 📞\n\nWould you like to explore our signature cakes while you wait?`,
      [
        { id: "btn_menu", title: "📋 View Menu" },
        { id: "btn_status", title: "📦 My Orders" },
      ]
    );
    return;
  }

  if (msg.type === "text" && msg.text) {
    const text = msg.text.trim();
    const validation = validateAndSanitize("notes", text);
    if (!validation.success) {
      await sendTextMessage(msg.from, `⚠️ ${validation.error}`);
      return;
    }
    const sanitizedText = (validation.data as string) ?? "";
    const looksLikeAddress = /\d+/.test(sanitizedText) && sanitizedText.split(/\s+/).length > 3;

    if (looksLikeAddress || convo.selectedNotes) {
      await Promise.all([
        updateState(msg.from, ConversationState.INPUTTING_ADDRESS, { selectedAddress: sanitizedText }),
        sendTextMessage(msg.from, "📍 *Address received!* \n\nPlease share a **Reference Photo** 📸 to help us understand your design better.")
      ]);
    } else {
      await Promise.all([
        updateState(msg.from, ConversationState.CUSTOM_ORDER_DETAILS, { selectedNotes: sanitizedText }),
        sendTextMessage(msg.from, "✅ Description received! 📝\n\nSend a **Reference Photo** 📸 or reply with your **Delivery Address** to proceed.")
      ]);
    }
    return;
  }
}

export async function handleReferenceImageUpload(
  msg: IncomingMessage,
  convo: WhatsAppConversation
) {
  if (msg.type === "image" && msg.image) {
    const { downloadAndUploadImage } = await import("../media");
    const publicUrl = await downloadAndUploadImage(msg.image.id);

    const orderNumber = await createCustomOrder(msg, convo, publicUrl ?? undefined, msg.image.id, msg.image.caption ?? "");

    await sendInteractiveButtons(
      msg.from,
      `📸 *Reference Photo Received!* 🍰\n\nYour request has been logged as *#${orderNumber}*.\n\nOur team will review your design and call you shortly to provide a quote and confirm details. 📞\n\nWould you like to explore our signature cakes while you wait?`,
      [
        { id: "btn_menu", title: "📋 View Menu" },
        { id: "btn_status", title: "📦 My Orders" },
      ]
    );
  } else {
    await sendTextMessage(msg.from, "Please upload a **Reference Photo** 📸 to proceed.\n\n(We need an image to understand your design! ✨)");
  }
}
