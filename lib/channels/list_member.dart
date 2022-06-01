import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/components/profile/user_profile_desktop.dart';
import 'package:workcake/models/models.dart';

class ListMember extends StatefulWidget {
  final members;
  final isDelete;
  final type;

  ListMember({Key? key, this.isDelete, this.type, this.members}) : super(key: key);

  @override
  _ListMemberState createState() => _ListMemberState();
}

class _ListMemberState extends State<ListMember> {
  List checkboxs = [];

  onSelect(value, index) {
    List list = checkboxs.toSet().toList();
    if (value) {
      list.add(index);
    } else {
      list.remove(index);
    }
    this.setState(() {
      checkboxs = list;
    });

    Provider.of<Channels>(context, listen: false).onSelectChannelMember(list);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User>(context).currentUser;
    // List channelMember = Provider.of<Channels>(context, listen: true).channelMember;
    List channelMember = widget.members;
    final onlineMembers = channelMember.where((e) => e["is_online"] == true).toList();
    final offlineMembers = channelMember.where((e) => e["is_online"] != true).toList();
    double deviceWidth = MediaQuery.of(context).size.width;
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;

    return SingleChildScrollView(
      child: Container(
        // padding: EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 15),
        child: Column(
          children: [
            onlineMembers.length > 0 ? Container(
              width: deviceWidth,
              padding: EdgeInsets.only(left: 15, top: 10),
              child: Text("Online - ${onlineMembers.length}", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w600))
            ) : Container(),
            Container(
              child: ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                itemCount: onlineMembers.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () async {
                      if (widget.type == "channel") {
                        if (currentUser["id"] != onlineMembers[index]["id"]) {
                          showUserDialog(context, onlineMembers[index]["id"]);
                        }
                      }
                    },
                    leading: Container(
                      width: 48,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          CachedAvatar(onlineMembers[index]["avatar_url"], height: 40, width: 40, isRound: true, name: onlineMembers[index]["full_name"]),
                        ]),
                    ),
                    title: Text('${onlineMembers[index]["full_name"]}'),
                    subtitle: Text("Online", style: TextStyle(fontSize: 12.5)),
                    trailing: Icon(Icons.person_outline, size: 24),
                  );
                },
              )
            ),
            offlineMembers.length > 0 ? Container(
              width: deviceWidth,
              padding: EdgeInsets.only(left: 15, top: 5, bottom: 5),
              child: offlineMembers.length > 0 ? Text("Offline - ${offlineMembers.length}", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w600)) : Container()
            ) : Container(),
            Container(
              child: ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                itemCount: offlineMembers.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () {
                      if (widget.type == "channel") {
                        showUserDialog(context, offlineMembers[index]["id"]);
                      }
                    },
                    leading: Container(
                      width: 48,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          CachedAvatar(offlineMembers[index]["avatar_url"], height: 40, width: 40, isRound: true, name: offlineMembers[index]["full_name"]),
                        ]),
                    ),
                    title: Text('${offlineMembers[index]["full_name"]}'),
                    subtitle: Text("Offline", style: TextStyle(fontSize: 12.5)),
                    trailing: Icon(Icons.person_outline, size: 24),
                  );
                }
              )
            ),
          ],
        ),
      ),
    );
  }
}

showUserDialog(context, id) {
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
