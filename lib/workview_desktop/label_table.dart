import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phoenix_wings/phoenix_wings.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_confirm_dialog.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';

import 'label.dart';

class LabelTable extends StatefulWidget {
  LabelTable({
    Key? key,
    this.createLabel,
    this.closeTable,
    this.channelId,
    this.onSelectLabel
  }) : super(key: key);

  final createLabel;
  final closeTable;
  final channelId;
  final onSelectLabel;

  @override
  _LabelTableState createState() => _LabelTableState();
}

class _LabelTableState extends State<LabelTable> {
  final _labelNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _labelNameEditController = TextEditingController();
  final _descriptionEditController = TextEditingController();

  List colors = [
    "1CE9AE", "0E8A16", "0052CC", "5319E7", "FF2C65", "FBA704", "D93F0B", "B60205", "CECECE",
    "57B99D", "65C87A", "5097D5", "925EB1", "D63964", "EAC545", "D8823B", "D65745", "98A5A6",
    "397E6B", "448852", "346690", "693B86", "9F2857", "B87E2E", "9C481B", "8D3529", "667C89"
  ];
  Random random = new Random();
  PhoenixChannel? channel;
  var pickedColor;
  var pickedColorEdit;
  var selectLabel;

  @override
  void initState() { 
    super.initState();
    this.setState(() {
      pickedColor = random.nextInt(8);
    });
    channel = Provider.of<Auth>(context, listen: false).channel;
    channel?.on("update_label_issue", (payload, ref, joinRef) {
      final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
      final token = Provider.of<Auth>(context, listen: false).token;
      Provider.of<Channels>(context, listen: false).getLabelsStatistical(token, currentWorkspace["id"], currentChannel["id"]);
    });
  }

