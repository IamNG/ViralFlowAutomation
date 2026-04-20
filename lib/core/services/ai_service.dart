import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viralflow_automation/core/models/content_model.dart';

class AIService {
  final SupabaseClient _client;

  AIService(this._client);

  /// Generate viral content using AI (via Supabase Edge Function)
  Future<ContentResult> generateContent({
    required String prompt,
    required ContentType contentType,
    required List<Platform> platforms,
    String? tone, // casual, professional, humorous, inspirational
    String? language, // en, hi, hinglish
    String? targetAudience,
    int? wordCount,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'generate-content',
        body: {
          'prompt': prompt,
          'content_type': contentType.name,
          'platforms': platforms.map((p) => p.name).toList(),
          'tone': tone ?? 'casual',
          'language': language ?? 'hinglish',
          'target_audience': targetAudience ?? 'general',
          'word_count': wordCount ?? 150,
        },
      );

      final data = jsonDecode(response.data);
      return ContentResult.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Generate hashtags for content
  Future<List<String>> generateHashtags({
    required String content,
    required Platform platform,
    int count = 10,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'generate-hashtags',
        body: {
          'content': content,
          'platform': platform.name,
          'count': count,
        },
      );

      final data = jsonDecode(response.data);
      return List<String>.from(data['hashtags']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Generate image for content (via DALL-E)
  Future<String> generateImage({
    required String prompt,
    String size = '1024x1024',
    String style = 'vivid',
  }) async {
    try {
      final response = await _client.functions.invoke(
        'generate-image',
        body: {
          'prompt': prompt,
          'size': size,
          'style': style,
        },
      );

      final data = jsonDecode(response.data);
      return data['image_url'];
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get trending topics
  Future<List<TrendingTopic>> getTrendingTopics({
    required Platform platform,
    String? category,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'trending-topics',
        body: {
          'platform': platform.name,
          'category': category ?? 'all',
        },
      );

      final data = jsonDecode(response.data);
      return (data['topics'] as List)
          .map((t) => TrendingTopic.fromJson(t))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Repurpose content for different platforms
  Future<Map<String, RepurposedVariant>> repurposeContent({
    required String caption,
    required List<Platform> targetPlatforms,
    String tone = 'casual',
    String language = 'hinglish',
  }) async {
    try {
      final response = await _client.functions.invoke(
        'repurpose-content',
        body: {
          'caption': caption,
          'platforms': targetPlatforms.map((p) => p.name).toList(),
          'tone': tone,
          'language': language,
        },
      );

      final data = response.data is String ? jsonDecode(response.data) : response.data;
      final variants = data['variants'] as Map<String, dynamic>;
      return variants.map((key, value) =>
          MapEntry(key, RepurposedVariant.fromJson(value as Map<String, dynamic>)));
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic e) {
    if (e is FunctionException) {
      return Exception('AI Service Error: ${e.toString()}');
    }
    return Exception('Failed to generate content: $e');
  }
}

class ContentResult {
  final String caption;
  final List<String> hashtags;
  final String? imageUrl;
  final String? suggestedTime;

  ContentResult({
    required this.caption,
    required this.hashtags,
    this.imageUrl,
    this.suggestedTime,
  });

  factory ContentResult.fromJson(Map<String, dynamic> json) => ContentResult(
        caption: json['caption'] ?? '',
        hashtags: List<String>.from(json['hashtags'] ?? []),
        imageUrl: json['image_url'],
        suggestedTime: json['suggested_time'],
      );
}

class TrendingTopic {
  final String title;
  final String category;
  final int volume;
  final double growthRate;

  TrendingTopic({
    required this.title,
    required this.category,
    required this.volume,
    required this.growthRate,
  });

  factory TrendingTopic.fromJson(Map<String, dynamic> json) => TrendingTopic(
        title: json['title'] ?? '',
        category: json['category'] ?? '',
        volume: json['volume'] ?? 0,
        growthRate: (json['growth_rate'] ?? 0).toDouble(),
      );
}

class RepurposedVariant {
  final String caption;
  final List<String> hashtags;
  final int charCount;
  final String tip;

  RepurposedVariant({
    required this.caption,
    required this.hashtags,
    required this.charCount,
    required this.tip,
  });

  factory RepurposedVariant.fromJson(Map<String, dynamic> json) => RepurposedVariant(
        caption: json['caption'] ?? '',
        hashtags: List<String>.from(json['hashtags'] ?? []),
        charCount: json['char_count'] ?? 0,
        tip: json['tip'] ?? '',
      );
}