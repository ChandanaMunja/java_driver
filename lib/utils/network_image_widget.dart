import 'package:cached_network_image/cached_network_image.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/themes/responsive.dart';
import 'package:flutter/material.dart';

bool _isHttpUrl(String url) {
  final u = url.trim();
  return u.startsWith('http://') || u.startsWith('https://');
}

class NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final Widget? errorWidget;
  final BoxFit? fit;
  final double? borderRadius;
  final Color? color;

  const NetworkImageWidget({
    super.key,
    this.height,
    this.width,
    this.fit,
    required this.imageUrl,
    this.borderRadius,
    this.errorWidget,
    this.color,
  });

  Widget _fallbackPlaceholder(BuildContext context) {
    final h = height ?? Responsive.height(8, context);
    final w = width ?? Responsive.width(15, context);
    final ph = Constant.placeHolderImage.trim();
    if (ph.isNotEmpty && _isHttpUrl(ph)) {
      return Image.network(
        ph,
        fit: fit ?? BoxFit.fitWidth,
        height: h,
        width: w,
      );
    }
    Widget inner = Icon(
      Icons.person_rounded,
      size: (h < w ? h : w) * 0.45,
      color: Colors.grey.shade600,
    );
    final box = Container(
      height: h,
      width: w,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: inner,
    );
    if (borderRadius != null && borderRadius! > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: box,
      );
    }
    return box;
  }

  @override
  Widget build(BuildContext context) {
    final safeUrl = imageUrl.trim();
    if (safeUrl.isEmpty) {
      return errorWidget ?? _fallbackPlaceholder(context);
    }

    return CachedNetworkImage(
      imageUrl: safeUrl,
      fit: fit ?? BoxFit.fitWidth,
      height: height ?? Responsive.height(8, context),
      width: width ?? Responsive.width(15, context),
      color: color,
      progressIndicatorBuilder: (context, url, downloadProgress) => Constant.loader(),
      errorWidget: (context, url, error) =>
          errorWidget ?? _fallbackPlaceholder(context),
    );
  }
}
