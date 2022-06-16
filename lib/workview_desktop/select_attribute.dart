import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/dropdown_overlay.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/models/models.dart';
import 'label.dart';

class SelectAttribute extends StatefulWidget {
  const SelectAttribute({
    Key? key,
    this.issue,
    required this.title,
    required this.icon,
    required this.listAttribute,
    required this.selectedAtt,
    required this.selectAttribute,
    this.fromMessage,
    this.dropdownKey,
    this.nextDropdown, this.closeTable, this.onSearchAttribute,
  }) : super(key: key);

  final issue;
  final title;
  final icon;
  final listAttribute;
  final selectedAtt;
  final selectAttribute;
  final fromMessage;
  final dropdownKey;
  final nextDropdown;
  final closeTable;
  final onSearchAttribute;

  @override
  _SelectAttributeState createState() => _SelectAttributeState();
}

class _SelectAttributeState extends State<SelectAttribute> {
  List listAttribute = [];
  List selectedDefault = [];
  List beforeAttribute = [];
  FocusNode _focusNodeInput = FocusNode();
  GlobalKey<DropdownOverlayState> _currentDropdownKey = GlobalKey<DropdownOverlayState>();
  final _descriptionController = TextEditingController();

  TextEditingController _titleController = TextEditingController();

  List colors = [
    "1CE9AE", "0E8A16", "0052CC", "5319E7", "FF2C65", "FBA704", "D93F0B", "B60205", "CECECE",
    "57B99D", "65C87A", "5097D5", "925EB1", "D63964", "EAC545", "D8823B", "D65745", "98A5A6",
    "397E6B", "448852", "346690", "693B86", "9F2857", "B87E2E", "9C481B", "8D3529", "667C89"
  ];
  Random random = new Random();
  var pickedColor;
  var pickedColorEdit;
  var selectLabel;
  var selectedMilestone;
  DateTime dateTime = DateTime.now();
  int tab = 1;
  String textSearch = '';
  var indexFind;

  @override
  void initState() { 
    super.initState();
    _currentDropdownKey = widget.dropdownKey;
    this.setState(() {
      listAttribute = sortListAttribute();
      pickedColor = random.nextInt(8);
    });
    _focusNodeInput = FocusNode(
      onKey: (node, event) {
        if(event is RawKeyDownEvent) {
          if(event.isKeyPressed(LogicalKeyboardKey.enter)) {
            Navigator.pop(context);
          } else if(event.isKeyPressed(LogicalKeyboardKey.arrowDown) ) {
            node.nextFocus();
          } else if(event.isKeyPressed(LogicalKeyboardKey.tab)) {
            _currentDropdownKey.currentState!.removeDropdownRoute();
            if(widget.title != "Milestone") {
              widget.nextDropdown(widget.title);
            }
          }
        }
        return KeyEventResult.ignored;
      }
    );
    
  }

