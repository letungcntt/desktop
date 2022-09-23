import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/message_item/attachments/text_file.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/workview_desktop/pagination.dart';
import 'package:workcake/workview_desktop/renderListUser.dart';
import 'issue_drop_bar.dart';
import 'label.dart';

class IssueTable extends StatefulWidget {
  const IssueTable({
    Key? key,
    this.channelId,
    this.milestone,
    this.resetFilter,
    this.onChangeFilter,
    this.text,
    this.label
  }) : super(key: key);

  final channelId;
  final milestone;
  final resetFilter;
  final onChangeFilter;
  final text;
  final label;

  @override
  _IssueTableState createState() => _IssueTableState();
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}

class _IssueTableState extends State<IssueTable> {
  List filters = [];
  List selectedAuthor = [];
  List selectedMilestone = [];
  List selectedLabel = [];
  List selectedAssignee = [];
  String sortBy = "newest";
  List selectedCheckbox = [];
  bool selectAll = false;
  bool isIssueLoading = true;
  int currentPage = 1;
  bool unreadOnly = false;

  @override
  void initState() {
    super.initState();
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final issueClosedTab = Provider.of<Work>(context, listen: false).issueClosedTab;

    if (widget.label != null) {
      selectedLabel = [widget.label["id"]];
      filters = [{
        "type": "label",
        "name": widget.label["name"],
        "id": widget.label["id"]
      }];
      Provider.of<Channels>(context, listen: false).getListIssue(token, currentWorkspace["id"], currentChannel["id"], 1, issueClosedTab, filters, sortBy, widget.text, unreadOnly).then((value) => {
        isIssueLoading = false
      });
    } else if (widget.milestone != null) {
      this.setState(() {
        selectedMilestone = [widget.milestone["id"]];
        filters = [{
          "type": "milestone",
          "name": widget.milestone["title"],
          "id": widget.milestone["id"]
        }];
        Provider.of<Channels>(context, listen: false).getListIssue(token, currentWorkspace["id"], currentChannel["id"], 1, issueClosedTab, filters, sortBy, widget.text, unreadOnly).then((value) => {
          isIssueLoading = false
        });
      });
    } else {
      Timer.run(() async{
        final currentUser = Provider.of<User>(context, listen: false).currentUser;
        var snapshot = await Hive.openBox("snapshotData_${currentUser["id"]}");
        Provider.of<Channels>(context, listen: false).setDataIssue(snapshot.get("issues") ?? []);
        isIssueLoading = false;
        final tempIssueState = Provider.of<Channels>(context, listen: false).tempIssueState;
        final lastPage = tempIssueState != null ? tempIssueState["lastPage"] ?? 1 : 1;
        currentPage = lastPage;

        Provider.of<Channels>(context, listen: false).getListIssue(token, currentWorkspace["id"], currentChannel["id"], lastPage, issueClosedTab, [], sortBy, widget.text, unreadOnly).then((value) {
          if (mounted) {
            final data = Provider.of<Channels>(context, listen: false).data;
            final index = data.indexWhere((e) => e["id"] == currentChannel["id"]);
            List issues = data[index]["issues"] ?? [];
            snapshot.put("issues:${currentChannel["id"]}", issues);
          }
        });
        if (tempIssueState != null) Provider.of<Channels>(context, listen: false).tempIssueState = {...tempIssueState, 'lastPage': 1};
      });
    }
  }

  @override
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final bool issueClosedTab = Provider.of<Work>(context, listen: false).issueClosedTab;

