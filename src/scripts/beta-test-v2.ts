/* eslint-disable */
import "dotenv/config";
import { handleIncomingMessage } from "../server/whatsapp/conversation-handler";
import { db } from "../server/db";
import { clearMenuCache } from "../server/whatsapp/conversation-handler";

// ─── Mock Environment ───────────────────────────────────────────────────────

const sentMessages: any[] = [];

global.fetch = (async (url: string, options: any) => {
  if (url.includes("graph.facebook.com")) {
    const body = JSON.parse(options.body);
    sentMessages.push({ type: "whatsapp", url, body });
    return { ok: true, text: async () => "OK", json: async () => ({}) };
  }
  if (url.includes("nominatim.openstreetmap.org")) {
    return {
      ok: true,
      json: async () => ({ display_name: "Mocked Street, City, India" }),
    };
  }
  return { ok: true, json: async () => ({}) };
}) as any;

// ─── Test Helper ────────────────────────────────────────────────────────────

async function simulateMessage(phone: string, name: string, content: any) {
  console.log(`\n[Test] Sending to Bot from ${phone} (${name}):`, JSON.stringify(content));
  const msg: any = {
    from: phone,
    name: name,
    messageId: `msg_${Date.now()}`,
    type: content.type || "text",
  };

  if (msg.type === "text") {
    msg.text = content.text;
  } else if (msg.type === "interactive") {
    msg.interactiveId = content.id;
    msg.interactiveTitle = content.title;
  } else if (msg.type === "location") {
    msg.location = content.location;
  }

  await handleIncomingMessage(msg);
  
  const responses = [...sentMessages];
  sentMessages.length = 0;
  return responses;
}

function logResponses(responses: any[]) {
  responses.forEach((res, i) => {
    if (res.body.type === "text") {
      console.log(`  Bot Response ${i + 1} (Text):`, res.body.text.body);
    } else if (res.body.type === "interactive") {
      console.log(`  Bot Response ${i + 1} (Interactive ${res.body.interactive.type}):`, res.body.interactive.body.text);
      if (res.body.interactive.type === "button") {
        console.log("    Buttons:", res.body.interactive.action.buttons.map((b: any) => b.reply.title).join(" | "));
      } else if (res.body.interactive.type === "list") {
        console.log("    List Sections:", res.body.interactive.action.sections.map((s: any) => s.title).join(", "));
      }
    }
  });
}

// ─── Main Test Runner ───────────────────────────────────────────────────────

async function runTests() {
  const TEST_PHONE = "918888888888";
  const TEST_NAME = "Beta Tester";

  try {
    console.log("🚀 Starting Beta Test V2 (New Flow Validation)...");
    
    // Reset state
    await db.whatsAppCartItem.deleteMany({ where: { phone: TEST_PHONE } });
    await db.whatsAppConversation.deleteMany({ where: { phone: TEST_PHONE } });
    clearMenuCache();

    console.log("\n--- Scenario 1: Multi-Step Order Flow ---");
    
    // 1. Initial Greeting
    let responses = await simulateMessage(TEST_PHONE, TEST_NAME, { text: "Hello" });
    logResponses(responses);

    // 2. Open Menu
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_menu", type: "interactive" });
    logResponses(responses);

    // 3. Select Category
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "cat_chocolate", type: "interactive" });
    logResponses(responses);

    // 4. Select Cake
    const cakeId = responses[0]?.body.interactive.action.sections[0].rows[0].id;
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: cakeId, type: "interactive" });
    logResponses(responses);

    // 5. Select Size
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "size_0", type: "interactive" });
    logResponses(responses);

    // 6. Click "Confirm Order" (btn_checkout) - This should ADD TO CART and SHOW SUMMARY
    console.log("\n[Check] Expecting Cart Summary...");
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_checkout", type: "interactive" });
    logResponses(responses);
    const hasAdded = responses.some(r => r.body.text?.body.includes("added to cart"));
    const hasSummary = responses.some(r => r.body.interactive?.body.text.includes("Cart Summary"));
    console.log(hasAdded && hasSummary ? "✅ Success: Cake added and Summary shown." : "❌ Failure: Cart summary not shown.");

    // 7. Click "Confirm Order" (btn_checkout) AGAIN - This should PROMPT FOR ADDRESS
    console.log("\n[Check] Expecting Address Prompt...");
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_checkout", type: "interactive" });
    logResponses(responses);
    const hasAddressPrompt = responses.some(r => r.body.text?.body.includes("delivery address"));
    console.log(hasAddressPrompt ? "✅ Success: Prompted for address." : "❌ Failure: Not prompted for address.");

    // 8. Provide Address
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { text: "123 Beta Lane, Bangalore" });
    logResponses(responses);
    const hasCustomPrompt = responses.some(r => r.body.text?.body.includes("Cake Customization"));
    console.log(hasCustomPrompt ? "✅ Success: Showed enhanced customization prompts." : "❌ Failure: Missing customization prompts.");

    // 9. Provide Customization
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { text: "Write 'Happy Beta' on it. Blue cream." });
    logResponses(responses);

    // 10. Select Date
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "date_2026-05-07", type: "interactive" });
    logResponses(responses);

    // 11. Select Time
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "time_12pm_3pm", type: "interactive" });
    logResponses(responses);

    // 12. Final Confirmation
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_confirm", type: "interactive" });
    logResponses(responses);

    console.log("\n--- Scenario 2: Optimized Cancel Logic ---");
    // Restart first to get to a state
    await simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_menu", type: "interactive" });
    
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { text: "Restart" });
    logResponses(responses);
    const hasCancelMsg = responses.some(r => r.body.text?.body.includes("Order cancelled"));
    const hasWelcome = responses.some(r => r.body.interactive?.body.text.includes("Welcome to *Sonna's Patisserie*"));
    console.log(hasCancelMsg && hasWelcome ? "✅ Success: Restart shows cancellation and welcome message." : "❌ Failure: Incorrect restart behavior.");

    console.log("\n--- Scenario 3: Coordinate Removal Check ---");
    // Go to address step
    await simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_menu", type: "interactive" });
    const catRes = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "cat_chocolate", type: "interactive" });
    await simulateMessage(TEST_PHONE, TEST_NAME, { id: catRes[0].body.interactive.action.sections[0].rows[0].id, type: "interactive" });
    await simulateMessage(TEST_PHONE, TEST_NAME, { id: "size_0", type: "interactive" });
    await simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_checkout", type: "interactive" });
    await simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_checkout", type: "interactive" });
    
    // Share Location
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { 
      type: "location", 
      location: { latitude: 12.9716, longitude: 77.5946, name: "Cubbon Park" } 
    });
    logResponses(responses);
    const hasCoords = responses.some(r => /[\d.]+, [\d.]+/.test(r.body.text?.body || ""));
    console.log(!hasCoords ? "✅ Success: Coordinates removed from address message." : "❌ Failure: Coordinates still present in message.");

    console.log("\n✅ Beta Test V2 Completed.");
  } catch (error) {
    console.error("\n❌ Beta Test Failed:", error);
  } finally {
    process.exit(0);
  }
}

void runTests();
