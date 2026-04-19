import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:viralflow_automation/app/app_theme.dart';
import 'package:viralflow_automation/core/providers/providers.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final recentContentAsync = ref.watch(recentContentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ViralFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentUserProvider);
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(recentContentProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              userAsync.when(
                data: (user) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${user.fullName.split(' ').first}! 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to create viral content today?',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
                loading: () => const SizedBox(
                  height: 60,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, __) => Text('Welcome back! 👋\n(${e.toString().split('\\n')[0]})',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),

              // Quick Stats Row
              statsAsync.when(
                data: (stats) => Row(
                  children: [
                    _StatCard(
                      title: 'Content',
                      value: stats.totalContent.toString(),
                      icon: Icons.article_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      title: 'Views',
                      value: _formatCompactNumber(stats.totalViews),
                      icon: Icons.visibility_rounded,
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      title: 'Credits',
                      value: stats.creditsRemaining.toString(),
                      icon: Icons.bolt_rounded,
                      color: AppTheme.accentColor,
                    ),
                  ],
                ),
                loading: () => _buildShimmerStatsRow(),
                error: (e, __) => const Text('Unable to load stats.'),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text('Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _QuickActionCard(
                    icon: Icons.auto_awesome_rounded,
                    label: 'AI Post',
                    gradient: AppTheme.primaryGradient,
                    onTap: () => context.go('/create'),
                  ),
                  const SizedBox(width: 12),
                  _QuickActionCard(
                    icon: Icons.schedule_rounded,
                    label: 'Schedule',
                    gradient: AppTheme.accentGradient,
                    onTap: () => context.go('/schedule'),
                  ),
                  const SizedBox(width: 12),
                  _QuickActionCard(
                    icon: Icons.trending_up_rounded,
                    label: 'Trends',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                    ),
                    onTap: () => context.go('/analytics'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Trending Topics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🔥 Trending Topics',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => context.go('/analytics'),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _TrendingTopicCard(
                  title: 'AI Tools for Creators', category: 'Tech', growth: '+245%'),
              const _TrendingTopicCard(
                  title: 'Instagram Reels Tips', category: 'Social Media', growth: '+180%'),
              const _TrendingTopicCard(
                  title: 'Side Hustle Ideas', category: 'Business', growth: '+156%'),
              const SizedBox(height: 24),

              // Recent Content
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Content',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => context.go('/content'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              recentContentAsync.when(
                data: (contents) {
                  if (contents.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Text('No content created yet.', style: TextStyle(color: Colors.grey[600])),
                    );
                  }
                  return Column(
                    children: contents.map((c) => _RecentContentCard(
                      title: c.title,
                      status: c.status.name,
                      views: _formatCompactNumber(c.views),
                      platform: c.platforms.isNotEmpty ? c.platforms.first.name : 'Web',
                    )).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, __) => const Text('Unable to load recent content.'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCompactNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildShimmerStatsRow() {
    return Row(
      children: List.generate(3, (index) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      )),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendingTopicCard extends StatelessWidget {
  final String title;
  final String category;
  final String growth;

  const _TrendingTopicCard({
    required this.title,
    required this.category,
    required this.growth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(category, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(growth,
                style: const TextStyle(
                    color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _RecentContentCard extends StatelessWidget {
  final String title;
  final String status;
  final String views;
  final String platform;

  const _RecentContentCard({
    required this.title,
    required this.status,
    required this.views,
    required this.platform,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'Published'
        ? AppTheme.successColor
        : status == 'Scheduled'
            ? AppTheme.primaryColor
            : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.article_rounded, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Text(platform, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(width: 8),
                    if (views != '-')
                      Text('$views views', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}