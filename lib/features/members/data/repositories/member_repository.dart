import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/member_model.dart';

class MemberRepository {
  final DatabaseHelper _databaseHelper;

  MemberRepository(this._databaseHelper);

  Future<List<MemberModel>> getMembersByFamily(String familyId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'members',
      where: 'family_id = ?',
      whereArgs: [familyId],
    );
    return List.generate(maps.length, (i) {
      return MemberModel.fromMap(maps[i]);
    });
  }

  Future<List<MemberModel>> getAllMembers() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('members');
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
