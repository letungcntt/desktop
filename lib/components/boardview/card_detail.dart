import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/boardview/component/AttachmentItem.dart';
import 'package:workcake/models/models.dart';
import 'CardItem.dart';
import 'component/ChecklistItem.dart';
import 'component/ListMember.dart';
import 'component/models.dart';

class CardDetail extends StatefulWidget {
  final listCardId;

  CardDetail({
    Key? key,
    this.listCardId,
    required this.card
  }) : super(key: key);

  final CardItem card;

  @override
  _CardDetailState createState() => _CardDetailState();
}

class _CardDetailState extends State<CardDetail> {
  bool onEditTitle = false;
  bool onEditDescription = false;
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  var focusNode = FocusNode();
  bool hideDescription = false;
  bool hideAttachment = false;

  @override
  void initState() { 
    CardItem card = widget.card;
    final token = Provider.of<Auth>(context, listen: false).token;
    Provider.of<Boards>(context, listen: false).getActivity(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id).then((res) {
      if (!mounted) return;
      this.setState(() {
        card.activity = res["activity"];
        card.checklists = res["checklists"];
        card.attachments = res["attachments"];
      });
      Provider.of<Boards>(context, listen: false).onSelectCard(card);
    });
    super.initState();
  }

  addOrRemoveMember(userId) {
    final token = Provider.of<Auth>(context, listen: false).token;
    final index = widget.card.members.indexWhere((e) => e == userId);

    if (index == -1) {
      widget.card.members.add(userId);
    } else {
      widget.card.members.removeAt(index);
    }
    this.setState(() {});
    Provider.of<Boards>(context, listen: false).addOrRemoveAttribute(token, widget.card.workspaceId, widget.card.channelId, widget.card.boardId, widget.card.listCardId, widget.card.id, userId, "member");
  }

  setLabel(value) {
    final token = Provider.of<Auth>(context, listen: false).token;
    final index = widget.card.labels.indexWhere((e) => e == value);

    if (index == -1) {
      widget.card.labels.add(value);
    } else {
      widget.card.labels.removeAt(index);
    }
    this.setState(() {});
    Provider.of<Boards>(context, listen: false).addOrRemoveAttribute(token, widget.card.workspaceId, widget.card.channelId, widget.card.boardId, widget.card.listCardId, widget.card.id, value, "label");
  }

  onDeleteAttachment(att) {
    final token = Provider.of<Auth>(context, listen: false).token;
    CardItem card = widget.card;
    final index = card.attachments.indexWhere((e) => e["id"] == att["id"]);
    if (index == -1) return;
    card.attachments.removeAt(index);
    this.setState(() {});
    Provider.of<Boards>(context, listen: false).deleteAttachment(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id, att["id"]);
  }

