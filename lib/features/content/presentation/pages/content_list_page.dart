import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viralflow_automation/app/app_theme.dart';
import 'package:viralflow_automation/core/models/content_model.dart';
import 'package:viralflow_automation/core/providers/providers.dart';

class ContentListPage extends ConsumerStatefulWidget {
  const ContentListPage({super.key});

  @override
  ConsumerState<ContentListPage> createState() => _ContentListPageState();
}

class _ContentListPageState extends ConsumerState<ContentListPage> {
  ContentStatus? _filterStatus;
  ContentType? _filterType;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ContentModel> _getFilteredContent(List<ContentModel> allContent) {
    return allContent.where((item) {
      if (_filterStatus != null && item.status != _filterStatus) return false;
      if (_filterType != null && item.contentType != _filterType) return false;
      if (_searchController.text.isNotEmpty && !item.title.toLowerCase().contains(_searchController.text.toLowerCase())) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allContentAsync = ref.watch(allContentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Content'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(allContentProvider),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Search content...',
                  suffixIcon: _filterStatus != null || _filterType != null || _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            setState(() {
                              _filterStatus = null;
                              _filterType = null;
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            // Filter Chips
            if (_filterStatus != null || _filterType != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (_filterStatus != null)
                      Chip(
                        label: Text(_filterStatus!.name, style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _filterStatus = null),
                        backgroundColor: _statusColor(_filterStatus!).withOpacity(0.1),
                      ),
                    if (_filterType != null)
                      Chip(
                        label: Text(_filterType!.name, style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _filterType = null),
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      ),
                  ],
                ),
              ),

            // Content List
            Expanded(
              child: allContentAsync.when(
                data: (contents) {
                  final filtered = _getFilteredContent(contents);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('No content found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          Text('Create your first viral post!', style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _ContentCard(content: filtered[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, __) => Center(child: Text('Error loading content: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to create content
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create New'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter Content', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ContentStatus.values.map((status) => FilterChip(
                      selected: _filterStatus == status,
                      onSelected: (selected) {
                        setModalState(() => _filterStatus = selected ? status : null);
                        setState(() => _filterStatus = selected ? status : null);
                      },
                      label: Text(status.name),
                    )).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ContentType.values.map((type) => FilterChip(
                      selected: _filterType == type,
                      onSelected: (selected) {
                        setModalState(() => _filterType = selected ? type : null);
                        setState(() => _filterType = selected ? type : null);
                      },
                      label: Text(type.name),
                    )).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(ContentStatus status) {
    switch (status) {
      case ContentStatus.published:
        return AppTheme.successColor;
      case ContentStatus.scheduled:
        return AppTheme.primaryColor;
      case ContentStatus.draft:
        return Colors.grey;
      case ContentStatus.generated:
        return AppTheme.secondaryColor;
      case ContentStatus.failed:
        return AppTheme.errorColor;
    }
  }
}

class _ContentCard extends StatelessWidget {
  final ContentModel content;

  const _ContentCard({required this.content});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(content.status);
    final isWeb = content.platforms.isEmpty;

    return Dismissible(
      key: ValueKey(content.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: AppTheme.errorColor),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.schedule_rounded, color: AppTheme.primaryColor),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return await _showDeleteConfirm(context);
        }
        // Schedule action
        return false;
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            // Type Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(content.contentType), color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 14),

            // Content Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(content.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      isWeb ? const Text('Web') : _PlatformBadge(platform: content.platforms.first),
                      const SizedBox(width: 8),
                      Text(content.createdAt.toString().substring(0, 10), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                  if (content.views > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.visibility_rounded, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('${content.views}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        const SizedBox(width: 12),
                        Icon(Icons.favorite_rounded, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('${content.likes}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(content.status.name,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(ContentType type) {
    switch (type) {
      case ContentType.post: return Icons.article_rounded;
      case ContentType.reel: return Icons.play_circle_rounded;
      case ContentType.story: return Icons.auto_stories_rounded;
      case ContentType.thread: return Icons.forum_rounded;
      case ContentType.carousel: return Icons.view_carousel_rounded;
      case ContentType.tweet: return Icons.tag_rounded;
      case ContentType.youtubeShort: return Icons.smart_display_rounded;
      case ContentType.blog: return Icons.edit_note_rounded;
    }
  }

  Color _statusColor(ContentStatus status) {
    switch (status) {
      case ContentStatus.published: return AppTheme.successColor;
      case ContentStatus.scheduled: return AppTheme.primaryColor;
      case ContentStatus.draft: return Colors.grey;
      case ContentStatus.generated: return AppTheme.secondaryColor;
      case ContentStatus.failed: return AppTheme.errorColor;
    }
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  final Platform platform;

  const _PlatformBadge({required this.platform});

  @override
  Widget build(BuildContext context) {
    final color = _platformColor(platform);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(platform.name,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Color _platformColor(Platform p) {
    switch (p) {
      case Platform.instagram: return const Color(0xFFE1306C);
      case Platform.youtube: return const Color(0xFFFF0000);
      case Platform.twitter: return const Color(0xFF1DA1F2);
      case Platform.linkedin: return const Color(0xFF0077B5);
      case Platform.facebook: return const Color(0xFF1877F2);
      case Platform.tiktok: return const Color(0xFF000000);
    }
  }
}