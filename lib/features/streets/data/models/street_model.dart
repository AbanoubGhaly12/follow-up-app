import 'package:equatable/equatable.dart';

class StreetModel extends Equatable {
  final String id;
  final String zoneId;
  final String name;
  final String tag;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StreetModel({
    required this.id,
    required this.zoneId,
    required this.name,
    this.tag = '',
    this.isSynced = true, // Defaults to true for legacy rows
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, zoneId, name, tag, isSynced, createdAt, updatedAt];

  factory StreetModel.fromMap(Map<String, dynamic> map) {
    return StreetModel(
      id: map['id'] as String,
      zoneId: map['zone_id'] as String,
      name: map['name'] as String,
      tag: map['tag'] as String? ?? '',
      isSynced: (map['is_synced'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'name': name,
      'tag': tag,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'zone_id': zoneId,
      'name': name,
      'tag': tag,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StreetModel.fromFirestore(String id, Map<String, dynamic> map) {
    return StreetModel(
      id: id,
      zoneId: map['zone_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      tag: map['tag'] as String? ?? '',
      isSynced: true, // If it's coming from Firestore, it's inherently synced
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  StreetModel copyWith({
    String? id,
    String? zoneId,
    String? name,
    String? tag,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StreetModel(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      name: name ?? this.name,
      tag: tag ?? this.tag,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
