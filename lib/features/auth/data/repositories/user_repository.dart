import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/sync/firestore_sync_service.dart';
import '../models/user_model.dart';

class UserRepository {
  final DatabaseHelper _dbHelper;
  final FirestoreSyncService _syncService;

  UserRepository(this._dbHelper, this._syncService);

  Future<AppUserModel?> getUser(String uid) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );

    if (maps.isNotEmpty) {
      return AppUserModel.fromMap(maps.first);
    }

    final remoteData = await _syncService.fetchUser(uid);
    if (remoteData != null) {
      final user = AppUserModel.fromFirestore(uid, remoteData);
      await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return user;
    }
    return null;
  }

  Future<void> addUser(AppUserModel user) async {
    final db = await _dbHelper.database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _syncService.pushUser(user.toFirestore());
  }

  Future<void> updateUserZones(String uid, List<String> zoneIds) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );

    if (maps.isNotEmpty) {
      final user = AppUserModel.fromMap(maps.first);
      final updatedUser = user.copyWith(managedZoneIds: zoneIds);
      await db.update(
        'users',
        updatedUser.toMap(),
        where: 'uid = ?',
        whereArgs: [uid],
      );
      await _syncService.pushUser(updatedUser.toFirestore());
    }
  }

  Future<List<AppUserModel>> getManagedUsers() async {
    final db = await _dbHelper.database;
    final userId = _syncService.currentUserId;
    if (userId == null) return [];

    // First try to fetch from local DB
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'parent_admin_uid = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) {
      // If local is empty, try to fetch from Firestore and sync
      final remoteUsers = await _syncService.getManagedUsers();
      for (var userData in remoteUsers) {
        final user = AppUserModel.fromFirestore(userData['uid'], userData);
        await db.insert(
          'users', 
          user.toMap(), 
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      return remoteUsers.map((u) => AppUserModel.fromFirestore(u['uid'], u)).toList();
    }

    return List.generate(maps.length, (i) => AppUserModel.fromMap(maps[i]));
  }

  Future<void> deleteUser(String uid) async {
    final db = await _dbHelper.database;
    await db.delete('users', where: 'uid = ?', whereArgs: [uid]);
    // Remote delete not implemented for safety, user remains in Firebase Auth
  }
}
