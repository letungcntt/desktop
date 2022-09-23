import 'package:flutter/material.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/common/video_player.dart';
import 'package:workcake/components/message_item/attachments/image_detail.dart';
import 'package:workcake/components/message_item/attachments/images_gallery.dart';

class MarkdownAttachment extends StatefulWidget {
  MarkdownAttachment({
    Key? key,
    required this.alt,
    required this.uri
  }) : super(key: key);

  final alt;
  final uri;

  @override
  State<MarkdownAttachment> createState() => _MarkdownAttachmentState();
}

class _MarkdownAttachmentState extends State<MarkdownAttachment> {
  @override
  Widget build(BuildContext context) {
    String alt = widget.alt ?? "";
    final uri = widget.uri;
    var tag = Utils.getRandomString(30);

    return (alt.toLowerCase().contains('.mp4') || alt.contains(".mov")) ? VideoPlayer(att: {"content_url": uri.toString(), "name": alt})
    : GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            barrierDismissible: true,
            barrierLabel: '',
            opaque: false,
            barrierColor: Colors.black.withOpacity(1.0),
            pageBuilder: (context, _, __) => ImageDetail(url: "$uri", id: tag, full: true, tag: tag)
          )
        );
      },
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 400,
          maxWidth: 750
        ),
        child: ImageItem(
          tag: uri,
          img: {
            'content_url': uri.toString(),
            'name': alt
          }, 
          previewComment: true,
          isConversation: false,
          failed: !(alt.toLowerCase().contains('jpg')
            || alt.toLowerCase().contains('jpeg')
            || alt.toLowerCase().contains('png')
            || alt.toLowerCase().contains("image")
            || alt.toLowerCase().contains("img")) ? true : null,
        )
      )
    );
  }
}