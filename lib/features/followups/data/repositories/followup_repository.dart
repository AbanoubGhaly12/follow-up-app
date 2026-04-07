import '../../../../core/database/database_helper.dart';
import '../../../../core/sync/firestore_sync_service.dart';
import '../models/followup_model.dart';
import 'package:sqflite/sqflite.dart';

class FollowupRepository {
  final DatabaseHelper _dbHelper;
  final FirestoreSyncService _syncService;

  FollowupRepository(this._dbHelper, this._syncService);

  Future<void> _syncFollowups() async {
    final db = await _dbHelper.database;
    final remoteFollowups = await _syncService.fetchFollowups();
    if (remoteFollowups.isNotEmpty) {
      for (var followupData in remoteFollowups) {
        await db.insert(
          'followups',
          followupData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  Future<List<FollowupModel>> getFollowupsByFamilyId(String familyId, {bool forceSync = false}) async {
    final db = await _dbHelper.database;
    
    if (forceSync) {
      await _syncFollowups();
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'followups',
      where: 'family_id = ?',
      whereArgs: [familyId],
      orderBy: 'followup_date DESC',
    );

    if (maps.isEmpty && !forceSync) {
      await _syncFollowups();
      // Re-query after sync
      final syncMaps = await db.query(
        'followups',
        where: 'family_id = ?',
        whereArgs: [familyId],
        orderBy: 'followup_date DESC',
      );
      return syncMaps.map((f) => FollowupModel.fromMap(f)).toList();
    }

    return List.generate(maps.length, (i) => FollowupModel.fromMap(maps[i]));
  }

  Future<void> insertFollowup(FollowupModel followup) async {
    final db = await _dbHelper.database;
    await db.insert(
      'followups',
      followup.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _syncService.pushFollowup(followup.toMap());
  }

  Future<void> deleteFollowup(String id) async {
    final db = await _dbHelper.database;
    await db.delete('followups', where: 'id = ?', whereArgs: [id]);
    await _syncService.deleteFollowupRemote(id);
  }

  Future<List<FollowupModel>> getFollowupsReport({
    DateTime? date,
    FollowupType? type,
    String? zoneId,
    String? streetId,
    int? inactivityMonths,
    bool? isFamilyReport,
    bool forceSync = false,
  }) async {
    final db = await _dbHelper.database;
    
    if (forceSync) {
      await _syncFollowups();
    }
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (inactivityMonths != null) {
      if (streetId != null) {
        whereClause += "fams.street_id = ? ";
        whereArgs.add(streetId);
      } else if (zoneId != null) {
        whereClause += "s.zone_id = ? ";
        whereArgs.add(zoneId);
      }

      if (isFamilyReport == true) {
        final String inactivityCondition =
            inactivityMonths == -1
                ? "(SELECT COUNT(*) FROM followups WHERE family_id = fams.id AND member_id IS NULL) = 0"
                : '''
          (SELECT COUNT(*) FROM followups 
           WHERE family_id = fams.id AND member_id IS NULL
           AND followup_date > date('now', '-$inactivityMonths month')) = 0
          ''';

        final String query = '''
          SELECT fams.id as family_id, fams.family_head as family_name,
                 (SELECT MAX(followup_date) FROM followups WHERE family_id = fams.id AND member_id IS NULL) as last_date
          FROM families fams
          JOIN streets s ON fams.street_id = s.id
          WHERE $inactivityCondition
          ${whereClause.isNotEmpty ? 'AND $whereClause' : ''}
          ORDER BY last_date DESC
        ''';

        final List<Map<String, dynamic>> maps = await db.rawQuery(
          query,
          whereArgs,
        );
        
        if (maps.isEmpty && !forceSync) {
           await _syncFollowups();
           // Re-query after sync
           final refreshedMaps = await db.rawQuery(query, whereArgs);
           return List.generate(refreshedMaps.length, (i) {
             final lastDateStr = refreshedMaps[i]['last_date'] as String?;
             return _buildNeglectModel(refreshedMaps[i], lastDateStr);
           });
        }
        
        return List.generate(maps.length, (i) {
          final lastDateStr = maps[i]['last_date'] as String?;
          return _buildNeglectModel(maps[i], lastDateStr);
        });
      } else {
        // Member-level neglect
        final String inactivityCondition =
            inactivityMonths == -1
                ? "(SELECT COUNT(*) FROM followups WHERE member_id = m.id) = 0"
                : '''
          (SELECT COUNT(*) FROM followups 
           WHERE member_id = m.id
           AND followup_date > date('now', '-$inactivityMonths month')) = 0
          ''';

        final String query = '''
          SELECT m.id as member_id, m.name as member_name, fams.id as family_id, fams.family_head as family_name,
                 (SELECT MAX(followup_date) FROM followups WHERE member_id = m.id) as last_date
          FROM members m
          JOIN families fams ON m.family_id = fams.id
          JOIN streets s ON fams.street_id = s.id
          WHERE $inactivityCondition
          ${whereClause.isNotEmpty ? 'AND $whereClause' : ''}
          ORDER BY last_date DESC
        ''';

        final List<Map<String, dynamic>> maps = await db.rawQuery(
          query,
          whereArgs,
        );
        
        if (maps.isEmpty && !forceSync) {
           await _syncFollowups();
           // Re-query after sync
           final refreshedMaps = await db.rawQuery(query, whereArgs);
           return List.generate(refreshedMaps.length, (i) {
             final lastDateStr = refreshedMaps[i]['last_date'] as String?;
             return _buildNeglectModel(refreshedMaps[i], lastDateStr);
           });
        }
        
        return List.generate(maps.length, (i) {
          final lastDateStr = maps[i]['last_date'] as String?;
          return _buildNeglectModel(maps[i], lastDateStr);
        });
      }
    }

    // Standard report filtering
    if (isFamilyReport != null) {
      whereClause +=
          isFamilyReport ? "f.member_id IS NULL " : "f.member_id IS NOT NULL ";
    }

    if (date != null) {
      if (whereClause.isNotEmpty) whereClause += "AND ";
      whereClause += "strftime('%Y-%m-%d', f.followup_date) = ? ";
      whereArgs.add(date.toIso8601String().substring(0, 10));
    }

    if (type != null) {
      if (whereClause.isNotEmpty) whereClause += "AND ";
      whereClause += "f.type = ? ";
      whereArgs.add(type.toString().split('.').last);
    }

    if (streetId != null) {
      if (whereClause.isNotEmpty) whereClause += "AND ";
      whereClause += "fam.street_id = ? ";
      whereArgs.add(streetId);
    } else if (zoneId != null) {
      if (whereClause.isNotEmpty) whereClause += "AND ";
      whereClause += "s.zone_id = ? ";
      whereArgs.add(zoneId);
    }

    final String query = '''
      SELECT f.*, fam.family_head as family_name, m.name as member_name
      FROM followups f
      JOIN families fam ON f.family_id = fam.id
      LEFT JOIN members m ON f.member_id = m.id
      JOIN streets s ON fam.street_id = s.id
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      ORDER BY f.followup_date DESC
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);

    if (maps.isEmpty && inactivityMonths == null && !forceSync) {
      await _syncFollowups();
      // Re-run the local query after sync to return filtered result
      final updatedMaps = await db.rawQuery(query, whereArgs);
      return List.generate(
        updatedMaps.length,
        (i) => FollowupModel.fromMap(updatedMaps[i]),
      );
    }

    return List.generate(maps.length, (i) => FollowupModel.fromMap(maps[i]));
  }

  FollowupModel _buildNeglectModel(Map<String, dynamic> map, String? lastDateStr) {
    final bool isMember = map.containsKey('member_id');
    return FollowupModel(
      id: isMember ? 'neglect_mem_${map['member_id']}' : 'neglect_fam_${map['family_id']}',
      familyId: map['family_id'] as String,
      familyName: map['family_name'] as String,
      memberId: isMember ? map['member_id'] as String : null,
      memberName: isMember ? map['member_name'] as String : null,
      type: FollowupType.other,
      followupDate: lastDateStr != null ? DateTime.parse(lastDateStr) : DateTime(2000),
      notes: lastDateStr ?? 'NEVER',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
