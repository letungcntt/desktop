import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:popover/popover.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/boardview/component/AttachmentItem.dart';
import 'package:workcake/providers/providers.dart';
import 'component/ChecklistItem.dart';
import 'component/ListMember.dart';
import 'component/models.dart';

class CreateCard extends StatefulWidget {
  final listCardId;

  CreateCard({
    Key? key,
    this.listCardId
  }) : super(key: key);

  @override
  _CreateCardState createState() => _CreateCardState();
}

class _CreateCardState extends State<CreateCard> {
  bool onEditDescription = false;
  List checklists = [];
  List members = [];
  List labels = [];
  int? priority;
  DateTime? dueDate;
  List attachments = [];
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  FocusNode titleFocusNode = FocusNode();
  var box;

  @override
  void initState() {
    Timer.run(() async {
      final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
      box = await Hive.openBox("draftsKanban");
      var draftCard = box.get(selectedBoard["id"]);
      if (draftCard == null) return;
      this.setState(() {
        descriptionController.text = draftCard["description"] ?? "";
        titleController.value = titleController.value.copyWith(
          text: draftCard["title"] ?? "",
          selection: TextSelection.collapsed(
            offset: (draftCard["title"] ?? "").length
          )
        );
        members = draftCard["members"] ?? [];
        labels = draftCard["labels"] ?? [];
        priority = draftCard["priority"];
        dueDate = draftCard["dueDate"];
        attachments = draftCard["attachments"];
        checklists = draftCard["checklists"] ?? [];
      });
    });

    super.initState();
  }

  saveDraftCard() {
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;

    var card = {
      "title": titleController.text.trim(),
      "description": descriptionController.text.trim(),
      "checklists": checklists,
      "members": members,
      "labels": labels,
      "priority": priority,
      "dueDate": dueDate,
      "attachments": attachments
    };

    box.put(selectedBoard["id"], card);
  }

  onCreateChecklist(title) {
    this.setState(() {
      checklists.insert(0, {"title": title, "tasks": []});
    });
    saveDraftCard();
  }

  onEditTask(value, index) {
    this.setState(() {
      // tasks[index]['title'] = value;
    });
    saveDraftCard();
  }

  addOrRemoveMember(userId) {
    final index = members.indexWhere((e) => e == userId);
    if (index == -1) {
      members.add(userId);
    } else {
      members.removeAt(index);
    }
    this.setState(() {});
    saveDraftCard();
  }

  setPriority(value) {
    this.setState(() {
      priority = value;
    });
    saveDraftCard();
  }

  setLabel(value) {
    final index = labels.indexWhere((e) => e == value);
    if (index == -1) {
      labels.add(value);
    } else {
      labels.removeAt(index);
    }
    this.setState(() {});
    saveDraftCard();
  }

  setDueDate(picked) {
    setState(() {
      dueDate = picked;
    });
    saveDraftCard();
  }

  onDeleteAttachment(att) {
    final index = attachments.indexOf(att);
    if (index == -1) return;
    setState(() {
      attachments.removeAt(index);
    });
    saveDraftCard();
  }

