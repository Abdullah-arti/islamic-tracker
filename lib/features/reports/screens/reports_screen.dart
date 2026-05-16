// lib/features/reports/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_theme.dart';

enum ReportPeriod { daily, monthly, yearly }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReportPeriod _period = ReportPeriod.daily;

  List<Map<String, dynamic>> _worshipData = [];
  List<Map<String, dynamic>> _surveyData = [];
  bool _loading = true;

  // For date navigation
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsScrolling) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _period = ReportPeriod.daily;
              break;
            case 1:
              _period = ReportPeriod.monthly;
              break;
            case 2:
              _period = ReportPeriod.yearly;
              break;
          }
        });
        _loadData();
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final db = DatabaseHelper.instance;

    String startDate, endDate;

    switch (_period) {
      case ReportPeriod.daily:
        startDate = _fmt(_selectedDate);
        endDate = startDate;
        break;
      case ReportPeriod.monthly:
        startDate = _fmt(DateTime(_selectedMonth.year, _selectedMonth.month, 1));
        endDate = _fmt(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));
        break;
      case ReportPeriod.yearly:
        startDate = '$_selectedYear-01-01';
        endDate = '$_selectedYear-12-31';
        break;
    }

    final worship = await db.getWorshipByDateRange(startDate, endDate);
    final surveys = await db.getSurveysByDateRange(startDate, endDate);

    if (mounted) {
      setState(() {
        _worshipData = worship;
        _surveyData = surveys;
        _loading = false;
      });
    }
  }

  // ─── Aggregation helpers ─────────────────────────────────────────────────

  Map<String, int> get _worshipTotals {
    final totals = {
      'prayer_fajr': 0,
      'prayer_dhuhr': 0,
      'prayer_asr': 0,
      'prayer_maghrib': 0,
      'prayer_isha': 0,
      'fasting': 0,
      'zakat_reminder': 0,
      'family_ties': 0,
    };
    for (final row in _worshipData) {
      for (final key in totals.keys) {
        if (row[key] == 1) totals[key] = (totals[key] ?? 0) + 1;
      }
    }
    return totals;
  }

  Map<String, Map<String, int>> get _surveyTotals {
    final totals = <String, Map<String, int>>{};
    for (final row in _surveyData) {
      final prayer = row['prayer_name'] as String;
      totals.putIfAbsent(prayer, () => {
            'mosque': 0,
            'dhikr': 0,
            'sunnah': 0,
            'quran': 0,
            'total': 0,
          });
      totals[prayer]!['total'] = (totals[prayer]!['total'] ?? 0) + 1;
      if (row['prayed_in_mosque'] == 1)
        totals[prayer]!['mosque'] = (totals[prayer]!['mosque'] ?? 0) + 1;
      if (row['did_dhikr'] == 1)
        totals[prayer]!['dhikr'] = (totals[prayer]!['dhikr'] ?? 0) + 1;
      if (row['prayed_sunnah'] == 1)
        totals[prayer]!['sunnah'] = (totals[prayer]!['sunnah'] ?? 0) + 1;
      if (row['read_quran'] == 1)
        totals[prayer]!['quran'] = (totals[prayer]!['quran'] ?? 0) + 1;
    }
    return totals;
  }

  int get _totalDays => _worshipData.length;

  double _pct(int count, int total) {
    if (total == 0) return 0.0;
    return (count / total * 100).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: const Text('التقارير'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: AppTheme.accentGold,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontFamily: 'Amiri', fontSize: 15),
            tabs: const [
              Tab(text: 'يومي'),
              Tab(text: 'شهري'),
              Tab(text: 'سنوي'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Date navigator
            _buildDateNavigator(theme),
            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _worshipData.isEmpty && _surveyData.isEmpty
                      ? _buildEmptyState()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildWorshipSummary(theme),
                              const SizedBox(height: 16),
                              if (_period != ReportPeriod.daily)
                                _buildPrayerChart(theme),
                              if (_period != ReportPeriod.daily)
                                const SizedBox(height: 16),
                              _buildSurveyReport(theme),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Date navigator ───────────────────────────────────────────────────────

  Widget _buildDateNavigator(ThemeData theme) {
    String label;
    switch (_period) {
      case ReportPeriod.daily:
        label = DateFormat('EEEE، d MMMM yyyy', 'ar').format(_selectedDate);
        break;
      case ReportPeriod.monthly:
        label = DateFormat('MMMM yyyy', 'ar').format(_selectedMonth);
        break;
      case ReportPeriod.yearly:
        label = '$_selectedYear';
        break;
    }

    return Container(
      color: AppTheme.primaryGreen.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppTheme.primaryGreen),
            onPressed: _goBack,
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppTheme.primaryGreen),
            onPressed: _goForward,
          ),
        ],
      ),
    );
  }

  void _goBack() {
    setState(() {
      switch (_period) {
        case ReportPeriod.daily:
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
          break;
        case ReportPeriod.monthly:
          _selectedMonth =
              DateTime(_selectedMonth.year, _selectedMonth.month - 1);
          break;
        case ReportPeriod.yearly:
          _selectedYear--;
          break;
      }
    });
    _loadData();
  }

  void _goForward() {
    setState(() {
      switch (_period) {
        case ReportPeriod.daily:
          if (_selectedDate.isBefore(DateTime.now())) {
            _selectedDate = _selectedDate.add(const Duration(days: 1));
          }
          break;
        case ReportPeriod.monthly:
          final next =
              DateTime(_selectedMonth.year, _selectedMonth.month + 1);
          if (next.isBefore(DateTime.now())) _selectedMonth = next;
          break;
        case ReportPeriod.yearly:
          if (_selectedYear < DateTime.now().year) _selectedYear++;
          break;
      }
    });
    _loadData();
  }

  // ─── Worship summary ──────────────────────────────────────────────────────

  Widget _buildWorshipSummary(ThemeData theme) {
    final totals = _worshipTotals;
    final days = _totalDays == 0 ? 1 : _totalDays;

    final items = [
      {'label': 'الفجر', 'emoji': '🌅', 'key': 'prayer_fajr'},
      {'label': 'الظهر', 'emoji': '☀️', 'key': 'prayer_dhuhr'},
      {'label': 'العصر', 'emoji': '🌤️', 'key': 'prayer_asr'},
      {'label': 'المغرب', 'emoji': '🌆', 'key': 'prayer_maghrib'},
      {'label': 'العشاء', 'emoji': '🌙', 'key': 'prayer_isha'},
      {'label': 'الصوم', 'emoji': '🌙', 'key': 'fasting'},
      {'label': 'الزكاة', 'emoji': '💰', 'key': 'zakat_reminder'},
      {'label': 'صلة الرحم', 'emoji': '🤝', 'key': 'family_ties'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 ملخص العبادات',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_period != ReportPeriod.daily) ...[
              const SizedBox(height: 4),
              Text(
                'إجمالي الأيام المسجلة: $_totalDays',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 14),
            ...items.map((item) {
              final count = totals[item['key'] as String] ?? 0;
              final pct = _period == ReportPeriod.daily
                  ? (count == 1 ? 100.0 : 0.0)
                  : _pct(count, days);
              return _buildProgressRow(
                emoji: item['emoji'] as String,
                label: item['label'] as String,
                count: count,
                total: _period == ReportPeriod.daily ? 1 : days,
                percent: pct,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow({
    required String emoji,
    required String label,
    required int count,
    required int total,
    required double percent,
  }) {
    final color = percent >= 80
        ? AppTheme.primaryGreen
        : percent >= 50
            ? Colors.orange.shade600
            : Colors.red.shade400;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontFamily: 'Amiri', fontSize: 15),
                ),
              ),
              Text(
                _period == ReportPeriod.daily
                    ? (count == 1 ? '✅' : '❌')
                    : '$count/$total',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percent.round()}%',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Prayer chart (monthly/yearly) ───────────────────────────────────────

  Widget _buildPrayerChart(ThemeData theme) {
    final totals = _worshipTotals;
    final days = _totalDays == 0 ? 1 : _totalDays;

    final prayers = [
      {'label': 'فجر', 'key': 'prayer_fajr'},
      {'label': 'ظهر', 'key': 'prayer_dhuhr'},
      {'label': 'عصر', 'key': 'prayer_asr'},
      {'label': 'مغرب', 'key': 'prayer_maghrib'},
      {'label': 'عشاء', 'key': 'prayer_isha'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📈 معدل الالتزام بالصلوات',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barGroups: prayers.asMap().entries.map((e) {
                    final count = totals[e.value['key']!] ?? 0;
                    final pct = _pct(count, days);
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: pct,
                          color: pct >= 80
                              ? AppTheme.primaryGreen
                              : pct >= 50
                                  ? Colors.orange.shade400
                                  : Colors.red.shade400,
                          width: 28,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) {
                          final label =
                              prayers[val.toInt()]['label'] as String;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Survey report ────────────────────────────────────────────────────────

  Widget _buildSurveyReport(ThemeData theme) {
    final surveys = _surveyTotals;
    if (surveys.isEmpty) return const SizedBox.shrink();

    final prayers = [
      {'name': 'fajr', 'label': 'الفجر', 'emoji': '🌅'},
      {'name': 'dhuhr', 'label': 'الظهر', 'emoji': '☀️'},
      {'name': 'asr', 'label': 'العصر', 'emoji': '🌤️'},
      {'name': 'maghrib', 'label': 'المغرب', 'emoji': '🌆'},
      {'name': 'isha', 'label': 'العشاء', 'emoji': '🌙'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 تقارير الاستبيانات',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            ...prayers.where((p) => surveys.containsKey(p['name']!)).map((p) {
              final data = surveys[p['name']!]!;
              final total = data['total']! == 0 ? 1 : data['total']!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(p['emoji']!, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'صلاة ${p['label']!}',
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildSurveyItem(
                      '🕌', 'صلاة المسجد', data['mosque']!, total),
                  _buildSurveyItem('📿', 'الذكر', data['dhikr']!, total),
                  _buildSurveyItem('🙏', 'السنة', data['sunnah']!, total),
                  _buildSurveyItem('📖', 'القرآن', data['quran']!, total),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyItem(
      String emoji, String label, int count, int total) {
    final pct = _pct(count, total);
    final color = pct >= 80
        ? AppTheme.primaryGreen
        : pct >= 50
            ? Colors.orange.shade600
            : Colors.red.shade400;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 14),
            ),
          ),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${pct.round()}%',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'لا توجد بيانات لهذه الفترة',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بتسجيل عباداتك من الشاشة الرئيسية',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 15,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
