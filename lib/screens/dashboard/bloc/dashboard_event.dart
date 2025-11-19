part of 'dashboard_bloc.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object> get props => [];
}

final class RefreshPriceEvent extends DashboardEvent {}

final class RefreshPriceChartEvent extends DashboardEvent {}
