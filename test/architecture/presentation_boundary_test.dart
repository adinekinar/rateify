import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// §18.8 repository rule, enforced as an actual test rather than a manual
/// code-review step (TC-CONV-028 and its equivalents in later features):
/// no file under any feature's `presentation/` directory may import `dio`
/// or `hive` directly — only `data/` and the composition root
/// (`lib/main.dart`) are allowed to.
void main() {
  test('no presentation-layer file imports dio or hive directly', () {
    final libDir = Directory('lib');
    final offendingFiles = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (!entity.path.contains(
        '${Platform.pathSeparator}presentation${Platform.pathSeparator}',
      )) {
        continue;
      }

      final content = entity.readAsStringSync();
      final importsForbiddenPackage = RegExp(
        r'''import\s+['"]package:(dio|hive|hive_flutter)/''',
      ).hasMatch(content);
      if (importsForbiddenPackage) {
        offendingFiles.add(entity.path);
      }
    }

    expect(
      offendingFiles,
      isEmpty,
      reason:
          'presentation-layer files must not import dio/hive directly: $offendingFiles',
    );
  });
}