  @override
  void didUpdateWidget (oldWidget) {
    if (oldWidget.listAttribute.length != widget.listAttribute.length) {
      listAttribute = sortListAttribute();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _focusNodeInput.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String text = "";
  onCreateMilestone() {
    final token = Provider.of<Auth>(context, listen: false).token;
    final List dataWS = Provider.of<Workspaces>(context, listen: false).data;
    final List dataCN = Provider.of<Channels>(context, listen: false).data;

    int indexWS = dataWS.indexWhere((ele) => ele['id'] == widget.issue['workspace_id']);
    int indexCN = dataCN.indexWhere((ele) => ele['id'] == widget.issue['channel_id']);

    final currentChannel = indexCN != -1 ? dataCN[indexCN] : Provider.of<Channels>(context, listen: false).currentChannel;
    final currentWorkspace = indexWS != -1 ? dataWS[indexWS] : Provider.of<Workspaces>(context, listen: false).currentWorkspace;

    List milestones = currentChannel["milestones"];
    if (Utils.checkedTypeEmpty(_titleController.text)) {
      final index = milestones.indexWhere((e) => e["name"] == _titleController.text);
      if (index == -1) {
      Map milestone = {
        "title": _titleController.text,
        "description": _descriptionController.text,
        "due_date": dateTime.toUtc().millisecondsSinceEpoch~/1000 + 86400
      };

      Provider.of<Channels>(context, listen: false).createChannelMilestone(token, currentWorkspace["id"], currentChannel["id"], milestone);
      _titleController.clear();
      _descriptionController.clear();
      }
    }
  }
  getListLabel() {
    var listLabel = [];
    for(int index = 0; index < widget.selectedAtt.length; index++) {
      var labelId =  widget.selectedAtt[index];
      var itemIndex = widget.listAttribute.indexWhere((e) => e["id"].toString() == labelId.toString());
      var item = itemIndex != -1 ? widget.listAttribute[itemIndex] : null;
      if (item == null) {
        // return [];
      } else {
        listLabel.add(item);
      }
    }
    return listLabel;
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

  renderDueDate({milestone, isIcon = false}) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final DateTime now = DateTime. now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final formatted = formatter. format(now);
    final isPast = (milestone["due_date"].compareTo(formatted) < 0);
    
    return isIcon ? Container(
      padding: EdgeInsets.only(left: 16),
      child: Icon(isPast ? Icons.warning_amber_outlined : Icons.calendar_today_outlined,
      size: 19,
      color: isPast ? Color(0xffEB5757) : isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65))
    ) : Container(
      child:
        Text(
          milestone["due_date"] != null
            ? isPast
              ? calculateDueby(milestone["due_date"])
              : "Due by " + (DateFormatter().renderTime(DateTime.parse(milestone["due_date"]), type: "yMMMMd"))
            : "",
          style: TextStyle(color: isPast ? Color(0xffEB5757) : isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65), fontSize: 12, fontWeight: isPast ? FontWeight.w600 : FontWeight.w400)
        ),
    );
  }
showDialogNewLable(context) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;
  this.setState(() {
    listAttribute = sortListAttribute();
    pickedColor = random.nextInt(8);
  }); 
  Navigator.pop(context);

  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: Duration(milliseconds: 80),
    transitionBuilder: (context, a1, a2, widget){
      var begin = 0.5;
      var end = 1.0;
      var curve = Curves.decelerate;
      var curveTween = CurveTween(curve: curve);
      var tween = Tween(begin: begin, end: end).chain(curveTween);
      var offsetAnimation = a1.drive(tween);
      return ScaleTransition(
        scale: offsetAnimation,
        child: FadeTransition(
          opacity: a1,
          child: widget,
        ),
      );
    },
    pageBuilder: (BuildContext context, a1, a2) {
      return Container(
        child: AlertDialog(
          contentPadding: EdgeInsets.zero,
          clipBehavior : Clip.none,
          backgroundColor: isDark ? Color(0xff3D3D3D) : Colors.white,
          content: Container(
            height: 450.0,
            width: 400.0,
            child: Center(
              child: createOrNewLabel(context, null),
            )
          ),
        ),
      );
    }
  );
}

