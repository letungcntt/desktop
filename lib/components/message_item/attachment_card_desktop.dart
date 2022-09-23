import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:hive/hive.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/common/video_player.dart';
import 'package:workcake/components/call_center/p2p_manager.dart';
import 'package:workcake/components/collapse.dart';
import 'package:workcake/components/message_item/message_card_desktop.dart';
import 'package:workcake/components/profile/user_profile_desktop.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/components/widget_text.dart';
import 'package:workcake/media_conversation/stream_media_downloaded.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/services/upload_status.dart';

import 'attachments/attachments.dart';
import 'attachments/sticker_file.dart';

class AttachmentCardDesktop extends StatefulWidget {
  final attachments;
  final isChannel;
  final isChildMessage;
  final isThread;
  final id;
  final userId;
  final snippet;
  final blockCode;
  final conversationId;
  final lastEditedAt;
  final message;
  final isPinnedMessage;

  AttachmentCardDesktop({
    Key? key,
    this.attachments,
    this.isChannel,
    this.isChildMessage,
    this.id,
    this.userId,
    this.isThread,
    this.snippet,
    this.blockCode,
    this.conversationId,
    this.lastEditedAt,
    this.message,
    this.isPinnedMessage = false
  }) : super(key: key);

  @override
  _AttachmentCardDesktopState createState() => _AttachmentCardDesktopState();
}

class _AttachmentCardDesktopState extends State<AttachmentCardDesktop> {
  String snippet = "";
  bool isShift = false;

  @override
  void initState() {
    RawKeyboard.instance.addListener(handleKey);
    super.initState();
  }

  handleKey(RawKeyEvent event) {
    if (isShift != event.isShiftPressed) setState(() => isShift = event.isShiftPressed);
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(handleKey);
    super.dispose();
  }

  void openLink(e) async{
    if (await canLaunch(e.toString().trim())) {
      await launch(e.toString().trim());
    } else {
      throw 'Could not launch $e';
    }
  }

