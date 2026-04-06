part of 'zone_bloc.dart';

abstract class ZoneState extends Equatable {
  const ZoneState();

  @override
  List<Object> get props => [];
}

class ZoneInitial extends ZoneState {}

class ZoneLoading extends ZoneState {}

class ZoneLoaded extends ZoneState {
  final List<ZoneModel> zones;

  const ZoneLoaded(this.zones);

  @override
  List<Object> get props => [zones];
}

class ZoneError extends ZoneState {
  final String message;

  const ZoneError(this.message);

  @override
  List<Object> get props => [message];
}
