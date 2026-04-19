import 'package:flutter/material.dart';
import 'package:viralflow_automation/app/app_theme.dart';
import 'package:viralflow_automation/core/models/content_model.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viralflow_automation/core/providers/providers.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final scheduledAsync = ref.watch(scheduledContentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule 📅'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(scheduledContentProvider),
        child: Column(
          children: [
            // Date Selector
            _DateSelector(
              selectedDate: _selectedDate,
              onDateChanged: (date) => setState(() => _selectedDate = date),
            ),
            const SizedBox(height: 8),

            // Best Time Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Best Time to Post Today',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('9:00 AM & 8:00 PM for maximum engagement',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Timeline
            scheduledAsync.when(
              data: (allScheduled) {
                // Filter by selected date
                final dayItems = allScheduled.where((val) {
                  if (val.scheduledAt == null) return false;
                  final d = val.scheduledAt!;
                  return d.year == _selectedDate.year &&
                         d.month == _selectedDate.month &&
                         d.day == _selectedDate.day;
                }).toList();

                // Sort by time
                dayItems.sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

                return Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Schedule",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('${dayItems.length} posts',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (dayItems.isEmpty)
                        Expanded(
                          child: Center(
                            child: Text('No posts scheduled for this day.', style: TextStyle(color: Colors.grey[500])),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: dayItems.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final item = dayItems[index];
                              return _ScheduleTimelineCard(
                                content: item,
                                isLast: index == dayItems.length - 1,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
              loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
              error: (e, __) => Expanded(child: Center(child: Text('Error: $e'))),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScheduleDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Schedule Post'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showScheduleDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const _SchedulePostSheet(),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DateSelector({required this.selectedDate, required this.onDateChanged});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.add(Duration(days: i)));

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day.day == selectedDate.day && day.month == selectedDate.month;
          final isToday = index == 0;

          return GestureDetector(
            onTap: () => onDateChanged(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected ? null : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday ? 'Today' : _dayName(day.weekday),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  Text(
                    _monthName(day.month),
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white70 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _ScheduleTimelineCard extends StatelessWidget {
  final ContentModel content;
  final bool isLast;

  const _ScheduleTimelineCard({required this.content, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final timeStr = content.scheduledAt != null
        ? '${content.scheduledAt!.hour.toString().padLeft(2, '0')}:${content.scheduledAt!.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          SizedBox(
            width: 60,
            child: Text(
              timeStr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),

          // Timeline Indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
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
                        Text(content.title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          content.platforms.isNotEmpty ? content.platforms.first.name : 'Web',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        color: AppTheme.primaryColor,
                        onPressed: () {},
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        color: AppTheme.successColor,
                        onPressed: () {},
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SchedulePostSheet extends StatelessWidget {
  const _SchedulePostSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Schedule a Post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.article_rounded),
              hintText: 'Select content to schedule',
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: () {},
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.calendar_today_rounded),
                    hintText: 'Date',
                  ),
                  readOnly: true,
                  onTap: () async {
                    await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.access_time_rounded),
                    hintText: 'Time',
                  ),
                  readOnly: true,
                  onTap: () async {
                    await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.schedule_rounded),
              label: const Text('Schedule Post'),
            ),
          ),
        ],
      ),
    );
  }
}