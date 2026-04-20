// ViralFlow Automation - Analytics Sync Engine
// Supabase Edge Function: sync-analytics
// Triggered nightly by pg_cron to pull real metrics from connected accounts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
);

serve(async (_req) => {
  try {
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

    // 1. Fetch all active connected accounts
    const { data: accounts, error: fetchErr } = await supabaseAdmin
      .from('connected_accounts')
      .select('*')
      .eq('is_active', true);

    if (fetchErr) throw fetchErr;
    if (!accounts || accounts.length === 0) {
      return new Response(JSON.stringify({ message: "No active accounts to sync" }), {
        headers: { "Content-Type": "application/json" }
      });
    }

    const results = [];

    for (const account of accounts) {
      try {
        let metrics = { views: 0, likes: 0, shares: 0, engagement: 0, followers: 0 };

        if (account.platform === 'instagram') {
          metrics = await fetchInstagramInsights(account.access_token);
        } else if (account.platform === 'facebook') {
          metrics = await fetchFacebookInsights(account.access_token);
        }

        // Upsert daily record into platform_analytics
        const { error: upsertErr } = await supabaseAdmin
          .from('platform_analytics')
          .upsert({
            user_id: account.user_id,
            connected_account_id: account.id,
            platform: account.platform,
            record_date: today,
            total_views: metrics.views,
            total_likes: metrics.likes,
            total_shares: metrics.shares,
            engagement_rate: metrics.engagement,
            followers: metrics.followers,
          }, { onConflict: 'user_id, connected_account_id, platform, record_date' });

        if (upsertErr) throw upsertErr;
        results.push({ account_id: account.id, platform: account.platform, status: 'synced', metrics });

      } catch (accErr) {
        console.error(`Sync failed for ${account.platform} (${account.id}):`, accErr.message);
        results.push({ account_id: account.id, platform: account.platform, status: 'failed', error: accErr.message });
      }
    }

    return new Response(JSON.stringify({ message: "Sync complete", synced: results.length, results }), {
      headers: { "Content-Type": "application/json" }
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
});


/**
 * Instagram Insights API
 * Requires instagram_basic permission on the user token
 */
async function fetchInstagramInsights(userAccessToken: string) {
  // Step 1: Resolve IG Business Account ID from the linked FB Page
  const pagesRes = await fetch(`https://graph.facebook.com/v19.0/me/accounts?access_token=${userAccessToken}`);
  const pagesData = await pagesRes.json();

  if (!pagesData.data || pagesData.data.length === 0) {
    throw new Error("No Facebook Pages found to resolve IG account");
  }

  const page = pagesData.data[0];
  const igRes = await fetch(`https://graph.facebook.com/v19.0/${page.id}?fields=instagram_business_account&access_token=${page.access_token}`);
  const igData = await igRes.json();

  if (!igData.instagram_business_account) {
    throw new Error("No IG Business Account linked");
  }

  const igUserId = igData.instagram_business_account.id;

  // Step 2: Fetch profile metrics
  const profileRes = await fetch(`https://graph.facebook.com/v19.0/${igUserId}?fields=followers_count,media_count&access_token=${userAccessToken}`);
  const profileData = await profileRes.json();

  // Step 3: Fetch recent media insights (last 25 posts aggregate)
  const mediaRes = await fetch(`https://graph.facebook.com/v19.0/${igUserId}/media?fields=like_count,comments_count&limit=25&access_token=${userAccessToken}`);
  const mediaData = await mediaRes.json();

  let totalLikes = 0;
  let totalComments = 0;
  const postCount = mediaData.data?.length || 1;

  for (const post of (mediaData.data || [])) {
    totalLikes += post.like_count || 0;
    totalComments += post.comments_count || 0;
  }

  const followers = profileData.followers_count || 0;
  const engagementRate = followers > 0 ? ((totalLikes + totalComments) / postCount / followers) * 100 : 0;

  return {
    views: 0, // IG doesn't expose total views without insights API approval
    likes: totalLikes,
    shares: totalComments, // Using comments as a proxy metric
    engagement: Math.round(engagementRate * 100) / 100,
    followers: followers,
  };
}


/**
 * Facebook Page Insights API
 * Requires pages_read_engagement permission
 */
async function fetchFacebookInsights(userAccessToken: string) {
  // Step 1: Resolve the primary Page
  const pagesRes = await fetch(`https://graph.facebook.com/v19.0/me/accounts?access_token=${userAccessToken}`);
  const pagesData = await pagesRes.json();

  if (!pagesData.data || pagesData.data.length === 0) {
    throw new Error("No Facebook Pages found");
  }

  const page = pagesData.data[0];
  const pageToken = page.access_token;
  const pageId = page.id;

  // Step 2: Fetch page-level aggregate insights
  const insightsRes = await fetch(
    `https://graph.facebook.com/v19.0/${pageId}/insights?metric=page_impressions,page_engaged_users,page_fans&period=day&access_token=${pageToken}`
  );
  const insightsData = await insightsRes.json();

  let views = 0;
  let engaged = 0;
  let followers = 0;

  for (const metric of (insightsData.data || [])) {
    const latestValue = metric.values?.[metric.values.length - 1]?.value || 0;
    if (metric.name === 'page_impressions') views = latestValue;
    if (metric.name === 'page_engaged_users') engaged = latestValue;
    if (metric.name === 'page_fans') followers = latestValue;
  }

  // Step 3: Fetch recent posts for likes/shares
  const feedRes = await fetch(`https://graph.facebook.com/v19.0/${pageId}/posts?fields=likes.summary(true),shares&limit=25&access_token=${pageToken}`);
  const feedData = await feedRes.json();

  let totalLikes = 0;
  let totalShares = 0;

  for (const post of (feedData.data || [])) {
    totalLikes += post.likes?.summary?.total_count || 0;
    totalShares += post.shares?.count || 0;
  }

  const engagementRate = followers > 0 ? (engaged / followers) * 100 : 0;

  return {
    views,
    likes: totalLikes,
    shares: totalShares,
    engagement: Math.round(engagementRate * 100) / 100,
    followers,
  };
}