    if (oldWidget.channelId != widget.channelId || oldWidget.resetFilter != widget.resetFilter) {
      setState(() {
        filters = [];
        selectedAuthor = [];
        selectedMilestone = [];
        selectedLabel = [];
        selectedAssignee = [];
        sortBy = "newest";
        unreadOnly = false;
      });
      Provider.of<Channels>(context, listen: false).getListIssue(token, currentWorkspace["id"], currentChannel['id'], 1, issueClosedTab, [], sortBy, widget.text, false);
    }
  }

  setCurrentPage(page) {
    currentPage = page;
  }

  onSelectAtt(type, item, isRemove, {removeAll = false}) async {
    if (type == "Sort") {
      final token = Provider.of<Auth>(context, listen: false).token;
      final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
      final bool issueClosedTab = Provider.of<Work>(context, listen: false).issueClosedTab;
      this.setState(() { sortBy = "newest"; });
      Provider.of<Channels>(context, listen: false).getListIssue(token, currentWorkspace["id"], currentChannel['id'], 1, issueClosedTab, filters, sortBy, widget.text, unreadOnly);
      return;
    }

    if (removeAll) {
      this.setState(() {
        switch (type) {
          case "Author":
            selectedAuthor = [];
            break;
          case "Milestones":
            selectedMilestone = [];
            break;
          case "Label":
            selectedLabel = [];
            break;
          case "Assignee":
            selectedAssignee = [];
            break;

          default:
        }
      });
      onChangeFilter();
      onFilterIssue();
    } else {
      if (selectedCheckbox.length > 0 ) {
        final token = Provider.of<Auth>(context, listen: false).token;
        final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
        final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
        final issueClosedTab = Provider.of<Work>(context, listen: false).issueClosedTab;
        Navigator.of(context, rootNavigator: true).pop("Discard");

        Provider.of<Channels>(context, listen: false).bulkAction(token, currentWorkspace["id"], currentChannel["id"], type, item["id"], selectedCheckbox, isRemove, filters, 1, sortBy, issueClosedTab);
      } else {
        if (type == "Author") {
          List list = List.from(selectedAuthor);
          final index = list.indexWhere((e) => e == item["id"]);

          if (index == -1) {
            this.setState(() {
              selectedAuthor = [item["id"]];
            });
          } else {
            this.setState(() {
              selectedAuthor = [];
            });
          }
        } else if (type == "Milestones") {
          List list = List.from(selectedMilestone);
          final index = list.indexWhere((e) => e == item["id"]);

          if (item["no_milestone"] == true) {
            selectedMilestone = list.indexWhere((element) => element == "no_milestone") == -1 ? ["no_milestone"] : [];
          } else {
            if (index == -1) {
              this.setState(() {
                selectedMilestone = [item["id"]];
              });
            } else {
              this.setState(() {
                selectedMilestone = [];
              });
            }
          }
        } else if (type == "Label") {
          List list = List.from(selectedLabel);
          final index = list.indexWhere((e) => e == item["id"]);

          if (index == -1) {
            list.add(item["id"]);
          } else {
            list.removeAt(index);
          }

          this.setState(() {
            selectedLabel = list;
          });
        } else {
          List list = List.from(selectedAssignee);
          final index = list.indexWhere((e) => e == item["id"]);
          final indexNobody = list.indexWhere((element) => element == "is_nobody");

          if (item["is_nobody"] == true) {
            if (indexNobody == -1) {
              this.setState(() {
                list = ["is_nobody"];
              });
            } else {
              list = [];
            }
          } else {
            if (index == -1) {
              list.add(item["id"]);
              if (indexNobody != -1) {
                list.removeAt(indexNobody);
              }
            } else {
              list.removeAt(index);
            }
          }

          this.setState(() {
            selectedAssignee = list;
          });
        }

        onChangeFilter();
      }
    }
  }

  onChangeFilter() {
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final channelMember = Provider.of<Channels>(context, listen: false).channelMember;
    List labels = currentChannel["labels"] ?? [];
    List milestones = currentChannel["milestones"] ?? [];
    List newFilters = [];

    selectedAuthor.forEach((e) {
      var index = channelMember.indexWhere((ele) => ele["id"] == e);
      if (index != -1) {
        newFilters.add({
          "type": "author",
          "name": channelMember[index]["full_name"],
          "id": channelMember[index]["id"]
        });
      }
    });

    selectedAssignee.forEach((e) {
      if (e == "is_nobody") {
        newFilters.add({
          "type": "assignee",
          "name": "Assigned to nobody",
          "id": 0
        });
      } else {
        var index = channelMember.indexWhere((ele) => ele["id"] == e);
        if (index != -1) {
          newFilters.add({
            "type": "assignee",
            "name": channelMember[index]["full_name"],
            "id": channelMember[index]["id"]
          });
        }
      }
    });

    selectedMilestone.forEach((e) {
      if (e == "no_milestone") {
        newFilters.add({
          "type": "milestone",
          "no_milestone": true
        });
      } else {
        var index = milestones.indexWhere((ele) => ele["id"] == e);

        if (index != -1) {
          newFilters.add({
            "type": "milestone",
            "name": milestones[index]["title"],
            "id": milestones[index]["id"]
          });
        }
      }
    });

    selectedLabel.forEach((e) {
      var index = labels.indexWhere((ele) => ele["id"] == e);
      if (index != -1) {
        newFilters.add({
          "type": "label",
          "name": labels[index]["name"],
          "id": labels[index]["id"]
        });
      }
    });

    this.setState(() {
      filters = newFilters;
    });

    widget.onChangeFilter(filters);
  }

  parseFilterToString() {
    bool issueClosedTab = Provider.of<Work>(context, listen: false).issueClosedTab;

    List list = issueClosedTab ? ["is:closed"] : ["is:open"];

    filters.forEach((e) => {
      list.add(" ${e["type"]}:${e["name"]}")
    });

    return list.join(" ");
  }

  changeSort(type) {
    setState(() {
      sortBy = type;
    });
  }

  parseFilter(listIssues) {
    List list = listIssues;

    filters.forEach((filter) {
      if (filter["type"] == "label") {
        list = list.where((e) => e["labels"].contains(filter["id"])).toList();
      } else if (filter["type"] == "author") {
        list = list.where((e) => e["author_id"] == filter["id"]).toList();
      } else if (filter["type"] == "milestone") {
        list = list.where((e) => e["milestone_id"] == filter["id"]).toList();
      } else {
        list = list.where((e) => e["assignees"].contains(filter["id"])).toList();
      }
    });

    if (sortBy == "newest") {
      list.sort((a, b) => b["unique_id"].compareTo(a["unique_id"]));
    } else if (sortBy == "oldest") {
      list.sort((a, b) => a["unique_id"].compareTo(b["unique_id"]));
    } else if (sortBy == "recently_updated") {
      list.sort((a, b) => b["updated_at"].compareTo(a["updated_at"]));
    } else {
      list.sort((a, b) => a["updated_at"].compareTo(b["updated_at"]));
    }

    return list;
  }

  onChangeCheckbox(id) {
    List list = List.from(selectedCheckbox);
    int index = list.indexWhere((e) => e == id);

    if (index == -1) {
      list.add(id);
    } else {
      list.removeAt(index);
    }

    this.setState(() {
      selectedCheckbox = list;
    });
  }

  onCheckAll(value) {
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final data = Provider.of<Channels>(context, listen: false).data;
    final index = data.indexWhere((e) => e["id"] == currentChannel["id"]);
    List issues = index != -1 ? data[index]["issues"] ?? [] : [];

    if (value) {
      List list = [];

      for (var issue in issues) {
        list.add(issue["id"]);
      }

      this.setState(() {
        selectedCheckbox = list;
      });
    } else {
      this.setState(() {
        selectedCheckbox = [];
      });
    }

    this.setState(() {
      selectAll = value;
    });
  }

  onFilterIssue() {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final issueClosedTab = Provider.of<Work>(context, listen: false).issueClosedTab;
    setCurrentPage(1);
    Provider.of<Channels>(context, listen: false).getListIssue(auth.token, currentWorkspace["id"], currentChannel['id'], 1, issueClosedTab, filters, sortBy, widget.text, unreadOnly);
  }

  selectAssignee(id, name, type) {
    if (type == "label") {
      List newFilters = List.from(filters).where((e) => e["type"] != "label").toList();
      newFilters.add({"type": "label", "name": name, "id": id});
      filters = newFilters;
      selectedLabel = [id];
    } else if (type == "assignee") {
      List newFilters = List.from(filters).where((e) => e["type"] != "assignee").toList();
      newFilters.add({"type": "assignee", "name": name, "id": id});
      filters = newFilters;
      selectedAssignee = [id];
    } else {
      List newFilters = List.from(filters).where((e) => e["type"] != "author").toList();
      newFilters.add({"type": "author", "name": name, "id": id});
      filters = newFilters;
      selectedAuthor = [id];
    }
    setState(() {});
    onFilterIssue();
  }

  selectMilestone(milestoneId, title) {
    List newFilters = List.from(filters).where((e) => e["type"] != "milestone").toList();
    newFilters.add({"type": "milestone", "name": title, "id": milestoneId});
    setState(() {
      filters = newFilters;
      selectedMilestone = [milestoneId];
    });
    onFilterIssue();
  }

  newListChannelMember(List channelMember) {
    final currentUser = Provider.of<User>(context, listen: false).currentUser;

    final index = channelMember.indexWhere((ele) => ele["id"] == currentUser["id"]);
    List newList = channelMember;
    if (index != -1) {
      final member = channelMember[index];
      newList.removeAt(index);
      newList.insert(0, member);
      return newList;
    } else {
      return newList;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentChannel = Provider.of<Channels>(context, listen: true).currentChannel;
    final data = Provider.of<Channels>(context, listen: true).data;
    final index = data.indexWhere((e) => e["id"] == currentChannel["id"]);
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final channelMember = Provider.of<Channels>(context, listen: true).channelMember;
    final issueClosedTab = Provider.of<Work>(context, listen: true).issueClosedTab;
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    List issues = index != -1 ? data[index]["issues"] ?? [] : [];
    final openIssuesCount = index != -1 ? data[index]["openIssuesCount"] : null;
    final closedIssuesCount = index != -1 ? data[index]["closedIssuesCount"] : null;
    List labels = index != -1 ? data[index]["labels"] ?? [] : [];
    List milestones = index != -1 ? data[index]["milestones"] ?? [] : [];
    final List<dynamic> assignedToNobody = [{
      "is_nobody": true,
      "full_name": "Assigned to nobody"
    }];
    final newListAssignee = assignedToNobody + newListChannelMember(channelMember);
    if (selectedMilestone.length > 0) {
      final mid = selectedMilestone[0];
      milestones = milestones.where((ele) => ele["is_closed"] == false || (ele["is_closed"] == true && ele["id"] == mid)).toList();
    } else {
      milestones = milestones.where((e) => e["is_closed"] == false).toList();
    }

    final List<dynamic> noMilestone = [{"no_milestone": true, "title": "Issues with no milestone"}];
    milestones = noMilestone + milestones;

    return LayoutBuilder(
      builder: (context, cts) {
        bool isExpand = cts.maxWidth >= 812;
        Widget action =  Wrap(
          direction: Axis.horizontal,
          children: [
            Wrap(
              direction: Axis.horizontal,
              children: [
                Container(
                  margin: EdgeInsets.only(right: 4),
                  child: openIssuesCount != null
                    ? Container(
                      padding: EdgeInsets.only(bottom: 1),
                      child: SvgPicture.asset('assets/icons/error_outline.svg', color: !issueClosedTab ? Palette.buttonColor : Color(0xff9AA5B1))
                    )
                    : Container()
                ),
                InkWell(
                  onTap: () {
                    this.setState(() { isIssueLoading = true; });
                    Provider.of<Work>(context, listen: false).setIssueClosedTab(false);
                    Provider.of<Channels>(context, listen: false).getListIssue(auth.token, currentWorkspace["id"], currentChannel["id"], 1, false, filters, sortBy, widget.text, unreadOnly).then(
                      (value) {this.setState(() {
                        isIssueLoading = false;
                        selectedCheckbox = [];
                        selectAll = false;
                      });}
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 8),
                    child: Text(
                      openIssuesCount != null ? "$openIssuesCount Open" : "",
                      style: TextStyle(
                        color: !issueClosedTab ? Palette.buttonColor : Color(0xff9AA5B1),
                        fontWeight: !issueClosedTab ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 14
                      )
                    )
                  ),
                ),
              ],
            ),
            SizedBox(width: 15,),
            Wrap(
              direction: Axis.horizontal,
              children: [
                Container(
                  margin: EdgeInsets.only(right: 4),
                  child: closedIssuesCount != null ? Icon(
                    Icons.check,
                    color: issueClosedTab ? Palette.buttonColor : Color(0xff9AA5B1), size: 18
                  ) : Container()
                ),
                InkWell(
                  onTap: () {
                    this.setState(() { isIssueLoading = true; });
                    Provider.of<Work>(context, listen: false).setIssueClosedTab(true);
                    Provider.of<Channels>(context, listen: false).getListIssue(auth.token, currentWorkspace["id"], currentChannel["id"], 1, true, filters, sortBy, widget.text, unreadOnly).then(
                      (value) {this.setState(() {
                        isIssueLoading = false;
                        selectedCheckbox = [];
                        selectAll = false;
                      });}
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 4),
                    child: Text(
                      closedIssuesCount != null ? "$closedIssuesCount Closed": "",
                      style: TextStyle(
                        color: issueClosedTab ? Palette.buttonColor : Color(0xff9AA5B1),
                        fontWeight: !issueClosedTab ? FontWeight.w400 : FontWeight.w600,
                        fontSize: 14
                      )
                    )
                  ),
                )
              ],
            )
          ]
        );

        return Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if(!isExpand) Container(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    margin: EdgeInsets.only(bottom: 10),
                    child: action
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 24, right: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Palette.backgroundTheardDark : Palette.backgroundRightSiderLight,
                        border: Border(
                          top: BorderSide(color: !isDark ? Palette.borderSideColorLight : Colors.transparent, width: 1.0),
                          left: BorderSide(color: !isDark ? Palette.borderSideColorLight : Colors.transparent, width: 1.0),
                          right: BorderSide(color: !isDark ? Palette.borderSideColorLight : Colors.transparent, width: 1.0),
                          bottom: issues.length > 0 || isIssueLoading ? BorderSide(color: !isDark ? Palette.borderSideColorLight : Colors.transparent, width: 1.0) : BorderSide.none,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Color(0xff262626) : Color(0xffF8F8F8),
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight,
                                  width: 1.0,
                                ),
                              )
                            ),
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(left: 3),
                                        padding: EdgeInsets.symmetric(vertical: 8),
                                        width: 42,
                                        child: Theme(
                                          data: ThemeData(
                                            primarySwatch: Colors.blue,
                                            unselectedWidgetColor: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65) // Your color
                                          ),
                                          child: Transform.scale(
                                            scale: 0.9,
                                            child: Checkbox(
                                              value: selectAll,
                                              onChanged: (value) {
                                                onCheckAll(value);
                                              },
                                            )
                                          )
                                        )
                                      ),
                                      if(isExpand) Expanded(
                                        child: action
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(right: 10, bottom: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          setState(() { unreadOnly = !unreadOnly; });
                                          onFilterIssue();
                                        },
                                        child: ListAction(
                                          action: '',
                                          isDark: isDark,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: unreadOnly ? isDark ? Palette.backgroundRightSiderDark : Color(0xffDBDBDB) : null,
                                              borderRadius: BorderRadius.circular(6)
                                            ),
                                            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                            child: Text(
                                              "Unread only",
                                              style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65), fontWeight: FontWeight.w500)
                                            )
                                          ),
                                        )
                                      ),
                                      selectedCheckbox.length > 0 ? Container() : 
                                      IssueDropBar(title: "Author", listAttribute: newListChannelMember(channelMember), onSelectAtt: onSelectAtt, selectedAtt: selectedAuthor, onFilterIssue: onFilterIssue),
                                      IssueDropBar(title: "Label", listAttribute: labels, onSelectAtt: onSelectAtt, selectedAtt: selectedLabel, selectedCheckbox: selectedCheckbox, onFilterIssue: onFilterIssue),
                                      IssueDropBar(title: "Milestones", listAttribute: milestones, onSelectAtt: onSelectAtt, selectedAtt: selectedMilestone, selectedCheckbox: selectedCheckbox, onFilterIssue: onFilterIssue),
                                      IssueDropBar(title: "Assignee", listAttribute: newListAssignee, onSelectAtt: onSelectAtt, selectedAtt: selectedAssignee, selectedCheckbox: selectedCheckbox, onFilterIssue: onFilterIssue),
                                      selectedCheckbox.length > 0 ? Container() : 
                                      IssueDropBar(title: "Sort", sortBy: sortBy, changeSort: changeSort, onFilterIssue: onFilterIssue, onSelectAtt: onSelectAtt),
                                    ]
                                  )
                                )
                              ]
                            )
                          ),
                          isIssueLoading ? Container(
                            height: MediaQuery.of(context).size.height - 275 - (isExpand ? 0 : 35),
                            child: Center(
                              child: SpinKitFadingCircle(
                                color: isDark ? Colors.white60 : Color(0xff096DD9),
                                size: 35,
                              ),
                            ),
                          ) : ListIssue(
                            issues: issues,
                            filters: filters,
                            sortBy: sortBy,
                            selectedCheckbox: selectedCheckbox,
                            onChangeCheckbox: onChangeCheckbox,
                            isClosed: issueClosedTab,
                            selectAssignee: selectAssignee,
                            selectMilestone: selectMilestone,
                            page: currentPage,
                            isExpand: isExpand
                          )
                        ]
                      )
                    )
                  ),
                ],
              ),
              Pagination(channelId: currentChannel["id"], issueClosedTab: issueClosedTab, filters: filters, sortBy: sortBy, text: widget.text, handleCurrentPage: setCurrentPage, issuePerPage: issues.length, currentPage: currentPage, unreadOnly: unreadOnly)
            ]
          ),
        );
      }
    );
  }
}

