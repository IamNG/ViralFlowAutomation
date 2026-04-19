import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viralflow_automation/app/app_theme.dart';
import 'package:viralflow_automation/core/models/subscription_model.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:viralflow_automation/core/providers/providers.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  String _billingCycle = 'monthly';
  bool _isProcessing = false;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plans & Pricing 💎')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Choose Your Plan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock the full power of AI content creation',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // Billing Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _billingCycle = 'monthly'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _billingCycle == 'monthly' ? AppTheme.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Monthly',
                            style: TextStyle(
                              color: _billingCycle == 'monthly' ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _billingCycle = 'yearly'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _billingCycle == 'yearly' ? AppTheme.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Yearly',
                                style: TextStyle(
                                  color: _billingCycle == 'yearly' ? Colors.white : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _billingCycle == 'yearly' ? Colors.white30 : AppTheme.successColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Save 17%',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: _billingCycle == 'yearly' ? Colors.white : AppTheme.successColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Plan Cards
            ...AppPlans.all.map((plan) => _PlanCard(
                  plan: plan,
                  billingCycle: _billingCycle,
                  isCurrentPlan: _isCurrentPlan(plan.plan),
                  onSubscribe: () => _handleSubscribe(plan),
                  isProcessing: _isProcessing,
                )),
            const SizedBox(height: 24),

            // FAQ Section
            const Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _FaqItem(question: 'Can I cancel anytime?', answer: 'Yes! You can cancel your subscription anytime from Settings. You\'ll continue to have access until the end of your billing period.'),
            _FaqItem(question: 'What are credits?', answer: 'Credits are used each time you generate AI content. 1 credit = 1 content generation. Image generation costs 2 credits.'),
            _FaqItem(question: 'Is there a refund policy?', answer: 'We offer a 7-day money-back guarantee for all paid plans. No questions asked!'),
            _FaqItem(question: 'Can I upgrade/downgrade?', answer: 'Yes! You can upgrade or downgrade your plan anytime. The price difference will be prorated.'),
          ],
        ),
      ),
    );
  }

  bool _isCurrentPlan(SubscriptionPlan plan) {
    // TODO: Check actual user plan
    return plan == SubscriptionPlan.free;
  }

  PlanDetails? _currentPlanProcessing;

  Future<void> _handleSubscribe(PlanDetails plan) async {
    if (plan.plan == SubscriptionPlan.free) return;

    setState(() {
      _isProcessing = true;
      _currentPlanProcessing = plan;
    });

    try {
      // Create Razorpay order
      final orderData = await ref.read(subscriptionServiceProvider).createRazorpayOrder(
            plan: plan.plan,
            billingCycle: _billingCycle,
          );

      var options = {
        'key': 'rzp_test_YourActuallyKeyHere', // Should ideally come from env
        'amount': orderData['amount'],
        'name': 'ViralFlow Automation',
        'order_id': orderData['id'],
        'description': '${plan.name} Subscription',
        'prefill': {
          'contact': '', // From user profile if available
          'email': ref.read(currentUserProvider).value?.email ?? '',
        }
      };

      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      if (_currentPlanProcessing != null) {
        await ref.read(subscriptionServiceProvider).createSubscription(
              plan: _currentPlanProcessing!.plan,
              billingCycle: _billingCycle,
              razorpayPaymentId: response.paymentId!,
              razorpayOrderId: response.orderId!,
              razorpaySignature: response.signature!,
            );

        if (mounted) {
          _showPaymentSuccessDialog(_currentPlanProcessing!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Error: ${response.message}'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External Wallet Selected: ${response.walletName}'), backgroundColor: AppTheme.accentColor),
      );
    }
  }

  void _showPaymentSuccessDialog(PlanDetails plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Welcome to Pro! 🎉', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('You now have access to ${plan.creditsPerMonth == -1 ? 'unlimited' : plan.creditsPerMonth.toString()} credits per month'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Start Creating!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PlanDetails plan;
  final String billingCycle;
  final bool isCurrentPlan;
  final VoidCallback onSubscribe;
  final bool isProcessing;

  const _PlanCard({
    required this.plan,
    required this.billingCycle,
    required this.isCurrentPlan,
    required this.onSubscribe,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    final price = billingCycle == 'monthly' ? plan.monthlyPrice : plan.yearlyPrice;
    final isPro = plan.plan == SubscriptionPlan.pro;
    final isFree = plan.plan == SubscriptionPlan.free;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isPro ? AppTheme.primaryGradient : null,
        color: isPro ? null : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isPro ? null : Border.all(color: isCurrentPlan ? AppTheme.successColor : Colors.grey.withOpacity(0.2), width: isCurrentPlan ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(plan.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isPro ? Colors.white : null,
                            )),
                        if (plan.isPopular) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isPro ? Colors.white30 : AppTheme.accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Most Popular',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isPro ? Colors.white : AppTheme.accentColor,
                                )),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(plan.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isPro ? Colors.white70 : Colors.grey[600],
                        )),
                  ],
                ),
              ),
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (price > 0) ...[
                    Text(
                      '₹$price',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isPro ? Colors.white : null,
                      ),
                    ),
                    Text(
                      '/${billingCycle == 'monthly' ? 'mo' : 'yr'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isPro ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ] else ...[
                    Text('Free',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isPro ? Colors.white : AppTheme.successColor,
                        )),
                    Text('Forever',
                        style: TextStyle(
                          fontSize: 13,
                          color: isPro ? Colors.white70 : Colors.grey[600],
                        )),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Credits
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPro ? Colors.white.withOpacity(0.15) : AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, color: isPro ? Colors.white : AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  plan.creditsPerMonth == -1 ? 'Unlimited credits' : '${plan.creditsPerMonth} credits/month',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isPro ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Features
          ...plan.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 18, color: isPro ? Colors.white70 : AppTheme.successColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(feature,
                          style: TextStyle(
                            fontSize: 13,
                            color: isPro ? Colors.white.withOpacity(0.9) : Colors.grey[700],
                          )),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),

          // CTA Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrentPlan || isProcessing ? null : onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPro ? Colors.white : AppTheme.primaryColor,
                foregroundColor: isPro ? AppTheme.primaryColor : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isProcessing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      isCurrentPlan ? 'Current Plan ✓' : isFree ? 'Get Started Free' : 'Subscribe Now',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(widget.question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: Icon(_isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
        onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
        children: [
          Text(widget.answer, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5)),
        ],
      ),
    );
  }
}