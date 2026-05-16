// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/services/prayer_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/screens/settings_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../surveys/screens/survey_screen.dart';
import '../widgets/worship_card.dart';
import '../widgets/prayer_times_widget.dart';
import '../widgets/next_prayer_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _todayWorship = {};
  String _todayDate = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _todayDate = _formatDate(DateTime.now());
    _loadTodayData();
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _displayDate(DateTime date) {
    // Arabic date display
    final days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];
    final months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'إبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    final dayName = days[date.weekday - 1];
    return '$dayName ${date.day} ${months[date.month]} ${date.year}';
  }

  Future<void> _loadTodayData() async {
    setState(() => _loading = true);
    final data = await DatabaseHelper.instance.getDailyWorship(_todayDate);
    setState(() {
      _todayWorship = data ?? {};
      _loading = false;
    });
  }

  Future<void> _toggleWorship(String field, bool value) async {
    final updated = Map<String, dynamic>.from(_todayWorship);
    updated[field] = value ? 1 : 0;
    await DatabaseHelper.instance.upsertDailyWorship(_todayDate, updated);
    setState(() => _todayWorship = updated);
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    ).then((_) => _loadTodayData());
  }

  void _openReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportsScreen()),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الخروج', textAlign: TextAlign.center),
        content: const Text(
          'هل تريد الخروج من التطبيق؟',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              // Exit app
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🕌'),
              const SizedBox(width: 8),
              const Text('مُتابع العبادات'),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              offset: const Offset(0, 50),
              itemBuilder: (_) => [
                _buildMenuItem(
                  value: 'settings',
                  icon: Icons.settings_outlined,
                  label: 'الإعدادات',
                  color: AppTheme.primaryGreen,
                ),
                _buildMenuItem(
                  value: 'reports',
                  icon: Icons.bar_chart_outlined,
                  label: 'التقارير',
                  color: Colors.blue.shade700,
                ),
                const PopupMenuDivider(),
                _buildMenuItem(
                  value: 'exit',
                  icon: Icons.exit_to_app_outlined,
                  label: 'الخروج',
                  color: Colors.red.shade600,
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'settings':
                    _openSettings();
                    break;
                  case 'reports':
                    _openReports();
                    break;
                  case 'exit':
                    _showExitDialog();
                    break;
                }
              },
            ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : RefreshIndicator(
                onRefresh: _loadTodayData,
                color: AppTheme.primaryGreen,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Date header ──
                      _buildDateHeader(theme),
                      const SizedBox(height: 16),

                      // ── Next prayer widget ──
                      const NextPrayerWidget(),
                      const SizedBox(height: 16),

                      // ── Prayer times ──
                      PrayerTimesWidget(
                        fajrDone: _todayWorship['prayer_fajr'] == 1,
                        dhuhrDone: _todayWorship['prayer_dhuhr'] == 1,
                        asrDone: _todayWorship['prayer_asr'] == 1,
                        maghribDone: _todayWorship['prayer_maghrib'] == 1,
                        ishaDone: _todayWorship['prayer_isha'] == 1,
                        onToggle: (prayer, val) {
                          _toggleWorship('prayer_$prayer', val);
                        },
                        onSurveyTap: (prayer) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SurveyScreen(
                                prayerName: prayer,
                                date: _todayDate,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Other worship cards ──
                      _buildSectionTitle('عبادات أخرى', theme),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: WorshipCard(
                              icon: '🌙',
                              title: 'الصوم',
                              subtitle: 'هل صمت اليوم؟',
                              isChecked: _todayWorship['fasting'] == 1,
                              onChanged: (val) =>
                                  _toggleWorship('fasting', val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: WorshipCard(
                              icon: '💰',
                              title: 'الزكاة',
                              subtitle: 'هل أديت الزكاة؟',
                              isChecked: _todayWorship['zakat_reminder'] == 1,
                              onChanged: (val) =>
                                  _toggleWorship('zakat_reminder', val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      WorshipCard(
                        icon: '🤝',
                        title: 'صلة الرحم',
                        subtitle: 'هل تواصلت مع أهلك وأقاربك اليوم؟',
                        isChecked: _todayWorship['family_ties'] == 1,
                        onChanged: (val) =>
                            _toggleWorship('family_ties', val),
                        isFullWidth: true,
                      ),

                      const SizedBox(height: 24),
                      // ── Daily progress ──
                      _buildDailyProgress(theme),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Amiri',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
            style: TextStyle(
              color: AppTheme.accentGold,
              fontSize: 18,
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _displayDate(DateTime.now()),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Amiri',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Row(
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
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyProgress(ThemeData theme) {
    int total = 9; // 5 prayers + fasting + zakat + family + dhikr
    int completed = 0;

    if (_todayWorship['prayer_fajr'] == 1) completed++;
    if (_todayWorship['prayer_dhuhr'] == 1) completed++;
    if (_todayWorship['prayer_asr'] == 1) completed++;
    if (_todayWorship['prayer_maghrib'] == 1) completed++;
    if (_todayWorship['prayer_isha'] == 1) completed++;
    if (_todayWorship['fasting'] == 1) completed++;
    if (_todayWorship['zakat_reminder'] == 1) completed++;
    if (_todayWorship['family_ties'] == 1) completed++;

    final progress = total > 0 ? completed / total : 0.0;
    final percent = (progress * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('تقدم اليوم',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: AppTheme.primaryGreen)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _progressColor(progress).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$percent%',
                    style: TextStyle(
                      color: _progressColor(progress),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    AlwaysStoppedAnimation<Color>(_progressColor(progress)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$completed من $total عبادة مكتملة',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _progressColor(double progress) {
    if (progress >= 0.8) return AppTheme.primaryGreen;
    if (progress >= 0.5) return Colors.orange.shade600;
    return Colors.red.shade400;
  }
}
