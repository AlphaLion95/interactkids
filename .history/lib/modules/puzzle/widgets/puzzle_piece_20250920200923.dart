import 'package:flutter/material.dart';



import 'dart:async';
import 'package:flutter/material.dart';
import 'package:interactkids/modules/puzzle/widgets/puzzle_painter.dart';

class PuzzlePiece extends StatelessWidget {
  final ImageProvider imageProvider;
  final int rows;
  final int cols;
  final int row;
  final int col;

  const PuzzlePiece({
    Key? key,
    required this.imageProvider,
    required this.rows,
    required this.cols,
    required this.row,
    required this.col,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageInfo>(
      future: _getImageInfo(imageProvider),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final imageInfo = snapshot.data!;
        final image = imageInfo.image;

        return CustomPaint(
          size: Size.infinite,
          painter: PuzzlePainter(
            image: image,
            rows: rows,
            cols: cols,
            row: row,
            col: col,
          ),
        );
      },
    );
  }

  Future<ImageInfo> _getImageInfo(ImageProvider provider) async {
    final completer = Completer<ImageInfo>();
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((info, _) {
      completer.complete(info);
    });
    stream.addListener(listener);
    return completer.future;
  }
}
