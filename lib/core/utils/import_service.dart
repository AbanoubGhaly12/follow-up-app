import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';
import '../../../features/zones/data/models/zone_model.dart';
import '../../../features/zones/data/repositories/zone_repository.dart';
import '../../../features/streets/data/models/street_model.dart';
import '../../../features/streets/data/repositories/street_repository.dart';
import '../../../features/families/data/models/family_model.dart';
import '../../../features/families/data/repositories/family_repository.dart';
import '../../../features/members/data/models/member_model.dart';
import '../../../features/members/data/repositories/member_repository.dart';

class ImportResult {
  final int successCount;
  final int skipCount;
  final List<String> errors;

  ImportResult(this.successCount, this.skipCount, this.errors);
}

class ImportService {
  final ZoneRepository _zoneRepository;
  final StreetRepository _streetRepository;
  final FamilyRepository _familyRepository;
  final MemberRepository _memberRepository;
  final _uuid = const Uuid();

  ImportService(
    this._zoneRepository,
    this._streetRepository,
    this._familyRepository,
    this._memberRepository,
  );

  /// Parses CSV and returns a list of maps (headers as keys)
  List<Map<String, dynamic>> _parseCsv(String csvContent) {
    List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);
    if (rows.isEmpty) return [];

    final headers = rows.first.map((e) => e.toString().trim()).toList();
    final dataRows = rows.skip(1);

