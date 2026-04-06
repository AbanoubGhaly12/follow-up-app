import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/member_model.dart';

class MemberRepository {
  final DatabaseHelper _databaseHelper;

  MemberRepository(this._databaseHelper);

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
  }

  Future<void> updateMember(MemberModel member) async {
    final db = await _databaseHelper.database;
    await db.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<void> deleteMember(String id) async {
    final db = await _databaseHelper.database;
    await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }
}
