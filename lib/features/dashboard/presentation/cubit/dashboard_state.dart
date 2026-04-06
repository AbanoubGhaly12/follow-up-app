import 'package:equatable/equatable.dart';
import '../../data/repositories/dashboard_repository.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;

  const DashboardLoaded(this.stats);

  @override
  List<Object> get props => [
    stats.totalZones,
    stats.totalStreets,
    stats.totalFamilies,
    stats.totalMembers,
  ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object> get props => [message];
}
