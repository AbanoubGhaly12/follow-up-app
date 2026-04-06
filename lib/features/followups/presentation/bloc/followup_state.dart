import 'package:equatable/equatable.dart';
import '../../data/models/followup_model.dart';

abstract class FollowupState extends Equatable {
  const FollowupState();

  @override
  List<Object?> get props => [];
}

class FollowupInitial extends FollowupState {}

class FollowupLoading extends FollowupState {}

class FollowupLoaded extends FollowupState {
  final List<FollowupModel> followups;
  const FollowupLoaded(this.followups);

  @override
  List<Object?> get props => [followups];
}

class FollowupError extends FollowupState {
  final String message;
  const FollowupError(this.message);

  @override
  List<Object?> get props => [message];
}
