import 'dart:io';
import 'package:image/image.dart' as img;

void main(List<String> args) {
  final root = Directory.current.path;
  final work = {
    'fruits': Directory('$root/assets/images/fruits/Fruits'),
    'vegetables': Directory('$root/assets/images/vegetables'),
  };

  final outRoot = Directory('$root/assets/processed');
  if (!outRoot.existsSync()) outRoot.createSync(recursive: true);

  const maxDim = 1200; // max width/height after resize

  for (final entry in work.entries) {
    final cat = entry.key;
    final dir = entry.value;
    final outDir = Directory('${outRoot.path}/$cat');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    if (!dir.existsSync()) {
      print('No source folder for $cat: ${dir.path}');
      continue;
    }

    final files = dir.listSync(recursive: true).whereType<File>().where((f) {
      final l = f.path.toLowerCase();
      return l.endsWith('.png') ||
          l.endsWith('.jpg') ||
          l.endsWith('.jpeg') ||
          l.endsWith('.gif') ||
          l.endsWith('.bmp');
    }).toList();

    for (final f in files) {
      final name = f.path.split(RegExp(r'[\\/]')).last;
      final outPath = '${outDir.path}/$name';
      try {
        final bytes = f.readAsBytesSync();
        final image = img.decodeImage(bytes);
        if (image == null) {
          print('FAILED decode: ${f.path}');
          continue;
        }
        // Resize if necessary
        final w = image.width;
        final h = image.height;
        img.Image processed = image;
        if (w > maxDim || h > maxDim) {
          processed = img.copyResize(image,
              width: w > h ? maxDim : null,
              height: h >= w ? maxDim : null,
              interpolation: img.Interpolation.average);
        }
        // Ensure 8-bit RGBA and re-encode as PNG to preserve transparency
        final outBytes = img.encodePng(processed, level: 6);
        File(outPath).writeAsBytesSync(outBytes);
        print('WROTE: $outPath -> ${processed.width}x${processed.height}');
      } catch (e) {
        print('ERROR processing ${f.path} -> $e');
      }
    }
  }
  print('Done. Processed files written to ${outRoot.path}');
}
