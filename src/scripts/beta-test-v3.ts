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
  }

  // Use a slight delay for some messages to test concurrency
  if (content.delay) {
    await new Promise(r => setTimeout(r, content.delay));
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
      }
    }
  });
}

// ─── Main Test Runner ───────────────────────────────────────────────────────

async function runTests() {
  const TEST_PHONE = "917777777777";
  const TEST_NAME = "Optimization Tester";

  try {
    console.log("🚀 Starting Beta Test V3 (Optimizations Validation)...");
    
    // Reset state
    await db.whatsAppCartItem.deleteMany({ where: { phone: TEST_PHONE } });
    await db.whatsAppConversation.deleteMany({ where: { phone: TEST_PHONE } });
    clearMenuCache();

    console.log("\n--- Scenario 1: Fuzzy Search Check ---");
    // Typo: "Sonna’s Clasic Chocolate" instead of "Sonna’s Classic Chocolate"
    let responses = await simulateMessage(TEST_PHONE, TEST_NAME, { text: "Sonna’s Clasic Chocolate" });
    logResponses(responses);
    const foundFuzzy = responses.some(r => r.body.interactive?.body.text.includes("Sonna’s Classic Chocolate") || r.body.text?.body.includes("Sonna’s Classic Chocolate"));
    console.log(foundFuzzy ? "✅ Success: Found 'Sonna’s Classic Chocolate' via fuzzy search." : "❌ Failure: Fuzzy search failed for 'Sonna’s Clasic Chocolate'.");

    console.log("\n--- Scenario 2: Concurrency Lock Check ---");
    console.log("[Test] Sending 3 messages simultaneously...");
    // Sending them without awaiting immediately
    const p1 = simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_menu", type: "interactive" });
    const p2 = simulateMessage(TEST_PHONE, TEST_NAME, { text: "Help" });
    const p3 = simulateMessage(TEST_PHONE, TEST_NAME, { text: "Status" });
    
    const allResults = await Promise.all([p1, p2, p3]);
    console.log("✅ Concurrency check finished (See server logs for '⏳ Queuing' messages).");

    console.log("\n--- Scenario 3: Clear Cart Check ---");
    // Add something first
    await simulateMessage(TEST_PHONE, TEST_NAME, { text: "Chocolate Cake" });
    await simulateMessage(TEST_PHONE, TEST_NAME, { id: "size_0", type: "interactive" });
    const summaryRes = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_add_to_cart", type: "interactive" });
    logResponses(summaryRes);
    
    console.log("\n[Check] Clicking 'Clear Cart'...");
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_clear_cart", type: "interactive" });
    logResponses(responses);
    const hasClearMsg = responses.some(r => r.body.text?.body.includes("Cart cleared"));
    console.log(hasClearMsg ? "✅ Success: Cart cleared via button." : "❌ Failure: Clear cart button did not work.");

    console.log("\n✅ Beta Test V3 Completed.");
  } catch (error) {
    console.error("\n❌ Beta Test Failed:", error);
  } finally {
    process.exit(0);
  }
}

void runTests();
