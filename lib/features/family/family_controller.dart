import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'family_member.dart';
import 'family_repository.dart';

final familyRepositoryProvider = Provider<FamilyRepository>(
  (ref) => FamilyRepository(ref.watch(apiClientProvider)),
);

class FamilyController extends AsyncNotifier<List<FamilyMember>> {
  @override
  Future<List<FamilyMember>> build() =>
      ref.read(familyRepositoryProvider).members();

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