class ListIssue extends StatefulWidget {
  const ListIssue({
    Key? key,
    this.issues,
    this.filters,
    this.sortBy,
    this.isClosed,
    this.page,
    this.selectedCheckbox,
    this.onChangeCheckbox,
    this.selectAssignee,
    this.selectMilestone,
    this.isExpand = true
  }) : super(key: key);

  final issues;
  final filters;
  final sortBy;
  final isClosed;
  final page;
  final selectedCheckbox;
  final onChangeCheckbox;
  final selectAssignee;
  final selectMilestone;
  final bool isExpand;

  @override
  _ListIssueState createState() => _ListIssueState();
}

class _ListIssueState extends State<ListIssue> {
  ScrollController scrollController = ScrollController();

  @override
  void didUpdateWidget (oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) {
      scrollController.jumpTo(0.0);
    }
  }

  selectCheckbox(id) {
    widget.onChangeCheckbox(id);
  }

  @override
  Widget build(BuildContext context) {
    List issues = widget.issues.where((e) => e["is_closed"] == widget.isClosed).toList();
    final currentChannel = Provider.of<Channels>(context, listen: true).currentChannel;
    List channels = Provider.of<Channels>(context, listen: true).data;
    final indexChannel = channels.indexWhere((e) => e["id"] == currentChannel["id"]);
    var totalPage = channels[indexChannel]["totalPage"] ?? 0;
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;

    return Container(
      constraints: BoxConstraints(
        maxHeight: (MediaQuery.of(context).size.height - (totalPage > 1 ? 170 : 150) - (Platform.isMacOS ? 55 : 49) - 50 - (widget.isExpand ? 0 : 36))
      ),
      child: ListView.builder(
        controller: scrollController,
        shrinkWrap: true,
        itemCount: issues.length,
        itemBuilder: (BuildContext context, int index) {
          final issue = issues[index];
          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: index == issues.length - 1 || issues.length == 0 ? Colors.transparent : (isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight),
                  width: 1.0,
                ),
              ),
            ),
            child: IssueItem(issue: issue, selectCheckbox: selectCheckbox, selectedCheckbox: widget.selectedCheckbox, selectAssignee: widget.selectAssignee, selectMilestone: widget.selectMilestone)
          );
        },
      )
    );
  }
}

