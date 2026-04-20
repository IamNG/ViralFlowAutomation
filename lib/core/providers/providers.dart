import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viralflow_automation/core/services/auth_service.dart';
import 'package:viralflow_automation/core/services/ai_service.dart';
import 'package:viralflow_automation/core/services/content_service.dart';
import 'package:viralflow_automation/core/services/subscription_service.dart';
import 'package:viralflow_automation/core/services/analytics_service.dart';
import 'package:viralflow_automation/core/models/content_model.dart';

// Supabase client provider
import 'package:viralflow_automation/core/services/oauth_service.dart';

// Supabase client provider
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// OAuth service provider
final oauthServiceProvider = Provider<OAuthService>((ref) {
  return OAuthService(ref.read(supabaseProvider));
});

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(supabaseProvider));
});

// AI service provider
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService(ref.read(supabaseProvider));
});

// Content service provider
final contentServiceProvider = Provider<ContentService>((ref) {
  return ContentService(ref.read(supabaseProvider));
});

// Subscription service provider
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(ref.read(supabaseProvider));
});

// Analytics service provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref.read(supabaseProvider));
});

// Auth state provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authServiceProvider).authStateStream;
});

// Current user provider
final currentUserProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(authServiceProvider).getCurrentUserProfile();
});

// Dashboard stats provider
final dashboardStatsProvider = FutureProvider.family.autoDispose<DashBoardStats, String?>((ref, accountId) async {
  return ref.read(analyticsServiceProvider).getDashboardStats(accountId: accountId);
});

// Recent content provider
final recentContentProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(contentServiceProvider).getUserContent(limit: 5);
});

// All content provider
final allContentProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(contentServiceProvider).getUserContent(limit: 100);
});

// Content performance provider (30 days)
final contentPerformanceProvider = FutureProvider.family.autoDispose<List<DailyStats>, String?>((ref, accountId) async {
  return ref.read(analyticsServiceProvider).getContentPerformance(days: 30, accountId: accountId);
});

// Platform analytics provider
final platformAnalyticsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(analyticsServiceProvider).getPlatformAnalytics();
});

// Best posting times provider
final bestPostingTimesProvider = FutureProvider.family.autoDispose<List<PostingTime>, String?>((ref, accountId) async {
  return ref.read(analyticsServiceProvider).getBestPostingTimes(accountId: accountId);
});

// Scheduled content provider
final scheduledContentProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(contentServiceProvider).getUserContent(
        status: ContentStatus.scheduled,
        limit: 100, // fetching a generous limit to filter later by day
      );
});

// AI Insights provider
final insightsProvider = FutureProvider.family.autoDispose<List<InsightRecommendation>, String?>((ref, accountId) async {
  return ref.read(analyticsServiceProvider).getInsights(accountId: accountId);
});

// Connected platforms provider
final connectedPlatformsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(oauthServiceProvider).getConnectedPlatforms();
});

// Connected platforms Stream provider
final connectedPlatformsStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(oauthServiceProvider).connectedPlatformsStream();
});