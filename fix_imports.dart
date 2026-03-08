import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;

    // Fix absolute imports
    final replacements = {
      'package:poultry_accounting/data/': 'package:poultry_accounting/backend/data/',
      'package:poultry_accounting/domain/': 'package:poultry_accounting/backend/domain/',
      'package:poultry_accounting/presentation/': 'package:poultry_accounting/frontend/presentation/',
      'package:poultry_accounting/config/': 'package:poultry_accounting/frontend/config/',
    };

    for (final entry in replacements.entries) {
      if (content.contains(entry.key)) {
        content = content.replaceAll(entry.key, entry.value);
        changed = true;
      }
    }

    // Fix relative imports in main.dart
    if (file.path.endsWith('main.dart')) {
      if (content.contains("'presentation/")) {
        content = content.replaceAll("'presentation/", "'frontend/presentation/");
        changed = true;
      }
      if (content.contains("'config/")) {
        content = content.replaceAll("'config/", "'frontend/config/");
        changed = true;
      }
      if (content.contains("'data/")) {
        content = content.replaceAll("'data/", "'backend/data/");
        changed = true;
      }
      if (content.contains("'domain/")) {
        content = content.replaceAll("'domain/", "'backend/domain/");
        changed = true;
      }
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Updated: ${file.path}');
    }
  }
}
