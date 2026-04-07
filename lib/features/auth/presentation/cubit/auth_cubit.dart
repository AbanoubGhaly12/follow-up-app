import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  late final StreamSubscription _authSubscription;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    _authSubscription = _authRepository.authStateChanges.listen((user) async {
      if (user != null) {
        final profile = await _fetchOrCreateProfile(user);
        emit(AuthAuthenticated(user, profile: profile));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<AppUserModel?> _fetchOrCreateProfile(dynamic user) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return AppUserModel.fromFirestore(user.uid, doc.data()!);
      } else {
        // First time login - assume super admin if no parent
        final newProfile = AppUserModel(
          uid: user.uid,
          name: user.displayName ?? user.email?.split('@').first ?? 'User',
          email: user.email ?? '',
          role: UserRole.superAdmin,
          createdAt: DateTime.now(),
        );
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(newProfile.toFirestore());
        return newProfile;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      await _authRepository.signIn(email: email, password: password);
      // AuthAuthenticated will be emitted by the authStateChanges listener
    } catch (e) {
      emit(AuthError(e.toString()));
      // After showing the error, revert to unauthenticated
      emit(AuthUnauthenticated());
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    // AuthUnauthenticated will be emitted by the authStateChanges listener
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
