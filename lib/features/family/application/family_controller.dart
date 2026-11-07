import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tiyn_app/app/providers.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/family/data/family_repository.dart';

final familyRepositoryProvider = Provider<FamilyRepository>(
  (ref) => FamilyRepository(ref.watch(apiClientProvider)),
);

class FamilyController extends AsyncNotifier<List<FamilyMember>> {
  @override
  Future<List<FamilyMember>> build() async {
    if (ref.watch(currentUserIdProvider) == null) return const [];
    return ref.read(familyRepositoryProvider).members();
  }

  /// Reloads without a spinner. If the reload fails while a list is already
  /// on screen, that list stays and nothing is surfaced.
  Future<void> refresh() async {
    final previous = state.value;
    final next = await AsyncValue.guard(
      ref.read(familyRepositoryProvider).members,
    );
    if (next.hasError && previous != null) return;
    state = next;
  }

  Future<void> join(String code) async {
    await ref.read(familyRepositoryProvider).join(code);
    // Strict on purpose: the join succeeded, so a failed reload must show an
    // error (with retry) instead of leaving the teen on the join screen.
    state = await AsyncValue.guard(ref.read(familyRepositoryProvider).members);
  }
}

final familyControllerProvider =
    AsyncNotifierProvider<FamilyController, List<FamilyMember>>(
      FamilyController.new,
    );

/// Display names by member id, for screens that only show a name.
final familyNamesProvider = Provider<Map<String, String>>(
  (ref) => {
    for (final m
        in ref.watch(familyControllerProvider).value ?? const <FamilyMember>[])
      m.id: m.displayName,
  },
);
