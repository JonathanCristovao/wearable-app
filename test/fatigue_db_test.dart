import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:aiwearable/models/activity_record.dart';
import 'package:aiwearable/services/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<Database> _openOldV6Db() async {
    final path = p.join(await getDatabasesPath(), 'activities.db');
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 6,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE activities (
              id TEXT PRIMARY KEY,
              type TEXT NOT NULL,
              environment TEXT NOT NULL,
              startTime TEXT NOT NULL,
              endTime TEXT NOT NULL,
              duration INTEGER NOT NULL,
              userId TEXT,
              userName TEXT,
              emoji TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE data_points (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              activityId TEXT NOT NULL,
              timestamp TEXT NOT NULL,
              sensorsData TEXT NOT NULL,
              phoneSensorsData TEXT,
              FOREIGN KEY (activityId) REFERENCES activities (id) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE custom_activity_types (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              emoji TEXT NOT NULL,
              sensorsJson TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE users (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              age INTEGER,
              weight REAL,
              height REAL,
              injury TEXT,
              activityFrequency TEXT,
              disease TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE settings (
              key TEXT PRIMARY KEY,
              value TEXT
            )
          ''');
        },
      ),
    );
  }

  test('fatigue level survives v6 -> v7 migration', () async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    // Create DB with OLD v6 schema (no fatigueLevel column)
    final db = await _openOldV6Db();
    await db.insert('activities', {
      'id': 'test-old-$stamp',
      'type': 'walking',
      'environment': 'outdoor',
      'startTime': DateTime.now().toIso8601String(),
      'endTime': DateTime.now().toIso8601String(),
      'duration': 2,
    });
    await db.insert('data_points', {
      'activityId': 'test-old-$stamp',
      'timestamp': DateTime.now().toIso8601String(),
      'sensorsData': '{}',
    });
    await db.close();

    // Opening through DatabaseHelper (version 7) should run the migration
    final loaded = await DatabaseHelper.instance.getActivity('test-old-$stamp');
    expect(loaded, isNotNull);
    expect(loaded!.dataPoints.length, 1);
    expect(loaded.dataPoints[0].fatigueLevel, isNull);

    // Save a new record with fatigue level after migration
    final now = DateTime.now();
    final record = ActivityRecord(
      id: 'test-new-$stamp',
      type: 'walking',
      environment: 'outdoor',
      startTime: now,
      endTime: now.add(const Duration(seconds: 2)),
      duration: const Duration(seconds: 2),
      dataPoints: [
        ActivityDataPoint(timestamp: now, sensors: {}, fatigueLevel: 4),
      ],
    );
    await DatabaseHelper.instance.saveActivity(record);
    final loadedNew =
        await DatabaseHelper.instance.getActivity('test-new-$stamp');
    expect(loadedNew!.dataPoints[0].fatigueLevel, 4);

    await DatabaseHelper.instance.deleteActivity('test-old-$stamp');
    await DatabaseHelper.instance.deleteActivity('test-new-$stamp');
  });

  test('fatigue level survives save and load (fresh schema)', () async {
    final now = DateTime.now();
    final record = ActivityRecord(
      id: 'test-fresh-${now.millisecondsSinceEpoch}',
      type: 'walking',
      environment: 'outdoor',
      startTime: now,
      endTime: now.add(const Duration(seconds: 2)),
      duration: const Duration(seconds: 2),
      dataPoints: [
        ActivityDataPoint(timestamp: now, sensors: {}, fatigueLevel: 2),
        ActivityDataPoint(
          timestamp: now.add(const Duration(seconds: 1)),
          sensors: {},
        ),
      ],
    );

    await DatabaseHelper.instance.saveActivity(record);

    final loaded =
        await DatabaseHelper.instance.getActivity(record.id);
    expect(loaded, isNotNull);
    expect(loaded!.dataPoints[0].fatigueLevel, 2);
    expect(loaded.dataPoints[1].fatigueLevel, isNull);

    await DatabaseHelper.instance.deleteActivity(record.id);
  });
}
