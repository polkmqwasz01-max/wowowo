import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CicakGurun app widget can be created', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('CicakGurun'),
        ),
      ),
    );

    expect(find.text('CicakGurun'), findsOneWidget);
  });
}
