-- ─────────────────────────────────────────────────────────────────────────────
--  Sonna Patisserie — Row Level Security (RLS) Migration
-- ─────────────────────────────────────────────────────────────────────────────
--  Apply this SQL in your Supabase SQL Editor to enable RLS on all tables.
--  This prevents unauthorized access via the anon key.
--
--  IMPORTANT: After applying, test thoroughly. The Flutter app uses the anon
--  key directly, so policies must allow legitimate app operations while
--  blocking malicious access.
--
--  For production: Move sensitive operations (order creation, staff management,
--  inventory) to Supabase Edge Functions and tighten these policies further.
-- ─────────────────────────────────────────────────────────────────────────────

-- ─── Menu Tables (Public Read, Admin Write) ──────────────────────────────────
-- Customers need to read menu; only staff/owner should modify.

ALTER TABLE "Cake" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Menu items are viewable by everyone"
  ON "Cake" FOR SELECT
  USING (true);

-- Block direct INSERT/UPDATE/DELETE from anon key
-- (Menu edits should go through authenticated admin sessions)
CREATE POLICY "Menu items can be inserted by authenticated users"
  ON "Cake" FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Menu items can be updated by authenticated users"
  ON "Cake" FOR UPDATE
  USING (auth.role() = 'authenticated');

CREATE POLICY "Menu items can be deleted by authenticated users"
  ON "Cake" FOR DELETE
  USING (auth.role() = 'authenticated');


ALTER TABLE "Category" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Categories are viewable by everyone"
  ON "Category" FOR SELECT
  USING (true);

CREATE POLICY "Categories can be modified by authenticated users"
  ON "Category" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');


ALTER TABLE "CakeOption" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Cake options are viewable by everyone"
  ON "CakeOption" FOR SELECT
  USING (true);

CREATE POLICY "Cake options can be modified by authenticated users"
  ON "CakeOption" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');


-- ─── Order Tables (Public Read, Controlled Write) ───────────────────────────
-- Customers can create orders; everyone can read their own orders.
-- Direct UPDATE/DELETE on orders is blocked (use Edge Functions for status changes).

ALTER TABLE "Order" ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read orders (needed for order tracking)
-- In production, restrict to: USING (auth.uid() = userId OR auth.role() = 'authenticated')
CREATE POLICY "Orders are viewable by everyone"
  ON "Order" FOR SELECT
  USING (true);

-- Allow order creation via direct insert (should move to Edge Function in production)
CREATE POLICY "Orders can be created by anyone"
  ON "Order" FOR INSERT
  WITH CHECK (true);

-- Block direct updates from anon key (prevent payment/status tampering)
-- In production, only allow authenticated staff/owner to update
CREATE POLICY "Orders can be updated by authenticated users"
  ON "Order" FOR UPDATE
  USING (auth.role() = 'authenticated');

-- Block direct deletion
CREATE POLICY "Orders can be deleted by authenticated users"
  ON "Order" FOR DELETE
  USING (auth.role() = 'authenticated');


ALTER TABLE "OrderItem" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Order items are viewable by everyone"
  ON "OrderItem" FOR SELECT
  USING (true);

-- Order items should only be created alongside orders (via RPC or trigger)
CREATE POLICY "Order items can be created by anyone"
  ON "OrderItem" FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Order items can be modified by authenticated users"
  ON "OrderItem" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');


-- ─── Staff Table (Restricted) ───────────────────────────────────────────────
-- Staff data should never be readable by anon key.
-- Only authenticated users (owner/staff) should access this.

ALTER TABLE "Staff" ENABLE ROW LEVEL SECURITY;

-- Block all anon access to staff table
-- In production, use Edge Functions for staff verification
CREATE POLICY "Staff data accessible by authenticated users"
  ON "Staff" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');


-- ─── Expense Table (Restricted) ─────────────────────────────────────────────
-- Financial data should only be accessible by authenticated owner/staff.

ALTER TABLE "Expense" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Expenses accessible by authenticated users"
  ON "Expense" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');


-- ─── Inventory Table (Restricted) ───────────────────────────────────────────
-- Inventory data should only be accessible by authenticated staff.

ALTER TABLE "InventoryItem" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Inventory accessible by authenticated users"
  ON "InventoryItem" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');


-- ─── SystemSetting Table (Restricted) ───────────────────────────────────────
-- System settings (including owner PIN hash) should never be readable by anon.

ALTER TABLE "SystemSetting" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "System settings accessible by authenticated users"
  ON "SystemSetting" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');


-- ─── WhatsApp Conversation Tables (Restricted) ──────────────────────────────
-- WhatsApp data contains customer PII; restrict access.

ALTER TABLE "WhatsAppConversation" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "WhatsApp conversations accessible by authenticated users"
  ON "WhatsAppConversation" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');


ALTER TABLE "WhatsAppCartItem" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "WhatsApp cart items accessible by authenticated users"
  ON "WhatsAppCartItem" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');


-- ─── Auth Tables (NextAuth-style) ───────────────────────────────────────────
-- These are typically managed by a backend, not the Flutter app directly.

ALTER TABLE "Account" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Session" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "User" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "VerificationToken" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Auth tables accessible by authenticated users"
  ON "Account" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Auth tables accessible by authenticated users"
  ON "Session" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Auth tables accessible by authenticated users"
  ON "User" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Auth tables accessible by authenticated users"
  ON "VerificationToken" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');


-- ─── RPC Function Security ──────────────────────────────────────────────────
-- Ensure the create_order_with_items function runs with SECURITY DEFINER
-- so it can insert into restricted tables on behalf of anon users.

-- Run this if the function exists:
-- ALTER FUNCTION create_order_with_items(jsonb, jsonb) SECURITY DEFINER;


-- ─── Database Triggers for updatedAt ────────────────────────────────────────
-- These triggers automatically set updatedAt on row modification,
-- replacing the need for client-side timestamping.

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW."updatedAt" = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at_cake
  BEFORE UPDATE ON "Cake"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_updated_at_category
  BEFORE UPDATE ON "Category"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_updated_at_cake_option
  BEFORE UPDATE ON "CakeOption"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_updated_at_order
  BEFORE UPDATE ON "Order"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_updated_at_expense
  BEFORE UPDATE ON "Expense"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_updated_at_staff
  BEFORE UPDATE ON "Staff"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_updated_at_inventory
  BEFORE UPDATE ON "InventoryItem"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_updated_at_whatsapp_conversation
  BEFORE UPDATE ON "WhatsAppConversation"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ─── NOTES ──────────────────────────────────────────────────────────────────
-- 1. After applying this migration, the Flutter app's menu reading will still
--    work (SELECT is allowed for everyone on Cake/Category/CakeOption).
--
-- 2. Order creation via the RPC `create_order_with_items` needs to be set as
--    SECURITY DEFINER so it can insert into the Order table on behalf of anon.
--
-- 3. Staff login, owner PIN verification, expense tracking, and inventory
--    management will BREAK until you implement proper Supabase Auth or
--    Edge Functions. This is intentional — these operations should never
--    be accessible via the anon key.
--
-- 4. To fix the broken operations, you have two options:
--    a) Implement Supabase Edge Functions for each sensitive operation
--    b) Use Supabase Auth with custom claims to identify staff/owner
--
-- 5. Test thoroughly in a staging environment before applying to production.
-- ─────────────────────────────────────────────────────────────────────────────
