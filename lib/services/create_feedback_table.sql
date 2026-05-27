-- Run this in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/qwqsarpzcwwpgyimhxzn/sql

CREATE TABLE IF NOT EXISTS "Feedback" (
  id          TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  rating      NUMERIC(2,1) DEFAULT 0,
  message     TEXT DEFAULT '',
  user_phone  TEXT DEFAULT '',
  "userId"    TEXT,
  "userPhone" TEXT,
  "orderId"   TEXT,
  type        TEXT DEFAULT 'REVIEW',
  "createdAt" TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE "Feedback" ENABLE ROW LEVEL SECURITY;

-- Allow anyone (including anonymous/unauthenticated) to insert feedback
DROP POLICY IF EXISTS "Anyone can insert feedback" ON "Feedback";
CREATE POLICY "Anyone can insert feedback"
  ON "Feedback" FOR INSERT
  WITH CHECK (true);

-- Allow everyone to read feedback (owner dashboard uses anon key)
DROP POLICY IF EXISTS "Anyone can read feedback" ON "Feedback";
CREATE POLICY "Anyone can read feedback"
  ON "Feedback" FOR SELECT
  USING (true);
