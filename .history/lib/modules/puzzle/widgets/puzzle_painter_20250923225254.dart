import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PuzzlePainter extends CustomPainter {
  final ui.Image image;
  final int rows;
  final int cols;
  final int row;
  final int col;

  PuzzlePainter({
    required this.image,
    required this.rows,
    required this.cols,
    required this.row,
    required this.col,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pieceWidth = image.width / cols;
    final pieceHeight = image.height / rows;

    final src = Rect.fromLTWH(
      col * pieceWidth,
      row * pieceHeight,
      pieceWidth,
      pieceHeight,
    );

    // Inset the destination slightly to avoid any 1px edge clipping
    // when pieces are very small. This also gives a tiny visible border
    // so kids can better identify piece edges.
    final inset = 1.0;
    final dst = Rect.fromLTWH(inset, inset, size.width - inset * 2,
        size.height - inset * 2);

    final paint = Paint()..isAntiAlias = true;
    // Prefer higher quality sampling when scaling down images
    paint.filterQuality = FilterQuality.high;

    // Draw the image patch scaled into the small destination rect.
    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant PuzzlePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.rows != rows ||
        oldDelegate.cols != cols ||
        oldDelegate.row != row ||
        oldDelegate.col != col;
  }
}
