import 'package:better_selection/better_selection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/styles.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/profile/user_profile_desktop.dart';
import 'package:workcake/models/models.dart';

import 'message_item/attachment_card_desktop.dart';
import 'message_item/message_card_desktop.dart';

class PinnedMessage extends StatefulWidget {
  const PinnedMessage({
    Key? key,
    @required this.isDark,
  }) : super(key: key);

  final isDark;

  @override
  _PinnedMessageState createState() => _PinnedMessageState();
}

class _PinnedMessageState extends State<PinnedMessage> {
  bool open = false;
  List snippetList = [];
  List listBlockCode = [];

  onExpand(value) async{
    var box = await Hive.openBox('drafts');
    box.put('openMember', value);

    setState(() {
      open = value;
    });
  }

  onSelectMessage(Map message){
    Provider.of<Messages>(context, listen: false).handleProcessMessageToJump(message, context);
  }

  @override
  Widget build(BuildContext context) {
    final pinnedMessages = Provider.of<Channels>(context, listen: true).pinnedMessages;
    final showChannelPinned = Provider.of<Channels>(context, listen: true).showChannelPinned;
    final workspaceId = Provider.of<Workspaces>(context, listen: true).currentWorkspace["id"];
    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Palette.backgroundTheardDark,
                  border: Border(
                    bottom: BorderSide(
                      color: Palette.borderSideColorDark
                    )
                  )
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset('assets/icons/pinned.svg'),
                        const SizedBox(width: 10),
                        const Text("Pinned Messages", style: TextStyle(color: Color(0xffF0F4F8), fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    IconButton(
                      padding: const EdgeInsets.only(left: 2),
                      onPressed:(){
                        Provider.of<Channels>(context, listen: false).openChannelPinned(!showChannelPinned);
                      }, 
                      icon: SvgPicture.asset('assets/icons/newX.svg', height: 14.13)
                    )
                  ]
                )
              ),
              Expanded(
                child: Container(
                  child: (pinnedMessages.isEmpty) ? Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text("No items have been pinned yet!", style: TextStyle(fontSize: 14, color: widget.isDark? const Color(0xDBDBDBDB) : Colors.grey[700])),
                        const SizedBox(height: 9),
                        Text(
                          "Open the context menu on important messages or files and choose Pin to ﻿pan-photo to stick them here.",
                          style: TextStyle(
                            fontSize: 11.5, color: Palette.fillerText, height: 1.5
                          )
                        ),
                      ],
                    )
                  ) : Container(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: pinnedMessages.length,
                      controller: ScrollController(),
                      itemBuilder: (BuildContext context, int index) {
                        var item = pinnedMessages[index];
                        List newList =  item["attachments"] != null ?  item["attachments"].where((e) => e["mime_type"] == "html").toList() : [];
                        if (newList.isNotEmpty) {
                          Utils.handleSnippet(newList[0]["content_url"], false).then((value) {
                            int index = snippetList.indexWhere((e) => e["id"] == item["id"]);
                            if (index == -1) {
                              setState(() {
                              snippetList.add({
                                "id": item["id"],
                                "snippet": value,
                              });
                            });
                            }
                          });
                        }
                        List blockCode = item["attachments"] != null ? item["attachments"].where((e) => e["mime_type"] == "block_code").toList() : [];
                        if (blockCode.isNotEmpty) {
                          Utils.handleSnippet(blockCode[0]["content_url"], true).then((value) {
                            int index = listBlockCode.indexWhere((e) => e["id"] == item["id"]);
                            if (index == -1) {
                              setState(() {
                              listBlockCode.add({
                                "id": item["id"],
                                "block_code": value,
                              });
                            });
                            }
                          });
                        }
                        final newSnippet = snippetList.where((e) => e["id"] == item["id"]).toList();
                        final newListBlockCode = listBlockCode.where((e) => e["id"] == item["id"]).toList();
                        final snippet = newSnippet.isNotEmpty ? newSnippet[0]["snippet"] : "";
                        final newBlockCode = newListBlockCode.isNotEmpty ? newListBlockCode[0]["block_code"] : "";
                        
                        final message = {
                          'id': item['id'],
                          "avatarUrl": item["avatar_url"] ?? "",
                          "fullName": item["full_name"] ?? "",
                          "workspace_id": workspaceId,
                          "channel_id": item["channel_id"],
                          'inserted_at': item['inserted_at'],
                          'current_time': item['current_time'] ?? DateTime.parse(item['inserted_at']).toUtc().microsecondsSinceEpoch
                        };
                          
                        return InkWell(
                          onTap: () {
                            onSelectMessage(message);
                          },
                          child: PinnedMessageTile(item: item, snippet: snippet, newBlockCode: newBlockCode, isDark: widget.isDark)
                        );
                      }
                    )
                  )
                )
              )
            ]
          )
        )
      ],
    );
  }
}

