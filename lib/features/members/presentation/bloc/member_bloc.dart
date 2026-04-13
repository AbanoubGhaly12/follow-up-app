import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/member_model.dart';
import '../../data/repositories/member_repository.dart';

part 'member_event.dart';
part 'member_state.dart';

class MemberBloc extends Bloc<MemberEvent, MemberState> {
  final MemberRepository _memberRepository;

  MemberBloc(this._memberRepository) : super(MemberInitial()) {
    on<LoadMembers>(_onLoadMembers);
    on<AddMember>(_onAddMember);
    on<UpdateMember>(_onUpdateMember);
    on<DeleteMember>(_onDeleteMember);
    on<ImportMembersCsv>(_onImportMembersCsv);
    on<SyncOfflineMembers>(_onSyncOfflineMembers);
  }

  Future<void> _onLoadMembers(
    LoadMembers event,
    Emitter<MemberState> emit,
  ) async {
    emit(MemberLoading());
    try {
      final members = await _memberRepository.getMembers(
        familyId: event.familyId,
        zoneId: event.zoneId,
        streetId: event.streetId,
      );
      emit(MemberLoaded(members));
    } catch (e) {
      emit(MemberError(e.toString()));
    }
  }

  Future<void> _onAddMember(AddMember event, Emitter<MemberState> emit) async {
    try {
      await _memberRepository.addMember(event.member);
      add(LoadMembers(familyId: event.member.familyId));
    } catch (e) {
      emit(MemberError(e.toString()));
    }
  }

  Future<void> _onUpdateMember(
    UpdateMember event,
    Emitter<MemberState> emit,
  ) async {
    try {
      await _memberRepository.updateMember(event.member);
      add(LoadMembers(familyId: event.member.familyId));
    } catch (e) {
      emit(MemberError(e.toString()));
    }
  }

  Future<void> _onDeleteMember(
    DeleteMember event,
    Emitter<MemberState> emit,
  ) async {
    try {
      await _memberRepository.deleteMember(event.id);
      add(LoadMembers(familyId: event.familyId));
    } catch (e) {
      emit(MemberError(e.toString()));
    }
  }

  Future<void> _onImportMembersCsv(
    ImportMembersCsv event,
    Emitter<MemberState> emit,
  ) async {
    try {
      await _memberRepository.importMembersFromCsv(event.csvData);
      add(const LoadMembers());
    } catch (e) {
      emit(MemberError('Import Error: ${e.toString()}'));
    }
  }

  Future<void> _onSyncOfflineMembers(
    SyncOfflineMembers event,
    Emitter<MemberState> emit,
  ) async {
    try {
      await _memberRepository.syncOfflineMembers();
      add(const LoadMembers());
    } catch (e) {
      if (e.toString().contains('network_unavailable')) {
        emit(const MemberError('Network unavailable. Connect to the internet to sync.'));
      } else {
        emit(MemberError('Sync Error: ${e.toString()}'));
      }
    }
  }
}
