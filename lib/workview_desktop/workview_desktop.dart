import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/boardview/kanban_view.dart';
import 'package:workcake/components/dropdown_overlay.dart';
import 'package:workcake/components/right_sider.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/workview_desktop/search_bar_issue.dart';

import 'issue_table.dart';
import 'label_table.dart';
import 'milestones_table.dart';

class WorkviewDesktop extends StatefulWidget {
  WorkviewDesktop({
    Key? key,
  }) : super(key: key);

  @override
  _WorkviewDesktopState createState() => _WorkviewDesktopState();
}

class _WorkviewDesktopState extends State<WorkviewDesktop> {
  String currentTab = "issue";
  bool createLabel = false;
  bool createMilestone = false;
  bool createIssue = false;
  var selectedMilestone;
  var selectedLabel;
  int resetFilter = 0;
  List filters = [];
  String text = "";
  bool unreadOnly = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<Auth>(context, listen: false);
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;

    if (currentChannel["kanban_mode"] == false) {
      Provider.of<Channels>(context, listen: false).getMilestoneStatiscal(auth.token, currentWorkspace["id"], currentChannel["id"]);
    }
  }

  closeTable() {
    this.setState(() {
      createLabel = false;
      createMilestone = false;
      createIssue = false;
    });
  }

  onSelectMilestone(milestone) {
    this.setState(() {
      selectedMilestone = milestone;
      currentTab = "issue";
      filters = [{"type": "milestone", "name": milestone["title"], "id": milestone["id"]}];
    });
  }

  onSelectLabel(label) {
    this.setState(() {
      selectedLabel = label;
      filters = [{"type": "label", "name": label["name"], "id": label["id"]}];
      currentTab = "issue";
    });
  }

  onSearchIssue(value) {
    this.setState(() { text = value ?? ""; });
    final auth = Provider.of<Auth>(context, listen: false);
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final issueClosedTab = Provider.of<Work>(context, listen: false).issueClosedTab;

    Provider.of<Channels>(context, listen: false).getListIssue(auth.token, currentWorkspace["id"], currentChannel["id"], 1, issueClosedTab, filters, "newest", text, unreadOnly);
  }

  onChangeFilter(filters) {
    this.setState(() {
      this.filters = filters;
    });
  }

  @override
  Widget build(BuildContext context) {
    resetFilter = Provider.of<Work>(context, listen: true).resetFilter;
    final currentChannel = Provider.of<Channels>(context).currentChannel;
    final channelMember = Provider.of<Channels>(context).channelMember;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    final currentMember = Provider.of<Channels>(context, listen: true).currentMember;
    final issueClosedTab = Provider.of<Work>(context, listen: true).issueClosedTab;
    final auth = Provider.of<Auth>(context, listen: true);
    final isDark = auth.theme == ThemeType.DARK;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            children: [
              WorkviewHeader(currentChannel: currentChannel, currentMember: currentMember, auth: auth, currentWorkspace: currentWorkspace, channelMember: channelMember),
              currentChannel["kanban_mode"] == true ? KanbanView(channelId: currentChannel["id"]) : Container(
                padding: EdgeInsets.only(top: 24, right: 24, left: 24, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        TextButton(
                          style: ButtonStyle(
                            shape: MaterialStateProperty.all(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                            )),
                            padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
                            backgroundColor: MaterialStateProperty.all(currentTab == "issue" ? Palette.buttonColor :
                              currentTab == "label" && !createLabel ? Utils.getPrimaryColor() :
                              currentTab == "milestone" && !createMilestone ? Utils.getPrimaryColor() : Color(0xff1E1E1E)),
                            overlayColor: MaterialStateProperty.all(Color(0xff0969DA))
                          ),
                          onPressed: currentTab == "issue" ? () async {
                            var box = await Hive.openBox("draftsIssue");
                            var boxDraftIssue = box.get(currentChannel["id"].toString());
                            String description = '';
                            String title = '';
                            List assignees = [];
                            List labels = [];
                            List milestone = [];

                            if (boxDraftIssue != null) {
                              description = boxDraftIssue["description"] ?? "";
                              title = boxDraftIssue["title"] ?? "";
                              assignees = boxDraftIssue["assignees"] ?? [];
                              labels = boxDraftIssue["labels"] ?? [];
                              milestone = boxDraftIssue["milestone"] ?? [];
                            }

                            Provider.of<Channels>(context, listen: false).onChangeOpenIssue({
                              'type': 'create',
                              'description': description,
                              'title': title,
                              'is_closed': false,
                              'assignees': assignees,
                              'labels': labels,
                              'milestone': milestone
                            });
                          } : currentTab == "label" && !createLabel ? () {this.setState(() {
                            createLabel = true;
                          });}
                            : currentTab == "milestone" && !createMilestone ? () {this.setState(() {
                              createMilestone = true;
                            });} : null,
                          child: Text(currentTab == "issue" ? S.current.newIssue : currentTab == "label" ? S.current.newLabel : S.current.newMilestone, style: TextStyle(color: Colors.white)),
                        ),
                        SearchBarIssue(onSearchIssue: onSearchIssue)
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: currentTab == "issue" ? (isDark ? Color(0xff5E5E5E) : Color(0xff3D3D3D)): (isDark ? Color(0xff1E1E1E) : Color(0xffF8F8F8)),
                            border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xff3D3D3D), width: 1),
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(2), bottomLeft: Radius.circular(2))
                          ),
                          child: HoverItem(
                            colorHover: currentTab == "issue" ? Colors.transparent : Colors.grey.withOpacity(0.2),
                            child: InkWell(
                              onTap: () {
                                this.setState(() {
                                  currentTab = "issue";
                                  resetFilter++;
                                  selectedMilestone = null;
                                });
                                Provider.of<Channels>(context, listen: false).getListIssue(auth.token, currentWorkspace["id"], currentChannel["id"], 1, issueClosedTab, [], "newest", text, unreadOnly);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                                height: 32,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(padding: EdgeInsets.only(top: 2), child: Icon(CupertinoIcons.info_circle, size: 14, color: currentTab == "issue" ? Colors.white : (isDark ? Colors.white : Colors.black87))),
                                    SizedBox(width: 6),
                                    Text(S.current.issues, style: TextStyle(color: currentTab == "issue" ? Colors.white : (isDark ? Colors.white : Colors.black87), fontWeight: FontWeight.normal, fontSize: 13.5))
                                  ],
                                ),
                              )
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: currentTab == "label" ? (isDark ? Color(0xff5E5E5E) : Color(0xff3D3D3D)): (isDark ? Color(0xff1E1E1E) : Color(0xffF8F8F8)),
                            border: Border(
                              top: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xff3D3D3D), width: 1),
                              bottom: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xff3D3D3D), width: 1),
                              ),
                          ),
                          child: HoverItem(
                            colorHover: currentTab == "label" ? Colors.transparent : Colors.grey.withOpacity(0.2),
                            child: InkWell(
                              onTap: () {
                                this.setState(() {
                                  currentTab = "label";
                                  resetFilter++;
                                  selectedMilestone = null;
                                });
                                Provider.of<Channels>(context, listen: false).getLabelsStatistical(auth.token, currentWorkspace["id"], currentChannel["id"]);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                                height: 32,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(padding: EdgeInsets.only(top: 2), child: Icon(CupertinoIcons.tag, size: 14, color: currentTab == "label" ? Colors.white : (isDark ? Colors.white : Colors.black87))),
                                    SizedBox(width: 6),
                                    Text(S.current.labels, style: TextStyle(color: currentTab == "label" ? Colors.white : (isDark ? Colors.white : Colors.black87), fontWeight: FontWeight.normal, fontSize: 13.5))
                                  ],
                                ),
                              )
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: currentTab == "milestone" ? (isDark ? Color(0xff5E5E5E) : Color(0xff3D3D3D)): (isDark ? Color(0xff1E1E1E) : Color(0xffF8F8F8)),
                            border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xff3D3D3D), width: 1),
                            borderRadius: BorderRadius.only(topRight: Radius.circular(2), bottomRight: Radius.circular(2))
                          ),
                          child: HoverItem(
                            colorHover: currentTab == "milestone" ? Colors.transparent : Colors.grey.withOpacity(0.2),
                            child: InkWell(
                              onTap: () {
                                this.setState(() {
                                  currentTab = "milestone";
                                });
                                Provider.of<Channels>(context, listen: false).getMilestoneStatiscal(auth.token, currentWorkspace["id"], currentChannel["id"]);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                                height: 32,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(padding: EdgeInsets.only(top: 2), child: Icon(CupertinoIcons.flag, size: 14, color: currentTab == "milestone" ? Colors.white : (isDark ? Colors.white : Colors.black87))),
                                    SizedBox(width: 6),
                                    Text(S.current.milestones, style: TextStyle(color: currentTab == "milestone" ? Colors.white : (isDark ? Colors.white : Colors.black87), fontWeight: FontWeight.normal, fontSize: 13.5))
                                  ],
                                ),
                              )
                            ),
                          ),
                        ),
                      ]
                    )
                  ]
                )
              ),
              if (currentChannel["kanban_mode"] != true) Expanded(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 50),
                  child: currentTab == "issue" ? IssueTable(key: ValueKey(1), channelId: currentChannel["id"], milestone: selectedMilestone, resetFilter: resetFilter, onChangeFilter: onChangeFilter, text: text, label: selectedLabel) :
                    currentTab == "label" ? LabelTable(key: ValueKey(2),createLabel: createLabel, closeTable: closeTable, channelId: currentChannel["id"], onSelectLabel: onSelectLabel) :
                    MilestonesTable(key: ValueKey(3),createMilestone: createMilestone, closeTable: closeTable, onSelectMilestone: onSelectMilestone, channelId: currentChannel["id"]),
                )
              )
            ]
          ),
        ),
      ],
    );
  }
}

