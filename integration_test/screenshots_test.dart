// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pottery_tracker/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture the main pottery tracker screens', (tester) async {
    app.main();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('01-studio');

    // Create a finished piece first. Sale records must link to a finished piece.
    await tester.tap(find.text('Pieces').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add pieces'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Hand-thrown stoneware vase');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finished').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02-pieces');

    await tester.tap(find.text('Materials').last);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('03-materials');

    await tester.tap(find.text('Firings').last);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('04-firings');

    await tester.tap(find.text('For Sale').last);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('05-for-sale-empty');

    await tester.tap(find.text('Add finished item'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Hand-thrown stoneware vase').last);
    await tester.tap(find.text('Hand-thrown stoneware vase').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '68.00 USD');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('06-for-sale-item');

    await tester.tap(find.byTooltip('Create listing'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('07-marketplace-listing');
  });
}
