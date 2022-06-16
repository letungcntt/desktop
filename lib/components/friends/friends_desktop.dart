import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/icon_online.dart';
import 'package:workcake/components/message_item/attachments/text_file.dart';
import 'package:workcake/components/profile/user_profile_desktop.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/models/models.dart';
class ListFriends extends StatefulWidget{
  final friendList;
  final auth;
  final widget;
  final isRequest;

  const ListFriends({
    Key? key,
    @required this.friendList,
    @required this.auth,
    @required this.widget,
    this.isRequest
  }) : super(key: key);
  @override
  _ListFriendsState createState() {
    return _ListFriendsState();
  }
}
class _ListFriendsState extends State<ListFriends> {
  String itemHover = "";
  bool rebuild = false;

goDirectMessage(user) {
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

  parseDatetime(time) {
    if (time != "") {
      DateTime offlineTime = DateTime.parse(time).add(Duration(hours: 7));
      DateTime now = DateTime.now();
      final difference = now.difference(offlineTime).inMinutes;
      final hour = difference ~/ 60;
      final minutes = difference % 60;
      final day = hour ~/24;
      // final hourLeft = hour % 24 + 1;
      
      if (day > 0) {
        return 'Active ${day.toString().padLeft(2, "")} ${day > 1 ? "days" : "day"} ago';
      } else if (hour > 0) {
        return 'Active ${hour.toString().padLeft(2, "")} ${hour > 1 ? "hours" : "hour"} ago';
      } else {
        if (minutes <= 1) return "moment ago";
        else return 'Active ${minutes.toString().padLeft(2, "0")} minutes ago';
      }
    } else {
      return "Offline";
    }
  }

  onChangeIsHover(String value) {
    setState(() {
      itemHover = value;
      rebuild = false;
    });

    Future.delayed(Duration.zero, () {
      if(this.mounted) {
        setState(() => rebuild = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Flexible(
      child: Container(
        child: ListView.builder(
          // physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: widget.friendList.length,
          controller: ScrollController(),
          itemBuilder: (context, index) {
            Map app = widget.friendList[index];
            return Container(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: InkWell(
                onTap: () async {
                  goDirectMessage(widget.friendList[index]);
                  await Provider.of<DirectMessage>(context, listen: false).onChangeSelectedFriend(false);
                },
                hoverColor: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Palette.defaultTextLight : Palette.defaultTextDark,
                    borderRadius: BorderRadius.circular(4)
                  ),
                  margin: EdgeInsets.all(0),
                  child: ListAction(
                    action: "",
                    isDark: isDark,
                    child: HoverItem(
                      onHover: () => onChangeIsHover(app["id"] ),
                      onExit: () => onChangeIsHover(""),
                      child: Row(
                        children: <Widget>[
                          Container(
                            constraints: BoxConstraints(maxHeight: 65, maxWidth: 65),
                            child: Stack(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.only(right: 5,left: 15),
                                  child: GestureDetector(
                                    onTap: () async {
                                      await onShowUserInfo(context, widget.friendList[index]["id"]);
                                    },
                                    child: CachedImage(
                                      widget.friendList[index]["avatar_url"],
                                      radius: 35,
                                      isRound: true,
                                      name: widget.friendList[index]["full_name"],
                                      isAvatar: true,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 4, bottom: -13,
                                  child: !widget.isRequest && widget.friendList[index]["is_online"] ? IconOnline() : Container()
                                )
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(left: 4),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      GestureDetector(
                                        onTap: () async {
                                          await onShowUserInfo(context, widget.friendList[index]["id"]);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 3),
                                          child: Text(widget.friendList[index]["full_name"], style: TextStyle( fontSize: 15, )),
                                        )
                                      ),
                                      widget.friendList[index]["is_online"] != true ? SizedBox(height: 2) : SizedBox(height: 4),
                                      Row(
                                        children: <Widget>[
                                          widget.friendList[index]["is_online"] != true ? Container(
                                          child: Text(
                                            widget.friendList[index]["offline_at"] != null ? parseDatetime(widget.friendList[index]["offline_at"]) : "" ,
                                            style: TextStyle(fontSize: 11,  color: isDark ? Color(0xffF0F4F8) : Color(0xff627D98)),
                                            overflow: TextOverflow.ellipsis,
                                           ),
                                          ) :SizedBox()
                                        ],
                                      )
                                    ],
                                  ),
                                  (itemHover == app["id"] ) ? 
                                  Container(
                                    margin: EdgeInsets.only(right: 2),
                                    child: Row(
                                      children: [
                                        widget.isRequest && !widget.friendList[index]["is_pending"] 
                                        ? Container()
                                        :widget.isRequest ? GestureDetector(
                                          onTap: () async {
                                            if(widget.isRequest) await Provider.of<User>(context,listen: false).acceptRequest(widget.auth.token, widget.friendList[index]["id"]);
                                          },
                                          child: Icon(
                                            widget.isRequest ? PhosphorIcons.checkCircle : Icons.phone_in_talk ,
                                            size: 18,
                                            color: isDark ? Color(0xff78A5FD) : Color(0xff2A5298)
                                          ),
                                        ):SizedBox(),
                                        SizedBox(width: 4,),
                                        GestureDetector(
                                          onTap: widget.isRequest 
                                          ? () async {
                                            await Provider.of<User>(context,listen: false).removeRequest(widget.auth.token, widget.friendList[index]["id"]);
                                          } 
                                          : ()  {  
                                            var user =  widget.friendList[index];
                                            var currentUser = Provider.of<User>(context, listen: false).currentUser;
                                            Provider.of<Workspaces>(context, listen: false).tab = 0;
                                            Provider.of<DirectMessage>(context, listen: false).setSelectedDM(DirectModel(
                                              "", 
                                              [
                                                {"user_id": currentUser["id"],"full_name": currentUser["full_name"], "avatar_url": currentUser["avatar_url"]}, 
                                                {"user_id": user["id"], "avatar_url": user["avatar_url"],  "full_name": user["full_name"],}
                                              ], 
                                              "", false, 0, {}, false, 0, {}, "", null
                                            ), "");
                                          },
                                          child:  Container(
                                            margin: EdgeInsets.only(right: 15),
                                            child: Icon(
                                              widget.isRequest ? PhosphorIcons.xCircle : Icons.message,
                                              size: 18,
                                              color: widget.isRequest ? isDark ? Color(0xffAA4141) : Color(0xffAA4141) : isDark ? Color(0xffFAAD14) : Utils.getPrimaryColor()
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ):SizedBox()
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }
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
