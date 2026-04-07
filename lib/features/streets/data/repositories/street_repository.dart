import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/sync/firestore_sync_service.dart';
import '../models/street_model.dart';

class StreetRepository {
  final DatabaseHelper dbHelper;
  final FirestoreSyncService _syncService;

  StreetRepository({required this.dbHelper, required FirestoreSyncService syncService})
      : _syncService = syncService;

  Future<int> insertStreet(StreetModel street) async {
    final db = await dbHelper.database;
    final result = await db.insert(
      'streets',
      street.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _syncService.pushStreet(street.toMap());
    return result;
  }

  Future<List<StreetModel>> getStreetsForZone(String zoneId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'streets',
      where: 'zone_id = ?',
      whereArgs: [zoneId],
    );

    if (maps.isEmpty) {
      final remoteStreets = await _syncService.fetchStreets(zoneId);
      for (var streetData in remoteStreets) {
        await db.insert(
          'streets',
          streetData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      return remoteStreets.map((s) => StreetModel.fromMap(s)).toList();
    }

    return List.generate(maps.length, (i) => StreetModel.fromMap(maps[i]));
  }

  Future<List<StreetModel>> getAllStreets() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('streets');
    return List.generate(maps.length, (i) => StreetModel.fromMap(maps[i]));
  }

  Future<int> updateStreet(StreetModel street) async {
    final db = await dbHelper.database;
    final result = await db.update(
      'streets',
      street.toMap(),
      where: 'id = ?',
      whereArgs: [street.id],
    );
    await _syncService.pushStreet(street.toMap());
    return result;
  }

  Future<int> deleteStreet(String id, {String? zoneId}) async {
    final db = await dbHelper.database;
    final result = await db.delete('streets', where: 'id = ?', whereArgs: [id]);
    if (zoneId != null) {
      await _syncService.deleteStreetRemote(id, zoneId);
    }
    return result;
  }
}
