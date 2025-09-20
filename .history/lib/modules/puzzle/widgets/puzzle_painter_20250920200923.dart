
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

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

    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
