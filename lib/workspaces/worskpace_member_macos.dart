import 'package:flutter/material.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/components/profile/user_profile_desktop.dart';
import 'package:workcake/providers/providers.dart';

class WorkspaceMemberMacOS extends StatefulWidget {
  final onlineMember;
  final offlineMember;

  WorkspaceMemberMacOS({
    Key? key,
    this.onlineMember,
    this.offlineMember
  }) : super(key: key);

  @override
  _WorkspaceMemberMacOSState createState() => _WorkspaceMemberMacOSState();
}

class _WorkspaceMemberMacOSState extends State<WorkspaceMemberMacOS> {

  parseDatetime(time) {
    if (time != "") {
      DateTime offlineTime = DateTime.parse(time).add(Duration(hours: 7));
      DateTime now = DateTime.now();
      final difference = now.difference(offlineTime).inMinutes;

      final hour = difference ~/ 60;
      final minutes = difference % 60;
      final day = hour ~/24;
      final hourLeft = hour % 24 + 1;

      if (day > 0) {
        return 'Active ${day.toString().padLeft(2, "")} ${day > 1 ? "days" : "day"} and ${hourLeft.toString().padLeft(2, "")} ${hourLeft > 1 ? "hours" : "hour"} hours ago';
      } else if (hour > 0) {
        return 'Active ${hour.toString().padLeft(2, "")} ${hour > 1 ? "hours" : "hour"} ago';
      } else {
        if (minutes <= 1) return "a moment ago";
        else return 'Active ${minutes.toString().padLeft(2, "0")} minutes ago';
      }
    } else {
      return "Offline";
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;

    return  Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Scrollbar(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget> [
              widget.onlineMember.length == 0 ? Container () : Container(
                child: Text(
                  "Online - ${widget.onlineMember.length}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[700]
                  )
                ),
              ),
              Container(
                child: _renderMembers(widget.onlineMember),
              ),
              widget.offlineMember.length == 0 ? Container () : Container(
                child: Text(
                  "Offline - ${widget.offlineMember.length}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[700]
                  )
                ),
              ),
              Container(
                child: _renderMembers(widget.offlineMember),
              ),
            ]
          ),
        )
      ),
    );
  }

  Widget _renderMembers(dataMembers) {
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(0),
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      itemCount: dataMembers.length,
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: EdgeInsets.all(0),
          onTap: () {
            onShowUserInfo(context, dataMembers[index]["user_id"] ?? dataMembers[index]["id"]);
          },
          leading: Stack(children: [
            Container(
              margin: EdgeInsets.only(top: 5),
              padding: EdgeInsets.all(3),
              height: 42, width: 42,
              child: CachedAvatar(dataMembers[index]["avatar_url"], height: 34, width: 34, radius: 4, name: dataMembers[index]["full_name"], isAvatar: true)),
            Positioned(
              right: 0,
              bottom: 2,
              child: Container(
                width: 10, height: 10,
                decoration: BoxDecoration( borderRadius: BorderRadius.all(Radius.circular(10)), color: dataMembers[index]["is_online"] ? Color(0xff73d13d) : Color(0xffd4d7dc))
              ),
            ),
          ]),
          title: Text(
            '${dataMembers[index]["full_name"]}',
            style: TextStyle(fontSize: 13)
          ),
          subtitle: Text(
            dataMembers[index]["is_online"] == true ? "Active" : dataMembers[index]["offline_at"] != null ? parseDatetime(dataMembers[index]["offline_at"]) : "Offline",
            style: TextStyle(fontSize: 11, color: Color(0xff6a6e74), height: 1.6),
          ),
        );
      },
    );
  }


  onShowUserInfo(context, id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
          insetPadding: EdgeInsets.all(0),
          contentPadding: EdgeInsets.all(0),
          content: UserProfileDesktop(userId: id),
        );
      }
    );
  }
}
