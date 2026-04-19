// ViralFlow Automation - Image Generation Edge Function
// Supabase Edge Function: generate-image
// Uses OpenAI DALL-E API to generate images

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Check credits (image generation costs 2 credits)
    const { data: userData } = await supabaseClient
      .from("users")
      .select("plan, credits_remaining")
      .eq("id", user.id)
      .single();

    if (userData.plan !== "enterprise" && userData.credits_remaining < 2) {
      return new Response(JSON.stringify({ error: "Not enough credits. Image generation requires 2 credits." }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { prompt, size = "1024x1024", style = "vivid" } = await req.json();

    // Enhance prompt for social media
    const enhancedPrompt = `Create a stunning, eye-catching social media image: ${prompt}. 
    Style: Modern, vibrant colors, clean composition, professional quality. 
    The image should be suitable for Instagram/social media posting.`;

    const openaiResponse = await fetch("https://api.openai.com/v1/images/generations", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify({
        model: "dall-e-3",
        prompt: enhancedPrompt,
        n: 1,
        size,
        quality: "standard",
        style,
      }),
    });

    const openaiData = await openaiResponse.json();
    const imageUrl = openaiData.data[0].url;

    // Deduct 2 credits for image generation
    if (userData.plan !== "enterprise") {
      await supabaseClient.rpc("deduct_credits", {
        p_user_id: user.id,
        p_amount: 2,
      });
    }

    return new Response(
      JSON.stringify({ image_url: imageUrl }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});