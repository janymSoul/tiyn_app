import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tiyn_app/app/router/redirect.dart';
import 'package:tiyn_app/app/router/routes.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/presentation/sign_in_screen.dart';
import 'package:tiyn_app/features/auth/presentation/splash_screen.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/presentation/join_teen_screen.dart';
import 'package:tiyn_app/features/parent/presentation/create_task_screen.dart';
import 'package:tiyn_app/features/parent/presentation/parent_home_screen.dart';
import 'package:tiyn_app/features/parent/presentation/parent_shell.dart';
import 'package:tiyn_app/features/parent/presentation/parent_task_screen.dart';
import 'package:tiyn_app/features/parent/presentation/review_list_screen.dart';
import 'package:tiyn_app/features/parent/presentation/review_screen.dart';
import 'package:tiyn_app/features/parent/presentation/teen_detail_screen.dart';
import 'package:tiyn_app/features/payouts/presentation/parent_payout_screen.dart';
import 'package:tiyn_app/features/payouts/presentation/request_payout_screen.dart';
import 'package:tiyn_app/features/payouts/presentation/teen_payout_screen.dart';
import 'package:tiyn_app/features/tasks/data/task_kind.dart';
import 'package:tiyn_app/features/teen/presentation/teen_home_screen.dart';
import 'package:tiyn_app/features/teen/presentation/teen_milestone_screen.dart';
import 'package:tiyn_app/features/teen/presentation/teen_task_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.listen(familyControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

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
      GoRoute(
        path: Routes.teenHome,
        builder: (_, _) => const TeenHomeScreen(),
        routes: [
          GoRoute(
            path: Routes.teenCashOutPattern,
            builder: (_, _) => const RequestPayoutScreen(),
          ),
          GoRoute(
            path: 'payout/:id',
            builder: (_, state) =>
                TeenPayoutScreen(payoutId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'task/:id',
            builder: (_, state) =>
                TeenTaskScreen(taskId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'milestone/:id',
            builder: (_, state) =>
                TeenMilestoneScreen(milestoneId: state.pathParameters['id']!),
          ),
        ],
      ),
      // Outside the shell on purpose: the form covers the bottom bar.
      GoRoute(
        path: Routes.parentNew,
        builder: (_, state) {
          final q = state.uri.queryParameters;
          return CreateTaskScreen(
            args: CreateTaskArgs(
              teenId: q['teenId'] ?? '',
              kind: q['kind'] == 'milestone'
                  ? TaskKind.milestone
                  : TaskKind.task,
              milestoneId: q['milestoneId'],
              milestoneDeadline: DateTime.tryParse(
                q['milestoneDeadline'] ?? '',
              ),
            ),
          );
        },
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
                    routes: [
                      GoRoute(
                        path: Routes.parentTaskPattern,
                        builder: (_, state) => ParentTaskScreen(
                          teenId: state.pathParameters['id']!,
                          taskId: state.pathParameters['taskId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.parentReview,
                builder: (_, _) => const ReviewListScreen(),
                routes: [
                  GoRoute(
                    path: Routes.parentPayoutPattern,
                    builder: (_, state) => ParentPayoutScreen(
                      payoutId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: Routes.parentReviewTaskPattern,
                    builder: (_, state) =>
                        ReviewScreen(taskId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
