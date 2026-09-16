import 'dart:convert';
import 'dart:io';

import 'package:docflownew/models/secretary.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.4.121:8000';

  // =========================
  // معالجة مستند متعدد الصفحات
  // =========================

  static Future<Map<String, dynamic>> processDocument(
    List<File> files,
  ) async {
    if (files.isEmpty) {
      throw Exception('لم يتم اختيار أي صفحة');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/process'),
    );

    // إضافة جميع صفحات المستند
    for (final file in files) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'files',
          file.path,
        ),
      );
    }

    final response = await request.send();

    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception(body);
    }

    return jsonDecode(body) as Map<String, dynamic>;
  }

  // =========================
  // جلب أمناء السر
  // =========================

  static Future<List<Secretary>> getSecretaries() async {
    final response = await http.get(
      Uri.parse('$baseUrl/secretaries'),
    );

    if (response.statusCode != 200) {
      throw Exception('فشل في جلب أمناء السر');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final secretariesJson =
        data['secretaries'] as List<dynamic>;

    return secretariesJson
        .map(
          (item) => Secretary.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // =========================
  // إضافة أمين سر
  // =========================

  static Future<void> createSecretary(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/secretaries'),
      body: {
        'name': name,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('فشل في إضافة أمين السر');
    }
  }

  // =========================
  // تعديل اسم أمين السر
  // =========================

  static Future<void> updateSecretary(
    String oldName,
    String newName,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/secretaries/${Uri.encodeComponent(oldName)}',
      ),
      body: {
        'new_name': newName,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('فشل في تعديل اسم أمين السر');
    }
  }

  // =========================
  // حذف أمين سر
  // =========================

  static Future<void> deleteSecretary(String name) async {
    final response = await http.delete(
      Uri.parse(
        '$baseUrl/secretaries/${Uri.encodeComponent(name)}',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('فشل في حذف أمين السر');
    }
  }

  // =========================
  // إضافة نماذج خط
  // =========================

  static Future<void> enrollSecretary(
    String name,
    List<File> files,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/secretaries/enroll'),
    );

    request.fields['name'] = name;

    for (final file in files) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'files',
          file.path,
        ),
      );
    }

    final response = await request.send();

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception(body);
    }
  }
}