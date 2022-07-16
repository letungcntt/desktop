import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:workcake/common/utils.dart';

  class StickerFile extends StatefulWidget {
    StickerFile({
      Key? key,
      this.data,
      this.isPreview = false
    }) : super(key: key);

    final data;
    final bool isPreview;

    @override
    _StickerFileState createState() => _StickerFileState();
  }

class _StickerFileState extends State<StickerFile> with TickerProviderStateMixin{
  bool isAnimate = false;

  @override
  void initState() {
    if(widget.isPreview) onChangeIsRepeat();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  onChangeIsRepeat() {
    setState(() => isAnimate = true);
    Future.delayed(Duration(milliseconds: 3100), () {
      if(this.mounted) setState(() => isAnimate = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    if(Utils.isWinOrLinux()) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12),
        width: widget.isPreview ? null : 140.0, height: widget.isPreview ? null : 140.0,
        child: Lottie.network(
          data["content_url"],
        )
      );
    }

    return widget.isPreview ? MouseRegion(
      onHover: (value) {
        setState(() {
          isAnimate = true;
        });
      },
      onExit: (value) {
        onChangeIsRepeat();
      },
      child: Lottie.network(
        data["content_url"],
        animate: isAnimate,
      ),
    ) : Column(
      children: [
        MouseRegion(
          onHover: (value) {
            setState(() {
              isAnimate = true;
            });
          },
          onExit: (value) {
            onChangeIsRepeat();
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            width: 140, height: 140,
            child: Lottie.network(
              data["content_url"],
              animate: isAnimate,
              repeat: isAnimate
            )
          ),
        ),
      ],
    );
  }
}