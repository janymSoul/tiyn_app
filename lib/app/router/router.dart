import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/app/router/redirect.dart';
import 'package:tiyn_app/app/router/routes.dart';
import 'package:tiyn_app/design/widgets/placeholder_tab.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/presentation/sign_in_screen.dart';
import 'package:tiyn_app/features/auth/presentation/splash_screen.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/presentation/join_teen_screen.dart';
import 'package:tiyn_app/features/parent/presentation/parent_home_screen.dart';
import 'package:tiyn_app/features/parent/presentation/parent_shell.dart';
import 'package:tiyn_app/features/parent/presentation/teen_detail_screen.dart';
import 'package:tiyn_app/features/teen/presentation/teen_home_placeholder.dart';
import 'package:tiyn_app/features/teen/presentation/teen_shell.dart';
import 'package:tiyn_app/l10n/app_localizations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.listen(familyControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  GoRoute tab(String path, Widget Function(BuildContext) build) =>
      GoRoute(path: path, builder: (context, _) => build(context));

  return GoRouter(
    refreshListenable: refresh,
    initialLocation: Routes.splash,
    redirect: (context, state) => resolveRedirect(
      auth: ref.read(authControllerProvider),
      family: ref.read(familyControllerProvider),
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final auth = ref.watch(authControllerProvider);
            final family = ref.watch(familyControllerProvider);
            if (auth.hasError) {
              return SplashScreen(
                hasError: true,
                onRetry: () => ref.invalidate(authControllerProvider),
                onSignOut: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              );
            }
            if (family.hasError && !family.isLoading) {
              return SplashScreen(
                hasError: true,
                onRetry: () => ref.invalidate(familyControllerProvider),
                onSignOut: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              );
            }
            return const SplashScreen();
          },
        ),
      ),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: Routes.teenJoin, builder: (_, _) => const JoinTeenScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => TeenShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              tab(
                Routes.teenHome,
                (_) => Consumer(
                  builder: (context, ref, _) {
                    final user = ref.watch(authControllerProvider).value;
                    final parents =
                        ref.watch(familyControllerProvider).value ?? const [];
                    return TeenHomePlaceholder(
                      displayName: user?.displayName ?? '',
                      parentNames: [for (final p in parents) p.displayName],
                      onSignOut: () =>
                          ref.read(authControllerProvider.notifier).signOut(),
                    );
                  },
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              tab(
                Routes.teenProgress,
                (context) => PlaceholderTab(
                  title: AppLocalizations.of(context).navProgress,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              tab(
                Routes.teenGoals,
                (context) => PlaceholderTab(
                  title: AppLocalizations.of(context).navGoals,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              tab(
                Routes.teenActivity,
                (context) => PlaceholderTab(
                  title: AppLocalizations.of(context).navActivity,
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ParentShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.parentHome,
                builder: (_, _) => const ParentHomeScreen(),
                routes: [
                  GoRoute(
                    path: Routes.parentTeenPattern,
                    builder: (_, state) =>
                        TeenDetailScreen(teenId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              tab(
                Routes.parentReview,
                (context) => PlaceholderTab(
                  title: AppLocalizations.of(context).navToCheck,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
