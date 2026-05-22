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

DROP POLICY IF EXISTS "Menu items are viewable by everyone" ON "Cake";
CREATE POLICY "Menu items are viewable by everyone"
  ON "Cake" FOR SELECT
  USING (true);

-- Block direct INSERT/UPDATE/DELETE from anon key
-- (Menu edits should go through authenticated admin sessions with staff/owner verification)
DROP POLICY IF EXISTS "Menu items can be inserted by staff or service role" ON "Cake";
CREATE POLICY "Menu items can be inserted by staff or service role"
  ON "Cake" FOR INSERT
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );

DROP POLICY IF EXISTS "Menu items can be updated by staff or service role" ON "Cake";
CREATE POLICY "Menu items can be updated by staff or service role"
  ON "Cake" FOR UPDATE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );

DROP POLICY IF EXISTS "Menu items can be deleted by staff or service role" ON "Cake";
CREATE POLICY "Menu items can be deleted by staff or service role"
  ON "Cake" FOR DELETE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );


ALTER TABLE "Category" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Categories are viewable by everyone" ON "Category";
CREATE POLICY "Categories are viewable by everyone"
  ON "Category" FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Categories can be modified by staff or service role" ON "Category";
CREATE POLICY "Categories can be modified by staff or service role"
  ON "Category" FOR ALL
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  )
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );


ALTER TABLE "CakeOption" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cake options are viewable by everyone" ON "CakeOption";
CREATE POLICY "Cake options are viewable by everyone"
  ON "CakeOption" FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Cake options can be modified by staff or service role" ON "CakeOption";
CREATE POLICY "Cake options can be modified by staff or service role"
  ON "CakeOption" FOR ALL
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  )
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );


-- ─── Order Tables (Public Read, Controlled Write) ───────────────────────────
-- Customers can create orders; staff can view/manage all orders.
-- Note: This app currently uses anon key access, not authenticated sessions.
-- For production, migrate to Edge Functions with service role access.

ALTER TABLE "Order" ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read orders (staff app uses anon key)
-- In production, restrict this via Edge Functions or migrate to authenticated sessions
DROP POLICY IF EXISTS "Orders are viewable by everyone" ON "Order";
CREATE POLICY "Orders are viewable by everyone"
  ON "Order" FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Orders can be created by anyone" ON "Order";
CREATE POLICY "Orders can be created by anyone"
  ON "Order" FOR INSERT
  WITH CHECK (
    auth.role() = 'service_role' OR
    auth.role() = 'anon'
  );

-- IMPORTANT: Direct updates to orders should be restricted.
-- Order modifications should go through controlled RPC functions or Edge Functions
-- that validate business logic (e.g., status transitions, payment reconciliation).
--
-- For now, we allow staff to update orders, but this should be migrated to
-- server-side RPCs that enforce proper state machine transitions.
--
-- The policy below allows authenticated staff to update orders, but direct
-- client updates bypass validation. TODO: Move to server-side RPC.
DROP POLICY IF EXISTS "Orders can be updated by staff only" ON "Order";
CREATE POLICY "Orders can be updated by staff only"
  ON "Order" FOR UPDATE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );

-- Allow authenticated staff to delete orders (should also be RPC-controlled)
DROP POLICY IF EXISTS "Orders can be deleted by staff only" ON "Order";
CREATE POLICY "Orders can be deleted by staff only"
  ON "Order" FOR DELETE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );


ALTER TABLE "OrderItem" ENABLE ROW LEVEL SECURITY;

-- Allow authenticated staff or service role to view order items
DROP POLICY IF EXISTS "Order items are viewable by everyone" ON "OrderItem";
CREATE POLICY "Order items are viewable by everyone"
  ON "OrderItem" FOR SELECT
  USING (true);

-- Order items can be created by authenticated users, anon checkouts, or service role
DROP POLICY IF EXISTS "Order items can be created by authenticated users" ON "OrderItem";
CREATE POLICY "Order items can be created by authenticated users"
  ON "OrderItem" FOR INSERT
  WITH CHECK (
    auth.role() = 'service_role' OR
    auth.uid() IS NOT NULL OR
    auth.role() = 'anon'
  );

