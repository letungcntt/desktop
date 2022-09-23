import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/components/custom_confirm_dialog.dart';
import 'package:workcake/components/profile/user_profile_desktop.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/providers/providers.dart';

import '../../generated/l10n.dart';
class ListFriends extends StatefulWidget{
  final friendList;
  final auth;
  final widget;
  final isRequest;
  final bool isNewFriend;
  final bool isSend;

  const ListFriends({
    Key? key,
    required this.friendList,
    required this.auth,
    required this.widget,
    this.isRequest,
    this.isNewFriend = false,
    this.isSend = false
  }) : super(key: key);
  @override
  _ListFriendsState createState() {
    return _ListFriendsState();
  }
}
class _ListFriendsState extends State<ListFriends> {
  String itemHover = "";
  bool rebuild = false;
  bool isHoverMessenger = false;
  bool isHoverDelete = false ;

  goDirectMessage(user) {
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    Provider.of<DirectMessage>(context, listen: false).onChangeSelectedFriend(false);
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
              child: InkWell(
                onTap: widget.isNewFriend ? null : () => goDirectMessage(widget.friendList[index]),
                hoverColor: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Palette.defaultTextLight : Palette.defaultTextDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  margin: EdgeInsets.all(0),
                  child: HoverItem(
                    colorHover: isDark ? Color(0xff3D3D3D) : Color(0xffFFFFFF),
                    onHover: () => onChangeIsHover(app["id"] ),
                    onExit: () => onChangeIsHover(""),
                    child: Container(
                      // margin: EdgeInsets.symmetric(horizontal: 12),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: !widget.isRequest ? null : BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 1, color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight,
                          )
                        )
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: <Widget>[
                              Container(
                                constraints: BoxConstraints(maxHeight: 65, maxWidth: 65),
                                child: Stack(
                                  children: <Widget>[
                                    Container(
                                      child: GestureDetector(
                                        onTap: () async {
                                          await onShowUserInfo(context, widget.friendList[index]["id"]);
                                        },
                                        child: CachedImage(
                                          widget.friendList[index]["avatar_url"],
                                          radius: 30,
                                          isRound: true,
                                          name: widget.friendList[index]["full_name"],
                                          isAvatar: true,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 18, left: 18,
                                      child: Container(
                                        height: 14, width: 14,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(7),
                                          color: !widget.isRequest && widget.friendList[index]["is_online"]
                                            ? isDark ? Color(0xff2e2e2e) : Color(0xFFF3F3F3)
                                            : Colors.transparent
                                        ),
                                      )
                                    ),
                                    Positioned(
                                      top: 20, left: 20,
                                      child: Container(
                                        height: 10, width: 10,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        padding: EdgeInsets.all(1),
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(4),
                                            color: !widget.isRequest && widget.friendList[index]["is_online"]
                                              ? Color(0xff73d13d)
                                              : Colors.transparent,
                                          ),
                                        ),
                                      )
                                    )
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 60,
                                  margin: EdgeInsets.only(left: 8),
                                  padding: EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          GestureDetector(
                                            onTap: () => onShowUserInfo(context, widget.friendList[index]["id"]),
                                            child: Padding(
                                              padding: widget.friendList[index]["is_online"] != true ? EdgeInsets.only(top: 6) : EdgeInsets.only(top: 16),
                                              child: Text(widget.friendList[index]["full_name"], style: TextStyle( fontSize: 15, )),
                                            )
                                          ),
                                          widget.friendList[index]["is_online"] != true ? SizedBox(height: 4) : SizedBox(height: 4),
                                          Row(
                                            children: <Widget>[
                                              widget.friendList[index]["is_online"] != true ? Container(
                                              child: Text(
                                                widget.friendList[index]["offline_at"] != null ? parseDatetime(widget.friendList[index]["offline_at"]) : "" ,
                                                style: TextStyle(fontSize: 11,  color: isDark ? Color(0xffF0F4F8) : Color(0xff627D98)),
                                                overflow: TextOverflow.ellipsis,
                                               ),
                                              ) : SizedBox()
                                            ],
                                          ),
                                        ],
                                      ),
                                     widget.isRequest ? Container(height: 10,) : (itemHover == app["id"] ) ?
                                      Container(
                                        margin: EdgeInsets.only(left: 24),
                                        child: Row(
                                          children: [
                                            Row(
                                              children: [
                                                widget.isRequest && !widget.friendList[index]["is_pending"]
                                                ? Container()
                                                : widget.isRequest ? GestureDetector(
                                                  onTap: () async {
                                                    if(widget.isRequest) await Provider.of<User>(context,listen: false).acceptRequest(widget.auth.token, widget.friendList[index]["id"]);
                                                  },
                                                  child: Icon(
                                                    widget.isRequest ? PhosphorIcons.checkCircle : Icons.phone_in_talk ,
                                                    size: 23,
                                                    color: isDark ? Color(0xff78A5FD) : Color(0xff2A5298)
                                                  ),
                                                ) : SizedBox(),
                                                SizedBox(width: 4,),
                                                InkWell(
                                                  onHover: (hover){
                                                      setState(() {
                                                        isHoverMessenger = hover;
                                                      });
                                                    },
                                                  onTap: () async {
                                                    var user =  widget.friendList[index];
                                                    var currentUser = Provider.of<User>(context, listen: false).currentUser;
                                                    Provider.of<Workspaces>(context, listen: false).tab = 0;
                                                    await Provider.of<DirectMessage>(context, listen: false).getInfoDirectMessage(Provider.of<Auth>(context,listen: false).token, MessageConversationServices.shaString([user["id"], currentUser["id"]]));
                                                    Provider.of<DirectMessage>(context, listen: false).setSelectedDM(DirectModel(
                                                      "",
                                                      [
                                                        {"user_id": currentUser["id"],"full_name": currentUser["full_name"], "avatar_url": currentUser["avatar_url"]},
                                                        {"user_id": user["id"], "avatar_url": user["avatar_url"],  "full_name": user["full_name"],}
                                                      ],
                                                      "", false, 0, {}, false, 0, {}, "", null
                                                    ), "");
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: isDark ? Color(0xff4C4C4C) : Color(0xffEDEDED),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(
                                                        width: 1,
                                                        color: isDark ? isHoverMessenger ? Color(0xffFAAD14) : Color(0xff4C4C4C) : isHoverMessenger ? Color(0xff1890FF) : Color(0xffEDEDED),
                                                      ),
                                                    ),
                                                    padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
                                                    margin: EdgeInsets.only(right: 12),
                                                    child: Icon(
                                                      PhosphorIcons.chatCircleDots,
                                                      size: 18,
                                                      color: isDark ? isHoverMessenger ? Color(0xffFAAD14) : Color(0xffDBDBDB) : isHoverMessenger ? Color(0xff1890FF) : Color(0xff3D3D3D),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                            if(!widget.isRequest) InkWell(
                                              onHover: (hover){
                                                setState(() {
                                                  isHoverDelete = hover;
                                                });
                                              },
                                              onTap: () {
                                                showModal(
                                                  context: context,
                                                  builder: (context) {
                                                    return CustomConfirmDialog(
                                                      subtitle: 'Do you want to delete this friend ?',
                                                      title: 'Delete friend',
                                                      onConfirm: () {
                                                        Provider.of<User>(context,listen: false).removeRequest(widget.auth.token, widget.friendList[index]["id"]);
                                                      },
                                                      onCancel: null,
                                                    );
                                                  }
                                                );
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: isDark ? Color(0xff4C4C4C) : Color(0xffEDEDED),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(
                                                    width: 1,
                                                    color:  isHoverDelete ? Palette.errorColor : isDark ? Color(0xff3D3D3D) : Color(0xffEDEDED),
                                                  ),
                                                ),
                                                margin: EdgeInsets.only(right: 4),
                                                padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
                                                child: HoverItem(
                                                  child: Icon(
                                                    PhosphorIcons.xCircle,
                                                    size: 18,
                                                    color:  isHoverDelete ? Palette.errorColor : isDark ? Color(0xffDBDBDB) : Color(0xff3D3D3D), 
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ) : SizedBox(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          widget.isRequest && !widget.isSend ? Container(
                            margin: const EdgeInsets.only(bottom: 16, left: 32),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: !widget.isRequest ? null : () => Provider.of<User>(context,listen: false).acceptRequest(widget.auth.token, widget.friendList[index]["id"]),
                                  child: Container(
                                    height: 30, width: 126,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Palette.dayBlue, borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      S.current.accept,
                                      style: TextStyle(color: Palette.defaultTextDark),
                                    )
                                  ),
                                ),
                                SizedBox(width: 10,),
                                InkWell(
                                  onTap: () =>Provider.of<User>(context,listen: false).removeRequest(widget.auth.token, widget.friendList[index]["id"]),
                                  child: Container(
                                    height: 30, width: 126,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border.all(width: 1, color: Palette.errorColor),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(S.current.delete , style: TextStyle(color: Palette.errorColor),)
                                  ),
                                ),
                              ],
                            ),
                          ) : SizedBox(),
                          widget.isSend ? InkWell(
                            onTap: () =>Provider.of<User>(context,listen: false).removeRequest(widget.auth.token, widget.friendList[index]["id"]),
                            child: Container(
                              height: 30,
                              alignment: Alignment.center,
                              margin: EdgeInsets.only(bottom: 14, left: 40, right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(width: 1, color: Palette.errorColor),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(S.current.delete , style: TextStyle(color: Palette.errorColor),)
                            ),
                          ) : Container()
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
  showModal(
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
