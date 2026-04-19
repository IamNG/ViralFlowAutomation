-- Migration: Analytics Metrics Aggregation
-- Description: Automatically aggregates daily platform metrics to save expensive aggregate queries

-- 1. Create Analytics Aggregated Table
CREATE TABLE IF NOT EXISTS public.daily_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    total_views BIGINT DEFAULT 0,
    total_likes BIGINT DEFAULT 0,
    total_shares BIGINT DEFAULT 0,
    total_comments BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- Enable RLS
ALTER TABLE public.daily_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own analytics"
    ON public.daily_analytics FOR SELECT
    USING (auth.uid() = user_id);

-- 2. Create Aggregation Function
CREATE OR REPLACE FUNCTION public.aggregate_daily_metrics()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.daily_analytics (user_id, date, total_views, total_likes, total_shares, total_comments)
    SELECT 
        user_id,
        CURRENT_DATE,
        SUM(views) as total_views,
        SUM(likes) as total_likes,
        SUM(shares) as total_shares,
        SUM(comments) as total_comments
    FROM public.contents
    WHERE status = 'published'
    GROUP BY user_id
    ON CONFLICT (user_id, date) DO UPDATE SET
        total_views = EXCLUDED.total_views,
        total_likes = EXCLUDED.total_likes,
        total_shares = EXCLUDED.total_shares,
        total_comments = EXCLUDED.total_comments,
        created_at = NOW();
END;
$$;

-- 3. Schedule it to run daily at midnight via pg_cron
-- Remove if already exists
SELECT cron.unschedule('daily_analytics_aggregation');

SELECT cron.schedule(
    'daily_analytics_aggregation',
    '0 0 * * *', -- Run at 00:00 every day
    $$SELECT public.aggregate_daily_metrics()$$
);
