import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/utils.dart';
import 'package:http/http.dart' as http;
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/providers/providers.dart';

import '../message_item/attachments/text_file.dart';


class FriendList extends StatefulWidget {
  final type;

  FriendList({
    key,
    this.type
  }) : super(key: key);

  @override
  _FriendListState createState() => _FriendListState();
}

class _FriendListState extends State<FriendList> {
  final _controller = ScrollController();
  List friendList = [];
  String token = "";
  Map currentWorkspace = {};
  Map currentChannel = {};
  bool doneChecking = false;

  checkInvite(userId, workspaceId, channelId) async{
    bool check = false;
    var url;
    var resData;
    if (widget.type == "toWorkspace"){
      url = Utils.apiUrl + "/workspaces/$workspaceId/get_invite?token=$token";
      final response = await http.post(Uri.parse(url),headers: Utils.headers,
        body: json.encode({"user_id": userId})
      );
      resData = json.decode(response.body);
      doneChecking = true;
    }
    else{
      url = Utils.apiUrl + "/workspaces/$workspaceId/channels/$channelId/get_invite?token=$token";
      final response = await http.post(Uri.parse(url), headers: Utils.headers,
        body: json.encode({"user_id": userId})
      );
      resData = json.decode(response.body);
      doneChecking = true;
    }

    if (resData["success"] == true){
      check = resData["is_invited"];
    }
    return check ? "Invited" : "Invite";
  }

  @override
  void initState() {
    super.initState();

    this.setState(() {
      friendList = Provider.of<User>(context, listen: false).friendList;
      token = Provider.of<Auth>(context, listen: false).token;
      currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;

    });

    final workspaceMembers = Provider.of<Workspaces>(context, listen: false).members;

    List list = widget.type == 'toWorkspace' ? friendList : workspaceMembers;
    friendList = list;


    friendList.map((e) {
      int index = friendList.indexWhere((element) => element == e);
      var a = e;
      checkInvite(friendList[index]["id"], currentWorkspace["id"], currentChannel["id"]).then((ele) {
        if (this.mounted) setState(() {
          a["invite"] = ele;
        });
      });
      return a;
    }).toList();
  }

  _invite(token, workspaceId, channelId , user) {
    String email = user["email"] ?? "";
    if (widget.type == 'toWorkspace') {
      Provider.of<Workspaces>(context, listen: false).inviteToWorkspace(token, currentWorkspace["id"], email, 1, user["id"]);
    } else {
      if (currentChannel["is_private"]) {
        Provider.of<Channels>(context, listen: false).inviteToChannel(token, currentWorkspace["id"], currentChannel["id"], email, 1, user["id"]);
      } else {
        Provider.of<Channels>(context, listen: false).inviteToPubChannel(token, currentWorkspace["id"], currentChannel["id"], user["id"]);
      }
    }
  }

  validate(id) {
    final workspaceMembers = Provider.of<Workspaces>(context, listen: true).members;
    final channelMember = Provider.of<Channels>(context, listen: true).channelMember;
    bool check = true;
    List list = widget.type == 'toWorkspace' ? workspaceMembers : channelMember;

    for (var member in list) {
      if (id == member["id"]) {
        check = false;
      }
    }
    return check;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double deviceHeight = MediaQuery.of(context).size.height;
    final currentChannel = Provider.of<Channels>(context, listen: true).currentChannel;
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;

    return Container(
      height: deviceHeight - deviceHeight*.15 - 220,
      child: friendList.length == 0 ? Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: Column(
            children: [
              isDark ? SvgPicture.asset('assets/icons/contactDark.svg') : SvgPicture.asset('assets/icons/contactLight.svg'),
              SizedBox(height: 16,),
              Text(S.current.noFriendToAdd, style: TextStyle(color: isDark ? Colors.white : Colors.black.withOpacity(0.85), fontSize: 14, fontWeight: FontWeight.w600)),
              SizedBox(height: 8,),
              Text(S.current.addFriendUsingEmail, style: TextStyle(color: isDark ? Color(0xffF5F7FA) : Colors.black.withOpacity(0.85), fontSize: 12)),
            ],
          ),
        )
      ) : Container(
        padding: EdgeInsets.symmetric(vertical: 0),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color:isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9),
              width: 0.5,
            ),
            bottom: BorderSide(
              color:isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9),
              width: 0.5,
            ),
          ),
        ),
        child: ListView.builder(
          controller: _controller,
          scrollDirection: Axis.vertical,
          itemCount: friendList.length,
          itemBuilder: (context, index) {
            return ListAction(
              isDark: isDark,
              action: "",
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1.0,
                    color:isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9),
                  ),
                ),
                child: ListTile(
                  leading: CachedAvatar(
                    friendList[index]["avatar_url"],
                    height: 32, width: 32,
                    isRound: true,
                    name: friendList[index]["full_name"],
                  ),
                  title: Text("${Utils.getUserNickName(friendList[index]["id"]) ?? friendList[index]["full_name"]}", 
                    style: TextStyle(fontSize: 14.0, fontFamily: "Roboto")),
                  trailing: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                    ),
                    height: 28,
                    width: 90,
                    child: validate(friendList[index]["id"]) == false ?
                    Center(
                      child: Text( S.current.acceptInvite , 
                        style: TextStyle(fontSize: 13, color: Colors.grey)
                       )
                      )
                    : friendList[index]["invite_${currentWorkspace["id"]}_${widget.type == "toChannel"  ? currentChannel["id"] : ""}"] == null 
                    ? InkWell(
                      child: Center(
                        child: Text(currentChannel["is_private"] ? S.current.invite : S.current.invite,
                          style: TextStyle(fontSize: 13, color: isDark ? Color(0xffEAE8E8) : Color(0xff5E5E5E))
                          )
                        ),
                        onTap: () {
                          _invite(auth.token, currentWorkspace["id"], currentChannel["id"], friendList[index]);
                          this.setState(() {
                          friendList[index]["invite_${currentWorkspace["id"]}_${widget.type == "toChannel"  ? currentChannel["id"] : ""}"] = true;
                         });
                        }
                     ): Center(
                      child: Text(
                        S.current.invited, style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ),
                  )
                ),
              ),
            );
          }
        ),
      )
    );
  }
}