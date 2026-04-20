import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class OAuthService {
  final SupabaseClient _client;

  OAuthService(this._client);

  Future<void> connectPlatform(String platform) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    if (platform == 'facebook' || platform == 'instagram') {
      const appId = '825196553310972'; // The Client ID provided safely into code
      const redirectUri = 'https://eppgbkjvsauluzlavqvj.supabase.co/functions/v1/auth-callback';
      // We pass the platform_userId to identify who just authenticated on the callback securely
      final state = '${platform}_$userId';
      
      final String scope = platform == 'instagram' 
        ? 'instagram_basic,instagram_content_publish,pages_show_list,pages_read_engagement,pages_manage_posts'
        : 'pages_show_list,pages_read_engagement,pages_manage_posts';
        
      final url = Uri.parse('https://www.facebook.com/v19.0/dialog/oauth?client_id=$appId&redirect_uri=$redirectUri&state=$state&scope=$scope&response_type=code');

      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch Meta Gateway');
      }
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