  openFileSelector() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    List attachments = widget.card.attachments;

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
          hideAttachment = false;
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
            setState(() {
              attachments[i] = responseData;
            });
            Provider.of<Boards>(context, listen: false).addAttachment(token, widget.card.workspaceId, widget.card.channelId, widget.card.boardId, 
              widget.card.listCardId, widget.card.id, responseData["content_url"], responseData["mime_type"], responseData["file_name"]).then((res) {
                attachments[i]["id"] = res["attachment"]["id"];
              });
          });
        }
      }
    } on Exception catch (e) {
      print("$e Cancel");
    }
  }

  setDueDate(picked) {
    widget.card.dueDate = picked;
    updateCardTitleOrDescription();
  }

  setPriority(value) {
    widget.card.priority = value;
    updateCardTitleOrDescription();
  }

  onChangeCardTitle() {
    if (titleController.text.trim() != "") {
      widget.card.title = titleController.text.trim();
      updateCardTitleOrDescription();
    } else {
      titleController.text = widget.card.title;
    }
    this.setState(() {
      onEditTitle = false;
    });
  }

  handleKeyPress(event) {
    if (event is RawKeyUpEvent) {
      var data = event.data;
      if (data.physicalKey.debugName == "Enter" && (event.isShiftPressed || event.isMetaPressed)) {
        if (descriptionController.text.trim() != "") {
          widget.card.description = descriptionController.text.trim();
          updateCardTitleOrDescription();
        } else {
          descriptionController.text = widget.card.description;
        }
        this.setState(() {
          onEditDescription = false;
        });
      }
    }
  }

  updateCardTitleOrDescription() {
    final token = Provider.of<Auth>(context, listen: false).token;
    CardItem card = widget.card;
    var payload = {
      "id": card.id,
      "description": card.description,
      "title": card.title,
      "is_archived": card.isArchived,
      "due_date": card.dueDate != null ? card.dueDate!.toUtc().millisecondsSinceEpoch~/1000 + 86400 : null,
      "priority": card.priority
    };
    Provider.of<Boards>(context, listen: false).updateCardTitleOrDescription(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, payload);
    this.setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final card = widget.card;

    return Container(
      width: 994,
      color: isDark ? Color(0xff3D3D3D) : null,
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minHeight: 606, maxHeight: 720),
          child: SingleChildScrollView(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Color(0xff5E5E5E),
                        width: 1.0
                      )
                    )
                  ),
                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                  width: 732,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      onEditTitle ? Container(
                        color: Color(0xff2E2E2E),
                        height: 46,
                        child: Focus(
                          onFocusChange: (focus) {
                            if (!focus) {
                              this.setState(() {
                                onEditTitle = false;
                              });
                            }
                          },
                          child: CupertinoTextField(
                            controller: titleController,
                            autofocus: true,
                            onEditingComplete: () {
                              onChangeCardTitle();
                            },
                            placeholder: "Please input title",
                            cursorColor: isDark ? Colors.white : null,
                            padding: EdgeInsets.only(left: 12),
                            style: TextStyle(color: Color(0xffFFFFFF), fontSize: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: Color(0xff5e5e5e), width: 1)
                            )
                          ),
                        )
                      ) : InkWell(
                        onTap: () {
                          this.setState(() {
                            onEditTitle = true;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Color(0xff4C4C4C),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Color(0xff5E5E5E))
                          ),
                          height: 46,
                          child: Row(
                            children: [
                              Text(card.title, style: TextStyle(fontSize: 16))
                            ]
                          )
                        )
                      ),
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () {
                              this.setState(() { hideDescription = !hideDescription; });
                            },
                            child: Wrap(
                              children: [
                                Text("Description", style: TextStyle(fontSize: 15)),
                                SizedBox(width: 12),
                                Icon(hideDescription ? PhosphorIcons.caretRight : PhosphorIcons.caretDown, size: 18.0),
                              ]
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              this.setState(() { hideDescription = false; onEditDescription = true; });
                            },
                            child: Icon(PhosphorIcons.pencilSimpleLine, size: 17)
                          )
                        ],
                      ),
                      if(!hideDescription) Container(
                        margin: EdgeInsets.only(top: 16),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            onEditDescription ? Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: Color(0xff2E2E2E),
                                    border: Border.all(color: Color(0xff5E5E5E), width: 1)
                                  ),
                                  width: double.infinity,
                                  height: 176,
                                  child: RawKeyboardListener(
                                    focusNode: focusNode,
                                    onKey: handleKeyPress,
                                    child: Focus(
                                      onFocusChange: (focus) {
                                          if (!focus) {
                                            this.setState(() { onEditDescription = false; });
                                          }
                                        },
                                      child: TextFormField(
                                        autofocus: true,
                                        controller: descriptionController,
                                        minLines: 1,
                                        maxLines: 8,
                                        decoration: InputDecoration.collapsed(
                                          hintText: "Add a more detailed...",
                                          hintStyle: TextStyle(fontSize: 14)
                                        )
                                      ),
                                    ),
                                  )
                                ),
                              ],
                            ) : InkWell(
                              onTap: () {
                                this.setState(() {
                                  onEditDescription = true;
                                });
                              },
                              child: Container(
                                height: 176,
                                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Color(0xff4C4C4C),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Color(0xff5E5E5E))
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(card.description, style: TextStyle(fontSize: 16))
                                  ]
                                )
                              )
                            )
                          ]
                        )
                      ),

                      //////////////////////////////////////////////////////////////////////////////
                      /////// Checklist/////////////////////////////////////////////////////////////
                      /////////////////////////////////////////////////////////////////////////////////
                      
                      Checklists(checklists: card.checklists, card: card),
                      
                      //////////////////////////////////////////////////////////////////////////////
                      ////////////////////////////////////////////////////////////////////////////
                      
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () {
                              this.setState(() {
                                hideAttachment = !hideAttachment;
                              });
                            },
                            child: Wrap(
                              children: [
                                Text("Attachments", style: TextStyle(fontSize: 15)),
                                SizedBox(width: 12),
                                Icon(hideAttachment ? PhosphorIcons.caretRight : PhosphorIcons.caretDown, size: 18.0)
                              ]
                            )
                          ),
                          InkWell(
                            onTap: () {
                              openFileSelector();
                            }, 
                            child: Icon(PhosphorIcons.uploadSimple, size: 20),
                          )
                        ]
                      ),
                      SizedBox(height: 12),
                      if (card.attachments.length > 0 && !hideAttachment) Container(
                        margin: EdgeInsets.only(bottom: 12),
                        height: 96,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: card.attachments.length,
                          itemBuilder: (BuildContext context, int index) { 
                            return AttachmentItem(attachment: card.attachments[index], onDeleteAttachment: onDeleteAttachment);
                          }
                        )
                      ),
                      if (card.attachments.length == 0) InkWell(
                        overlayColor: MaterialStateProperty.all(Colors.transparent),
                        onTap: () {
                          openFileSelector();
                        }, 
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 7, horizontal: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(color: Color(0xff5E5E5E))
                              ),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Icon(PhosphorIcons.uploadSimple, size: 20),
                                  SizedBox(width: 8),
                                  Text("Upload", style: TextStyle(fontSize: 15))
                                ]
                              )
                            ),
                            SizedBox(width: 20),
                            Text("Add a new attachment", style: TextStyle(color: Color(0xffA6A6A6)))
                          ]
                        )
                      )
                    ]
                  )
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                  width: 262,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectAssignee(members: card.members, addOrRemoveMember: addOrRemoveMember),
                      SizedBox(height: 24),
                      SelectLabel(labels: card.labels, setLabel: setLabel),
                      SizedBox(height: 24),
                      SelectPriority(priority: card.priority, setPriority: setPriority),
                      SizedBox(height: 24),
                      SelectDueDate(setDueDate: setDueDate, dueDate: card.dueDate)
                    ]
                  )
                )
              ]
            ),
          )
        )
      )
    );
  }
}