class IssueItem extends StatefulWidget {
  const IssueItem({
    Key? key,
    @required this.issue,
    this.selectCheckbox,
    this.selectedCheckbox,
    this.selectAssignee,
    this.selectMilestone
  }) : super(key: key);

  final issue;
  final selectCheckbox;
  final selectedCheckbox;
  final selectAssignee;
  final selectMilestone;

  @override
  _IssueItemState createState() => _IssueItemState();
}

class _IssueItemState extends State<IssueItem> {
  var channel;
  var issue;

  @override
  void initState() {
    super.initState();

    this.setState(() {
      issue = widget.issue;
    });
  }

  parseDatetime(time) {
    if (time != "") {
      DateTime offlineTime = DateTime.parse(time).add(Duration(hours: 7));
      DateTime now = DateTime.now();
      final difference = now.difference(offlineTime).inMinutes;
      final int hour = difference ~/ 60;
      final int minutes = difference % 60 + 1;
      final int day = hour ~/24;

      if (day > 0) {
        int month = day ~/30;
        int year = month ~/12;
        if (year >= 1) return '${year.toString().padLeft(1, "")} ${year > 1 ? "years" : "year"} ago';
        else {
          if (month >= 1) return '${month.toString().padLeft(1, "")} ${month > 1 ? "months" : "month"} ago';
          else return '${day.toString().padLeft(1, "")} ${day > 1 ? "days" : "day"} ago';
        }
      } else if (hour > 0) {
        return '${hour.toString().padLeft(1, "")} ${hour > 1 ? "hours" : "hour"} ago';
      } else if(minutes <= 1) {
        return 'moment ago';
      } else {
        return '${minutes.toString().padLeft(1, "0")} minutes ago';
      }
    } else {
      return "";
    }
  }

