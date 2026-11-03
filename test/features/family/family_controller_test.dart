import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/core/network/api_exception.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';
import 'package:tiyn_app/features/family/data/family_repository.dart';

class _TestAuth extends AuthController {
  @override
  Future<User?> build() async => null;

  void setUser(User? user) => state = AsyncData(user);
}

class _CountingRepository implements FamilyRepository {
  int calls = 0;
  bool failing = false;
  bool joinSucceeds = false;

  @override
  Future<List<FamilyMember>> members() async {
    calls++;
    if (failing) throw const ApiException(code: 'network_error');
    return [
      FamilyMember(
        id: 'm$calls',
        role: Role.teen,
        displayName: 'Member $calls',
      ),
    ];
  }

  @override
  Future<FamilyMember> join(String code) async {
    if (!joinSucceeds) throw UnimplementedError();
    return const FamilyMember(id: 'p', role: Role.parent, displayName: 'P');
  }
}

User _user(String id) =>
    User(id: id, role: Role.parent, displayName: id, joinCode: 'ABCDEF');

void main() {
  late _CountingRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _CountingRepository();
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authControllerProvider.overrideWith(_TestAuth.new),
        familyRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(familyControllerProvider, (_, _) {});
  });

  _TestAuth auth() =>
      container.read(authControllerProvider.notifier) as _TestAuth;

  test('signed out: empty list and no API call', () async {
    await container.read(authControllerProvider.future);
    expect(await container.read(familyControllerProvider.future), isEmpty);
    expect(repository.calls, 0);
  });

  test('refetches when the signed-in user changes', () async {
    await container.read(authControllerProvider.future);

    auth().setUser(_user('a'));
    final first = await container.read(familyControllerProvider.future);
    expect(first.single.id, 'm1');

    auth().setUser(_user('b'));
    final second = await container.read(familyControllerProvider.future);
    expect(second.single.id, 'm2');
    expect(repository.calls, 2);
  });

  test('signing out clears the family without calling the API', () async {
    await container.read(authControllerProvider.future);
    auth().setUser(_user('a'));
    await container.read(familyControllerProvider.future);

    auth().setUser(null);
    expect(await container.read(familyControllerProvider.future), isEmpty);
    expect(repository.calls, 1);
  });

  group('refresh', () {
    Future<void> signedInWithData() async {
      await container.read(authControllerProvider.future);
      auth().setUser(_user('a'));
      await container.read(familyControllerProvider.future);
    }

    test(
      'a failed refresh keeps the previous data and shows no error',
      () async {
        await signedInWithData();
        repository.failing = true;

        await container.read(familyControllerProvider.notifier).refresh();

        final state = container.read(familyControllerProvider);
        expect(state.hasError, isFalse);
        expect(state.value?.single.id, 'm1');
        expect(repository.calls, 2);
      },
    );

    test('a successful refresh replaces the data without a spinner', () async {
      await signedInWithData();
      final states = <AsyncValue<List<FamilyMember>>>[];
      container.listen(familyControllerProvider, (_, next) => states.add(next));

      await container.read(familyControllerProvider.notifier).refresh();

      expect(states.single.value?.single.id, 'm2');
      expect(states.any((s) => s.isLoading), isFalse);
    });

    test(
      'a failed load with nothing to keep still reports the error',
      () async {
        repository.failing = true;
        await container.read(authControllerProvider.future);
        auth().setUser(_user('a'));
        await expectLater(
          container.read(familyControllerProvider.future),
          throwsA(isA<ApiException>()),
        );
      },
    );

    test(
      'join stays strict: a failed reload after joining is an error',
      () async {
        await signedInWithData();
        repository
          ..joinSucceeds = true
          ..failing = true;

        await container.read(familyControllerProvider.notifier).join('SXVPUR');

        expect(container.read(familyControllerProvider).hasError, isTrue);
      },
    );
  });
}