class WorkviewHeader extends StatefulWidget {
  const WorkviewHeader({
    Key? key,
    @required this.currentChannel,
    @required this.currentMember,
    @required this.auth,
    @required this.currentWorkspace,
    @required this.channelMember,
    this.onChangeMode
  }) : super(key: key);

  final currentChannel;
  final currentMember;
  final auth;
  final currentWorkspace;
  final channelMember;
  final onChangeMode;

  @override
  _WorkviewHeaderState createState() => _WorkviewHeaderState();
}

class _WorkviewHeaderState extends State<WorkviewHeader> {

  onChangeSubcribeIssue() {
    final auth = Provider.of<Auth>(context, listen: false);
    Navigator.pop(context);
    Map member = Map.from(widget.currentMember);
    member["subcribe_issue"] = !Utils.checkedTypeEmpty(member["subcribe_issue"]);

    Provider.of<Channels>(context, listen: false).changeChannelMemberInfo(auth.token, widget.currentWorkspace["id"], widget.currentChannel["id"], member, "");
  }

  Widget _workViewHeader() {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () {},
                  child: Container(
                    decoration: BoxDecoration(
                      color: Palette.backgroundTheardDark,
                      borderRadius: BorderRadius.all(Radius.circular(2))
                    ),
                    height: 32, width: 232,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.only(left: 8),
                            child: Text(
                              widget.currentChannel?["name"] ?? "",
                              style: TextStyle(
                                color: Color(0xffF0F4F8),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, color: Colors.white, size: 20)
                      ]
                    )
                  )
                ),
                SizedBox(width: 10),
                widget.currentMember != null && widget.currentMember["watching_issue"] != null ? InkWell(
                  child: DropdownOverlay(
                    menuDirection: MenuDirection.start,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: HoverItem(
                        colorHover: Palette.hoverColorDefault,
                        child: Container(
                          height: 30,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              width: 1,
                              color: Palette.borderSideColorLight,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment:  MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Utils.checkedTypeEmpty(widget.currentMember["watching_issue"]) ? CupertinoIcons.eye_slash : CupertinoIcons.eye, color: Palette.topicTile, size: 15),
                              SizedBox(width: 5),
                              Text(
                                Utils.checkedTypeEmpty(widget.currentMember["watching_issue"]) ? S.current.unwatch : S.current.watch,
                                style: TextStyle(
                                  color: Palette.topicTile,
                                  fontSize: 14
                                )
                              ),
                              SizedBox(width: 8),
                              Icon(CupertinoIcons.arrowtriangle_down_fill, color: Palette.topicTile, size: 12),
                            ]
                          ),
                        ),
                      ),
                    ),
                    dropdownWindow: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xff4C4C4C) : Colors.white,
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: Column(
                        children: [
                          TextButton(
                            style: ButtonStyle(
                              overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                              padding: MaterialStateProperty.all(EdgeInsets.zero)
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              Map member = Map.from(widget.currentMember);
                              member["watching_issue"] = false;

                              Provider.of<Channels>(context, listen: false).changeChannelMemberInfo(auth.token, widget.currentWorkspace["id"], widget.currentChannel["id"], member, "");
                            },
                            child: HoverItem(
                              colorHover: Palette.hoverColorDefault,
                              child: Container(
                                decoration: BoxDecoration(
                                  // border: Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)),
                                  color: Colors.transparent,
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 5),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 30,
                                      child: !Utils.checkedTypeEmpty(widget.currentMember["watching_issue"])
                                          ? Icon(CupertinoIcons.checkmark_alt, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, size: 15)
                                          : null,
                                    ),
                                    Expanded(
                                      child: Container(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              S.current.watchMention,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                                              ),
                                            ),
                                            Text(
                                              S.current.descWatchMention,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: isDark ? Color(0xffB7B7B7) : Colors.black.withOpacity(0.45),
                                              ),
                                            ),
                                          ],
                                        )
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            style: ButtonStyle(
                              overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                              padding: MaterialStateProperty.all(EdgeInsets.zero)
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              Map member = Map.from(widget.currentMember);
                              member["watching_issue"] = true;

                              Provider.of<Channels>(context, listen: false).changeChannelMemberInfo(auth.token, widget.currentWorkspace["id"], widget.currentChannel["id"], member, "");
                            },
                            child: HoverItem(
                              colorHover: Palette.hoverColorDefault,
                              child: Container(
                                decoration: BoxDecoration(
                                  // border: Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)),
                                  color: Colors.transparent,
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 5),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 30,
                                      child: Utils.checkedTypeEmpty(widget.currentMember["watching_issue"])
                                          ? Icon(CupertinoIcons.checkmark_alt, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, size: 15)
                                          : null,
                                    ),
                                    Expanded(
                                      child: Container(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              S.current.watchActivity,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                                              ),
                                            ),
                                            Text(
                                              S.current.descWatchActivity,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: isDark ? Color(0xffB7B7B7) : Colors.black.withOpacity(0.45),
                                              )
                                            )
                                          ]
                                        )
                                      )
                                    )
                                  ]
                                )
                              ),
                            )
                          ),
                          Divider(),
                          TextButton(
                            style: ButtonStyle(
                              overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                              padding: MaterialStateProperty.all(EdgeInsets.zero)
                            ),
                            onPressed: () => onChangeSubcribeIssue(),
                            child: HoverItem(
                              colorHover: Palette.hoverColorDefault,
                              child: Container(
                                decoration: BoxDecoration(
                                  // border: Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)),
                                  color: Colors.transparent,
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 5),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 30,
                                      child: Utils.checkedTypeEmpty(widget.currentMember["subcribe_issue"])
                                          ? Icon(CupertinoIcons.checkmark_alt, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, size: 15)
                                          : null,
                                    ),
                                    Expanded(
                                      child: Container(
                                        child: Text(
                                          S.current.watchAllComment,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                                          ),
                                        )
                                      )
                                    )
                                  ]
                                )
                              ),
                            ),
                          ),
                        ]
                      )
                    ),
                    width: 260,
                    isAnimated: true
                  ),
                ) : Container()
                // Container(
                //   margin: EdgeInsets.all(8),
                //   child: SvgPicture.asset('assets/icons/back_time.svg')
                // ),
                // Text('Dev_pancake', style: TextStyle(color: Colors.white)),
                // SizedBox(width: 10)
              ]
            )
          ]
        ),
        ButtonOpenView(isTap: true)
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return widget.currentChannel["kanban_mode"] != true ? Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Color(0xfcfcff)),
        ),
        color: Color(0xff3D3D3D),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: _workViewHeader()
    ) : Container();
  }
}