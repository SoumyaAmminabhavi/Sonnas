/* eslint-disable */
import "dotenv/config";
import { handleIncomingMessage } from "../server/whatsapp/conversation-handler";
import { db } from "../server/db";
import { clearMenuCache } from "../server/whatsapp/conversation-handler";

// ─── Mock Environment ───────────────────────────────────────────────────────

const sentMessages: any[] = [];

// Mock global fetch to capture WhatsApp API calls
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

// Mock Razorpay (Since we don't have Jest, we'll let it use the real one with test keys or handle it)
// If we wanted to mock it properly without Jest, we'd need a more complex setup.
// For now, let's see if the test keys in .env work.

// Actually, since I'm running this as a standalone script with tsx, 
// I might need to mock differently if I'm not using a test runner.
// I'll manually override the exports if possible, or just rely on fetch mocking for WhatsApp.
// For Razorpay, I'll see if I can just mock the library it uses.

// ─── Test Helper ────────────────────────────────────────────────────────────

async function simulateMessage(phone: string, name: string, content: any) {
  console.log(`\n[Test] Sending to Bot from ${phone} (${name}):`, content);
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
  } else if (msg.type === "image") {
    msg.image = content.image;
  }

  await handleIncomingMessage(msg);
  
  // Return and clear sent messages for the next step
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
    } else if (res.body.type === "image") {
      console.log(`  Bot Response ${i + 1} (Image):`, res.body.image.caption);
    }
  });
}

// ─── Main Test Runner ───────────────────────────────────────────────────────

async function runTests() {
  const TEST_PHONE = "919999999999";
  const TEST_NAME = "Test User";

  try {
    console.log("🚀 Starting WhatsApp Bot E2E Tests...");
    
    // Clear state
    await db.whatsAppCartItem.deleteMany({ where: { phone: TEST_PHONE } });
    await db.whatsAppConversation.deleteMany({ where: { phone: TEST_PHONE } });
    clearMenuCache();

    // 1. Happy Path: Standard Order
    console.log("\n--- Scenario 1: Standard Order Journey ---");
    
    let responses = await simulateMessage(TEST_PHONE, TEST_NAME, { text: "Hi" });
    logResponses(responses);

    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_menu", title: "📋 View Menu", type: "interactive" });
    logResponses(responses);

    // Handle Category Selection (since we have > 10 cakes)
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "cat_chocolate", title: "🍫 Chocolate", type: "interactive" });
    logResponses(responses);

    // Now select a cake from the filtered list
    // We'll look for cake_ IDs in the response
    const cakeId = responses[0]?.body.interactive.action.sections[0].rows[0].id || "cake_1";
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: cakeId, title: "Chocolate Cake", type: "interactive" });
    logResponses(responses);

    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "size_0", title: "0.5kg — ₹750", type: "interactive" });
    logResponses(responses);

    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_checkout", title: "💳 Confirm Order", type: "interactive" });
    logResponses(responses);

    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { text: "123 Test Street, Bangalore" });
    logResponses(responses);

    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { text: "Skip" });
    logResponses(responses);

    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "date_2026-05-06", title: "Tomorrow", type: "interactive" });
    logResponses(responses);

    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "time_3pm_6pm", title: "3 PM - 6 PM", type: "interactive" });
    logResponses(responses);

    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_confirm", title: "✅ Confirm Order", type: "interactive" });
    logResponses(responses);

    // 2. Custom Order Flow
    console.log("\n--- Scenario 2: Custom Cake Flow ---");
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_custom", title: "🎨 Custom Cake", type: "interactive" });
    logResponses(responses);

    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { text: "I want a blue butterfly cake" });
    logResponses(responses);

    // 3. Edge Case: Restart
    console.log("\n--- Scenario 3: Restart Command ---");
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { text: "Restart" });
    logResponses(responses);

    // 4. Edge Case: GPS Location
    console.log("\n--- Scenario 4: GPS Location Handling ---");
    // Move to ASKING_ADDRESS first (correctly this time)
    await simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_menu", type: "interactive" });
    const catResponses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "cat_vanilla", type: "interactive" });
    const vanillaCakeId = catResponses[0]?.body.interactive.action.sections[0].rows[0].id || "cake_2";
    
    await simulateMessage(TEST_PHONE, TEST_NAME, { id: vanillaCakeId, type: "interactive" });
    await simulateMessage(TEST_PHONE, TEST_NAME, { id: "size_0", type: "interactive" });
    await simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_checkout", type: "interactive" });
    
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { 
      type: "location", 
      location: { latitude: 12.9716, longitude: 77.5946, name: "Cubbon Park" } 
    });
    logResponses(responses);

    // 5. Optimization Case: Empty Cart Checkout Rejection
    console.log("\n--- Scenario 5: Empty Cart Checkout Rejection ---");
    // Reset state first
    await simulateMessage(TEST_PHONE, TEST_NAME, { text: "Restart" });
    
    responses = await simulateMessage(TEST_PHONE, TEST_NAME, { id: "btn_checkout", type: "interactive" });
    logResponses(responses);
    const hasWarning = responses.some(r => r.body.text?.body.includes("cart is empty"));
    console.log(hasWarning ? "✅ Correctly rejected empty cart checkout." : "❌ Failed to reject empty cart checkout.");

    console.log("\n✅ E2E Tests Completed.");
  } catch (error) {
    console.error("\n❌ Test Failed:", error);
  } finally {
    process.exit(0);
  }
}

void runTests();
