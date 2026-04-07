import 'dart:convert';
import 'package:equatable/equatable.dart';

class ZoneModel extends Equatable {
  final String id;
  final String name;
  final String tag;
  final String? description;
  final List<String> zoneAdmins;
  final String? adminUid;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ZoneModel({
    required this.id,
    required this.name,
    required this.tag,
    this.description,
    required this.zoneAdmins,
    this.adminUid,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    tag,
    description,
    zoneAdmins,
    adminUid,
    createdAt,
    updatedAt,
  ];

  factory ZoneModel.fromMap(Map<String, dynamic> map) {
    return ZoneModel(
      id: map['id'] as String,
      name: map['name'] as String,
      tag: map['tag'] as String,
      description: map['description'] as String?,
      zoneAdmins:
          (jsonDecode(map['zone_admins'] as String) as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      adminUid: map['admin_uid'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tag': tag,
      'description': description,
      'zone_admins': jsonEncode(zoneAdmins),
      'admin_uid': adminUid,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'tag': tag,
      'description': description,
      'zone_admins': zoneAdmins,
      'admin_uid': adminUid,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ZoneModel.fromFirestore(String id, Map<String, dynamic> map) {
    return ZoneModel(
      id: id,
      name: map['name'] as String? ?? '',
      tag: map['tag'] as String? ?? '',
      description: map['description'] as String?,
      zoneAdmins: List<String>.from(map['zone_admins'] as List? ?? []),
      adminUid: map['admin_uid'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  ZoneModel copyWith({
    String? id,
    String? name,
    String? tag,
    String? description,
    List<String>? zoneAdmins,
    String? adminUid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ZoneModel(
      id: id ?? this.id,
      name: name ?? this.name,
      tag: tag ?? this.tag,
      description: description ?? this.description,
      zoneAdmins: zoneAdmins ?? this.zoneAdmins,
      adminUid: adminUid ?? this.adminUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
