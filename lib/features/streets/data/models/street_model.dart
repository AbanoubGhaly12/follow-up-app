import 'package:equatable/equatable.dart';

class StreetModel extends Equatable {
  final String id;
  final String zoneId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StreetModel({
    required this.id,
    required this.zoneId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, zoneId, name, createdAt, updatedAt];

  factory StreetModel.fromMap(Map<String, dynamic> map) {
    return StreetModel(
      id: map['id'] as String,
      zoneId: map['zone_id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  StreetModel copyWith({
    String? id,
    String? zoneId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StreetModel(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
