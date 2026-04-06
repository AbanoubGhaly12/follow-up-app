import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/street_model.dart';

class StreetRepository {
  final DatabaseHelper dbHelper;

  StreetRepository({required this.dbHelper});

  Future<int> insertStreet(StreetModel street) async {
    final db = await dbHelper.database;
    return await db.insert(
      'streets',
      street.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StreetModel>> getStreetsForZone(String zoneId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'streets',
      where: 'zone_id = ?',
      whereArgs: [zoneId],
    );
    return List.generate(maps.length, (i) => StreetModel.fromMap(maps[i]));
  }

  Future<List<StreetModel>> getAllStreets() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('streets');
    return List.generate(maps.length, (i) => StreetModel.fromMap(maps[i]));
  }

  Future<int> updateStreet(StreetModel street) async {
    final db = await dbHelper.database;
    return await db.update(
      'streets',
      street.toMap(),
      where: 'id = ?',
      whereArgs: [street.id],
    );
  }

  Future<int> deleteStreet(String id) async {
    final db = await dbHelper.database;
    return await db.delete('streets', where: 'id = ?', whereArgs: [id]);
  }
}
