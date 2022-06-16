import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/models/models.dart';
import 'package:workcake/workview_desktop/issue_table.dart';

class ListUser extends StatefulWidget {
  ListUser({
    Key? key,
    required this.assignees,
    required this.selectAssignee,
  }) : super(key: key);

  final List assignees;
  final Function selectAssignee;

  @override
  _ListUserState createState() => _ListUserState();
}

class _ListUserState extends State<ListUser> {
  bool isHover = false;
  Map? userHover;

  checkUnreadThread() {
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];
    final dataThreads = Provider.of<Threads>(context, listen: false).dataThreads;
    final index = dataThreads.indexWhere((e) => e["workspaceId"] == workspaceId);
    num count = 0;
    bool unread = false;

    if (index != -1) {
      final threadsWorkspace = dataThreads[index]["threads"];

      for (var i = 0; i < threadsWorkspace.length; i++) {
        count += (threadsWorkspace[i]["mention_count"]) ?? 0;

        if (threadsWorkspace[i]["unread"] ?? false) {
          unread = true;
        }
      }
    }

    return {
      "unread": unread,
      "count": count
    };
  }

  void onHover(bool value, Map? data) {
    setState(() {
      isHover = value;
      userHover = data;
    });
  }

  

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final assignees = widget.assignees;

    return PortalEntry(
      visible: isHover,
      portalAnchor: Alignment.bottomCenter,
      childAnchor: Alignment.topCenter,
      portal: userHover != null ? Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Color(0xff1E1E1E),
          borderRadius: BorderRadius.all(Radius.circular(4))
        ),
        child: Text(userHover!["full_name"], style: TextStyle(color: Palette.defaultTextDark)),
      ) : Container(),
      child: Container(
        width: 100,
        height: 36,
        child: Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [
            assignees.length <= 5 ? Container() :
            Positioned(
              right: 0 + (isHover && userHover == null ? -6 : 0),
              child: InkWell(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white60,
                  ),
                  padding: EdgeInsets.all(1),
                  width: 34,
                  height: 34,
                  child: Container(
                    decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Color(0xff52606D) : Color(0xffE4E7EB),
                  ),
                    padding: EdgeInsets.symmetric(vertical: 7, horizontal: assignees.length > 9 ? 2 : 6),
                    width: 32,
                    height: 32,
                    child: Text("+${assignees.length - 5}", style: TextStyle(color: isDark ? Colors.white70: Color.fromRGBO(0, 0, 0, 0.65), fontSize: 14, fontWeight: FontWeight.w400))
                  )
                ),
              )
            ),
            assignees.length <= 4 ? Container() : 
            Positioned(
              right: 12.5 + (isHover && userHover != null && userHover!['id'] == assignees[4]["id"] ? -6 : 0),
              child: AssigneeAvatar(
                userId: assignees[4]["id"],
                url: assignees[4]["avatar_url"], 
                name: assignees[4]["full_name"], 
                selectAssignee: widget.selectAssignee,
                onHover: onHover,
              )
            ),
            assignees.length <= 3 ? Container() : 
            Positioned(
              right: 25 + (isHover && userHover != null && userHover!['id'] == assignees[3]["id"] ? -6 : 0),
              child: AssigneeAvatar(
                userId: assignees[3]["id"],
                url: assignees[3]["avatar_url"], 
                name: assignees[3]["full_name"], 
                selectAssignee: widget.selectAssignee,
                onHover: onHover,
              )
            ),
            assignees.length <= 2 ? Container() : 
            Positioned(
              right: 37.5 + (isHover && userHover != null && userHover!['id'] == assignees[2]["id"] ? -6 : 0),
              child: AssigneeAvatar(
                userId: assignees[2]["id"],
                url: assignees[2]["avatar_url"], 
                name: assignees[2]["full_name"], 
                selectAssignee: widget.selectAssignee,
                onHover: onHover,
              )
            ),
            assignees.length <= 1 ? Container() : 
            Positioned(
              right: 50 + (isHover && userHover != null && userHover!['id'] == assignees[1]["id"] ? -6 : 0),
              child: AssigneeAvatar(
                userId: assignees[1]["id"],
                url: assignees[1]["avatar_url"], 
                name: assignees[1]["full_name"], 
                selectAssignee: widget.selectAssignee,
                onHover: onHover,
              ),
            ),
            assignees.length == 0 ? Container() :
            AssigneeAvatar(
              userId: assignees[0]["id"],
              url: assignees[0]["avatar_url"], 
              name: assignees[0]["full_name"], 
              selectAssignee: widget.selectAssignee,
              onHover: onHover,
            ),
          ]
        ),
      ),
    );
  }
}