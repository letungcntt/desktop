import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/icon_online.dart';
import 'package:workcake/components/profile/user_profile_desktop.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/models/models.dart';

import 'custom_friend_dialog.dart';

class FriendsDesktop extends StatefulWidget {
  final icon;

  FriendsDesktop({
    this.icon,
  });
  @override
  _FriendsDesktopState createState() => _FriendsDesktopState();
}

class _FriendsDesktopState extends State<FriendsDesktop> {
  TextEditingController controller = TextEditingController();
  bool hoverSendButton = false;

  @override
  void initState() { 
    super.initState(); 
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<dynamic> getInfoFriendTag(String content, String token) async {
    final url = Utils.apiUrl + 'users/get_info_friend_tag?token=$token';
    try {
      var response = await Dio().post(url, data: {
        "content": content
      });
      
      var resData = response.data;
      return resData;
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  void gotoDirectMessage(token) async {
    final result = await getInfoFriendTag(controller.text, token);

    if (result["success"]) {
      final user = result["data"];
      final currentUser = Provider.of<User>(context, listen: false).currentUser;
      final token = Provider.of<Auth>(context, listen: false).token;
      Map newUser = Map.from(user);
      newUser["conversation_id"] = "";
      newUser["user_id"] = newUser["id"];
      Map newCurrentUser = Map.from(currentUser);
      newCurrentUser["conversation_id"] = "";
      newCurrentUser["user_id"] = newCurrentUser["id"];

      List users = [newUser, newCurrentUser];
      DirectModel directMessage = DirectModel(
        "",
        users,
        "",
        true, 0, {}, false, 0, {}, user["full_name"]
      );
      Provider.of<DirectMessage>(context, listen: false).setSelectedDM(directMessage, token);
      await Provider.of<DirectMessage>(context, listen: false).onChangeSelectedFriend(false);
    }
    else {
      showDialog(
        context: context,
        builder: (_) => CustomFriendDialog(
          title: "Create conversation failed",
          string: result["message"],
        )
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final friendList = Provider.of<User>(context, listen: true).friendList;
    final onlineUsers = friendList.where((e) => e["is_online"] == true).toList();
    final pendingUsers = Provider.of<User>(context, listen: true).pendingList;
    final sendingUsers = Provider.of<User>(context,listen: true).sendingList;
    final requestList = [...pendingUsers, ...sendingUsers];
    // final offlineUsers = friendList.where((e) => e["is_online"] == false).toList();
    final isDark  = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final friendTab = Provider.of<Friend>(context).tab; 
    // bool checked = true;
    
    sendFriendRequest() async {
      final usernameTag = controller.text;
      final data = await Provider.of<User>(context,listen: false).sendFriendRequestTag(usernameTag,auth.token);

      showDialog(
        context: context,
        builder: (_) => CustomFriendDialog(
          title: data["success"] ? "FRIEND REQUEST SUCCESS" : "FRIEND REQUEST FAILED",
          string: data["message"],
        )
      );
    }

    sortTimeList(friendList){
      different(time){
        if (time != null) {
          DateTime offlineTime = DateTime.parse(time).add(Duration(hours: 7));
          DateTime now = DateTime.now();
          final difference = now.difference(offlineTime).inMinutes;
          return difference;
        }
        return -1;
      }

      var activeList = friendList.where((element) => element["is_online"] == true).toList();
      var inactiveList = friendList.where((element) => !element["is_online"] == true).toList();

      inactiveList.sort((a,b) => different(a["offline_at"]).compareTo(different(b["offline_at"])));
      return [...activeList, ...inactiveList];
    }

    Widget addFriendTab(){
      
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("ADD FRIEND", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Palette.buttonColor)),
            SizedBox(height: 20,),
            Text("Enter your friend's name with their tag. Ex JohnDoe#1234", style: TextStyle(fontSize: 12)),
            SizedBox(height: 12,),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                border: !isDark ? Border.all(width: 1.0,color: Color(0xffE4E7EB)) : null,
                borderRadius: BorderRadius.all(Radius.circular(8)),
                color: isDark ? Color(0xff1E1E1E) : Colors.white
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Container(
                      child: TextField(
                        focusNode: FocusNode(),
                        controller: controller,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.only(left: 0, bottom: 11, top: 10, right: 15),
                          hintText: "Enter a Username#0000",
                          hintStyle: TextStyle(fontSize: 14.0, color: isDark ? Colors.white24 : Color.fromRGBO(0, 0, 0, 0.30))
                        ),
                      ),
                    ),
                  ),
                  // Expanded(child: Container()),
                  Container(
                    width: 50,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? Palette.selectChannelColor : Colors.blue[200],
                      borderRadius: BorderRadius.circular(3)
                    ),
                    // child: TextButton(
                    //   style: ButtonStyle(
                    //     backgroundColor: MaterialStateProperty.all(controller.text.length > 0 ? Palette.buttonColor : isDark ? Palette.selectChannelColor : Colors.black26),
                    //     shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0))),
                    //     padding: MaterialStateProperty.all(
                    //       EdgeInsets.symmetric(horizontal: 16)
                    //     )
                    //   ),
                    //   child: Text("Send Friend Request",style: TextStyle(fontWeight: FontWeight.w400, fontSize: 12, color: Colors.white)),
                    //   onPressed: () => controller.text.length > 0 ? sendFriendRequest() : null,
                    // ),
                    child: MouseRegion(
                      onEnter: (value) => setState(() => hoverSendButton = true),
                      onExit: (value) => setState(() => hoverSendButton = false),
                      child: TextButton(onPressed: () => controller.text.length > 0 ? sendFriendRequest() : null, child: Icon(Icons.person_add_alt_1_sharp, color: Colors.white)),
                      // child: Row(children: [
                      //   Expanded(child: 
                      //     hoverSendButton ? TextButton(onPressed: () => controller.text.length > 0 ? sendFriendRequest() : null, child: Icon(Icons.person_add_alt_1_sharp, color: Colors.white)) : Center(child: SingleChildScrollView(scrollDirection: Axis.horizontal,child: Row(children: [Text("Send friend request")])))),
                      //   AnimatedContainer(curve: Curves.easeInOut, duration: Duration(milliseconds: 100), decoration: BoxDecoration(color: isDark ? Colors.grey : Colors.grey[100]), width: !hoverSendButton ? 0 : 75, 
                      //     child: Center(child: SingleChildScrollView(scrollDirection: Axis.horizontal, 
                      //       // child: Row(children: [TextButton(onPressed:() => controller.text.length > 0 ? gotoDirectMessage(auth.token) : null, child: Icon(Icons.message, color: Colors.white))])
                      //     ))
                      //   )
                      // ])
                    )
                  )
                ],
              ),
            ),
            SizedBox(height: 25,),
            Text("Outgoing Friend Request", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            SizedBox(height: 10,),
            ListFriends(friendList: sendingUsers, auth: auth, widget: widget, isRequest: true),
            SizedBox(height: 25,),
            Row(
              children: [
                Text("Incoming Friend Request", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                SizedBox(width: 10),
                if (pendingUsers.length > 0) Container(
                  margin: EdgeInsets.only(right: 2),
                  padding: EdgeInsets.only(left: 9, right: 9),
                  height: 18,
                  decoration: BoxDecoration(
                    color: Palette.errorColor,
                    borderRadius: BorderRadius.circular(18)
                  ),
                  child: Center(
                    child: Text(
                      pendingUsers.length.toString(),
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                )
              ],
            ),
            SizedBox(height: 10,),
            ListFriends(friendList: pendingUsers, auth: auth, widget: widget, isRequest: true),
          ],
        ),
      )
      ; 
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        children: [
          friendTab == "Online" ? onlineUsers.length > 0 ? Row(children: [Text("ONLINE - ${onlineUsers.length}", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5, color: isDark ? Colors.white70 : Color(0xff627D98)))]) : Container() : 
          friendTab == "All" ? Row(children: [Text("ALL FRIENDS - ${friendList.length}",style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5, color: isDark ? Colors.white70 : Color(0xff627D98)))],) : 
          friendTab == "Pending" ? Row(children: [Text("PENDING - ${requestList.length}",style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5, color: isDark ? Colors.white70 : Color(0xff627D98)))],) : 
          friendTab == "Blocked" ? Row(children: [Text("BLOCKED - 0",style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5, color: isDark ? Colors.white70 : Color(0xff627D98)))],) : 
          Container(),
          SizedBox(height: 10,),
          friendTab == "Online" ? ListFriends(friendList: onlineUsers, auth: auth, widget: widget,isRequest: false, ) : 
          friendTab == "All" ? ListFriends(friendList: sortTimeList(friendList), auth: auth, widget: widget, isRequest: false,) : 
          friendTab == "Pending" ? ListFriends(friendList: requestList, auth: auth, widget: widget, isRequest: true) :
          friendTab == "Blocked" ? ListFriends(friendList: [], auth: auth, widget: widget,isRequest: false,) : 
          addFriendTab()
        ],
      ),
    );
  }
}

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
    final token = Provider.of<Auth>(context, listen: false).token;
    Map newUser = Map.from(user);
    newUser["conversation_id"] = "";
    newUser["user_id"] = newUser["id"];
    Map newCurrentUser = Map.from(currentUser);
    newCurrentUser["conversation_id"] = "";
    newCurrentUser["user_id"] = newCurrentUser["id"];

    List users = [newUser, newCurrentUser];
    DirectModel directMessage = DirectModel(
      "",
      users,
      "",
      true, 0, {}, false, 0, {}, ""
    );
    Provider.of<DirectMessage>(context, listen: false).setSelectedDM(directMessage, token);
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
                  child: HoverItem(
                    colorHover: isDark ? Color(0xff4C4C4C) : Color(0xffEDEDED),
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
                            padding: EdgeInsets.symmetric(vertical: 13),
                          
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            await onShowUserInfo(context, widget.friendList[index]["id"]);
                                          },
                                          child: Container(
                                            constraints: BoxConstraints(
                                              // maxWidth: MediaQuery.of(context).size.width - resSidebarWidth - 330
                                            ),
                                            child: Text(widget.friendList[index]["full_name"], style: TextStyle( fontSize: 15, ))
                                          )
                                        ),
                                      ],
                                    ),
                                    widget.isRequest ? Container() : SizedBox(height: 5),
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
                                           PhosphorIcons.checkCircle ,
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
                                            "", 
                                            false, 
                                            0, 
                                            {}, 
                                            false,
                                            0,
                                            {},
                                            ""
                                          ), "");
                                        },
                                        child: widget.isRequest ? Container(
                                          margin: EdgeInsets.only(right: 15),
                                          child: Icon(
                                             PhosphorIcons.xCircle,
                                            size: 18,
                                            color: isDark ? Color(0xffAA4141) : Color(0xffAA4141)
                                          ),
                                        ):SizedBox(),
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
