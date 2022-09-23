import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/message_item/attachment_card_desktop.dart';
import 'package:workcake/providers/providers.dart';

class ShareAttachments extends StatefulWidget {
  final att;
  final channel;

  const ShareAttachments({ Key? key, required this.att, this.channel}) : super(key: key);

  @override
  State<ShareAttachments> createState() => _ShareAttachmentsState();
}

class _ShareAttachmentsState extends State<ShareAttachments> {

  parseTime(dynamic time) {
    var messageLastTime = "";
    if (time != null) {
      DateTime dateTime = DateTime.parse(time);
      final messageTime = DateFormat('kk:mm').format(DateTime.parse(time).add(Duration(hours: 7)));
      final dayTime = DateFormatter().getVerboseDateTimeRepresentation(dateTime, "en");

      messageLastTime = "$dayTime at $messageTime";
    }
    return messageLastTime;
  }

  onSelectMessage(Map message){
    Provider.of<Messages>(context, listen: false).handleProcessMessageToJump(message, context);
  }

  onSelectMessageDM(Map messsage) async {
    final auth = Provider.of<Auth>(context, listen: false);
    await Provider.of<DirectMessage>(context, listen: false).processDataMessageToJump(messsage, auth.token, auth.userId);
  }

  Widget replyDM() {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final att = widget.att;

    return InkWell(
      onTap: () {
        if (!att['data']['isChannel']) {
          Provider.of<DirectMessage>(context, listen: false).getInfoDirectMessage(auth.token, att['data']['conversation_id'] ?? att['data']['conversationId']).then((value) {
            if(value) {
              onSelectMessageDM({
                ...att["data"],
              });
            }
          });
        } else {
          final List data = Provider.of<Channels>(context, listen: false).data;
          int index = data.indexWhere((ele) => ele['id'] == att["data"]["channelId"] && ele['workspace_id'] == att["data"]["workspaceId"]);
          if (index == -1) return;

          onSelectMessage({
            ...att["data"],
            "workspace_id": att["data"]["workspaceId"],
            "channel_id": att["data"]["channelId"]
          });
        }
      },
      child: Container(
        margin: EdgeInsets.only(top: 5, right: 16),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Color(0xff2E2E2E) : Color(0xffEDEDED),
          border: Border(
            left: BorderSide(
              color: Color(0xffd0d0d0),
              width: 4.0,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              child: Row(
                children: [
                  // Text("Replied to ", style: TextStyle(fontStyle: FontStyle.italic)),
                  CachedAvatar(
                    att["data"]["avatarUrl"],
                    height: 20, width: 20,
                    isRound: true,
                    name: att["data"]["fullName"],
                    isAvatar: true,
                    fontSize: 13,
                  ),
                  SizedBox(width: 5),
                  Text(att["data"]["fullName"])
                ],
              ),
            ),
            SizedBox(height: 10),
            Utils.checkedTypeEmpty(att["data"]["isUnsent"])
              ? Container(
                height: 19,
                child: Text(
                  "[This message was deleted.]",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Color(isDark ? 0xffe8e8e8 : 0xff898989)
                  ),
                )
              )
              : (att["data"]["message"] != "" && att["data"]["message"] != null)
                ? Container(
                  padding: EdgeInsets.only(left: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(att["data"]["message"]),
                      att["data"]["attachments"] != null && att["data"]["attachments"].length > 0
                        // ? Text("Attachments")
                        ? AttachmentCardDesktop(
                          attachments: att["data"]["attachments"],
                          isChannel: att["data"]["isChannel"],
                          id: att["data"]["id"],
                          isChildMessage: false,
                          isThread: att["data"]["isThread"] ?? false,
                          lastEditedAt: parseTime(att["data"]["lastEditedAt"])
                        )
                        : Container()
                    ],
                  ),
                )
                : att["data"]["attachments"] != null && att["data"]["attachments"].length > 0
                  ? Container(
                    padding: EdgeInsets.only(left: 3),
                    // child: Text("Attachments")
                    child: AttachmentCardDesktop(
                      attachments: att["data"]["attachments"],
                      isChannel: att["data"]["isChannel"],
                      id: att["data"]["id"],
                      isChildMessage: false,
                      isThread: false,
                      conversationId: att["data"]["conversationId"],
                      lastEditedAt: parseTime(att["data"]["lastEditedAt"]),
                      blockCode: att['data']['block_code'],
                    )
                  )
                  : Container(),
            SizedBox(height: 5),
          ],
        )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final att = widget.att;
    final channel = widget.channel;

