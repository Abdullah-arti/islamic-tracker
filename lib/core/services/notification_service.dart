// lib/core/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../database/database_helper.dart';
import 'prayer_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Notification ID ranges ────────────────────────────────────────────────
  // 101–105: Pre-prayer reminders (fajr, dhuhr, asr, maghrib, isha)
  // 201–205: Post-prayer surveys
  // 301: Monday fasting reminder (Sunday 8pm)
  // 302: Thursday fasting reminder (Wed 8pm)
  // 303: Daily family ties reminder (8am)
  // 304: Monthly zakat reminder (1st of month)
  // 400+: Islamic special days

  Future<void> initialize() async {
    if (_initialized) return;

    // Set timezone
    final String timezoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Navigation handled by app
    debugPrint('Notification tapped: ${response.id} / ${response.payload}');
  }

  // ─── Notification details ─────────────────────────────────────────────────

  NotificationDetails _buildDetails({
    String channelId = 'islamic_tracker',
    String channelName = 'تتبع العبادات',
    String channelDesc = 'إشعارات تتبع العبادات اليومية',
    Importance importance = Importance.high,
    Priority priority = Priority.high,
    bool playSound = true,
    String? sound,
  }) {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: importance,
      priority: priority,
      playSound: playSound,
      sound: sound != null
          ? RawResourceAndroidNotificationSound(sound)
          : const DefaultAndroidNotificationSound(),
      styleInformation: const BigTextStyleInformation(''),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: const Color(0xFF1B5E20),
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  // ─── Schedule all notifications ───────────────────────────────────────────

  Future<void> scheduleAllNotifications() async {
    final enabled =
        await DatabaseHelper.instance.getSetting('notifications_enabled');
    if (enabled == '0') return;

    await cancelAll();

    await _schedulePrayerReminders();
    await _scheduleFastingReminders();
    await _scheduleFamilyTiesReminder();
    await _scheduleZakatReminder();
    await _scheduleIslamicSpecialDays();
    await _schedulePrayerSurveys();
  }

  // ─── 1. Prayer reminders (10 min before each prayer) ─────────────────────

  Future<void> _schedulePrayerReminders() async {
    final prayerEnabled =
        await DatabaseHelper.instance.getSetting('prayer_enabled');
    if (prayerEnabled == '0') return;

    // Schedule for today and tomorrow
    for (int dayOffset = 0; dayOffset <= 6; dayOffset++) {
      final date = DateTime.now().add(Duration(days: dayOffset));
      final prayers = await PrayerService.instance.getPrayerTimesForDate(date);

      for (final prayer in prayers) {
        final reminderTime =
            prayer.time.subtract(const Duration(minutes: 10));
        if (reminderTime.isAfter(DateTime.now())) {
          final notifId = prayer.notificationId + (dayOffset * 10);
          await _scheduleOnce(
            id: notifId,
            title: '🕌 وقت الصلاة يقترب',
            body: '${prayer.arabicName} بعد قليل .. استعد',
            scheduledTime: reminderTime,
            payload: 'prayer_reminder:${prayer.name}',
          );
        }
      }
    }
  }

  // ─── 2. Post-prayer surveys (1 hour after prayer) ─────────────────────────

  Future<void> _schedulePrayerSurveys() async {
    final surveyEnabled =
        await DatabaseHelper.instance.getSetting('survey_enabled');
    if (surveyEnabled == '0') return;

    for (int dayOffset = 0; dayOffset <= 6; dayOffset++) {
      final date = DateTime.now().add(Duration(days: dayOffset));
      final prayers = await PrayerService.instance.getPrayerTimesForDate(date);

      for (final prayer in prayers) {
        final surveyTime = prayer.time.add(const Duration(hours: 1));
        if (surveyTime.isAfter(DateTime.now())) {
          final notifId = 200 + prayers.indexOf(prayer) + 1 + (dayOffset * 10);
          await _scheduleOnce(
            id: notifId,
            title: '📋 استبيان ما بعد الصلاة',
            body: 'هل أكملت عباداتك بعد صلاة ${prayer.arabicName}؟',
            scheduledTime: surveyTime,
            payload: 'prayer_survey:${prayer.name}:${_dateStr(date)}',
            channelId: 'surveys',
            channelName: 'الاستبيانات',
          );
        }
      }
    }
  }

  // ─── 3. Fasting reminders ─────────────────────────────────────────────────

  Future<void> _scheduleFastingReminders() async {
    final fastingEnabled =
        await DatabaseHelper.instance.getSetting('fasting_enabled');
    if (fastingEnabled == '0') return;

    // Schedule for next 8 weeks
    for (int week = 0; week < 8; week++) {
      // Sunday 8pm → Monday fasting reminder
      final nextSunday = _nextWeekday(DateTime.sunday, week);
      final sundayEvening =
          DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 20, 0);
      if (sundayEvening.isAfter(DateTime.now())) {
        await _scheduleOnce(
          id: 301 + week,
          title: '🌙 تذكير الصيام',
          body: 'لا تنسَ صوم يوم الاثنين',
          scheduledTime: sundayEvening,
          payload: 'fasting:monday',
          channelId: 'fasting',
          channelName: 'تذكيرات الصيام',
        );
      }

      // Wednesday 8pm → Thursday fasting reminder
      final nextWednesday = _nextWeekday(DateTime.wednesday, week);
      final wednesdayEvening = DateTime(
          nextWednesday.year, nextWednesday.month, nextWednesday.day, 20, 0);
      if (wednesdayEvening.isAfter(DateTime.now())) {
        await _scheduleOnce(
          id: 351 + week,
          title: '🌙 تذكير الصيام',
          body: 'لا تنسَ صوم يوم الخميس',
          scheduledTime: wednesdayEvening,
          payload: 'fasting:thursday',
          channelId: 'fasting',
          channelName: 'تذكيرات الصيام',
        );
      }
    }
  }

  // ─── 4. Family ties daily reminder (8am) ─────────────────────────────────

  Future<void> _scheduleFamilyTiesReminder() async {
    final familyEnabled =
        await DatabaseHelper.instance.getSetting('family_ties_enabled');
    if (familyEnabled == '0') return;

    // Schedule for next 30 days
    for (int day = 0; day < 30; day++) {
      final date = DateTime.now().add(Duration(days: day));
      final reminderTime = DateTime(date.year, date.month, date.day, 8, 0);
      if (reminderTime.isAfter(DateTime.now())) {
        await _scheduleOnce(
          id: 400 + day,
          title: '🤝 صلة الرحم',
          body: 'لا تنسَ صلة الرحم اليوم',
          scheduledTime: reminderTime,
          payload: 'family_ties',
          channelId: 'family',
          channelName: 'صلة الرحم',
        );
      }
    }
  }

  // ─── 5. Monthly Zakat reminder (1st of month) ─────────────────────────────

  Future<void> _scheduleZakatReminder() async {
    final zakatEnabled =
        await DatabaseHelper.instance.getSetting('zakat_enabled');
    if (zakatEnabled == '0') return;

    for (int month = 0; month < 12; month++) {
      final now = DateTime.now();
      final targetMonth = (now.month + month - 1) % 12 + 1;
      final targetYear = now.year + ((now.month + month - 1) ~/ 12);
      final reminderTime = DateTime(targetYear, targetMonth, 1, 9, 0);
      if (reminderTime.isAfter(DateTime.now())) {
        await _scheduleOnce(
          id: 500 + month,
          title: '💰 تذكير الزكاة',
          body: 'لا تنسَ الزكاة هذا الشهر',
          scheduledTime: reminderTime,
          payload: 'zakat',
          channelId: 'zakat',
          channelName: 'الزكاة',
        );
      }
    }
  }

  // ─── 6. Islamic special days ──────────────────────────────────────────────

  Future<void> _scheduleIslamicSpecialDays() async {
    final now = DateTime.now();
    final currentYear = now.year;

    // Special days with approximate Gregorian dates for 2025-2026
    // Each reminder is sent the NIGHT BEFORE at 9pm
    final List<Map<String, dynamic>> specialDays = [
      // Ayyam al-Bid (White Days): 13th, 14th, 15th of each Hijri month
      // Approximately scheduled - app should use proper Hijri conversion
      // For now: approximate monthly white days
      ..._generateWhiteDays(currentYear),
      ..._generateWhiteDays(currentYear + 1),

      // Day of Arafah (9 Dhul-Hijja) - 2025: June 5
      {
        'name': '🕋 يوم عرفة',
        'body': 'غداً يوم عرفة المبارك — لا تنسَ الصيام',
        'date': DateTime(2025, 6, 5, 21, 0),
        'id': 601,
      },
      // Ashura (10 Muharram) - 2025: July 6
      {
        'name': '📅 يوم عاشوراء',
        'body': 'غداً يوم عاشوراء — لا تنسَ صيام التاسع والعاشر',
        'date': DateTime(2025, 7, 5, 21, 0),
        'id': 602,
      },
      // 9th Muharram reminder
      {
        'name': '📅 تاسوعاء',
        'body': 'غداً يوم التاسع من محرم — يُسن صيامه مع العاشر',
        'date': DateTime(2025, 7, 4, 21, 0),
        'id': 603,
      },
      // Arafah 2026
      {
        'name': '🕋 يوم عرفة',
        'body': 'غداً يوم عرفة المبارك — لا تنسَ الصيام',
        'date': DateTime(2026, 5, 26, 21, 0),
        'id': 611,
      },
      // Ramadan start reminder (2025: Feb 28 / 2026: Feb 17 approx)
      {
        'name': '🌙 استقبال رمضان',
        'body': 'غداً أول أيام شهر رمضان المبارك — رمضان كريم 🌙',
        'date': DateTime(2025, 2, 28, 21, 0),
        'id': 620,
      },
      {
        'name': '🌙 استقبال رمضان',
        'body': 'غداً أول أيام شهر رمضان المبارك — رمضان كريم 🌙',
        'date': DateTime(2026, 2, 17, 21, 0),
        'id': 621,
      },
      // Last 10 nights of Ramadan
      {
        'name': '✨ العشر الأواخر',
        'body': 'تبدأ الليلة العشر الأواخر من رمضان — أحيِ لياليها بالعبادة',
        'date': DateTime(2025, 3, 21, 21, 0),
        'id': 630,
      },
      // Laylat al-Qadr estimate (27th Ramadan)
      {
        'name': '⭐ ليلة القدر المرتقبة',
        'body': 'الليلة هي ليلة السابع والعشرين من رمضان — أحيِها بالدعاء والذكر',
        'date': DateTime(2025, 3, 27, 20, 0),
        'id': 640,
      },
      // Shawwal 6 fasting (6 days after Eid)
      {
        'name': '🌟 صيام ست من شوال',
        'body': 'لا تنسَ صيام الست من شوال — كمن صام الدهر كله',
        'date': DateTime(2025, 4, 1, 8, 0),
        'id': 650,
      },
      {
        'name': '🌟 صيام ست من شوال',
        'body': 'لا تنسَ صيام الست من شوال — كمن صام الدهر كله',
        'date': DateTime(2026, 3, 22, 8, 0),
        'id': 651,
      },
    ];

    for (final day in specialDays) {
      final DateTime dt = day['date'] as DateTime;
      if (dt.isAfter(now)) {
        await _scheduleOnce(
          id: day['id'] as int,
          title: day['name'] as String,
          body: day['body'] as String,
          scheduledTime: dt,
          payload: 'islamic_event',
          channelId: 'islamic_events',
          channelName: 'المناسبات الإسلامية',
        );
      }
    }
  }

  // Generate white days reminders (13, 14, 15 of each Hijri month)
  // Approximated as every ~29.5 days from a known white day
  List<Map<String, dynamic>> _generateWhiteDays(int year) {
    final List<Map<String, dynamic>> days = [];
    // Approximate: first white day of Jan 2025 = Jan 13
    // Then repeat every ~30 days for each month
    for (int month = 1; month <= 12; month++) {
      // Approximate 13th of Hijri ≈ mid of Gregorian month
      final approxDate = DateTime(year, month, 13, 21, 0);
      if (approxDate.isAfter(DateTime.now())) {
        days.add({
          'name': '⚪ أيام البيض',
          'body':
              'غداً الثالث عشر من الشهر — أيام البيض (13، 14، 15) يُسن صيامها',
          'date': approxDate,
          'id': 700 + (year - 2025) * 12 + month,
        });
      }
    }
    return days;
  }

  // ─── Core scheduling helper ───────────────────────────────────────────────

  Future<void> _scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String channelId = 'islamic_tracker',
    String channelName = 'تتبع العبادات',
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        _buildDetails(channelId: channelId, channelName: channelName),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error scheduling notification $id: $e');
    }
  }

  // ─── Utilities ────────────────────────────────────────────────────────────

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> cancelById(int id) async {
    await _plugin.cancel(id);
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  DateTime _nextWeekday(int weekday, int weekOffset) {
    final now = DateTime.now();
    int daysUntil = (weekday - now.weekday) % 7;
    if (daysUntil == 0 && weekOffset == 0) daysUntil = 7;
    return now.add(Duration(days: daysUntil + weekOffset * 7));
  }

  String _dateStr(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
