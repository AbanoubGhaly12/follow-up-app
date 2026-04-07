import 'package:get_it/get_it.dart';
import '../database/database_helper.dart';
import '../sync/firestore_sync_service.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/user_cubit.dart';
import '../../features/zones/data/repositories/zone_repository.dart';
import '../../features/zones/presentation/bloc/zone_bloc.dart';
import '../../features/streets/data/repositories/street_repository.dart';
import '../../features/streets/presentation/bloc/street_bloc.dart';
import '../../features/families/data/repositories/family_repository.dart';
import '../../features/families/presentation/bloc/family_bloc.dart';
import '../../features/members/data/repositories/member_repository.dart';
import '../../features/members/presentation/bloc/member_bloc.dart';
import '../../features/dashboard/data/repositories/dashboard_repository.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../settings/settings_cubit.dart';
import '../../features/templates/data/repositories/template_repository.dart';
import '../../features/templates/presentation/bloc/template_bloc.dart';
import '../../features/followups/data/repositories/followup_repository.dart';
import '../../features/followups/presentation/bloc/followup_bloc.dart';
import '../../features/auth/data/repositories/user_repository.dart';
import '../../features/auth/data/repositories/user_admin_repository.dart';
import '../utils/import_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Database
  final dbHelper = DatabaseHelper();
  sl.registerLazySingleton(() => dbHelper);

  // Firebase Services
  sl.registerLazySingleton(() => FirestoreSyncService());
  sl.registerLazySingleton(() => AuthRepository());

  // Auth
  sl.registerFactory(() => AuthCubit(authRepository: sl()));
  sl.registerFactory(() => UserCubit(sl(), sl()));

  // Repositories
  sl.registerLazySingleton(() => UserRepository(sl(), sl()));
  sl.registerLazySingleton(() => UserAdminRepository(sl()));
  sl.registerLazySingleton(() => ZoneRepository(sl(), sl(), sl()));
  sl.registerLazySingleton(() => StreetRepository(dbHelper: sl(), syncService: sl()));
  sl.registerLazySingleton(() => FamilyRepository(sl(), sl()));
  sl.registerLazySingleton(() => MemberRepository(sl(), sl()));
  sl.registerLazySingleton(() => DashboardRepository(sl()));
  sl.registerLazySingleton(() => TemplateRepository(sl()));
  sl.registerLazySingleton(() => FollowupRepository(sl(), sl()));
  sl.registerLazySingleton(() => ImportService(sl(), sl(), sl(), sl()));

  // Blocs
  sl.registerFactory(() => SettingsCubit());
  sl.registerFactory(() => ZoneBloc(sl()));
  sl.registerFactory(() => StreetBloc(repository: sl()));
  sl.registerFactory(() => FamilyBloc(sl()));
  sl.registerFactory(() => MemberBloc(sl()));
  sl.registerFactory(() => DashboardCubit(repository: sl()));
  sl.registerFactory(() => TemplateBloc(repository: sl()));
  sl.registerFactory(() => FollowupBloc(repository: sl()));
}