  parseDescription(description) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    int checked = 0;
    int total = 0;

    List list = description.split("\n");

    for (var item in list) {
      if (item.length > 5) {
        String sub = item.substring(0, 5);

        if (sub == "- [ ]" || sub == "- [x]") {
          total +=1;
        }
        if (sub == "- [x]") {
          checked +=1;
        }
      }
    }

    return total > 0 ? Wrap(
      direction: Axis.horizontal,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(Icons.playlist_add_check_outlined, color: isDark ? Color(0xffB7B7B7) : Colors.black.withOpacity(0.45)),
        SizedBox(width: 4),
        Text(
          "$checked of $total",
          style: TextStyle(
            color: isDark ? Color(0xffB7B7B7) : Colors.black.withOpacity(0.45),
            fontSize: 12.5
          )
        ),
        SizedBox(width: 6),
        Container(
          width: 70,
          height: 6,
          padding: EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            child: LinearProgressIndicator(
              value: checked/total,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlue),
              backgroundColor: Color(0xffD6D6D6),
            )
          )
        ),
      ]
    ) : Wrap();
  }

  onSelectIssue() async {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final data = Provider.of<Channels>(context, listen: false).data;
    final userId = auth.userId;
    final token = auth.token;
    Provider.of<Channels>(context, listen: false).updateUnreadIssue(token, currentWorkspace["id"], currentChannel["id"], issue["id"], userId);
    Provider.of<Threads>(context, listen: false).updateUnreadThreadIssue(currentWorkspace["id"], currentChannel["id"], issue["id"], token);

    final index = data.indexWhere((e) => e["id"] == currentChannel["id"]);

    List issues = (index != -1 ? data[index]["issues"] ?? [] : []).where((e) => widget.selectedCheckbox.contains(e["id"]) == true).toList();
    int indexIssue = issues.indexWhere((e) => e['id'] == issue['id']);
    Provider.of<Channels>(context, listen: false).onChangeOpenIssue({...indexIssue != -1 ? issues[indexIssue] : issue, 'type': 'edited'});
  }

  @override
  Widget build(BuildContext context) {
    issue = widget.issue;
    final currentChannel = Provider.of<Channels>(context, listen: true).currentChannel;
    final workspaceMember = Provider.of<Workspaces>(context, listen: true).members;
    final channelMember = Provider.of<Channels>(context, listen: true).channelMember;
    final indexUser = workspaceMember.indexWhere((e) => e["id"] == issue["author_id"]);
    final author = indexUser == -1 ? null : workspaceMember[indexUser];
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final issueClosedTab = Provider.of<Work>(context, listen: true).issueClosedTab;
    final data = Provider.of<Channels>(context, listen: true).data;
    final index = data.indexWhere((e) => e["id"] == currentChannel["id"]);
    List labels = index != -1 ? data[index]["labels"] ?? [] : [];
    List milestones = index != -1 ? data[index]["milestones"] ?? [] : [];
    List assignees = issue["assignees"] != null ? channelMember.where((e) => issue["assignees"].contains(e["id"])).toList() : [];
    List issueLabels = issue["labels"] != null ? labels.where((e) => issue["labels"].contains(e["id"])).toList() : [];

    final indexMilestone = milestones.indexWhere((e) => e["id"] == issue["milestone_id"]);
    final milestone = indexMilestone == -1 ? null : milestones[indexMilestone];
    final currentUser = Provider.of<User>(context, listen: true).currentUser;

    return Container(
      decoration: BoxDecoration(
         border: Border(
          left: BorderSide(
            color: (issue["users_unread"] ?? []).contains(currentUser["id"]) ? Colors.blue : Colors.transparent,
            width: 3.0,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 8,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    SizedBox(height: 8),
                    Container(
                      height: 22, width: 42,
                      child: Theme(
                        data: ThemeData(
                          primarySwatch: Colors.blue,
                          unselectedWidgetColor: isDark ? Colors.grey[500] : Colors.grey[700], // Your color
                        ),
                        child: Transform.scale(
                          scale: 0.8,
                          child: Checkbox(
                            value: widget.selectedCheckbox.contains(issue["id"]),
                            onChanged: (value) => widget.selectCheckbox(issue["id"])
                          )
                        )
                      )
                    ),
                    SizedBox(height: 1),
                    Container(
                      margin: EdgeInsets.all(6),
                      child: SvgPicture.asset('assets/icons/error_outline.svg',
                        color: !issueClosedTab ?Palette.successColor : Colors.redAccent
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          InkWell(
                            onTap: () {
                              onSelectIssue();
                            },
                            child: Container(
                              padding: EdgeInsets.only(right: 8, top: 4, bottom: 4),
                              child: Text(
                                issue["title"],
                                style: TextStyle(
                                  color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16
                                ),
                                maxLines: 10
                              )
                            ),
                          ),
                          Container(
                            child: Wrap(
                              children: issueLabels.map<Widget>((e) {
                                var label = e;
                                return InkWell(
                                  onTap: () => widget.selectAssignee(label["id"], label["name"], "label"),
                                  child: Container(
                                    padding: EdgeInsets.only(top: 4, bottom: 4),
                                    child: LabelDesktop(labelName: label["name"], color: int.parse("0XFF${label["color_hex"]}"))
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),

                      if (author != null) Container(
                        child: Wrap(
                          direction: Axis.horizontal,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.only(right: 4, top: 4, bottom: 4),
                              child: Wrap(
                                children: [
                                  Text(
                                    "#${issue["unique_id"]} opened ${issue["inserted_at"] != null ? parseDatetime(issue["inserted_at"]) : ''} by",
                                    style: TextStyle(
                                      color: isDark ? Color(0xffB7B7B7) : Colors.black.withOpacity(0.45),
                                      fontSize: 12
                                    )
                                  ),
                                  HiglightElement(
                                    onTap: () {
                                      widget.selectAssignee(author["id"], author["full_name"], "author");
                                    },
                                    title: "author",
                                    authorName: author["nickname"] ?? author["full_name"],
                                  )
                                ]
                              )
                            ),
                            issue["description"] != null ? parseDescription(issue["description"]) : Wrap(),
                            milestone != null ? HiglightElement(
                              onTap: () {
                                widget.selectMilestone(milestone["id"], milestone["title"]);
                              },
                              milestone: milestone,
                            ) : Container()
                          ]
                        ),
                      )
                    ]
                  ),
                )
              ]
            ),
          ),
          SizedBox(width: 12),
          Container(
            width: 100,
            height: 36,
            child: ListUser(assignees: assignees, selectAssignee: widget.selectAssignee)
          ),
          Container(
            width: 90,
            child: (issue["comments_count"] != null && issue["comments_count"] > 0) ? Wrap(
              direction: Axis.horizontal,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              children: [
                Icon(CupertinoIcons.bubble_right, size: 16, color: isDark ? Color(0xffB7B7B7) : Colors.black.withOpacity(0.45),),
                SizedBox(width: 3),
                Text(
                  "${issue["comments_count"]}",
                  style: TextStyle(
                    color: isDark ? Color(0xffB7B7B7) : Colors.black.withOpacity(0.45),
                    fontSize: 14.5
                  )
                )
              ]
            ) : Container()
          )
        ]
      )
    );
  }
}

