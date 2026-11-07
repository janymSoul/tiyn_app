import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiyn_app/app/providers.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/payouts/application/payout_problem.dart';
import 'package:tiyn_app/features/payouts/data/payout.dart';
import 'package:tiyn_app/features/payouts/data/payout_repository.dart';
import 'package:tiyn_app/features/payouts/data/payout_state.dart';

final payoutRepositoryProvider = Provider<PayoutRepository>(
  (ref) => PayoutRepository(ref.watch(apiClientProvider)),
);

/// Open requests addressed to the signed-in parent.
class RequestedPayoutsController extends AsyncNotifier<List<Payout>> {
  @override
  Future<List<Payout>> build() async {
    // A different user must never see the previous user's requests.
    if (ref.watch(currentUserIdProvider) == null) return const [];
    return _fetch();
  }

  Future<List<Payout>> _fetch() =>
      ref.read(payoutRepositoryProvider).list(state: PayoutState.requested);

  /// Reloads without a spinner. If it fails while a list is already on
  /// screen, that list stays and nothing is surfaced.
  Future<void> refresh() async {
    final previous = state.value;
    final generation = ++_generation;
    final next = await AsyncValue.guard(_fetch);
    // A newer refresh or a local removal happened meanwhile: this answer is
    // older than what the screen already shows.
    if (!ref.mounted || generation != _generation) return;
    if (next.hasError && previous != null) return;
    state = next;
  }

  int _generation = 0;

  /// Drops a request that was just resolved, without waiting for the refetch,
  /// so the row and the badge go even if that refetch fails. Any refresh
  /// already in flight is older than this and is discarded.
  void remove(String id) {
    final list = state.value;
    if (list == null) return;
    _generation++;
    state = AsyncData([
      for (final p in list)
        if (p.id != id) p,
    ]);
  }
}

final requestedPayoutsProvider =
    AsyncNotifierProvider<RequestedPayoutsController, List<Payout>>(
      RequestedPayoutsController.new,
    );

class PayoutDetailController extends AsyncNotifier<Payout> {
  PayoutDetailController(this.id);

  final String id;

  @override
  Future<Payout> build() => _fetch();

  Future<Payout> _fetch() => ref.read(payoutRepositoryProvider).get(id);

  /// Reloads without a spinner. If it fails while a payout is already on
  /// screen, that payout stays and nothing is surfaced, except when the
  /// payout is gone for this user (404, or 403 after an unlink): then the
  /// screen must stop offering actions on it.
  Future<void> refresh() async {
    final previous = state.value;
    final next = await AsyncValue.guard(_fetch);
    if (!ref.mounted) return;
    if (next.hasError && previous != null && !_isGone(next.error!)) return;
    state = next;
  }

  static bool _isGone(Object error) {
    final problem = PayoutProblem.from(error);
    return problem == PayoutProblem.notFound ||
        problem == PayoutProblem.notLinked;
  }
}

/// One payout, loaded on its own so a screen shows the latest state even when
/// the list it was opened from is stale. No automatic retries: the screen has
/// its own "Try again".
final payoutDetailProvider = AsyncNotifierProvider.autoDispose
    .family<PayoutDetailController, Payout, String>(
      PayoutDetailController.new,
      retry: (_, _) => null,
    );

/// Oldest request first: that is the one that expires first. The API promises
/// no order.
List<Payout> payoutQueue(Iterable<Payout> requested) {
  final queue = requested.toList()
    ..sort((a, b) {
      final c = a.requestedAt.compareTo(b.requestedAt);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  return queue;
}
