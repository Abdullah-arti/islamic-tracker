// lib/core/services/prayer_service.dart
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

class PrayerInfo {
  final String name;
  final String arabicName;
  final DateTime time;
  final int notificationId;

  PrayerInfo({
    required this.name,
    required this.arabicName,
    required this.time,
    required this.notificationId,
  });
}

class PrayerService {
  static final PrayerService instance = PrayerService._();
  PrayerService._();

  // Cairo coordinates default
  double _latitude = 30.0444;
  double _longitude = 31.2357;

  Future<void> loadCoordinates() async {
    final lat = await DatabaseHelper.instance.getSetting('latitude');
    final lng = await DatabaseHelper.instance.getSetting('longitude');
    if (lat != null) _latitude = double.tryParse(lat) ?? _latitude;
    if (lng != null) _longitude = double.tryParse(lng) ?? _longitude;
  }

  Future<List<PrayerInfo>> getPrayerTimesForDate(DateTime date) async {
    await loadCoordinates();

    final coordinates = Coordinates(_latitude, _longitude);
    final dateComponents = DateComponents.from(date);
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;

    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    return [
      PrayerInfo(
        name: 'fajr',
        arabicName: 'الفجر',
        time: prayerTimes.fajr.toLocal(),
        notificationId: 101,
      ),
      PrayerInfo(
        name: 'dhuhr',
        arabicName: 'الظهر',
        time: prayerTimes.dhuhr.toLocal(),
        notificationId: 102,
      ),
      PrayerInfo(
        name: 'asr',
        arabicName: 'العصر',
        time: prayerTimes.asr.toLocal(),
        notificationId: 103,
      ),
      PrayerInfo(
        name: 'maghrib',
        arabicName: 'المغرب',
        time: prayerTimes.maghrib.toLocal(),
        notificationId: 104,
      ),
      PrayerInfo(
        name: 'isha',
        arabicName: 'العشاء',
        time: prayerTimes.isha.toLocal(),
        notificationId: 105,
      ),
    ];
  }

  Future<List<PrayerInfo>> getTodayPrayers() async {
    return getPrayerTimesForDate(DateTime.now());
  }

  Future<PrayerInfo?> getNextPrayer() async {
    final prayers = await getTodayPrayers();
    final now = DateTime.now();
    for (final prayer in prayers) {
      if (prayer.time.isAfter(now)) return prayer;
    }
    // Return fajr of tomorrow
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowPrayers = await getPrayerTimesForDate(tomorrow);
    return tomorrowPrayers.first;
  }

  // Returns list of {prayer, surveyTime} for survey notifications
  Future<List<Map<String, dynamic>>> getPrayerSurveyTimes() async {
    final prayers = await getTodayPrayers();
    return prayers.map((p) {
      return {
        'prayer': p,
        'surveyTime': p.time.add(const Duration(hours: 1)),
      };
    }).toList();
  }
}
