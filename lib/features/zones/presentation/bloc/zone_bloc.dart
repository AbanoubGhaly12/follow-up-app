import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/zone_model.dart';
import '../../data/repositories/zone_repository.dart';

part 'zone_event.dart';
part 'zone_state.dart';

class ZoneBloc extends Bloc<ZoneEvent, ZoneState> {
  final ZoneRepository _zoneRepository;

  ZoneBloc(this._zoneRepository) : super(ZoneInitial()) {
    on<LoadZones>(_onLoadZones);
    on<AddZone>(_onAddZone);
    on<UpdateZone>(_onUpdateZone);
    on<DeleteZone>(_onDeleteZone);
  }

  Future<void> _onLoadZones(LoadZones event, Emitter<ZoneState> emit) async {
    emit(ZoneLoading());
    try {
      final zones = await _zoneRepository.getZones();
      emit(ZoneLoaded(zones));
    } catch (e) {
      emit(ZoneError(e.toString()));
    }
  }

  Future<void> _onAddZone(AddZone event, Emitter<ZoneState> emit) async {
    try {
      await _zoneRepository.addZone(event.zone);
      add(LoadZones());
    } catch (e) {
      emit(ZoneError(e.toString()));
    }
  }

  Future<void> _onUpdateZone(UpdateZone event, Emitter<ZoneState> emit) async {
    try {
      await _zoneRepository.updateZone(event.zone);
      add(LoadZones());
    } catch (e) {
      emit(ZoneError(e.toString()));
    }
  }

  Future<void> _onDeleteZone(DeleteZone event, Emitter<ZoneState> emit) async {
    try {
      await _zoneRepository.deleteZone(event.id);
      add(LoadZones());
    } catch (e) {
      emit(ZoneError(e.toString()));
    }
  }
}
