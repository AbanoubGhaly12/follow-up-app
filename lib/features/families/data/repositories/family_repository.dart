import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
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
         AND member_id IS NULL 
         AND strftime('%Y-%m', followup_date) = strftime('%Y-%m', 'now')) > 0 as is_followed_up_this_month,
        (SELECT MAX(followup_date) FROM followups 
         WHERE family_id = f.id 
         AND member_id IS NULL 
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
          final familyModel = FamilyModel.fromFirestore(familyData['id'], familyData);
          await db.insert(
            'families',
            familyModel.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        return remoteFamilies.map((f) => FamilyModel.fromFirestore(f['id'], f)).toList();
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
         AND member_id IS NULL 
         AND strftime('%Y-%m', followup_date) = strftime('%Y-%m', 'now')) > 0 as is_followed_up_this_month,
        (SELECT MAX(followup_date) FROM followups 
         WHERE family_id = f.id 
         AND member_id IS NULL 
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
    
    // Check for tag uniqueness per street locally
    if (family.tag.trim().isNotEmpty) {
      final existing = await db.query(
        'families',
        where: 'tag = ? AND street_id = ?',
        whereArgs: [family.tag, family.streetId],
      );
      if (existing.isNotEmpty) {
        throw Exception('Family with this tag already exists in this street.');
      }
    }

    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
    
    String zoneId = '';
    final streetRows = await db.query('streets', where: 'id = ?', whereArgs: [family.streetId]);
    if (streetRows.isNotEmpty) {
      zoneId = streetRows.first['zone_id'] as String;
    }
    
    if (isOnline && family.tag.trim().isNotEmpty && zoneId.isNotEmpty) {
      final remoteExists = await _syncService.doesFamilyTagExist(family.tag, zoneId, family.streetId);
      if (remoteExists) {
        throw Exception('Family with this tag already exists in Cloud.');
      }
    }
    
    final finalFamily = family.copyWith(isSynced: isOnline);

    await db.insert(
      'families',
      finalFamily.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    if (isOnline && zoneId.isNotEmpty) {
      await _syncService.pushFamily(finalFamily.toFirestore()..['id'] = finalFamily.id, zoneId);
    }
  }

  Future<void> updateFamily(FamilyModel family) async {
    final db = await _databaseHelper.database;
    
    // Check for tag uniqueness per street locally excluding this family
    if (family.tag.trim().isNotEmpty) {
      final existing = await db.query(
        'families',
        where: 'tag = ? AND street_id = ? AND id != ?',
        whereArgs: [family.tag, family.streetId, family.id],
      );
      if (existing.isNotEmpty) {
        throw Exception('Family with this tag already exists in this street.');
      }
    }

    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
    
    String zoneId = '';
    final streetRows = await db.query('streets', where: 'id = ?', whereArgs: [family.streetId]);
    if (streetRows.isNotEmpty) {
      zoneId = streetRows.first['zone_id'] as String;
    }
    
    final finalFamily = family.copyWith(isSynced: isOnline);

    await db.update(
      'families',
      finalFamily.toMap(),
      where: 'id = ?',
      whereArgs: [finalFamily.id],
    );
    
    if (isOnline && zoneId.isNotEmpty) {
      await _syncService.pushFamily(finalFamily.toFirestore()..['id'] = finalFamily.id, zoneId);
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

  Future<void> importFamiliesFromCsv(List<Map<String, dynamic>> csvData, String streetId) async {
    for (var row in csvData) {
      // Required defaults
      final addressInfo = AddressInfo(
        street: row['street']?.toString() ?? '',
        buildingNumber: row['building_number']?.toString() ?? '',
        floorNumber: row['floor_number']?.toString() ?? '',
        flatNumber: row['flat_number']?.toString() ?? '',
        streetFrom: row['street_from']?.toString() ?? '',
      );
      
      final family = FamilyModel(
        id: const Uuid().v4(),
        streetId: streetId,
        familyHead: row['family_head']?.toString() ?? 'Unnamed Family',
        tag: row['tag']?.toString() ?? '',
        mobileNumber: row['mobile_number']?.toString() ?? '',
        landline: row['landline']?.toString() ?? '',
        addressInfo: addressInfo,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      try {
        await addFamily(family);
      } catch (e) {
        if (!e.toString().contains('already exists')) {
          rethrow;
        }
      }
    }
  }

  Future<void> syncOfflineFamilies() async {
    final db = await _databaseHelper.database;
    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
    
    if (!isOnline) {
      throw Exception('network_unavailable');
    }
    
    final List<Map<String, dynamic>> offlineMaps = await db.query(
      'families',
      where: 'is_synced = ? OR is_synced IS NULL',
      whereArgs: [0],
    );
    
    for (var map in offlineMaps) {
      var family = FamilyModel.fromMap(map);
      
      String zoneId = '';
      final streetRows = await db.query('streets', where: 'id = ?', whereArgs: [family.streetId]);
      if (streetRows.isNotEmpty) {
        zoneId = streetRows.first['zone_id'] as String;
      }
      
      if (zoneId.isEmpty) continue;
      
      final remoteExists = await _syncService.doesFamilyTagExist(family.tag, zoneId, family.streetId);
      if (remoteExists) {
        await db.delete('families', where: 'id = ?', whereArgs: [family.id]);
        continue;
      }
      
      family = family.copyWith(isSynced: true);
      
      await _syncService.pushFamily(family.toFirestore()..['id'] = family.id, zoneId);
      
      await db.update(
        'families',
        family.toMap(),
        where: 'id = ?',
        whereArgs: [family.id],
      );
    }
  }
}
