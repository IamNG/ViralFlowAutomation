// ViralFlow Automation - Auto Publish Engine
// Supabase Edge Function: auto-publish
// Triggered by pg_cron
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
);

serve(async (req) => {
  try {
    const now = new Date().toISOString();

    // 1. Fetch posts scheduled to be published
    const { data: scheduledPosts, error: fetchError } = await supabaseAdmin
      .from('contents')
      .select('*')
      .eq('status', 'scheduled')
      .lte('scheduled_at', now)
      .limit(20);

    if (fetchError) throw fetchError;
    if (!scheduledPosts || scheduledPosts.length === 0) {
      return new Response(JSON.stringify({ message: "No posts to publish" }), { headers: { "Content-Type": "application/json" } });
    }

    const results = [];

    // 2. Process each post dynamically
    for (const post of scheduledPosts) {
      try {
        const userId = post.user_id;

        // Fetch User's authorized Meta graph tokens
        const { data: accounts } = await supabaseAdmin
          .from('connected_accounts')
          .select('*')
          .eq('user_id', userId)
          .in('platform', ['facebook', 'instagram']);

        if (!accounts || accounts.length === 0) {
           throw new Error("No connected social accounts found for user");
        }

        let overallSuccess = true;
        let lastError = null;

        // For each intended platform array on the content ['facebook', 'instagram']
        for (const targetPlatform of post.platforms) {
          const authData = accounts.find(a => a.platform === targetPlatform);
          if (!authData) continue; // User didn't connect this platform

          try {
            if (targetPlatform === 'facebook') {
              await publishToFacebook(authData.access_token, post);
            } else if (targetPlatform === 'instagram') {
              await publishToInstagram(authData.access_token, post);
            }
          } catch (platErr) {
             overallSuccess = false;
             lastError = platErr.message;
             console.error(`Error publishing to ${targetPlatform}:`, platErr);
          }
        }

        // 3. Mark database correctly
        if (overallSuccess) {
          await supabaseAdmin.from('contents').update({ status: 'published', published_at: now }).eq('id', post.id);
          results.push({ id: post.id, status: 'published' });
        } else {
          await supabaseAdmin.from('contents').update({ status: 'failed' }).eq('id', post.id);
          results.push({ id: post.id, status: 'failed', error: lastError });
        }
      } catch (err) {
        await supabaseAdmin.from('contents').update({ status: 'error' }).eq('id', post.id);
        results.push({ id: post.id, status: 'error', error: err.message });
      }
    }

    return new Response(JSON.stringify({ message: "Process complete", results }), { headers: { "Content-Type": "application/json" } });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});

/**
 * Facebook Graph Engine: Dynamic Post Push
 */
async function publishToFacebook(userAccessToken: string, post: any) {
  // 1. Resolve the primary Facebook Page tied to the user
  const pagesReq = await fetch(`https://graph.facebook.com/v19.0/me/accounts?access_token=${userAccessToken}`);
  const pagesData = await pagesReq.json();
  if (!pagesData.data || pagesData.data.length === 0) throw new Error("No Facebook Pages found for user");
  
  const page = pagesData.data[0]; // For advanced MVP, we pick the first managed page
  const pageId = page.id;
  const pageToken = page.access_token; // Highly important: FB requires the PAGE access token

  // 2. Publish Image natively
  const mediaUrl = post.image_url || post.video_url; // Handle BYOC and AI generated content equally
  if (!mediaUrl) throw new Error("No media URL attached to content");

  const publishReq = await fetch(`https://graph.facebook.com/v19.0/${pageId}/photos`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      url: mediaUrl,
      message: post.body,
      access_token: pageToken
    })
  });

  const publishData = await publishReq.json();
  if (publishData.error) throw new Error(publishData.error.message);
  return publishData;
}

/**
 * Instagram Graph Engine: 2-Step Media Container Push
 */
async function publishToInstagram(userAccessToken: string, post: any) {
  // 1. Resolve the FB Page linked to IG Business Account
  const pagesReq = await fetch(`https://graph.facebook.com/v19.0/me/accounts?access_token=${userAccessToken}`);
  const pagesData = await pagesReq.json();
  if (!pagesData.data || pagesData.data.length === 0) throw new Error("No Facebook Pages found");
  
  const pageAuth = pagesData.data[0];
  
  const igResolveReq = await fetch(`https://graph.facebook.com/v19.0/${pageAuth.id}?fields=instagram_business_account&access_token=${pageAuth.access_token}`);
  const igResolveData = await igResolveReq.json();
  
  if (!igResolveData.instagram_business_account) {
    throw new Error("No Instagram Business Account linked to the Facebook Page");
  }
  const igUserId = igResolveData.instagram_business_account.id;

  // 2. Create the Media Container object
  const mediaUrl = post.image_url || post.video_url;
  if (!mediaUrl) throw new Error("Missing media URL");

  const t = mediaUrl.includes('.mp4') ? 'VIDEO' : 'IMAGE';
  const containerReq = await fetch(`https://graph.facebook.com/v19.0/${igUserId}/media`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      [t === 'VIDEO' ? 'video_url' : 'image_url']: mediaUrl,
      caption: post.body,
      media_type: t,
      access_token: userAccessToken
    })
  });

  const containerData = await containerReq.json();
  if (containerData.error) throw new Error(containerData.error.message);
  
  const creationId = containerData.id;

  // 3. Command Instagram to actively Publish the instantiated container
  const publishReq = await fetch(`https://graph.facebook.com/v19.0/${igUserId}/media_publish`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      creation_id: creationId,
      access_token: userAccessToken
    })
  });

  const publishData = await publishReq.json();
  if (publishData.error) throw new Error(publishData.error.message);
  
  return publishData;
}
