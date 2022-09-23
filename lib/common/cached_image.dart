import 'dart:math';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:workcake/common/utils.dart';

import '../components/widget_text.dart';

class CachedImage extends StatelessWidget {
  final imageUrl;
  final isRound;
  final double radius;
  final double? height;
  final double? width;
  final BoxFit fit;
  final name;
  final isAvatar;
  final full;
  final double fontSize;

  final noImageAvailable = "https://statics.pancake.vn/web-media/3e/24/0b/bb/09a144a577cf6867d00ac47a751a0064598cd8f13e38d0d569a85e0a.png";

  CachedImage(
    this.imageUrl, {
    this.isRound = false,
    this.radius = 0,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.name = "",
    this.isAvatar = false,
    this.full = false,
    this.fontSize = 12
  });
  
  @override
  Widget build(BuildContext context) {
    try {
      return SizedBox(
        height: isRound ? radius : height,
        width: isRound ? radius : width,
        child: (!Utils.checkedTypeEmpty(imageUrl) || imageUrl == noImageAvailable) 
        ? DefaultAvatar(name: name, fontSize: fontSize, radius: radius)
        : ClipRRect(
          borderRadius: BorderRadius.circular(isRound ? 50 : radius),
          child: ExtendedImage.network(
            (imageUrl != null && imageUrl != "") ? imageUrl : noImageAvailable,
            key: Key(imageUrl),
            fit: fit,
            cacheWidth: isAvatar ? 100 : !full ? 720 : null,
            repeat: ImageRepeat.repeat,
            cache: true,
            cacheMaxAge: Duration(days: 10),
          )
        ),
      );
    } catch (e) {
      return Container( 
        height: 25,
        width: 25,
        child: DefaultAvatar(name: name, radius: radius)
      );
    }
  }
}

class DefaultAvatar extends StatelessWidget {
  const DefaultAvatar({
    Key? key,
    this.name = "",
    this.fontSize = 12.0,
    this.radius = 2
  }) : 
  super();

  final name;
  final double radius;
  final double fontSize;

  getColorAvatar(letter) {
    List alphabets = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"];

    final index = alphabets.indexWhere((e) => e == letter);
    return index;
  }

  @override
  Widget build(BuildContext context) {
    final firstLetter = (Utils.checkedTypeEmpty(name) ? name : "P").substring(0, 1).toUpperCase();
    final index = getColorAvatar(firstLetter) + 1;
    
    return !Utils.checkedTypeEmpty(name) ? Container() : Container(
      decoration: BoxDecoration(
        color: Color(((index + 1) * pi * 0.1 * 0xFFFFFF).toInt()).withOpacity(1.0),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 20,
        child: TextWidget(
          firstLetter,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            color: Colors.white
          ),
        ),
      ),
    );
  }
}