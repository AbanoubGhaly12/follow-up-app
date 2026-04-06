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
}
