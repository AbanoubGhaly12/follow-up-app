import 'package:sqflite/sqflite.dart';
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
    final userId = _syncService.currentUserId;
    
    final zoneWithAdmin = zone.adminUid == null 
      ? zone.copyWith(adminUid: userId)
      : zone;

    await db.insert(
      'zones',
      zoneWithAdmin.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _syncService.pushZone(zoneWithAdmin.toFirestore()..['id'] = zoneWithAdmin.id);

    // Update all assigned admins' zone lists
    for (final adminUid in zoneWithAdmin.zoneAdmins) {
      await _syncUserZoneList(adminUid);
    }
  }

  Future<void> updateZone(ZoneModel zone) async {
    final db = await _databaseHelper.database;
    await db.update(
      'zones',
      zone.toMap(),
      where: 'id = ?',
      whereArgs: [zone.id],
    );
    await _syncService.pushZone(zone.toFirestore()..['id'] = zone.id);

    // Update all assigned admins' zone lists
    for (final adminUid in zone.zoneAdmins) {
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
}
