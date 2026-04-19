import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viralflow_automation/features/auth/presentation/pages/splash_page.dart';
import 'package:viralflow_automation/features/auth/presentation/pages/login_page.dart';
import 'package:viralflow_automation/features/auth/presentation/pages/signup_page.dart';
import 'package:viralflow_automation/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:viralflow_automation/features/content/presentation/pages/create_content_page.dart';
import 'package:viralflow_automation/features/content/presentation/pages/content_list_page.dart';
import 'package:viralflow_automation/features/schedule/presentation/pages/schedule_page.dart';
import 'package:viralflow_automation/features/analytics/presentation/pages/analytics_page.dart';
import 'package:viralflow_automation/features/subscription/presentation/pages/subscription_page.dart';
import 'package:viralflow_automation/features/settings/presentation/pages/settings_page.dart';
import 'package:viralflow_automation/features/home/presentation/pages/home_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final supabase = Supabase.instance.client;
  final authState = ValueNotifier<AsyncValue<bool>>(const AsyncLoading());

  supabase.auth.onAuthStateChange.listen((event) {
    final isSignedIn = event.event == AuthChangeEvent.signedIn;
    authState.value = AsyncData(isSignedIn);
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = supabase.auth.currentSession != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/splash';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardPage(),
            ),
          ),
          GoRoute(
            path: '/create',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CreateContentPage(),
            ),
          ),
          GoRoute(
            path: '/content',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ContentListPage(),
            ),
          ),
          GoRoute(
            path: '/schedule',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SchedulePage(),
            ),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsPage(),
            ),
          ),
          GoRoute(
            path: '/subscription',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SubscriptionPage(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
        ],
      ),
    ],
  );
});