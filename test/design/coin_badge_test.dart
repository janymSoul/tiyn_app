import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiyn_app/design/widgets/coin_badge.dart';

void main() {
  testWidgets('a long amount shrinks to stay inside the circle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: CoinBadge(size: 180, glyph: '1 234 567 ₸')),
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    final circle = tester.getRect(find.byType(CoinBadge));
    final text = tester.getRect(find.text('1 234 567 ₸'));
    final radius = circle.width / 2;
    for (final corner in [
      text.topLeft,
      text.topRight,
      text.bottomLeft,
      text.bottomRight,
    ]) {
      expect(
        (corner - circle.center).distance,
        lessThanOrEqualTo(radius),
        reason: 'text corner $corner must be inside the circle',
      );
    }
    expect(text.width, lessThan(circle.width * 0.8));
  });

  testWidgets('a short glyph keeps its natural size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: CoinBadge(size: 180, glyph: '₸')),
        ),
      ),
    );
    final text = tester.getRect(find.text('₸'));
    expect(text.height, greaterThanOrEqualTo(180 * 0.42));
  });
}
