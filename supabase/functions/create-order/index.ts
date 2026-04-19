// ViralFlow Automation - Razorpay Order Creation Edge Function
// Supabase Edge Function: create-order

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const RAZORPAY_KEY_ID = Deno.env.get("RAZORPAY_KEY_ID")!;
const RAZORPAY_KEY_SECRET = Deno.env.get("RAZORPAY_KEY_SECRET")!;

const PLAN_PRICES: Record<string, Record<string, number>> = {
  pro: { monthly: 49900, yearly: 499900 }, // Amount in paise (₹499 = 49900 paise)
  enterprise: { monthly: 199900, yearly: 1999900 },
};

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

    const { plan, billing_cycle } = await req.json();

    if (!PLAN_PRICES[plan]) {
      return new Response(JSON.stringify({ error: "Invalid plan" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const amount = PLAN_PRICES[plan][billing_cycle];
    if (!amount) {
      return new Response(JSON.stringify({ error: "Invalid billing cycle" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Create Razorpay order
    const orderPayload = {
      amount,
      currency: "INR",
      receipt: `rcpt_${user.id.substring(0, 8)}_${Date.now()}`,
      notes: {
        user_id: user.id,
        plan,
        billing_cycle,
      },
    };

    const auth = btoa(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`);

    const razorpayResponse = await fetch("https://api.razorpay.com/v1/orders", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Basic ${auth}`,
      },
      body: JSON.stringify(orderPayload),
    });

    const orderData = await razorpayResponse.json();

    return new Response(
      JSON.stringify({
        order_id: orderData.id,
        amount: orderData.amount,
        currency: orderData.currency,
        key: RAZORPAY_KEY_ID,
        prefill: {
          name: user.user_metadata?.full_name || "",
          email: user.email,
        },
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