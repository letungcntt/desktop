import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/components/custom_confirm_dialog.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/providers/providers.dart';

class AttachmentItem extends StatefulWidget {
  const AttachmentItem({
    Key? key,
    required this.attachments,
    this.onDeleteAttachment,
    required this.index
  }) : super(key: key);

  final attachments;
  final onDeleteAttachment;
  final int index;

  @override
  State<AttachmentItem> createState() => _AttachmentItemState();
}

class _AttachmentItemState extends State<AttachmentItem> {
  bool onHover = false;

  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachments[widget.index];
    var isDark  = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;

    return HoverItem(
      showTooltip: true,
      tooltip: Container(
        color: isDark ? Color(0xFF1c1c1c): Colors.white,
        child: Text(attachment["file_name"])
      ),
      onHover: () {
        this.setState(() { onHover = true; });
      },
      onExit: () {
        this.setState(() { onHover = false; });
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Color(0xff5E5E5E)
              ),
              borderRadius: BorderRadius.circular(4)
            ),
            height: 84,
            width: 66,
            margin: EdgeInsets.only(right : 8),
            child: (attachment["type"] == "image" || attachment["mime_type"] == "image") ? InkWell(
              child: CachedImage(attachment["content_url"], width: 66, height: 84, radius: 2),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Container(
                      child: AlertDialog(
                        backgroundColor: isDark ? Color(0xff3D3D3D) : Colors.white,
                        contentPadding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        content: Container(
                            height: 810.0,
                            width: 1200.0,
                            child: Center(
                              child: ImageViewerKabanMode(
                                listImage: widget.attachments,
                                index: widget.index,
                                isDark: isDark,
                              )
                            )
                        ),
                      ),
                    );
                  }
                );
              },
            ) : InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogContex)  {
                    return CustomConfirmDialog(
                      title: "Download attachment",
                      subtitle: "Do you want to download ${attachment["file_name"]}",
                      onConfirm: () async {
                        Provider.of<Work>(context, listen: false).addTaskDownload({"content_url": attachment["content_url"], "name": attachment["file_name"], "version": attachment["version"]});
                      }
                    );
                  }
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.grey[400]
                ),
                child: attachment["uploading"] == true ? Icon(PhosphorIcons.spinner, color: Colors.grey[600], size: 32) : Icon(PhosphorIcons.folder, color: Colors.grey[600], size: 32)
              )
            )
          ),
          if (onHover) Positioned(
            top: 2,
            right: 10,
            child: InkWell(
              onTap: () {
                widget.onDeleteAttachment(widget.attachments[widget.index]);
              },
              child: Icon(PhosphorIcons.x, size: 18, color: Palette.topicTile,)
            )
          )
        ]
      )
    );
  }
}

class ImageViewerKabanMode extends StatefulWidget {
  final List listImage;
  final int index;
  final bool isDark;

  const ImageViewerKabanMode({
    Key? key,
    required this.listImage,
    required this.index,
    required this.isDark
  }) : super(key: key);

  @override
  _ImageViewerKabanModeState createState() => _ImageViewerKabanModeState();
}

class _ImageViewerKabanModeState extends State<ImageViewerKabanMode> {
  var imageIndex;
  ScrollController controller = ScrollController();

  @override
  void initState() {
    imageIndex = widget.index;
    RawKeyboard.instance.addListener(handleEvent);
    super.initState();
  }

  handleEvent(RawKeyEvent event) {
    if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)){
      if (imageIndex < widget.listImage.length - 1) {
        setState(() => imageIndex += 1);
      }
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)){
      if (imageIndex > 0) {
        setState(() => imageIndex -= 1);
      }
    }

    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(handleEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.listImage[imageIndex];
    final bool isDark = widget.isDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Column(
              children: [
                Container(
                  alignment: Alignment.topCenter,
                  height: constraints.maxHeight*0.75,
                  margin: EdgeInsets.only(top: 30, bottom: 10),
                  padding: EdgeInsets.symmetric(horizontal: 120),
                  child: ExtendedImage.network(
                    data['content_url'] ?? '',
                    clearMemoryCacheWhenDispose: true,
                    enableMemoryCache: true,
                    fit: BoxFit.contain,
                  )
                ),
                Expanded(
                  child: Container(
                    width: constraints.maxWidth,
                    margin: EdgeInsets.symmetric(horizontal: 40),
                    child: Scrollbar(
                      thickness: 6.0,
                      controller: controller,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: ListView.builder(
                          controller: controller,
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.listImage.length,
                          itemBuilder: (context, int index) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  imageIndex = index;
                                });
                              },
                              overlayColor: MaterialStateProperty.all(Colors.transparent),
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: imageIndex == index ? (isDark ? Palette.calendulaGold : Palette.dayBlue) : Colors.transparent,
                                    width: 1.75
                                  ),
                                  borderRadius: BorderRadius.all(Radius.circular(4))
                                ),
                                width: 128, height: 80,
                                child: ExtendedImage.network(
                                  widget.listImage[index]['content_url'] ?? '',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          }
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16)
              ],
            ),
            AnimatedPositioned(
              duration: Duration(milliseconds: 200),
              top: 30.0,
              child: Container(
                height: 50,
                alignment: Alignment.centerRight,
                width: constraints.maxWidth,
                padding: EdgeInsets.only(right: 40),
                child: InkWell(
                  focusNode: FocusNode(skipTraversal: true),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
                      borderRadius: BorderRadius.all(Radius.circular(24))
                    ),
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      PhosphorIcons.xThin,
                      size: 20.0, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight
                    ),
                  )
                )
              )
            ),
            AnimatedPositioned(
              duration: Duration(milliseconds: 200),
              top: (constraints.maxHeight-120)/2,
              child: Container(
                height: 50,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 40),
                width: constraints.maxWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      focusNode: FocusNode(skipTraversal: true),
                      onTap: () {
                        if (imageIndex > 0) {
                          setState(() => imageIndex -= 1);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                          border: Border.all(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                        ),
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          PhosphorIcons.caretLeftThin,
                          size: 22.0, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight
                        ),
                      )
                    ),
                    InkWell(
                      focusNode: FocusNode(skipTraversal: true),
                      onTap: () {
                        if (imageIndex < widget.listImage.length - 1) {
                          setState(() => imageIndex += 1);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                          border: Border.all(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                        ),
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          PhosphorIcons.caretRightThin,
                          size: 22.0, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight
                        ),
                      )
                    ),
                  ],
                )
              )
            ),
          ],
        );
      }
    );
  }
}
