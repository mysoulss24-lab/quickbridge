import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickbridge/main.dart';

void main() {
  testWidgets('QuickBridgeApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: QuickBridgeApp(),
      ),
    );

    // Verify the splash screen is displayed.
    expect(find.text('QuickBridge'), findsOneWidget);

  });
}