showDialogNewMilestones(context) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;
  this.setState(() {
    listAttribute = sortListAttribute();
    pickedColor = random.nextInt(8);
  }); 
  Navigator.pop(context);

  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: Duration(milliseconds: 80),
    transitionBuilder: (context, a1, a2, widget){
      var begin = 0.5;
      var end = 1.0;
      var curve = Curves.decelerate;
      var curveTween = CurveTween(curve: curve);
      var tween = Tween(begin: begin, end: end).chain(curveTween);
      var offsetAnimation = a1.drive(tween);
      return ScaleTransition(
        scale: offsetAnimation,
        child: FadeTransition(
          opacity: a1,
          child: widget,
        ),
      );
    },
    pageBuilder: (BuildContext context, a1, a2) {
      return Container(
        child: AlertDialog(
          contentPadding: EdgeInsets.zero,
          clipBehavior : Clip.none,

          backgroundColor: isDark ? Color(0xff3D3D3D) : Colors.white,
          content: Container(
            height: 330.0,
            width: 450.0,
            child: Center(
              child: createOrNewMilestones(context, null),
            )
          ),
        ),
      );
    }
  );
}
  calculateMilestone(milestone) {
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final milestonesStatistical = currentChannel["milestonesStatistical"] ?? [];

    int closed = 0;
    int open = 0;
    double percent = 0;
    for(var ms in milestonesStatistical) {
      if(ms["id"] == milestone["id"]) {
        closed = ms["close_issue"].length == 0 ? 0 : ms["close_issue"][0];
        open = ms["open_issue"].length == 0 ? 0 : ms["open_issue"][0];
        percent = open + closed > 0 ? closed / (open + closed) * 100 : 0;
        break;
      }
    }

    return {
      "closed": closed,
      "open": open,
      "percent": percent
    };
  }

  onRemoveAttribute(attributeId) {
    final index = widget.listAttribute.indexWhere((e) => e["id"] == attributeId);

    if (index != -1) {
      widget.selectAttribute(widget.listAttribute[index]);
    }
  }

  onFilterAttribute(value) {
    if (value.trim() != "") {
      List list = List.from(sortListAttribute()).where((e) {
        if (widget.title == "Assignees") {
          return Utils.unSignVietnamese(e["full_name"]).contains(Utils.unSignVietnamese(value)) ? true : false;
        } else if (widget.title == "Labels") {
          return e["name"].toLowerCase().contains(value) ? true : false;
        } else {
          return e["title"].toLowerCase().contains(value) ? true : false;
        }
      }).toList();

      setState(() {
        listAttribute = list;
      });
    } else {
      setState(() {
        listAttribute = sortListAttribute();
      });
    }
  }

  sortListAttribute() {
    List listAttribute = widget.listAttribute ?? [];
    List listIdSelected = widget.selectedAtt ?? [];
    List selectedList = listAttribute.where((item) => listIdSelected.contains(item["id"])).toList();
    List unSelectedList = listAttribute.where((item) => !listIdSelected.contains(item["id"])).toList();

    return selectedList + unSelectedList;
  }

  getCurrentChannel(){
    if (widget.issue["id"] == null) {
      return Provider.of<Channels>(context, listen: false).currentChannel["id"];
    } else {
      return widget.issue["channel_id"];
    }
  }

  listAssignee() {
    if (widget.fromMessage ?? false) return Provider.of<Workspaces>(context, listen: false).members;

    final members = Provider.of<Channels>(context, listen: true).listChannelMember;
    final channelId = getCurrentChannel();
    final index = members.indexWhere((e) => e["id"] == channelId);
    final workspaceMember = index == -1 ? [] : members[index]["members"];

    return workspaceMember;
  }

  updateIssueTimeline(beforeAttribute, selectedAtt) async {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final workspaceId = widget.issue['workspace_id'] ?? currentWorkspace['id'];
    final channelId = widget.issue['channel_id'] ?? currentChannel['id'];
    List added = [];
    List removed = [];

    if (widget.issue["id"] != null) {
      for (var item in selectedAtt) {
        if (!beforeAttribute.contains(item)) {
          added.add(item);
        }
      }

      for (var item in beforeAttribute) {
        if (!widget.selectedAtt.contains(item)) {
          removed.add(item);
        }
      }

      if ((added.length > 0 || removed.length > 0)) {
        Map data = {
          "type": widget.title.toLowerCase(),
          "added": added,
          "removed": removed
        };

        await Provider.of<Channels>(context, listen: false).updateIssueTimeline(auth.token, workspaceId, channelId, widget.issue["id"], data);
      }

      setState(() {
        listAttribute = sortListAttribute();
        selectedDefault = [];
      });
    }
  }
  goDirectAssignee(user) async {
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    Provider.of<Workspaces>(context, listen: false).setTab(0);
    Provider.of<DirectMessage>(context, listen: false).setSelectedDM(DirectModel(
      "", 
      [
        {"user_id": currentUser["id"], "full_name": currentUser["full_name"], "avatar_url": currentUser["avatar_url"], "is_online": true},
        {"user_id": user["id"], "full_name": user["full_name"], "avatar_url": user["avatar_url"], "is_online": user["is_online"]}
      ], "", false, 0, {}, false, 0, {}, user["full_name"], null), ""
    );
    final keyScaffold = Provider.of<Auth>(context, listen: false).keyDrawer;
    keyScaffold.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final workspaceMember = widget.title == "Assignees" ? listAssignee() : [];
    final labels = widget.title == "Labels" ? getListLabel() : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownOverlay(
          key: widget.dropdownKey,
          menuDirection: MenuDirection.end,
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isDark ? Palette.borderSideColorDark : Color(0xffEDEDED),
                ),
                child: HoverItem(
                  colorHover: Colors.grey.withOpacity(0.2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${widget.title}", style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65), fontSize: 14, fontWeight: FontWeight.w700)),
                        widget.icon
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          dropdownWindow: StatefulBuilder(
            builder: (context, setState) {
              var colorNavigate = isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.45);
              if (listAttribute.length == -1) {
                setState((){
                  listAttribute = sortListAttribute();
                }
              );
            } 
            return Container(
              decoration: BoxDecoration(
                color: isDark ? Palette.backgroundTheardDark : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
                          )
                        ),
                        height: 56,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 5),
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
                            suffixIcon: Utils.checkedTypeEmpty(_titleController.text) ? InkWell(
                              child: Icon(Icons.clear, size: 14, color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65)),
                              onTap: () {
                                _titleController.clear();
                                onFilterAttribute("");
                                setState(() => textSearch = "");
                              }) : null,
                            contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight), borderRadius: BorderRadius.all(Radius.circular(4))),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight), borderRadius: BorderRadius.all(Radius.circular(4))),
                          ),
                          style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65), fontSize: 13, fontWeight: FontWeight.w400),
                          onChanged: (value) {
                            onFilterAttribute(value.toLowerCase());
                            setState(() {
                              textSearch = value;
                              indexFind = -1;
                            });
                          },
                        ),
                      ),
                      if(indexFind == -1 && listAttribute.length == 0) widget.title == "Labels" ? InkWell(
                        onTap: (){
                          showDialogNewLable(context);
                            this.setState(() {}); 
                          },
                        child: HoverItem(
                          colorHover: isDark ? Color(0xff828282) : Color(0xffDBDBDB),
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
                              )
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bookmark_add_outlined,size: 16,),
                                SizedBox(width: 10,),
                                Text("Create new label",style: TextStyle(fontSize: 14),),
                              ],
                            ),
                          ),
                        ),
                      ):SizedBox(),
                      if(indexFind == -1 && listAttribute.length==0) widget.title == "Milestone" ? InkWell(
                        onTap: (){
                          showDialogNewMilestones(context);
                          this.setState(() {}); 
                        },
                        child: HoverItem(
                          colorHover: isDark ? Color(0xff828282) : Color(0xffDBDBDB),
                          child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
                          )
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIcons.flag,size: 16,),
                            SizedBox(width: 10,),
                            Text("Create new Milestone",style: TextStyle(fontSize: 14),),
                          ],
                        ),
                      ),
                        ),
                      ):SizedBox(),
                      Container(
                        height: 380,
                        child: SingleChildScrollView(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: listAttribute.length, 
                            itemBuilder: (BuildContext context, int index) {
                              var item = listAttribute[index];
                              return Focus(
                                focusNode: FocusNode(
                                  onKey: (FocusNode node, RawKeyEvent event) {
                                    if (event is RawKeyDownEvent) {
                                      if(event.isKeyPressed(LogicalKeyboardKey.enter)) {
                                        final index = selectedDefault.indexWhere((e) => e == item["id"]);
                                        List list = List.from(selectedDefault);
                                        if (index != -1) list.removeAt(index);
                                        else list.add(item["id"]);
                                        setState(() => selectedDefault = list);
                                        widget.selectAttribute(item);
                                        Navigator.pop(context);
                                        return KeyEventResult.handled;
                                      } else if(event.isKeyPressed(LogicalKeyboardKey.tab)) {
                                        _currentDropdownKey.currentState!.removeDropdownRoute();
                                        if(widget.title != "Milestone") {
                                          widget.nextDropdown(widget.title);
                                        }
                                      } else if(!(event.isKeyPressed(LogicalKeyboardKey.arrowDown) || event.isKeyPressed(LogicalKeyboardKey.arrowUp)
                                        || event.isKeyPressed(LogicalKeyboardKey.enter) || event.isKeyPressed(LogicalKeyboardKey.space)
                                        || event.isKeyPressed(LogicalKeyboardKey.tab)
                                      )){
                                        _focusNodeInput.requestFocus();
                                      } else if(event.isKeyPressed(LogicalKeyboardKey.tab)) {
                                        _currentDropdownKey.currentState!.dispose();
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
                                  onPressed: () {
                                    final index = selectedDefault.indexWhere((e) => e == item["id"]);
                                    List list = List.from(selectedDefault);
                                    if (index != -1) list.removeAt(index);
                                    else list.add(item["id"]);
                                    setState(() => selectedDefault = list);
                                    widget.selectAttribute(item);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)),
                                      color: selectedDefault.contains(item["id"]) && widget.title == "Milestone" ? (isDark ? Color(0xff323F4B) : Color(0xffE4E7EB)) : Colors.transparent,
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 5),
                                    child: Row(
                                      children: [
                                        if(widget.title == "Milestone") renderDueDate(milestone: item, isIcon: true),
                                        Container(
                                          margin: widget.title == "Milestone" ? EdgeInsets.only(left: 16) : EdgeInsets.only(left: 0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: widget.title == "Milestone" ? 198 : 288,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Container(
                                                      child: Row(
                                                        children: [
                                                          if (widget.title != "Milestone") SizedBox(width: 12),
                                                          if (widget.title == "Assignees") CachedImage(
                                                            item["avatar_url"],
                                                            height: 24,
                                                            width: 24,
                                                            radius: 50,
                                                            name: item["nickname"] ?? item["full_name"],
                                                          ),
                                                          if (widget.title == "Assignees") SizedBox(width: 12),
                                                          Container(
                                                            width: widget.title == "Milestone" ? 100 : null,
                                                            padding: EdgeInsets.symmetric(vertical: widget.title != "Milestone" ? 4 : 0, horizontal: widget.title == "Labels" ? 8 : 0),
                                                            decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.circular(16),
                                                              color: widget.title == "Labels" ? Color(int.parse("0xFF${listAttribute[index]["color_hex"]}")) : Colors.transparent,
                                                            ),
                                                            child: Text(
                                                              widget.title == "Milestone" ? item["title"] :  widget.title == "Labels" ? item["name"] : item["nickname"] ?? item["full_name"], 
                                                              style: TextStyle(color: widget.title == "Labels" ? Colors.white : (isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)), fontWeight: widget.title == "Labels" ? FontWeight.w400 : FontWeight.w600, fontSize: widget.title == "Labels" ? 12 : 14),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      margin: EdgeInsets.only(right: 15),
                                                      child: selectedDefault.contains(item["id"]) && widget.title != "Milestone"
                                                      ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                                      : Container(width: 16, height: 16)
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              if (widget.title == "Milestone") Container(
                                                margin: EdgeInsets.only(top: 6),
                                                child: Row(children: [
                                                  Container(
                                                    child: widget.title == "Milestone" ? renderDueDate(milestone: item) : 
                                                    Text(item["description"], style: TextStyle(color: Colors.grey[700]))),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                            Text("Use", style: TextStyle(fontSize: 13.5, color:colorNavigate,)),
                            SizedBox(width: 6,),
                            Icon(CupertinoIcons.arrow_up, size: 17, color: colorNavigate,),
                            SizedBox(width: 4,),
                            Icon(CupertinoIcons.arrow_down, size: 17, color: colorNavigate),
                            SizedBox(width: 4,),
                            Platform.isMacOS ? Icon(CupertinoIcons.return_icon, size: 17, color: colorNavigate,) : Icon(Icons.subdirectory_arrow_left, size: 18, color: colorNavigate),
                            SizedBox(width: 6,),
                            Text("to navigate", style: TextStyle(fontSize: 13.5, color: colorNavigate))
                          ],
                        ),
                      )
                    ],
                  )
                )
              );
            }
          ),
          isAnimated: true,
          onTap: () {
            selectedDefault = List.from(widget.selectedAtt);
            beforeAttribute = List.from(widget.selectedAtt);
          },
          onPop: () {
            updateIssueTimeline(beforeAttribute, widget.selectedAtt);
            listAttribute = sortListAttribute();
            _titleController.clear();
          }
        ),

        widget.selectedAtt.length == 0 ? Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  final userId = Provider.of<Auth>(context, listen: false).userId;
                  final index = workspaceMember.indexWhere((e) => e["id"] == userId);
                  if (index == -1) return;
                  List list = List.from(selectedDefault);
                  list.add(userId);
                  setState(() => selectedDefault = list);
                  widget.selectAttribute(workspaceMember[index]);
                  updateIssueTimeline([], list);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4.0,),
                  height: 24,
                  child: Text(
                    widget.title == "Milestone" ? "No milestone" : widget.title == "Labels" ? "None yet" : "No one-assign yourself", 
                    style: TextStyle(color: isDark ? Color(0xffD9D9D9) : Color.fromRGBO(0, 0, 0, 0.45), fontSize: 12)
                  )
                )
              )
            ]
          )
        )
        : ( widget.title != "Labels" ? Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.selectedAtt.length,
            itemBuilder: (BuildContext context, int index) {
              var itemIndex = (widget.title == "Assignees" ? workspaceMember : widget.listAttribute).indexWhere((e) => e["id"] == widget.selectedAtt[index]);
              var item = itemIndex != -1 ? (widget.title == "Assignees" ? workspaceMember : widget.listAttribute)[itemIndex] : null;

              return item == null ? Container() : Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.title == "Milestone" ? Container(
                      margin: EdgeInsets.only(top: 4),
                      height: 5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        child: LinearProgressIndicator(
                          value: calculateMilestone(item)["percent"]/100,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff27AE60)),
                          backgroundColor: Color(0xffD6D6D6),
                        )
                      )
                    ) : Container(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: widget.title == "Assignees" ? () => goDirectAssignee(item) : null,
                          child: Row(
                            children: [
                              if (widget.title == "Assignees") Container(
                                margin: EdgeInsets.only(right: 8),
                                child: CachedImage(
                                  item["avatar_url"],
                                  height: 24,
                                  width: 24,
                                  radius: 50,
                                  name: item["nickname"] ?? item["full_name"],
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: widget.title == "Milestone" ? 12 : 0),
                                child: Text(
                                  widget.title == "Milestone" ? item["title"] : item["nickname"] ?? item["full_name"], 
                                  style: TextStyle(fontWeight: widget.title != "Milestone" ? FontWeight.w400 : FontWeight.w700, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )
                      ]
                    )
                  ]
                )
              );
            }
          ),
        ) : Container(
          child: widget.selectedAtt.length == 0 ? Text("None yet") : Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Wrap(
              children: labels.map<Widget>((e) {
                var label = e;
                return Container(
                  padding: EdgeInsets.only(top: 4, bottom: 4, right: 4),
                  child: LabelDesktop(labelName: label["name"], color: int.parse("0XFF${label["color_hex"]}"))
                );
              }).toList(),
            )
          )
        ))
      ]
    );
  }
  Widget createOrNewLabel(BuildContext context, label) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    return StatefulBuilder(
      builder: (context, setState) {
        onCreateLabel() {
          final token = Provider.of<Auth>(context, listen: false).token;
          final List dataWS = Provider.of<Workspaces>(context, listen: false).data;
          final List dataCN = Provider.of<Channels>(context, listen: false).data;

          int indexWS = dataWS.indexWhere((ele) => ele['id'] == widget.issue['workspace_id']);
          int indexCN = dataCN.indexWhere((ele) => ele['id'] == widget.issue['channel_id']);

          final currentChannel = indexCN != -1 ? dataCN[indexCN] : Provider.of<Channels>(context, listen: false).currentChannel;
          final currentWorkspace = indexWS != -1 ? dataWS[indexWS] : Provider.of<Workspaces>(context, listen: false).currentWorkspace;

          List labels = currentChannel["labels"];
          if (Utils.checkedTypeEmpty(_titleController.text)) {
            final index = labels.indexWhere((e) => e["name"] == _titleController.text);
            if (index == -1) {
              Map label = {
                "name": _titleController.text,
                "description": _descriptionController.text,
                "color_hex": colors[pickedColor].toString(),
                "issues": 0
              };
              Provider.of<Channels>(context, listen: false).createChannelLabel(token, currentWorkspace["id"], currentChannel["id"], label);
              _titleController.clear();
              _descriptionController.clear();
            }
          }
        }
        onChangedColorPicker(value) {
          int index = colors.indexWhere((ele) => ele == value);
          setState(() => pickedColor = index);
        }
        onChangedlabelName(value) {
          setState(() => _titleController.text);
        }
        return LayoutBuilder(
          builder: (context, contraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 35,
                padding: EdgeInsets.only(left: 14,right: 10),
                decoration: BoxDecoration(
                  color: isDark ? Palette.borderSideColorDark : Palette.backgroundTheardLight,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                  )
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Create new label",style: TextStyle(fontSize: 14),),
                    InkWell(
                      onTap: (() {
                        Navigator.pop(context);
                      }),
                      child: Icon(PhosphorIcons.xCircle,size: 16,)),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: 14, right: 16,top: 15,bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      child: LabelDesktop(
                        labelName: Utils.checkedTypeEmpty(_titleController.text) ? _titleController.text : "Label preview",
                        color: int.parse("0xFF${colors[pickedColor]}"),
                      ),
                    ),
                  ],
                ),
              ),
               Container(
                margin: EdgeInsets.only(left: 14,bottom: 8,top: 5),
                child: Text("Name", style: TextStyle(fontWeight: FontWeight.w500,fontSize: 15))
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: 14,top: 0,bottom: 9,right: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                    color: isDark ? Color(0xff1E1E1E) : Colors.white,
                  ),
                  child: TextFormField(
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w300),
                    controller:  _titleController ,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(8),
                      hintText: label == null ?  "Add name" : "${label["name"]}",
                      hintStyle: TextStyle(color: Color(0xff9AA5B1), fontWeight: FontWeight.w300, fontSize: 14.0),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0), borderSide: BorderSide(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0), borderSide: BorderSide(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))),
                    ),
                    onChanged: (value) {
                      setState(() {onChangedlabelName(value);});
                    }
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 14,bottom: 8, top: 4),
                child: Text("Description", style: TextStyle(fontWeight: FontWeight.w500,fontSize: 15))
              ),
              Container(
                height: 42,
                margin: EdgeInsets.only(left: 14,right: 14),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xff1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(4.0)
                ),
                child: TextFormField(
                  onChanged: (value) {
                    setState(() {});
                  },
                  controller:  _descriptionController ,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w300),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(8),
                    hintText: label == null ? "Description(Opt)" : "${label["description"]}",
                    hintStyle: TextStyle(color: Color(0xff9AA5B1), fontWeight: FontWeight.w300, fontSize: 14.0),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0), borderSide: BorderSide(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0), borderSide: BorderSide(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))),
                  ),
                ),
              ),
               Container(
                margin: EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Text("Color", style: TextStyle(fontWeight: FontWeight.w500,fontSize: 15))
              ),
               Center(
                 child: Container(
                  height: 112,
                  padding: EdgeInsets.only(left: 16,right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GridView.count(
                        shrinkWrap: true,
                        primary: false,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 5,
                        crossAxisCount: 9,
                        children: colors.map((e) => 
                          InkWell(
                            onTap: () {
                              onChangedColorPicker(e);
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
               ),
               SizedBox(height: 8,),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9),
                      width: 1.0,
                    ),
                  )
                ),
              ),
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 15,bottom: 10),
                  child: TextButton(
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        )
                      ),
                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 16.0, horizontal: 30.0)),
                      backgroundColor: MaterialStateProperty.all(Palette.buttonColor)
                    ),
                    onPressed: () { 
                      setState(() {
                        if(label==null){
                          setState(() => _titleController.text);
                          Navigator.pop(context);
                          onCreateLabel();
                        } 
                      });
                    },
                    child:Text( "Create label", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ]
          ),
        );
      }
    );
  }