class Checklists extends StatefulWidget {
  const Checklists({
    Key? key,
    required this.checklists,
    required this.card
  }) : super(key: key);

  final List checklists;
  final CardItem card;

  @override
  State<Checklists> createState() => _ChecklistsState();
}

class _ChecklistsState extends State<Checklists> {
  TextEditingController checklistController = TextEditingController();
  bool onAddChecklist = false;
  bool hideCheckList = false;

  deleteChecklist(index) {
    final token = Provider.of<Auth>(context, listen: false).token;
    final card = widget.card;
    Provider.of<Boards>(context, listen: false).deleteChecklistOrTask(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id, widget.checklists[index]["id"], null);

    this.setState(() {
      widget.checklists.removeAt(index);
    });
  }

  onCreateChecklist(title) {
    final token = Provider.of<Auth>(context, listen: false).token;
    final card = widget.card;

    Provider.of<Boards>(context, listen: false).createChecklist(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id, title).then((res) {
      this.setState(() {
        widget.checklists.insert(0, {"title": title, "tasks": [], "id": res["checklist"]["id"]});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                this.setState(() {
                  hideCheckList = !hideCheckList; 
                });
              },
              child: Wrap(
                children: [
                  Text("Checklists", style: TextStyle(fontSize: 15)),
                  SizedBox(width: 12),
                  Icon(hideCheckList ? PhosphorIcons.caretRight : PhosphorIcons.caretDown, size: 18.0)
                ]
              ),
            ),
            if(!onAddChecklist && widget.checklists.length > 0) InkWell(
              onTap: () {
                this.setState(() {
                  hideCheckList = false; 
                  onAddChecklist = true;
                });
              },
              child: Icon(PhosphorIcons.plus, size: 18.0)
            )
          ]
        ),
        onAddChecklist ? Container(
          margin: EdgeInsets.only(top: 12),
          height: 40,
          child: Focus(
            onFocusChange: (hasFocus) {
              if(!hasFocus) {
                this.setState(() {
                  onAddChecklist = false;
                });
              }
            },
            child: CupertinoTextField(
              controller: checklistController,
              autofocus: true,
              onEditingComplete: () {
                if (checklistController.text.trim() != "") {
                  onCreateChecklist(checklistController.text.trim());
                }
                checklistController.clear();
                setState(() { onAddChecklist = false; });
              },
              placeholder: "Please input title",
              cursorColor: isDark ? Colors.white : null,
              padding: EdgeInsets.only(left: 16, bottom: 2),
              style: TextStyle(color: Color(0xffFFFFFF), fontSize: 15),
              decoration: BoxDecoration(
                color: Color(0xff2E2E2E),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Color(0xff5e5e5e), width: 1)
              )
            ),
          ),
        ) : (widget.checklists.length == 0) ? Container(
          margin: EdgeInsets.only(top: 12),
          child: InkWell(
            onTap: () {
              this.setState(() {
                onAddChecklist = true;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Color(0xff2E2E2E) : null,
                border: Border.all(color: Color(0xff5E5E5E)),
                borderRadius: BorderRadius.circular(2)
              ),
              height: 40,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.plusCircle, color: Color(0xffC9C9C9), size: 17),
                  SizedBox(width: 12),
                  Text("New checklist")
                ]
              )
            )
          ),
        ) : Container(),
        hideCheckList ? Container() : Column(
          children: widget.checklists.map<Widget>((checklist) {
            var index = widget.checklists.indexOf(checklist);
            return ChecklistItem(checklist: checklist, indexChecklist: index, deleteChecklist: deleteChecklist);
          }).toList()
        )
      ]
    );
  }
}

