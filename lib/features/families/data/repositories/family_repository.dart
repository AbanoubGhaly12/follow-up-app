import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/family_model.dart';

class FamilyRepository {
  final DatabaseHelper _databaseHelper;

  FamilyRepository(this._databaseHelper);

  Future<List<FamilyModel>> getFamiliesForZone(String streetId) async {
    final db = await _databaseHelper.database;
    final String query = '''
      SELECT *, 
        (SELECT COUNT(*) FROM followups 
         WHERE family_id = f.id 
         AND strftime('%Y-%m', followup_date) = strftime('%Y-%m', 'now')) > 0 as is_followed_up_this_month,
        (SELECT MAX(followup_date) FROM followups 
         WHERE family_id = f.id 
         AND strftime('%Y-%m', followup_date) = strftime('%Y-%m', 'now')) as last_followup_date
      FROM families f
      WHERE f.street_id = ?
    ''';
    final List<Map<String, dynamic>> maps = await db.rawQuery(query, [streetId]);
    return List.generate(maps.length, (i) {
      return FamilyModel.fromMap(maps[i]);
    });
  }

  Future<List<FamilyModel>> getAllFamilies() async {
    final db = await _databaseHelper.database;
    final String query = '''
      SELECT *, 
        (SELECT COUNT(*) FROM followups 
         WHERE family_id = f.id 
         AND strftime('%Y-%m', followup_date) = strftime('%Y-%m', 'now')) > 0 as is_followed_up_this_month,
        (SELECT MAX(followup_date) FROM followups 
         WHERE family_id = f.id 
         AND strftime('%Y-%m', followup_date) = strftime('%Y-%m', 'now')) as last_followup_date
      FROM families f
    ''';
    final List<Map<String, dynamic>> maps = await db.rawQuery(query);
    return List.generate(maps.length, (i) {
      return FamilyModel.fromMap(maps[i]);
    });
  }

  Future<void> addFamily(FamilyModel family) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'families',
      family.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateFamily(FamilyModel family) async {
    final db = await _databaseHelper.database;
    await db.update(
      'families',
      family.toMap(),
      where: 'id = ?',
      whereArgs: [family.id],
    );
  }

  Future<void> deleteFamily(String id) async {
    final db = await _databaseHelper.database;
    await db.delete('families', where: 'id = ?', whereArgs: [id]);
  }
}
