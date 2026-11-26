import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final platform = Platform.environment['SCREENSHOT_PLATFORM'] ?? 'unknown';
  final output = Directory('screenshots/$platform')..createSync(recursive: true);

  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('${output.path}/$name.png');
      await file.writeAsBytes(bytes, flush: true);
      print('Saved screenshot: ${file.path}');
      return true;
    },
  );
}