class SelectDueDate extends StatefulWidget {
  final setDueDate;
  final dueDate;

  const SelectDueDate({
    Key? key,
    this.setDueDate,
    this.dueDate
  }) : super(key: key);

  @override
  State<SelectDueDate> createState() => _SelectDueDateState();
}

class _SelectDueDateState extends State<SelectDueDate> {
  selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.dueDate != null ? widget.dueDate : DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2049),
    );

    if (picked == null) {
      return;
    }

    widget.setDueDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      onTap: () {
        selectDate(context);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            onTap: () {
              selectDate(context);
            },
            child: Container(
              height: 32,
              padding: EdgeInsets.symmetric(vertical: 7, horizontal: 12),
              decoration: BoxDecoration(
                color: Color(0xff5E5E5E),
                borderRadius: BorderRadius.circular(2)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Due Date"),
                  Icon(PhosphorIcons.clock, size: 16)
                ]
              )
            )
          ),
          SizedBox(height: 12),
          widget.dueDate != null ? InkWell(
            onTap: () {
              selectDate(context);
            },
            child: Text(
              "${DateFormatter().renderTime(DateTime.parse('${widget.dueDate}'), type: 'yMMMd')}", 
              style: TextStyle(color: Color(0xffB7B7B7), fontSize: 14)
            )
          ) : Text("Add Due Date", style: TextStyle(color: Color(0xffA6A6A6), fontSize: 12))
        ]
      ),
    );
  }
}

class SelectLabel extends StatefulWidget {
  final labels;
  final setLabel;

  const SelectLabel({
    Key? key,
    this.labels,
    this.setLabel
  }) : super(key: key);

  @override
  State<SelectLabel> createState() => _SelectLabelState();
}

