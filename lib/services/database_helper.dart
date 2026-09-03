import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/activity_record.dart';
import '../models/phone_sensor_data.dart';
import '../models/user_profile.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('activities.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 8,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Table for activity records
    await db.execute('''
      CREATE TABLE activities (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        environment TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        duration INTEGER NOT NULL,
        userId TEXT,
        userName TEXT
      )
    ''');

    // Table for activity data points
    await db.execute('''
      CREATE TABLE data_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activityId TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        sensorsData TEXT NOT NULL,
        phoneSensorsData TEXT,
        fatigueLevel INTEGER,
        FOREIGN KEY (activityId) REFERENCES activities (id) ON DELETE CASCADE
      )
    ''');

    // Index for faster queries
    await db.execute('''
      CREATE INDEX idx_activity_id ON data_points(activityId)
    ''');

    // Table for custom activity types
    await db.execute('''
      CREATE TABLE custom_activity_types (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL,
        sensorsJson TEXT NOT NULL
      )
    ''');

    // Table for user profiles
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

    // Table for app settings (key-value)
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Table for trashed activities (recycle bin)
    await db.execute('''
      CREATE TABLE deleted_activities (
        id TEXT PRIMARY KEY,
        activityJson TEXT NOT NULL,
        deletedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE data_points ADD COLUMN phoneSensorsData TEXT',
      );
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_activity_types (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          emoji TEXT NOT NULL,
          sensorsJson TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE activities ADD COLUMN userId TEXT',
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
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
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE activities ADD COLUMN userName TEXT',
      );
    }
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE activities ADD COLUMN emoji TEXT',
      );
    }
    if (oldVersion < 7) {
      await db.execute(
        'ALTER TABLE data_points ADD COLUMN fatigueLevel INTEGER',
      );
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS deleted_activities (
          id TEXT PRIMARY KEY,
          activityJson TEXT NOT NULL,
          deletedAt TEXT NOT NULL
        )
      ''');
    }
  }

  // Save activity record
  Future<void> saveActivity(ActivityRecord record) async {
    final db = await database;

    // Save activity
    await db.insert('activities', {
      'id': record.id,
      'type': record.type,
      'environment': record.environment,
      'startTime': record.startTime.toIso8601String(),
      'endTime': record.endTime.toIso8601String(),
      'duration': record.duration.inSeconds,
      if (record.userId != null) 'userId': record.userId,
      if (record.userName != null) 'userName': record.userName,
      if (record.emoji != null) 'emoji': record.emoji,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Save data points
    final batch = db.batch();
    for (var dataPoint in record.dataPoints) {
      batch.insert('data_points', {
        'activityId': record.id,
        'timestamp': dataPoint.timestamp.toIso8601String(),
        'sensorsData': jsonEncode(_sensorSnapshotsToMap(dataPoint.sensors)),
        if (dataPoint.phoneSensors != null)
          'phoneSensorsData': jsonEncode(dataPoint.phoneSensors!.toJson()),
        if (dataPoint.fatigueLevel != null)
          'fatigueLevel': dataPoint.fatigueLevel,
      });
    }
    await batch.commit(noResult: true);
  }

  // Convert sensor snapshots to map for JSON storage
  Map<String, dynamic> _sensorSnapshotsToMap(
    Map<String, SensorSnapshot> sensors,
  ) {
    return sensors.map(
      (key, value) => MapEntry(key, {
        'accelX': value.accelX,
        'accelY': value.accelY,
        'accelZ': value.accelZ,
        'gyroX': value.gyroX,
        'gyroY': value.gyroY,
        'gyroZ': value.gyroZ,
        'roll': value.roll,
        'pitch': value.pitch,
        'yaw': value.yaw,
        'quaternionW': value.quaternionW,
        'quaternionX': value.quaternionX,
        'quaternionY': value.quaternionY,
        'quaternionZ': value.quaternionZ,
      }),
    );
  }

  // Convert map to sensor snapshots
  Map<String, SensorSnapshot> _mapToSensorSnapshots(Map<String, dynamic> map) {
    return map.map((key, value) {
      final sensorMap = value as Map<String, dynamic>;
      return MapEntry(
        key,
        SensorSnapshot(
          accelX: sensorMap['accelX'] as double,
          accelY: sensorMap['accelY'] as double,
          accelZ: sensorMap['accelZ'] as double,
          gyroX: sensorMap['gyroX'] as double,
          gyroY: sensorMap['gyroY'] as double,
          gyroZ: sensorMap['gyroZ'] as double,
          roll: sensorMap['roll'] as double,
          pitch: sensorMap['pitch'] as double,
          yaw: sensorMap['yaw'] as double,
          quaternionW: sensorMap['quaternionW'] as double? ?? 1.0,
          quaternionX: sensorMap['quaternionX'] as double? ?? 0.0,
          quaternionY: sensorMap['quaternionY'] as double? ?? 0.0,
          quaternionZ: sensorMap['quaternionZ'] as double? ?? 0.0,
        ),
      );
    });
  }

  // Get all activities
  Future<List<ActivityRecord>> getAllActivities() async {
    final db = await database;

    // Get activities
    final activities = await db.query('activities', orderBy: 'startTime DESC');

    // Load data points for each activity
    List<ActivityRecord> records = [];
    for (var activity in activities) {
      final dataPoints = await db.query(
        'data_points',
        where: 'activityId = ?',
        whereArgs: [activity['id']],
        orderBy: 'timestamp ASC',
      );

      List<ActivityDataPoint> points = dataPoints.map((dp) {
        final sensorsData =
            jsonDecode(dp['sensorsData'] as String) as Map<String, dynamic>;
        final phoneSensorsRaw = dp['phoneSensorsData'] as String?;
        return ActivityDataPoint(
          timestamp: DateTime.parse(dp['timestamp'] as String),
          sensors: _mapToSensorSnapshots(sensorsData),
          phoneSensors: phoneSensorsRaw != null
              ? PhoneSensorData.fromJson(
                  jsonDecode(phoneSensorsRaw) as Map<String, dynamic>,
                )
              : null,
          fatigueLevel: dp['fatigueLevel'] as int?,
        );
      }).toList();

      records.add(
        ActivityRecord(
          id: activity['id'] as String,
          type: activity['type'] as String,
          environment: activity['environment'] as String,
          startTime: DateTime.parse(activity['startTime'] as String),
          endTime: DateTime.parse(activity['endTime'] as String),
          duration: Duration(seconds: activity['duration'] as int),
          dataPoints: points,
          userId: activity['userId'] as String?,
          userName: activity['userName'] as String?,
          emoji: activity['emoji'] as String?,
        ),
      );
    }

    return records;
  }

  // Get single activity
  Future<ActivityRecord?> getActivity(String id) async {
    final db = await database;

    final activities = await db.query(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (activities.isEmpty) return null;

    final activity = activities.first;
    final dataPoints = await db.query(
      'data_points',
      where: 'activityId = ?',
      whereArgs: [id],
      orderBy: 'timestamp ASC',
    );

    List<ActivityDataPoint> points = dataPoints.map((dp) {
      final sensorsData =
          jsonDecode(dp['sensorsData'] as String) as Map<String, dynamic>;
      final phoneSensorsRaw = dp['phoneSensorsData'] as String?;
      return ActivityDataPoint(
        timestamp: DateTime.parse(dp['timestamp'] as String),
        sensors: _mapToSensorSnapshots(sensorsData),
        phoneSensors: phoneSensorsRaw != null
            ? PhoneSensorData.fromJson(
                jsonDecode(phoneSensorsRaw) as Map<String, dynamic>,
              )
            : null,
        fatigueLevel: dp['fatigueLevel'] as int?,
      );
    }).toList();

    return ActivityRecord(
      id: activity['id'] as String,
      type: activity['type'] as String,
      environment: activity['environment'] as String,
      startTime: DateTime.parse(activity['startTime'] as String),
      endTime: DateTime.parse(activity['endTime'] as String),
      duration: Duration(seconds: activity['duration'] as int),
      dataPoints: points,
      userId: activity['userId'] as String?,
      userName: activity['userName'] as String?,
      emoji: activity['emoji'] as String?,
    );
  }

  // Delete activity
  Future<void> deleteActivity(String id) async {
    final db = await database;
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
    await db.delete('data_points', where: 'activityId = ?', whereArgs: [id]);
  }

  // ---- Trash / Recycle Bin ----

  Future<void> moveToTrash(ActivityRecord record) async {
    final db = await database;
    await db.insert('deleted_activities', {
      'id': record.id,
      'activityJson': jsonEncode(record.toJson()),
      'deletedAt': DateTime.now().toIso8601String(),
    });
    await db.delete('activities', where: 'id = ?', whereArgs: [record.id]);
    await db.delete('data_points', where: 'activityId = ?', whereArgs: [record.id]);
  }

  Future<List<Map<String, dynamic>>> getTrashItems() async {
    final db = await database;
    return await db.query('deleted_activities', orderBy: 'deletedAt DESC');
  }

  Future<Map<String, dynamic>?> getTrashItem(String id) async {
    final db = await database;
    final rows = await db.query(
      'deleted_activities',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> restoreFromTrash(String id) async {
    final db = await database;
    final row = await getTrashItem(id);
    if (row == null) return;

    final recordMap = jsonDecode(row['activityJson'] as String) as Map<String, dynamic>;
    final record = ActivityRecord.fromJson(recordMap);

    await db.insert('activities', {
      'id': record.id,
      'type': record.type,
      'environment': record.environment,
      'startTime': record.startTime.toIso8601String(),
      'endTime': record.endTime.toIso8601String(),
      'duration': record.duration.inSeconds,
      if (record.userId != null) 'userId': record.userId,
      if (record.userName != null) 'userName': record.userName,
      if (record.emoji != null) 'emoji': record.emoji,
    });

    final batch = db.batch();
    for (var dp in record.dataPoints) {
      batch.insert('data_points', {
        'activityId': record.id,
        'timestamp': dp.timestamp.toIso8601String(),
        'sensorsData': jsonEncode(_sensorSnapshotsToMap(dp.sensors)),
        if (dp.phoneSensors != null)
          'phoneSensorsData': jsonEncode(dp.phoneSensors!.toJson()),
        if (dp.fatigueLevel != null)
          'fatigueLevel': dp.fatigueLevel,
      });
    }
    await batch.commit(noResult: true);

    await db.delete('deleted_activities', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> permanentlyDeleteFromTrash(String id) async {
    final db = await database;
    await db.delete('deleted_activities', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearTrash() async {
    final db = await database;
    await db.delete('deleted_activities');
  }

  Future<int> trashItemCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM deleted_activities');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ---- Custom Activity Types ----

  Future<void> saveCustomActivityType(ActivityType type) async {
    final db = await database;
    await db.insert(
      'custom_activity_types',
      {
        'id': type.id,
        'name': type.name,
        'emoji': type.emoji ?? '🏃',
        'sensorsJson': jsonEncode(
          type.requiredSensors.map((s) => s.toJson()).toList(),
        ),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ActivityType>> getAllCustomActivityTypes() async {
    final db = await database;
    final rows = await db.query('custom_activity_types');
    return rows.map((row) {
      final sensors =
          (jsonDecode(row['sensorsJson'] as String) as List)
              .map((s) => SensorPosition.fromJson(s as Map<String, dynamic>))
              .toList();
      return ActivityType(
        id: row['id'] as String,
        name: row['name'] as String,
        environment: 'custom',
        icon: Icons.category,
        emoji: row['emoji'] as String,
        isCustom: true,
        requiredSensors: sensors,
      );
    }).toList();
  }

  Future<void> deleteCustomActivityType(String id) async {
    final db = await database;
    await db.delete(
      'custom_activity_types',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('data_points');
    await db.delete('activities');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // ---- User Profiles ----

  Future<void> saveUser(UserProfile user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<UserProfile>> getAllUsers() async {
    final db = await database;
    final rows = await db.query('users', orderBy: 'name ASC');
    return rows.map((row) => UserProfile.fromMap(row)).toList();
  }

  Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Settings ----

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> deleteSetting(String key) async {
    final db = await database;
    await db.delete('settings', where: 'key = ?', whereArgs: [key]);
  }
}
