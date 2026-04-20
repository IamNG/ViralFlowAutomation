// ViralFlow Automation - Content Repurposing Engine
// Takes one caption and intelligently adapts it for multiple platforms
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) throw new Error("Unauthorized");

    const { caption, platforms, tone, language } = await req.json();

    if (!caption || !platforms || platforms.length === 0) {
      throw new Error("caption and platforms[] are required");
    }

    const platformRules: Record<string, string> = {
      instagram: "Max 2200 chars. Use emojis heavily. Include 20-30 hashtags at the end. Hook in first line. Use line breaks for readability.",
      facebook: "Conversational tone. No hashtag spam (max 3-5). Can be longer form. Include a call-to-action question at the end.",
      twitter: "Max 280 chars. Be punchy and witty. Use max 2-3 hashtags inline. No fluff.",
      linkedin: "Professional but human. Use paragraph breaks. Include industry insights. Max 5 hashtags. End with a thought-provoking question.",
      tiktok: "Very short caption (50-100 chars). Trendy slang. 3-5 viral hashtags like #fyp #viral. Hook-style.",
      youtube: "SEO-optimized description. Include timestamps format. Keyword-rich first 2 lines. Call to subscribe.",
    };

    let results: Record<string, any> = {};

    if (OPENAI_API_KEY) {
      // AI-powered repurposing
      const platformPrompts = platforms.map((p: string) => `${p}: ${platformRules[p] || "Adapt naturally."}`).join("\n");

      const openaiRes = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${OPENAI_API_KEY}`,
        },
        body: JSON.stringify({
          model: "gpt-3.5-turbo",
          messages: [
            {
              role: "system",
              content: `You are a world-class social media copywriter. Given one piece of content, repurpose it for multiple platforms following each platform's best practices.
              
Tone: ${tone || "casual"}
Language: ${language || "english"}

Platform rules:
${platformPrompts}

Return STRICTLY valid JSON with this exact format:
{
  "variants": {
    "platform_name": {
      "caption": "adapted caption text",
      "hashtags": ["#tag1", "#tag2"],
      "char_count": 150,
      "tip": "one line pro tip for this platform"
    }
  }
}`
            },
            { role: "user", content: `Original content:\n${caption}` }
          ],
          temperature: 0.7,
          max_tokens: 2000,
        }),
      });

      const aiData = await openaiRes.json();
      const parsed = JSON.parse(aiData.choices[0].message?.content || "{}");
      results = parsed.variants || {};
    } else {
      // Intelligent fallback without OpenAI
      for (const platform of platforms) {
        let adapted = caption;
        let hashtags: string[] = [];
        let tip = "";

        switch (platform) {
          case "twitter":
            adapted = caption.substring(0, 250) + (caption.length > 250 ? "..." : "");
            hashtags = ["#viral", "#trending"];
            tip = "Keep it under 280 characters for maximum engagement";
            break;
          case "instagram":
            adapted = "🔥 " + caption + "\n\n.\n.\n.";
            hashtags = ["#reels", "#explore", "#viral", "#trending", "#instagood", "#fyp"];
            tip = "Use a strong hook in the first line — it's all users see before 'more'";
            break;
          case "facebook":
            adapted = caption + "\n\n💬 What do you think? Drop your thoughts below! 👇";
            hashtags = ["#trending", "#viral"];
            tip = "End with a question to boost comment engagement";
            break;
          case "linkedin":
            adapted = "💡 " + caption + "\n\n---\nWhat's your take on this? I'd love to hear from industry experts.";
            hashtags = ["#leadership", "#innovation", "#growth"];
            tip = "Professional storytelling drives 3x more shares on LinkedIn";
            break;
          case "tiktok":
            adapted = caption.substring(0, 80) + " 🔥";
            hashtags = ["#fyp", "#viral", "#foryou", "#trending"];
            tip = "Keep it ultra short — TikTok captions should be a teaser, not the story";
            break;
          case "youtube":
            adapted = caption + "\n\n⏰ Timestamps:\n0:00 - Intro\n0:30 - Main Content\n\n🔔 Subscribe for more!\n\n";
            hashtags = ["#youtube", "#shorts", "#subscribe"];
            tip = "First 2 lines appear in search results — make them keyword-rich";
            break;
          default:
            hashtags = ["#content", "#viral"];
            tip = "Adapt your content to match this platform's audience";
        }

        results[platform] = {
          caption: adapted,
          hashtags,
          char_count: adapted.length,
          tip,
        };
      }
    }

    return new Response(JSON.stringify({ variants: results }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
