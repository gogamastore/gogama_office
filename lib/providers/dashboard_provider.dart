// lib/providers/dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_data.dart';
import '../models/sales_data.dart';
import '../services/dashboard_service.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) => DashboardService());

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  return ref.watch(dashboardServiceProvider).getDashboardData();
});

final salesAnalyticsProvider = FutureProvider<List<SalesData>>((ref) async {
  return ref.watch(dashboardServiceProvider).getSalesAnalytics();
});