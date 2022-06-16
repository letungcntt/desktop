import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:collection/collection.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/dropdown_overlay.dart';
import 'package:workcake/models/models.dart';

import 'issue_table.dart';

class IssueDropBar extends StatefulWidget {
  IssueDropBar({
    Key? key,
    this.title,
    this.listAttribute,
    this.selectedAtt,
    this.onSelectAtt,
    this.sortBy,
    this.changeSort,
    this.selectedCheckbox,
    this.tab,
    this.onFilterIssue
  }) : super(key: key);

  final title;
  final listAttribute;
  final selectedAtt;
  final onSelectAtt;
  final sortBy;
  final changeSort;
  final selectedCheckbox;
  final tab;
  final onFilterIssue;

  @override
  _IssueDropBarState createState() => _IssueDropBarState();
}

class _IssueDropBarState extends State<IssueDropBar> {

  List listAttribute = [];
  List defaultSelected = [];
  bool isShowModal = false;
  FocusNode _focusNodeInput = FocusNode();
  TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    this.setState(() {
      listAttribute = widget.listAttribute ?? [];
    });

    _focusNodeInput = FocusNode(
      onKey: (node, event) {
        if(event is RawKeyDownEvent) {
          if(event.isKeyPressed(LogicalKeyboardKey.enter)) {
          Navigator.pop(context);
          } else if(event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
            node.nextFocus();
          }
        }
        return KeyEventResult.ignored;
      }
    );
  }

  @override
  void didUpdateWidget (oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!isShowModal) {
      listAttribute = reSortListAttribute();
    }
  }

  @override
  void dispose() {
    _focusNodeInput.dispose();
    _titleController.dispose();
    super.dispose();
  }

  reSortListAttribute() {
    List listAttribute = widget.listAttribute ?? [];
    List listIdSelect = widget.selectedAtt ?? [];
    List selectedList = listAttribute.where((item) => listIdSelect.contains(item["id"])).toList();
    List unSelectedList = listAttribute.where((item) => !listIdSelect.contains(item["id"])).toList();
    return selectedList + unSelectedList;
  }

  calculateDueby(due) {
    final DateTime now = DateTime. now();
    final pastDay = now.difference(DateTime.parse(due)).inDays;
    final pastMonth = pastDay ~/ 30;

    if (pastMonth > 0) {
      return "Past due by ${pastMonth.toString()} ${pastMonth > 1 ? "months" : "month"}";
    } else {
      return "Past due by ${pastDay.toString()} ${pastDay > 1 ? "days" : "day"}";
    }
  }

  renderDueDate(milestone) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final DateTime now = DateTime. now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final formatted = formatter. format(now);
    final isPast = (milestone["due_date"].compareTo(formatted) < 0);

    return Container(
      width: 198,
      child: Text(
        milestone["due_date"] != null
          ? isPast
            ? calculateDueby(milestone["due_date"])
            : "Due by " + (DateFormatter().renderTime(DateTime.parse(milestone["due_date"]), type: "yMMMMd"))
          : "",
        style: TextStyle(color: isPast ? Color(0xffEB5757) : isDark ? Colors.white70 : Colors.grey[700], fontSize: 12)
      ),
    );
  }

  changeSort(type) {
    widget.changeSort(type);
  }

  onFilterAttribute(value) {
    if (value.trim() != "") {
      List list = List.from(reSortListAttribute()).where((e) {
        if (widget.title == "Assignee" || widget.title == "Author") {
          return Utils.unSignVietnamese(e["full_name"]).contains(Utils.unSignVietnamese(value));
        } else if (widget.title == "Label") {
          return e["name"].toLowerCase().contains(value);
        } else {
          return e["title"].toLowerCase().contains(value);
        }
      }).toList();

      setState(() {
        listAttribute = list;
      });
    } else {
      setState(() {
        listAttribute = reSortListAttribute();
      });
    }
  }

  checkIssueCount(item) {
    if (widget.selectedCheckbox != null && widget.selectedCheckbox.length > 0) {
      final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
      final data = Provider.of<Channels>(context, listen: false).data;
      final index = data.indexWhere((e) => e["id"] == currentChannel["id"]);
      List issues = (index != -1 ? data[index]["issues"] ?? [] : []).where((e) => widget.selectedCheckbox.contains(e["id"]) == true).toList();
      List openIssues = issues.where((e) => !e["is_closed"]).toList();
      List closedIssues = issues.where((e) => e["is_closed"]).toList();
      int count;
      var issueClosedTab = Provider.of<Work>(context, listen: false).issueClosedTab;
      if (widget.title == "Milestones") {
        count = (!issueClosedTab ? openIssues : closedIssues)
        .where((e) => e["milestone_id"] == item["id"]).toList().length;
      } else {
        count = (!issueClosedTab ? openIssues : closedIssues)
        .where((e) => e[(widget.title == "Label" ? "labels" : "assignees")]
        .contains(item["id"])).toList().length;
      }

      if (count == 0) {
        return 0;
      } else if (count < widget.selectedCheckbox.length) {
        return 1;
      } else {
        return 2;
      }
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final formatted = formatter.format(now);
    var colorNavigate = isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.45);

    return DropdownOverlay(
      menuOffset: 15,
      isAnimated: true,
      menuDirection: MenuDirection.end,
      width: 300,
      dropdownWindow: StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? Palette.backgroundTheardDark : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
            ),

            child: widget.title == "Sort"
              ? SortList(sortBy: widget.sortBy, changeSort: widget.changeSort)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
                        )
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: TextFormField(
                        autofocus: true,
                        focusNode: _focusNodeInput,
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: widget.title == "Milestone" ? "Filter milestone" : widget.title == "Labels" ? "Filter labels" : "Type or choose a name",
                          hintStyle: TextStyle(color: isDark ? Color(0xFFD9D9D9) : Color.fromRGBO(0, 0, 0, 0.35),
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            fontFamily: "Roboto"
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight), borderRadius: BorderRadius.all(Radius.circular(4))),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight), borderRadius: BorderRadius.all(Radius.circular(4))),
                          suffixIcon: InkWell(
                              child: Icon(Icons.clear, size: 14, color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65)),
                              onTap: () {
                                _titleController.clear();
                                onFilterAttribute("");
                                setState(() {});
                              }),
                        ),
                        style: TextStyle(color:isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65), fontSize: 13, fontWeight: FontWeight.w400),
                        onChanged: (value) {
                          onFilterAttribute(value.toLowerCase());
                          setState(() {});
                        },
                      ),
                    ),
                    Container(
                      height: 368,
                      child: SingleChildScrollView(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: listAttribute.length,
                          itemBuilder: (BuildContext context, int index) {
                            var item = listAttribute[index];

                            return Focus(
                              focusNode: FocusNode(
                                onKey: (FocusNode node, RawKeyEvent event) {
                                  if(event is RawKeyDownEvent) {
                                    if(event.isKeyPressed(LogicalKeyboardKey.enter)) {
                                      Navigator.pop(context);
                                      return KeyEventResult.handled;
                                    } else if( !(event.isKeyPressed(LogicalKeyboardKey.arrowDown)
                                      || event.isKeyPressed(LogicalKeyboardKey.arrowUp) || event.isKeyPressed(LogicalKeyboardKey.enter)
                                      || event.isKeyPressed(LogicalKeyboardKey.space) || event.isKeyPressed(LogicalKeyboardKey.tab))
                                    ){
                                      _focusNodeInput.requestFocus();
                                    } else if(event.isKeyPressed(LogicalKeyboardKey.tab)) {
                                      return KeyEventResult.handled;
                                    }
                                  }
                                  
                                  return KeyEventResult.ignored;
                                }
                              ),
                              child: TextButton(
                                style: ButtonStyle(
                                  overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                                  padding: MaterialStateProperty.all(EdgeInsets.zero)
                                ),
                                onPressed: () async {
                                  var count = checkIssueCount(item);
                                  await widget.onSelectAtt(widget.title, item, count == 2 ? true : false);

                                  if (!(widget.selectedCheckbox != null && widget.selectedCheckbox.length > 0 && widget.title == "Milestones")) {
                                    Timer(Duration(milliseconds: (widget.selectedCheckbox != null && widget.selectedCheckbox.length > 0) ? 0 : 100), () {
                                      if (this.mounted) {
                                        setState(() {});
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
                                    )
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          widget.title == "Milestones" && item["no_milestone"] != true ? Container(
                                          child: Icon(
                                            item["due_date"].compareTo(formatted) < 0 ? Icons.warning_amber_outlined : Icons.calendar_today_outlined, size: 20, 
                                            color: item["due_date"].compareTo(formatted) < 0 ? Color(0xffEB5757) : isDark ? Colors.white70 : Colors.grey[700]
                                          )) : Container(),
                                          
                                          if (widget.title != "Milestones") (widget.title == "Label") ?
                                          Container(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(vertical: 4, horizontal:8),
                                              decoration: BoxDecoration(
                                                color: Color(int.parse("0xFF${listAttribute[index]["color_hex"]}")),
                                                borderRadius: BorderRadius.circular(16)
                                              ),
                                              child: Text(item["name"], style: TextStyle(color: Colors.white, fontSize: 12),),
                                            ),
                                          ) : item["is_nobody"] != true ? CachedImage(
                                            item["avatar_url"],
                                            height: 28,
                                            width: 28,
                                            radius: 50,
                                            name: item["nickname"] ?? item["full_name"],
                                          ) : SizedBox(),

                                          if (widget.title != "Milestones") SizedBox(width: 12),
                                          Expanded(
                                            child: Container(
                                              margin: widget.title == "Milestones" ? EdgeInsets.only(left: 10) : null,
                                              padding: widget.title == "Milestones" ? EdgeInsets.symmetric(vertical: 5) : null,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 212,
                                                    margin: EdgeInsets.only(bottom: 5),
                                                    child: Text(
                                                      widget.title == "Milestones" ? item["title"] : widget.title == "Label" ? "" :item["nickname"] ?? item["full_name"],
                                                      style: TextStyle(color: widget.title == "Labels" ? Colors.white : (isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)), fontWeight: widget.title == "Labels" ? FontWeight.w400 : FontWeight.w600, fontSize: widget.title == "Labels" ? 12 : 14),
                                                      overflow: TextOverflow.ellipsis,
                                                    )
                                                  ),
                                                  if (widget.title != "Author" && widget.title != "Assignee") Container(
                                                    constraints: BoxConstraints(maxWidth: 340),
                                                    child: widget.title == "Milestones" && item["no_milestone"] != true ? renderDueDate(item) : Container()
                                                  )
                                                ]
                                              )
                                            )
                                          ),
                                          item["no_milestone"] == true && widget.selectedAtt.contains("no_milestone")
                                            ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor) :
                                          item["is_nobody"] == true && widget.selectedAtt.contains("is_nobody")
                                            ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                            : (widget.selectedCheckbox != null && checkIssueCount(item) == 2)
                                              ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                              : (widget.selectedCheckbox != null && checkIssueCount(item) == 1)
                                                ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                                : widget.selectedAtt.contains(item["id"])
                                                  ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                                  : Container(width: 20, height: 20),
                                          SizedBox(height: 6),
                                        ]
                                      ),
                                    ]
                                  )
                                )
                              ),
                            );
                          }
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight, width: 0.5)),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Use", style: TextStyle(fontSize: 13.5, color: colorNavigate,)),
                          SizedBox(width: 6,),
                          Icon(CupertinoIcons.arrow_up, size: 17, color: colorNavigate,),
                          SizedBox(width: 6,),
                          Icon(CupertinoIcons.arrow_down, size: 17, color: colorNavigate),
                          SizedBox(width: 6,),
                          Platform.isMacOS ? Icon(CupertinoIcons.return_icon, size: 17, color: colorNavigate,) : Icon(Icons.subdirectory_arrow_left, size: 18, color: colorNavigate),
                          SizedBox(width: 6,),
                          Text("to navigate", style: TextStyle(fontSize: 13.5, color: colorNavigate))
                        ],
                      ),
                    )
                  ],
                )
          );
        }
      ),
      onTap: () {
        setState(() {
          defaultSelected = widget.selectedAtt != null ? List.from(widget.selectedAtt) : [];
          isShowModal = true;
        });
      },
      onPop: () {
        _titleController.clear();
        this.setState(() {
          listAttribute = reSortListAttribute();
          isShowModal = false;
        });

        if (!ListEquality().equals(widget.selectedAtt, defaultSelected)) {
          widget.onFilterIssue();
        }
      },
      child: Container(
        margin:EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          color: ((widget.selectedAtt != null && widget.selectedAtt.length > 0) || (widget.title == "Sort" && widget.sortBy != "newest")) ? isDark ? Palette.backgroundRightSiderDark : Color(0xffDBDBDB) : null,
          borderRadius: BorderRadius.circular(6)
        ),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 9, vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.title,
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65), fontWeight: FontWeight.w500)
              ),
              ((widget.selectedAtt != null && widget.selectedAtt.length > 0) || (widget.title == "Sort" && widget.sortBy != "newest")) ? MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: () async {
                    widget.onSelectAtt(widget.title, null, false, removeAll: true);
                  },
                  child: Icon(Icons.close, color: isDark ? Colors.white : Colors.grey[700], size: 20)
                )
              ) : Icon(Icons.arrow_drop_down, color: isDark ? Colors.white : Colors.grey[700], size: 20)
            ]
          )
        )
      )
    );
  }
}
