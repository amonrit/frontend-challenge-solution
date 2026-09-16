import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Standard network image with a shimmer placeholder.
class TheNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const TheNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pixelRatio = MediaQuery.devicePixelRatioOf(context);
        final logicalWidth = width != null && width!.isFinite
            ? width
            : constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : null;
        final logicalHeight = height != null && height!.isFinite
            ? height
            : constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : null;
        final memCacheWidth = _decodeDimension(logicalWidth, pixelRatio);
        final memCacheHeight = _decodeDimension(logicalHeight, pixelRatio);

        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            placeholder: (context, _) => Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child:
                  Container(width: width, height: height, color: Colors.white),
            ),
            errorWidget: (context, _, __) => Container(
              width: width,
              height: height,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image_not_supported_outlined),
            ),
          ),
        );
      },
    );
  }

  static int? _decodeDimension(double? logicalSize, double pixelRatio) {
    if (logicalSize == null || !logicalSize.isFinite || logicalSize <= 0) {
      return null;
    }
    final pixels = (logicalSize * pixelRatio).round();
    return pixels > 0 ? pixels : null;
  }
}
