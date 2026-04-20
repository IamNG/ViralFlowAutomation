import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viralflow_automation/core/models/content_model.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ContentService {
  final SupabaseClient _client;

  ContentService(this._client);

  /// Create new content
  Future<ContentModel> createContent(ContentModel content) async {
    final response = await _client
        .from('contents')
        .insert(content.toJson())
        .select()
        .single();
    return ContentModel.fromJson(response);
  }

  /// Upload Media to Supabase Storage
  Future<String> uploadMedia(PlatformFile file) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final ext = file.extension ?? 'mp4';
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = '$userId/$fileName';

    if (file.bytes != null) {
      // Web / Binary approach
      await _client.storage.from('content-media').uploadBinary(
            path,
            file.bytes!,
          );
    } else if (file.path != null) {
      // Mobile approach
      await _client.storage.from('content-media').upload(
            path,
            File(file.path!),
          );
    } else {
      throw Exception('Invalid file data');
    }

    return _client.storage.from('content-media').getPublicUrl(path);
  }

  /// Get all content for current user
  Future<List<ContentModel>> getUserContent({
    ContentStatus? status,
    ContentType? type,
    int limit = 20,
    int offset = 0,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    var query = _client
        .from('contents')
        .select()
        .eq('user_id', userId);

    if (status != null) {
      query = query.eq('status', status.name);
    }
    if (type != null) {
      query = query.eq('content_type', type.name);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return response.map((e) => ContentModel.fromJson(e)).toList();
  }

  /// Update content
  Future<ContentModel> updateContent(ContentModel content) async {
    final response = await _client
        .from('contents')
        .update({
          ...content.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', content.id)
        .select()
        .single();
    return ContentModel.fromJson(response);
  }

  /// Delete content
  Future<void> deleteContent(String contentId) async {
    await _client.from('contents').delete().eq('id', contentId);
  }

  /// Schedule content for publishing
  Future<ContentModel> scheduleContent({
    required String contentId,
    required DateTime scheduledAt,
    required List<Platform> platforms,
  }) async {
    final response = await _client
        .from('contents')
        .update({
          'status': 'scheduled',
          'scheduled_at': scheduledAt.toIso8601String(),
          'platforms': platforms.map((p) => p.name).toList(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', contentId)
        .select()
        .single();
    return ContentModel.fromJson(response);
  }

  /// Publish content immediately
  Future<ContentModel> publishContent(String contentId) async {
    // Call edge function to publish
    await _client.functions.invoke(
      'publish-content',
      body: {'content_id': contentId},
    );

    final response = await _client
        .from('contents')
        .update({
          'status': 'published',
          'published_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', contentId)
        .select()
        .single();
    return ContentModel.fromJson(response);
  }

  /// Get content analytics
  Future<Map<String, dynamic>> getContentAnalytics(String contentId) async {
    final response = await _client.functions.invoke(
      'content-analytics',
      body: {'content_id': contentId},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Deduct credits after content generation
  Future<void> deductCredits(int amount) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client.rpc('deduct_credits', params: {
      'user_id': userId,
      'amount': amount,
    });
  }
}