import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_confirm_dialog.dart';
import 'package:workcake/components/message_item/attachments/attachments.dart';
import 'package:workcake/models/models.dart';

import 'CardItem.dart';

class ListActivity extends StatefulWidget {
  ListActivity({
    Key? key,
    required this.card
  }) : super(key: key);

  final CardItem card;

  @override
  _ListActivityState createState() => _ListActivityState();
}



class _ListActivityState extends State<ListActivity> {
  TextEditingController controller = TextEditingController();

  parseTime(comment) {
    final auth = Provider.of<Auth>(context, listen: false);
    DateTime dateTime = DateTime.parse(comment["inserted_at"]);
    final messageTime = DateFormat('kk:mm').format(DateTime.parse(comment["inserted_at"]).add(Duration(hours: 7)));
    final dayTime = DateFormatter().getVerboseDateTimeRepresentation(dateTime, auth.locale);

    return (comment["inserted_at"] != "" && comment["inserted_at"] != null)
      ? "${dayTime == "Today" ? messageTime : DateFormatter().renderTime(DateTime.parse(comment["inserted_at"]), type: "MMMd") + " at $messageTime"}"
      : "";
  }

  onDeleteComment(comment) {
    CardItem card = widget.card;
    final token = Provider.of<Auth>(context, listen: false).token;
    int index = card.activity.indexWhere((e) => e["id"] == comment["id"]);

    if (index == -1) return;

    Provider.of<Boards>(context, listen: false).deleteComment(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id, comment["id"]);
    card.activity.removeAt(index);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User>(context, listen: true).currentUser;
    final token = Provider.of<Auth>(context, listen: true).token;
    CardItem card = widget.card;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(width: 16, child: Icon(Icons.menu, color: Colors.grey[700], size: 25)),
            SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Activity", style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.w600)),
              ]
            )
          ]
        ),
        SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedAvatar(currentUser["avatar_url"], name: currentUser["full_name"], width: 36, height: 36),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                  border: Border.all(color: Color(0xffe1e3e9))
                ),
                margin: EdgeInsets.only(left: 10),
                child: Column(
                  children: [
                    TextFormField(
                      minLines: 1,
                      maxLines: 10,
                      controller: controller,
                      style: TextStyle(color: Colors.grey[800]),
                      decoration: InputDecoration(
                        hintStyle: TextStyle(color: Colors.grey[800]),
                        hintText: "Write a comment...",
                        border: OutlineInputBorder(borderSide: BorderSide.none)
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.blueAccent),
                            child: TextButton(
                            onPressed: () async {
                              if (controller.text.trim() != "") {
                                await Provider.of<Boards>(context, listen: false).sendCommentCard(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id, controller.text.trim());
                                await Provider.of<Boards>(context, listen: false).getActivity(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id).then((res) {
                                  this.setState(() {
                                    card.activity = res["activity"];
                                  });
                                });
                                controller.clear();
                              }
                            }, 
                            child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)))
                          )
                        ]
                      )
                    )
                  ]
                )
              )
            )
          ]
        ),
        SizedBox(height: 20),
        Column(
          children: card.activity.map((e) {
            final comment = e;
            final author = comment["author"];

            return  Container(
              margin: EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CachedAvatar(author["avatar_url"], name: author["full_name"], width: 36, height: 36),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(left: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.end,
                            children: [
                              Container(
                                margin: EdgeInsets.only(left: 2),
                                child: Text(author["full_name"], style: TextStyle(color: Colors.grey[700]))
                              ),
                              SizedBox(width: 10),
                              Text("${parseTime(comment)}", style: TextStyle(color: Colors.grey[600], fontSize: 13))
                            ],
                          ),
                          SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.only(left: 10),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.white, 
                              border: Border.all(color: Color(0xffe1e3e9)),
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: Markdown(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              physics: NeverScrollableScrollPhysics(),
                              imageBuilder: (uri, title, alt) {
                                var tag  = Utils.getRandomString(30);
            
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        barrierDismissible: true,
                                        barrierLabel: '',
                                        opaque: false,
                                        barrierColor: Colors.black.withOpacity(1.0),
                                        pageBuilder: (context, _, __) => ImageDetail(url: "$uri", id: tag, full: true, tag: tag)
                                      )
                                    );
                                  },
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxHeight: 400,
                                      maxWidth: 750
                                    ),
                                    child: ImageItem(tag: tag, img: {'content_url': uri.toString(), 'name': alt}, previewComment: true, isConversation: false),
                                  )
                                );
                              },
                              shrinkWrap: true,
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(fontSize: 15.5, height: 1, color: Colors.grey[700]),
                                a: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                code: TextStyle(fontSize: 15, fontStyle: FontStyle.italic)
                              ),
                              checkboxBuilder: (value) {
                                return Text("- [ ]", style: TextStyle(fontSize: 15.5, height: 1));
                              },
                              onTapLink: (link, url, uri) async{
                                if (await canLaunch(url ?? "")) {
                                  await launch(url ?? "");
                                } else {
                                  throw 'Could not launch $url';
                                }
                              },
                              selectable: true,
                              data: comment["comment"]
                            )
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              SizedBox(width: 2),
                              InkWell(
                                onTap: () {},
                                child: Text("Edit", style: TextStyle(color: Colors.grey[600], decoration: TextDecoration.underline))
                              ),
                              SizedBox(width: 6),
                              InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return CustomConfirmDialog(
                                        title: "Delete comment",
                                        subtitle: "Are you sure you want to delete this comment?",
                                        onConfirm: () async {
                                          final token = Provider.of<Auth>(context, listen: false).token;
                                          int index = card.activity.indexWhere((e) => e["id"] == comment["id"]);

                                          if (index == -1) return;

                                          Provider.of<Boards>(context, listen: false).deleteComment(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id, comment["id"]);
                                          setState(() { card.activity.removeAt(index); });
                                        }
                                      );
                                    }
                                  );
                                },
                                child: Text("Delete", style: TextStyle(color: Colors.grey[600], decoration: TextDecoration.underline))
                              )
                            ]                              
                          )
                        ]
                      )
                    )
                  )
                ]
              )
            );
          }).toList(),
        )
      ]
    );
  }
}