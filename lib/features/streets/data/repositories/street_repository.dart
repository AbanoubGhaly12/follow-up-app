import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
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
    
    // Check for tag uniqueness per zone locally
    if (street.tag.trim().isNotEmpty) {
      final existing = await db.query(
        'streets',
        where: 'tag = ? AND zone_id = ?',
        whereArgs: [street.tag, street.zoneId],
      );
      if (existing.isNotEmpty) {
        throw Exception('Street with this tag already exists in this zone.');
      }
    }

    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
    
    if (isOnline && street.tag.trim().isNotEmpty) {
      final remoteExists = await _syncService.doesStreetTagExist(street.tag, street.zoneId);
      if (remoteExists) {
        throw Exception('Street with this tag already exists in Cloud.');
      }
    }
    
    final finalStreet = street.copyWith(isSynced: isOnline);

    final result = await db.insert(
      'streets',
      finalStreet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    if (isOnline) {
      await _syncService.pushStreet(finalStreet.toFirestore()..['id'] = finalStreet.id);
    }
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
        // Assume from firestore is inherently synced
        final streetModel = StreetModel.fromFirestore(streetData['id'], streetData);
        await db.insert(
          'streets',
          streetModel.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      return remoteStreets.map((s) => StreetModel.fromFirestore(s['id'], s)).toList();
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
    
    // Check for tag uniqueness per zone excluding this street
    if (street.tag.trim().isNotEmpty) {
      final existing = await db.query(
        'streets',
        where: 'tag = ? AND zone_id = ? AND id != ?',
        whereArgs: [street.tag, street.zoneId, street.id],
      );
      if (existing.isNotEmpty) {
        throw Exception('Street with this tag already exists in this zone.');
      }
    }
    
    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
    
    if (isOnline && street.tag.trim().isNotEmpty) {
      // Remote check logic - omitted to allow self-update safely.
    }
    
    final finalStreet = street.copyWith(isSynced: isOnline);

    final result = await db.update(
      'streets',
      finalStreet.toMap(),
      where: 'id = ?',
      whereArgs: [finalStreet.id],
    );
    
    if (isOnline) {
      await _syncService.pushStreet(finalStreet.toFirestore()..['id'] = finalStreet.id);
    }
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

  Future<void> importStreetsFromCsv(List<Map<String, dynamic>> csvData, String zoneId) async {
    for (var row in csvData) {
      final street = StreetModel(
        id: const Uuid().v4(),
        zoneId: zoneId,
        name: row['name']?.toString() ?? 'Unnamed Street',
        tag: row['tag']?.toString() ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      try {
        await insertStreet(street);
      } catch (e) {
        if (!e.toString().contains('already exists')) {
          rethrow;
        }
      }
    }
  }

  Future<void> syncOfflineStreets() async {
    final db = await dbHelper.database;
    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
    
    if (!isOnline) {
      throw Exception('network_unavailable');
    }
    
    final List<Map<String, dynamic>> offlineMaps = await db.query(
      'streets',
      where: 'is_synced = ? OR is_synced IS NULL',
      whereArgs: [0],
    );
    
    for (var map in offlineMaps) {
      var street = StreetModel.fromMap(map);
      
      final remoteExists = await _syncService.doesStreetTagExist(street.tag, street.zoneId);
      if (remoteExists) {
        await db.delete('streets', where: 'id = ?', whereArgs: [street.id]);
        continue;
      }
      
      street = street.copyWith(isSynced: true);
      
      await _syncService.pushStreet(street.toFirestore()..['id'] = street.id);
      
      await db.update(
        'streets',
        street.toMap(),
        where: 'id = ?',
        whereArgs: [street.id],
      );
    }
  }
}