class _SelectLabelState extends State<SelectLabel> {
  onSelectLabel() {
    showPopover( 
      backgroundColor: Color(0xff2E2E2E),
      context: context,
      transitionDuration: const Duration(milliseconds: 50),
      direction: PopoverDirection.bottom,
      barrierColor: Colors.transparent,
      width: 262,
      height: 288,
      arrowHeight: 0,
      arrowWidth: 0,
      bodyBuilder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final selectedBoard = Provider.of<Boards>(context, listen: true).selectedBoard;
          final labels = selectedBoard["labels"];

          return Stack(
            children: [
              Container(
                color: Color(0xff2E2E2E),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      child: CupertinoTextField(
                        decoration: BoxDecoration(
                          color: Color(0xff2E2E2E),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: Color(0xff5E5E5E))
                        ),
                        padding: EdgeInsets.only(top: 6, left: 10, bottom: 4),
                        placeholder: "Filter labels",
                        placeholderStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: Color(0xff5E5E5E)),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: 52),
                        itemCount: labels.length,
                        itemBuilder: (BuildContext context, int index) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                widget.setLabel(labels[index]["id"]);
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.only(left: 9, right: 16),
                              height: 44,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: index == 0 ? Colors.transparent : Color(0xff5E5E5E),
                                    width: 1.0
                                  )
                                )
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Checkbox(
                                        activeColor: Color(0xffFAAD14),
                                        onChanged: (bool? value) {  }, value: widget.labels.contains(labels[index]["id"])
                                      ),
                                      SizedBox(width: 6),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                        alignment: Alignment.centerLeft,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: Color(int.parse("0xFF${labels[index]["color_hex"]}")),
                                          borderRadius: BorderRadius.circular(16)
                                        ),
                                        margin: EdgeInsets.symmetric(vertical: 3),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 2),
                                          constraints: BoxConstraints(maxWidth: 200 - 72),
                                          child: Text(labels[index]["name"], style: TextStyle(fontSize: 12, color: Colors.grey[50]), overflow: TextOverflow.ellipsis)
                                        )
                                      )
                                    ]
                                  ),
                                  Wrap(
                                    children: [
                                      InkWell(
                                        onTap: () {},
                                        child: Icon(PhosphorIcons.pencilSimpleLine, color: Colors.grey[500], size: 16)
                                      ),
                                      SizedBox(width: 12),
                                      InkWell(
                                        onTap: () {},
                                        child: Icon(PhosphorIcons.trashSimple, color: Colors.grey[500], size: 16)
                                      )
                                    ]
                                  )
                                ]
                              ),
                            ),
                          );
                        }
                      )
                    )
                  ]
                )
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  height: 52,
                  width: 262,
                  decoration: BoxDecoration(
                    color: Color(0xff2E2E2E),
                    border: Border(
                      top: BorderSide(
                        color: Color(0xff5E5E5E),
                        width: 1.0
                      )
                    )
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onCreateLabel();
                    },
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xff4C4C4C),
                          borderRadius: BorderRadius.circular(3)
                        ),
                        width: 226,
                        height: 30,
                        child: Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(PhosphorIcons.plus, size: 16),
                              SizedBox(width: 6),
                              Text("Add a Label", style: TextStyle(fontSize: 14))
                            ]
                          )
                        )
                      )
                    )
                  )
                )
              )
            ]
          );
        }
      )
    );
  }

  onCreateLabel() {
    showPopover( 
      backgroundColor: Color(0xff2E2E2E),
      context: context,
      transitionDuration: const Duration(milliseconds: 50),
      direction: PopoverDirection.bottom,
      barrierColor: Colors.transparent,
      width: 337,
      height: 418,
      arrowHeight: 0,
      arrowWidth: 0,
      bodyBuilder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CreateLabel(
            onCancel: () {
              Navigator.pop(context);
              onSelectLabel();
            },
            createLabel: createLabel
          );
        }
      )
    );
  }

  createLabel(title, color) {
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    
    Provider.of<Boards>(context, listen: false).createLabel(token, currentWorkspace["id"], currentChannel["id"], selectedBoard["id"], title, color);
    Navigator.pop(context);
    onSelectLabel();
  }

  @override
  Widget build(BuildContext context) {
    final selectedBoard = Provider.of<Boards>(context, listen: true).selectedBoard;

    List labels = widget.labels.map((e) {
      var index = selectedBoard["labels"].indexWhere((ele) => ele["id"] == e);
      var item = selectedBoard["labels"][index];
      return Label(colorHex: item["color_hex"], title: item["name"], id: item["id"].toString());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          onTap: () {
            onSelectLabel();
          },
          child: Container(
            height: 32,
            padding: EdgeInsets.symmetric(vertical: 7, horizontal: 12),
            decoration: BoxDecoration(
              color: Color(0xff5E5E5E),
              borderRadius: BorderRadius.circular(2)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Labels"),
                Icon(PhosphorIcons.tag, size: 16)
              ]
            )
          )
        ),
        widget.labels.length == 0 ? Container(
          margin: EdgeInsets.only(top: 12),
          child: Text("None yet", style: TextStyle(color: Color(0xffA6A6A6), fontSize: 12))
        ) : Wrap(
          children: labels.map<Widget>((label) {
            return Container(
              decoration: BoxDecoration(
                color: Color(int.parse("0xFF${label.colorHex}")),
                borderRadius: BorderRadius.circular(16)
              ),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: EdgeInsets.only(right: 8, top: 8),
              height: 22,
              child: Text(label.title, style: TextStyle(color: Colors.white, fontSize: 12)),
            );
          }).toList(),
        )
      ]
    );
  }
}