  TextSpan renderText(string) {
    final isDark  = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    RegExp exp = new RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
    List list = string.replaceAll("\n", " \n").split(" ");

    return TextSpan(
      style: TextStyle(fontSize: 15, height: 1.5),
      children: list.map<TextSpan>((e){
        Iterable<RegExpMatch> matches = exp.allMatches(e);
        bool isLink = false;
        if (e.startsWith('\n')) isLink = e.startsWith('\nhttp');
        else isLink = e.startsWith('http');
        if (matches.length > 0 && isLink)
          return TextSpan(
            children: [
              TextSpan(
                text: e,
                style: matches.length > 0
                  ? TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, decoration: TextDecoration.underline)
                  : TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                recognizer: TapGestureRecognizer()..onTap = matches.length > 0 && !isShift ? () {
                  openLink(e);
                } : null,
              ),
              TextSpan(text: " ")
            ]
          );
        else return TextSpan(text: "$e ", style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight));
      }).toList()
    );
  }

  onShowIssueInfo(issue) {
    Provider.of<Channels>(context, listen: false).onChangeOpenIssue({...issue, 'type': 'edited', 'comments': [], 'timelines': [], 'fromMentions': true, "is_closed": false});
    Provider.of<Auth>(context, listen: false).keyDrawer.currentState!.openEndDrawer();
  }
  showInfo(context, id) {
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    if (id != null && currentUser["id"] != id) onShowUserInfo(context, id);
  }

  renderTextMention(att, isDark, user, dm) {
    return att["data"].map((e){
      if (e["type"] == "text" && Utils.checkedTypeEmpty(e["value"])) return e["value"];
      if (e["name"] == "all" || e["type"] == "all") return "@all ";

      if (e["type"] == "issue") {
        return "";
      } else {
        if (widget.isChannel) {
          return Utils.checkedTypeEmpty(e["name"]) ? "@${e["name"]} " : "";
        } else {
          var u = dm == null ? [] : dm.user.where((element) => element["user_id"] == e["value"]).toList();
          return u.length > 0 ? "@${u[0]["full_name"]} " : "";

        }
      }
    }).toList().join("");
  }

  Widget renderFile(att, isDark) {
    return (att["name"] ?? "").toLowerCase().contains(".heic")
      ? ImagesGallery(isChildMessage: widget.isChildMessage, att: {"data": [att]}, isThread: widget.isThread, message: widget.message, isConversation: !widget.isChannel, )
      : RenderFile(att: att, isDark: isDark, isConversation: Utils.checkedTypeEmpty(widget.conversationId));
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final appInChannel = Provider.of<Channels>(context, listen: false).appInChannels;
    final channels = Provider.of<Channels>(context, listen: false).data;
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final token = Provider.of<Auth>(context, listen: false).token;
    final openThread = Provider.of<Messages>(context, listen: true).openThread;
    final showChannelSetting = Provider.of<Channels>(context, listen: true).showChannelSetting;
    final showDirectSetting = Provider.of<DirectMessage>(context, listen: true).showDirectSetting;
    var indexDM = Provider.of<DirectMessage>(context, listen: true).data.indexWhere((element) => element.id == widget.conversationId);
    final dm = indexDM  == -1 ? Provider.of<DirectMessage>(context, listen: true).directMessageSelected : Provider.of<DirectMessage>(context, listen: true).data[indexDM];
    List newAttachments = List.from(widget.attachments).where((e) => !(e["type"] == "image" || e["mime_type"] == "image")).toList();
    List images = (widget.attachments ?? []).where((e) => e["type"] == "image" || e["mime_type"] == "image").toList();
    newAttachments.add({"type": "image", "data": images});
    final isOnThreads = Provider.of<Threads>(context, listen: false).isOnThreads;
    final user = Provider.of<User>(context, listen: false).currentUser;

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
          newAttachments.map<Widget>((att) {
            if (att["uploading"] == true) {
              return StreamBuilder(
                stream: StreamUploadStatus.instance.status,
                builder: (context, status) {
                  double statusUploadAtt = 0.0;
                  if (status.data != null) {
                    try {
                      statusUploadAtt = (status.data as Map)[att["att_id"]];
                    } catch (e) {
                      statusUploadAtt = 1.0;
                    }
                  }
                  return Container(
                    constraints: BoxConstraints(maxWidth: 330, minWidth: 250),
                    margin: EdgeInsets.only(bottom: 5, top: 5),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color(0X55D1D2D3)
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Container(
                          child: Icon(CupertinoIcons.doc_fill, size: 30.0, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight)
                        ),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextWidget(
                                  att["name"] ?? "",
                                  style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15
                                  )
                                ),
                                SizedBox(height: statusUploadAtt > 0.99 ? 2 : 5),
                                ClipRRect(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                  child:  TextWidget(
                                    "Processing",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Palette.defaultTextDark.withOpacity(0.7) : Palette.defaultTextLight,
                                      fontWeight: FontWeight.w300
                                    )
                                  )
                                )
                              ]
                            )
                          )
                        )
                      ]
                    )
                  );
                }
              );
            }

            switch (att["type"]) {
              case "pos_app":
                return PosAppAttachments(att: att);
              case "poll":
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: PollCard(att: att, message: widget.message, isPinnedMessage: widget.isPinnedMessage),
                );
              case "send_to_channel_from_thread":
                if (widget.isThread) return Container();
                var _onTapMention = TapGestureRecognizer();
                var parentMessage = att["parent_message"];
                return RichTextWidget(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "replied to a thread: ",
                        style: TextStyle(color: isDark ? Colors.white70 : Color(0xFF323F4B))
                      ),
                      TextSpan(
                        text: Utils.checkedTypeEmpty(att["parent_message"]["message"])
                            ? att["parent_message"]["message"]
                            : att["parent_message"]["attachments"][0]["type"] == "mention"
                                ? renderTextMention(att["parent_message"]["attachments"][0], isDark, user, dm)
                                : att["parent_message"]["attachments"][0]["mime_type"] == "image"
                                    ? att["parent_message"]["attachments"][0]["name"]
                                    : "Parent message",
                        style: TextStyle(color: Colors.lightBlue[400], fontSize: 15, height: 1.5),
                        recognizer: _onTapMention..onTap = () => !isShift
                            ? Provider.of<Messages>(context, listen: false).openThreadMessage(true, parentMessage)
                            : null,
                      ),
                    ]
                  ),
                );
              case "order":
                return OrderAttachments(att: att, id: widget.id);
              case "message_start":
                return Center(
                  child: Container(
                    margin: EdgeInsets.only(right: 55),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFFfff7e6),
                      borderRadius: BorderRadius.circular(8)
                    ),

                    child: TextWidget(att["data"], style: TextStyle(color: Color(0xFFfa8c16)),)
                  ),
                ) ;
              case "device_info":
                var time  = att["data"]["request_time"] == null ? "_" :  DateTime.fromMicrosecondsSinceEpoch(att["data"]["request_time"]);
                var deviceInfo = att["data"]["device_info"];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    att["attachments_v2"] ?? false ? Column(
                      children: [
                        Text.rich(
                          TextSpan(
                            style: TextStyle(height: 1.57),
                            children: [
                              TextSpan(text: "A new device  "),
                              TextSpan(text: "($deviceInfo)", style: TextStyle(fontWeight: FontWeight.w700)),
                              TextSpan(text:" request sync data"),
                            ]
                          )
                        ),
                        SizedBox(height: 4,),
                      ],
                    ) : SizedBox(),
                    Container(
                      margin: EdgeInsets.only(top: 5),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: isDark ? Colors.white12 : Colors.grey[300],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              TextWidget("Device id:"),
                              SizedBox(width: 5),
                              Expanded(child: TextWidget(att["data"]["device_id"], overflow: TextOverflow.ellipsis))
                            ]
                          ),
                          Container(height: 5),
                          Row(
                            children: [
                              TextWidget("Request time:"),
                              SizedBox(width: 5),
                              att["data"]["request_time"] == null ? Container() : TextWidget(DateFormatter().renderTime(DateTime.parse(time.toString()), type: 'yMMMMd'), overflow: TextOverflow.ellipsis)
                            ]
                          ),
                        ],
                      )
                    ),
                  ],
                );
              case "action_button":
                return Container(
                  margin: EdgeInsets.only(top: 5),
                  child: Column(
                    children: att["data"].map<Widget>((ele){
                      return TextButton(
                        style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Color(0xFF1890ff)), padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 20))),
                        onPressed: ()async {
                          String url  = "${Utils.apiUrl}users/logout_device?token=$token";
                          LazyBox box = Hive.lazyBox('pairkey');
                          try{
                            var res = await Dio().post(url, data: {
                              "current_device": await box.get("deviceId"),
                              "data": await Utils.encryptServer({"device_id": ele["data"]["device_id"], "message_id" : widget.id})
                            });
                            if(res.data["success"] == false) throw res.data["message"];
                          }catch(e){
                             // sl.get<Auth>().showErrorDialog(e.toString());
                          }
                        },
                        // padding: EdgeInsets.all(10),
                        child: TextWidget(ele["label"], style: TextStyle(color: Color(0xFFffffff)))
                      );
                    }).toList(),
                  ),
                );
              case "mention":
                var value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichTextWidget(
                      TextSpan(
                        children: [
                          TextSpan(
                            children: att["data"].map<TextSpan>((e){
                              if (e["type"] == "text") value = e["value"];
                              if (e["type"] == "text" && Utils.checkedTypeEmpty(e["value"])) return renderText(e["value"]);
                              if (e["name"] == "all" || e["type"] == "all") return TextSpan(text: "@all ",  style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, fontSize: 15.5, height: 1.5));

                              if (e["type"] == "issue") {
                                return TextSpan(
                                  children: [
                                    WidgetSpan(
                                      child: MentionIssue(e: e, onShowIssueInfo: onShowIssueInfo)
                                    )
                                  ]
                                );
                              } else {
                                if (widget.isChannel) {
                                  var _onTapMention = TapGestureRecognizer();
                                  return Utils.checkedTypeEmpty(e["name"]) ? TextSpan(
                                    text: "@${e["name"]}",
                                    style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, fontSize: 15.5, height: 1.5),
                                    recognizer: user["id"] != e["value"] ? (_onTapMention..onTap = () => !isShift ? onShowUserInfo(context, e["value"]) : null) : null,
                                  ) : TextSpan(text: "");
                                } else {
                                  var _onTapMention = TapGestureRecognizer();
                                  if (e["type"] == "text") return renderText(e["value"]);
                                  return  TextSpan(
                                    text:  "${e["trigger"] ?? "@"}${e["name"]}",
                                    style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, fontSize: 15.5, height: 1.5),
                                    recognizer: user["id"] != e["value"] ? (_onTapMention..onTap = () => !isShift && e["type"] == "user" ? onShowUserInfo(context,e["value"]) : null) : null
                                  );

                                }
                              }
                            }).toList()
                          ),
                          widget.lastEditedAt != null
                          ? WidgetSpan(child: Tooltip(
                            child: TextWidget(" (edited)",style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Color(0xff6c6f71))),
                            message: widget.lastEditedAt,
                            decoration: ShapeDecoration(
                              shape: CustomBorder(),
                              color: isDark ? Palette.backgroundRightSiderLight : Palette.backgroundRightSiderDark
                            ),
                            preferBelow: false, verticalOffset: 10.0
                          ))
                          : TextSpan()
                        ]
                      ),
                      key: Key('AttachmentMentionItem${widget.id}')
                    ),
                    if (Utils.checkedTypeEmpty(value)) MessageCardDesktop(message: value, id: widget.id, onlyPreview: true)
                  ],
                );

              case "block_code":
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: att["data"].map<Widget>((e){
                    if (e["type"] == "block_code" && Utils.checkedTypeEmpty(e["value"].trim())) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isDark ? Color(0xff1E1E1E) : Color(0xffEDEDED),
                        ),
                        margin: EdgeInsets.only(right: 16, top: 4, bottom: 4),
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        child: RichTextWidget(
                          TextSpan(
                            text: e["value"],
                            style: TextStyle(
                              height: 1.67,
                              fontWeight: FontWeight.w300, fontSize: 14,
                              fontFamily: 'Menlo',
                              color: isDark ? Color.fromARGB(255, 198, 208, 224) : Palette.defaultTextLight
                            ),
                          ),
                          key: Key('AttachmentBlockCodeItem${widget.id}')
                        ),
                      );
                    }
                    if (e["type"] == "text" && e["value"] != "") {
                      return Container(
                        child: RichTextWidget(
                          TextSpan(
                            text: e["value"],
                            style: TextStyle(height: 1.5, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                          ),
                          key: Key('AttachmentItem${widget.id}')
                        )
                      );
                    } else {
                      return Container();
                    }
                  }).toList()
                );

              case "BizBanking":
                return BizBankingAttachments(att: att);

              case "bot":
                var appId  = att["bot"]["id"];
                var app =  appInChannel.where((element) => element["app_id"] == appId).toList();
                var appName  = " ";
                if (app.length > 0) appName = app[0]["app_name"];
                return Container(
                  margin: EdgeInsets.only(right: 60),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 35,
                            width: 35,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Color(0xFF1890FF),
                              borderRadius: BorderRadius.circular(5)
                            ),
                            child: TextWidget(
                              (att["bot"]["name"] ?? appName)[0].toString().toUpperCase(),
                              style: TextStyle(fontSize: 20, color: Color(0xFFFFFFFF)),
                              overflow: TextOverflow.ellipsis
                            ),
                          ),
                          Container(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextWidget(
                                  att["bot"]["name"] ?? appName,
                                  style : TextStyle(
                                    fontWeight:  FontWeight.w600,
                                    fontSize: 15,
                                    color: isDark ? Color(0xFFd8dcde) : Colors.grey[800]
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                                TextWidget(
                                  "/" + att["data"]["command"] + " ${att["data"]["text"] ?? ""}",
                                  style: TextStyle(
                                    color: Color(0xFFBFBFBF),
                                    fontSize: 10
                                  ),
                                  textAlign: TextAlign.left,
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      att["data"]["result"] != null ?
                        Container(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.all(5),
                          margin: EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: isDark ?  Color(0xff4f5660) : Color(0xFFf0f0f0),
                            borderRadius: BorderRadius.circular(5)
                          ),
                          child: TextWidget(
                            att["data"]["result"]["body"] ?? "",
                            style: TextStyle(fontSize: 10),
                            textAlign: TextAlign.left,
                          ),
                        )
                        : Container(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.all(5),
                          margin: EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: isDark ?  Color(0xff4f5660) : Color(0xFFf0f0f0),
                            borderRadius: BorderRadius.circular(5)
                          ),
                          child: TextWidget("Processing", style: TextStyle(fontSize: 10),),
                        ),
                      Container(height: 8)
                    ],
                  ),
                );

              case "invite":
                final channelId = (att["data"] ?? {})["channel_id"] ?? null;
                final workspaceId = (att["data"] ?? {})["workspace_id"];
                final inviteUser = (att["data"] ?? {})["invite_user"];
                final inviteUserName = (att["data"] ?? {})["full_name"];
                final channelName = (att["data"] ?? {})["channel_name"];
                final workspaceName = (att["data"] ?? {})["workspace_name"];
                final isAccepted = (att["data"] ?? {})["isAccepted"] ?? null;
                final bool isWorkspace = att["data"]["is_workspace"] ?? false;
                var userId = att["data"]["user_id_assign"];

                return Container(
                  margin: EdgeInsets.only(top: 4),
                  padding: EdgeInsets.only(bottom: 15),
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      att["attachments_v2"] ?? false ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: TextStyle(height: 1.57),
                              children: [
                                TextSpan(
                                  recognizer: new TapGestureRecognizer()..onTapUp = (_) => showInfo(context,userId),
                                  text: inviteUserName, style: TextStyle(fontWeight: FontWeight.w700)),
                                TextSpan(text: " has invite you to "),
                                TextSpan(text: isWorkspace ? workspaceName : channelName, style: TextStyle(fontWeight: FontWeight.w700)),
                                TextSpan(text: isWorkspace ? " workspace" :" channel"),
                              ]
                            )
                          ),
                          SizedBox(height: 4,)
                        ],
                      ) : SizedBox(),
                      Row(
                        children: [
                          Container(
                            width: 130,
                            child: TextButton(
                              style: ButtonStyle(
                                backgroundColor: isAccepted == null ? MaterialStateProperty.all(Colors.blue) : MaterialStateProperty.all(isDark ? Color(0xff5E5E5E): Color(0xffA6A6A6),
                                ),
                              ),
                              onPressed: isAccepted == null ? () async{
                                if (channelId != null) {
                                  Provider.of<Channels>(context, listen: false).joinChannelByInvitation(token, workspaceId, channelId, inviteUser, widget.id).then((value){
                                    showDialog(
                                      context: context,
                                      builder: (_) {
                                        return CupertinoAlertDialog(
                                          title: TextWidget(value),
                                        );
                                      },
                                    );
                                  }
                                );
                              } else {
                                Provider.of<Workspaces>(context, listen: false).joinWorkspaceByInvitation(token, workspaceId, user["email"], 1, inviteUser, widget.id).then((value) {
                                  showDialog(
                                    context: context,
                                    builder: (_) {
                                      return CupertinoAlertDialog(
                                        title: TextWidget(value),
                                      );
                                    }
                                  );
                                });
                              }
                            } : (){},
                            child: Container(
                              width: MediaQuery.of(context).size.width / 4,
                              child: Center(child: isAccepted == null || isAccepted == false ? TextWidget("Accept", style: TextStyle(color: Colors.white)) : TextWidget("Accepted", style: TextStyle(color: Color(0xffffffff))))
                            ),
                          ),
                        ),
                        SizedBox(width: 8,),
                        Container(
                          width: 130,
                          child: TextButton(
                            style: ButtonStyle(
                              backgroundColor: isAccepted == null ? MaterialStateProperty.all(Colors.red) : MaterialStateProperty.all(isDark ? Color(0xff5E5E5E): Color(0xffA6A6A6)),
                            ),
                            onPressed: isAccepted == null ? () {
                              if(channelId != null){
                                Provider.of<Channels>(context, listen: false).declineInviteChannel(token, workspaceId, channelId, inviteUser, widget.id).then((value){
                                  showDialog(
                                    context: context,
                                    builder: (_) {
                                      return CupertinoAlertDialog(
                                        title: TextWidget(value),
                                      );
                                    }
                                  );
                                });
                              }
                              else {
                                Provider.of<Workspaces>(context, listen: false).declineInviteWorkspace(token, workspaceId, inviteUser, widget.id).then((value){
                                  showDialog(
                                    context: context,
                                    builder: (_) {
                                      return CupertinoAlertDialog(
                                        title: TextWidget(value),
                                      );
                                    }
                                  );
                                });
                              }
                            } : () {},
                            child: Container(
                              width: MediaQuery.of(context).size.width / 4,
                              child: Center(child: isAccepted == null || isAccepted == true ? TextWidget("Discard",  style: TextStyle(color: Color(0xffffffff))) : TextWidget("Discarded",  style: TextStyle(color: Colors.black)))
                            ),
                          ),
                        )
                      ],
                      ),
                    ],
                  )
                );

              case "image":
                if (att["data"].length > 0)  {
                  var filename = att["data"].length == 1 ? att["data"][0]["name"] : "${att["data"].length} files";
                  filename = filename.trim() == "" ? "Image ${DateTime.parse(widget.message['insertedAt']).add(Duration(hours: 7))}.png" : filename;

                  return Collapse(
                    child: ImagesGallery(isChildMessage: widget.isChildMessage, att: att, isThread: widget.isThread, message: widget.message, isConversation: !widget.isChannel),
                    name: filename.toString()
                  );
                } else {
                  return Container();
                }

              case "assign":
                var channelId = att["data"]["channel_id"];
                var workspaceId = att["data"]["workspace_id"];
                var issueId = att["data"]["issue_id"];
                String assignUser = att["data"]["full_name"] ?? "";
                String channelName = att["data"]["channel_name"] ?? "";
                bool isAssign = att["data"]["assign"];
                var userId = att["data"]["user_id_assign"];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    att["attachments_v2"] ?? false ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            style: TextStyle(height: 1.57),
                            children: [
                              TextSpan(
                                recognizer: new TapGestureRecognizer()..onTapUp = (_) => showInfo(context,userId),
                                text: assignUser,
                                style: TextStyle(fontWeight: FontWeight.w700,color: isDark ? Palette.calendulaGold : Palette.dayBlue , fontSize: 15)
                              ),
                              TextSpan(text: " has ${isAssign ? "assign" : "unassign"} you in an issue in "),
                              TextSpan(text: channelName),
                              TextSpan(text: " channel"),
                            ]
                          )
                        ),
                        SizedBox(height: 4,)
                      ],
                    ) : SizedBox(),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(3)
                      ),
                      margin: EdgeInsets.only(top: 10),
                      padding: EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 50),
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () async {
                              var issue = await Provider.of<Channels>(context, listen: false).getIssue(token, workspaceId, channelId, issueId);
                              Provider.of<Workspaces>(context, listen: false).selectWorkspace(token, workspaceId, context);
                              Provider.of<Workspaces>(context, listen: false).getInfoWorkspace(token, workspaceId, context);
                              Provider.of<Channels>(context, listen: false).setCurrentChannel(issue["channelId"]);
                              Provider.of<Channels>(context, listen: false).onChangeOpenIssue({...issue, 'type': 'edited', 'comments': issue['comments'], 'timelines': issue['timelines'], 'fromMentions': true});
                              Provider.of<Auth>(context, listen: false).keyDrawer.currentState!.openEndDrawer();
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(Colors.tealAccent[100]),
                              fixedSize: MaterialStateProperty.all(Size.fromWidth(120))
                            ),
                            child: TextWidget("Review Issue", style: TextStyle(color: Colors.black87))
                          ),
                          TextButton(
                            onPressed: (){},
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(Colors.tealAccent[100]),
                              fixedSize: MaterialStateProperty.all(Size.fromWidth(120))
                            ),
                            child: TextWidget("Unassign", style: TextStyle(color: Colors.black87))
                          )
                        ],
                      ),
                    ),
                  ],
                );

              case "snappy_request":
                final data = att["data"];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => onShowUserInfo(context, data["sender_id"]),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 10, top: 5),
                        // child: Text.rich(
                        //   TextSpan(
                        //     style: TextStyle(height: 1.57),
                        //     children: []
                        //   )
                        // ),
                        child: TextWidget(widget.message['message'])
                      ),
                    ),
                    Container(
                      height: 32,
                      margin: EdgeInsets.only(right: 12, bottom: 5),
                      child: OutlinedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                        ),
                        onPressed: () => onReviewSnappyRequest(context, data, widget.id),
                        child: TextWidget(
                          data['form_title'],
                          style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                      ),
                    ),
                  ],
                );

              case "close_issue":
                var channelId = att["data"]["channel_id"];
                var workspaceId = att["data"]["workspace_id"];
                var issueId = att["data"]["issue_id"];
                var isClosed = att["data"]["is_closed"] ?? att["data"]["is_close"];
                var assignUser = att["data"]["assign_user"];
                var channelName = att["data"]["channel_name"];
                var issueAuthor = att["data"]["issue_author"] ?? "";
                var userId = att["data"]["user_id_assign"];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    att["attachments_v2"] ?? false ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            style: TextStyle(height: 1.57),
                            children: att["data"]["user_watching"] ?? false ? [
                              TextSpan(
                                recognizer: new TapGestureRecognizer()..onTapUp = (_) => showInfo(context,userId),
                                text: assignUser,
                                style: TextStyle(fontWeight: FontWeight.w700,color: isDark ? Palette.calendulaGold : Palette.dayBlue , fontSize: 15)),
                              TextSpan(text: " has ${isClosed ? "closed" : "reopen"} an issue "),
                              TextSpan(text: issueAuthor, style: TextStyle(fontWeight: FontWeight.w500)),
                              TextSpan(text: " created in "),
                              TextSpan(text: channelName),
                              TextSpan(text: " channel"),
                            ] : [
                              TextSpan(
                                recognizer: new TapGestureRecognizer()..onTapUp = (_) => showInfo(context,userId),
                                text: assignUser,
                                style: TextStyle(fontWeight: FontWeight.w700,color: isDark ? Palette.calendulaGold : Palette.dayBlue , fontSize: 15)),
                              TextSpan(text: " has ${isClosed ? "closed" : "reopen"} an issue you has been assign in "),
                              TextSpan(text: channelName),
                              TextSpan(text: " channel"),
                            ]
                          )
                        ),
                        SizedBox(height: 4,)
                      ],
                    ) : SizedBox(),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(3)
                      ),
                      margin: EdgeInsets.only(top: 10),
                      padding: EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 50),
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            child: TextWidget("Review issue", style: TextStyle(color: Colors.white)),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(Colors.red),
                              fixedSize: MaterialStateProperty.all(Size.fromWidth(120))
                            ),
                            onPressed: () async {
                              var issue = await Provider.of<Channels>(context, listen: false).getIssue(token, workspaceId, channelId, issueId);
                              Provider.of<Workspaces>(context, listen: false).selectWorkspace(token, workspaceId, context);
                              Provider.of<Workspaces>(context, listen: false).getInfoWorkspace(token, workspaceId, context);
                              Provider.of<Channels>(context, listen: false).setCurrentChannel(channelId);
                              Provider.of<Channels>(context, listen: false).onChangeOpenIssue({...issue, 'type': 'edited', 'comments': issue['comments'], 'timelines': issue['timelines'], 'fromMentions': true});
                              Provider.of<Auth>(context, listen: false).keyDrawer.currentState!.openEndDrawer();
                            },
                          ),
                          TextButton(
                            child: TextWidget(isClosed ? "Reopen issue" : "Close issue", style: TextStyle(color: Colors.white)),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(Colors.grey), fixedSize: MaterialStateProperty.all(Size.fromWidth(120)),
                            ),
                            onPressed: (){},
                          )
                        ]
                      ),
                    ),
                  ],
                );
              case "call_terminated":
                String timerCounter = att["data"]["timerCounter"] ?? "0:00";
                String mediaType = att["data"]["mediaType"] ?? "video";
                return Container(
                  padding: EdgeInsets.all(20.0),
                  width: 150,
                  decoration: BoxDecoration(
                    color: isDark ?Colors.white38 : Colors.grey,
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Icon(mediaType == "video" ? PhosphorIcons.videoCameraLight : PhosphorIcons.phoneThin),
                          TextWidget(timerCounter),
                        ],
                      ),
                      Divider(thickness: 1.0, color: Colors.white),
                      TextButton(
                        onPressed: (){
                          final indexOtherUser = dm.user.indexWhere((e) => e["user_id"] != user["id"]);
                          final otherUser = indexOtherUser == -1 ? {} : dm.user[indexOtherUser];

                          if (mediaType == "video") {
                            p2pManager.createVideoCall(context, otherUser, dm.id);
                          } else if (mediaType == "audio") {
                            p2pManager.createAudioCall(context, otherUser, dm.id);
                          }
                        },
                        child: TextWidget("Gọi lại", style: TextStyle(color: isDark ? Colors.white : Colors.black),),
                      ),
                    ],
                  ),
                );
              case 'sticker':
                return StickerFile(key: Key(widget.id.toString()), data: att['data']);

              default:
                switch (att["mime_type"]) {
                  case "share":
                    if(att["data"]["channelId"] != null) {
                      // final channel = channels.firstWhere(((ele) => ele["id"] == att["data"]["channelId"]));
                      int indexChannel = channels.indexWhere((ele) => ele["id"] == att["data"]["channelId"]);
                      return indexChannel != -1 ? ShareAttachments(att: att, channel: channels[indexChannel]) : ShareAttachments(att: att);
                    } else {
                      return ShareAttachments(att: att);
                  }
                  case "shareforwar":
                  if(att["data"]["channelId"] != null) {
                    // final channel = channels.firstWhere(((ele) => ele["id"] == att["data"]["channelId"]));
                    int indexChannel = channels.indexWhere((ele) => ele["id"] == att["data"]["channelId"]);
                    return indexChannel != -1 ? ShareAttachments(att: att, channel: channels[indexChannel]) : ShareAttachments(att: att);
                    } else {
                      return ShareAttachments(att: att);
                  }
                  case "image":
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
                            pageBuilder: (context, _, __) => ImageDetail(url: att["content_url"], id: widget.id, full: true, tag: tag, keyEncrypt: att["key_encrypt"], version: att["version"])
                          )
                        );
                      },
                      child: att["content_url"] == null
                        ? TextWidget("Message unavailable", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13, fontWeight: FontWeight.w200))
                        : Hero(
                          tag: tag,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: 400,
                              maxHeight: 400,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 5),
                            child: CachedImage(
                              att["content_url"],
                              radius: 5,
                              fit: BoxFit.contain
                            )
                          ),
                        )
                    );
                  case "mov":
                  case "MOV":
                  case "MP4":
                  case "mp4":
                    if (att["content_url"] != null){
                      var url = att["content_url"].toLowerCase();
                      if (url.contains(".mov") || url.contains(".mp4") || url.contains("flv") || url.contains("avi")) {
                        return Collapse(
                          child: VideoPlayer(att: att),
                          name: att["name"].toString()
                        );
                      } else {
                        return renderFile(att, isDark);
                      }
                    }              
                    else return renderFile(att, isDark);
                  case "html":
                    return Container(
                      margin: EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isDark ? Color(0xff2E2E2E) : Color(0xffDBDBDB)
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      width: isOnThreads
                        ? widget.isChildMessage || widget.isThread ? 260 : deviceWidth - 420
                        : widget.isChildMessage || widget.isThread ? 260 :  deviceWidth - 420 - (showDirectSetting || showChannelSetting || openThread ? 330 : 0),
                      child: RichTextWidget(
                        TextSpan(
                          text: widget.snippet,
                          style: TextStyle(
                            fontWeight: FontWeight.w300, fontSize: 14, height: 1.75,
                            color: isDark ? Colors.white70 : Colors.grey[800]
                          ),
                          children: [
                            TextSpan(
                              text: "\nSee more ...",
                              style: TextStyle(fontWeight: FontWeight.w300, fontSize: 13, color: Colors.blueAccent),
                              recognizer: TapGestureRecognizer()..onTapUp = !isShift ? (_) => launch(att["content_url"]) : null,
                            )
                          ],
                        ),
                        key: Key('AttachmentItem${widget.id}')
                      )
                    );

                  case "m4a":
                  case 'mp3':
                  case 'wav':
                  case 'm3u':
                    // if (Platform.isWindows || Platform.isLinux) return renderFile(att, isDark);
                    return Container(
                      width: 600,
                      child: !widget.isChannel ? RecordDirect.build(context, att) : AudioPlayerMessage(
                        source: UrlSource(att["content_url"]),
                        att: att
                      ),
                    );

                  default:
                    String type = Utils.getLanguageFile((att["mime_type"] ?? '').toLowerCase());
                    int index = Utils.languages.indexWhere((ele) => ele == type);

                    return (index != -1 && att['preview'] != null) ? TextFile(att: att, isChannel: widget.isChannel) : renderFile(att, isDark);
                }
            }
          }
        ).toList(),
      )
    );
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
}

