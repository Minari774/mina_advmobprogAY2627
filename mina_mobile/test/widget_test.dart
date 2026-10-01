import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mina_mobile/main.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const minaAdvMobProg());
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