class AssigneeAvatar extends StatefulWidget {
  const AssigneeAvatar({
    Key? key,
    required this.userId,
    required this.url,
    required this.name,
    required this.selectAssignee,
    required this.onHover
  }) : super(key: key);

  final userId;
  final url;
  final name;
  final selectAssignee;
  final Function onHover;

  @override
  State<AssigneeAvatar> createState() => _AssigneeAvatarState();
}

class _AssigneeAvatarState extends State<AssigneeAvatar> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onHover: (value) => widget.onHover(value, {
        'id': widget.userId,
        'full_name': widget.name,
        'avatar_url': widget.url
      }),
      onTap: () => widget.selectAssignee(widget.userId, widget.name, "assignee"),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // color: Colors.white70,
        ),
        padding: EdgeInsets.all(1),
        width: 34,
        height: 34,
        child: CachedImage(
          widget.url,
          width: 34,
          height: 34,
          isAvatar: true,
          radius: 50,
          name: widget.name
        ),
      ),
    );
  }
}

class SortList extends StatefulWidget {
  const SortList({
    Key? key,
    this.sortBy,
    this.changeSort
  }) : super(key: key);

  final sortBy;
  final changeSort;

  @override
  _SortListState createState() => _SortListState();
}

class _SortListState extends State<SortList> {
  var sortBy;

