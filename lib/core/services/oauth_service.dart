import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class OAuthService {
  final SupabaseClient _client;

  OAuthService(this._client);

  Future<void> connectPlatform(String platform) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Here we would typically call an edge function to get the OAuth URL
    // For now, we simulate the redirection to an OAuth provider
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
        .from('platform_integrations')
        .delete()
        .eq('user_id', userId)
        .eq('platform', platform);
  }

  Future<List<Map<String, dynamic>>> getConnectedPlatforms() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('platform_integrations')
        .select('platform, profile_name, profile_picture')
        .eq('user_id', userId);
        
    return response;
  }
}
