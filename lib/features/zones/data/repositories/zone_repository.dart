import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/zone_model.dart';

class ZoneRepository {
  final DatabaseHelper _databaseHelper;

  ZoneRepository(this._databaseHelper);

  Future<List<ZoneModel>> getZones() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('zones');
    return List.generate(maps.length, (i) {
      return ZoneModel.fromMap(maps[i]);
    });
  }

  Future<void> addZone(ZoneModel zone) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'zones',
      zone.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateZone(ZoneModel zone) async {
    final db = await _databaseHelper.database;
    await db.update(
      'zones',
      zone.toMap(),
      where: 'id = ?',
      whereArgs: [zone.id],
    );
  }

  Future<void> deleteZone(String id) async {
    final db = await _databaseHelper.database;
    await db.delete('zones', where: 'id = ?', whereArgs: [id]);
  }
}
