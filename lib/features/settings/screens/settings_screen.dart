// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _prayerEnabled = true;
  bool _fastingEnabled = true;
  bool _zakatEnabled = true;
  bool _familyTiesEnabled = true;
  bool _notificationsEnabled = true;
  bool _surveyEnabled = true;

  String _city = 'القاهرة';
  final TextEditingController _latController =
      TextEditingController(text: '30.0444');
  final TextEditingController _lngController =
      TextEditingController(text: '31.2357');
  final TextEditingController _cityController =
      TextEditingController(text: 'القاهرة');

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = DatabaseHelper.instance;
    final prayer = await db.getSetting('prayer_enabled');
    final fasting = await db.getSetting('fasting_enabled');
    final zakat = await db.getSetting('zakat_enabled');
    final family = await db.getSetting('family_ties_enabled');
    final notifs = await db.getSetting('notifications_enabled');
    final survey = await db.getSetting('survey_enabled');
    final lat = await db.getSetting('latitude');
    final lng = await db.getSetting('longitude');
    final city = await db.getSetting('city');

    if (mounted) {
      setState(() {
        _prayerEnabled = prayer != '0';
        _fastingEnabled = fasting != '0';
        _zakatEnabled = zakat != '0';
        _familyTiesEnabled = family != '0';
        _notificationsEnabled = notifs != '0';
        _surveyEnabled = survey != '0';
        if (lat != null) _latController.text = lat;
        if (lng != null) _lngController.text = lng;
        if (city != null) {
          _city = city;
          _cityController.text = city;
        }
        _loading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    await DatabaseHelper.instance.setSetting(key, value ? '1' : '0');
    // Reschedule notifications
    await NotificationService.instance.scheduleAllNotifications();
  }

  Future<void> _saveLocation() async {
    final db = DatabaseHelper.instance;
    await db.setSetting('latitude', _latController.text.trim());
    await db.setSetting('longitude', _lngController.text.trim());
    await db.setSetting('city', _cityController.text.trim());
    await NotificationService.instance.scheduleAllNotifications();

    if (mounted) {
      setState(() => _city = _cityController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ تم حفظ الموقع وإعادة جدولة الإشعارات',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Amiri', fontSize: 15)),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: const Text('الإعدادات'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Worship toggles ──
                    _buildSectionHeader('🕌 العبادات', theme),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          _buildWorshipTile(
                            emoji: '🙏',
                            title: 'الصلاة',
                            subtitle: 'تتبع الصلوات الخمس وتذكيراتها',
                            value: _prayerEnabled,
                            onChanged: (val) {
                              setState(() => _prayerEnabled = val);
                              _saveSetting('prayer_enabled', val);
                            },
                          ),
                          const Divider(height: 1, indent: 16),
                          _buildWorshipTile(
                            emoji: '🌙',
                            title: 'الصوم',
                            subtitle: 'تذكير بصوم الاثنين والخميس',
                            value: _fastingEnabled,
                            onChanged: (val) {
                              setState(() => _fastingEnabled = val);
                              _saveSetting('fasting_enabled', val);
                            },
                          ),
                          const Divider(height: 1, indent: 16),
                          _buildWorshipTile(
                            emoji: '💰',
                            title: 'الزكاة',
                            subtitle: 'تذكير شهري بالزكاة',
                            value: _zakatEnabled,
                            onChanged: (val) {
                              setState(() => _zakatEnabled = val);
                              _saveSetting('zakat_enabled', val);
                            },
                          ),
                          const Divider(height: 1, indent: 16),
                          _buildWorshipTile(
                            emoji: '🤝',
                            title: 'صلة الرحم',
                            subtitle: 'تذكير يومي صباحي',
                            value: _familyTiesEnabled,
                            onChanged: (val) {
                              setState(() => _familyTiesEnabled = val);
                              _saveSetting('family_ties_enabled', val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Notifications ──
                    _buildSectionHeader('🔔 الإشعارات والاستبيانات', theme),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          _buildWorshipTile(
                            emoji: '🔔',
                            title: 'الإشعارات',
                            subtitle: 'تفعيل/تعطيل جميع الإشعارات',
                            value: _notificationsEnabled,
                            onChanged: (val) {
                              setState(() => _notificationsEnabled = val);
                              _saveSetting('notifications_enabled', val);
                            },
                          ),
                          const Divider(height: 1, indent: 16),
                          _buildWorshipTile(
                            emoji: '📋',
                            title: 'استبيانات ما بعد الصلاة',
                            subtitle: 'تذكير بالاستبيان بعد ساعة من كل صلاة',
                            value: _surveyEnabled,
                            onChanged: (val) {
                              setState(() => _surveyEnabled = val);
                              _saveSetting('survey_enabled', val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Location ──
                    _buildSectionHeader('📍 الموقع (لمواقيت الصلاة)', theme),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المدينة الحالية: $_city',
                              style: const TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 15,
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _cityController,
                              textDirection: TextDirection.rtl,
                              decoration: _inputDecoration('اسم المدينة', '📍'),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _latController,
                                    keyboardType: TextInputType.number,
                                    textDirection: TextDirection.ltr,
                                    decoration:
                                        _inputDecoration('خط العرض', '🌐'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _lngController,
                                    keyboardType: TextInputType.number,
                                    textDirection: TextDirection.ltr,
                                    decoration:
                                        _inputDecoration('خط الطول', '🗺️'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _saveLocation,
                                icon: const Icon(Icons.save),
                                label: const Text('حفظ الموقع'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '💡 يمكنك البحث عن إحداثيات مدينتك على Google Maps',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Preset cities ──
                    _buildSectionHeader('🏙️ مدن سريعة', theme),
                    const SizedBox(height: 8),
                    _buildPresetCities(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
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
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWorshipTile({
    required String emoji,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 28)),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontFamily: 'Amiri', fontSize: 13),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryGreen,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String prefixText) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Amiri'),
      prefixIcon: Text(prefixText,
          style: const TextStyle(fontSize: 20),
          textAlign: TextAlign.center),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: AppTheme.primaryGreen, width: 2),
      ),
    );
  }

  Widget _buildPresetCities() {
    final cities = [
      {'name': 'القاهرة', 'lat': '30.0444', 'lng': '31.2357'},
      {'name': 'مكة المكرمة', 'lat': '21.3891', 'lng': '39.8579'},
      {'name': 'المدينة المنورة', 'lat': '24.5247', 'lng': '39.5692'},
      {'name': 'الرياض', 'lat': '24.7136', 'lng': '46.6753'},
      {'name': 'دبي', 'lat': '25.2048', 'lng': '55.2708'},
      {'name': 'بغداد', 'lat': '33.3152', 'lng': '44.3661'},
      {'name': 'الجزائر', 'lat': '36.7372', 'lng': '3.0865'},
      {'name': 'المغرب', 'lat': '33.9716', 'lng': '-6.8498'},
      {'name': 'إسطنبول', 'lat': '41.0082', 'lng': '28.9784'},
      {'name': 'لندن', 'lat': '51.5074', 'lng': '-0.1278'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cities
          .map(
            (city) => InkWell(
              onTap: () {
                setState(() {
                  _cityController.text = city['name']!;
                  _latController.text = city['lat']!;
                  _lngController.text = city['lng']!;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _cityController.text == city['name']
                      ? AppTheme.primaryGreen
                      : AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  city['name']!,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _cityController.text == city['name']
                        ? Colors.white
                        : AppTheme.primaryGreen,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
