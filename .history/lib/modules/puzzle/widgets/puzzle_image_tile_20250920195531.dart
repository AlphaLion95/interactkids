import 'dart:io';
import 'package:flutter/material.dart';

class PuzzleImageTile extends StatelessWidget {
  final String imagePath;
  final double progress;
  final VoidCallback onTap;
  const PuzzleImageTile({required this.imagePath, required this.progress, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isAsset = imagePath.startsWith('assets/');
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.18),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              width: 74,
              height: 74,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.10),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: isAsset
                    ? Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.image,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        ),
                      )
                    : Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            color: Colors.orange,
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}
