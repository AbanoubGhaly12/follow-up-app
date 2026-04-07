import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/sync/firestore_sync_service.dart';
import '../models/family_model.dart';

class FamilyRepository {
  final DatabaseHelper _databaseHelper;
  final FirestoreSyncService _syncService;

  FamilyRepository(this._databaseHelper, this._syncService);

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
    
    if (maps.isEmpty) {
      // Find zoneId for this street
      final streetRows = await db.query('streets', where: 'id = ?', whereArgs: [streetId]);
      if (streetRows.isNotEmpty) {
        final zoneId = streetRows.first['zone_id'] as String;
        final remoteFamilies = await _syncService.fetchFamilies(zoneId, streetId);
        for (var familyData in remoteFamilies) {
          await db.insert(
            'families',
            familyData,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        return remoteFamilies.map((f) => FamilyModel.fromMap(f)).toList();
      }
    }

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
    // For Firestore nested path we need the zoneId, but it's not on FamilyModel.
    // We look it up from the street.
    final streetRows = await db.query('streets', where: 'id = ?', whereArgs: [family.streetId]);
    if (streetRows.isNotEmpty) {
      final zoneId = streetRows.first['zone_id'] as String;
      await _syncService.pushFamily(family.toMap(), zoneId);
    }
  }

  Future<void> updateFamily(FamilyModel family) async {
    final db = await _databaseHelper.database;
    await db.update(
      'families',
      family.toMap(),
      where: 'id = ?',
      whereArgs: [family.id],
    );
    final streetRows = await db.query('streets', where: 'id = ?', whereArgs: [family.streetId]);
    if (streetRows.isNotEmpty) {
      final zoneId = streetRows.first['zone_id'] as String;
      await _syncService.pushFamily(family.toMap(), zoneId);
    }
  }

  Future<void> deleteFamily(String id) async {
    final db = await _databaseHelper.database;
    // Look up the street/zone before deleting
    final familyRows = await db.query('families', where: 'id = ?', whereArgs: [id]);
    String? streetId;
    String? zoneId;
    if (familyRows.isNotEmpty) {
      streetId = familyRows.first['street_id'] as String?;
      if (streetId != null) {
        final streetRows = await db.query('streets', where: 'id = ?', whereArgs: [streetId]);
        if (streetRows.isNotEmpty) {
          zoneId = streetRows.first['zone_id'] as String?;
        }
      }
    }
    await db.delete('families', where: 'id = ?', whereArgs: [id]);
    if (streetId != null && zoneId != null) {
      await _syncService.deleteFamilyRemote(id, streetId, zoneId);
    }
  }
}
