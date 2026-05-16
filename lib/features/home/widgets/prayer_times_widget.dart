// lib/features/home/widgets/prayer_times_widget.dart
import 'package:flutter/material.dart';
import '../../../core/services/prayer_service.dart';
import '../../../core/theme/app_theme.dart';

class PrayerTimesWidget extends StatefulWidget {
  final bool fajrDone;
  final bool dhuhrDone;
  final bool asrDone;
  final bool maghribDone;
  final bool ishaDone;
  final Function(String prayer, bool val) onToggle;
  final Function(String prayer) onSurveyTap;

  const PrayerTimesWidget({
    super.key,
    required this.fajrDone,
    required this.dhuhrDone,
    required this.asrDone,
    required this.maghribDone,
    required this.ishaDone,
    required this.onToggle,
    required this.onSurveyTap,
  });

  @override
  State<PrayerTimesWidget> createState() => _PrayerTimesWidgetState();
}

class _PrayerTimesWidgetState extends State<PrayerTimesWidget> {
  List<PrayerInfo> _prayers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    final prayers = await PrayerService.instance.getTodayPrayers();
    if (mounted) {
      setState(() {
        _prayers = prayers;
        _loading = false;
      });
    }
  }

  bool _getPrayerDone(String name) {
    switch (name) {
      case 'fajr':
        return widget.fajrDone;
      case 'dhuhr':
        return widget.dhuhrDone;
      case 'asr':
        return widget.asrDone;
      case 'maghrib':
        return widget.maghribDone;
      case 'isha':
        return widget.ishaDone;
      default:
        return false;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final isAm = hour < 12;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute ${isAm ? 'ص' : 'م'}';
  }

  String _getPrayerEmoji(String name) {
    switch (name) {
      case 'fajr':
        return '🌅';
      case 'dhuhr':
        return '☀️';
      case 'asr':
        return '🌤️';
      case 'maghrib':
        return '🌆';
      case 'isha':
        return '🌙';
      default:
        return '🕌';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '🕌 الصلوات الخمس',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryGreen),
                ),
              )
            else
              ..._prayers.map((prayer) {
                final done = _getPrayerDone(prayer.name);
                final isPast = prayer.time.isBefore(DateTime.now());

                return _PrayerRow(
                  emoji: _getPrayerEmoji(prayer.name),
                  arabicName: prayer.arabicName,
                  time: _formatTime(prayer.time),
                  isDone: done,
                  isPast: isPast,
                  onToggle: (val) => widget.onToggle(prayer.name, val),
                  onSurveyTap: () => widget.onSurveyTap(prayer.name),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final String emoji;
  final String arabicName;
  final String time;
  final bool isDone;
  final bool isPast;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSurveyTap;

  const _PrayerRow({
    required this.emoji,
    required this.arabicName,
    required this.time,
    required this.isDone,
    required this.isPast,
    required this.onToggle,
    required this.onSurveyTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDone
            ? AppTheme.primaryGreen.withOpacity(0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? AppTheme.primaryGreen.withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arabicName,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDone ? AppTheme.primaryGreen : Colors.black87,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Survey button (only shows if past)
          if (isPast)
            IconButton(
              icon: Icon(
                Icons.assignment_outlined,
                color: Colors.blue.shade600,
                size: 22,
              ),
              tooltip: 'استبيان ما بعد الصلاة',
              onPressed: onSurveyTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
          const SizedBox(width: 4),
          // Checkbox
          GestureDetector(
            onTap: () => onToggle(!isDone),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDone ? AppTheme.primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDone ? AppTheme.primaryGreen : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
