import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

class UserAdminRepository {
  final UserRepository _userRepository;

  UserAdminRepository(this._userRepository);

  /// Creates a sub-user in Firebase Auth without logging out the current admin.
  /// Then saves the user metadata to Firestore/SQLite via UserRepository.
  Future<void> registerSubUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required String parentAdminUid,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // 1. Create the user in Firebase Auth using a secondary app instance
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 2. Save user metadata to our system
      final newUser = AppUserModel(
        uid: uid,
        name: name,
        email: email,
        parentAdminUid: parentAdminUid,
        role: role,
        createdAt: DateTime.now(),
      );

      await _userRepository.addUser(newUser);

    } finally {
      await secondaryApp?.delete();
    }
  }
}
