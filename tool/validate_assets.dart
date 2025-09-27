import 'dart:io';
import 'package:image/image.dart' as img;

/// Validator that attempts to decode any raster image file (GIF, PNG, JPG, BMP,
/// TIFF, ICO, TGA, etc.) except certain web/vector/heic formats which we skip.
/// GIFs (including animated) are accepted and reported with frame counts.
void main(List<String> args) {
  final projectRoot = Directory.current.path;
  final fruitsDir = Directory('$projectRoot/assets/images/fruits');
  final veggiesDir = Directory('$projectRoot/assets/images/vegetables');

  final files = <String>[];
  void collect(Directory d) {
    if (!d.existsSync()) return;
    files.addAll(
        d.listSync(recursive: true).whereType<File>().map((f) => f.path));
  }

  collect(fruitsDir);
  collect(veggiesDir);

  // Blacklist formats we explicitly do NOT want to try to decode here.
  final blacklistExt = <String>{'.webp', '.svg', '.heic', '.heif'};

  final valid = <String>[];
  final invalid = <String>[];

  for (final path in files) {
    final lower = path.toLowerCase();
    final ext =
        lower.contains('.') ? lower.substring(lower.lastIndexOf('.')) : '';
    final base = path.split(RegExp(r'[\\/]')).last;
    // Skip dotfiles and zero-length files (e.g. .gitkeep)
    final f = File(path);
    if (base.startsWith('.') || !f.existsSync() || f.lengthSync() == 0) {
      print('SKIP (dot/empty): $path');
      continue;
    }
    if (blacklistExt.contains(ext)) {
      print('SKIP (web/vector): $path');
      continue;
    }

    try {
      final bytes = File(path).readAsBytesSync();

      // Try a regular image decode (PNG, JPEG, GIF first frame, BMP, etc.)
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        print('FAILED: $path (decode returned null)');
        invalid.add(path);
      } else {
        print('OK: $path -> ${decoded.width}x${decoded.height}');
        valid.add(path);
      }
    } catch (e) {
      print('ERROR: $path -> $e');
      invalid.add(path);
    }
  }

  print('\nSummary:');
  print('Valid files (${valid.length}):');
  for (final v in valid) {
    print(' - ${v.replaceFirst('${Directory.current.path}\\', '')}');
  }
  print('\nInvalid files (${invalid.length}):');
  for (final iv in invalid) {
    print(' - ${iv.replaceFirst('${Directory.current.path}\\', '')}');
  }
}
