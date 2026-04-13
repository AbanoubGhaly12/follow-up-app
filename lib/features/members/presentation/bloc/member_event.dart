part of 'member_bloc.dart';

abstract class MemberEvent extends Equatable {
  const MemberEvent();

  @override
  List<Object?> get props => [];
}

class LoadMembers extends MemberEvent {
  final String? familyId;
  final String? zoneId;
  final String? streetId;

  const LoadMembers({this.familyId, this.zoneId, this.streetId});

  @override
  List<Object?> get props => [familyId, zoneId, streetId];
}

class AddMember extends MemberEvent {
  final MemberModel member;

  const AddMember(this.member);

  @override
  List<Object?> get props => [member];
}

class UpdateMember extends MemberEvent {
  final MemberModel member;

  const UpdateMember(this.member);

  @override
  List<Object?> get props => [member];
}

class DeleteMember extends MemberEvent {
  final String id;
  final String familyId;

  const DeleteMember(this.id, this.familyId);

  @override
  List<Object?> get props => [id, familyId];
}

class ImportMembersCsv extends MemberEvent {
  final List<Map<String, dynamic>> csvData;

  const ImportMembersCsv(this.csvData);

  @override
  List<Object?> get props => [csvData];
}

class SyncOfflineMembers extends MemberEvent {
  const SyncOfflineMembers();

  @override
  List<Object?> get props => [];
}
