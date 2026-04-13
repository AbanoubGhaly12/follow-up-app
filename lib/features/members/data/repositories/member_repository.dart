import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/sync/firestore_sync_service.dart';
import '../models/member_model.dart';
import 'dart:convert';

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
        (SELECT COUNT(*) FROM followups 
         WHERE member_id = m.id 
         AND type = 'birthday'
         AND strftime('%Y', followup_date) = strftime('%Y', 'now')) > 0 as is_birthday_followed_up_this_year,
        (SELECT COUNT(*) FROM followups 
         WHERE member_id = m.id 
         AND type = 'condolence'
         AND strftime('%Y', followup_date) = strftime('%Y', 'now')) > 0 as is_condolence_followed_up_this_year,
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
            final memberModel = MemberModel.fromFirestore(memberData['id'], memberData);
            await db.insert(
              'members',
              memberModel.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          return remoteMembers.map((m) => MemberModel.fromFirestore(m['id'], m)).toList();
        }
      }
    }

    return List.generate(maps.length, (i) {
      return MemberModel.fromMap(maps[i]);
    });
  }

  Future<void> addMember(MemberModel member) async {
    final db = await _databaseHelper.database;
    
    if (member.tag.trim().isNotEmpty) {
      final existing = await db.query(
        'members',
        where: 'tag = ? AND family_id = ?',
        whereArgs: [member.tag, member.familyId],
      );
      if (existing.isNotEmpty) {
        throw Exception('Member with this tag already exists in this family.');
      }
    }

    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
    
    String streetId = '';
    String zoneId = '';
    
    final familyRows = await db.query('families', where: 'id = ?', whereArgs: [member.familyId]);
    if (familyRows.isNotEmpty) {
      streetId = familyRows.first['street_id'] as String;
      final streetRows = await db.query('streets', where: 'id = ?', whereArgs: [streetId]);
      if (streetRows.isNotEmpty) {
        zoneId = streetRows.first['zone_id'] as String;
      }
    }
    
    if (isOnline && member.tag.trim().isNotEmpty && zoneId.isNotEmpty && streetId.isNotEmpty) {
      final remoteExists = await _syncService.doesMemberTagExist(member.tag, zoneId, streetId, member.familyId);
      if (remoteExists) {
        throw Exception('Member with this tag already exists in Cloud.');
      }
    }

    final finalMember = member.copyWith(isSynced: isOnline);

    await db.insert(
      'members',
      finalMember.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    if (isOnline && zoneId.isNotEmpty && streetId.isNotEmpty) {
      await _syncService.pushMember(finalMember.toFirestore()..['id'] = finalMember.id, streetId, zoneId);
    }
  }

  Future<void> updateMember(MemberModel member) async {
    final db = await _databaseHelper.database;
    
    if (member.tag.trim().isNotEmpty) {
      final existing = await db.query(
        'members',
        where: 'tag = ? AND family_id = ? AND id != ?',
        whereArgs: [member.tag, member.familyId, member.id],
      );
      if (existing.isNotEmpty) {
        throw Exception('Member with this tag already exists in this family.');
      }
    }

    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
    
    String streetId = '';
    String zoneId = '';
    
    final familyRows = await db.query('families', where: 'id = ?', whereArgs: [member.familyId]);
    if (familyRows.isNotEmpty) {
      streetId = familyRows.first['street_id'] as String;
      final streetRows = await db.query('streets', where: 'id = ?', whereArgs: [streetId]);
      if (streetRows.isNotEmpty) {
        zoneId = streetRows.first['zone_id'] as String;
      }
    }

    final finalMember = member.copyWith(isSynced: isOnline);

    await db.update(
      'members',
      finalMember.toMap(),
      where: 'id = ?',
      whereArgs: [finalMember.id],
    );
    
    if (isOnline && zoneId.isNotEmpty && streetId.isNotEmpty) {
      await _syncService.pushMember(finalMember.toFirestore()..['id'] = finalMember.id, streetId, zoneId);
    }
  }

  Future<void> deleteMember(String id) async {
    final db = await _databaseHelper.database;
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

  Future<void> importMembersFromCsv(List<Map<String, dynamic>> csvData) async {
    final db = await _databaseHelper.database;
    
    for (var row in csvData) {
      final familyTag = row['family_tag']?.toString().trim();
      if (familyTag == null || familyTag.isEmpty) {
        continue; // Skip if no family tag
      }
      
      final familyRows = await db.query('families', where: 'tag = ?', whereArgs: [familyTag]);
      if (familyRows.isEmpty) {
        continue; // Skip if family tag isn't matched locally
      }
      
      final familyId = familyRows.first['id'] as String;
      
      String? parsedBirthdateStr = row['birthdate']?.toString();
      DateTime? bdate;
      if (parsedBirthdateStr != null && parsedBirthdateStr.isNotEmpty) {
        bdate = DateTime.tryParse(parsedBirthdateStr);
      }
      
      final member = MemberModel(
        id: const Uuid().v4(),
        familyId: familyId,
        name: row['name']?.toString() ?? 'Unnamed',
        tag: row['tag']?.toString() ?? '',
        birthdate: bdate,
        mobileNumber: row['mobile_number']?.toString() ?? '',
        email: row['email']?.toString() ?? '',
        confessionFather: row['confession_father']?.toString() ?? '',
        confessionFatherChurchName: row['confession_father_church_name']?.toString() ?? '',
        nationalId: row['national_id']?.toString() ?? '',
        belongToChurchName: row['belong_to_church_name']?.toString() ?? '',
        isDead: row['is_dead']?.toString().toLowerCase() == 'true' || row['is_dead'] == '1',
        isFamilyHead: row['is_family_head']?.toString().toLowerCase() == 'true' || row['is_family_head'] == '1',
        maritalStatus: MaritalStatus.single,
        collegeYear: CollegeYear.PRIM,
        profession: row['profession']?.toString() ?? '',
        weeklyOffDays: const [],
        role: MemberRole.member,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      
      try {
        await addMember(member);
      } catch (e) {
        if (!e.toString().contains('already exists')) {
          rethrow;
        }
      }
    }
  }

  Future<void> syncOfflineMembers() async {
    final db = await _databaseHelper.database;
    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
    
    if (!isOnline) {
      throw Exception('network_unavailable');
    }
    
    final List<Map<String, dynamic>> offlineMaps = await db.query(
      'members',
      where: 'is_synced = ? OR is_synced IS NULL',
      whereArgs: [0],
    );
    
    for (var map in offlineMaps) {
      var member = MemberModel.fromMap(map);
      
      String streetId = '';
      String zoneId = '';
      
      final familyRows = await db.query('families', where: 'id = ?', whereArgs: [member.familyId]);
      if (familyRows.isNotEmpty) {
        streetId = familyRows.first['street_id'] as String;
        final streetRows = await db.query('streets', where: 'id = ?', whereArgs: [streetId]);
        if (streetRows.isNotEmpty) {
          zoneId = streetRows.first['zone_id'] as String;
        }
      }
      
      if (zoneId.isEmpty || streetId.isEmpty) continue;
      
      final remoteExists = await _syncService.doesMemberTagExist(member.tag, zoneId, streetId, member.familyId);
      if (remoteExists) {
        await db.delete('members', where: 'id = ?', whereArgs: [member.id]);
        continue;
      }
      
      member = member.copyWith(isSynced: true);
      
      await _syncService.pushMember(member.toFirestore()..['id'] = member.id, streetId, zoneId);
      
      await db.update(
        'members',
        member.toMap(),
        where: 'id = ?',
        whereArgs: [member.id],
      );
    }
  }
}