  openFileSelector() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    try {
      var myMultipleFiles = await Utils.openFilePicker([XTypeGroup(extensions: [])]);

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
            setState(() {
              attachments[i] = responseData;
            });
          });
        }
      }
    } on Exception catch (e) {
      print("$e Cancel");
    }
    saveDraftCard();
  }

  onCreateNewCard() {
    final token = Provider.of<Auth>(context, listen: false).token;
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
    var card = {
      "id": Utils.getRandomNumber(10),
      "title": titleController.text,
      "description": descriptionController.text,
      "checklists": checklists,
      "members": members,
      "labels": labels,
      "priority": priority,
      "due_date": dueDate != null ? dueDate!.toUtc().millisecondsSinceEpoch~/1000 + 86400 : null,
      "attachments": attachments
    };

    Provider.of<Boards>(context, listen: false).createNewCard(token, selectedBoard["workspace_id"], selectedBoard["channel_id"], selectedBoard["id"], widget.listCardId, card);
    box.put(selectedBoard["id"], null);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Container(
      width: 994,
      color: isDark ? Color(0xff3D3D3D) : null,
      child: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              constraints: BoxConstraints(minHeight: 606, maxHeight: 720),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(bottom: 66),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                                  width: 1.0
                                )
                              )
                            ),
                            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                            width: 732,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      color: isDark ? Palette.backgroundTheardDark : Color(0xffF3F3F3),
                                      height: 46,
                                      child: TextFormField(
                                        controller: titleController,
                                        focusNode: titleFocusNode,
                                        autofocus: true,
                                        onEditingComplete: () {
                                          if (titleController.text.trim() != "") {
                                            saveDraftCard();
                                          }
                                          titleFocusNode.unfocus();
                                        },
                                        decoration: InputDecoration(
                                          hintText: "Please input title",
                                          contentPadding: EdgeInsets.only(left: 12),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                                            borderRadius: BorderRadius.all(Radius.circular(4))
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                                            borderRadius: BorderRadius.all(Radius.circular(4))
                                          )
                                        ),
                                        cursorColor: isDark ? Colors.white : null,
                                        style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 15),
                                      )
                                    )
                                  ]
                                ),
                                SizedBox(height: 30),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Wrap(
                                      children: [
                                        Text("Description", style: TextStyle(fontSize: 15)),
                                        SizedBox(width: 12),
                                        Icon(PhosphorIcons.caretDown, size: 18.0),
                                      ]
                                    ),
                                    Icon(PhosphorIcons.pencilLine, size: 17)
                                  ],
                                ),
                                Container(
                                  margin: EdgeInsets.only(top: 16),
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          color: isDark ? Palette.backgroundTheardDark : Color(0xffF3F3F3),
                                        ),
                                        width: double.infinity,
                                        height: 126,
                                        child: TextFormField(
                                          autofocus: true,
                                          controller: descriptionController,
                                          onChanged: (value) {
                                            saveDraftCard();
                                          },
                                          minLines: 8,
                                          maxLines: 8,
                                          decoration: InputDecoration(
                                            hintText: "Add a more detailed...",
                                            hintStyle: TextStyle(fontSize: 14),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                                              borderRadius: BorderRadius.all(Radius.circular(4))
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                                              borderRadius: BorderRadius.all(Radius.circular(4))
                                            )
                                          )
                                        )
                                      )
                                    ]
                                  )
                                ),

                                //////////////////////////////////////////////////////////////////////////////
                                /////// Checklist/////////////////////////////////////////////////////////////
                                /////////////////////////////////////////////////////////////////////////////////

                                Checklists(checklists: checklists, onCreateChecklist: onCreateChecklist),

                                //////////////////////////////////////////////////////////////////////////////
                                ////////////////////////////////////////////////////////////////////////////

                                SizedBox(height: 30),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Wrap(
                                      children: [
                                        Text("Attachments", style: TextStyle(fontSize: 15)),
                                        SizedBox(width: 12),
                                        Icon(PhosphorIcons.caretDown, size: 18.0)
                                      ]
                                    ),
                                    InkWell(
                                      onTap: () {
                                        openFileSelector();
                                      },
                                      child: Container(
                                        margin: EdgeInsets.only(right: 4),
                                        child: Icon(PhosphorIcons.uploadSimple, size: 20)
                                      ),
                                    )
                                  ]
                                ),
                                SizedBox(height: 12),
                                if (attachments.length > 0) Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  height: 96,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: attachments.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      return AttachmentItem(attachments: attachments, onDeleteAttachment: onDeleteAttachment, index: index);
                                    }
                                  )
                                ),
                                if (attachments.length == 0) InkWell(
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
                                          border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB))
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
                                SelectAssignee(members: members, addOrRemoveMember: addOrRemoveMember),
                                SizedBox(height: 24),
                                SelectLabel(labels: labels, setLabel: setLabel),
                                SizedBox(height: 24),
                                SelectPriority(priority: priority, setPriority: setPriority),
                                SizedBox(height: 24),
                                SelectDueDate(setDueDate: setDueDate, dueDate: dueDate)
                              ]
                            )
                          )
                        ]
                      )
                    )
                  ]
                ),
              )
            ),

            Positioned(
              bottom: 0,
              child: Container(
                padding: EdgeInsets.only(top: 16, right: 20, bottom: 16),
                width: 994,
                decoration: BoxDecoration(
                  color: isDark ? Color(0xff3D3D3D) : null,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                      width: 1.0
                    )
                  )
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      overlayColor: MaterialStateProperty.all(Colors.transparent),
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Color(0xffFF7875)
                          )
                        ),
                        child: Text("Cancel", style: TextStyle(color: Color(0xffFF7875)))
                      )
                    ),
                    SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        onCreateNewCard();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(4)
                        ),
                        padding: EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                        child: Text("Create Card", style: TextStyle(color: Palette.defaultTextDark)),
                      ),
                    )
                  ]
                )
              )
            )
          ]
        ),
      )
    );
  }
}

class Checklists extends StatefulWidget {
  const Checklists({
    Key? key,
    required this.checklists,
    this.onCreateChecklist
  }) : super(key: key);

  final List checklists;
  final onCreateChecklist;

  @override
  State<Checklists> createState() => _ChecklistsState();
}

class _ChecklistsState extends State<Checklists> {
  TextEditingController checklistController = TextEditingController();
  bool onAddChecklist = false;

