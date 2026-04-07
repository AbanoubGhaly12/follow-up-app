import 'dart:convert';

import 'package:equatable/equatable.dart';

enum UserRole {
  superAdmin,
  subAdmin,
  member
}

class AppUserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String? parentAdminUid;
  final UserRole role;
  final List<String> managedZoneIds;
  final DateTime createdAt;

  const AppUserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.parentAdminUid,
    required this.role,
    this.managedZoneIds = const [],
    required this.createdAt,
  });

  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isSubAdmin => role == UserRole.subAdmin;
  bool get isMember => role == UserRole.member;

  @override
  List<Object?> get props => [uid, name, email, parentAdminUid, role, managedZoneIds, createdAt];

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'parent_admin_uid': parentAdminUid,
      'role': role.toString().split('.').last,
      'managed_zone_ids': jsonEncode(managedZoneIds),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      parentAdminUid: map['parent_admin_uid'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => UserRole.member,
      ),
      managedZoneIds: map['managed_zone_ids'] != null
          ? (jsonDecode(map['managed_zone_ids'] as String) as List<dynamic>)
              .map((e) => e as String)
              .toList()
          : [],
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'parent_admin_uid': parentAdminUid,
      'role': role.toString().split('.').last,
      'managed_zone_ids': managedZoneIds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppUserModel.fromFirestore(String uid, Map<String, dynamic> map) {
    return AppUserModel(
      uid: uid,
      name: map['name'] as String,
      email: map['email'] as String,
      parentAdminUid: map['parent_admin_uid'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => UserRole.member,
      ),
      managedZoneIds: List<String>.from(map['managed_zone_ids'] as List? ?? []),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  AppUserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? parentAdminUid,
    UserRole? role,
    List<String>? managedZoneIds,
    DateTime? createdAt,
  }) {
    return AppUserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      parentAdminUid: parentAdminUid ?? this.parentAdminUid,
      role: role ?? this.role,
      managedZoneIds: managedZoneIds ?? this.managedZoneIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