class CreateLabel extends StatefulWidget {
  final onCancel;
  final createLabel;

  const CreateLabel({
    Key? key,
    this.onCancel,
    this.createLabel
  }) : super(key: key);

  @override
  State<CreateLabel> createState() => _CreateLabelState();
}

class _CreateLabelState extends State<CreateLabel> {
  List colors = [
    "5CDBD3", "389E0D", "1890FF", "531DAB", "F759AB", "FAAD14", "D46B08", "FF7875", "D9DBEA", 
    "13C2C2", "B7EB8F", "096DD9", "722ED1", "C41D7F", "FFD666", "FA8C16", "F5222D", "8F90A6",
    "08979C", "237804", "0050B3", "B37FEB", "9E1068", "D48806", "FFA940", "A8071A", "6B7588"
  ];
  int selectedColor = 0;
  TextEditingController labelTitleController = TextEditingController();

  createLabel() {
    if (labelTitleController.text.trim() == "") return;
    widget.createLabel(labelTitleController.text, colors[selectedColor]);
    setState(() {
      selectedColor = 0;
      labelTitleController.text = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Text("Title"),
              SizedBox(height: 12),
              Container(
                height: 40,
                child: CupertinoTextField(
                  controller: labelTitleController,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  placeholder: "Name label",
                  style: TextStyle(color: Color(0xffA6A6A6), fontSize: 14),
                  placeholderStyle: TextStyle(color: Color(0xffA6A6A6), fontSize: 14),
                  decoration: BoxDecoration(
                    color: Color(0xff2E2E2E),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: Color(0xff5E5E5E))
                  )
                )
              ),
              SizedBox(height: 16),
              Text("Description"),
              SizedBox(height: 12),
              Container(
                height: 40,
                child: CupertinoTextField(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  placeholder: "Description",
                  style: TextStyle(color: Color(0xffA6A6A6), fontSize: 14),
                  placeholderStyle: TextStyle(color: Color(0xffA6A6A6), fontSize: 14),
                  decoration: BoxDecoration(
                    color: Color(0xff2E2E2E),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: Color(0xff5E5E5E))
                  )
                )
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(int.parse("0xFF${colors[selectedColor]}")),
                  borderRadius: BorderRadius.circular(15)
                ),
                height: 24,
                child: Text("${labelTitleController.text.trim() != "" ? labelTitleController.text : "Please input title"}", style: TextStyle(color: Colors.grey[50]), overflow: TextOverflow.ellipsis),
              ),
              SizedBox(height: 16),
              Text("Color"),
              SizedBox(height: 4),
              Container(
                child: Wrap(
                  children: colors.map((e) {
                    int index = colors.indexWhere((ele) => ele == e);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedColor = index;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(top: 8, right: (index == 8 || index == 17 || index == 26) ? 0 : 11),
                        decoration: BoxDecoration(
                          color: Color(int.parse("0xFF$e")),
                          borderRadius: BorderRadius.circular(3)
                        ),
                        height: 24,
                        width: 24,
                        child: Icon(Icons.check, color: selectedColor == index ? Colors.grey[300] : Colors.transparent),
                      ),
                    );
                  }).toList()
                )
              )
            ]
          )
        ),
        Divider(color: Color(0xff5E5E5E)),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  widget.onCancel();
                },
                child: Container(
                  height: 32,
                  width: 138,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xffFF7875)),
                    borderRadius: BorderRadius.circular(2)
                  ),
                  child: Center(child: Text("Cancel", style: TextStyle(color: Color(0xffFF7875))))
                ),
              ),
              InkWell(
                onTap: () {
                  createLabel();
                },
                child: Container(
                  height: 32,
                  width: 138,
                  decoration: BoxDecoration(
                    color: Color(0xff1890FF)
                  ),
                  child: Center(child: Text("Create Label"))
                )
              )
            ]
          )
        )
      ]
    );
  }
}

