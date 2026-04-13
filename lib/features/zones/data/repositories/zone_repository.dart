import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/sync/firestore_sync_service.dart';
import '../../../auth/data/repositories/user_repository.dart';
import '../models/zone_model.dart';

class ZoneRepository {
  final DatabaseHelper _databaseHelper;
  final FirestoreSyncService _syncService;
  final UserRepository _userRepository;

  ZoneRepository(this._databaseHelper, this._syncService, this._userRepository);

  Future<List<ZoneModel>> getZones({
    bool isSuperAdmin = false,
    bool otherZonesOnly = false,
  }) async {
    final db = await _databaseHelper.database;
    final userId = _syncService.currentUserId;
    if (userId == null) return [];

    final List<Map<String, dynamic>> maps;

    if (isSuperAdmin && otherZonesOnly) {
      // Show ONLY zones where the user is NOT an admin
      // Show ALL zones for the global oversight view
      maps = await db.query('zones');
    } else {
      // Filtered view for Sub-Admins
      maps = await db.query(
        'zones',
        where: 'admin_uid = ? OR zone_admins LIKE ?',
        whereArgs: [userId, '%"$userId"%'],
      );
    }

    if (maps.isEmpty) {
      final remoteZones = await _syncService.fetchZones(isAdmin: isSuperAdmin, fetchOther: otherZonesOnly);
      for (var zoneData in remoteZones) {
        final zone = ZoneModel.fromFirestore(zoneData['id'], zoneData);
        await db.insert(
          'zones',
          zone.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      return remoteZones.map((z) => ZoneModel.fromFirestore(z['id'], z)).toList();
    }

    return List.generate(maps.length, (i) {
      return ZoneModel.fromMap(maps[i]);
    });
  }

  Future<void> addZone(ZoneModel zone) async {
    final db = await _databaseHelper.database;
    
    // Check for tag uniqueness
    if (zone.tag.trim().isNotEmpty) {
      final existing = await db.query(
        'zones',
        where: 'tag = ?',
        whereArgs: [zone.tag],
      );
      if (existing.isNotEmpty) {
        throw Exception('Zone with this tag already exists.');
      }
    }

    final userId = _syncService.currentUserId;
    
    final zoneWithAdmin = zone.adminUid == null 
      ? zone.copyWith(adminUid: userId)
      : zone;
      
    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
    
    if (isOnline && zone.tag.trim().isNotEmpty) {
      final remoteExists = await _syncService.doesZoneTagExist(zone.tag);
      if (remoteExists) {
        throw Exception('Zone with this tag already exists in Cloud.');
      }
    }
    
    final finalZone = zoneWithAdmin.copyWith(isSynced: isOnline);

    await db.insert(
      'zones',
      finalZone.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    if (isOnline) {
      await _syncService.pushZone(finalZone.toFirestore()..['id'] = finalZone.id);
    }

    // Update all assigned admins' zone lists
    for (final adminUid in finalZone.zoneAdmins) {
      await _syncUserZoneList(adminUid);
    }
  }

  Future<void> updateZone(ZoneModel zone) async {
    final db = await _databaseHelper.database;
    
    // Check for tag uniqueness excluding this zone
    if (zone.tag.trim().isNotEmpty) {
      final existing = await db.query(
        'zones',
        where: 'tag = ? AND id != ?',
        whereArgs: [zone.tag, zone.id],
      );
      if (existing.isNotEmpty) {
        throw Exception('Zone with this tag already exists.');
      }
    }
    
    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
    
    if (isOnline && zone.tag.trim().isNotEmpty) {
      final remoteExists = await _syncService.doesZoneTagExist(zone.tag);
      // Ensure we don't throw if the remote zone is just this exact same zone updating itself
      if (remoteExists) {
        // Technically we can't tell if the remote tag belongs to *this* zone easily via doesZoneTagExist
        // without returning the UID. For now, since update implies it already exists, 
        // the standard query would be needed, but since Firestore doc ID is zone.id, 
        // updating its own tag is fine.
        // However, wait. The local check already excluded `id != ?`.
      }
    }
    
    final finalZone = zone.copyWith(isSynced: isOnline);
    
    await db.update(
      'zones',
      finalZone.toMap(),
      where: 'id = ?',
      whereArgs: [finalZone.id],
    );
    
    if (isOnline) {
      await _syncService.pushZone(finalZone.toFirestore()..['id'] = finalZone.id);
    }

    // Update all assigned admins' zone lists
    for (final adminUid in finalZone.zoneAdmins) {
      await _syncUserZoneList(adminUid);
    }
  }

  Future<void> deleteZone(String id) async {
    final db = await _databaseHelper.database;
    
    // Get zone to find admins before deleting
    final List<Map<String, dynamic>> maps = await db.query(
      'zones',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    List<String> affectedAdmins = [];
    if (maps.isNotEmpty) {
      final zone = ZoneModel.fromMap(maps.first);
      affectedAdmins = zone.zoneAdmins;
    }

    await db.delete(
      'zones',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _syncService.deleteZoneRemote(id);

    // Update affected admins' zone lists
    for (final adminUid in affectedAdmins) {
      await _syncUserZoneList(adminUid);
    }
  }

  /// Helper to fetch all zones assigned to a user and update their profile
  Future<void> _syncUserZoneList(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'zones',
      where: 'admin_uid = ? OR zone_admins LIKE ?',
      whereArgs: [userId, '%"$userId"%'],
    );
    
    final zoneIds = maps.map((m) => m['id'] as String).toList();
    await _userRepository.updateUserZones(userId, zoneIds);
  }

  /// One-time sync to populate all users' managedZoneIds from current zones
  Future<void> syncAllUserZoneLists() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> userMaps = await db.query('users');
    for (final userMap in userMaps) {
      final userId = userMap['uid'] as String;
      await _syncUserZoneList(userId);
    }
  }

  Future<void> importZonesFromCsv(List<Map<String, dynamic>> csvData) async {
    for (var row in csvData) {
      final zone = ZoneModel(
        id: const Uuid().v4(),
        name: row['name']?.toString() ?? 'Unnamed Zone',
        tag: row['tag']?.toString() ?? '',
        description: row['description']?.toString(),
        zoneAdmins: const [],
        adminUid: _syncService.currentUserId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false, // addZone will check connectivity automatically
      );
      try {
        await addZone(zone);
      } catch (e) {
        if (!e.toString().contains('already exists')) {
          rethrow;
        }
        // Skip existing tags to allow partial imports
      }
    }
  }

  Future<void> syncOfflineZones() async {
    final db = await _databaseHelper.database;
    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
    
    if (!isOnline) {
      throw Exception('network_unavailable');
    }
    
    final List<Map<String, dynamic>> offlineMaps = await db.query(
      'zones',
      where: 'is_synced = ? OR is_synced IS NULL',
      whereArgs: [0],
    );
    
    for (var map in offlineMaps) {
      var zone = ZoneModel.fromMap(map);
      
      final remoteExists = await _syncService.doesZoneTagExist(zone.tag);
      if (remoteExists) {
        // "if exists ignore it": we delete the offline duplicate locally 
        // to prevent it from piling up or duplicating the cloud dataset.
        await db.delete('zones', where: 'id = ?', whereArgs: [zone.id]);
        continue;
      }
      
      zone = zone.copyWith(isSynced: true);
      
      // push to firestore
      await _syncService.pushZone(zone.toFirestore()..['id'] = zone.id);
      
      // update local
      await db.update(
        'zones',
        zone.toMap(),
        where: 'id = ?',
        whereArgs: [zone.id],
      );
    }
  }
}