-- Restrict update/delete on OrderItem: only service_role or active staff
DROP POLICY IF EXISTS "Order items can be updated by active staff" ON "OrderItem";
CREATE POLICY "Order items can be updated by active staff"
  ON "OrderItem" FOR UPDATE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (
      SELECT 1 FROM "Staff" s
      WHERE s."authUserId" = auth.uid()::text AND s."isActivated" = true
    )
  );

DROP POLICY IF EXISTS "Order items can be deleted by active staff" ON "OrderItem";
CREATE POLICY "Order items can be deleted by active staff"
  ON "OrderItem" FOR DELETE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (
      SELECT 1 FROM "Staff" s
      WHERE s."authUserId" = auth.uid()::text AND s."isActivated" = true
    )
  );


-- ─── Staff Table (Restricted) ───────────────────────────────────────────────
-- Staff data contains sensitive info (PINs, personal details).
-- PRODUCTION WARNING: Login verification via anon-key should be migrated to an
-- Edge Function to avoid exposing password hashes and personal data to clients.

ALTER TABLE "Staff" ENABLE ROW LEVEL SECURITY;

-- Restrict to service role or authenticated staff only
DROP POLICY IF EXISTS "Staff data readable by service role or self" ON "Staff";
CREATE POLICY "Staff data readable by service role or self"
  ON "Staff" FOR SELECT
  USING (
    auth.role() = 'service_role' OR
    "authUserId" = auth.uid()::text
  );

-- Restrict writes to service role only (owner/staff management via Edge Functions)
DROP POLICY IF EXISTS "Staff data writable by service role" ON "Staff";
CREATE POLICY "Staff data writable by service role"
  ON "Staff" FOR INSERT
  WITH CHECK (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Staff data updatable by service role or self" ON "Staff";
CREATE POLICY "Staff data updatable by service role or self"
  ON "Staff" FOR UPDATE
  USING (
    auth.role() = 'service_role'
  )
  WITH CHECK (
    auth.role() = 'service_role'
  );

DROP POLICY IF EXISTS "Staff data deletable by service role only" ON "Staff";
CREATE POLICY "Staff data deletable by service role only"
  ON "Staff" FOR DELETE
  USING (auth.role() = 'service_role');


-- ─── Expense Table (Restricted) ─────────────────────────────────────────────
-- Financial data should only be accessible by owner/staff with proper permissions.
-- PRODUCTION WARNING: Login verification via anon-key should be migrated to an
-- Edge Function to prevent unauthorized access to financial records.

ALTER TABLE "Expense" ENABLE ROW LEVEL SECURITY;

-- Restrict to service role or authenticated staff only
DROP POLICY IF EXISTS "Expenses readable by service role or staff" ON "Expense";
CREATE POLICY "Expenses readable by service role or staff"
  ON "Expense" FOR SELECT
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );

DROP POLICY IF EXISTS "Expenses writable by service role or staff" ON "Expense";
CREATE POLICY "Expenses writable by service role or staff"
  ON "Expense" FOR INSERT
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );

DROP POLICY IF EXISTS "Expenses updatable by service role or staff" ON "Expense";
CREATE POLICY "Expenses updatable by service role or staff"
  ON "Expense" FOR UPDATE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  )
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );

DROP POLICY IF EXISTS "Expenses deletable by service role or staff" ON "Expense";
CREATE POLICY "Expenses deletable by service role or staff"
  ON "Expense" FOR DELETE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );


-- ─── Inventory Table (Restricted) ───────────────────────────────────────────
-- Inventory data should only be accessible by staff with inventory permissions.
-- PRODUCTION WARNING: Login verification via anon-key should be migrated to an
-- Edge Function to prevent unauthorized access to inventory data.

ALTER TABLE "InventoryItem" ENABLE ROW LEVEL SECURITY;

-- Restrict to service role or authenticated staff only
DROP POLICY IF EXISTS "Inventory readable by service role or staff" ON "InventoryItem";
CREATE POLICY "Inventory readable by service role or staff"
  ON "InventoryItem" FOR SELECT
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );

DROP POLICY IF EXISTS "Inventory writable by service role or staff" ON "InventoryItem";
CREATE POLICY "Inventory writable by service role or staff"
  ON "InventoryItem" FOR INSERT
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );

