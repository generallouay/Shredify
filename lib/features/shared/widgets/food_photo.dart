import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Renders a food photo from either a local file path or a remote URL.
class FoodPhoto extends StatelessWidget {
  final String? photoPath;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Widget? placeholder;

  const FoodPhoto({
    super.key,
    this.photoPath,
    this.width = 48,
    this.height = 48,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  bool get _isRemote =>
      photoPath != null &&
      (photoPath!.startsWith('http://') || photoPath!.startsWith('https://'));

  Widget _placeholder() =>
      placeholder ??
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: const Icon(Icons.fastfood_outlined,
            size: 20, color: Colors.white38),
      );

  @override
  Widget build(BuildContext context) {
    if (photoPath == null) return _placeholder();

    final radius = borderRadius ?? BorderRadius.circular(8);

    if (_isRemote) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: photoPath!,
          width: width,
          height: height,
          fit: fit,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _placeholder(),
        ),
      );
    }

    final file = File(photoPath!);
    if (!file.existsSync()) return _placeholder();

    return ClipRRect(
      borderRadius: radius,
      child: Image.file(file, width: width, height: height, fit: fit),
    );
  }
}
