// ViralFlow Automation - Auto Publish Engine
// Supabase Edge Function: auto-publish
// Triggered by pg_cron every minute

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
);

serve(async (req) => {
  try {
    // Authenticate that only trusted sources can call this (e.g. pg_net header)
    // Optional depending on your Supabase configuration

    const now = new Date().toISOString();

    // 1. Fetch posts scheduled to be published
    const { data: scheduledPosts, error: fetchError } = await supabaseAdmin
      .from('contents')
      .select('*')
      .eq('status', 'scheduled')
      .lte('scheduled_at', now)
      .limit(50);

    if (fetchError) throw fetchError;
    if (!scheduledPosts || scheduledPosts.length === 0) {
      return new Response(JSON.stringify({ message: "No posts to publish" }), {
        headers: { "Content-Type": "application/json" }
      });
    }

    const results = [];

    // 2. Iterate and publish each post to its intended platforms
    for (const post of scheduledPosts) {
      try {
        const userId = post.user_id;

        // Fetch user's social media tokens
        const { data: integrations } = await supabaseAdmin
          .from('platform_integrations')
          .select('*')
          .eq('user_id', userId);

        let success = true;
        let errorMessage = null;

        // Simple loop indicating we try to post to every platform set for this content
        // In reality, you would map over post.platforms array and hit Social APIs
        // For demonstration, we simulate success
        
        // ... (API logic to send post.body/images to Twitter/LinkedIn/Instagram based on integrations data)

        // 3. Mark post as published or failed
        if (success) {
          await supabaseAdmin
            .from('contents')
            .update({ status: 'published', published_at: now })
            .eq('id', post.id);
          results.push({ id: post.id, status: 'published' });
        } else {
          await supabaseAdmin
            .from('contents')
            .update({ status: 'failed' }) // optionally store errorMessage
            .eq('id', post.id);
          results.push({ id: post.id, status: 'failed', error: errorMessage });
        }
      } catch (err) {
        results.push({ id: post.id, status: 'error', error: err.message });
      }
    }

    return new Response(JSON.stringify({ message: "Process complete", results }), {
      headers: { "Content-Type": "application/json" }
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
});
