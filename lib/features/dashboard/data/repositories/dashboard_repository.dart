import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';

class DashboardStats {
  final int totalZones;
  final int totalStreets;
  final int totalFamilies;
  final int totalMembers;

  DashboardStats({
    required this.totalZones,
    required this.totalStreets,
    required this.totalFamilies,
    required this.totalMembers,
  });
}

class DashboardRepository {
  final DatabaseHelper _dbHelper;

  DashboardRepository(this._dbHelper);

  Future<DashboardStats> getStats() async {
    final db = await _dbHelper.database;

    final zonesCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM zones'),
        ) ??
        0;
    final streetsCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM streets'),
        ) ??
        0;
    final familiesCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM families'),
        ) ??
        0;
    final membersCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM members'),
        ) ??
        0;

    return DashboardStats(
      totalZones: zonesCount,
      totalStreets: streetsCount,
      totalFamilies: familiesCount,
      totalMembers: membersCount,
    );
  }
}
