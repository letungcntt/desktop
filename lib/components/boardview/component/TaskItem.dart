import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/boardview/CardItem.dart';
import 'package:workcake/models/models.dart';

import 'AttachmentItem.dart';
import 'ListMember.dart';
import 'ShowMoreTaskItem.dart';

class TaskItem extends StatefulWidget {
  final task;
  final onDeleteTask;
  final index;
  final checklist;

  const TaskItem({
    Key? key,
    this.task,
    this.onDeleteTask, 
    this.index,
    this.checklist
  }) : super(key: key);
  
  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  TextEditingController controller = TextEditingController();
  bool onEditTask = false;
  
  @override
  void initState() {
    controller.text = widget.task["title"];
    super.initState();
  }

  onDeleteTask() {
    widget.onDeleteTask(widget.index);
  }

  onAddTaskAttachment() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final attachments = widget.task["attachments"];
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    CardItem? card =  Provider.of<Boards>(context, listen: false).selectedCard;

    try {
      var myMultipleFiles = await Utils.openFilePicker([
        XTypeGroup(
          extensions: ['jpg', 'jpeg', 'gif', 'png', 'xlsx', 'json', 'xls', 'zip', 'docs']
        )
      ]);
      
      for (var e in myMultipleFiles) {
        Map newFile = {
          "filename": e["name"],
          "file_name": e["name"],
          "uploading": true,
          "path":  base64.encode(e["file"])
        };

        setState(() {
          attachments.add(newFile);
        });
      }

      for (var i = 0; i < attachments.length; i++) {
        if (attachments[i]["uploading"] == true) {
          var file = attachments[i];
          final url = Utils.apiUrl + 'workspaces/${currentWorkspace["id"]}/contents?token=$token';
          final body = {
            "file": file,
            "content_type": "image",
            "mime_type": "image",
            "filename": file["filename"]
          };

          Dio().post(url, data: json.encode(body)).then((response) async {
            final responseData = response.data;

            if (responseData["success"] == true) {
              var attachment = {...responseData, 'content_id' : responseData["id"]};
              setState(() {
                attachments[i] = attachment;
              });
              if (card == null) return;
              Provider.of<Boards>(context, listen: false).addTaskAttachment(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id, widget.task["id"], responseData);
            }
          });
        }
      }
    } on Exception catch (e) {
      print("$e Cancel");
    }
  }

  addOrRemoveTaskMember(userId) {
    final token = Provider.of<Auth>(context, listen: false).token;
    final index = widget.task["assignees"].indexWhere((e) => e == userId);
    CardItem? card =  Provider.of<Boards>(context, listen: false).selectedCard;

    if (index == -1) {
      widget.task["assignees"].add(userId);
    } else {
      widget.task["assignees"].removeAt(index);
    }
    setState(() {});

    if (card == null) return;
    Provider.of<Boards>(context, listen: false).addOrRemoveTaskAssignee(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id, widget.task["id"], userId);
  }

  findUser(id) {
    final members = Provider.of<Workspaces>(context, listen: false).members;
    final indexMember = members.indexWhere((e) => e["id"] == id);

    if (indexMember != -1) {
      return members[indexMember];
    } else {
      return {};
    }
  }

  onRemoveTaskAttachment(att) {
    final index =  widget.task["attachments"].indexOf(att);
    final token = Provider.of<Auth>(context, listen: false).token;
    CardItem? card = Provider.of<Boards>(context, listen: false).selectedCard;

    if (index == -1) return;
    setState(() { widget.task["attachments"].removeAt(index); });

    if (card == null) return;
    Provider.of<Boards>(context, listen: false).removeTaskAttachment(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id, widget.task["id"], widget.task["attachments"][index]["content_id"]);
  }

  onEditingTask(title) {
    this.setState(() {
      widget.task["title"] = title;
      onEditTask = false;
    });
    createOrchangeTask();
  }

  onCheckTask(value) {
    this.setState(() {
      if (widget.task["value"] == null ) {
        widget.task["is_checked"] = value;
      } else {
        widget.task["value"] = value;
      }
    });
    createOrchangeTask();
  }

  createOrchangeTask() {
    final token = Provider.of<Auth>(context, listen: false).token;
    CardItem? card = Provider.of<Boards>(context, listen: false).selectedCard;
    if (card == null) return;
    Provider.of<Boards>(context, listen: false).createOrChangeTask(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, 
      card.id, widget.checklist["id"], widget.task["title"], widget.task["is_checked"] ?? widget.task["value"] ?? false, widget.task["id"]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 683,
      decoration: BoxDecoration(
        color: Color(0xff444444),
        border: Border(
          top: BorderSide(
            color: Color(0xff5E5E5E),
            width: 1.0
          )
        )
      ),
      height: ((widget.task["attachments"] ?? []).length > 0) ? 130 : 40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: EdgeInsets.only(top: 2),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(width: 5),
                    Transform.scale(
                      scale: 0.9,
                      child: Checkbox(
                        activeColor: Color(0xffFAAD14),
                        checkColor: Color(0xff2E2E2E),
                        value: widget.task["value"] ?? widget.task["is_checked"] ?? false,
                        onChanged: (bool? value) {  
                          onCheckTask(value);
                        }
                      )
                    ),
                    SizedBox(width: 4),
                    Container(
                      child: onEditTask ? Container(
                        width: 540,
                        child: Focus(
                          onFocusChange: (focus) {
                            if (!focus) {
                              this.setState(() {
                                onEditTask = false;
                              });
                              if (controller.text.trim() != "") {
                                onEditingTask(controller.text);
                              }
                            } 
                          },
                          child: TextField(
                            autofocus: true,
                            onEditingComplete: () {
                              onEditingTask(controller.text);
                            },
                            controller: controller,
                            style: TextStyle(fontSize: 14),
                            decoration: InputDecoration.collapsed(hintText: "Add")
                          )
                        )
                      ) : InkWell(
                        onTap: () {
                          this.setState(() { onEditTask = true; });
                        },
                        child: Text(widget.task["title"])
                      )
                    )
                  ]
                )
              ),
              Container(
                height: 20,
                child: Wrap(
                  children: [
                    InkWell(
                      onTap: () {
                        showPopover(
                          context: context, 
                          backgroundColor: Color(0xff2E2E2E),
                          transitionDuration: const Duration(milliseconds: 50),
                          direction: PopoverDirection.bottom,
                          barrierColor: Colors.transparent,
                          width: 300,
                          height: 400,
                          arrowHeight: 0,
                          arrowWidth: 0,
                          bodyBuilder: (context) => ListMember(members: widget.task["assignees"], addOrRemoveMember: addOrRemoveTaskMember)
                        );
                      },
                      child: Container(
                        height: 26,
                        width: 68,
                        child: Stack(
                          children: (widget.task["assignees"] ?? []).map<Widget>((e) {
                            var user = findUser(e);
                            double index = (widget.task["assignees"] ?? []).indexOf(e).toDouble();

                            return index < 3 || (index == 3 && (widget.task["assignees"] ?? []).length == 4 ) ? Positioned(
                              top: 0,
                              right: 12*index,
                              child: CachedAvatar(user["avatar_url"], name: user["full_name"], width: 24, height: 24, radius: 50)
                            ) : index == 3 ? Positioned(
                              top: 0,
                              right: 12*index,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xff2E2E2E),
                                  borderRadius: BorderRadius.circular(50)
                                ),
                                width: 26,
                                height: 26,
                                child: Center(child: Text("+ ${widget.task["assignees"].length - 3}", style: TextStyle(fontSize: 12)))
                              )
                            ) : Container();
                          }).toList()
                        ),
                      ),
                    ),
                    ShowMoreTaskIcon(
                      task: widget.task, 
                      addOrRemoveTaskMember: addOrRemoveTaskMember, 
                      onAddTaskAttachment: onAddTaskAttachment,
                      onDeleteTask: onDeleteTask
                    )
                  ]
                )
              )
            ]
          ),
          if ((widget.task["attachments"] ?? []).length > 0) Container(
            height: 84,
            margin: EdgeInsets.only(left: 12, bottom: 4, top: 4),
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      onAddTaskAttachment();
                    },
                    child: DottedBorder(
                      padding: EdgeInsets.all(0),
                      dashPattern: [3, 3],
                      color: Color(0xff5E5E5E),
                      radius: Radius.circular(4),
                      child: Container(
                        height: 82,
                        width: 66,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIcons.plus, size: 19),
                            SizedBox(height: 20),
                            Text("New File", style: TextStyle(fontSize: 11.5))
                          ]
                        )
                      )
                    ),
                  ),
                  SizedBox(width: 8),
                  ...widget.task["attachments"].map((attachment) {
                    return AttachmentItem(attachment: attachment, onDeleteAttachment: onRemoveTaskAttachment);
                  })
                ]
              )
            )
          )
        ]
      )
    );
  }
}