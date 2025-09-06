import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:whatsapp_clone/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('WhatsApp Clone Integration Tests', () {
    testWidgets('app launches successfully', (WidgetTester tester) async {
      // Launch the app
      await tester.pumpWidget(
        const ProviderScope(
          child: WhatsAppCloneApp(),
        ),
      );

      // Wait for the app to settle
      await tester.pumpAndSettle();

      // Verify that the splash screen is displayed
      expect(find.text('WhatsApp Clone'), findsOneWidget);
      expect(find.byIcon(Icons.chat), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('splash screen has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: WhatsAppCloneApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Find the scaffold and verify its background color
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);

      final Scaffold scaffold = tester.widget(scaffoldFinder);
      expect(scaffold.backgroundColor, const Color(0xFF25D366));

      // Verify text styling
      final titleFinder = find.text('WhatsApp Clone');
      expect(titleFinder, findsOneWidget);

      final Text titleWidget = tester.widget(titleFinder);
      expect(titleWidget.style?.color, Colors.white);
      expect(titleWidget.style?.fontSize, 24);
      expect(titleWidget.style?.fontWeight, FontWeight.bold);
    });
  });
}