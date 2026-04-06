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
  }) async {
    final db = await _dbHelper.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (date != null) {
      whereClause += "strftime('%Y-%m-%d', f.followup_date) = ? ";
      whereArgs.add(date.toIso8601String().substring(0, 10));
    }

    if (type != null) {
      if (whereClause.isNotEmpty) whereClause += "AND ";
      whereClause += "f.type = ? ";
      whereArgs.add(type.toString().split('.').last);
    }

    final String query = '''
      SELECT f.*, fam.family_head as family_name
      FROM followups f
      JOIN families fam ON f.family_id = fam.id
      ${whereClause.isNotEmpty ? 'WHERE ' + whereClause : ''}
      ORDER BY f.followup_date DESC
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);
    return List.generate(maps.length, (i) => FollowupModel.fromMap(maps[i]));
  }
}
