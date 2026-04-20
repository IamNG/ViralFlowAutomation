import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viralflow_automation/app/app_theme.dart';
import 'package:viralflow_automation/core/providers/providers.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '7d';
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ref.watch(connectedPlatformsStreamProvider).when(
          data: (platforms) {
            if (platforms.isEmpty) return const Text('Analytics 📊');
            return DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedAccountId,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black87),
                hint: const Text('🌍 Overview (All)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('🌍 Overview (All)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  ...platforms.map((p) => DropdownMenuItem(
                    value: p['id'] as String,
                    child: Text('@${p['platform_username']} (${p['platform']})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ))
                ],
                onChanged: (val) => setState(() => _selectedAccountId = val),
              ),
            );
          },
          loading: () => const Text('Analytics 📊'),
          error: (_, __) => const Text('Analytics 📊'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Platforms'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(
            selectedPeriod: _selectedPeriod, 
            selectedAccountId: _selectedAccountId,
            onPeriodChanged: (p) => setState(() => _selectedPeriod = p)
          ),
          const _PlatformsTab(),
          _InsightsTab(selectedAccountId: _selectedAccountId),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final String selectedPeriod;
  final String? selectedAccountId;
  final ValueChanged<String> onPeriodChanged;

  const _OverviewTab({required this.selectedPeriod, required this.selectedAccountId, required this.onPeriodChanged});

  String _formatCompactNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider(selectedAccountId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          Row(
            children: ['7d', '30d', '90d', '1y'].map((period) {
              final isSelected = selectedPeriod == period;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(period),
                  selected: isSelected,
                  onSelected: (_) => onPeriodChanged(period),
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Stats Grid
          statsAsync.when(
            data: (stats) => Column(
              children: [
                Row(
                  children: [
                    _StatBox(title: 'Total Views', value: _formatCompactNumber(stats.totalViews), change: '+12.5%', isPositive: true, icon: Icons.visibility_rounded),
                    const SizedBox(width: 12),
                    _StatBox(title: 'Engagement', value: '${stats.engagementRate.toStringAsFixed(1)}%', change: '+2.1%', isPositive: true, icon: Icons.favorite_rounded),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatBox(title: 'Total Likes', value: _formatCompactNumber(stats.totalLikes), change: '+8.7%', isPositive: true, icon: Icons.thumb_up_rounded),
                    const SizedBox(width: 12),
                    _StatBox(title: 'Total Shares', value: _formatCompactNumber(stats.totalShares), change: '-1.2%', isPositive: false, icon: Icons.share_rounded),
                  ],
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Text('Error: $e'),
          ),
          const SizedBox(height: 24),

          // Views Chart
          const Text('Views Over Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][value.toInt() % 7],
                            style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ),
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [FlSpot(0, 3.2), FlSpot(1, 4.5), FlSpot(2, 3.8), FlSpot(3, 6.1), FlSpot(4, 5.4), FlSpot(5, 7.2), FlSpot(6, 8.9)],
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Engagement Chart
          const Text('Engagement Rate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][value.toInt() % 7],
                            style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ),
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 5.2, color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 7.8, color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 6.1, color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 9.4, color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 8.2, color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 11.5, color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 10.3, color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(4))]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Top Performing Content
          const Text('Top Performing Content', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _TopContentCard(rank: 1, title: 'AI Tools for Students', views: '12.5K', engagement: '9.8%'),
          _TopContentCard(rank: 2, title: 'Morning Routine Reel', views: '8.3K', engagement: '7.2%'),
          _TopContentCard(rank: 3, title: 'Tech Tips Thread', views: '5.1K', engagement: '6.5%'),
        ],
      ),
    );
  }
}

class _PlatformsTab extends StatelessWidget {
  const _PlatformsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Platform Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _PlatformCard(
            name: 'Instagram',
            icon: Icons.camera_alt_rounded,
            color: const Color(0xFFE1306C),
            followers: '12.5K',
            posts: 45,
            engagement: '8.3%',
            reach: '34.2K',
          ),
          const SizedBox(height: 12),
          _PlatformCard(
            name: 'YouTube',
            icon: Icons.smart_display_rounded,
            color: const Color(0xFFFF0000),
            followers: '5.2K',
            posts: 18,
            engagement: '6.1%',
            reach: '18.9K',
          ),
          const SizedBox(height: 12),
          _PlatformCard(
            name: 'Twitter',
            icon: Icons.tag_rounded,
            color: const Color(0xFF1DA1F2),
            followers: '8.7K',
            posts: 120,
            engagement: '4.5%',
            reach: '22.1K',
          ),
          const SizedBox(height: 12),
          _PlatformCard(
            name: 'LinkedIn',
            icon: Icons.work_rounded,
            color: const Color(0xFF0077B5),
            followers: '3.1K',
            posts: 32,
            engagement: '5.8%',
            reach: '9.4K',
          ),
        ],
      ),
    );
  }
}

