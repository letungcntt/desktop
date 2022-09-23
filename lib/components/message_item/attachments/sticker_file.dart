import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/providers/providers.dart';

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

  showModalPreview(bool isDark, data) {
    showModal(
      context: context, builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          content: Container(
            width: 400, height: 480,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight.withOpacity(0.75))
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'Preview image',
                          style: TextStyle(
                            color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                            fontWeight: FontWeight.w500, fontSize: 16
                          ),
                        )
                      ),
                      InkWell(
                        child: Icon(
                          PhosphorIcons.xCircle,
                        size: 20, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                        ),
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  )
                ),
                Expanded(
                  child: ExtendedImage.network(data["content_url"])
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final bool isDark = Provider.of<Auth>(context).theme == ThemeType.DARK;

    if(Utils.isWinOrLinux()) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12),
        width: widget.isPreview ? null : 140.0, height: widget.isPreview ? null : 140.0,
        child: data['type'] != 'static' ? Lottie.network(
          data["content_url"],
        ) : ExtendedImage.network(data["content_url"])
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
      child: data['type'] != 'static' ? Lottie.network(
        data["content_url"],
        animate: isAnimate,
      ) : GestureDetector(
        onLongPress: () => showModalPreview(isDark, data),
        onSecondaryTap: () => showModalPreview(isDark, data),
        child: ExtendedImage.network(
          data["content_url"],
        ),
      ),
    ) : MouseRegion(
      onHover: (value) {
        setState(() {
          isAnimate = true;
        });
      },
      onExit: (value) {
        onChangeIsRepeat();
      },
      child: data['type'] != 'static' ? Container(
        padding: EdgeInsets.symmetric(horizontal: 12),
        width: 140, height: 140,
        child:  Lottie.network(
          data["content_url"],
          animate: isAnimate,
          repeat: isAnimate
        ),
      ) : Container(
        width: data['name'] == 'DOG_HAHAHA' ? 160 : 250, height: data['name'] == 'DOG_HAHAHA' ? 160 : 250,
        child: ExtendedImage.network(data["content_url"])
      ),
    );
  }
}