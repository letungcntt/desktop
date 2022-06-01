// ignore_for_file: body_might_complete_normally_nullable

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:workcake/common/utils.dart';

import 'cached_image.dart';

class CachedAvatar extends StatelessWidget {
  final imageUrl;
  final bool isRound;
  final double radius;
  final double height;
  final double width;
  final BoxFit fit;
  final String? name;
  final bool isAvatar;
  final bool full;
  final double fontSize;

  final String noImageAvailable = "https://statics.pancake.vn/web-media/3e/24/0b/bb/09a144a577cf6867d00ac47a751a0064598cd8f13e38d0d569a85e0a.png";

  CachedAvatar(
    this.imageUrl, {
    required this.name,
    required this.width,
    required this.height,
    this.isRound = false,
    this.fit = BoxFit.cover,
    this.isAvatar = false,
    this.fontSize = 12,
    this.full = false, 
    this.radius = 50,
  });
  
  @override
  Widget build(BuildContext context) {
    try {
      return SizedBox(
        height: height,
        width: width,
        child: (!Utils.checkedTypeEmpty(imageUrl) || imageUrl == noImageAvailable) 
        ? DefaultAvatar(name: name, fontSize: fontSize, radius: 100)
        : ClipOval(
          child: Container(
            child: ExtendedImage.network(
              (imageUrl != null && imageUrl != "") ? imageUrl : noImageAvailable,
              fit: BoxFit.cover,
              key: Key(imageUrl),
              repeat: ImageRepeat.repeat,
              cacheHeight: (height*2).toInt(),
              retries: 1,
              cache: true,
              filterQuality: FilterQuality.high,
              cacheMaxAge: Duration(days: 10),
              loadStateChanged: (ExtendedImageState state) {
                // if (state.extendedImageLoadState == LoadState.loading) {
                //   return DefaultAvatar(name: name, radius: radius);
                // } 
                if (state.extendedImageLoadState == LoadState.failed) {
                  return DefaultAvatar(name: name, radius: radius);
                }
              }
            ),
          )
        ),
      );
    } catch (e) {
      return Container( 
        child: DefaultAvatar(name: name, radius: radius)
      );
    }
  }
}