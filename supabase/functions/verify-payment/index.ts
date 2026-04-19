// ViralFlow Automation - Razorpay Payment Verification Edge Function
// Supabase Edge Function: verify-payment

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const RAZORPAY_KEY_SECRET = Deno.env.get("RAZORPAY_KEY_SECRET")!;

const PLAN_PRICES: Record<string, Record<string, number>> = {
  pro: { monthly: 49900, yearly: 499900 },
  enterprise: { monthly: 199900, yearly: 1999900 },
};

async function verifySignature(orderId: string, paymentId: string, signature: string, secret: string) {
  const data = new TextEncoder().encode(`${orderId}|${paymentId}`);
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const signedBuffer = await crypto.subtle.sign("HMAC", key, data);
  const hex = Array.from(new Uint8Array(signedBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return hex === signature;
}

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

    const { plan, billing_cycle, razorpayOrderId, razorpayPaymentId, razorpaySignature } = await req.json();

    if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return new Response(JSON.stringify({ error: "Missing payment details" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const isValid = await verifySignature(razorpayOrderId, razorpayPaymentId, razorpaySignature, RAZORPAY_KEY_SECRET);
    if (!isValid) {
      return new Response(JSON.stringify({ error: "Invalid payment signature" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Since signature is valid, fetch the order from Razorpay to verify its notes
    const auth = btoa(`${Deno.env.get("RAZORPAY_KEY_ID")!}:${RAZORPAY_KEY_SECRET}`);
    const rzpRes = await fetch(`https://api.razorpay.com/v1/orders/${razorpayOrderId}`, {
      headers: { Authorization: `Basic ${auth}` }
    });
    const orderDetails = await rzpRes.json();
    
    // Ensure the order originally belonged to this user and for this plan
    if (orderDetails.notes?.user_id !== user.id || orderDetails.notes?.plan !== plan) {
      // return error if hijacked
      return new Response(JSON.stringify({ error: "Order details mismatch" }), {
         status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Avoid double processing
    const { data: existingSub } = await supabaseClient.from('subscriptions').select('*').eq('razorpay_order_id', razorpayOrderId).maybeSingle();
    if (existingSub) {
      return new Response(JSON.stringify({ success: true, message: "Already processed" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    // Note: use service_role since user RLS might block if not properly configured for inserts depending on RLS
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const now = new Date();
    const periodEnd = new Date(now);
    if (billing_cycle === 'monthly') {
      periodEnd.setDate(now.getDate() + 30);
    } else {
      periodEnd.setFullYear(now.getFullYear() + 1);
    }

    const planDetails = plan === 'pro' ? { credits_per_month: 500 } : { credits_per_month: -1 };

    const { data: newSub, error: subError } = await supabaseAdmin.from('subscriptions').insert({
      user_id: user.id,
      plan: plan,
      status: 'active',
      amount: PLAN_PRICES[plan][billing_cycle] / 100, // back to rupees
      currency: 'INR',
      billing_cycle: billing_cycle,
      credits_per_month: planDetails.credits_per_month,
      credits_used: 0,
      current_period_start: now.toISOString(),
      current_period_end: periodEnd.toISOString(),
      razorpay_payment_id: razorpayPaymentId,
      razorpay_order_id: razorpayOrderId,
      razorpay_signature: razorpaySignature,
    }).select().single();

    if (subError) throw subError;

    // Update user profile
    await supabaseAdmin
        .from('users')
        .update({ plan: plan, updated_at: now.toISOString() })
        .eq('id', user.id);

    return new Response(
      JSON.stringify({ success: true, subscription: newSub }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
