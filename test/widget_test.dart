import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/app/app.dart';
import 'package:tiyn_app/core/session/role.dart';
import 'package:tiyn_app/features/auth/application/auth_controller.dart';
import 'package:tiyn_app/features/auth/data/user.dart';
import 'package:tiyn_app/features/family/application/family_controller.dart';
import 'package:tiyn_app/features/family/data/family_member.dart';

class _SignedOut extends AuthController {
  @override
  Future<User?> build() async => null;
}

class _Family extends FamilyController {
  @override
  Future<List<FamilyMember>> build() async => const [
    FamilyMember(id: '2', role: Role.teen, displayName: 'Dana'),
  ];
}

class _Parent extends AuthController {
  @override
  Future<User?> build() async => const User(
    id: '1',
    role: Role.parent,
    displayName: 'Aigerim',
    joinCode: 'SXVPUR',
  );
}

void main() {
  testWidgets('signed-out user lands on the sign-in screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(_SignedOut.new)],
        child: const TiynApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('signed-in parent sees the join code', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_Parent.new),
          familyControllerProvider.overrideWith(_Family.new),
        ],
        child: const TiynApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SXVPUR'), findsOneWidget);
    expect(find.text('Connect your teen'), findsOneWidget);
    expect(find.text('Dana'), findsOneWidget);
    expect(find.text('Dana'), findsOneWidget);
  });
}