class _InsightsTab extends ConsumerWidget {
  final String? selectedAccountId;
  
  const _InsightsTab({required this.selectedAccountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider(selectedAccountId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Insights 🤖', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Best Posting Times
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Best Posting Times', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                SizedBox(height: 12),
                _InsightRow(day: 'Monday', time: '9:00 AM', score: '92%'),
                _InsightRow(day: 'Wednesday', time: '12:00 PM', score: '88%'),
                _InsightRow(day: 'Friday', time: '6:00 PM', score: '85%'),
                _InsightRow(day: 'Saturday', time: '10:00 AM', score: '79%'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content Recommendations
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_rounded, color: AppTheme.accentColor),
                    SizedBox(width: 8),
                    Text('Content Recommendations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                insightsAsync.when(
                  data: (insights) {
                    if (insights.isEmpty) return const Text('Not enough data to calculate insights yet.');
                    return Column(
                      children: insights.map((item) => _RecommendationCard(
                        title: item.title,
                        description: item.description,
                        impact: item.impact,
                      )).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, __) => Text('Could not fetch recommendations: $e'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Audience Insights
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.people_rounded, color: AppTheme.secondaryColor),
                    SizedBox(width: 8),
                    Text('Audience Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                _AudienceRow(label: 'Top Age Group', value: '18-24'),
                _AudienceRow(label: 'Top Location', value: 'India 🇮🇳'),
                _AudienceRow(label: 'Active Hours', value: '9-11 PM'),
                _AudienceRow(label: 'Growth Rate', value: '+15.2% this month'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Widgets

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;

  const _StatBox({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const Spacer(),
                Icon(
                  isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 14,
                  color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                ),
                Text(change,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopContentCard extends StatelessWidget {
  final int rank;
  final String title;
  final String views;
  final String engagement;

  const _TopContentCard({
    required this.rank,
    required this.title,
    required this.views,
    required this.engagement,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1 ? Colors.amber : rank == 2 ? Colors.grey : Colors.brown;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: rankColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(child: Text('#$rank', style: TextStyle(fontWeight: FontWeight.bold, color: rankColor, fontSize: 12))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(views, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(engagement, style: const TextStyle(fontSize: 11, color: AppTheme.successColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final String followers;
  final int posts;
  final String engagement;
  final String reach;

  const _PlatformCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.followers,
    required this.posts,
    required this.engagement,
    required this.reach,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('$followers followers', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
              Text('$posts posts', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(label: 'Engagement', value: engagement),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(label: 'Reach', value: reach),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String day;
  final String time;
  final String score;

  const _InsightRow({required this.day, required this.time, required this.score});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(day, style: const TextStyle(color: Colors.white, fontSize: 13))),
          SizedBox(width: 70, child: Text(time, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(score, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final String title;
  final String description;
  final String impact;

  const _RecommendationCard({
    required this.title,
    required this.description,
    required this.impact,
  });

  @override
  Widget build(BuildContext context) {
    final impactColor = impact == 'High' ? AppTheme.successColor : AppTheme.warningColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: impactColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(impact, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: impactColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AudienceRow extends StatelessWidget {
  final String label;
  final String value;

  const _AudienceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}