class PinnedMessageTile extends StatefulWidget {
  final item;
  final snippet;
  final newBlockCode;
  final isDark;
  const PinnedMessageTile({ Key? key, required this.item, required this.snippet, required this.newBlockCode, required this.isDark}) : super(key: key);

  @override
  _PinnedMessageTileState createState() => _PinnedMessageTileState();
}

class _PinnedMessageTileState extends State<PinnedMessageTile> {
  bool isShowCloseButton = false;
  late TapGestureRecognizer _onTapTextSpan;
  getUser(userId) {
    var users = Provider.of<Channels>(context, listen: false).channelMember;
    int index = users.indexWhere((e) => e["id"] == userId || e["user_id"] == userId);

    if (index != -1) {
      return {
        "avatar_url": users[index]["avatar_url"],
        "full_name": users[index]["full_name"],
        "role_id": users[index]["role_id"]
      };
    } else {
      return {
        "avatar_url": "",
        "full_name": "Bot"
      };
    }
  }

  @override
  void initState(){
    _onTapTextSpan = TapGestureRecognizer();
    super.initState();
  }
  
  @override
  void dispose() {
    _onTapTextSpan.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final token = Provider.of<Auth>(context, listen: true).token;
    final channelId = Provider.of<Channels>(context, listen: true).currentChannel["id"];
    final workspaceId = Provider.of<Workspaces>(context, listen: true).currentWorkspace["id"];
    final currentUser = Provider.of<User>(context, listen: true).currentUser;
    final customColor = currentUser["custom_color"];
    return MouseRegion(
      onEnter: (event) {
        setState(() {
          isShowCloseButton = true;
        });
      },
      onExit: (event) {
        setState(() {
          isShowCloseButton = false;
        });
      },
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17.5),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 4, color: widget.isDark ? Palette.selectChannelColor : Colors.grey[300]!),
            )
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: (){
                  if (currentUser["id"] != widget.item["user_id"]) {
                    onShowUserInfo(context, widget.item["user_id"]);
                  }
                },
                child: CachedAvatar(
                  widget.item["avatar_url"],
                    width: 32,
                    height: 32,
                    name: widget.item["full_name"],
                    isRound: true,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(widget.item["full_name"], 
                              style: TextStyle(
                                fontWeight: FontWeight.w700, 
                                color: widget.item["user_id"] == currentUser["id"] && (customColor != "default" && customColor != null)
                                  ? Color(int.parse("0xFF$customColor")) 
                                  : Constants.checkColorRole(getUser(widget.item["user_id"])["role_id"], widget.isDark), 
                                fontSize: 14)),
                            SizedBox(width: 5),
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(widget.item["inserted_at"] != null ? (DateFormatter().renderTime(DateTime.parse(widget.item["inserted_at"]), type: "dd/MM/yyyy")) : "", style: TextStyle(color: widget.isDark ? Palette.defaultBackgroundLight : Palette.defaultBackgroundDark,fontSize: 11)),
                            ),
                          ]
                        ),
                        isShowCloseButton
                        ? InkWell(
                          onTap:() {
                            Provider.of<Channels>(context, listen: false).pinMessage(token, workspaceId, channelId, widget.item["id"], false);
                          },
                          child: SvgPicture.asset('assets/icons/CloseCircle.svg', color: widget.isDark ? Palette.topicTile : Colors.grey[700], height: 18),
                        ) : const SizedBox(height: 18),
                      ],
                    ),
                    const SizedBox(height: 2.5),
                    widget.item["message"] != "" ? SelectableScope(
                      child: SizedBox(
                        width: double.infinity,
                        child: MessageCardDesktop(
                          id: widget.item["id"], 
                          message: widget.item["message"]
                        ),
                      ),
                    ) : const SizedBox(),
                    SelectableScope(
                      child: AttachmentCardDesktop(
                        id: widget.item["id"],
                        attachments: widget.item["attachments"],
                        isChannel: true,
                        isChildMessage: false,
                        userId: widget.item["user_id"],
                        snippet: widget.snippet,
                        blockCode: widget.newBlockCode,
                        isThread: true,
                      ),
                    ),
                  ],
                ),
              ),
            ]
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
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
        insetPadding: const EdgeInsets.all(0),
        contentPadding: const EdgeInsets.all(0),
        content: UserProfileDesktop(userId: id),
      );
    }
  );
}