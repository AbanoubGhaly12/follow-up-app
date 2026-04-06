import 'package:equatable/equatable.dart';

enum FollowupType { phone, visit, churchMeeting, onlineCall, other }

class FollowupModel extends Equatable {
  final String id;
  final String familyId;
  final String? familyName;
  final DateTime followupDate;
  final String notes;
  final FollowupType type;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FollowupModel({
    required this.id,
    required this.familyId,
    this.familyName,
    required this.followupDate,
    required this.notes,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    familyId,
    familyName,
    followupDate,
    notes,
    type,
    createdAt,
    updatedAt,
  ];

  factory FollowupModel.fromMap(Map<String, dynamic> map) {
    return FollowupModel(
      id: map['id'] as String,
      familyId: map['family_id'] as String,
      familyName: map['family_name'] as String?,
      followupDate: DateTime.parse(map['followup_date'] as String),
      notes: map['notes'] as String,
      type: FollowupType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => FollowupType.other,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'family_id': familyId,
      'family_name': familyName,
      'followup_date': followupDate.toIso8601String(),
      'notes': notes,
      'type': type.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FollowupModel copyWith({
    String? id,
    String? familyId,
    String? familyName,
    DateTime? followupDate,
    String? notes,
    FollowupType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FollowupModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      familyName: familyName ?? this.familyName,
      followupDate: followupDate ?? this.followupDate,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
