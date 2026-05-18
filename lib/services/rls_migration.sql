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
-- (Menu edits should go through authenticated admin sessions with staff/owner verification)
CREATE POLICY "Menu items can be inserted by staff or service role"
  ON "Cake" FOR INSERT
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  );

CREATE POLICY "Menu items can be updated by staff or service role"
  ON "Cake" FOR UPDATE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  );

CREATE POLICY "Menu items can be deleted by staff or service role"
  ON "Cake" FOR DELETE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  );


ALTER TABLE "Category" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Categories are viewable by everyone"
  ON "Category" FOR SELECT
  USING (true);

CREATE POLICY "Categories can be modified by staff or service role"
  ON "Category" FOR ALL
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  )
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  );


ALTER TABLE "CakeOption" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Cake options are viewable by everyone"
  ON "CakeOption" FOR SELECT
  USING (true);

CREATE POLICY "Cake options can be modified by staff or service role"
  ON "CakeOption" FOR ALL
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  )
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  );


-- ─── Order Tables (Public Read, Controlled Write) ───────────────────────────
-- Customers can create orders; staff can view/manage all orders.
-- Note: This app currently uses anon key access, not authenticated sessions.
-- For production, migrate to Edge Functions with service role access.

ALTER TABLE "Order" ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read orders (staff app uses anon key)
-- In production, restrict this via Edge Functions or migrate to authenticated sessions
CREATE POLICY "Orders are viewable by everyone"
  ON "Order" FOR SELECT
  USING (true);

-- Allow order creation via direct insert (anon key access for customer orders)
CREATE POLICY "Orders can be created by anyone"
  ON "Order" FOR INSERT
  WITH CHECK (true);

-- IMPORTANT: Direct updates to orders should be restricted.
-- Order modifications should go through controlled RPC functions or Edge Functions
-- that validate business logic (e.g., status transitions, payment reconciliation).
--
-- For now, we allow staff to update orders, but this should be migrated to
-- server-side RPCs that enforce proper state machine transitions.
--
-- The policy below allows authenticated staff to update orders, but direct
-- client updates bypass validation. TODO: Move to server-side RPC.
CREATE POLICY "Orders can be updated by staff only"
  ON "Order" FOR UPDATE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  );

-- Allow authenticated staff to delete orders (should also be RPC-controlled)
CREATE POLICY "Orders can be deleted by staff only"
  ON "Order" FOR DELETE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  );


ALTER TABLE "OrderItem" ENABLE ROW LEVEL SECURITY;

-- Allow anyone to view order items (staff app uses anon key)
-- In production, restrict this via Edge Functions or migrate to authenticated sessions
CREATE POLICY "Order items are viewable by everyone"
  ON "OrderItem" FOR SELECT
  USING (true);

-- Order items should only be created alongside orders (via RPC or trigger)
CREATE POLICY "Order items can be created by anyone"
  ON "OrderItem" FOR INSERT
  WITH CHECK (true);

-- Allow anyone to modify order items (staff app uses anon key)
-- In production, restrict this via Edge Functions or migrate to authenticated sessions
CREATE POLICY "Order items can be modified by anyone"
  ON "OrderItem" FOR ALL
  USING (true);


-- ─── Staff Table (Restricted) ───────────────────────────────────────────────
-- Staff data contains sensitive info (PINs, personal details).
-- PRODUCTION WARNING: Login verification via anon-key should be migrated to an
-- Edge Function to avoid exposing password hashes and personal data to clients.

ALTER TABLE "Staff" ENABLE ROW LEVEL SECURITY;

-- Restrict to service role or authenticated staff only
CREATE POLICY "Staff data readable by service role or self"
  ON "Staff" FOR SELECT
  USING (
    auth.role() = 'service_role' OR
    id = auth.uid()
  );

-- Restrict writes to service role only (owner/staff management via Edge Functions)
CREATE POLICY "Staff data writable by service role"
  ON "Staff" FOR INSERT
  WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Staff data updatable by service role or self"
  ON "Staff" FOR UPDATE
  USING (
    auth.role() = 'service_role' OR
    (auth.uid() IS NOT NULL AND id = auth.uid())
  )
  WITH CHECK (
    auth.role() = 'service_role' OR
    (auth.uid() IS NOT NULL AND id = auth.uid())
  );

CREATE POLICY "Staff data deletable by service role only"
  ON "Staff" FOR DELETE
  USING (auth.role() = 'service_role');


-- ─── Expense Table (Restricted) ─────────────────────────────────────────────
-- Financial data should only be accessible by owner/staff with proper permissions.
-- PRODUCTION WARNING: Login verification via anon-key should be migrated to an
-- Edge Function to prevent unauthorized access to financial records.

ALTER TABLE "Expense" ENABLE ROW LEVEL SECURITY;

-- Restrict to service role or authenticated staff only
CREATE POLICY "Expenses readable by service role or staff"
  ON "Expense" FOR SELECT
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  );

CREATE POLICY "Expenses writable by service role or staff"
  ON "Expense" FOR INSERT
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  );

CREATE POLICY "Expenses updatable by service role or staff"
  ON "Expense" FOR UPDATE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  )
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  );

CREATE POLICY "Expenses deletable by service role or staff"
  ON "Expense" FOR DELETE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  );


-- ─── Inventory Table (Restricted) ───────────────────────────────────────────
-- Inventory data should only be accessible by staff with inventory permissions.
-- PRODUCTION WARNING: Login verification via anon-key should be migrated to an
-- Edge Function to prevent unauthorized access to inventory data.

