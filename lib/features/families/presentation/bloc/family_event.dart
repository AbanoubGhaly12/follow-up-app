part of 'family_bloc.dart';

abstract class FamilyEvent extends Equatable {
  const FamilyEvent();

  @override
  List<Object> get props => [];
}

class LoadFamilies extends FamilyEvent {
  final String? streetId;

  const LoadFamilies({this.streetId});

  @override
  List<Object> get props => [streetId ?? ''];
}

class AddFamily extends FamilyEvent {
  final FamilyModel family;

  const AddFamily(this.family);

  @override
  List<Object> get props => [family];
}

class UpdateFamily extends FamilyEvent {
  final FamilyModel family;

  const UpdateFamily(this.family);

  @override
  List<Object> get props => [family];
}

class DeleteFamily extends FamilyEvent {
  final String familyId;
  final String streetId;

  const DeleteFamily(this.familyId, this.streetId);

  @override
  List<Object> get props => [familyId, streetId];
}

class ImportFamiliesCsv extends FamilyEvent {
  final List<Map<String, dynamic>> csvData;
  final String streetId;

  const ImportFamiliesCsv(this.csvData, this.streetId);

  @override
  List<Object> get props => [csvData, streetId];
}

class SyncOfflineFamilies extends FamilyEvent {
  const SyncOfflineFamilies();
}
