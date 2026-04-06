import 'package:equatable/equatable.dart';
import '../../data/models/followup_model.dart';

abstract class FollowupEvent extends Equatable {
  const FollowupEvent();

  @override
  List<Object?> get props => [];
}

class LoadFollowups extends FollowupEvent {
  final String familyId;
  const LoadFollowups(this.familyId);

  @override
  List<Object?> get props => [familyId];
}

class AddFollowup extends FollowupEvent {
  final FollowupModel followup;
  final String familyId;
  const AddFollowup(this.followup, this.familyId);

  @override
  List<Object?> get props => [followup, familyId];
}

class DeleteFollowup extends FollowupEvent {
  final String id;
  final String familyId;
  const DeleteFollowup(this.id, this.familyId);

  @override
  List<Object?> get props => [id, familyId];
}

class SearchFollowups extends FollowupEvent {
  final DateTime? date;
  final FollowupType? type;
  const SearchFollowups({this.date, this.type});

  @override
  List<Object?> get props => [date, type];
}
