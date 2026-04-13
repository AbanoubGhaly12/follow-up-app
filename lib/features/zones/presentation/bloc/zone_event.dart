part of 'zone_bloc.dart';

abstract class ZoneEvent extends Equatable {
  const ZoneEvent();

  @override
  List<Object> get props => [];
}

class LoadZones extends ZoneEvent {
  final bool isSuperAdmin;
  final bool otherZonesOnly;

  const LoadZones({this.isSuperAdmin = false, this.otherZonesOnly = false});

  @override
  List<Object> get props => [isSuperAdmin, otherZonesOnly];
}

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

class ImportZonesCsv extends ZoneEvent {
  final List<Map<String, dynamic>> csvData;

  const ImportZonesCsv(this.csvData);

  @override
  List<Object> get props => [csvData];
}

class SyncOfflineZones extends ZoneEvent {}
