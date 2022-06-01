import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_search_bar.dart';
import 'package:workcake/components/friends/friend_list.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';

class InviteMember extends StatefulWidget {
  final type;

  InviteMember({this.type});
  @override
  _InviteMemberState createState() => _InviteMemberState();
}

class _InviteMemberState extends State<InviteMember> {
  final TextEditingController _invitePeopleController = TextEditingController();
  var user;

  @override
  void dispose() {
    _invitePeopleController.dispose();
    super.dispose();
  }

  _invitePeople() {
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    String pattern = r'(^(?:[+0]9)?[0-9]{10}$)';
    RegExp regExp = new RegExp(pattern);

    if (widget.type == 'toWorkspace') {
      if (!regExp.hasMatch( _invitePeopleController.text)) {
        Provider.of<Workspaces>(context, listen: false).inviteToWorkspace(token, currentWorkspace["id"], _invitePeopleController.text, 1, null);
      } else {
        Provider.of<Workspaces>(context, listen: false).inviteToWorkspace(token, currentWorkspace["id"], _invitePeopleController.text, 2, null);
      }
    } else {
      if (!regExp.hasMatch( _invitePeopleController.text)) {
        Provider.of<Channels>(context, listen: false).inviteToChannel(token, currentWorkspace["id"], currentChannel["id"], _invitePeopleController.text, 1, null);
      } else {
        Provider.of<Channels>(context, listen: false).inviteToChannel(token, currentWorkspace["id"], currentChannel["id"], _invitePeopleController.text, 2, null);
      }
    }
    _invitePeopleController.clear();
  }

  onSearch(value, type) async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final url = Utils.apiUrl + 'workspaces/${currentWorkspace["id"]}/search_member?text=$value&type=$type&token=$token';

    try {
      var response = await Dio().get(url);
      var dataRes = response.data;

      if (dataRes["success"]) {
        setState(() {
          user = dataRes["user"];
        });
      }
    } catch (e) {
      print(e.toString());
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  _invite(token, workspaceId, user) {
    String email = user["email"];
    Provider.of<Workspaces>(context, listen: false).inviteToWorkspace(token, workspaceId, email, 1, user);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: true);
    final members = Provider.of<Workspaces>(context, listen: true).members;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    final isDark = auth.theme == ThemeType.DARK;
    var _debounce;
    String pattern = r'(^(?:[+0]9)?[0-9]{10}$)';
    RegExp regExp = new RegExp(pattern);
    
    validate(id) {
      bool check = true;
      for (var member in members) {
        if (id == member["id"]) {
          check = false;
        }
      }
      return check;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () { Navigator.pop(context); }
        ),
        title: Text(
          S.of(context).invitePeople,
          style: TextStyle(fontSize: 18),
        ),
        centerTitle: true,
        actions: <Widget>[
          TextButton(
            onPressed: () => {
              _invitePeople()
            },
            child: Center(
              child: Text(
                'Send',
                style: TextStyle(
                  fontSize: 18.0,
                  color: isDark ? Colors.white : Colors.grey[800]
                ),
              ),
            )
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
              child: CustomSearchBar(
                placeholder: "Type an email or phone number to invite",
                controller: _invitePeopleController,
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      if (value != "") {
                        if (value.contains("@gmail.com") || value.contains("@pancake.vn")) {
                          onSearch(value, 1);
                        } else if (regExp.hasMatch(value)) {
                          onSearch(value, 2);
                        } else {
                          setState(() {
                            user = null;
                          });
                        }
                      } else {
                        setState(() {
                          user = null;
                        });
                      }
                    }
                  );
                },
              ),
            ),
          ),
          user != null ? Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      "RESULTS",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[700]
                      )
                    )
                  ]),
                SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          CachedAvatar(
                            user["avatar_url"],
                            height: 35, width: 35,
                            isRound: true,
                            name: user["full_name"]
                          ),
                          Container(margin: EdgeInsets.only(left: 20), child: Text("${user["full_name"]}"))
                        ],
                      ),
                    ],
                  ),
                  Container(
                    height: 34,
                    width: 80,
                    child: TextButton(
                      // shape: RoundedRectangleBorder(
                      //   borderRadius: BorderRadius.circular(5),
                      //   side: BorderSide(color: validate(user["id"]) == true ? Utils.getPrimaryColor() : Colors.grey),
                      // ),
                      child: Text("Invite", style: TextStyle(fontSize: 13, color: validate(user["id"]) == true ? Utils.getPrimaryColor() : Colors.grey)), 
                      onPressed: validate(user["id"]) == true ? () => _invite(auth.token, currentWorkspace["id"], user) : null
                    ),
                  ),
                ]),
              ],
            ),
          ) : Column(
            children: [
              Container(padding: EdgeInsets.only(left: 15, top: 10), child: Row(children: [Text("YOUR FRIENDS", style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey[300] : Colors.grey[700]))])),
              FriendList(type: widget.type),
            ],
          )
        ],
      ),
    );
  }
}