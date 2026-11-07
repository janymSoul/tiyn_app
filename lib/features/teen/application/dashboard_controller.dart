import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/app/providers.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/teen/data/dashboard.dart';
import 'package:tiyn_app/features/teen/data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(apiClientProvider)),
);

class DashboardController extends AsyncNotifier<Dashboard?> {
  @override
  Future<Dashboard?> build() async {
    // Rebuilt for every user, so one teen never sees another's balance.
    if (ref.watch(currentUserIdProvider) == null) return null;
    return ref.read(dashboardRepositoryProvider).load();
  }

  /// Reloads without a spinner. If it fails while a dashboard is already on
  /// screen, that dashboard stays and nothing is surfaced.
  Future<void> refresh() async {
    final previous = state.value;
    final next = await AsyncValue.guard(
      ref.read(dashboardRepositoryProvider).load,
    );
    if (!ref.mounted) return;
    if (next.hasError && previous != null) return;
    state = next;
  }
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, Dashboard?>(
      DashboardController.new,
    );