Widget createOrNewMilestones(BuildContext context, label) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;
  String dateString = DateFormatter().renderTime(dateTime, type: "dd-MM-yyyy");
  return StatefulBuilder(
    builder: (context, setState) {
      return LayoutBuilder(
        builder: (context, contraints) => Column(
          children: [
            Container(
              height: 35,
              padding: EdgeInsets.only(left: 14),
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isDark ? Palette.borderSideColorDark : Palette.backgroundTheardLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                )
              ),
              child: Row(
                children: [
                  Text("Create new Milestones",style: TextStyle(fontSize: 14),),
                ],
              ),
            ),
              Container(
                margin: EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    SizedBox(width: 16,),
                    SizedBox(
                      width: 35.0,
                      child: Text("Title", style: TextStyle(fontWeight: FontWeight.w500))
                    ),
                    SizedBox(width: 5.0,),
                    Expanded(
                      child: Container(
                        height: 40.0,
                        margin: EdgeInsets.only(right: 16),
                        constraints: const BoxConstraints(
                          maxWidth: 800.0
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                          color: isDark ? Color(0xff1F2933) : Colors.white,
                        ),
                        child: TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                            hintText: "Add Title",
                            hintStyle: TextStyle(color: Color(0xff9AA5B1), fontWeight: FontWeight.w300, fontSize: 13.0),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0), borderSide: BorderSide(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0), borderSide: BorderSide(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))),
                          ),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.w300),
                          onChanged: (value) {
                            setState(() {});
                          }
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 10,)
,             Container(
                margin: EdgeInsets.only(top: 14),
                child: Row(
                  children: [
                    SizedBox(width: 16,),
                    SizedBox(
                      width: 110.0,
                      child: Text("Due date (Opt)", style: TextStyle(fontWeight: FontWeight.w500))
                    ),
                    SizedBox(width: 5.0),
                    Expanded(
                      child: Container(
                        height: 40.0,
                        margin: EdgeInsets.only(right: 16),
                        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isDark ? Color(0xff1F2933) : Colors.white,
                          border: Border.all(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))
                        ),
                        child: InkWell(
                          onTap: () async{
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedMilestone != null ? DateTime.parse(selectedMilestone["due_date"]) : DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != dateTime) {
                              if (picked != null) {
                                setState(() {
                                  dateTime = picked;
                                  dateString = DateFormatter().renderTime(dateTime, type: "dd-MM-yyyy");
                                });
                              }
                            }
                          },
                          child: Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  dateString, 
                                  style: TextStyle(color: isDark ? Colors.white.withOpacity(0.85) : Color(0xff1F2933), fontSize: 13.0, fontWeight: FontWeight.w300),
                                ),
                                Icon(Icons.calendar_today_outlined, size: 18.0, color: isDark ? Colors.white.withOpacity(0.85) : Color(0xff1F2933))
                              ],
                            ),
                          )
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 15,),
              Container(
                margin: EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    SizedBox(width: 16,),
                    SizedBox(
                      width: 102.0,
                      child: Text("Description", style: TextStyle(fontWeight: FontWeight.w500))
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: Container(
                        height: 40.0,
                        margin: EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                          color: isDark ? Color(0xff1F2933) : Colors.white,
                        ),
                        child: TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                            hintText: "Add Description",
                            hintStyle: TextStyle(color: Color(0xff9AA5B1), fontWeight: FontWeight.w300, fontSize: 13.0),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0), borderSide: BorderSide(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0), borderSide: BorderSide(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))),
                          ),
                          onChanged: (value) {
                            setState(() {});
                          }
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 25,),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9),
                      width: 1.0,
                    ),
                  )
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 15,bottom: 10),
                height: 40,
                child: SizedBox(
                  width: 140,
                  child: TextButton(
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        )
                      ),
                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 16.0)),
                      backgroundColor: MaterialStateProperty.all(Palette.buttonColor)
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onCreateMilestone();
                    },
                    child: Text("Create milestone", style: TextStyle(color: Colors.white))
                  ),
                ),
              )
            ]
          ),
        );
      }
    );
  }
}

