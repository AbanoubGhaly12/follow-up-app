import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/street_repository.dart';
import 'street_event.dart';
import 'street_state.dart';

class StreetBloc extends Bloc<StreetEvent, StreetState> {
  final StreetRepository repository;

  StreetBloc({required this.repository}) : super(StreetInitial()) {
    on<LoadStreets>(_onLoadStreets);
    on<AddStreet>(_onAddStreet);
    on<UpdateStreet>(_onUpdateStreet);
    on<DeleteStreet>(_onDeleteStreet);
    on<ImportStreetsCsv>(_onImportStreetsCsv);
    on<SyncOfflineStreets>(_onSyncOfflineStreets);
  }

  Future<void> _onLoadStreets(
    LoadStreets event,
    Emitter<StreetState> emit,
  ) async {
    emit(StreetLoading());
    try {
      final streets =
          event.zoneId != null
              ? await repository.getStreetsForZone(event.zoneId!)
              : await repository.getAllStreets();
      emit(StreetLoaded(streets));
    } catch (e) {
      emit(StreetError(e.toString()));
    }
  }

  Future<void> _onAddStreet(AddStreet event, Emitter<StreetState> emit) async {
    try {
      await repository.insertStreet(event.street);
      add(LoadStreets(zoneId: event.street.zoneId));
    } catch (e) {
      emit(StreetError(e.toString()));
    }
  }

  Future<void> _onUpdateStreet(
    UpdateStreet event,
    Emitter<StreetState> emit,
  ) async {
    try {
      await repository.updateStreet(event.street);
      add(LoadStreets(zoneId: event.street.zoneId));
    } catch (e) {
      emit(StreetError(e.toString()));
    }
  }

  Future<void> _onDeleteStreet(
    DeleteStreet event,
    Emitter<StreetState> emit,
  ) async {
    try {
      await repository.deleteStreet(event.streetId);
      add(LoadStreets(zoneId: event.zoneId));
    } catch (e) {
      emit(StreetError(e.toString()));
    }
  }

  Future<void> _onImportStreetsCsv(
    ImportStreetsCsv event,
    Emitter<StreetState> emit,
  ) async {
    try {
      await repository.importStreetsFromCsv(event.csvData, event.zoneId);
      add(LoadStreets(zoneId: event.zoneId));
    } catch (e) {
      emit(StreetError('Import Error: ${e.toString()}'));
    }
  }

  Future<void> _onSyncOfflineStreets(
    SyncOfflineStreets event,
    Emitter<StreetState> emit,
  ) async {
    // Currently relying on the last known zoneId since Sync doesn't target a specific zone
    // But LoadStreets(zoneId: null) fetches all streets if needed.
    // Ideally we just reload the current view. 
    try {
      await repository.syncOfflineStreets();
      add(const LoadStreets()); // Reload all or rely on current state
    } catch (e) {
      if (e.toString().contains('network_unavailable')) {
        emit(const StreetError('Network unavailable. Connect to the internet to sync.'));
      } else {
        emit(StreetError('Sync Error: ${e.toString()}'));
      }
    }
  }
}
