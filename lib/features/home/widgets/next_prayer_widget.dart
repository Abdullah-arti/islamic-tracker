// lib/features/home/widgets/next_prayer_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/prayer_service.dart';
import '../../../core/theme/app_theme.dart';

class NextPrayerWidget extends StatefulWidget {
  const NextPrayerWidget({super.key});

  @override
  State<NextPrayerWidget> createState() => _NextPrayerWidgetState();
}

class _NextPrayerWidgetState extends State<NextPrayerWidget> {
  PrayerInfo? _nextPrayer;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadNextPrayer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_nextPrayer != null) {
        setState(() {
          _remaining = _nextPrayer!.time.difference(DateTime.now());
          if (_remaining.isNegative) {
            _loadNextPrayer();
          }
        });
      }
    });
  }

  Future<void> _loadNextPrayer() async {
    final prayer = await PrayerService.instance.getNextPrayer();
    if (mounted) {
      setState(() {
        _nextPrayer = prayer;
        _remaining = prayer?.time.difference(DateTime.now()) ?? Duration.zero;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format2(int n) => n.toString().padLeft(2, '0');

  String _formatDuration(Duration d) {
    if (d.isNegative) return '00:00:00';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${_format2(h)}:${_format2(m)}:${_format2(s)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_nextPrayer == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('⏳', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الصلاة القادمة',
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Amiri',
                    fontSize: 14,
                  ),
                ),
                Text(
                  _nextPrayer!.arabicName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Amiri',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'الوقت المتبقي',
                style: TextStyle(
                  color: Colors.white60,
                  fontFamily: 'Amiri',
                  fontSize: 12,
                ),
              ),
              Text(
                _formatDuration(_remaining),
                style: const TextStyle(
                  color: AppTheme.accentGold,
                  fontFamily: 'Amiri',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