    return channel == null
    ? replyDM()
    : Container(
      margin: EdgeInsets.only(top: 5, right: 16),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Color(0xff2E2E2E) : Color(0xffEDEDED),
          border: Border(
            left: BorderSide(
              color: Color(0xffd0d0d0),
              width: 4.0,
            ),
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            child: Row(
              children: [
                CachedAvatar(
                  att["data"]["avatarUrl"],
                  height: 24, width: 24,
                  isRound: true,
                  name: att["data"]["fullName"],
                  isAvatar: true,
                  fontSize: 13,
                ),
                SizedBox(width: 5),
                Text(att["data"]["fullName"])
              ],
            ),
          ),
          SizedBox(height: 4),
          Utils.checkedTypeEmpty(att["data"]["isUnsent"])
            ? Container(
              height: 19,
              child: Text(
                "[This message was deleted.]",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Color(isDark ? 0xffe8e8e8 : 0xff898989)
                ),
              )
            )
            : (att["data"]["message"] != "" && att["data"]["message"] != null)
              ? Container(
                padding: EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(att["data"]["message"]),
                    att["data"]["attachments"] != null && att["data"]["attachments"].length > 0
                      // ? Text("Attachments")
                      ? AttachmentCardDesktop(
                        attachments: att["data"]["attachments"],
                        isChannel: att["data"]["isChannel"] ?? true,
                        id: att["data"]["id"],
                        isChildMessage: false,
                        isThread: att["data"]["isThread"] ?? false,
                        lastEditedAt: parseTime(att["data"]["lastEditedAt"])
                      )
                      : Container()
                  ],
                ),
              )
              : att["data"]["attachments"] != null && att["data"]["attachments"].length > 0
                ? Container(
                  padding: EdgeInsets.only(left: 8),
                  // child: Text("Attachments")
                  child: AttachmentCardDesktop(
                    attachments: att["data"]["attachments"],
                    isChannel: att["data"]["isChannel"],
                    id: att["data"]["id"],
                    isChildMessage: false,
                    isThread: false,
                    conversationId: att["data"]["conversationId"],
                    lastEditedAt: parseTime(att["data"]["lastEditedAt"]),
                    blockCode: att['data']['block_code'],
                  )
                )
                : Container(),
          SizedBox(height: 5),
          Container(
            child: Row(
              children: [
                Text("Posted in ", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Color(0xFF323F4B))),
                SizedBox(width: 3),
                channel['is_private']
                  ? SvgPicture.asset('assets/icons/Locked.svg', width: 9, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight)
                  : SvgPicture.asset('assets/icons/iconNumber.svg', width: 9, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                SizedBox(width: 3),
                Text(channel["name"] ?? "", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Color(0xFF323F4B))),
                SizedBox(width: 5),
                Text(parseTime(att["data"]["insertedAt"]), style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Color(0xFF323F4B))),
                SizedBox(width: 5),
                if(att['data']['current_time'] != null) Container(width: 1, height: 13, color: Colors.blueGrey),
                if(att['data']['current_time'] != null) SizedBox(width: 5),
                if(att['data']['current_time'] != null) Expanded(
                  child: InkWell(
                    onTap: () {
                      onSelectMessage({
                        ...att["data"],
                        "workspace_id": att["data"]["workspaceId"],
                        "channel_id": att["data"]["channelId"]
                      });
                    },
                    child: Text("View message", style: TextStyle(fontSize: 12, color: Colors.blue, overflow: TextOverflow.ellipsis)),
                  ),
                )
              ],
            ),
          ),
        ],
      )
    );
  }
}