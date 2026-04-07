import 'dart:convert';
import 'package:equatable/equatable.dart';

enum MaritalStatus { single, married, divorced, widowed }

enum CollegeYear { PRESCHOOL, KG, PRIM, PREP, SEC, UNIV }

enum MemberRole { father, mother, child, basic_member }

class MemberModel extends Equatable {
  final String id;
  final String familyId;
  final String name;
  final DateTime birthdate;
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
  final DateTime? lastFollowupDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MemberModel({
    required this.id,
    required this.familyId,
    required this.name,
    required this.birthdate,
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
    this.lastFollowupDate,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    familyId,
    name,
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
    lastFollowupDate,
    createdAt,
    updatedAt,
  ];

  factory MemberModel.fromMap(Map<String, dynamic> map) {
    return MemberModel(
      id: map['id'] as String,
      familyId: map['family_id'] as String,
      name: map['name'] as String,
      birthdate: DateTime.parse(map['birthdate'] as String),
      mobileNumber: map['mobile_number'] as String,
      email: map['email'] as String,
      confessionFather: map['confession_father'] as String,
      confessionFatherChurchName:
          map['confession_father_church_name'] as String,
      nationalId: map['national_id'] as String,
      belongToChurchName: map['belong_to_church_name'] as String,
      isDead: (map['is_dead'] as int) == 1,
      deathDate:
          map['death_date'] != null
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
      'birthdate': birthdate.toIso8601String(),
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
      'birthdate': birthdate.toIso8601String(),
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
      birthdate: DateTime.parse(map['birthdate'] as String),
      mobileNumber: map['mobile_number'] as String? ?? '',
      email: map['email'] as String? ?? '',
      confessionFather: map['confession_father'] as String? ?? '',
      confessionFatherChurchName: map['confession_father_church_name'] as String? ?? '',
      nationalId: map['national_id'] as String? ?? '',
      belongToChurchName: map['belong_to_church_name'] as String? ?? '',
      isDead: map['is_dead'] == true || map['is_dead'] == 1,
      deathDate: map['death_date'] != null
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
        orElse: () => MemberRole.basic_member,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  MemberModel copyWith({
    String? id,
    String? familyId,
    String? name,
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
    DateTime? lastFollowupDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemberModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
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
      lastFollowupDate: lastFollowupDate ?? this.lastFollowupDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