  @override
  void initState() {
    super.initState();
    this.setState(() {
      sortBy = widget.sortBy;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    return Container(
      height: 186,
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text("Sort by", style: TextStyle(fontWeight: FontWeight.w500))
          ),
          Divider(height: 0),
          Container(
            constraints: BoxConstraints(
              minWidth: 320
            ),
            child: TextButton(
              style: ButtonStyle(
                padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 18))
              ),
              child: Row(
                children: [
                  sortBy == "newest" ? Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor),
                  ) : SizedBox(width: 42, height: 18),
                  Text("Newest", style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065), fontWeight: FontWeight.w400)),
                ],
              ),
              onPressed: () {
                widget.changeSort("newest");
                setState(() {
                  sortBy = "newest";
                });
                Navigator.of(context).pop();
              },
            ),
          ),
          Divider(height: 0),
          Container(
            constraints: BoxConstraints(
              minWidth: 320
            ),
            child: TextButton(
              style: ButtonStyle(
                padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 18))
              ),
              child: Row(
                children: [
                  sortBy == "oldest" ? Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor),
                  ) : SizedBox(width: 42, height: 18),
                  Text("Oldest", style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065), fontWeight: FontWeight.w400)),
                ],
              ),
              onPressed: () {
                widget.changeSort("oldest");
                setState(() {
                  sortBy = "oldest";
                });
                Navigator.of(context).pop();
              },
            ),
          ),
          Divider(height: 0),
          Container(
            constraints: BoxConstraints(
              minWidth: 320,
            ),
            child: TextButton(
              style: ButtonStyle(
                padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 18))
              ),
              child: Row(
                children: [
                  sortBy == "recently_updated" ? Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor),
                  ) : SizedBox(width: 42, height: 18),
                  Text("Recently updated", style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065), fontWeight: FontWeight.w400)),
                ],
              ),
              onPressed: () {
                widget.changeSort("recently_updated");
                setState(() {
                  sortBy = "recently_updated";
                });
                Navigator.of(context).pop();
              },
            ),
          ),
          Divider(height: 0),
          Container(
            constraints: BoxConstraints(
              minWidth: 320,
            ),
            child: TextButton(
              style: ButtonStyle(
                padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 18))
              ),
              child: Row(
                children: [
                  sortBy == "least_recently_updated" ? Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor),
                  ) : SizedBox(width: 42, height: 18),
                  Text("Least recently updated", style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065), fontWeight: FontWeight.w400)),
                ],
              ),
              onPressed: () {
                widget.changeSort("least_recently_updated");
                setState(() {
                  sortBy = "least_recently_updated";
                });
                Navigator.of(context).pop();
              }
            )
          )
        ]
      ),
    );
  }
}

