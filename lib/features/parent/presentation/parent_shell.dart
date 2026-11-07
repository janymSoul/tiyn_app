import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/core/lifecycle/refresh_on_foreground.dart';
import 'package:tiyn_app/features/parent/application/parent_tabs.dart';
import 'package:tiyn_app/features/payouts/application/payout_providers.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

/// Home and To check. Progress, Goals and Activity are hidden until they exist.
class ParentShell extends ConsumerWidget {
  const ParentShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Proofs and payout requests both wait for the parent.
    final proofs = ref.watch(
      submittedTasksProvider.select((s) => s.value?.length ?? 0),
    );
    final requests = ref.watch(
      requestedPayoutsProvider.select((s) => s.value?.length ?? 0),
    );
    final toCheck = proofs + requests;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
          // After the frame: a tab opened for the first time is built by
          // goBranch, and only then is there a listener to hear this.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(tabSelectedProvider.notifier)
                .selected(ParentTab.values[index]);
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: _CountBadge(
              count: toCheck,
              child: const Icon(Icons.task_alt),
            ),
            label: l10n.navToCheck,
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    final l10n = AppLocalizations.of(context);
    return Badge(
      label: Text(count > 9 ? '9+' : '$count'),
      // The visible label is just a number; say what it counts.
      child: Semantics(label: l10n.navBadgeWaiting(count), child: child),
    );
  }
}