    return dataRows.map((row) {
      final map = <String, dynamic>{};
      for (var i = 0; i < headers.length; i++) {
        if (i < row.length) {
          map[headers[i]] = row[i];
        } else {
          map[headers[i]] = null;
        }
      }
      return map;
    }).toList();
  }

  Future<ImportResult> importZones(String csvContent) async {
    final data = _parseCsv(csvContent);
    int success = 0;
    int skipped = 0;
    final errors = <String>[];

    for (var row in data) {
      try {
        final name = row['name']?.toString().trim();
        final tag = row['tag']?.toString().trim();
        if (name == null || name.isEmpty || tag == null || tag.isEmpty) {
          errors.add("Missing name or tag in row: $row");
          continue;
        }

        final now = DateTime.now();
        final zone = ZoneModel(
          id: _uuid.v4(),
          name: name,
          tag: tag,
          description: row['description']?.toString(),
          zoneAdmins: [],
          createdAt: now,
          updatedAt: now,
        );

        await _zoneRepository.addZone(zone);
        success++;
      } catch (e) {
        errors.add("Error importing zone: $e");
      }
    }

    return ImportResult(success, skipped, errors);
  }

  Future<ImportResult> importStreets(String csvContent) async {
    final data = _parseCsv(csvContent);
    int success = 0;
    final errors = <String>[];

    // Cache zones for tag lookup
    final zones = await _zoneRepository.getZones();
    final tagToId = {for (var z in zones) z.tag: z.id};

    for (var row in data) {
      try {
        final zoneTag = row['zone_tag']?.toString().trim();
        final name = row['name']?.toString().trim();

        if (zoneTag == null || name == null) {
          errors.add("Missing zone_tag or name in row: $row");
          continue;
        }

        final zoneId = tagToId[zoneTag];
        if (zoneId == null) {
          errors.add("Zone tag '$zoneTag' not found for street '$name'");
          continue;
        }

        final now = DateTime.now();
        final street = StreetModel(
          id: _uuid.v4(),
          zoneId: zoneId,
          name: name,
          createdAt: now,
          updatedAt: now,
        );

        await _streetRepository.insertStreet(street);
        success++;
      } catch (e) {
        errors.add("Error importing street: $e");
      }
    }

    return ImportResult(success, 0, errors);
  }

  Future<ImportResult> importFamilies(String csvContent) async {
    final data = _parseCsv(csvContent);
    int success = 0;
    final errors = <String>[];

    // Cache streets for name lookup (simple version, assuming unique names across zones if possible, 
    // or better use a more specific lookup)
    final streets = await _streetRepository.getAllStreets();
    final streetToId = {for (var s in streets) s.name: s.id};

    for (var row in data) {
      try {
        final streetName = row['street_name']?.toString().trim();
        final head = row['family_head']?.toString().trim();

        if (streetName == null || head == null) {
          errors.add("Missing street_name or family_head in row: $row");
          continue;
        }

        final streetId = streetToId[streetName];
        if (streetId == null) {
          errors.add("Street '$streetName' not found for family '$head'");
          continue;
        }

        final now = DateTime.now();
        final family = FamilyModel(
          id: _uuid.v4(),
          streetId: streetId,
          familyHead: head,
          landline: row['landline']?.toString() ?? '',
          marriageDate: _parseDate(row['marriage_date']),
          addressInfo: AddressInfo(
            street: streetName,
            buildingNumber: row['building_number']?.toString() ?? '',
            floorNumber: row['floor_number']?.toString() ?? '',
            flatNumber: row['flat_number']?.toString() ?? '',
            streetFrom: row['street_from']?.toString() ?? '',
          ),
          createdAt: now,
          updatedAt: now,
        );

        await _familyRepository.addFamily(family);
        success++;
      } catch (e) {
        errors.add("Error importing family: $e");
      }
    }

    return ImportResult(success, 0, errors);
  }

  Future<ImportResult> importMembers(String csvContent) async {
    final data = _parseCsv(csvContent);
    int success = 0;
    final errors = <String>[];

    // To link members, we search families by head name
    final families = await _familyRepository.getAllFamilies();
    final headToFamilyId = {for (var f in families) f.familyHead: f.id};

    for (var row in data) {
      try {
        final headName = row['family_head_name']?.toString().trim();
        final name = row['name']?.toString().trim();

        if (headName == null || name == null) {
          errors.add("Missing family_head_name or name in row: $row");
          continue;
        }

        final familyId = headToFamilyId[headName];
        if (familyId == null) {
          errors.add("Family with head '$headName' not found for member '$name'");
          continue;
        }

        final now = DateTime.now();
        final member = MemberModel(
          id: _uuid.v4(),
          familyId: familyId,
          name: name,
          birthdate: _parseDate(row['birthdate'], defaultDate: now),
          mobileNumber: row['mobile_number']?.toString() ?? '',
          email: row['email']?.toString() ?? '',
          confessionFather: row['confession_father']?.toString() ?? '',
          confessionFatherChurchName: row['confession_father_church']?.toString() ?? '',
          nationalId: row['national_id']?.toString() ?? '',
          belongToChurchName: row['belong_to_church']?.toString() ?? '',
          isDead: _parseBool(row['is_dead']),
          maritalStatus: _parseMaritalStatus(row['marital_status']),
          collegeYear: _parseCollegeYear(row['college_year']),
          profession: row['profession']?.toString() ?? '',
          weeklyOffDays: [],
          role: _parseMemberRole(row['role']),
          createdAt: now,
          updatedAt: now,
        );

        await _memberRepository.addMember(member);
        success++;
      } catch (e) {
        errors.add("Error importing member: $e");
      }
    }

    return ImportResult(success, 0, errors);
  }

  DateTime _parseDate(dynamic value, {DateTime? defaultDate}) {
    if (value == null || value.toString().isEmpty) return defaultDate ?? DateTime.now();
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      // Handle DD/MM/YYYY if needed, but for now stick to ISO
      return defaultDate ?? DateTime.now();
    }
  }

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    final s = value.toString().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  MaritalStatus _parseMaritalStatus(dynamic value) {
    final s = value?.toString().toLowerCase() ?? '';
    return MaritalStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => MaritalStatus.single,
    );
  }

  CollegeYear _parseCollegeYear(dynamic value) {
    final s = value?.toString().toUpperCase() ?? '';
    return CollegeYear.values.firstWhere(
      (e) => e.name == s,
      orElse: () => CollegeYear.UNIV,
    );
  }

  MemberRole _parseMemberRole(dynamic value) {
    final s = value?.toString().toLowerCase() ?? '';
    return MemberRole.values.firstWhere(
      (e) => e.name == s,
      orElse: () => MemberRole.basic_member,
    );
  }
}