class HiglightElement extends StatefulWidget {
  HiglightElement({Key? key, required this.onTap, this.title, this.authorName, this.milestone}) : super(key: key);
  final onTap;
  final String? title;
  final String? authorName;
  final milestone;

  @override
  _HiglightElementState createState() => _HiglightElementState();
}

class _HiglightElementState extends State<HiglightElement> {
  bool highLight = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;

    return InkWell(
      onTap: widget.onTap,
      onHover: (hover) {
        if(highLight != hover) {
          setState(() {
            highLight = hover;
          });
        }
      },
      child: widget.title == "author" ? Container(
        padding: EdgeInsets.only(bottom: 1, left: 1, right: 1),
        child: Text(
          " ${widget.authorName} ",
          style: TextStyle(
            color: highLight ? Utils.getPrimaryColor() : isDark ? Color(0xffB7B7B7) : Colors.black.withOpacity(0.55),
            fontSize: 12
          )
        ),
      ) : Container(
        margin: EdgeInsets.only(bottom: 2),
        child: Wrap(
          direction: Axis.horizontal,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(CupertinoIcons.flag, size: 16, color: highLight ? Utils.getPrimaryColor() :  isDark ? Color(0xffB7B7B7) : Colors.black.withOpacity(0.55),),
            Text(
              widget.milestone["due_date"] != null ? (DateFormatter().renderTime(DateTime.parse(widget.milestone["due_date"]), type: "MMMd")) : "",
              style: TextStyle(color: highLight ? Utils.getPrimaryColor() : isDark ? Color(0xffB7B7B7) : Colors.black.withOpacity(0.55), fontSize: 12.5)
            )
          ]
        ),
      ),
    );
  }
}
