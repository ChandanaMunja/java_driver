import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final File? imageFile;

  const FullScreenImageViewer({super.key, required this.imageUrl, this.imageFile});

  @override
  Widget build(BuildContext context) {
    final safeUrl = imageUrl.trim();
    final ph = Constant.placeHolderImage.trim();
    final useNetworkPlaceholder =
        ph.isNotEmpty &&
            (ph.startsWith('http://') || ph.startsWith('https://'));

    if (imageFile == null &&
        safeUrl.isEmpty &&
        !useNetworkPlaceholder) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        body: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: Hero(
            tag: imageUrl,
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: MediaQuery.sizeOf(context).shortestSide * 0.2,
            ),
          ),
        ),
      );
    }

    final imageProvider = imageFile != null
        ? Image.file(imageFile!).image
        : NetworkImage(
            safeUrl.isNotEmpty ? safeUrl : ph,
          );

    return Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        body: Container(
          color: Colors.black,
          child: Hero(
            tag: imageUrl,
            child: PhotoView(
              imageProvider: imageProvider,
            ),
          ),
        ));
  }
}
