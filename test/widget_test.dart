import 'package:flutter_test/flutter_test.dart';
import 'package:pottery_tracker/main.dart';

void main() {
  testWidgets('shows the Pottery Manager studio shell', (tester) async {
    await tester.pumpWidget(const PotteryTrackerApp());

    expect(find.text('Pottery Manager'), findsOneWidget);
    expect(find.text('Studio'), findsWidgets);
    expect(find.text('Pieces'), findsWidgets);
    expect(find.text('Materials'), findsWidgets);
    expect(find.text('Firings'), findsWidgets);
  });
  testWidgets('shows app and bundled third-party license notices', (tester) async {
    await tester.pumpWidget(const PotteryTrackerApp());
    await tester.tap(find.byTooltip('About and open-source licenses'));
    await tester.pumpAndSettle();

    expect(find.text('About Pottery Manager'), findsOneWidget);
    await tester.tap(find.text('Open-source licenses'));
    await tester.pumpAndSettle();

    expect(find.text('Licenses'), findsOneWidget);
    expect(find.textContaining('Pottery Manager'), findsWidgets);
    expect(find.textContaining('MIT License'), findsWidgets);
  });
}
