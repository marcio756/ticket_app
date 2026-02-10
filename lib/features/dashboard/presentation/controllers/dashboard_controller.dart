import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/dashboard_stats_model.dart';

// Provider para o estado do Dashboard (AsyncValue gere loading/erro/sucesso)
final dashboardControllerProvider =
    StateNotifierProvider.autoDispose<DashboardController, AsyncValue<DashboardStatsModel?>>((ref) {
  return DashboardController();
});

class DashboardController extends StateNotifier<AsyncValue<DashboardStatsModel?>> {
  DashboardController() : super(const AsyncValue.loading()) {
    loadDashboard();
  }

  final _apiClient = ApiClient();

  Future<void> loadDashboard() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.client.get('/dashboard');
      final data = DashboardStatsModel.fromJson(response.data);
      state = AsyncValue.data(data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}