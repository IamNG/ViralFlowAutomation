// ViralFlow Automation - Dashboard Stats Edge Function
// Supabase Edge Function: dashboard-stats

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { user_id } = await req.json();

    // Get content stats
    const { data: contents } = await supabaseClient
      .from("contents")
      .select("views, likes, shares, comments, status")
      .eq("user_id", user_id);

    // Get user credits
    const { data: userData } = await supabaseClient
      .from("users")
      .select("credits_remaining, plan")
      .eq("id", user_id)
      .single();

    const totalContent = contents?.length || 0;
    const totalViews = contents?.reduce((sum: number, c: any) => sum + (c.views || 0), 0) || 0;
    const totalLikes = contents?.reduce((sum: number, c: any) => sum + (c.likes || 0), 0) || 0;
    const totalShares = contents?.reduce((sum: number, c: any) => sum + (c.shares || 0), 0) || 0;
    const totalComments = contents?.reduce((sum: number, c: any) => sum + (c.comments || 0), 0) || 0;

    const engagementRate = totalViews > 0
      ? ((totalLikes + totalShares + totalComments) / totalViews * 100).toFixed(2)
      : "0";

    return new Response(
      JSON.stringify({
        total_content: totalContent,
        total_views: totalViews,
        total_likes: totalLikes,
        total_shares: totalShares,
        credits_remaining: userData?.credits_remaining || 0,
        engagement_rate: parseFloat(engagementRate),
        growth_percentage: 12.5,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});