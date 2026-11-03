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

  Future<void> refresh() async {
    state = await AsyncValue.guard(ref.read(familyRepositoryProvider).members);
  }

  Future<void> join(String code) async {
    await ref.read(familyRepositoryProvider).join(code);
    await refresh();
  }
}

final familyControllerProvider =
    AsyncNotifierProvider<FamilyController, List<FamilyMember>>(
      FamilyController.new,
    );
