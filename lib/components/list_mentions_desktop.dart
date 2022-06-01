import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/models/models.dart';

import 'mention_item.dart';

class ListMentionsDesktop extends StatefulWidget {
  @override
  _ListMentionsDesktopState createState() => _ListMentionsDesktopState();
}

class _ListMentionsDesktopState extends State<ListMentionsDesktop> {
  ScrollController controller = new ScrollController();

  void initState() {
    super.initState();
    controller.addListener(_scrollListener);
    Timer.run(()  {
      var channel  =  Provider.of<Auth>(context, listen: false).channel;
      var currentWorkspace  =  Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      channel.push(event: "read_workspace_mentions", payload: {"workspace_id": currentWorkspace["id"]});
    });
  }

  _scrollListener(){
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final token = Provider.of<Auth>(context, listen: false).token;
    if (controller.position.extentAfter < 10) {
      Provider.of<Workspaces>(context, listen: false).getMentions(token, currentWorkspace["id"], true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataMentions = Provider.of<Workspaces>(context, listen: true).mentions;
    final channels  =  Provider.of<Channels>(context, listen: true).data;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    var indexW = dataMentions.indexWhere((element) => "${element["workspace_id"]}" == "${currentWorkspace["id"]}");
    List mentions  = [];

    if (indexW != -1){
      dataMentions[indexW]["data"].sort((a, b) =>  a["current_time"] > b["current_time"] ? -1 : 1);
      mentions = dataMentions[indexW]["data"];
    } 
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12.0),
      child: Container(
        height: 800,
        child: ListView.builder(
          shrinkWrap: true,
          controller: controller,
          itemCount: mentions.length,
          itemBuilder: (context, index) {
            final locale = Provider.of<Auth>(context, listen: false).locale;
            final messageTime = DateFormat('kk:mm').format(DateTime.parse(mentions[index]["inserted_at"]).add(Duration(hours: 7)));
            DateTime dateTime = DateTime.parse(mentions[index]["inserted_at"]);
            final dayTime = DateFormatter().getVerboseDateTimeRepresentation(dateTime, locale);
            var showDateThread = (dayTime == "Today" ? "Today" : DateFormatter().renderTime(DateTime.parse(mentions[index]["inserted_at"]), type: "MMMd")) + " at $messageTime";
            // get source name
            String sourceName = "a direct message";
            String issueUniq = "";
            String text = "";
            if (Utils.checkedTypeEmpty(mentions[index]["channel_id"])) {
              var issueUniqueId = mentions[index]["issue"]["unique_id"] ?? "";
              issueUniq = issueUniqueId.toString();
              int indexChannel  = channels.indexWhere((element) => element["id"] == mentions[index]["channel_id"]);
              if (indexChannel == -1) sourceName = "channel has been deleted";
              else sourceName = channels[indexChannel]["name"];

              if (mentions[index]["type"] == "issues") {
                text = mentions[index]["issue"]["description"] ?? "";
              } else if (mentions[index]["type"] == "issue_comment") {
                text = mentions[index]["issue_comment"]["comment"] ?? "";
              }
            }
            return MentionItem(mentions: mentions, index: index, sourceName: sourceName,  issueUniq: issueUniq, text: text, showDateThread: showDateThread);
          },
        ),
      )
    );
  }
}