import 'package:equatable/equatable.dart';

class AddressInfo extends Equatable {
  final String street;
  final String buildingNumber;
  final String floorNumber;
  final String flatNumber;
  final String streetFrom;

  const AddressInfo({
    required this.street,
    required this.buildingNumber,
    required this.floorNumber,
    required this.flatNumber,
    required this.streetFrom,
  });

  @override
  List<Object> get props => [
    street,
    buildingNumber,
    floorNumber,
    flatNumber,
    streetFrom,
  ];
}

class FamilyModel extends Equatable {
  final String id;
  final String streetId;
  final String familyHead;
  final DateTime? marriageDate;
  final String landline;
  final AddressInfo addressInfo;
  final bool isFollowedUpThisMonth;
  final DateTime? lastFollowupDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FamilyModel({
    required this.id,
    required this.streetId,
    this.familyHead = '',
    this.marriageDate,
    required this.landline,
    required this.addressInfo,
    this.isFollowedUpThisMonth = false,
    this.lastFollowupDate,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    streetId,
    familyHead,
    marriageDate,
    landline,
    addressInfo,
    isFollowedUpThisMonth,
    lastFollowupDate,
    createdAt,
    updatedAt,
  ];

  factory FamilyModel.fromMap(Map<String, dynamic> map) {
    return FamilyModel(
      id: map['id'] as String,
      streetId: map['street_id'] as String,
      familyHead: map['family_head'] as String? ?? '',
      marriageDate:
          map['marriage_date'] != null
              ? DateTime.parse(map['marriage_date'] as String)
              : null,
      landline: map['landline'] as String,
      addressInfo: AddressInfo(
        street: map['street'] as String? ?? '',
        buildingNumber: map['building_number'] as String? ?? '',
        floorNumber: map['floor_number'] as String? ?? '',
        flatNumber: map['flat_number'] as String? ?? '',
        streetFrom: map['street_from'] as String? ?? '',
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
      'street_id': streetId,
      'family_head': familyHead,
      'marriage_date': marriageDate?.toIso8601String(),
      'landline': landline,
      'street': addressInfo.street,
      'building_number': addressInfo.buildingNumber,
      'floor_number': addressInfo.floorNumber,
      'flat_number': addressInfo.flatNumber,
      'street_from': addressInfo.streetFrom,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'street_id': streetId,
      'family_head': familyHead,
      'marriage_date': marriageDate?.toIso8601String(),
      'landline': landline,
      'street': addressInfo.street,
      'building_number': addressInfo.buildingNumber,
      'floor_number': addressInfo.floorNumber,
      'flat_number': addressInfo.flatNumber,
      'street_from': addressInfo.streetFrom,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory FamilyModel.fromFirestore(String id, Map<String, dynamic> map) {
    return FamilyModel(
      id: id,
      streetId: map['street_id'] as String? ?? '',
      familyHead: map['family_head'] as String? ?? '',
      marriageDate: map['marriage_date'] != null
          ? DateTime.parse(map['marriage_date'] as String)
          : null,
      landline: map['landline'] as String? ?? '',
      addressInfo: AddressInfo(
        street: map['street'] as String? ?? '',
        buildingNumber: map['building_number'] as String? ?? '',
        floorNumber: map['floor_number'] as String? ?? '',
        flatNumber: map['flat_number'] as String? ?? '',
        streetFrom: map['street_from'] as String? ?? '',
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  FamilyModel copyWith({
    String? id,
    String? streetId,
    String? familyHead,
    DateTime? marriageDate,
    String? landline,
    AddressInfo? addressInfo,
    bool? isFollowedUpThisMonth,
    DateTime? lastFollowupDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyModel(
      id: id ?? this.id,
      streetId: streetId ?? this.streetId,
      familyHead: familyHead ?? this.familyHead,
      marriageDate: marriageDate ?? this.marriageDate,
      landline: landline ?? this.landline,
      addressInfo: addressInfo ?? this.addressInfo,
      isFollowedUpThisMonth:
          isFollowedUpThisMonth ?? this.isFollowedUpThisMonth,
      lastFollowupDate: lastFollowupDate ?? this.lastFollowupDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
