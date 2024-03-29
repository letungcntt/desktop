import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:popover/popover.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/components/boardview/CardItem.dart';
import 'package:workcake/components/custom_confirm_dialog.dart';
import 'package:workcake/providers/providers.dart';

import 'TaskItem.dart';

class ChecklistItem extends StatefulWidget {
  const ChecklistItem({
    Key? key,
    this.checklist,
    this.indexChecklist,
    this.deleteChecklist
  }) : super(key: key);

  final checklist;
  final indexChecklist;
  final deleteChecklist;

  @override
  State<ChecklistItem> createState() => _ChecklistItemState();
}

class _ChecklistItemState extends State<ChecklistItem> {
  TextEditingController taskController = TextEditingController();
  bool onAddTask = false;
  bool editChecklistTitle = false;
  TextEditingController titleController = TextEditingController();

  onEditChecklistTitle(value) {
    this.setState(() {
      editChecklistTitle = true;
    });
    titleController.text = widget.checklist["title"];
  }

  updateChecklist() {
    final token = Provider.of<Auth>(context, listen: false).token;
    CardItem? card =  Provider.of<Boards>(context, listen: false).selectedCard;
    if (card == null || titleController.text.trim() == "") return;
    Provider.of<Boards>(context, listen: false).updateChecklist(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id, widget.checklist["id"], titleController.text);
    widget.checklist["title"] = titleController.text;
    titleController.clear();
    this.setState(() {
      editChecklistTitle = false;
    });
  }

  onDeleteTask(index) {
    final token = Provider.of<Auth>(context, listen: false).token;
    CardItem? card =  Provider.of<Boards>(context, listen: false).selectedCard;
    if (card != null) {
      Provider.of<Boards>(context, listen: false).deleteChecklistOrTask(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id, widget.checklist["id"],  widget.checklist["tasks"][index]["id"]);
    }
    this.setState(() {
      widget.checklist["tasks"].removeAt(index);
    });
  }

  onAddNewTask(title, index) {
    final token = Provider.of<Auth>(context, listen: false).token;
    CardItem? card = Provider.of<Boards>(context, listen: false).selectedCard;

    if (card == null) {
      this.setState(() {
        widget.checklist["tasks"].add({"title": title, "assignees": [], 'attachments': [], 'value': false});
      });
    } else {
      Provider.of<Boards>(context, listen: false).createOrChangeTask(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id, widget.checklist["id"], title, false, null).then((res) {
        this.setState(() {
          widget.checklist["tasks"].add({"title": title, "assignees": [], 'attachments': [], 'value': false, "id": res["task"]["id"]});
        });
      });
    }
  }

  onCheckAll(value) {
    widget.checklist["tasks"].forEach((item) => item["value"] = value);
    this.setState(() {});

    final token = Provider.of<Auth>(context, listen: false).token;
    CardItem? card =  Provider.of<Boards>(context, listen: false).selectedCard;
    if (card == null) return;
    Provider.of<Boards>(context, listen: false).checkAllTask(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id, widget.checklist["id"], value);
  }

