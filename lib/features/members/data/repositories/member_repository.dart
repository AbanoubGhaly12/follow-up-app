import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/sync/firestore_sync_service.dart';
import '../models/member_model.dart';

class MemberRepository {
  final DatabaseHelper _databaseHelper;
  final FirestoreSyncService _syncService;

  MemberRepository(this._databaseHelper, this._syncService);

  Future<List<MemberModel>> getMembers({
    String? familyId,
    String? zoneId,
    String? streetId,
  }) async {
    final db = await _databaseHelper.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (familyId != null) {
      whereClause = 'm.family_id = ?';
      whereArgs.add(familyId);
    } else if (streetId != null) {
      whereClause = 'f.street_id = ?';
      whereArgs.add(streetId);
    } else if (zoneId != null) {
      whereClause = 's.zone_id = ?';
      whereArgs.add(zoneId);
    }

    final String query = '''
      SELECT m.*, 
        (SELECT COUNT(*) FROM followups 
         WHERE member_id = m.id 
         AND strftime('%Y-%m', followup_date) = strftime('%Y-%m', 'now')) > 0 as is_followed_up_this_month,
        (SELECT MAX(followup_date) FROM followups 
         WHERE member_id = m.id 
         AND strftime('%Y-%m', followup_date) = strftime('%Y-%m', 'now')) as last_followup_date
      FROM members m
      JOIN families f ON m.family_id = f.id
      JOIN streets s ON f.street_id = s.id
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);
    
    if (maps.isEmpty && familyId != null) {
      // Lookup hierarchy to fetch from Firestore
      final familyRows = await db.query('families', where: 'id = ?', whereArgs: [familyId]);
      if (familyRows.isNotEmpty) {
        final streetId = familyRows.first['street_id'] as String;
        final streetRows = await db.query('streets', where: 'id = ?', whereArgs: [streetId]);
        if (streetRows.isNotEmpty) {
          final zoneId = streetRows.first['zone_id'] as String;
          final remoteMembers = await _syncService.fetchMembers(zoneId, streetId, familyId);
          for (var memberData in remoteMembers) {
            await db.insert(
              'members',
              memberData,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          return remoteMembers.map((m) => MemberModel.fromMap(m)).toList();
        }
      }
    }

    return List.generate(maps.length, (i) {
      return MemberModel.fromMap(maps[i]);
    });
  }

  Future<void> addMember(MemberModel member) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'members',
      member.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Look up street and zone for Firestore nested path
    final familyRows = await db.query('families', where: 'id = ?', whereArgs: [member.familyId]);
    if (familyRows.isNotEmpty) {
      final streetId = familyRows.first['street_id'] as String;
      final streetRows = await db.query('streets', where: 'id = ?', whereArgs: [streetId]);
      if (streetRows.isNotEmpty) {
        final zoneId = streetRows.first['zone_id'] as String;
        await _syncService.pushMember(member.toMap(), streetId, zoneId);
      }
    }
  }

  Future<void> updateMember(MemberModel member) async {
    final db = await _databaseHelper.database;
    await db.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
    final familyRows = await db.query('families', where: 'id = ?', whereArgs: [member.familyId]);
    if (familyRows.isNotEmpty) {
      final streetId = familyRows.first['street_id'] as String;
      final streetRows = await db.query('streets', where: 'id = ?', whereArgs: [streetId]);
      if (streetRows.isNotEmpty) {
        final zoneId = streetRows.first['zone_id'] as String;
        await _syncService.pushMember(member.toMap(), streetId, zoneId);
      }
    }
  }

  Future<void> deleteMember(String id) async {
    final db = await _databaseHelper.database;
    // Look up hierarchy before deleting
    final memberRows = await db.query('members', where: 'id = ?', whereArgs: [id]);
    String? familyId;
    String? streetId;
    String? zoneId;
    if (memberRows.isNotEmpty) {
      familyId = memberRows.first['family_id'] as String?;
      if (familyId != null) {
        final familyRows = await db.query('families', where: 'id = ?', whereArgs: [familyId]);
        if (familyRows.isNotEmpty) {
          streetId = familyRows.first['street_id'] as String?;
          if (streetId != null) {
            final streetRows = await db.query('streets', where: 'id = ?', whereArgs: [streetId]);
            if (streetRows.isNotEmpty) {
              zoneId = streetRows.first['zone_id'] as String?;
            }
          }
        }
      }
    }
    await db.delete('members', where: 'id = ?', whereArgs: [id]);
    if (familyId != null && streetId != null && zoneId != null) {
      await _syncService.deleteMemberRemote(id, familyId, streetId, zoneId);
    }
  }
}
