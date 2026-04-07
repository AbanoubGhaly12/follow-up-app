import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/followup_repository.dart';
import 'followup_event.dart';
import 'followup_state.dart';

class FollowupBloc extends Bloc<FollowupEvent, FollowupState> {
  final FollowupRepository repository;

  FollowupBloc({required this.repository}) : super(FollowupInitial()) {
    on<LoadFollowups>(_onLoad);
    on<AddFollowup>(_onAdd);
    on<DeleteFollowup>(_onDelete);
    on<SearchFollowups>(_onSearch);
  }

  Future<void> _onLoad(LoadFollowups event, Emitter<FollowupState> emit) async {
    emit(FollowupLoading());
    try {
      final followups = await repository.getFollowupsByFamilyId(
        event.familyId,
        forceSync: event.forceSync,
      );
      emit(FollowupLoaded(followups));
    } catch (e) {
      emit(FollowupError(e.toString()));
    }
  }

  Future<void> _onAdd(AddFollowup event, Emitter<FollowupState> emit) async {
    try {
      await repository.insertFollowup(event.followup);
      add(LoadFollowups(event.familyId));
    } catch (e) {
      emit(FollowupError(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteFollowup event,
    Emitter<FollowupState> emit,
  ) async {
    try {
      await repository.deleteFollowup(event.id);
      add(LoadFollowups(event.familyId));
    } catch (e) {
      emit(FollowupError(e.toString()));
    }
  }

  Future<void> _onSearch(
    SearchFollowups event,
    Emitter<FollowupState> emit,
  ) async {
    emit(FollowupLoading());
    try {
      final followups = await repository.getFollowupsReport(
        date: event.date,
        type: event.type,
        zoneId: event.zoneId,
        streetId: event.streetId,
        inactivityMonths: event.inactivityMonths,
        isFamilyReport: event.isFamilyReport,
        forceSync: event.forceSync,
      );
      emit(FollowupLoaded(followups));
    } catch (e) {
      emit(FollowupError(e.toString()));
    }
  }
}
