import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:popover/popover.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/components/custom_confirm_dialog.dart';
import 'package:workcake/providers/providers.dart';

import 'SelectTaskAssignee.dart';
import 'SelectTaskAttachment.dart';

class ShowMoreTaskIcon extends StatefulWidget {
  const ShowMoreTaskIcon({
    Key? key,
    this.task,
    this.addOrRemoveTaskMember,
    this.onAddTaskAttachment,
    this.onDeleteTask
  }) : super(key: key);

  final task;
  final addOrRemoveTaskMember;
  final onAddTaskAttachment;
  final onDeleteTask;

  @override
  State<ShowMoreTaskIcon> createState() => _ShowMoreTaskIconState();
}

class _ShowMoreTaskIconState extends State<ShowMoreTaskIcon> {
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return InkWell(
      onTap: () {
        showPopover(
          context: context,
          backgroundColor: isDark ? Color(0xff2E2E2E) : Colors.white,
          transitionDuration: const Duration(milliseconds: 50),
          direction: PopoverDirection.bottom,
          barrierColor: Colors.transparent,
          width: 176,
          height: 124,
          arrowHeight: 0,
          arrowWidth: 0,
          bodyBuilder: (context) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectTaskAssignee(members: widget.task["assignees"], addOrRemoveTaskMember: widget.addOrRemoveTaskMember),
                Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1),
                SelectTaskAttachment(task: widget.task, onAddTaskAttachment: widget.onAddTaskAttachment),
                Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1),
                // Container(
                //   height: 40,
                //   padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                //   child: Row(
                //     children: [
                //       Icon(PhosphorIcons.eyeSlash, size: 17),
                //       SizedBox(width: 14),
                //       Text("Hide Attachment", style: TextStyle(fontSize: 14))
                //     ]
                //   )
                // ),
                // Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1),
                // Container(
                //   height: 40,
                //   padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                //   child: Row(
                //     children: [
                //       Icon(PhosphorIcons.copySimple, size: 17),
                //       SizedBox(width: 14),
                //       Text("Duplicate Item", style: TextStyle(fontSize: 14))
                //     ]
                //   ),
                // ),
                // Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (dialogContex)  {
                        return CustomConfirmDialog(
                          title: "Delete task",
                          subtitle: "Do you want to download this task",
                          onConfirm: () async {
                            widget.onDeleteTask();
                          }
                        );
                      }
                    );
                  },
                  child: Container(
                    height: 40,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.trashSimple, size: 17, color: Color(0xffFF7875)),
                        SizedBox(width: 14),
                        Text("Delete", style: TextStyle(fontSize: 14, color: Color(0xffFF7875)))
                      ]
                    ),
                  ),
                ),
              ],
            )
          )
        );
      },
      child: Container(
        height: 24,
        width: 24,
        child: Icon(Icons.more_vert, size: 18, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight))
    );
  }
}