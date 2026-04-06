import '../../../../core/database/database_helper.dart';
import '../models/followup_model.dart';
import 'package:sqflite/sqflite.dart';

class FollowupRepository {
  final DatabaseHelper _dbHelper;

  FollowupRepository(this._dbHelper);

  Future<List<FollowupModel>> getFollowupsByFamilyId(String familyId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'followups',
      where: 'family_id = ?',
      whereArgs: [familyId],
      orderBy: 'followup_date DESC',
    );
    return List.generate(maps.length, (i) => FollowupModel.fromMap(maps[i]));
  }

  Future<void> insertFollowup(FollowupModel followup) async {
    final db = await _dbHelper.database;
    await db.insert(
      'followups',
      followup.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteFollowup(String id) async {
    final db = await _dbHelper.database;
    await db.delete('followups', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FollowupModel>> getFollowupsReport({
    DateTime? date,
    FollowupType? type,
    String? zoneId,
    String? streetId,
    int? inactivityMonths,
    bool? isFamilyReport,
  }) async {
    final db = await _dbHelper.database;
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
        return List.generate(maps.length, (i) {
          final lastDateStr = maps[i]['last_date'] as String?;
          return FollowupModel(
            id: 'neglect_fam_${maps[i]['family_id']}',
            familyId: maps[i]['family_id'] as String,
            familyName: maps[i]['family_name'] as String,
            type: FollowupType.other,
            followupDate:
                lastDateStr != null
                    ? DateTime.parse(lastDateStr)
                    : DateTime(2000),
            notes: lastDateStr ?? 'NEVER',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
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
        return List.generate(maps.length, (i) {
          final lastDateStr = maps[i]['last_date'] as String?;
          return FollowupModel(
            id: 'neglect_mem_${maps[i]['member_id']}',
            familyId: maps[i]['family_id'] as String,
            familyName: maps[i]['family_name'] as String,
            memberId: maps[i]['member_id'] as String,
            memberName: maps[i]['member_name'] as String,
            type: FollowupType.other,
            followupDate:
                lastDateStr != null
                    ? DateTime.parse(lastDateStr)
                    : DateTime(2000),
            notes: lastDateStr ?? 'NEVER',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
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
    return List.generate(maps.length, (i) => FollowupModel.fromMap(maps[i]));
  }
}
