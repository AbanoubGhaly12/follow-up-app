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
  }

  Future<void> _onLoadMembers(
    LoadMembers event,
    Emitter<MemberState> emit,
  ) async {
    emit(MemberLoading());
    try {
      final members =
          event.familyId != null
              ? await _memberRepository.getMembersByFamily(event.familyId!)
              : await _memberRepository.getAllMembers();
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
}
