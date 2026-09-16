import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // Singleton
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  // الحصول على قاعدة البيانات
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB();

    return _database!;
  }

  // إنشاء / فتح قاعدة البيانات
  Future<Database> _initDB() async {
    // الحصول على مجلد التطبيق
    final directory = await getApplicationDocumentsDirectory();

    // إنشاء مجلد خاص بقاعدة البيانات
    final dbDirectory = Directory(
      join(directory.path, 'DocFlow'),
    );

    if (!await dbDirectory.exists()) {
      await dbDirectory.create(recursive: true);
    }

    // مسار قاعدة البيانات
    final path = join(
      dbDirectory.path,
      'docflow.db',
    );

    print('Database path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // إنشاء الجداول
  Future<void> _createDB(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE secretaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  // =========================
  // إضافة أمين سر
  // =========================

  Future<int> addSecretary(String name) async {
    final db = await database;

    return await db.insert(
      'secretaries',
      {
        'name': name,
        'isActive': 1,
      },
    );
  }

  // =========================
  // جلب جميع أمناء السر
  // =========================

  Future<List<Map<String, dynamic>>> getSecretaries() async {
    final db = await database;

    return await db.query(
      'secretaries',
      orderBy: 'id DESC',
    );
  }

  // =========================
  // تعديل اسم أمين السر
  // =========================

  Future<int> updateSecretary(
    int id,
    String name,
  ) async {
    final db = await database;

    return await db.update(
      'secretaries',
      {
        'name': name,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // حذف أمين السر
  // =========================

  Future<int> deleteSecretary(int id) async {
    final db = await database;

    return await db.delete(
      'secretaries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // إغلاق قاعدة البيانات
  // =========================

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}