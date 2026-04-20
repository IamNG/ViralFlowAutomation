// ViralFlow Automation - AI Content Generation Edge Function
// Supabase Edge Function: generate-content
// Uses OpenAI API to generate viral social media content

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;

interface GenerateContentRequest {
  prompt: string;
  content_type: string;
  platforms: string[];
  tone?: string;
  language?: string;
  target_audience?: string;
  word_count?: number;
}

function buildSystemPrompt(req: GenerateContentRequest): string {
  const languageMap: Record<string, string> = {
    hinglish: "Hinglish (Hindi written in English script, like 'Aaj main bataunga...')",
    english: "English",
    hindi: "Hindi (Devanagari script)",
  };

  const toneMap: Record<string, string> = {
    casual: "casual and friendly",
    professional: "professional and authoritative",
    humorous: "funny and entertaining",
    inspirational: "motivational and inspiring",
    educational: "informative and educational",
    controversial: "bold and thought-provoking",
  };

  const platformGuides: Record<string, string> = {
    instagram: "Instagram: Use emojis, short paragraphs, call-to-action at the end. Max 2200 chars for caption.",
    youtube: "YouTube: Include hook in first 2 lines, use timestamps, end with subscribe CTA.",
    twitter: "Twitter/X: Keep under 280 chars, use 1-2 hashtags max, be punchy.",
    linkedin: "LinkedIn: Professional tone, use bullet points, share insights and lessons.",
    facebook: "Facebook: Conversational, ask questions to drive engagement.",
    tiktok: "TikTok: Short, trendy, use current slang and hooks.",
  };

  const platformTips = req.platforms
    .map((p) => platformGuides[p] || "")
    .filter(Boolean)
    .join("\n");

  return `You are a viral social media content creator AI. Generate highly engaging, viral-worthy content.

Language: ${languageMap[req.language] || "Hinglish"}
Tone: ${toneMap[req.tone] || "casual and friendly"}
Content Type: ${req.content_type}
Target Audience: ${req.target_audience || "general social media users"}
Word Count: Around ${req.word_count || 150} words

Platform Guidelines:
${platformTips}

Rules:
1. Create scroll-stopping hooks in the first line
2. Use relevant emojis (but don't overdo it)
3. Include a clear call-to-action
4. Make it shareable and relatable
5. Use storytelling when possible
6. Return the response as JSON with "caption" and "hashtags" fields
7. Generate 8-12 relevant hashtags
8. Suggest the best posting time as "suggested_time" field`;
}

serve(async (req) => {
  // Handle CORS
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

    // Verify user
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Check credits
    const { data: userData } = await supabaseClient
      .from("users")
      .select("plan, credits_remaining")
      .eq("id", user.id)
      .single();

    if (!userData) {
      return new Response(JSON.stringify({ error: "User not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (userData.plan !== "enterprise" && userData.credits_remaining <= 0) {
      return new Response(JSON.stringify({ error: "No credits remaining. Please upgrade your plan." }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body: GenerateContentRequest = await req.json();

    // Call OpenAI
    const openaiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: buildSystemPrompt(body) },
          { role: "user", content: body.prompt },
        ],
        temperature: 0.8,
        max_tokens: 1000,
        response_format: { type: "json_object" },
      }),
    });

    const openaiData = await openaiResponse.json();
    
    if (!openaiResponse.ok || !openaiData.choices) {
      console.error("OpenAI Error:", openaiData);
      return new Response(
        JSON.stringify({ error: `OpenAI API Error: ${(openaiData.error?.message) || 'Unknown error'}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    
    const content = JSON.parse(openaiData.choices[0].message.content);

    // Deduct credits
    if (userData.plan !== "enterprise") {
      await supabaseClient.rpc("deduct_credits", {
        p_user_id: user.id,
        p_amount: 1,
      });
    }

    return new Response(
      JSON.stringify({
        caption: content.caption || "",
        hashtags: content.hashtags || [],
        suggested_time: content.suggested_time || "9:00 AM",
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