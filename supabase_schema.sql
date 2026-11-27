-- ==============================================================================
-- BudgetKo / Tasker - Group Wallet Supabase Schema Setup Script
-- ==============================================================================
-- Run this script in the Supabase SQL Editor if your tables are not yet created.
-- Dashboard -> SQL Editor -> New Query -> Paste & Run
-- ==============================================================================

-- 1. Enable UUID extension if not enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Group Wallets Table
CREATE TABLE IF NOT EXISTS group_wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    currency TEXT DEFAULT '₱',
    created_by_name TEXT NOT NULL,
    created_by_id TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Group Members Table
CREATE TABLE IF NOT EXISTS group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES group_wallets(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    color_hex BIGINT DEFAULT 4280391411,
    joined_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(wallet_id, user_id)
);

-- 4. Group Transactions Table
CREATE TABLE IF NOT EXISTS group_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES group_wallets(id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL,
    transaction_type TEXT NOT NULL, -- 'expense', 'income', 'contribution'
    category TEXT DEFAULT 'General',
    notes TEXT,
    paid_by_name TEXT NOT NULL,
    paid_by_id TEXT NOT NULL,
    paid_by_color_hex BIGINT DEFAULT 4280391411,
    date TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. Helper RPC function to allow client-side table creation / migrations if needed
CREATE OR REPLACE FUNCTION exec_sql(query text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    EXECUTE query;
END;
$$;

-- 6. Enable Row Level Security (RLS)
ALTER TABLE group_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_transactions ENABLE ROW LEVEL SECURITY;

-- 7. Create Public Access Policies (Allow group members with anon key to read & write)
DROP POLICY IF EXISTS "Public access on group_wallets" ON group_wallets;
CREATE POLICY "Public access on group_wallets" ON group_wallets FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public access on group_members" ON group_members;
CREATE POLICY "Public access on group_members" ON group_members FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public access on group_transactions" ON group_transactions;
CREATE POLICY "Public access on group_transactions" ON group_transactions FOR ALL USING (true) WITH CHECK (true);

-- 8. Enable Realtime for group tables
ALTER PUBLICATION supabase_realtime ADD TABLE group_wallets;
ALTER PUBLICATION supabase_realtime ADD TABLE group_members;
ALTER PUBLICATION supabase_realtime ADD TABLE group_transactions;
