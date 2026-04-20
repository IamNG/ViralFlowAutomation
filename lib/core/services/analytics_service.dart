import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final SupabaseClient _client;

  AnalyticsService(this._client);

  /// Get dashboard stats
  Future<DashBoardStats> getDashboardStats({String? accountId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client.functions.invoke(
      'dashboard-stats',
      body: {'user_id': userId, 'account_id': accountId},
    );

    final data = response.data as Map<String, dynamic>;
    return DashBoardStats.fromJson(data);
  }

  /// Get content performance over time
  Future<List<DailyStats>> getContentPerformance({
    int days = 30,
    String? accountId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client.functions.invoke(
      'content-performance',
      body: {
        'user_id': userId,
        'days': days,
        'account_id': accountId,
      },
    );

    final data = response.data as List;
    return data.map((e) => DailyStats.fromJson(e)).toList();
  }

  /// Get platform-wise analytics
  Future<Map<String, PlatformStats>> getPlatformAnalytics({String? accountId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client.functions.invoke(
      'platform-analytics',
      body: {'user_id': userId, 'account_id': accountId},
    );

    final data = response.data as Map<String, dynamic>;
    return data.map((key, value) =>
        MapEntry(key, PlatformStats.fromJson(value as Map<String, dynamic>)));
  }

  /// Get best posting times
  Future<List<PostingTime>> getBestPostingTimes({String? accountId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client.functions.invoke(
      'best-posting-times',
      body: {'user_id': userId, 'account_id': accountId},
    );

    final data = response.data as List;
    return data.map((e) => PostingTime.fromJson(e)).toList();
  }
}

class DashBoardStats {
  final int totalContent;
  final int totalViews;
  final int totalLikes;
  final int totalShares;
  final int creditsRemaining;
  final double engagementRate;
  final double growthPercentage;

  DashBoardStats({
    required this.totalContent,
    required this.totalViews,
    required this.totalLikes,
    required this.totalShares,
    required this.creditsRemaining,
    required this.engagementRate,
    required this.growthPercentage,
  });

  factory DashBoardStats.fromJson(Map<String, dynamic> json) => DashBoardStats(
        totalContent: json['total_content'] ?? 0,
        totalViews: json['total_views'] ?? 0,
        totalLikes: json['total_likes'] ?? 0,
        totalShares: json['total_shares'] ?? 0,
        creditsRemaining: json['credits_remaining'] ?? 0,
        engagementRate: (json['engagement_rate'] ?? 0).toDouble(),
        growthPercentage: (json['growth_percentage'] ?? 0).toDouble(),
      );
}

class DailyStats {
  final DateTime date;
  final int views;
  final int likes;
  final int shares;
  final int contentCount;

  DailyStats({
    required this.date,
    required this.views,
    required this.likes,
    required this.shares,
    required this.contentCount,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) => DailyStats(
        date: DateTime.parse(json['date']),
        views: json['views'] ?? 0,
        likes: json['likes'] ?? 0,
        shares: json['shares'] ?? 0,
        contentCount: json['content_count'] ?? 0,
      );
}

class PlatformStats {
  final String platform;
  final int followers;
  final int posts;
  final double engagementRate;
  final int totalReach;

  PlatformStats({
    required this.platform,
    required this.followers,
    required this.posts,
    required this.engagementRate,
    required this.totalReach,
  });

  factory PlatformStats.fromJson(Map<String, dynamic> json) => PlatformStats(
        platform: json['platform'] ?? '',
        followers: json['followers'] ?? 0,
        posts: json['posts'] ?? 0,
        engagementRate: (json['engagement_rate'] ?? 0).toDouble(),
        totalReach: json['total_reach'] ?? 0,
      );
}

class PostingTime {
  final String dayOfWeek;
  final String time;
  final double engagementScore;

  PostingTime({
    required this.dayOfWeek,
    required this.time,
    required this.engagementScore,
  });

  factory PostingTime.fromJson(Map<String, dynamic> json) => PostingTime(
        dayOfWeek: json['day_of_week'] ?? '',
        time: json['time'] ?? '',
        engagementScore: (json['engagement_score'] ?? 0).toDouble(),
      );
}