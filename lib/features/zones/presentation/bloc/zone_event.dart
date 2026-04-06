part of 'zone_bloc.dart';

abstract class ZoneEvent extends Equatable {
  const ZoneEvent();

  @override
  List<Object> get props => [];
}

class LoadZones extends ZoneEvent {}

class AddZone extends ZoneEvent {
  final ZoneModel zone;

  const AddZone(this.zone);

  @override
  List<Object> get props => [zone];
}

class UpdateZone extends ZoneEvent {
  final ZoneModel zone;

  const UpdateZone(this.zone);

  @override
  List<Object> get props => [zone];
}

class DeleteZone extends ZoneEvent {
  final String id;

  const DeleteZone(this.id);

  @override
  List<Object> get props => [id];
}
