import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme.dart';

class ProductThumb extends StatelessWidget {
  final String? path;
  final double size;
  const ProductThumb({super.key, this.path, this.size = 52});

  Widget _placeholder() => Container(
        color: AppColors.mint,
        child: Icon(Icons.inventory_2_outlined,
            color: AppColors.emerald, size: size * 0.5),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: path == null
            ? _placeholder()
            : Image.file(
                File(path!),
                fit: BoxFit.cover,
                cacheWidth: (size * 3).round(),
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
      ),
    );
  }
}