  @override
  Widget build(BuildContext context) {
    var checklist = widget.checklist;
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 12),
          padding: EdgeInsets.only(left: 14, bottom: 3),
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? Color(0xff2E2E2E) : Color(0xffEAE8E8),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            )
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              !editChecklistTitle ? Text(checklist["title"], style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight)) : Expanded(
                child: TextFormField(
                  autofocus: true,
                  onEditingComplete: () {
                    updateChecklist();
                  },
                  controller: titleController,
                  style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Please input checklist title",
                    hintStyle: TextStyle(color: Color(0xffA6A6A6), fontSize: 14),
                    contentPadding: EdgeInsets.only(left: 2, bottom: 8),
                    border: InputBorder.none
                  )
                )
              ),
              ShowMoreChecklistItem(
                indexChecklist: widget.indexChecklist, 
                deleteChecklist: widget.deleteChecklist, 
                onCheckAll: onCheckAll, 
                onEditChecklistTitle: onEditChecklistTitle, 
                editChecklistTitle: editChecklistTitle
              )
            ]
          )
        ),
        Wrap(
          direction: Axis.vertical,
          children: checklist["tasks"].map<Widget>((task) {
            final index = checklist["tasks"].indexOf(task);
            return TaskItem(task: task, index: index, onDeleteTask: onDeleteTask, checklist: checklist);
          }).toList(),
        ),
        Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1),
        (onAddTask || checklist["isNew"] == true) ? Container(
          padding: EdgeInsets.only(left: 4, bottom: 2),
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? Color(0xff2E2E2E) : Color(0xffF8F8F8),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.only(top: 2, left: 1),
                child: Transform.scale(
                  scale: 0.9,
                  child: Checkbox(
                    onChanged: (bool? value) {  },
                    value: false
                  ),
                ),
              ),
              SizedBox(width: 5),
              Expanded(
                child: Focus(
                  onFocusChange: (focus) {
                    if (!focus) {
                      setState(() { onAddTask = false; });
                      widget.checklist["isNew"] = false;
                    }
                  },
                  child: TextFormField(
                    autofocus: true,
                    onEditingComplete: () {
                      if (taskController.text.trim() != "") {
                        onAddNewTask(taskController.text.trim(), widget.indexChecklist);
                      }
                      taskController.clear();
                    },
                    controller: taskController,
                    style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Please input task name",
                      hintStyle: TextStyle(color: Color(0xffA6A6A6), fontSize: 14),
                      contentPadding: EdgeInsets.only(left: 2, bottom: 8),
                      border: InputBorder.none
                    )
                  ),
                )
              )
            ]
          )
        ) : InkWell(
          onTap: () {
            setState(() { onAddTask = true; });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Color(0xff444444) : Color(0xffF8F8F8),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              )
            ),
            height: 40,
            padding: EdgeInsets.only(left: 7),
            child: Row(
              children: [
                Icon(PhosphorIcons.plusCircle, size: 18, color: isDark ? Color(0xffC9C9C9) : Color(0xff5E5E5E)),
                SizedBox(width: 12),
                Text("New Task", style: TextStyle(color: isDark ? Color(0xffC9C9C9) : Color(0xff5E5E5E), fontSize: 14)),
              ]
            )
          ),
        )
      ]
    );
  }
}

class ShowMoreChecklistItem extends StatefulWidget {
  const ShowMoreChecklistItem({
    Key? key,
    this.deleteChecklist,
    this.indexChecklist,
    this.onCheckAll,
    this.onEditChecklistTitle,
    this.editChecklistTitle
  }) : super(key: key);

  final deleteChecklist;
  final indexChecklist;
  final onCheckAll;
  final onEditChecklistTitle;
  final editChecklistTitle;

  @override
  State<ShowMoreChecklistItem> createState() => _ShowMoreChecklistItemState();
}

class _ShowMoreChecklistItemState extends State<ShowMoreChecklistItem> {
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
          width: 142,
          height: 165,
          arrowHeight: 0,
          arrowWidth: 0,
          bodyBuilder: (context) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)
              )
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    widget.onEditChecklistTitle(true);
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 40,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.pencilSimpleLine, size: 17),
                        SizedBox(width: 14),
                        Text("Edit Title", style: TextStyle(fontSize: 14))
                      ]
                    )
                  )
                ),
                Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1),
                InkWell(
                  onTap: () {
                    widget.onCheckAll(true);
                  },
                  child: Container(
                    height: 40,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.check, size: 17),
                        SizedBox(width: 14),
                        Text("Check All", style: TextStyle(fontSize: 14))
                      ]
                    )
                  ),
                ),
                Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1),
                InkWell(
                  onTap: () {
                    widget.onCheckAll(false);
                  },
                  child: Container(
                    height: 40,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.x, size: 17),
                        SizedBox(width: 14),
                        Text("Uncheck All", style: TextStyle(fontSize: 14))
                      ]
                    )
                  ),
                ),
                Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (dialogContex)  {
                        return CustomConfirmDialog(
                          title: "Delete checklist",
                          subtitle: "Do you want to download this checklist",
                          onConfirm: () async {
                            widget.deleteChecklist(widget.indexChecklist);
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
                        Icon(PhosphorIcons.trashSimple, size: 17, color: Color(0xffFF7875),),
                        SizedBox(width: 14),
                        Text("Delete", style: TextStyle(fontSize: 14, color: Color(0xffFF7875)))
                      ]
                    )
                  ),
                )
              ]
            ),
          )
        );
      },
      child: Container(
        margin: EdgeInsets.only(right: 2),
        child: Icon(Icons.more_vert, size: 20, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight)
      ),
    );
  }
}
