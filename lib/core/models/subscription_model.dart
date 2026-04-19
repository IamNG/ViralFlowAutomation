import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_model.freezed.dart';
part 'subscription_model.g.dart';

enum SubscriptionPlan {
  @JsonValue('free')
  free,
  @JsonValue('pro')
  pro,
  @JsonValue('enterprise')
  enterprise,
}

enum SubscriptionStatus {
  @JsonValue('active')
  active,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('expired')
  expired,
  @JsonValue('past_due')
  pastDue,
}

@freezed
class SubscriptionModel with _$SubscriptionModel {
  const factory SubscriptionModel({
    required String id,
    required String userId,
    required SubscriptionPlan plan,
    required SubscriptionStatus status,
    @Default(0) double amount,
    @Default('INR') String currency,
    @Default('monthly') String billingCycle, // monthly, yearly
    @Default(0) int creditsPerMonth,
    @Default(0) int creditsUsed,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    DateTime? cancelledAt,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _SubscriptionModel;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);
}

@freezed
class PlanDetails with _$PlanDetails {
  const factory PlanDetails({
    required SubscriptionPlan plan,
    required String name,
    required String description,
    required double monthlyPrice,
    required double yearlyPrice,
    required int creditsPerMonth,
    required List<String> features,
    @Default(false) bool isPopular,
  }) = _PlanDetails;

  factory PlanDetails.fromJson(Map<String, dynamic> json) =>
      _$PlanDetailsFromJson(json);
}

// Plan details constants
class AppPlans {
  static const free = PlanDetails(
    plan: SubscriptionPlan.free,
    name: 'Free',
    description: 'Get started with basic content creation',
    monthlyPrice: 0,
    yearlyPrice: 0,
    creditsPerMonth: 10,
    features: [
      '10 AI content generations/month',
      'Basic templates',
      '1 social media account',
      'Standard support',
    ],
  );

  static const pro = PlanDetails(
    plan: SubscriptionPlan.pro,
    name: 'Pro',
    description: 'For creators who want to go viral',
    monthlyPrice: 499,
    yearlyPrice: 4999,
    creditsPerMonth: 200,
    features: [
      '200 AI content generations/month',
      'Premium templates & AI models',
      '5 social media accounts',
      'Auto-scheduling',
      'Analytics dashboard',
      'Priority support',
    ],
    isPopular: true,
  );

  static const enterprise = PlanDetails(
    plan: SubscriptionPlan.enterprise,
    name: 'Enterprise',
    description: 'For teams and agencies',
    monthlyPrice: 1999,
    yearlyPrice: 19999,
    creditsPerMonth: -1, // unlimited
    features: [
      'Unlimited AI content generations',
      'Custom AI models',
      'Unlimited social accounts',
      'Team collaboration',
      'Advanced analytics',
      'API access',
      'Dedicated support',
    ],
  );

  static List<PlanDetails> get all => [free, pro, enterprise];
}