import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/main.dart';

void main() {
  group('WhatsApp Clone App', () {
    testWidgets('renders splash screen initially', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        const ProviderScope(
          child: WhatsAppCloneApp(),
        ),
      );

      // Verify that splash screen elements are present
      expect(find.text('WhatsApp Clone'), findsOneWidget);
      expect(find.byIcon(Icons.chat), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('uses WhatsApp green theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: WhatsAppCloneApp(),
        ),
      );

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.colorScheme.primary, const Color(0xFF25D366));
    });
  });
  
  group('Splash Screen', () {
    testWidgets('displays all required elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      expect(find.text('WhatsApp Clone'), findsOneWidget);
      expect(find.byIcon(Icons.chat), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('has correct background color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      final Scaffold scaffold = tester.widget(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF25D366));
    });
  });
}
