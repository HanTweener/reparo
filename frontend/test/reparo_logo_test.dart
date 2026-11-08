import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/reparo_logo.dart';

void main() {
  testWidgets('ReparoLogo renders with default and custom configurations', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ReparoLogo(size: 24),
              ReparoLogo(size: 48, darkPlate: true),
              ReparoLogo(size: 16, showPlate: false),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(ReparoLogo), findsNWidgets(3));
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
