import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/zone_model.dart';
import '../../data/repositories/zone_repository.dart';

part 'zone_event.dart';
part 'zone_state.dart';

class ZoneBloc extends Bloc<ZoneEvent, ZoneState> {
  final ZoneRepository _zoneRepository;
  bool _isSuperAdmin = false;
  bool _otherZonesOnly = false;

  ZoneBloc(this._zoneRepository) : super(ZoneInitial()) {
    on<LoadZones>(_onLoadZones);
    on<AddZone>(_onAddZone);
    on<UpdateZone>(_onUpdateZone);
    on<DeleteZone>(_onDeleteZone);
  }

  Future<void> _onLoadZones(LoadZones event, Emitter<ZoneState> emit) async {
    emit(ZoneLoading());
    _isSuperAdmin = event.isSuperAdmin;
    _otherZonesOnly = event.otherZonesOnly;
    try {
      final zones = await _zoneRepository.getZones(
        isSuperAdmin: _isSuperAdmin,
        otherZonesOnly: _otherZonesOnly,
      );
      emit(ZoneLoaded(zones));
    } catch (e) {
      emit(ZoneError(e.toString()));
    }
  }

  Future<void> _onAddZone(AddZone event, Emitter<ZoneState> emit) async {
    try {
      await _zoneRepository.addZone(event.zone);
      add(LoadZones(isSuperAdmin: _isSuperAdmin, otherZonesOnly: _otherZonesOnly));
    } catch (e) {
      emit(ZoneError(e.toString()));
    }
  }

  Future<void> _onUpdateZone(UpdateZone event, Emitter<ZoneState> emit) async {
    try {
      await _zoneRepository.updateZone(event.zone);
      add(LoadZones(isSuperAdmin: _isSuperAdmin, otherZonesOnly: _otherZonesOnly));
    } catch (e) {
      emit(ZoneError(e.toString()));
    }
  }

  Future<void> _onDeleteZone(DeleteZone event, Emitter<ZoneState> emit) async {
    try {
      await _zoneRepository.deleteZone(event.id);
      add(LoadZones(isSuperAdmin: _isSuperAdmin, otherZonesOnly: _otherZonesOnly));
    } catch (e) {
      emit(ZoneError(e.toString()));
    }
  }
}
