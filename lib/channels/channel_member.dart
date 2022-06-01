import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_search_bar.dart';
import 'package:workcake/models/models.dart';

import 'channel_member_bottom.dart';
import 'list_member.dart';

class ChannelMember extends StatefulWidget {
  final isDelete;
  ChannelMember({Key? key, this.isDelete}) : super(key: key);

  @override
  _ChannelMemberState createState() => _ChannelMemberState();
}

class _ChannelMemberState extends State<ChannelMember> {
  final TextEditingController _invitePeopleController = TextEditingController();
  List members = [];

  @override
  void initState() { 
    super.initState();
    final channelMember = Provider.of<Channels>(context, listen: false).channelMember;
    this.setState(() {
      members = channelMember;
    });
  }
  
  @override
  void dispose() {
    _invitePeopleController.dispose();
    super.dispose();
  }

  onSearchMember(token, value) async {
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final url = Utils.apiUrl + 'workspaces/${currentWorkspace["id"]}/channels/${currentChannel["id"]}/search_member?text=$value&token=$token';

    if (value != "") {
      try {
        var response = await Dio().get(url);
        var dataRes = response.data;

        if (dataRes["success"]) {
          this.setState(() {
            members = dataRes["members"];
          });
        }
        else throw HttpException(dataRes["message"]);
      } catch (e) {
        print(e.toString());
        // sl.get<Auth>().showErrorDialog(e.toString());
      }
    } else {
      final channelMember = Provider.of<Channels>(context, listen: false).channelMember;
      this.setState(() {
        members = channelMember;
      });
    }
  }

   
  @override
  Widget build(BuildContext context) {
    var _debounce;
    double deviceWidth = MediaQuery.of(context).size.width;
    final auth = Provider.of<Auth>(context);
    final isDelete = widget.isDelete;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0.0,
        title: Text(
          'Members',
          style: TextStyle(fontWeight: FontWeight.w400, fontSize: 19)
        ),
        bottom: PreferredSize(
          child: Container(
            padding: EdgeInsets.only(bottom: 10),
            width: deviceWidth - 30,
            height: 50,
            child: CustomSearchBar(
              placeholder: "Search Member",
              controller: _invitePeopleController,
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  onSearchMember(auth.token, value);
                });
              },
            )
          ),
          preferredSize: Size.fromHeight(50.0)
        ),
      ),
      body: ListMember(isDelete: isDelete, type: "channel", members: members),
      bottomNavigationBar: ChannelMemberBottom(isDelete: isDelete)
    );
  }
}
