import 'package:flutter/material.dart';
import 'package:workcake/providers/providers.dart';

import 'mention_item.dart';

class ListMentionsConversation extends StatefulWidget {
  @override
  _ListMentionsConversationState createState() => _ListMentionsConversationState();
}

class _ListMentionsConversationState extends State<ListMentionsConversation> {

  @override
  Widget build(BuildContext context) {
    final mentions = Provider.of<DirectMessage>(context, listen: true).dataMentionConversations["data"];

    return Container(
      margin: EdgeInsets.only(top: 12, bottom: 12),
      child: mentions != null
        ? ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: mentions?.length,
          controller: ScrollController(),
          itemBuilder: (context, index) {
            // get source name
            String sourceName = mentions[index]["name"] ??  "a direct message";
            return MentionItem(mention: mentions[index], sourceName: sourceName, showDateThread: "");
          },
        ) : Container(),
    );
  }
}