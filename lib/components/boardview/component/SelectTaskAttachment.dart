import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SelectTaskAttachment extends StatefulWidget {
  const SelectTaskAttachment({
    Key? key,
    this.task,
    this.onAddTaskAttachment
  }) : super(key: key);

  final task;
  final onAddTaskAttachment;

  @override
  State<SelectTaskAttachment> createState() => _SelectTaskAttachmentState();
}

class _SelectTaskAttachmentState extends State<SelectTaskAttachment> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        widget.onAddTaskAttachment();
      },
      child: Container(
        height: 40,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(PhosphorIcons.paperclip, size: 17),
            SizedBox(width: 14),
            Text("Attachment", style: TextStyle(fontSize: 14))
          ]
        ),
      ),
    );
  }
}
