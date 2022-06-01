import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/components/custom_confirm_dialog.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/models/models.dart';

class AttachmentItem extends StatefulWidget {
  const AttachmentItem({
    Key? key,
    this.attachment,
    this.onDeleteAttachment,
  }) : super(key: key);

  final attachment;
  final onDeleteAttachment;

  @override
  State<AttachmentItem> createState() => _AttachmentItemState();
}

class _AttachmentItemState extends State<AttachmentItem> {
  bool onHover = false;

  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachment;
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
            child: (attachment["type"] == "image" || attachment["mime_type"] == "image") ? 
              CachedImage(attachment["content_url"], width: 66, height: 84, radius: 2) : InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (dialogContex)  {
                    return CustomConfirmDialog(
                      title: "Download attachment",
                      subtitle: "Do you want to download ${attachment["file_name"]}",
                      onConfirm: () async {
                        Provider.of<Work>(context, listen: false).addTaskDownload({"content_url": attachment["content_url"], "name": attachment["file_name"]});
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
                child: attachment["uploading"] == true ? Icon(PhosphorIcons.spinner, color: Colors.grey[600], size: 32) : Icon(Icons.file_download_outlined, color: Colors.grey[600], size: 32)
              )
            )
          ),
          if (onHover) Positioned(
            top: 2,
            right: 10,
            child: InkWell(
              onTap: () {
                widget.onDeleteAttachment(widget.attachment);
              },
              child: Icon(PhosphorIcons.x, size: 18)
            )
          )
        ]
      )
    );
  }
}
