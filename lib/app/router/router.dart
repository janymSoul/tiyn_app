import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/presentation/sign_in_screen.dart';
import 'package:tiyn_app/features/home/home_screens.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    refreshListenable: refresh,
    initialLocation: '/',
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isLoading && !auth.hasValue) return null;
      final signedIn = auth.value != null;
      final onSignIn = state.matchedLocation == '/sign-in';
      if (!signedIn) return onSignIn ? null : '/sign-in';
      return onSignIn ? '/' : null;
    },
    routes: [
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(
        path: '/',
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final user = ref.watch(authControllerProvider).value;
            return user == null
                ? const SizedBox.shrink()
                : HomeShell(user: user);
          },
        ),
      ),
    ],
  );
});