class SelectPriority extends StatefulWidget {
  final priority;
  final setPriority;

  const SelectPriority({
    Key? key,
    this.priority,
    this.setPriority
  }) : super(key: key);

  @override
  State<SelectPriority> createState() => _SelectPriorityState();
}

class _SelectPriorityState extends State<SelectPriority> {
  onSelectPriority() {
    showPopover( 
      backgroundColor: Color(0xff2E2E2E),
      context: context,
      transitionDuration: const Duration(milliseconds: 50),
      direction: PopoverDirection.bottom,
      barrierColor: Colors.transparent,
      width: 262,
      height: 230,
      arrowHeight: 0,
      arrowWidth: 0,
      bodyBuilder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Column(
            children: [
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  widget.setPriority(1);
                },
                child: Container(
                  height: 46,
                  width: 262,
                  padding: EdgeInsets.only(top: 14, left: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xff5E5E5E), width: 1.0))
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(PhosphorIcons.warning, size: 14, color: Color(0xffD81A1A)),
                      SizedBox(width: 12),
                      Text("Very High", style: TextStyle(fontSize: 14, color: Color(0xffD81A1A)))
                    ]
                  )
                )
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  widget.setPriority(2);
                },
                child: Container(
                  height: 46,
                  width: 262,
                  padding: EdgeInsets.only(top: 14, left: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xff5E5E5E), width: 1.0))
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(PhosphorIcons.warning, size: 14, color: Color(0xffFAAD14)),
                      SizedBox(width: 12),
                      Text("High", style: TextStyle(fontSize: 14, color: Color(0xffFAAD14)))
                    ]
                  )
                )
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  widget.setPriority(3);
                },
                child: Container(
                  height: 46,
                  width: 262,
                  padding: EdgeInsets.only(top: 14, left: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xff5E5E5E), width: 1.0))
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(PhosphorIcons.warning, size: 14, color: Color(0xff27AE60)),
                      SizedBox(width: 12),
                      Text("Medium", style: TextStyle(fontSize: 14, color: Color(0xff27AE60)))
                    ]
                  )
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  widget.setPriority(4);
                },
                child: Container(
                  height: 46,
                  width: 262,
                  padding: EdgeInsets.only(top: 14, left: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xff5E5E5E), width: 1.0))
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(PhosphorIcons.warning, size: 14, color: Color(0xff69C0FF)),
                      SizedBox(width: 12),
                      Text("Low", style: TextStyle(fontSize: 14, color: Color(0xff69C0FF)))
                    ]
                  )
                )
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  widget.setPriority(5);
                },
                child: Container(
                  height: 46,
                  width: 262,
                  padding: EdgeInsets.only(top: 14, left: 16),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(PhosphorIcons.warning, size: 14),
                      SizedBox(width: 12),
                      Text("None", style: TextStyle(fontSize: 14))
                    ]
                  )
                )
              )
            ]
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      onTap: () {
        onSelectPriority();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            onTap: () {
              onSelectPriority();
            },
            child: Container(
              margin: EdgeInsets.only(top: 4),
              height: 32,
              padding: EdgeInsets.symmetric(vertical: 7, horizontal: 12),
              decoration: BoxDecoration(
                color: Color(0xff5E5E5E),
                borderRadius: BorderRadius.circular(2)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Priority"),
                  Icon(PhosphorIcons.flag, size: 16)
                ]
              )
            )
          ),
          SizedBox(height: 12),
          widget.priority == null ? Text("Add a Priority", style: TextStyle(color: Color(0xffA6A6A6), fontSize: 12)) 
          : Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                PhosphorIcons.warning, size: 14, 
                color: Color(widget.priority == 1 ? 0xffFF7875 : widget.priority == 2 ? 0xffFAAD14 : widget.priority == 3 ? 0xff27AE60 : widget.priority == 4 ? 0xff69C0FF : 0xffFFFFFF)
              ),
              SizedBox(width: 6),
              Text(
                "${widget.priority == 1 ? 'Very High' : widget.priority == 2 ? 'High' : widget.priority == 3 ? 'Medium' : 'Low'}",
                style: TextStyle(color: Color(widget.priority == 1 ? 0xffFF7875 : widget.priority == 2 ? 0xffFAAD14 : widget.priority == 3 ? 0xff27AE60 : widget.priority == 4 ? 0xff69C0FF : 0xffFFFFFF))
              )
            ]
          )
        ]
      )
    );
  }
}