  @override
  void didUpdateWidget(oldWidget) {
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    if (oldWidget.channelId != widget.channelId) {
      Provider.of<Channels>(context, listen: false).getLabelsStatistical(token, currentWorkspace["id"], widget.channelId);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    channel?.off("update_label_issue");
    _labelNameController.dispose();
    _descriptionController.dispose();
    _labelNameEditController.dispose();
    _descriptionEditController.dispose();
    super.dispose();
  }

  onCreateLabel() {
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    List labels = currentChannel["labels"];

    if (Utils.checkedTypeEmpty(_labelNameController.text)) {
      final index = labels.indexWhere((e) => e["name"] == _labelNameController.text);

      if (index == -1) {
        Map label = {
          "name": _labelNameController.text,
          "description": _descriptionController.text,
          "color_hex": colors[pickedColor].toString(),
          "issues": 0
        };

        Provider.of<Channels>(context, listen: false).createChannelLabel(token, currentWorkspace["id"], currentChannel["id"], label);
        _labelNameController.clear();
        _descriptionController.clear();
        widget.closeTable();
      }
    }
  }

  onUpdateLabel(label) {
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;

    Map newLabel = {
      "id": label["id"],
      "name": _labelNameEditController.text,
      "description": _descriptionEditController.text,
      "color_hex": colors[pickedColorEdit].toString(),
      "issues": 0
    };

    Provider.of<Channels>(context, listen: false).updateLabel(token, currentWorkspace["id"], currentChannel["id"], newLabel);
    this.setState(() {
      selectLabel = null;
    });
  }

  calculateLabel(label) {
    final currentChannel = Provider.of<Channels>(context, listen: true).currentChannel;
    final data = Provider.of<Channels>(context, listen: true).data;
    final int indexChannel = data.indexWhere((ele) => ele['id'] == currentChannel['id']);
    final channel = indexChannel  != -1 ? data[indexChannel] : currentChannel;
    List labelsStatistical = channel["labelsStatistical"] ?? [];
    var openIssue = 0;
     for(var ls in labelsStatistical) {
       if(label["id"] == ls["id"]) {
        openIssue = ls["issue_count"];
       }
     }
     return openIssue;
  }
 
  @override
  Widget build(BuildContext context) {
    final channelId = widget.channelId;
    final data = Provider.of<Channels>(context, listen: true).data;
    final index = data.indexWhere((e) => e["id"].toString() == channelId.toString());
    List labelsStatistical = index == -1 ? [] : data[index]["labelsStatistical"] ?? [];
    final labels = index == -1 ? [] : data[index]["labels"] ?? [];
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Column(
        children: [
          if (widget.createLabel) Container(
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight),
            ),
            margin: EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Palette.borderSideColorDark : Palette.backgroundTheardLight
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      LabelDesktop(
                        labelName: Utils.checkedTypeEmpty(_labelNameController.text) ? _labelNameController.text : "Label preview",
                        color: int.parse("0xFF${colors[pickedColor]}")
                      ),
                      Container()
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Palette.backgroundTheardDark : Colors.white,
                    border: isDark ? Border() : Border(
                      top: BorderSide(color: Palette.borderSideColorLight)
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: createOrEditLabel(context, null)
                )
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight),
                  borderRadius: BorderRadius.all(Radius.circular(4))
                ),
                child: Column(
                  children: [
                    Container( 
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Palette.borderSideColorDark : Palette.backgroundTheardLight,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(2))
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            margin: EdgeInsets.only(left: 4),
                            child: Text(
                              S.current.countLabels(labels.length),
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13.5
                              )
                            )
                          ),
                          Row(
                            children: [
                              Container(child: Text(S.current.sort, style: TextStyle(color: isDark ? Colors.white.withOpacity(0.85) : Color(0xff1F2933), fontSize: 13.5))),
                              Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white.withOpacity(0.85) : Color(0xff1F2933), size: 18.0)
                            ],
                          )
                        ]
                      )
                    ),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: (MediaQuery.of(context).size.height - (widget.createLabel ? 350 : 232))
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Palette.backgroundRightSiderDark : Colors.white,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(2))
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        controller: ScrollController(),
                        children: [
                          ...labels.map((label) => Container(
                            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              children: [
                                                Expanded(
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: InkWell(
                                                      onTap: () {
                                                        widget.onSelectLabel(label);
                                                      },
                                                      child: LabelDesktop(
                                                        labelName: selectLabel == label["id"] ? _labelNameEditController.text : label["name"], 
                                                        color: selectLabel == label["id"] ? int.parse("0xFF${colors[pickedColorEdit]}") : 
                                                        label["color_hex"] != null ? int.parse("0XFF${label["color_hex"]}") : 0xffffff,
                                                      ),
                                                    )
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    selectLabel == label["id"] ? _descriptionEditController.text : "${label["description"]}",
                                                    style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700])
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              margin: EdgeInsets.only(left: 10),
                                              child: Text(
                                                labelsStatistical.length > 0 ? "${calculateLabel(label)} open issues" : "",
                                                style: TextStyle(color: isDark ? Colors.white.withOpacity(0.85) : Color(0xff1F2933))
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 96,
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              _labelNameEditController.text = label["name"];
                                              _descriptionEditController.text = label["description"];
      
                                              int indexColor = colors.indexWhere((e) => e == label["color_hex"]);
                                              this.setState(() {
                                                pickedColorEdit = indexColor != -1 ? indexColor : 0;
                                                selectLabel = label["id"];
                                              });
                                            },
                                            hoverColor: Colors.transparent,
                                            splashColor: Colors.transparent,
                                            child: Text(S.current.edit, style: TextStyle(color: Colors.lightBlue))
                                          ),
                                          SizedBox(width: 16),
                                          InkWell(
                                            onTap: () {
                                              showConfirmDialog(context, label["id"]);
                                            },
                                            hoverColor: Colors.transparent,
                                            splashColor: Colors.transparent,
                                            child: Text(S.current.delete, style: TextStyle(color: Colors.redAccent))
                                          ),
                                        ]
                                      )
                                    )
                                  ]
                                ),
                                if (selectLabel == label["id"]) Column(
                                  children: [
                                    SizedBox(height: 24),
                                    createOrEditLabel(context, label)
                                  ]
                                )
                              ]
                            )
                          ))
                        ]
                      ),
                    )
                  ]
                )
              ),
            ),
          )
        ]
      )
    );
  }

  Widget createOrEditLabel(BuildContext context, label) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    return LayoutBuilder(
      builder: (context, contraints) => Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if(contraints.maxWidth > 756) Container(
                  margin: EdgeInsets.only(right: 8),
                  child: Text(S.current.name, style: TextStyle(fontWeight: FontWeight.w500))
                ),
                Container(
                  height: 32,
                  width: contraints.maxWidth * 1/5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                    color: isDark ? Color(0xff1E1E1E) : Colors.white,
                  ),
                  child: TextFormField(
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w300),
                    controller: label == null ? _labelNameController : _labelNameEditController,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(8),
                      hintText: label == null ?  S.current.addName : "${label["name"]}",
                      hintStyle: TextStyle(color: Color(0xff9AA5B1), fontWeight: FontWeight.w300, fontSize: 14.0),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0), borderSide: BorderSide(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0), borderSide: BorderSide(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))),
                    ),
                    onChanged: (value) {
                      this.setState(() {});
                    }
                  ),
                ),
                contraints.maxWidth < 756 ? SizedBox(width: 8,) : Container(
                  margin: EdgeInsets.fromLTRB(16, 0, 8, 0),
                  child: Text(S.current.description, style: TextStyle(fontWeight: FontWeight.w500))
                ),
                Container(
                  height: 32,
                  width: contraints.maxWidth * 1/4,
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xff1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(4.0)
                  ),
                  child: TextFormField(
                    onChanged: (value) {
                      this.setState(() {});
                    },
                    controller: label == null ? _descriptionController : _descriptionEditController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w300),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(8),
                      hintText: label == null ? S.current.description : "${label["description"]}",
                      hintStyle: TextStyle(color: Color(0xff9AA5B1), fontWeight: FontWeight.w300, fontSize: 14.0),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0), borderSide: BorderSide(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0), borderSide: BorderSide(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))),
                    ),
                  ),
                ),
                contraints.maxWidth > 850 ? Container(
                  margin: EdgeInsets.fromLTRB(16, 0, 8, 0),
                  child: Text(S.current.color, style: TextStyle(fontWeight: FontWeight.w500))
                ) : SizedBox(width: 8,),
                GestureDetector(
                  child: Container(
                    decoration: BoxDecoration(
                      color: label == null ? Color(int.parse("0xFF${colors[pickedColor]}")) : Color(int.parse("0xFF${colors[pickedColorEdit]}")),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    height: 32.0,
                    width: 40.0,
                    padding: EdgeInsets.only(bottom: 1.0),
                    child: Icon(CupertinoIcons.eyedropper, size: 18.0, color: Colors.white,)
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => Dialog(
                        backgroundColor: Color(0xff323F4B),
                        elevation: 0,
                        child: Container(
                          height: 112,
                          width: 304,
                          padding: EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GridView.count(
                                shrinkWrap: true,
                                primary: false,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                crossAxisCount: 9,
                                children: colors.map((e) => 
                                  InkWell(
                                    onTap: () {
                                      if (label == null) {
                                        this.setState(() {
                                          pickedColor = colors.indexWhere((color) => color == e);
                                        });
                                        Navigator.pop(context);
                                      } else {
                                        this.setState(() {
                                          pickedColorEdit = colors.indexWhere((color) => color == e);
                                        });
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(int.parse("0xFF$e")),
                                        borderRadius: BorderRadius.circular(4.0)
                                      ),
                                      height: 24.0,
                                      width: 24.0
                                    ),
                                  )
                                ).toList(),
                              )
                            ],
                          ),
                        ),
                      )
                    );
                  }
                )
              ]
            ),
          ),
          TextButton(
            style: ButtonStyle(
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                  side: BorderSide(color: Color(0xffFF7875))
                ),
              ),
              padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 16, horizontal: 22)),
              backgroundColor: MaterialStateProperty.all(
                isDark ? Colors.transparent : Colors.white
              )
            ),
            // disabledColor: Color(0xff6989BF),
            onPressed: () {
              if (label == null) {
                _labelNameController.clear();
                _descriptionController.clear();
                widget.closeTable();
              } else {
                this.setState(() {
                  selectLabel = null;
                });
              }
            },
            child: Text(S.current.cancel, style: TextStyle(color: Color(0xffFF7875)),),
          ),
          SizedBox(width: 10),
          TextButton(
            style: ButtonStyle(
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.0),
                )
              ),
              padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0)),
              backgroundColor: MaterialStateProperty.all(Palette.buttonColor)
            ),
            // disabledColor: Color(0xff6989BF),
            onPressed: () { 
              if (label == null) {
                onCreateLabel();
              } else {
                onUpdateLabel(label);
              }
            },
            child:Text(label == null ? S.current.createLabels: S.current.saveChanges, style: TextStyle(color: Colors.white)),
          )
        ]
      ),
    );
  }
}

showConfirmDialog(context, labelId) {
  final token = Provider.of<Auth>(context, listen: false).token;
  final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
  final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
  
  onDeleteLabel() {
    Provider.of<Channels>(context, listen: false).deleteAttribute(token, currentWorkspace["id"], currentChannel["id"], labelId, "label");
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return CustomConfirmDialog(
        title: S.current.deleteLabel,
        subtitle: S.current.descDeleteLabel,
        onConfirm: onDeleteLabel,
      );
    }
  );
}