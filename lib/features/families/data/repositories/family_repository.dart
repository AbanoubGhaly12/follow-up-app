import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/family_model.dart';

class FamilyRepository {
  final DatabaseHelper _databaseHelper;

  FamilyRepository(this._databaseHelper);

  Future<List<FamilyModel>> getFamiliesForZone(String streetId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'families',
      where: 'street_id = ?',
      whereArgs: [streetId],
    );
    return List.generate(maps.length, (i) {
      return FamilyModel.fromMap(maps[i]);
    });
  }

  Future<List<FamilyModel>> getAllFamilies() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('families');
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
