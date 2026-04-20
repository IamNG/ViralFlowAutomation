import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const META_APP_ID = Deno.env.get("META_APP_ID")!;
const META_APP_SECRET = Deno.env.get("META_APP_SECRET")!;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state"); // Contains {platform}_{userId}
  
  if (!code || !state) {
    return new Response(JSON.stringify({ error: "Missing code or state" }), { status: 400 });
  }

  const [platform, userId] = state.split("_");

  try {
    // 1. Exchange the Authorization code for a Meta Access Token
    // We must use the exact redirect URI used during the initial login step.
    const redirectUri = `https://eppgbkjvsauluzlavqvj.supabase.co/functions/v1/auth-callback`;
    const tokenUrl = `https://graph.facebook.com/v19.0/oauth/access_token?client_id=${META_APP_ID}&client_secret=${META_APP_SECRET}&redirect_uri=${redirectUri}&code=${code}`;

    const tokenResponse = await fetch(tokenUrl);
    const tokenData = await tokenResponse.json();

    if (tokenData.error) {
      throw new Error(tokenData.error.message);
    }

    const accessToken = tokenData.access_token;

    // 2. Query Graph API for basic user details
    const profileResponse = await fetch(`https://graph.facebook.com/v19.0/me?fields=id,name&access_token=${accessToken}`);
    const profileData = await profileResponse.json();

    const platformUserId = profileData.id;
    const platformUsername = profileData.name || "Facebook User";

    // 3. Save into connected_accounts securely using Admin role
    const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { error: dbError } = await supabaseAdmin.from('connected_accounts').upsert({
      user_id: userId,
      platform: platform,
      platform_user_id: platformUserId,
      platform_username: platformUsername,
      access_token: accessToken,
      is_active: true,
      updated_at: new Date().toISOString()
    }, { onConflict: 'user_id, platform' });

    if (dbError) throw dbError;

    // 4. Redirect Back to the ViralFlow Flutter Dashboard
    // We redirect to the Vercel base link to prevent Vercel 404 Routing errors (SPA conflict)
    // Facebook automatically appends #_=_ we want to prevent it from confusing Vercel
    return Response.redirect('https://viralflow-automation.vercel.app/?oauth_success=true', 302);

  } catch (error) {
    console.error("OAuth Error:", error.message);
    // Redirect to app base with an error flag
    return Response.redirect(`https://viralflow-automation.vercel.app/?oauth_error=${encodeURIComponent(error.message)}`, 302);
  }
});
