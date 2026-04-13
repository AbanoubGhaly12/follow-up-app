import 'dart:convert';
import 'package:equatable/equatable.dart';

enum MaritalStatus { single, married, divorced, widowed }

enum CollegeYear { PRESCHOOL, KG, PRIM, PREP, SEC, UNIV }

enum MemberRole { father, mother, child, member }

class MemberModel extends Equatable {
  final String id;
  final String familyId;
  final String name;
  final String tag;
  final bool isSynced;
  final bool isFamilyHead;
  final DateTime? birthdate;
  final String mobileNumber;
  final String email;
  final String confessionFather;
  final String confessionFatherChurchName;
  final String nationalId;
  final String belongToChurchName;
  final bool isDead;
  final DateTime? deathDate;
  final MaritalStatus maritalStatus;
  final CollegeYear collegeYear;
  final String profession;
  final List<String> weeklyOffDays;
  final MemberRole role;
  final bool isFollowedUpThisMonth;
  final bool isBirthdayFollowedUpThisYear;
  final bool isCondolenceFollowedUpThisYear;
  final DateTime? lastFollowupDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MemberModel({
    required this.id,
    required this.familyId,
    required this.name,
    this.tag = '',
    this.isSynced = true,
    this.isFamilyHead = false,
    this.birthdate,
    required this.mobileNumber,
    required this.email,
    required this.confessionFather,
    required this.confessionFatherChurchName,
    required this.nationalId,
    required this.belongToChurchName,
    required this.isDead,
    this.deathDate,
    required this.maritalStatus,
    required this.collegeYear,
    required this.profession,
    required this.weeklyOffDays,
    required this.role,
    this.isFollowedUpThisMonth = false,
    this.isBirthdayFollowedUpThisYear = false,
    this.isCondolenceFollowedUpThisYear = false,
    this.lastFollowupDate,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    familyId,
    name,
    tag,
    isSynced,
    isFamilyHead,
    birthdate,
    mobileNumber,
    email,
    confessionFather,
    confessionFatherChurchName,
    nationalId,
    belongToChurchName,
    isDead,
    deathDate,
    maritalStatus,
    collegeYear,
    profession,
    weeklyOffDays,
    role,
    isFollowedUpThisMonth,
    isBirthdayFollowedUpThisYear,
    isCondolenceFollowedUpThisYear,
    lastFollowupDate,
    createdAt,
    updatedAt,
  ];

  factory MemberModel.fromMap(Map<String, dynamic> map) {
    return MemberModel(
      id: map['id'] as String,
      familyId: map['family_id'] as String,
      name: map['name'] as String,
      tag: map['tag'] as String? ?? '',
      isSynced: (map['is_synced'] as int? ?? 1) == 1,
      isFamilyHead: (map['is_family_head'] as int? ?? 0) == 1,
      birthdate: map['birthdate'] != null && map['birthdate'].toString().isNotEmpty
          ? DateTime.tryParse(map['birthdate'] as String)
          : null,
      mobileNumber: map['mobile_number'] as String,
      email: map['email'] as String,
      confessionFather: map['confession_father'] as String,
      confessionFatherChurchName:
          map['confession_father_church_name'] as String,
      nationalId: map['national_id'] as String,
      belongToChurchName: map['belong_to_church_name'] as String,
      isDead: (map['is_dead'] as int) == 1,
      deathDate:
          map['death_date'] != null && map['death_date'].toString().isNotEmpty
              ? DateTime.parse(map['death_date'] as String)
              : null,
      maritalStatus: MaritalStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['marital_status'],
      ),
      collegeYear: CollegeYear.values.firstWhere(
        (e) => e.toString().split('.').last == map['college_year'],
      ),
      profession: map['profession'] as String,
      weeklyOffDays:
          (jsonDecode(map['weekly_off_days'] as String) as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      role: MemberRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
      ),
      isFollowedUpThisMonth: (map['is_followed_up_this_month'] as int? ?? 0) == 1,
      isBirthdayFollowedUpThisYear: (map['is_birthday_followed_up_this_year'] as int? ?? 0) == 1,
      isCondolenceFollowedUpThisYear: (map['is_condolence_followed_up_this_year'] as int? ?? 0) == 1,
      lastFollowupDate:
          map['last_followup_date'] != null
              ? DateTime.parse(map['last_followup_date'] as String)
              : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'family_id': familyId,
      'name': name,
      'tag': tag,
      'is_synced': isSynced ? 1 : 0,
      'is_family_head': isFamilyHead ? 1 : 0,
      'birthdate': birthdate?.toIso8601String() ?? '',
      'mobile_number': mobileNumber,
      'email': email,
      'confession_father': confessionFather,
      'confession_father_church_name': confessionFatherChurchName,
      'national_id': nationalId,
      'belong_to_church_name': belongToChurchName,
      'is_dead': isDead ? 1 : 0,
      'death_date': deathDate?.toIso8601String(),
      'marital_status': maritalStatus.toString().split('.').last,
      'college_year': collegeYear.toString().split('.').last,
      'profession': profession,
      'weekly_off_days': jsonEncode(weeklyOffDays),
      'role': role.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'family_id': familyId,
      'name': name,
      'tag': tag,
      'is_family_head': isFamilyHead,
      'birthdate': birthdate?.toIso8601String() ?? '',
      'mobile_number': mobileNumber,
      'email': email,
      'confession_father': confessionFather,
      'confession_father_church_name': confessionFatherChurchName,
      'national_id': nationalId,
      'belong_to_church_name': belongToChurchName,
      'is_dead': isDead,
      'death_date': deathDate?.toIso8601String(),
      'marital_status': maritalStatus.toString().split('.').last,
      'college_year': collegeYear.toString().split('.').last,
      'profession': profession,
      'weekly_off_days': weeklyOffDays,
      'role': role.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MemberModel.fromFirestore(String id, Map<String, dynamic> map) {
    return MemberModel(
      id: id,
      familyId: map['family_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      tag: map['tag'] as String? ?? '',
      isSynced: true,
      isFamilyHead: map['is_family_head'] == true || map['is_family_head'] == 1,
      birthdate: map['birthdate'] != null && map['birthdate'].toString().isNotEmpty
          ? DateTime.tryParse(map['birthdate'] as String)
          : null,
      mobileNumber: map['mobile_number'] as String? ?? '',
      email: map['email'] as String? ?? '',
      confessionFather: map['confession_father'] as String? ?? '',
      confessionFatherChurchName: map['confession_father_church_name'] as String? ?? '',
      nationalId: map['national_id'] as String? ?? '',
      belongToChurchName: map['belong_to_church_name'] as String? ?? '',
      isDead: map['is_dead'] == true || map['is_dead'] == 1,
      deathDate: map['death_date'] != null && map['death_date'].toString().isNotEmpty
          ? DateTime.parse(map['death_date'] as String)
          : null,
      maritalStatus: MaritalStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['marital_status'],
        orElse: () => MaritalStatus.single,
      ),
      collegeYear: CollegeYear.values.firstWhere(
        (e) => e.toString().split('.').last == map['college_year'],
        orElse: () => CollegeYear.PRIM,
      ),
      profession: map['profession'] as String? ?? '',
      weeklyOffDays: List<String>.from(map['weekly_off_days'] as List? ?? []),
      role: MemberRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => MemberRole.member,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  MemberModel copyWith({
    String? id,
    String? familyId,
    String? name,
    String? tag,
    bool? isSynced,
    bool? isFamilyHead,
    DateTime? birthdate,
    String? mobileNumber,
    String? email,
    String? confessionFather,
    String? confessionFatherChurchName,
    String? nationalId,
    String? belongToChurchName,
    bool? isDead,
    DateTime? deathDate,
    MaritalStatus? maritalStatus,
    CollegeYear? collegeYear,
    String? profession,
    List<String>? weeklyOffDays,
    MemberRole? role,
    bool? isFollowedUpThisMonth,
    bool? isBirthdayFollowedUpThisYear,
    bool? isCondolenceFollowedUpThisYear,
    DateTime? lastFollowupDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemberModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      tag: tag ?? this.tag,
      isSynced: isSynced ?? this.isSynced,
      isFamilyHead: isFamilyHead ?? this.isFamilyHead,
      birthdate: birthdate ?? this.birthdate,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      confessionFather: confessionFather ?? this.confessionFather,
      confessionFatherChurchName:
          confessionFatherChurchName ?? this.confessionFatherChurchName,
      nationalId: nationalId ?? this.nationalId,
      belongToChurchName: belongToChurchName ?? this.belongToChurchName,
      isDead: isDead ?? this.isDead,
      deathDate: deathDate ?? this.deathDate,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      collegeYear: collegeYear ?? this.collegeYear,
      profession: profession ?? this.profession,
      weeklyOffDays: weeklyOffDays ?? this.weeklyOffDays,
      role: role ?? this.role,
      isFollowedUpThisMonth:
          isFollowedUpThisMonth ?? this.isFollowedUpThisMonth,
      isBirthdayFollowedUpThisYear:
          isBirthdayFollowedUpThisYear ?? this.isBirthdayFollowedUpThisYear,
      isCondolenceFollowedUpThisYear:
          isCondolenceFollowedUpThisYear ?? this.isCondolenceFollowedUpThisYear,
      lastFollowupDate: lastFollowupDate ?? this.lastFollowupDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
