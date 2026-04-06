import 'package:equatable/equatable.dart';
import '../../data/models/street_model.dart';

abstract class StreetState extends Equatable {
  const StreetState();

  @override
  List<Object> get props => [];
}

class StreetInitial extends StreetState {}

class StreetLoading extends StreetState {}

class StreetLoaded extends StreetState {
  final List<StreetModel> streets;

  const StreetLoaded(this.streets);

  @override
  List<Object> get props => [streets];
}

class StreetError extends StreetState {
  final String message;

  const StreetError(this.message);

  @override
  List<Object> get props => [message];
}
