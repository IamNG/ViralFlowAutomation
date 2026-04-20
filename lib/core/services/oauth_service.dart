import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class OAuthService {
  final SupabaseClient _client;

  OAuthService(this._client);

  Future<void> connectPlatform(String platform) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // MOCK / SANDBOX Flow for Immediate Testing (Phase 2 Roadmap)
    // Replace this with Real OAuth Edge Function redirect once Meta App gets approved.
    if (platform == 'instagram' || platform == 'facebook') {
      await Future.delayed(const Duration(seconds: 2)); // Simulate API handshake
      
      await _client.from('connected_accounts').upsert({
        'user_id': userId,
        'platform': platform,
        'platform_user_id': 'mock_${platform}_123',
        'platform_username': '@developer_$platform',
        'access_token': 'mock_access_token_${platform}_xxxx',
        'is_active': true,
      }, onConflict: 'user_id, platform');
      return;
    }

    final url = Uri.parse('https://example.com/oauth/authorize?platform=$platform&user_id=$userId');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> disconnectPlatform(String platform) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Remove the OAuth token from database
    await _client
        .from('connected_accounts')
        .delete()
        .eq('user_id', userId)
        .eq('platform', platform);
  }

  Future<List<Map<String, dynamic>>> getConnectedPlatforms() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('connected_accounts')
        .select('*')
        .eq('user_id', userId);
        
    return response;
  }

  // Realtime stream for connected accounts
  Stream<List<Map<String, dynamic>>> connectedPlatformsStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _client
        .from('connected_accounts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.cast<Map<String, dynamic>>());
  }
}
