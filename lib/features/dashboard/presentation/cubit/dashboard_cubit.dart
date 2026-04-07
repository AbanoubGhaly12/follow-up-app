import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository repository;

  DashboardCubit({required this.repository}) : super(DashboardInitial());

  Future<void> loadStats({String? userId, bool isSuperAdmin = true}) async {
    emit(DashboardLoading());
    try {
      final stats = await repository.getStats(userId: userId, isSuperAdmin: isSuperAdmin);
      emit(DashboardLoaded(stats));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
