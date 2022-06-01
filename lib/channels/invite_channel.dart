import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_search_bar.dart';
import 'package:workcake/components/friends/friend_list.dart';
import 'package:workcake/models/models.dart';

class InviteChannel extends StatefulWidget {
  InviteChannel({Key? key}) : super(key: key);

  @override
  _InviteChannelState createState() => _InviteChannelState();
}

class _InviteChannelState extends State<InviteChannel> {
  final _controller = ScrollController();
  List members = [];

  @override
  void initState() {
    _controller.addListener(_scrollListener);
    super.initState();
  }

  _scrollListener() {
    FocusScope.of(context).unfocus();
  }


  searchMemberToInvite(token, workspaceId, channelId, text) async {
    final url = Utils.apiUrl + 'workspaces/$workspaceId/get_workspace_member?value=$text&token=$token';

    try {
      var response = await Dio().get(url);
      var dataRes = response.data;

      if (dataRes["success"]) {
        setState(() {
          members = dataRes["members"];
        });
      } else {
        setState(() {
          members = [];
        });
      }
    } catch (e) {
      print(e.toString());
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  onInviteToChannel(token, workspaceId, channelId, value) async {
    if (value != "") {
      searchMemberToInvite(token, workspaceId, channelId, value);
    } else {
      setState(() {
        members = [];
      });
    }
  }

  _invite(token, workspaceId, channelId , user) {
    String email = user["email"];
    Provider.of<Channels>(context, listen: false).inviteToChannel(token, workspaceId, channelId, email, 1, user["id"]);
  }

  @override
  Widget build(BuildContext context) {
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final channelMember = Provider.of<Channels>(context, listen: true).channelMember;
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;

    validate(id) {
      bool check = true;
      for (var member in channelMember) {
        if (id == member["id"]) {
          check = false;
        }
      }
      return check;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF353a3e) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10.0),
          topRight: Radius.circular(10.0)
        )
      ),
      padding: EdgeInsets.only(top: 30, left: 5, right: 5, bottom: 0),
      height: MediaQuery.of(context).size.height *.85,
      child: GestureDetector(
        onTap: () { FocusScope.of(context).unfocus(); },
        child: Column(
          children: [
            Text("Invite to channel", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[700])),
            Container(
              margin: EdgeInsets.only(bottom: 30, top: 10),
              child: Text("Enter Pancake ID to invite friends to channel", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 13))
            ),
            SearchBarChannel(onInviteToChannel: onInviteToChannel),
            Container(margin: EdgeInsets.only(top: 15, left: 10, right: 10), child: Divider()),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(members.length > 0 ? "RESULTS" : "YOUR FRIENDS", style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.grey[500]))
              ),
            ),
            members.length > 0 ? Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CachedImage(
                      members[index]["avatar_url"],
                      radius: 35,
                      isRound: true,
                      name: members[index]["full_name"]
                    ),
                    title: Text("${members[index]["full_name"]}"),
                    trailing: Container(
                      height: 34,
                      width: 80,
                      child: TextButton(
                        // shape: RoundedRectangleBorder(
                        //   borderRadius: BorderRadius.circular(5),
                        //   side: BorderSide(color: validate(members[index]["id"]) == true ? Utils.getPrimaryColor() : Colors.grey),
                        // ),
                        child: Text("Invite", style: TextStyle(fontSize: 13, color: validate(members[index]["id"]) == true ? Utils.getPrimaryColor() : Colors.grey)),
                        onPressed: validate(members[index]["id"]) == true ? () => _invite(auth.token, currentWorkspace["id"], currentChannel["id"], members[index]) : null
                      ),
                    ),
                  );
                },
              ),
            ) : FriendList(type: "toChannel")
          ]
        ),
      ),
    );
  }
}

class SearchBarChannel extends StatelessWidget {
  const SearchBarChannel({
    Key? key,
    this.onInviteToChannel
  }) : super(key: key);

  final onInviteToChannel;

  @override
  Widget build(BuildContext context) {
    // final TextEditingController _invitePeopleController = TextEditingController();
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final auth = Provider.of<Auth>(context);

    var _debounce;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: CustomSearchBar(
        placeholder: "Invite to ${currentChannel["name"]}",
        // controller: _invitePeopleController,
        onChanged: (value) {
          if (_debounce?.isActive ?? false) _debounce.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
            onInviteToChannel(auth.token, currentWorkspace["id"], currentChannel["id"], value);
          });
        },
      )
    );
  }
}