class SelectAssignee extends StatefulWidget {
  final addOrRemoveMember;
  final members;

  const SelectAssignee({
    Key? key,
    this.addOrRemoveMember,
    this.members
  }) : super(key: key);

  @override
  State<SelectAssignee> createState() => _SelectAssigneeState();
}

class _SelectAssigneeState extends State<SelectAssignee> {
  findUser(id) {
    final members = Provider.of<Workspaces>(context, listen: false).members;
    final indexMember = members.indexWhere((e) => e["id"] == id);

    if (indexMember != -1) {
      return members[indexMember];
    } else {
      return {};
    }
  }

  onSelectAssignee() {
    showPopover( 
      backgroundColor: Color(0xff2E2E2E),
      context: context,
      transitionDuration: const Duration(milliseconds: 50),
      direction: PopoverDirection.bottom,
      barrierColor: Colors.transparent,
      width: 258,
      height: 308,
      arrowHeight: 0,
      arrowWidth: 0,
      bodyBuilder: (context) => ListMember(members: widget.members, addOrRemoveMember: widget.addOrRemoveMember)
    );
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          onTap: () {
            onSelectAssignee();
          },
          child: Container(
            height: 32,
            padding: EdgeInsets.symmetric(vertical: 7, horizontal: 12),
            decoration: BoxDecoration(
              color: Color(0xff5E5E5E),
              borderRadius: BorderRadius.circular(2)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Members"),
                Icon(PhosphorIcons.userPlus, size: 16)
              ]
            )
          )
        ),
        widget.members.length == 0 ? Container(
          margin: EdgeInsets.only(top: 12),
          child: Text("No one-assign yourself", style: TextStyle(fontSize: 12, color: Color(0xffA6A6A6)))) : Container(
            margin: EdgeInsets.only(top: 6),
            child: Wrap(
            direction: Axis.vertical,
            children: widget.members.map<Widget>((e) {
              var user = findUser(e);

              return InkWell(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                onTap: () {onSelectAssignee();},
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 6),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      CachedAvatar(user["avatar_url"], name: user["full_name"], width: 26, height: 26, radius: 50),
                      SizedBox(width: 12),
                      Text(user["full_name"])
                    ],
                  )
                ),
              );
            }).toList()
        ),
          )
      ]
    );
  }
}