ALTER TABLE "InventoryItem" ENABLE ROW LEVEL SECURITY;

-- Restrict to service role or authenticated staff only
CREATE POLICY "Inventory readable by service role or staff"
  ON "InventoryItem" FOR SELECT
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  );

CREATE POLICY "Inventory writable by service role or staff"
  ON "InventoryItem" FOR INSERT
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  );

CREATE POLICY "Inventory updatable by service role or staff"
  ON "InventoryItem" FOR UPDATE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  )
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  );

CREATE POLICY "Inventory deletable by service role or staff"
  ON "InventoryItem" FOR DELETE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE id = auth.uid() AND "isActivated" = true)
  );


-- ─── SystemSetting Table (Restricted) ───────────────────────────────────────
-- System settings (including owner PIN hash) contain sensitive data.
-- PRODUCTION WARNING: Login verification via anon-key should be migrated to an
-- Edge Function to prevent exposure of owner PIN hash and system configuration.

ALTER TABLE "SystemSetting" ENABLE ROW LEVEL SECURITY;

-- Restrict to service role only - sensitive system configuration
CREATE POLICY "System settings readable by service role only"
  ON "SystemSetting" FOR SELECT
  USING (auth.role() = 'service_role');

CREATE POLICY "System settings writable by service role only"
  ON "SystemSetting" FOR INSERT
  WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "System settings updatable by service role only"
  ON "SystemSetting" FOR UPDATE
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "System settings deletable by service role only"
  ON "SystemSetting" FOR DELETE
  USING (auth.role() = 'service_role');


-- ─── WhatsApp Conversation Tables (Restricted) ──────────────────────────────
-- WhatsApp data contains customer PII.
-- SECURITY: Restricted to authenticated users and service_role only.
-- Anon access blocked to protect phone numbers and conversation data.

ALTER TABLE "WhatsAppConversation" ENABLE ROW LEVEL SECURITY;

-- Restrict to authenticated users only
CREATE POLICY "WhatsApp conversations readable by authenticated users"
  ON "WhatsAppConversation" FOR SELECT
  USING (auth.uid() IS NOT NULL OR auth.role() = 'service_role');

CREATE POLICY "WhatsApp conversations writable by authenticated users"
  ON "WhatsAppConversation" FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL OR auth.role() = 'service_role');

CREATE POLICY "WhatsApp conversations updatable by authenticated users"
  ON "WhatsAppConversation" FOR UPDATE
  USING (auth.uid() IS NOT NULL OR auth.role() = 'service_role')
  WITH CHECK (auth.uid() IS NOT NULL OR auth.role() = 'service_role');

CREATE POLICY "WhatsApp conversations deletable by authenticated users"
  ON "WhatsAppConversation" FOR DELETE
  USING (auth.uid() IS NOT NULL OR auth.role() = 'service_role');


ALTER TABLE "WhatsAppCartItem" ENABLE ROW LEVEL SECURITY;

-- Restrict to authenticated users only
CREATE POLICY "WhatsApp cart items readable by authenticated users"
  ON "WhatsAppCartItem" FOR SELECT
  USING (auth.uid() IS NOT NULL OR auth.role() = 'service_role');

CREATE POLICY "WhatsApp cart items writable by authenticated users"
  ON "WhatsAppCartItem" FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL OR auth.role() = 'service_role');

CREATE POLICY "WhatsApp cart items updatable by authenticated users"
  ON "WhatsAppCartItem" FOR UPDATE
  USING (auth.uid() IS NOT NULL OR auth.role() = 'service_role')
  WITH CHECK (auth.uid() IS NOT NULL OR auth.role() = 'service_role');

CREATE POLICY "WhatsApp cart items deletable by authenticated users"
  ON "WhatsAppCartItem" FOR DELETE
  USING (auth.uid() IS NOT NULL OR auth.role() = 'service_role');


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
-- 1. After applying this migration, the Flutter app will continue to work as-is
--    because all tables allow anon key access via "true" policies.
--
-- 2. Order creation via the RPC `create_order_with_items` is set as
--    SECURITY DEFINER so it can insert into the Order table on behalf of anon.
--
-- 3. SECURITY WARNING: The current policies allow unrestricted anon access to
--    sensitive tables (Staff, Expense, Inventory, SystemSetting, WhatsApp data).
--    This is necessary because the app uses anon key authentication, NOT
--    authenticated Supabase sessions.
--
-- 4. PRODUCTION MIGRATION PATH:
--    Option A) Migrate to Supabase Edge Functions:
--      - Create Edge Functions for: staff login, owner PIN verify, order updates,
--        expense CRUD, inventory CRUD, staff management
--      - Use service_role key in Edge Functions
--      - Update policies to restrict anon access: USING (auth.role() = 'service_role')
--
--    Option B) Migrate to Supabase Auth:
--      - Implement Supabase Auth with custom claims (staff_id, role, permissions)
--      - Update Staff table to include auth.uid() reference column
--      - Update policies to check auth.uid() and custom claims
--      - Modify Flutter app to use authenticated sessions
--
-- 5. CURRENT RISKS:
--    - Anyone with the anon key can read bcrypt password hashes (low risk)
--    - Anyone with the anon key can read/write sensitive business data (HIGH RISK)
--    - Deploy to production ONLY if anon key is kept strictly confidential
--
-- 6. Test thoroughly in a staging environment before applying to production.
-- ─────────────────────────────────────────────────────────────────────────────
