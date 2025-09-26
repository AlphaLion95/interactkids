import 'dart:io';
import 'package:image/image.dart' as img;

/// Simple utility: scan PNG files under assets/images/fruits/Fruits and
/// report whether any pixel has alpha < 255.
void main() {
  final dir = Directory('assets/images/fruits/Fruits');
  if (!dir.existsSync()) {
    print('Directory not found: ${dir.path}');
    return;
  }
  for (final f in dir.listSync()) {
    if (f is File && f.path.toLowerCase().endsWith('.png')) {
      final name = f.uri.pathSegments.last;
      try {
        final fileBytes = f.readAsBytesSync();
        final image = img.decodeImage(fileBytes);
        if (image == null) {
          print('$name: not an image');
          continue;
        }
        bool hasTransparent = false;
        // Use raw bytes (typically RGBA) to read alpha consistently.
        final raw = image.getBytes();
        final width = image.width;
        for (var y = 0; y < image.height && !hasTransparent; y++) {
          for (var x = 0; x < width; x++) {
            final idx = (y * width + x) * 4;
            final a = raw[idx + 3];
            if (a != 255) {
              hasTransparent = true;
              break;
            }
          }
        }
        print(
            '$name: alpha present? ${hasTransparent ? 'YES' : 'NO (fully opaque)'}');
      } catch (e) {
        print('$name: error $e');
      }
    }
  }
}
