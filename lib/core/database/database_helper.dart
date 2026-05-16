// lib/core/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('islamic_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Daily worship log
    await db.execute('''
      CREATE TABLE daily_worship (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        prayer_fajr INTEGER DEFAULT 0,
        prayer_dhuhr INTEGER DEFAULT 0,
        prayer_asr INTEGER DEFAULT 0,
        prayer_maghrib INTEGER DEFAULT 0,
        prayer_isha INTEGER DEFAULT 0,
        fasting INTEGER DEFAULT 0,
        zakat_reminder INTEGER DEFAULT 0,
        family_ties INTEGER DEFAULT 0,
        UNIQUE(date)
      )
    ''');

    // Post-prayer surveys (after each prayer)
    await db.execute('''
      CREATE TABLE prayer_surveys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        prayer_name TEXT NOT NULL,
        prayed_in_mosque INTEGER DEFAULT 0,
        did_dhikr INTEGER DEFAULT 0,
        prayed_sunnah INTEGER DEFAULT 0,
        read_quran INTEGER DEFAULT 0,
        completed_at TEXT,
        UNIQUE(date, prayer_name)
      )
    ''');

    // Settings
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Islamic events / special days
    await db.execute('''
      CREATE TABLE islamic_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        hijri_month INTEGER,
        hijri_day INTEGER,
        gregorian_date TEXT,
        description TEXT,
        notification_sent INTEGER DEFAULT 0
      )
    ''');

    // Insert default settings
    await db.insert('settings', {'key': 'prayer_enabled', 'value': '1'});
    await db.insert('settings', {'key': 'fasting_enabled', 'value': '1'});
    await db.insert('settings', {'key': 'zakat_enabled', 'value': '1'});
    await db.insert('settings', {'key': 'family_ties_enabled', 'value': '1'});
    await db.insert('settings', {'key': 'latitude', 'value': '30.0444'});
    await db.insert('settings', {'key': 'longitude', 'value': '31.2357'});
    await db.insert('settings', {'key': 'city', 'value': 'القاهرة'});
    await db.insert('settings', {'key': 'notifications_enabled', 'value': '1'});
    await db.insert('settings', {'key': 'survey_enabled', 'value': '1'});
  }

  // ─── Settings ─────────────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── Daily Worship ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getDailyWorship(String date) async {
    final db = await database;
    final result = await db.query(
      'daily_worship',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<void> upsertDailyWorship(
      String date, Map<String, dynamic> data) async {
    final db = await database;
    final existing = await getDailyWorship(date);
    if (existing == null) {
      await db.insert('daily_worship', {'date': date, ...data});
    } else {
      await db.update(
        'daily_worship',
        data,
        where: 'date = ?',
        whereArgs: [date],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getWorshipByDateRange(
      String startDate, String endDate) async {
    final db = await database;
    return await db.query(
      'daily_worship',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
  }

  // ─── Prayer Surveys ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getPrayerSurvey(
      String date, String prayerName) async {
    final db = await database;
    final result = await db.query(
      'prayer_surveys',
      where: 'date = ? AND prayer_name = ?',
      whereArgs: [date, prayerName],
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<void> upsertPrayerSurvey(
      String date, String prayerName, Map<String, dynamic> data) async {
    final db = await database;
    final existing = await getPrayerSurvey(date, prayerName);
    if (existing == null) {
      await db.insert('prayer_surveys', {
        'date': date,
        'prayer_name': prayerName,
        ...data,
      });
    } else {
      await db.update(
        'prayer_surveys',
        data,
        where: 'date = ? AND prayer_name = ?',
        whereArgs: [date, prayerName],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getSurveysByDateRange(
      String startDate, String endDate) async {
    final db = await database;
    return await db.query(
      'prayer_surveys',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllSurveys() async {
    final db = await database;
    return await db.query('prayer_surveys', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getAllWorship() async {
    final db = await database;
    return await db.query('daily_worship', orderBy: 'date DESC');
  }
}
