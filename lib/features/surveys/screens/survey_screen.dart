// lib/features/surveys/screens/survey_screen.dart
import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_theme.dart';

class SurveyScreen extends StatefulWidget {
  final String prayerName;
  final String date;

  const SurveyScreen({
    super.key,
    required this.prayerName,
    required this.date,
  });

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  bool? _prayedInMosque;
  bool? _didDhikr;
  bool? _prayedSunnah;
  bool? _readQuran;
  bool _loading = true;
  bool _saved = false;

  String get _arabicPrayerName {
    switch (widget.prayerName) {
      case 'fajr':
        return 'الفجر';
      case 'dhuhr':
        return 'الظهر';
      case 'asr':
        return 'العصر';
      case 'maghrib':
        return 'المغرب';
      case 'isha':
        return 'العشاء';
      default:
        return widget.prayerName;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final data = await DatabaseHelper.instance
        .getPrayerSurvey(widget.date, widget.prayerName);
    if (data != null && mounted) {
      setState(() {
        _prayedInMosque = data['prayed_in_mosque'] == 1
            ? true
            : data['prayed_in_mosque'] == 0
                ? false
                : null;
        _didDhikr = data['did_dhikr'] == 1
            ? true
            : data['did_dhikr'] == 0
                ? false
                : null;
        _prayedSunnah = data['prayed_sunnah'] == 1
            ? true
            : data['prayed_sunnah'] == 0
                ? false
                : null;
        _readQuran = data['read_quran'] == 1
            ? true
            : data['read_quran'] == 0
                ? false
                : null;
        _saved = data['completed_at'] != null;
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _saveSurvey() async {
    await DatabaseHelper.instance.upsertPrayerSurvey(
      widget.date,
      widget.prayerName,
      {
        'prayed_in_mosque': _prayedInMosque == true ? 1 : 0,
        'did_dhikr': _didDhikr == true ? 1 : 0,
        'prayed_sunnah': _prayedSunnah == true ? 1 : 0,
        'read_quran': _readQuran == true ? 1 : 0,
        'completed_at': DateTime.now().toIso8601String(),
      },
    );

    if (mounted) {
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '✅ تم حفظ الاستبيان بنجاح',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Amiri', fontSize: 16),
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: Text('استبيان صلاة $_arabicPrayerName'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Header card
                    _buildHeader(theme),
                    const SizedBox(height: 24),

                    // Questions
                    _buildQuestion(
                      emoji: '🕌',
                      question: 'هل صليت في المسجد؟',
                      value: _prayedInMosque,
                      onChanged: (val) =>
                          setState(() => _prayedInMosque = val),
                    ),
                    const SizedBox(height: 16),
                    _buildQuestion(
                      emoji: '📿',
                      question: 'هل ذكرت الله بعد الصلاة؟',
                      value: _didDhikr,
                      onChanged: (val) => setState(() => _didDhikr = val),
                    ),
                    const SizedBox(height: 16),
                    _buildQuestion(
                      emoji: '🙏',
                      question: 'هل أديت صلاة السنة؟',
                      value: _prayedSunnah,
                      onChanged: (val) => setState(() => _prayedSunnah = val),
                    ),
                    const SizedBox(height: 16),
                    _buildQuestion(
                      emoji: '📖',
                      question: 'هل قرأت وردك من القرآن؟',
                      value: _readQuran,
                      onChanged: (val) => setState(() => _readQuran = val),
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: (_prayedInMosque == null ||
                                _didDhikr == null ||
                                _prayedSunnah == null ||
                                _readQuran == null)
                            ? null
                            : _saveSurvey,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_saved ? '✅ تم الحفظ' : 'حفظ الاستبيان'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'أجب على جميع الأسئلة لتتمكن من الحفظ',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontFamily: 'Amiri',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('📋', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'استبيان ما بعد الصلاة',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'صلاة $_arabicPrayerName',
                  style: const TextStyle(
                    color: AppTheme.accentGold,
                    fontFamily: 'Amiri',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion({
    required String emoji,
    required String question,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _AnswerButton(
                    label: 'نعم ✅',
                    isSelected: value == true,
                    isYes: true,
                    onTap: () => onChanged(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AnswerButton(
                    label: 'لا ❌',
                    isSelected: value == false,
                    isYes: false,
                    onTap: () => onChanged(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isYes;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.label,
    required this.isSelected,
    required this.isYes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = isYes ? AppTheme.primaryGreen : Colors.red.shade600;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? selectedColor : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? selectedColor : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
