-- ViralFlow Automation - Database Schema
-- Migration: 001_initial_schema
-- Created: 2026-04-12

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS TABLE (extends Supabase Auth)
-- ============================================
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  avatar_url TEXT DEFAULT '',
  plan TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free', 'pro', 'enterprise')),
  credits_remaining INTEGER NOT NULL DEFAULT 10,
  total_content_generated INTEGER NOT NULL DEFAULT 0,
  connected_platforms TEXT[] DEFAULT '{}',
  referral_code TEXT UNIQUE DEFAULT uuid_generate_v4()::TEXT,
  referred_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Users can only see and update their own profile
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

-- Auto-create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- CONTENTS TABLE
-- ============================================
CREATE TABLE public.contents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  caption TEXT DEFAULT '',
  hashtags TEXT[] DEFAULT '{}',
  image_url TEXT DEFAULT '',
  video_url TEXT DEFAULT '',
  ai_prompt TEXT DEFAULT '',
  content_type TEXT NOT NULL CHECK (content_type IN ('post', 'reel', 'story', 'thread', 'carousel', 'tweet', 'youtube_short', 'blog')),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'generated', 'scheduled', 'published', 'failed')),
  platforms TEXT[] DEFAULT '{}',
  scheduled_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  likes INTEGER DEFAULT 0,
  shares INTEGER DEFAULT 0,
  views INTEGER DEFAULT 0,
  comments INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.contents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own content" ON public.contents
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own content" ON public.contents
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own content" ON public.contents
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own content" ON public.contents
  FOR DELETE USING (auth.uid() = user_id);

-- Index for faster queries
CREATE INDEX idx_contents_user_id ON public.contents(user_id);
CREATE INDEX idx_contents_status ON public.contents(status);
CREATE INDEX idx_contents_scheduled_at ON public.contents(scheduled_at) WHERE status = 'scheduled';

-- ============================================
-- SUBSCRIPTIONS TABLE
-- ============================================
CREATE TABLE public.subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  plan TEXT NOT NULL CHECK (plan IN ('free', 'pro', 'enterprise')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'past_due')),
  amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'INR',
  billing_cycle TEXT NOT NULL DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'yearly')),
  credits_per_month INTEGER NOT NULL DEFAULT 10,
  credits_used INTEGER NOT NULL DEFAULT 0,
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  razorpay_payment_id TEXT,
  razorpay_order_id TEXT,
  razorpay_signature TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscriptions" ON public.subscriptions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscriptions" ON public.subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscriptions" ON public.subscriptions
  FOR UPDATE USING (auth.uid() = user_id);

CREATE INDEX idx_subscriptions_user_id ON public.subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON public.subscriptions(status);

-- ============================================
-- ANALYTICS TABLE
-- ============================================
CREATE TABLE public.analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content_id UUID REFERENCES public.contents(id) ON DELETE SET NULL,
  platform TEXT NOT NULL,
  event_type TEXT NOT NULL CHECK (event_type IN ('view', 'like', 'share', 'comment', 'follow', 'click')),
  event_value INTEGER DEFAULT 1,
  event_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own analytics" ON public.analytics
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own analytics" ON public.analytics
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_analytics_user_id ON public.analytics(user_id);
CREATE INDEX idx_analytics_date ON public.analytics(event_date);
CREATE INDEX idx_analytics_content_id ON public.analytics(content_id);

-- ============================================
-- CONNECTED ACCOUNTS TABLE
-- ============================================
CREATE TABLE public.connected_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('instagram', 'youtube', 'twitter', 'linkedin', 'facebook', 'tiktok')),
  platform_user_id TEXT NOT NULL,
  platform_username TEXT NOT NULL,
  access_token TEXT NOT NULL,
  refresh_token TEXT,
  token_expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, platform)
);

-- Enable RLS
ALTER TABLE public.connected_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own accounts" ON public.connected_accounts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own accounts" ON public.connected_accounts
  FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- REFERRALS TABLE
-- ============================================
CREATE TABLE public.referrals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  referrer_id UUID NOT NULL REFERENCES public.users(id),
  referred_id UUID NOT NULL REFERENCES public.users(id),
  bonus_credits INTEGER DEFAULT 5,
  is_claimed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own referrals" ON public.referrals
  FOR SELECT USING (auth.uid() = referrer_id OR auth.uid() = referred_id);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Deduct credits from user
CREATE OR REPLACE FUNCTION public.deduct_credits(
  p_user_id UUID,
  p_amount INTEGER
)
RETURNS VOID AS $$
BEGIN
  UPDATE public.users
  SET credits_remaining = GREATEST(credits_remaining - p_amount, 0),
      total_content_generated = total_content_generated + 1,
      updated_at = NOW()
  WHERE id = p_user_id AND plan != 'enterprise';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add credits to user (for referrals, purchases)
CREATE OR REPLACE FUNCTION public.add_credits(
  p_user_id UUID,
  p_amount INTEGER
)
RETURNS VOID AS $$
BEGIN
  UPDATE public.users
  SET credits_remaining = credits_remaining + p_amount,
      updated_at = NOW()
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get dashboard stats
CREATE OR REPLACE FUNCTION public.get_dashboard_stats(
  p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_content', (SELECT COUNT(*) FROM contents WHERE user_id = p_user_id),
    'total_views', (SELECT COALESCE(SUM(views), 0) FROM contents WHERE user_id = p_user_id),
    'total_likes', (SELECT COALESCE(SUM(likes), 0) FROM contents WHERE user_id = p_user_id),
    'total_shares', (SELECT COALESCE(SUM(shares), 0) FROM contents WHERE user_id = p_user_id),
    'credits_remaining', (SELECT credits_remaining FROM users WHERE id = p_user_id),
    'engagement_rate', (SELECT CASE WHEN SUM(views) > 0 
      THEN ROUND((SUM(likes)::DECIMAL + SUM(shares)::DECIMAL + SUM(comments)::DECIMAL) / SUM(views)::DECIMAL * 100, 2)
      ELSE 0 END FROM contents WHERE user_id = p_user_id),
    'growth_percentage', 12.5
  ) INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_contents_updated_at
  BEFORE UPDATE ON public.contents
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============================================
-- STORAGE BUCKETS
-- ============================================
-- Insert storage bucket for content images (run via Supabase dashboard or API)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('content-images', 'content-images', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);