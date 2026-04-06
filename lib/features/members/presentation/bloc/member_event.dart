part of 'member_bloc.dart';

abstract class MemberEvent extends Equatable {
  const MemberEvent();

  @override
  List<Object> get props => [];
}

class LoadMembers extends MemberEvent {
  final String? familyId;

  const LoadMembers({this.familyId});

  @override
  List<Object> get props => [familyId ?? ''];
}

class AddMember extends MemberEvent {
  final MemberModel member;

  const AddMember(this.member);

  @override
  List<Object> get props => [member];
}

class UpdateMember extends MemberEvent {
  final MemberModel member;

  const UpdateMember(this.member);

  @override
  List<Object> get props => [member];
}

class DeleteMember extends MemberEvent {
  final String id;
  final String familyId;

  const DeleteMember(this.id, this.familyId);

  @override
  List<Object> get props => [id, familyId];
}
