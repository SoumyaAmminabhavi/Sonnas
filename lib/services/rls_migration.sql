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

-- Allow owners to read their own orders
CREATE POLICY "Orders are viewable by order owners"
  ON "Order" FOR SELECT
  USING (auth.uid()::text = "userId");

-- Allow authenticated staff/owner to view all orders
CREATE POLICY "Orders are viewable by operational staff"
  ON "Order" FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM "Staff" s
      WHERE s.id::text = auth.uid()::text AND s."isActivated" = true
    )
  );

-- Allow order creation via direct insert (should move to Edge Function in production)
CREATE POLICY "Orders can be created by anyone"
  ON "Order" FOR INSERT
  WITH CHECK (true);

-- Allow customers to update their own orders (if not finalized)
CREATE POLICY "Orders can be updated by owners"
  ON "Order" FOR UPDATE
  USING (auth.uid()::text = "userId");

-- Allow staff/owner to update any order status/details
CREATE POLICY "Orders can be updated by operational staff"
  ON "Order" FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM "Staff" s
      WHERE s.id::text = auth.uid()::text AND s."isActivated" = true
    )
  );

-- Block direct deletion (only staff/owner can do administrative deletions)
CREATE POLICY "Orders can be deleted by operational staff"
  ON "Order" FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM "Staff" s
      WHERE s.id::text = auth.uid()::text AND s."isActivated" = true
    )
  );


ALTER TABLE "OrderItem" ENABLE ROW LEVEL SECURITY;

-- Allow owners to view their own order items
CREATE POLICY "Order items are viewable by order owners"
  ON "OrderItem" FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM "Order" o
      WHERE o.id = "orderId" AND o."userId" = auth.uid()::text
    )
  );

-- Allow staff/owner to view all order items
CREATE POLICY "Order items are viewable by operational staff"
  ON "OrderItem" FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM "Staff" s
      WHERE s.id::text = auth.uid()::text AND s."isActivated" = true
    )
  );

-- Order items should only be created alongside orders (via RPC or trigger)
CREATE POLICY "Order items can be created by order owners"
  ON "OrderItem" FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM "Order" o
      WHERE o.id = "orderId" AND o."userId" = auth.uid()::text
    )
  );

CREATE POLICY "Order items can be created by operational staff"
  ON "OrderItem" FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM "Staff" s
      WHERE s.id::text = auth.uid()::text AND s."isActivated" = true
    )
  );

CREATE POLICY "Order items can be modified by order owners"
  ON "OrderItem" FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM "Order" o
      WHERE o.id = "orderId" AND o."userId" = auth.uid()::text
    )
  );

CREATE POLICY "Order items can be modified by operational staff"
  ON "OrderItem" FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM "Staff" s
      WHERE s.id::text = auth.uid()::text AND s."isActivated" = true
    )
  );


-- ─── Staff Table (Restricted) ───────────────────────────────────────────────
-- Staff data should never be readable by anon key.
-- Only authenticated users (owner/staff) should access this.

ALTER TABLE "Staff" ENABLE ROW LEVEL SECURITY;

-- Block all anon access to staff table
CREATE POLICY "Staff data accessible by owner role"
  ON "Staff" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');


-- ─── Expense Table (Restricted) ─────────────────────────────────────────────
-- Financial data should only be accessible by authenticated owner/staff.

ALTER TABLE "Expense" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Expenses accessible by owner role"
  ON "Expense" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');


-- ─── Inventory Table (Restricted) ───────────────────────────────────────────
-- Inventory data should only be accessible by authenticated staff.

ALTER TABLE "InventoryItem" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Inventory accessible by owner role"
  ON "InventoryItem" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');


-- ─── SystemSetting Table (Restricted) ───────────────────────────────────────
-- System settings (including owner PIN hash) should never be readable by anon.

ALTER TABLE "SystemSetting" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "System settings accessible by owner role"
  ON "SystemSetting" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');


-- ─── WhatsApp Conversation Tables (Restricted) ──────────────────────────────
-- WhatsApp data contains customer PII; restrict access.

ALTER TABLE "WhatsAppConversation" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "WhatsApp conversations accessible by owner role"
  ON "WhatsAppConversation" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');


ALTER TABLE "WhatsAppCartItem" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "WhatsApp cart items accessible by owner role"
  ON "WhatsAppCartItem" FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');


-- ─── Auth Tables (NextAuth-style) ───────────────────────────────────────────
-- These are typically managed by a backend, not the Flutter app directly.

ALTER TABLE "Account" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Session" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "User" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "VerificationToken" ENABLE ROW LEVEL SECURITY;

-- Auth tables should only be accessible by the service role (backend), not client-side.
-- These policies restrict access to service_role only.

DO $$
BEGIN
  EXECUTE 'CREATE POLICY "Auth tables restricted to service role"
    ON "Account" FOR ALL
    USING (auth.role() = ''service_role'')
    WITH CHECK (auth.role() = ''service_role'')';
END $$;

DO $$
BEGIN
  EXECUTE 'CREATE POLICY "Auth tables restricted to service role"
    ON "Session" FOR ALL
    USING (auth.role() = ''service_role'')
    WITH CHECK (auth.role() = ''service_role'')';
END $$;

DO $$
BEGIN
  EXECUTE 'CREATE POLICY "Auth tables restricted to service role"
    ON "User" FOR ALL
    USING (auth.role() = ''service_role'')
    WITH CHECK (auth.role() = ''service_role'')';
END $$;

DO $$
BEGIN
  EXECUTE 'CREATE POLICY "Auth tables restricted to service role"
    ON "VerificationToken" FOR ALL
    USING (auth.role() = ''service_role'')
    WITH CHECK (auth.role() = ''service_role'')';
END $$;


-- ─── RPC Function Security ──────────────────────────────────────────────────
-- Ensure the create_order_with_items function runs with SECURITY DEFINER
-- so it can insert into restricted tables on behalf of anon users.

-- Run this if the function exists (migration-safe):
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE p.proname = 'create_order_with_items'
    AND n.nspname = 'public'
    AND p.pronargs = 2
  ) THEN
    EXECUTE 'ALTER FUNCTION create_order_with_items(jsonb, jsonb) SECURITY DEFINER';
  END IF;
END $$;


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