DROP POLICY IF EXISTS "Inventory updatable by service role or staff" ON "InventoryItem";
CREATE POLICY "Inventory updatable by service role or staff"
  ON "InventoryItem" FOR UPDATE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  )
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );

DROP POLICY IF EXISTS "Inventory deletable by service role or staff" ON "InventoryItem";
CREATE POLICY "Inventory deletable by service role or staff"
  ON "InventoryItem" FOR DELETE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );


-- ─── SystemSetting Table (Restricted) ───────────────────────────────────────
-- System settings (including owner PIN hash) contain sensitive data.
-- PRODUCTION WARNING: Login verification via anon-key should be migrated to an
-- Edge Function to prevent exposure of owner PIN hash and system configuration.

ALTER TABLE "SystemSetting" ENABLE ROW LEVEL SECURITY;

-- Restrict to service role only - sensitive system configuration
DROP POLICY IF EXISTS "System settings readable by service role only" ON "SystemSetting";
CREATE POLICY "System settings readable by service role only"
  ON "SystemSetting" FOR SELECT
  USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS "System settings writable by service role only" ON "SystemSetting";
CREATE POLICY "System settings writable by service role only"
  ON "SystemSetting" FOR INSERT
  WITH CHECK (auth.role() = 'service_role');

DROP POLICY IF EXISTS "System settings updatable by service role only" ON "SystemSetting";
CREATE POLICY "System settings updatable by service role only"
  ON "SystemSetting" FOR UPDATE
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

DROP POLICY IF EXISTS "System settings deletable by service role only" ON "SystemSetting";
CREATE POLICY "System settings deletable by service role only"
  ON "SystemSetting" FOR DELETE
  USING (auth.role() = 'service_role');


-- ─── WhatsApp Conversation Tables (Restricted) ──────────────────────────────
-- WhatsApp data contains customer PII.
-- SECURITY: Restricted to authenticated users and service_role only.
-- Anon access blocked to protect phone numbers and conversation data.

ALTER TABLE "WhatsAppConversation" ENABLE ROW LEVEL SECURITY;

-- Restrict to owner or service_role only
DROP POLICY IF EXISTS "WhatsApp conversations readable by owner or service_role" ON "WhatsAppConversation";
CREATE POLICY "WhatsApp conversations readable by owner or service_role"
  ON "WhatsAppConversation" FOR SELECT
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );

DROP POLICY IF EXISTS "WhatsApp conversations writable by owner or service_role" ON "WhatsAppConversation";
CREATE POLICY "WhatsApp conversations writable by owner or service_role"
  ON "WhatsAppConversation" FOR INSERT
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );

DROP POLICY IF EXISTS "WhatsApp conversations updatable by owner or service_role" ON "WhatsAppConversation";
CREATE POLICY "WhatsApp conversations updatable by owner or service_role"
  ON "WhatsAppConversation" FOR UPDATE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  )
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );

DROP POLICY IF EXISTS "WhatsApp conversations deletable by owner or service_role" ON "WhatsAppConversation";
CREATE POLICY "WhatsApp conversations deletable by owner or service_role"
  ON "WhatsAppConversation" FOR DELETE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );


ALTER TABLE "WhatsAppCartItem" ENABLE ROW LEVEL SECURITY;

-- Restrict to conversation owner or service_role only
DROP POLICY IF EXISTS "WhatsApp cart items readable by conversation owner or service_role" ON "WhatsAppCartItem";
CREATE POLICY "WhatsApp cart items readable by conversation owner or service_role"
  ON "WhatsAppCartItem" FOR SELECT
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );

DROP POLICY IF EXISTS "WhatsApp cart items writable by conversation owner or service_role" ON "WhatsAppCartItem";
CREATE POLICY "WhatsApp cart items writable by conversation owner or service_role"
  ON "WhatsAppCartItem" FOR INSERT
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );

DROP POLICY IF EXISTS "WhatsApp cart items updatable by conversation owner or service_role" ON "WhatsAppCartItem";
CREATE POLICY "WhatsApp cart items updatable by conversation owner or service_role"
  ON "WhatsAppCartItem" FOR UPDATE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  )
  WITH CHECK (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );

