import 'package:equatable/equatable.dart';
import '../../data/models/street_model.dart';

abstract class StreetEvent extends Equatable {
  const StreetEvent();

  @override
  List<Object> get props => [];
}

class LoadStreets extends StreetEvent {
  final String? zoneId;

  const LoadStreets({this.zoneId});

  @override
  List<Object> get props => [zoneId ?? ''];
}

class AddStreet extends StreetEvent {
  final StreetModel street;

  const AddStreet(this.street);

  @override
  List<Object> get props => [street];
}

class UpdateStreet extends StreetEvent {
  final StreetModel street;

  const UpdateStreet(this.street);

  @override
  List<Object> get props => [street];
}

class DeleteStreet extends StreetEvent {
  final String streetId;
  final String zoneId;

  const DeleteStreet(this.streetId, this.zoneId);

  @override
  List<Object> get props => [streetId, zoneId];
}

class ImportStreetsCsv extends StreetEvent {
  final List<Map<String, dynamic>> csvData;
  final String zoneId;

  const ImportStreetsCsv(this.csvData, this.zoneId);

  @override
  List<Object> get props => [csvData, zoneId];
}

class SyncOfflineStreets extends StreetEvent {
  const SyncOfflineStreets();
}
