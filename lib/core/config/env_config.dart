/// Environment Configuration
/// Copy this file to env_config.dart and fill in your actual values
class EnvConfig {
  // Supabase (Injected via Vercel or --dart-define)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://eppgbkjvsauluzlavqvj.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwcGdia2p2c2F1bHV6bGF2cXZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1NzMyMTgsImV4cCI6MjA5MTE0OTIxOH0.xKVzCaSj-Yiy1TVmDU55GShBHfYQKA33MTQHQEI0mzo',
  );

  // OpenAI API
  static const String openaiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: 'YOUR_OPENAI_API_KEY_HERE',
  );

  // Razorpay
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'YOUR_RAZORPAY_KEY_ID_HERE',
  );
  
  static const String razorpayKeySecret = String.fromEnvironment(
    'RAZORPAY_KEY_SECRET',
    defaultValue: 'YOUR_RAZORPAY_SECRET_HERE',
  );

  // App Config
  static const String appName = 'ViralFlow Automation';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@viralflow.app';
}