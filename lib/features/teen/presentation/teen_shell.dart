import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

class TeenShell extends StatelessWidget {
  const TeenShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart),
            label: l10n.navProgress,
          ),
          NavigationDestination(
            icon: const Icon(Icons.flag_outlined),
            label: l10n.navGoals,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            label: l10n.navActivity,
          ),
        ],
      ),
    );
  }
}
