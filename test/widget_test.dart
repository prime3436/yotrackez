import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_snap/main.dart';

void main() {
  testWidgets('YOTRACKEZ app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const YOTRACKEZApp());
    expect(find.text('YOTRACKEZ'), findsOneWidget);
  });
}
