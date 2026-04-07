import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/user_admin_repository.dart';

abstract class UserState extends Equatable {
  const UserState();
  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}
class UserLoading extends UserState {}
class UsersLoaded extends UserState {
  final List<AppUserModel> users;
  const UsersLoaded(this.users);
  @override
  List<Object?> get props => [users];
}
class UserError extends UserState {
  final String message;
  const UserError(this.message);
  @override
  List<Object?> get props => [message];
}

class UserCubit extends Cubit<UserState> {
  final UserRepository _userRepository;
  final UserAdminRepository _userAdminRepository;

  UserCubit(this._userRepository, this._userAdminRepository) : super(UserInitial());

  Future<void> fetchManagedUsers() async {
    emit(UserLoading());
    try {
      final users = await _userRepository.getManagedUsers();
      emit(UsersLoaded(users));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> createSubUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String parentAdminUid,
  }) async {
    emit(UserLoading());
    try {
      await _userAdminRepository.registerSubUser(
        name: name,
        email: email,
        password: password,
        role: role,
        parentAdminUid: parentAdminUid,
      );
      fetchManagedUsers();
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
