import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/family_model.dart';
import '../../data/repositories/family_repository.dart';

part 'family_event.dart';
part 'family_state.dart';

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  final FamilyRepository _familyRepository;

  FamilyBloc(this._familyRepository) : super(FamilyInitial()) {
    on<LoadFamilies>(_onLoadFamilies);
    on<AddFamily>(_onAddFamily);
    on<UpdateFamily>(_onUpdateFamily);
    on<DeleteFamily>(_onDeleteFamily);
    on<ImportFamiliesCsv>(_onImportFamiliesCsv);
    on<SyncOfflineFamilies>(_onSyncOfflineFamilies);
  }

  Future<void> _onLoadFamilies(
    LoadFamilies event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyLoading());
    try {
      final families =
          event.streetId != null
              ? await _familyRepository.getFamiliesForZone(event.streetId!)
              : await _familyRepository.getAllFamilies();
      emit(FamilyLoaded(families));
    } catch (e) {
      emit(FamilyError(e.toString()));
    }
  }

  Future<void> _onAddFamily(AddFamily event, Emitter<FamilyState> emit) async {
    try {
      await _familyRepository.addFamily(event.family);
      add(LoadFamilies(streetId: event.family.streetId));
    } catch (e) {
      emit(FamilyError(e.toString()));
    }
  }

  Future<void> _onUpdateFamily(
    UpdateFamily event,
    Emitter<FamilyState> emit,
  ) async {
    try {
      await _familyRepository.updateFamily(event.family);
      add(LoadFamilies(streetId: event.family.streetId));
    } catch (e) {
      emit(FamilyError(e.toString()));
    }
  }

  Future<void> _onDeleteFamily(
    DeleteFamily event,
    Emitter<FamilyState> emit,
  ) async {
    try {
      await _familyRepository.deleteFamily(event.familyId);
      add(LoadFamilies(streetId: event.streetId));
    } catch (e) {
      emit(FamilyError(e.toString()));
    }
  }

  Future<void> _onImportFamiliesCsv(
    ImportFamiliesCsv event,
    Emitter<FamilyState> emit,
  ) async {
    try {
      await _familyRepository.importFamiliesFromCsv(event.csvData, event.streetId);
      add(LoadFamilies(streetId: event.streetId));
    } catch (e) {
      emit(FamilyError('Import Error: ${e.toString()}'));
    }
  }

  Future<void> _onSyncOfflineFamilies(
    SyncOfflineFamilies event,
    Emitter<FamilyState> emit,
  ) async {
    try {
      await _familyRepository.syncOfflineFamilies();
      add(const LoadFamilies());
    } catch (e) {
      if (e.toString().contains('network_unavailable')) {
        emit(const FamilyError('Network unavailable. Connect to the internet to sync.'));
      } else {
        emit(FamilyError('Sync Error: ${e.toString()}'));
      }
    }
  }
}
