import '../../../../core/database/database_helper.dart';
import '../models/template_model.dart';
import 'package:sqflite/sqflite.dart';

class TemplateRepository {
  final DatabaseHelper _dbHelper;

  TemplateRepository(this._dbHelper);

  Future<List<TemplateModel>> getAllTemplates() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'message_templates',
      orderBy: 'type ASC, created_at DESC',
    );
    return List.generate(maps.length, (i) => TemplateModel.fromMap(maps[i]));
  }

  Future<TemplateModel?> getTemplateById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'message_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return TemplateModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> insertTemplate(TemplateModel template) async {
    final db = await _dbHelper.database;
    await db.insert(
      'message_templates',
      template.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTemplate(TemplateModel template) async {
    final db = await _dbHelper.database;
    await db.update(
      'message_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<void> deleteTemplate(String id) async {
    final db = await _dbHelper.database;
    await db.delete('message_templates', where: 'id = ?', whereArgs: [id]);
  }
}
