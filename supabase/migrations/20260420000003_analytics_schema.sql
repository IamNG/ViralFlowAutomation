-- ============================================
-- PLATFORM ANALYTICS SCHEMA
-- Allows dynamic multi-tenant tracking per connected account
-- ============================================

CREATE TABLE public.platform_analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  connected_account_id UUID REFERENCES public.connected_accounts(id) ON DELETE CASCADE, -- NULL means aggregate totals
  platform TEXT NOT NULL CHECK (platform IN ('instagram', 'youtube', 'twitter', 'linkedin', 'facebook', 'tiktok', 'all')),
  record_date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_views INTEGER NOT NULL DEFAULT 0,
  total_likes INTEGER NOT NULL DEFAULT 0,
  total_shares INTEGER NOT NULL DEFAULT 0,
  engagement_rate NUMERIC(5,2) NOT NULL DEFAULT 0,
  followers INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Prevent multiple entries per account per day
  UNIQUE(user_id, connected_account_id, platform, record_date)
);

-- Turn on Row Level Security
ALTER TABLE public.platform_analytics ENABLE ROW LEVEL SECURITY;

-- Analytics viewing policy
CREATE POLICY "Users can view their own analytics"
ON public.platform_analytics FOR SELECT
USING (auth.uid() = user_id);

-- Analytics insertion policy (mostly handled by edge functions, but allowing authenticated for manual syncs)
CREATE POLICY "Users can insert their own analytics"
ON public.platform_analytics FOR INSERT
WITH CHECK (auth.uid() = user_id);