class MentionIssue extends StatefulWidget {
  MentionIssue({
    Key? key,
    this.e,
    this.onShowIssueInfo
  }) : super(key: key);

  final e;
  final onShowIssueInfo;

  @override
  _MentionIssueState createState() => _MentionIssueState();
}

class _MentionIssueState extends State<MentionIssue> {
  var hoveringIssue;
  bool getDataIssue = false;
  String message = "";
  bool accessIssue = true;

  @override
  void initState() {
    super.initState();

    try {
      List preloadIssues = Provider.of<Workspaces>(context, listen: false).preloadIssues;
      final index = widget.e["value"].split("-").length > 2 ?
        preloadIssues.indexWhere((e) => e["id"].toString() == widget.e["value"].split("-")[0].toString()
        && e["channel_id"].toString() == widget.e["value"].split("-")[2].toString()) : -1;
      accessIssue = index != -1;
    } catch (e) {
      print("get access issue ${e.toString()}");
    }
  }

  onHovering(value) async {
    if (this.mounted){
      this.setState(() {
        hoveringIssue = value;
      });
    }

    if (!getDataIssue && value != null) {
      try {
        final token = Provider.of<Auth>(context, listen: false).token;
        var issueId = value.split("-")[0];
        var workspaceId = value.split("-")[1];
        var channelId = value.split("-")[2];
        final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/get_access_issue?token=$token&issue_id=$issueId';
        final response = await Utils.getHttp(url);

        if (response["success"] == true) {
        } else {
          setState(() {
            message = response['message'] ?? "";
          });
        }
        getDataIssue = true;
      } catch (e) {
        print("onHovering attachment_card_desktop ${e.toString()}");
        getDataIssue = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.e;
    final isDark  = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return PortalTarget(
      anchor: Aligned(
        target: Alignment.topCenter,
        follower: Alignment.bottomCenter
      ),
      visible: e["value"] == hoveringIssue,
      portalFollower: message == "" ? Container() : Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Color(0xff1E1E1E),
          borderRadius: BorderRadius.all(Radius.circular(4))
        ),
        child: TextWidget(message, style: TextStyle(color: Palette.defaultTextDark)),
      ),
      child: InkWell(
        onTap: accessIssue ? () {
          widget.onShowIssueInfo(e);
        } : null,
        child: MouseRegion(
          onExit: (value) { onHovering(null); },
          onEnter: (value) { onHovering(e["value"]); },
          child: Container(
            height: 21.5,
            child: TextWidget(
              "#${e["name"]}",
              style: TextStyle(color: accessIssue ? (isDark ? Palette.calendulaGold : Palette.dayBlue) : Colors.grey[600], fontSize: 15.2, height: 1.5)
            ),
          )
        )
      )
    );
  }
}

