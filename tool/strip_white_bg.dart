// Small utility to strip near-white backgrounds from fruit PNGs and write
// processed versions into a `processed/` subfolder. Run with:
// dart run tool/strip_white_bg.dart

import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final srcDir = Directory('assets/images/fruits/Fruits');
  if (!srcDir.existsSync()) {
    print('Source directory not found: ${srcDir.path}');
    return;
  }
  final outDir = Directory('${srcDir.path}/processed');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  for (final f in srcDir.listSync()) {
    if (f is File && f.path.toLowerCase().endsWith('.png')) {
      final name = f.uri.pathSegments.last;
      print('Processing $name');
      try {
        final bytes = f.readAsBytesSync();
        final srcImg = img.decodePng(bytes);
        if (srcImg == null) {
          print('  Not a PNG: $name');
          continue;
        }
        // Convert near-white pixels to transparent.
        final out = img.Image.from(srcImg);
        // Read raw bytes (assumed RGBA) to detect near-white pixels.
        final raw = out.getBytes();
        final width = out.width;
        for (var y = 0; y < out.height; y++) {
          for (var x = 0; x < width; x++) {
            final idx = (y * width + x) * 4;
            final r = raw[idx];
            final g = raw[idx + 1];
            final b = raw[idx + 2];
            // If pixel is close to white (all channels >= 240) make it transparent
            if (r >= 240 && g >= 240 && b >= 240) {
              out.setPixelRgba(x, y, r, g, b, 0);
            }
          }
        }
        final outPath = '${outDir.path}/$name';
        File(outPath).writeAsBytesSync(img.encodePng(out));
        print('  Wrote $outPath');
      } catch (e) {
        print('  Error processing $name: $e');
      }
    }
  }
}
