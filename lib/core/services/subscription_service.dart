import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viralflow_automation/core/models/subscription_model.dart';

class SubscriptionService {
  final SupabaseClient _client;

  SubscriptionService(this._client);

  /// Get current subscription
  Future<SubscriptionModel?> getCurrentSubscription() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('subscriptions')
        .select()
        .eq('user_id', userId)
        .eq('status', 'active')
        .maybeSingle();

    if (response == null) return null;
    return SubscriptionModel.fromJson(response);
  }

  /// Create subscription (after Razorpay payment)
  Future<SubscriptionModel> createSubscription({
    required SubscriptionPlan plan,
    required String billingCycle,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final response = await _client.functions.invoke(
      'verify-payment',
      body: {
        'plan': plan.name,
        'billing_cycle': billingCycle,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      },
    );

    final data = response.data as Map<String, dynamic>;
    if (data['error'] != null) {
      throw Exception(data['error']);
    }

    return SubscriptionModel.fromJson(data['subscription'] as Map<String, dynamic>);
  }

  /// Cancel subscription
  Future<void> cancelSubscription() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client.from('subscriptions').update({
      'status': 'cancelled',
      'cancelled_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId).eq('status', 'active');

    // Downgrade user plan
    await _client
        .from('users')
        .update({'plan': 'free', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }

  /// Check if user has enough credits
  Future<bool> hasCredits(int required) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from('users')
        .select('plan, credits_remaining')
        .eq('id', userId)
        .single();

    // Enterprise has unlimited credits
    if (response['plan'] == 'enterprise') return true;

    return (response['credits_remaining'] as int) >= required;
  }

  /// Get Razorpay order ID
  Future<Map<String, dynamic>> createRazorpayOrder({
    required SubscriptionPlan plan,
    required String billingCycle,
  }) async {
    final response = await _client.functions.invoke(
      'create-order',
      body: {
        'plan': plan.name,
        'billing_cycle': billingCycle,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}