onReviewSnappyRequest(context, data, messageId) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;

  handleRequest(data, status) async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final workspaceId = data["workspace_id"];

    final body = {
      'message_id': messageId,
      'request_id': data['id'],
      'sender_id': data['sender_id'],
      'status': status
    };
    final url = Utils.apiUrl + 'workspaces/$workspaceId/handle_request?token=$token';
    try {
      final response = await Dio().post(url, data: body);
      var dataRes = response.data;
      if (dataRes["success"]) {
        Navigator.of(context, rootNavigator: true).pop("Discard");
      }
    } catch (e) {
      print("Error Channel: $e");
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  showModal(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0)),
        title: Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xff5E5E5E).withOpacity(0.5) : Color(0xffF3F3F3),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(4.0),
              topLeft: Radius.circular(4.0)
            )
          ),
          child: Container(
            padding: const EdgeInsets.only(top: 9, bottom: 9, left: 16),
            child: TextWidget("Review", style: TextStyle(fontSize: 16))
          ),
        ),
        titlePadding: const EdgeInsets.all(0),
        backgroundColor: isDark ? Palette.backgroundTheardDark : Colors.white,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 600,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ...data["form_submit"].map((e) {
                  return Container(
                    padding: EdgeInsets.all(10),
                    child: Utils.renderElementForm(context, e, isDark)
                  );
                }).toList(),
                data['status'] == "PENDING" ? Container(
                  decoration: BoxDecoration(border: Border(top: BorderSide(width: 0.2, color: Colors.grey))),
                  padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 11),
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 100, height: 32,
                        margin: EdgeInsets.only(right: 12),
                        child: OutlinedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                          ),
                          onPressed: () => handleRequest(data, "APPROVED"),
                          child: TextWidget(
                            'Duyệt',
                            style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                        ),
                      ),
                      Container(
                        width: 100, height: 32,
                        margin: EdgeInsets.only(right: 12),
                        child: OutlinedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Colors.red),
                          ),
                          onPressed: () => handleRequest(data, "CANCELED"),
                          child: TextWidget(
                            'Từ chối',
                            style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                        ),
                      ),
                    ],
                  ),
                ) : Container(
                  decoration: BoxDecoration(border: Border(top: BorderSide(width: 0.2, color: Colors.grey))),
                  padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 11),
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      data['status'] == "APPROVED"
                        ? Icon(CupertinoIcons.checkmark_seal, color: Colors.green)
                        : Icon(CupertinoIcons.xmark_seal, color: Colors.red),
                      SizedBox(width: 5),
                      TextWidget(data['status'] == "APPROVED" ? "Đã phê duyệt" : "Đã huỷ")
                    ],
                  ),
                ),
              ],
            ),
          )
        ),
      );
    }
  );
}