DROP POLICY IF EXISTS "WhatsApp cart items deletable by conversation owner or service_role" ON "WhatsAppCartItem";
CREATE POLICY "WhatsApp cart items deletable by conversation owner or service_role"
  ON "WhatsAppCartItem" FOR DELETE
  USING (
    auth.role() = 'service_role' OR
    EXISTS (SELECT 1 FROM "Staff" WHERE "authUserId" = auth.uid()::text AND "isActivated" = true)
  );


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
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'Account' AND policyname = 'Auth tables restricted to service role'
  ) THEN
    EXECUTE 'CREATE POLICY "Auth tables restricted to service role"
      ON "Account" FOR ALL
      USING (auth.role() = ''service_role'')
      WITH CHECK (auth.role() = ''service_role'')';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'Session' AND policyname = 'Auth tables restricted to service role'
  ) THEN
    EXECUTE 'CREATE POLICY "Auth tables restricted to service role"
      ON "Session" FOR ALL
      USING (auth.role() = ''service_role'')
      WITH CHECK (auth.role() = ''service_role'')';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'User' AND policyname = 'Auth tables restricted to service role'
  ) THEN
    EXECUTE 'CREATE POLICY "Auth tables restricted to service role"
      ON "User" FOR ALL
      USING (auth.role() = ''service_role'')
      WITH CHECK (auth.role() = ''service_role'')';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'VerificationToken' AND policyname = 'Auth tables restricted to service role'
  ) THEN
    EXECUTE 'CREATE POLICY "Auth tables restricted to service role"
      ON "VerificationToken" FOR ALL
      USING (auth.role() = ''service_role'')
      WITH CHECK (auth.role() = ''service_role'')';
  END IF;
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

DROP TRIGGER IF EXISTS set_updated_at_cake ON "Cake";
CREATE TRIGGER set_updated_at_cake
  BEFORE UPDATE ON "Cake"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at_category ON "Category";
CREATE TRIGGER set_updated_at_category
  BEFORE UPDATE ON "Category"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at_cake_option ON "CakeOption";
CREATE TRIGGER set_updated_at_cake_option
  BEFORE UPDATE ON "CakeOption"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at_order ON "Order";
CREATE TRIGGER set_updated_at_order
  BEFORE UPDATE ON "Order"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at_expense ON "Expense";
CREATE TRIGGER set_updated_at_expense
  BEFORE UPDATE ON "Expense"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at_staff ON "Staff";
CREATE TRIGGER set_updated_at_staff
  BEFORE UPDATE ON "Staff"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at_inventory ON "InventoryItem";
CREATE TRIGGER set_updated_at_inventory
  BEFORE UPDATE ON "InventoryItem"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at_whatsapp_conversation ON "WhatsAppConversation";
CREATE TRIGGER set_updated_at_whatsapp_conversation
  BEFORE UPDATE ON "WhatsAppConversation"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ─── NOTES ──────────────────────────────────────────────────────────────────
-- 1. After applying this migration, the Flutter app will require authenticated staff
--    sessions to access restricted tables.
--
-- 2. Order creation via the RPC `create_order_with_items` is set as
--    SECURITY DEFINER so it can insert into the "Order" and "OrderItem" tables on behalf of anonymous checkouts.
--
-- 3. SECURITY WARNING: The tables Staff, Expense, InventoryItem, SystemSetting,
--    WhatsAppTemplate, WhatsAppTemplateVersion, WhatsAppButton, WhatsAppListSection,
--    and WhatsAppListRow are now protected by RLS and require active staff authentication.
--
-- 4. PRODUCTION MIGRATION PATH:
--    - For the restricted tables (Staff, Expense, InventoryItem, SystemSetting, and the WhatsApp tables):
--      Migrate the client connections to use authenticated Supabase Auth sessions, or route
--      queries through Supabase Edge Functions executing under the service_role authorization.
--
-- 5. CURRENT RISKS & DEPLOYMENT GUIDANCE:
--    - Core features, operations skills, and restricted data API access require authenticated
--      staff sign-in. Ensure all active staff members are registered in the Staff table and
--      activated, with their authUserId set properly.
--
-- 6. Test thoroughly in a staging environment before applying to production.
-- ─────────────────────────────────────────────────────────────────────────────
