import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:witchat_mobile/app.dart';

void main() {
  testWidgets('Witchat app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WitchatApp(),
      ),
    );

    // Verify the app renders without errors
    expect(find.byType(WitchatApp), findsOneWidget);
  });
}
