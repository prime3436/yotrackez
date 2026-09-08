import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_snap/main.dart';

void main() {
  testWidgets('YOTRACKEZ app launches splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const YOTRACKEZApp());
    expect(find.text('YOTRACKEZ'), findsOneWidget);

    // Advance timers so splash screen transition completes
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump(const Duration(milliseconds: 600));
  });
}
