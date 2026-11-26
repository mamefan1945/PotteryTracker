import 'package:flutter_test/flutter_test.dart';
import 'package:pottery_tracker/main.dart';

void main() {
  testWidgets('shows the PotteryTracker studio shell', (tester) async {
    await tester.pumpWidget(const PotteryTrackerApp());

    expect(find.text('PotteryTracker'), findsOneWidget);
    expect(find.text('Studio'), findsWidgets);
    expect(find.text('Pieces'), findsWidgets);
    expect(find.text('Materials'), findsWidgets);
    expect(find.text('Firings'), findsWidgets);
  });
}