  deleteChecklist(index) {
    this.setState(() {
      widget.checklists.removeAt(index);
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
            Wrap(
              children: [
                Text("Checklists", style: TextStyle(fontSize: 15)),
                SizedBox(width: 12),
                Icon(PhosphorIcons.caretDown, size: 18.0)
              ]
            ),
            if(!onAddChecklist && widget.checklists.length > 0) InkWell(
              onTap: () {
                this.setState(() {
                  onAddChecklist = true;
                });
              },
              child: Icon(PhosphorIcons.plus, size: 18.0)
            )
          ]
        ),
        onAddChecklist ? Container(
          margin: EdgeInsets.only(top: 12),
          color: isDark ? Palette.backgroundTheardDark : Color(0xffF3F3F3),
          height: 40,
          child: Focus(
            onFocusChange: (hasFocus) {
              if(!hasFocus) {
                this.setState(() {
                  onAddChecklist = false;
                });
              }
            },
            child: TextFormField(
              controller: checklistController,
              autofocus: true,
              onEditingComplete: () {
                if (checklistController.text.trim() != "") {
                  widget.onCreateChecklist(checklistController.text.trim());
                }
                checklistController.clear();
                setState(() { onAddChecklist = false; });
              },
              cursorColor: isDark ? Colors.white : null,
              style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 15),
              decoration: InputDecoration(
                hintText: "Please input title",
                contentPadding: EdgeInsets.only(left: 16, bottom: 2),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                  borderRadius: BorderRadius.all(Radius.circular(4))
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                  borderRadius: BorderRadius.all(Radius.circular(4))
                )
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
                color: isDark ? Palette.backgroundTheardDark : Color(0xffF3F3F3),
                border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                borderRadius: BorderRadius.circular(4)
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
        Column(
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
      firstDate: DateTime.now(),
      lastDate: DateTime(2023),
    );

    if (picked == null) {
      return;
    }

    widget.setDueDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

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
                color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
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
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    showPopover(
      backgroundColor: isDark ? Palette.backgroundTheardDark : Colors.white,
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
                color: isDark ? Palette.backgroundTheardDark : Color(0xffF3F3F3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      child: CupertinoTextField(
                        decoration: BoxDecoration(
                          color: isDark ? Palette.backgroundTheardDark : Color(0xffF3F3F3),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB))
                        ),
                        padding: EdgeInsets.only(top: 6, left: 10, bottom: 4),
                        placeholder: "Filter labels",
                        placeholderStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
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
                                    color: index == 0 ? Colors.transparent : isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
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
                                        activeColor: isDark ? Palette.calendulaGold : Palette.dayBlue,
                                        onChanged: (bool? value) { 
                                          setState(() {
                                            widget.setLabel(labels[index]["id"]);
                                          });
                                         }, value: widget.labels.contains(labels[index]["id"])
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
                    color: isDark ? Palette.backgroundTheardDark : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
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
                          color: isDark ? Color(0xff4C4C4C) : Color(0xffF3F3F3),
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
                              Text("Create a Label", style: TextStyle(fontSize: 14))
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
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    showPopover(
      backgroundColor: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
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

    Provider.of<Boards>(context, listen: false).createLabel(token, currentWorkspace["id"], currentChannel["id"], selectedBoard["id"], title, color, null);
    Navigator.pop(context);
    onSelectLabel();
  }

  @override
  Widget build(BuildContext context) {
    final selectedBoard = Provider.of<Boards>(context, listen: true).selectedBoard;
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    List labels = widget.labels.map((e) {
      var index = selectedBoard["labels"].indexWhere((ele) => ele["id"] == e);
      var item = index != -1 ? selectedBoard["labels"][index] : null;
      return item != null ? Label(colorHex: item["color_hex"], title: item["name"], id: item["id"].toString()) : null;
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
              color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
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
            return label == null ? Container(width: 0) : Container(
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
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
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
                  style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 14),
                  placeholderStyle: TextStyle(color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65), fontSize: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Palette.backgroundTheardDark : Color(0xffF3F3F3),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB))
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
                  style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 14),
                  placeholderStyle: TextStyle(color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65), fontSize: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Palette.backgroundTheardDark : Color(0xffF3F3F3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB))
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
        Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
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
                    color: Utils.getPrimaryColor()
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
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    showPopover(
      backgroundColor: isDark ? Palette.backgroundTheardDark : Colors.white,
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
                    border: Border(bottom: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), width: 1.0))
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(PhosphorIcons.warning, size: 14, color: Color(0xffD81A1A)),
                      SizedBox(width: 12),
                      Text("Urgent", style: TextStyle(fontSize: 14, color: Color(0xffD81A1A)))
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
                    border: Border(bottom: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), width: 1.0))
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
                    border: Border(bottom: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), width: 1.0))
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
                    border: Border(bottom: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), width: 1.0))
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
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

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
              height: 32,
              padding: EdgeInsets.symmetric(vertical: 7, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
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
                "${widget.priority == 1 ? 'Urgent' : widget.priority == 2 ? 'High' : widget.priority == 3 ? 'Medium' : 'Low'}",
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
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    showPopover(
      backgroundColor: isDark ? Palette.backgroundTheardDark : Colors.white,
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
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

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
              color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
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