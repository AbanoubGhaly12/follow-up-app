import 'dart:convert';
import 'package:equatable/equatable.dart';

class ZoneModel extends Equatable {
  final String id;
  final String name;
  final String tag;
  final String? description;
  final List<String> zoneAdmins;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ZoneModel({
    required this.id,
    required this.name,
    required this.tag,
    this.description,
    required this.zoneAdmins,
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ZoneModel copyWith({
    String? id,
    String? name,
    String? tag,
    String? description,
    List<String>? zoneAdmins,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ZoneModel(
      id: id ?? this.id,
      name: name ?? this.name,
      tag: tag ?? this.tag,
      description: description ?? this.description,
      zoneAdmins: zoneAdmins ?? this.zoneAdmins,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
