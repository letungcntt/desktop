import 'dart:async';

import 'package:context_menus/context_menus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/focus_inputbox_manager.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/progress.dart';
import 'package:workcake/common/styles.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/draggable_scrollbar.dart';
import 'package:workcake/components/message_item/attachment_card_desktop.dart';
import 'package:workcake/components/message_item/forward_message.dart';
import 'package:workcake/components/message_item/message_card_desktop.dart';
import 'package:workcake/components/profile/user_profile_desktop.dart';
import 'package:workcake/components/reactions_dialog.dart';
import 'package:workcake/components/widget_text.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/emoji/itemEmoji.dart';
import 'package:workcake/models/models.dart';

class ChatItemMacOS extends StatefulWidget {
  final message;
  final isMe;
  final avatarUrl;
  final insertedAt;
  final fullName;
  final id;
  final isFirst;
  final isLast;
  final attachments;
  final count;
  final isChannel;
  final onEditMessage;
  final parentId;
  final isChildMessage;
  final userId;
  final width;
  final isThread;
  final infoThread;
  final success;
  final showHeader;
  final isSystemMessage;
  final isBlur;
  final showNewUser;
  final updateMessage;
  final reactions;
  final snippet;
  final blockCode;
  final conversationId;
  final channelId;
  final isViewMention;
  final bool isViewThread;
  final idMessageToJump;
  final lastEditedAt;
  final isUnsent;
  final onFirstFrameDone;
  final firstMessage;
  final Function? onShareMessage;
  final isDark;
  final isUnreadThreadMessage;
    // truong nay dc su dung khi tin nhan DM ko the giai ma va dang doi dc gui lai
  final waittingForResponse;
  final currentTime;
  final customColor;
  final isDirect;
  final accountType;
  final isAfterThread;
  final bool isShow;
  final GlobalKey<DraggableScrollbarState>? keyScroll;
  final bool isFetchingUp;
  final bool isFetchingDown;

  ChatItemMacOS({
    Key? key,
    required this.id,
    required this.message,
    required this.avatarUrl,
    required this.insertedAt,
    required this.fullName,
    required this.attachments,
    required this.isChannel,
    required this.userId,
    required this.isThread,
    required this.reactions,
    required this.isViewMention,
    this.isDirect,
    this.isMe,
    this.count,
    this.isFirst,
    this.isLast,
    this.onEditMessage,
    this.parentId,
    this.isChildMessage,
    this.width,
    this.infoThread,
    this.success = true,
    this.showHeader,
    this.isSystemMessage = false,
    this.isBlur,
    this.updateMessage,
    this.showNewUser,
    this.snippet,
    this.blockCode,
    this.conversationId, 
    this.channelId,
    this.isViewThread = false, 
    this.idMessageToJump,
    this.lastEditedAt,
    this.isUnsent,
    this.onFirstFrameDone,
    this.firstMessage,
    this.onShareMessage,
    required this.isDark,
    this.waittingForResponse,
    this.isUnreadThreadMessage,
    this.currentTime,
    this.customColor,
    this.accountType,
    this.isAfterThread = false,
    this.isShow = true,
    this.keyScroll,
    this.isFetchingUp = false,
    this.isFetchingDown = false,
  }) : super(key: key);

  @override
  _ChatItemMacOSState createState() => _ChatItemMacOSState();
}

class _ChatItemMacOSState extends State<ChatItemMacOS> {
  bool showMenu =  false;
  bool showMore = false;
  bool showEmoji = false;
  Color colorMention = Color(0xFFffffff);
  bool isShift = false;
  bool showDetail = false;
  var isHover = false;
  bool isHighlightMessage = false;
  bool isChecked = false;

  @override
  void initState(){
    super.initState();
    Timer.run(()async{

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(this.mounted && widget.onFirstFrameDone != null)
        widget.onFirstFrameDone(this.context, widget.currentTime,widget.id);
        if (widget.id == widget.idMessageToJump)  {
          setHighlightMessage();
        }
      });
    });
    RawKeyboard.instance.addListener(handleKey);
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
  renderInfoThread() {
    final List<dynamic> infoThread = widget.infoThread;
    final lastReply = infoThread[0]["inserted_at"] ?? infoThread[0]["time_create"];
    final auth = Provider.of<Auth>(context);
    List users = [];

    for (var i = 0; i < infoThread.length; i++) {
      if (users.indexWhere((e) => e["user_id"] == infoThread[i]["user_id"]) == -1) {
        users.add(infoThread[i]);
      }
    }

    users = (users.length >= 4 ? users.sublist(0, 4) : users).reversed.toList();

    DateTime dateTime = DateTime.parse(lastReply);
    final messageTime = DateFormat('kk:mm').format(DateTime.parse(lastReply).add(Duration(hours: 7)));
    final dayTime = DateFormatter().getVerboseDateTimeRepresentation(dateTime, auth.locale);

    final messageLastTime = (lastReply != "" && lastReply != null)
      ? "${dayTime == "Today" ? messageTime : DateFormatter().renderTime(DateTime.parse(widget.insertedAt), type: "MMMd") + " at $messageTime"}"
      : "";
    final dataInfoThreadMessage = Provider.of<DirectMessage>(context, listen: false).dataInfoThreadMessage;

    final int lengthUser = users.length > 4 ? 4 : users.length;
    double widthRenderAvatar = 0.0;

    switch (lengthUser) {
      case 4:
        widthRenderAvatar = lengthUser * 18.0;
        break;
      case 3:
        widthRenderAvatar = lengthUser * 20.0;
        break;
      case 2:
        widthRenderAvatar = lengthUser * 22.0;
        break;
      case 1:
        widthRenderAvatar = lengthUser * 26.0;
        break;
    }

    return Container(
      margin: EdgeInsets.only(top: 6),
      child: InkWell(
        onTap: () => openThreadAction(context),
        child: Container(
          height: 22,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: widthRenderAvatar,
                child: Stack(
                  alignment: AlignmentDirectional.centerEnd,
                  children: [
                    users.length <= 3 ? Container() : 
                    Positioned(
                      right: 45,
                      child: Container(
                        margin: EdgeInsets.only(right: 4),
                        child: CachedAvatar(
                          users[3]["avatar_url"],
                          height: 22, width: 22,
                          isRound: true,
                          isAvatar: true,
                          name: users[3]["full_name"],
                          fontSize: 10
                        )
                      )
                    ),
                    users.length <= 2 ? Container() : 
                    Positioned(
                      right: 30,
                      child: Container(
                        margin: EdgeInsets.only(right: 4),
                        child: CachedAvatar(
                          users[2]["avatar_url"],
                          height: 22, width: 22,
                          isRound: true,
                          isAvatar: true,
                          name: users[2]["full_name"],
                          fontSize: 10
                        )
                      )
                    ),
                    users.length <= 1 ? Container() : 
                    Positioned(
                      right: 15,
                      child: Container(
                        margin: EdgeInsets.only(right: 4),
                        child: CachedAvatar(
                          users[1]["avatar_url"],
                          height: 22, width: 22,
                          isRound: true,
                          isAvatar: true,
                          name: users[1]["full_name"],
                          fontSize: 10
                        )
                      )
                    ),
                    users.length == 0 ? Container() :
                    Container(
                      margin: EdgeInsets.only(right: 4),
                      child: CachedAvatar(
                          users[0]["avatar_url"],
                          height: 22, width: 22,
                          isRound: true,
                          isAvatar: true,
                          name: users[0]["full_name"],
                          fontSize: 10
                        )
                    )
                  ]
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: 4),
                child: Text("${widget.count} ${widget.count > 1 ? "replies" : "reply"}", style: TextStyle(fontSize: 11, color: Colors.lightBlue[400])),
              ),
              Container(
                margin: EdgeInsets.only(left: 5, right: 8),
                child: Text(
                  "Last reply at $messageLastTime",
                  style: TextStyle(fontSize: 11, color: Color(0xFF6a6e74)),
                  overflow: TextOverflow.ellipsis
                )
              ),
              ((dataInfoThreadMessage[widget.id] ?? {})["is_read"] ?? true) ? Text("") : Text("NEW", style: TextStyle(fontSize: 11, color: Colors.red))
            ]
          )
        )
      )
    );
  }

  getUser(userId) {
    List users = Provider.of<Workspaces>(context, listen: false).members;

    if (!widget.isChannel){
      var indexConversation = Provider.of<DirectMessage>(context, listen: false).data.indexWhere((element) => element.id == widget.conversationId);
      if (indexConversation == -1) users = [];
      else users = Provider.of<DirectMessage>(context, listen: false).data[indexConversation].user;
    }

    int index = users.indexWhere((e) => e["id"] == userId || e["user_id"] == userId);
    if (index != -1) {
      roleId = users[index]["role_id"];
      return {
        "avatar_url": users[index]["avatar_url"],
        "full_name": users[index]["full_name"],
        "role_id": users[index]["role_id"],
        "custom_color": users[index]["custom_color"]
      };
    } else {
      return {
        "avatar_url": "",
        "full_name": "Bot"
      };
    }
  }

  showInfo(context, id) {
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    if (id != null && currentUser["id"] != id) onShowUserInfo(context, id);
  }

  renderSystemMessage(attachments) {
    final isDark  = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final messageTime = DateFormat('kk:mm').format(DateTime.parse(widget.insertedAt).add(Duration(hours: 7)));

    return Container(
      margin: EdgeInsets.only(top: 5, bottom: 15),
      child: Column(
        children:
          attachments.map<Widget>((att) {
            final params = att["params"];

            switch (att["type"]) {
              case "datetime" :
                final lastMessageReaded = !widget.isChannel ?
                  (Provider.of<DirectMessage>(context, listen: true).getCurrentDataDMMessage(widget.conversationId) ?? {})["last_message_readed"] :
                  Provider.of<Channels>(context, listen: true).currentChannel["last_message_readed"];

                return Container(
                  margin: EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          height: 40,
                          thickness: 1,
                          color: (lastMessageReaded != null && att["id"] == lastMessageReaded) ? Colors.red[400] : isDark ? Color(0xff707070) : Color(0xFFB7B7B7)
                        )
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Center(
                          child: Text(
                            DateFormatter().getVerboseDateTimeRepresentation(DateFormat("yyyy-MM-dd").parse(att["value"]), null).toUpperCase(),
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w400,
                              color: isDark ? Color(0xff707070) : Colors.grey[800]
                            )
                          )
                        )
                      ),
                      Expanded(
                        child: Divider(
                          height: 40,
                          thickness: 1,
                          color: (lastMessageReaded != null && att["id"] == lastMessageReaded) ? Colors.red[400] : isDark ? Color(0xff707070) : Color(0xFFB7B7B7)
                        )
                      ),
                      (lastMessageReaded != null && att["id"] == lastMessageReaded) ? Container(
                        margin: EdgeInsets.only(left: 14, right: 20), 
                        child: Text("NEW", style: TextStyle(color: Colors.red)),
                      ) : Container()
                    ]
                  )
                );

              case "header_message_converastion": 
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            height: 40,
                            color: isDark ? Color(0xff707070) : Color(0xFFB7B7B7)
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            DateFormatter().getVerboseDateTimeRepresentation(DateFormat("yyyy-MM-dd").parse(widget.insertedAt), null).toUpperCase(),
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w400,
                              color: isDark ? Color(0xff707070) : Colors.grey[800]
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            height: 40,
                            color: isDark ? Color(0xff707070) : Color(0xFFB7B7B7)
                          )
                        )
                      ]
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFFcfba91) : Color(0xFFFFF7E6),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        border: Border.all(color: Color(0xFFFFD591))
                      ),
                      child: Text(att["data"], style: TextStyle(color: Colors.black.withOpacity(0.65)))
                    )
                  ]
                );

              case "create_channel":
                String listName = att["data_member"] != null ? att["data_member"].map((ele) => ele["full_name"]).toList().join(", ") : "";
                return Column(
                  children: [
                  Text.rich(
                      TextSpan( 
                        children: <InlineSpan>[ 
                          TextSpan(
                            text: att["user"], style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                            recognizer: TapGestureRecognizer()..onTapUp = (_) => showInfo(context, att["user_id"])
                          ),
                          TextSpan(text: " has created a channel: ", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13)),
                          TextSpan(text: "${params["name"]}", style: TextStyle(color: Colors.grey[700])),
                          TextSpan(text: " at $messageTime. ", style: TextStyle(fontSize: 13, color: Color(0xFF6a6e74), fontWeight: FontWeight.w400)),
                        ]
                      ),
                    ),
                    if (att["data_member"] != null && att["data_member"].length > 0) 
                    Text.rich(
                      TextSpan( 
                        children: <InlineSpan>[ 
                          TextSpan(text: listName, style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13)),
                          TextSpan(text: " has invited by ${att["user"]}",style: TextStyle(color: Colors.grey[700]))
                        ]
                      )
                    )
                  ],
                );

              case "invite":
                return att["user"] == att["invited_user"] ? Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: att["invited_user"],
                        style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, fontSize: 14),
                        recognizer: TapGestureRecognizer()..onTapUp = (_) => showInfo(context, att["invited_user_id"])
                      ),
                      TextSpan(text: " has joined the channel by invitation code", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      TextSpan(text: " at $messageTime", style: TextStyle(fontSize: 13, color: Color(0xFF6a6e74), fontWeight: FontWeight.w400))
                    ]
                  )
                ) : Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: att["user"], style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, fontSize: 14),
                        recognizer: TapGestureRecognizer()..onTapUp = (_) => showInfo(context, att["user_id"])
                      ),
                      TextSpan(text: " has invited ", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13)),
                      TextSpan(
                        text: att["invited_user"], style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, fontSize: 14),
                        recognizer: TapGestureRecognizer()..onTapUp = (_) => showInfo(context, att["invited_user_id"])
                      ),
                      TextSpan(text: " to channel", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      TextSpan(text: " at $messageTime", style: TextStyle(fontSize: 13, color: Color(0xFF6a6e74), fontWeight: FontWeight.w400)),
                    ]
                  )
                );
              case "invite_direct":
                return Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: att["user"], style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, fontSize: 14),
                        recognizer: TapGestureRecognizer()..onTapUp = (_) => showInfo(context, att["user_id"])
                      ),
                      TextSpan(text: " has invite ", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13)),
                      TextSpan(
                        text: att["invited_user"], style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, fontSize: 14),
                        recognizer: TapGestureRecognizer()..onTapUp = (_) => showInfo(context, att["invited_user_id"])
                      ),
                      TextSpan(text: " to this conversation", style: TextStyle(color: Colors.grey[500],fontStyle: FontStyle.italic, fontSize: 13)),
                      TextSpan(text: " at $messageTime", style: TextStyle(fontSize: 13, color: Color(0xFF6a6e74), fontWeight: FontWeight.w400)),
                    ]
                  )
                );
              case "update_conversation":
                return Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: att["user"]['name'], style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, fontSize: 14),
                        recognizer: TapGestureRecognizer()..onTapUp = (_) => showInfo(context, att["user"]['id'])
                      ),
                      TextSpan(text: "  has changed ${att['avatar_url'] != null ? 'avatar' : 'name'} this group ", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13)),
                    ]
                  )
                );
              case "leave_direct":
                return Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: att["user"], style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, fontSize: 14),
                        recognizer: TapGestureRecognizer()..onTapUp = (_) => showInfo(context, att["user_id"])
                      ),
                      TextSpan(text: " has left ", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13)),
                      TextSpan(text: "this conversation", style: TextStyle(color: Colors.grey[500],fontStyle: FontStyle.italic, fontSize: 13)),
                      TextSpan(text: " at $messageTime", style: TextStyle(fontSize: 13, color: Color(0xFF6a6e74), fontWeight: FontWeight.w400)),
                    ]
                  )
                );
              case "leave_channel":
                return Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: att["user"], style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, fontSize: 14),
                        recognizer: TapGestureRecognizer()..onTapUp = (_) => showInfo(context, att["user_id"])
                      ),
                      TextSpan(text: " has left the channel", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13)),
                      TextSpan(text: " at $messageTime", style: TextStyle(fontSize: 13, color: Color(0xFF6a6e74), fontWeight: FontWeight.w400)),
                    ]
                  )
                );
              case "delete":
                return Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: att["delete_user_name"], style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, fontSize: 14),
                        recognizer: TapGestureRecognizer()..onTapUp = (_) => showInfo(context, att["delete_user_id"])
                      ),
                      TextSpan(text: " was kicked from this channel", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13)),
                      TextSpan(text: " at $messageTime", style: TextStyle(fontSize: 13, color: Color(0xFF6a6e74), fontWeight: FontWeight.w400)),
                    ]
                  )
                );
              case "change_topic":
                return Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: Utils.getUserNickName(att["user_id"]) ?? att["user_name"], style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                        recognizer: TapGestureRecognizer()..onTapUp = (_) => showInfo(context, att["user_id"])
                      ),
                      TextSpan(text: " has changed channel topic to ", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13)),
                      TextSpan(text: params["topic"], style: TextStyle(color: Colors.grey[700])),
                      TextSpan(text: " at $messageTime", style: TextStyle(fontSize: 13, color: Color(0xFF6a6e74), fontWeight: FontWeight.w400))
                    ]
                  )
                );
              case "change_name":
                return Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: Utils.getUserNickName(att["user_id"]) ?? att["user_name"], style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                        recognizer: TapGestureRecognizer()..onTapUp = (_) => showInfo(context, att["user_id"])
                      ),
                      TextSpan(text: " has changed channel name to ", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13)),
                      TextSpan(text: params["name"], style: TextStyle(color: Colors.grey[700])),
                      TextSpan(text: " at $messageTime", style: TextStyle(fontSize: 13, color: Color(0xFF6a6e74), fontWeight: FontWeight.w400))
                    ]
                  )
                );
              case "change_private":
                return Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: Utils.getUserNickName(att["user_id"]) ?? att["user_name"], style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                        recognizer: TapGestureRecognizer()..onTapUp = (_) => showInfo(context, att["user_id"])
                      ),
                      TextSpan(text: " has changed channel private to ", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13)),
                      TextSpan(text: "${params["is_private"] ? "private" : "public"}", style: TextStyle(color: Colors.grey[700])),
                      TextSpan(text: " at $messageTime", style: TextStyle(fontSize: 13, color: Color(0xFF6a6e74), fontWeight: FontWeight.w400))
                    ]
                  )
                );

              case "archived":
                return  Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: Utils.getUserNickName(att["user_id"]) ?? att["user_name"], style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                        recognizer: TapGestureRecognizer()..onTapUp = (_) => showInfo(context, att["user_id"])
                      ),
                      TextSpan(text: " has ", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13)),
                      TextSpan(text: "${params["is_archived"] ? "archived" : "unarchived"}", style: TextStyle(color: Colors.grey[700])),
                      TextSpan(text: " this channel", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13)),
                      TextSpan(text: " at $messageTime", style: TextStyle(fontSize: 13, color: Color(0xFF6a6e74), fontWeight: FontWeight.w400))
                    ]
                  )
                );

              case "change_workflow":
                return  Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: Utils.getUserNickName(att["user_id"]) ?? att["user_name"], style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                        recognizer: TapGestureRecognizer()..onTapUp = (_) => showInfo(context, att["user_id"])
                      ),
                      TextSpan(text: " has changed channel workflow to ", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13)),
                      TextSpan(text: "${params["kanban_mode"] ? "Kanban mode" : "Dev mode"}", style: TextStyle(color: Colors.grey[700])),
                      TextSpan(text: " at $messageTime", style: TextStyle(fontSize: 13, color: Color(0xFF6a6e74), fontWeight: FontWeight.w400))
                    ]
                  )
                );
                
              default: 
                return Container();
              }
            }
        ).toList(),
      ),
    );
  }

  renderOtherReaction(List users){
    final userId = Provider.of<Auth>(context, listen: false).userId;
    List channelMembers = Provider.of<Channels>(context, listen: false).getDataMember(widget.channelId);
    bool isMe = users.indexWhere((element) => element == userId) != -1;
    String name = isMe ? "You" :  "";

    // List memberReaction = users.length > 2 ? users.sublist(0, 1) : users;
    var memberReaction;
    if(isMe && users.length == 2) {
      memberReaction = users.where((element) => element != userId).toList();
    }
    else {
      memberReaction = users.length > 2 ? users.where((element) => element != userId).toList().sublist(0, 1) : users;
    }
    
    var otherName = memberReaction.where((userId) => userId != Provider.of<Auth>(context, listen: false).userId)
    .map((userId) {
      try {
        var index = channelMembers.indexWhere((element) => element["id"] == userId);
        return channelMembers[index]["nickname"] ?? channelMembers[index]["full_name"];
      } catch (e) {
        return "";
      }
    }).toList().join(", ");

    final condition = (users.length - memberReaction.length - 1) > 0;
    if (users.length > 1 && (users.length - memberReaction.length) > 0) {
      if (name != "") {
        return name + (otherName != "" ? ", " : "") + otherName + "${condition ? " and " : ""}" + "${condition ? (users.length - memberReaction.length - 1) : ""}" + "${condition ? (users.length - memberReaction.length) <= 2 ? " other" : " others" : ""}";
      } else {
        return otherName + " and" + " ${users.length - memberReaction.length} " + "${users.length - memberReaction.length == 1 ? "other" : "others"}";
      }
    } else {
      if(name != "") {
        return name + (otherName != "" ? ", " : "") + otherName;
      } else {
        return otherName;
      }
    }
  }

  onChangeIsHover(bool value) {
    setState(() {
      isHover = value;
      rebuild = false;
    });

    Future.delayed(Duration.zero, () {
      if(this.mounted) {
        setState(() => rebuild = false);
      }
    });
  }

  renderReactions(List reactions, List workspaceEmojiData){
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    return Container(
      child: HoverItem(
        onHover: () => onChangeIsHover(true),
        onExit: () => onChangeIsHover(false),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Wrap(
              alignment: WrapAlignment.start,
              children: reactions.map((e){
                bool isMe = e["users"].indexWhere((element) => element == Provider.of<Auth>(context, listen: false).userId) != -1;
                final id = e["emoji"] is ItemEmoji ? e["emoji"].id : e["emoji"]["id"];

                return HoverItem(
                  key: Key("reaction_$id"),
                  showTooltip: true,
                  tooltip: Container(
                    color: isDark ? Color(0xFF1c1c1c): Colors.white,
                    child: Column(
                      children: [
                        Text(
                          "${renderOtherReaction(e["users"])}",
                          style: TextStyle(
                            fontSize: 12, 
                            color: isDark ? Colors.white : Colors.black, 
                            decoration: TextDecoration.none, 
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      ],
                    ),
                  ), 
                  colorHover: null,
                  child: GestureDetector(
                    onTap: (){
                      final channelId = widget.isChannel ? widget.channelId : null;
                      final workspaceId = widget.isChannel ? Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"] : null;
                      Provider.of<Messages>(context, listen: false).handleReactionMessage({
                        "emoji_id": id,
                        "message_id": widget.id,
                        "channel_id": channelId,
                        "workspace_id": workspaceId,
                        "user_id": Provider.of<Auth>(context, listen: false).userId,
                        "token": Provider.of<Auth>(context, listen: false).token,
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(top: 4),
                      child: Container(
                        padding: EdgeInsets.only(top: 4, left: 4, right: 4),
                        margin: EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isMe ? (isDark ? Color(0xffFAAD14) : Color(0xff91D5FF)) : Colors.transparent,
                            width: 1.5
                          ),
                          color: isMe
                            ? isDark ? Color(0xffFFF1B8).withOpacity(0.3): Color(0xffE6F7FF)
                            : isDark ? Color(0xff4C4C4C) : Color(0xffF3F3F3)
                        ),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.start,
                          alignment: WrapAlignment.center,
                          children: [
                            Container(
                              child: e["emoji"] is ItemEmoji
                                  ? e["emoji"].render(size: 18.0, padding: 0.0, isEnableHover: false, heightLine: 1.0)
                                  : e["emoji"]["type"] == "default"
                                      ? Text("${e["emoji"]["value"]}", style: TextStyle(fontSize: 18, height: 1.0))
                                      : CachedImage(e["emoji"]["url"], height: 36, width: 36,)
                            ),
                            e["count"] > 0 ? Text("  ${e["count"]}", style: TextStyle(fontSize: 11.5, color: isDark? Colors.white : Colors.blue)): Text("")
                          ]
                        )
                      )
                    )
                  )
                );
              }).toList(),
            ),
            (isHover && reactions.length > 0) ? Container(
              margin: EdgeInsets.only(left: 4, top: 4),
              child: Tooltip(
                message: "Show detail",
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context, 
                      builder: (BuildContext context) {
                        return Dialog(
                          child: ReactionsDialog(reactions: reactions, channelId: widget.channelId),
                        );
                      }
                    );
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xff4C4C4C) : Color(0xffF3F3F3),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Icon(PhosphorIcons.dotsThreeVertical, size: 16, color: isDark ? Colors.white : Colors.black))
                  ),
              ),
            ) : Container(),
          ],
        ),
      ),
    );
  }

  checkPinMessage() {
    final pinnedMessages = Provider.of<Channels>(context, listen: false).pinnedMessages;
    final index = pinnedMessages.indexWhere((e) => e["id"] == widget.id);

    return (index == -1);
  }

  checkMarkSavedMessage() {
    final savedMessages = Provider.of<User>(context, listen: false).savedMessages;
    final index = savedMessages.indexWhere((e) => e["message_id"] == widget.id);
    isChecked = (index != -1);
  }

  parseTime(dynamic time) {
    var messageLastTime = "";
    final auth = Provider.of<Auth>(context, listen: false);
    if (Utils.checkedTypeEmpty(widget.lastEditedAt)) {
      DateTime dateTime = DateTime.parse(time);
      final messageTime = DateFormat('kk:mm').format(DateTime.parse(time).add(Duration(hours: 7)));
      final dayTime = DateFormatter().getVerboseDateTimeRepresentation(dateTime, auth.locale);

      messageLastTime = "$dayTime at $messageTime";
      return messageLastTime;
    }
  }

  openThreadAction(context) async {
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final selectedTab = Provider.of<User>(context, listen: false).selectedTab;
    final conversationId = widget.isChannel ? null : widget.conversationId ?? Provider.of<DirectMessage>(context, listen: false).directMessageSelected.id;
    final channelId = widget.isChannel ? (selectedTab == "channel" || selectedTab == "thread") ? Provider.of<Channels>(context, listen: false).currentChannel["id"] : widget.channelId : null;
    final workspaceId = widget.isChannel ? currentWorkspace["id"] : null;
    final token = Provider.of<Auth>(context, listen: false).token;
    FocusInputStream.instance.focusToThread();
    int indexFromThread = (widget.attachments ?? []).indexWhere((e) => e["type"] == "send_to_channel_from_thread");
    Map parentMessage;
    if (indexFromThread != -1) {
      parentMessage = widget.attachments.where((e) => e["type"] == "send_to_channel_from_thread").toList()[0]["parent_message"];
    } else {
      parentMessage = {
        "id": widget.id,
        "message": widget.message,
        "avatarUrl": widget.avatarUrl,
        "insertedAt": widget.insertedAt,
        "fullName": widget.fullName,
        "attachments": widget.attachments,
        "isChannel": widget.isChannel,
        "userId": widget.userId,
        "channelId": channelId,
        "workspaceId": workspaceId,
        "conversationId": conversationId,
        "reactions": widget.reactions,
        "lastEditedAt": widget.lastEditedAt,
        "isUnsent": widget.isUnsent,
        "block_code": widget.blockCode,
        "snippet": widget.snippet
      };
    }
    if (widget.isChildMessage == null || widget.isChildMessage || !Utils.checkedTypeEmpty(widget.id)) return;
    Provider.of<Channels>(context, listen: false).openChannelSetting(false);
    if (widget.conversationId != null) {
      var indexDM = Provider.of<DirectMessage>(context, listen: false).data.indexWhere((element) => element.id == widget.conversationId);
      Provider.of<DirectMessage>(context, listen: false).setSelectedDM(Provider.of<DirectMessage>(context, listen: false).data[indexDM], "token");
    }
    Provider.of<Messages>(context, listen: false).openThreadMessage(true, parentMessage);
    await Provider.of<Threads>(context, listen: false).updateThreadUnread(workspaceId, channelId, parentMessage, token);
    Utils.updateBadge(context);
  }

  createIssueFromMessage(message) {
    final auth = Provider.of<Auth>(context, listen: false);
    DateTime dateTime = DateTime.parse(message["insertedAt"]);
    final messageTime = DateFormat('kk:mm').format(DateTime.parse(message["insertedAt"]).add(Duration(hours: 7)));
    final dayTime = DateFormatter().getVerboseDateTimeRepresentation(dateTime, auth.locale);

    final messageLastTime = (message["insertedAt"] != "" && message["insertedAt"] != null)
      ? "${dayTime == "Today" ? messageTime : DateFormatter().renderTime(DateTime.parse(widget.insertedAt), type: "MMMd") + " at $messageTime"}"
      : "";
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];
    final channelId = Provider.of<Channels>(context, listen: false).currentChannel["id"];

    String description = (message["message"] != "" && message["message"] != null) ? message["message"] : message["attachments"].length > 0 ? parseAttachments(message) : "";

    if (message["attachments"].length > 0) {
      for (var i = 0; i < message["attachments"].length; i++) {
        var image = message["attachments"][i];
        if (image["mime_type"] == "image") {
          description += "\n![${image["name"] ?? "Image"}](${image["content_url"]})";
        }
      }
    }
    /*
      required data Message Create Issue
      final message = {
        'id': widget.id,
        'message': widget.message,
        'attachments': widget.attachments,
        "avatarUrl": widget.avatarUrl ?? "",
        "fullName": widget.fullName ?? "",
        "workspaceId": widget.conversationId != null ? null : currentWorkspace['id'],
        "channelId": widget.channelId,
        'conversationId': widget.conversationId,
        'insertedAt': widget.insertedAt,
        'isChannel': widget.isChannel
      };
    */

    Map newIssue = {
      "workspace_id": workspaceId,
      "channel_id": channelId,
      "title": message["message"].length < 48 ? message["message"].replaceAll("\n", " ") : message["message"].replaceAll("\n", " ").substring(0, 48),
      "description": "$description \n\n${widget.fullName} - $messageLastTime",
      "comments": [],
      "timelines": [],
      "type": "create",
      "is_closed": false,
      "from_message": true,
      "message": message
    };

    Provider.of<Channels>(context, listen: false).onChangeOpenIssue(newIssue);
    Provider.of<Auth>(context, listen: false).keyDrawer.currentState!.openEndDrawer();
  }

  parseAttachments(dataM) {
    var message = dataM["message"] ?? "";
    var mentions = dataM["attachments"] != null ?  dataM["attachments"].where((element) => element["type"] == "mention").toList() : [];
    
    if (mentions.length > 0){
      var mentionData =  mentions[0]["data"];
      message = "";
      for(var i= 0; i< mentionData.length ; i++){
        if (mentionData[i]["type"] == "text" ) message += mentionData[i]["value"];
        else message += "=======${mentionData[i]["trigger"] ?? "@"}/${mentionData[i]["value"]}^^^^^${mentionData[i]["name"]}^^^^^${mentionData[i]["type"] ?? ((mentionData[i]["id"].length < 10) ? "all" : "user")}+++++++";
      }
    }

    return message;
  }

  var portalEntry = Container();
  bool rebuild = false;
  var roleId;

  @override
  void didUpdateWidget (oldWidget) {
    if (oldWidget.message != widget.message 
      || oldWidget.attachments.toString() != widget.attachments.toString()
      || oldWidget.avatarUrl != widget.avatarUrl 
      || oldWidget.fullName != widget.fullName
      || oldWidget.count != widget.count
      || oldWidget.reactions.toString() != widget.reactions.toString()
      || oldWidget.lastEditedAt != widget.lastEditedAt
      || oldWidget.isFirst != widget.isFirst
      || oldWidget.isLast != widget.isLast
      || oldWidget.isDark != widget.isDark
      || oldWidget.firstMessage != widget.firstMessage
      || oldWidget.waittingForResponse != widget.waittingForResponse
      || oldWidget.isBlur != widget.isBlur
      || oldWidget.isUnreadThreadMessage != widget.isUnreadThreadMessage
      || oldWidget.isUnsent != widget.isUnsent
      || oldWidget.customColor != widget.customColor
      || oldWidget.isAfterThread != widget.isAfterThread
      || roleId != getUser(widget.userId)["role_id"]
      || oldWidget.isShow != widget.isShow
      || oldWidget.isFetchingDown != widget.isFetchingDown
      || oldWidget.isFetchingUp != widget.isFetchingUp
    ) {
      this.setState(() {
        rebuild = false;
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  void setHighlightMessage() async {
    if (this.mounted)
      setState(() {
        isHighlightMessage = true;
        rebuild = false;
      });
    await Future.delayed(Duration(seconds: 5));  
    if(this.mounted) {
      setState(() {
        isHighlightMessage = false;
        rebuild = false;
      });
    }
  }

  showDialogForwardMessage(message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: ForwardMessage(message: message)
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!rebuild) {
      try {
        portalEntry = buildPortalEntry();
        rebuild = true;
      } catch (e) {
        portalEntry = Container(child: Text("${e.toString()}"));
        rebuild = false;
      }
    }

    return portalEntry;
  }

  getReadMessageConversation(String id, String conversationId){
    final auth = Provider.of<Auth>(context);
    int count = 0;
    final dm = Provider.of<DirectMessage>(context, listen: false).getModelConversation(conversationId);
    if (dm == null || (auth.userId != widget.userId)) return Container();
    int countDM = dm.user.where((element) => element["status"] == "in_conversation").length; 
    try {
      final dataUnreadMessage = Provider.of<DirectMessage>(context, listen: false).dataUnreadMessage;
      var unreadCount  =  dataUnreadMessage[id]["count_unread"];
      count = ( countDM - 1 - unreadCount).toInt();
    } catch (e) {
    }

    if (count == 0) return Icon(PhosphorIcons.check, size: 20);
    if ((countDM - 1) == count) return Icon(PhosphorIcons.checks, color: Color(0xFF1890ff), size: 20,);
    return Row(
      children: [
        Text("$count ", style: TextStyle(fontSize: 12)),
        Icon(PhosphorIcons.checks, color: Color(0xFFbfbfbf),size: 20)
      ]
    );
  }

  buildPortalEntry() {
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final selectedTab = Provider.of<User>(context, listen: false).selectedTab;
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    final auth = Provider.of<Auth>(context);
    final token = auth.token;
    final isDark = auth.theme == ThemeType.DARK;
    final messageTime = DateFormat('Hm').format(DateTime.parse(widget.insertedAt).add(Duration(hours: 7)));
    final locale = auth.locale;
    DateTime dateTime = DateTime.parse(widget.insertedAt);
    final dayTime = DateFormatter().getVerboseDateTimeRepresentation(dateTime.add(Duration(hours: 7)), locale);
    var showDateThread = widget.isThread ? ((dayTime == "Today" || dayTime == "Just now") ? "" 
      : DateFormatter().renderTime(DateTime.parse(widget.insertedAt), type: "MMMd")) + " $messageTime" 
      : widget.isViewMention || selectedTab == "thread"
        ? (dayTime == "Today" ? "Today" : DateFormatter().renderTime(DateTime.parse(widget.insertedAt), type: "MMMd")) + " at $messageTime"
        : messageTime;

    final channelId = widget.isChannel ? widget.channelId : null;
    final workspaceId = widget.isChannel ? currentWorkspace["id"] : null;
    bool isPoll = false;
    final conversationId = widget.isChannel ? null : widget.conversationId ?? Provider.of<DirectMessage>(context, listen: false).directMessageSelected.id;
    Map message = {
      "id": widget.id,
      "message": widget.message,
      "avatarUrl": widget.avatarUrl,
      "insertedAt": widget.insertedAt,
      "fullName": widget.fullName,
      "attachments": widget.attachments,
      "isChannel": widget.isChannel,
      "userId": widget.userId,
      "channelId": channelId,
      "workspaceId": workspaceId,
      "conversationId": conversationId,
      "reactions": widget.reactions,
      "lastEditedAt": widget.lastEditedAt,
      "isUnsent": widget.isUnsent,
      "count": widget.count,
      "isChildMessage": widget.isChildMessage,
      "current_time": widget.currentTime,
      "conversation_id": conversationId
    };

    int index = (widget.attachments ?? []).indexWhere((e) => e["type"] == "bot");
    int indexSnippet = (widget.attachments ?? []).indexWhere((e) => e["mime_type"] == "html" || e["mime_type"] == "block_code");
    int indexFromThread = (widget.attachments ?? []).indexWhere((e) => e["type"] == "send_to_channel_from_thread");
    var lastMessageReaded = Provider.of<Channels>(context, listen: false).currentChannel["last_message_readed"];
    final canEdit = index == -1 && indexSnippet == -1 && widget.userId == auth.userId;
    
    if (!widget.isChannel){
      lastMessageReaded = (Provider.of<DirectMessage>(context, listen: false).getCurrentDataDMMessage(widget.conversationId) ?? {})["last_message_readed"];
    }

    if(widget.attachments.length != 0){
      if (widget.attachments[0]["type"] == "poll") {
        isPoll = true;
      } else {
        isPoll = false;
      }
    }

    return Container(
      child: PortalEntry(
      portalAnchor: widget.isShow ? Alignment(1.2, 0.5) : Alignment(1.2, -0.5),
      childAnchor: widget.isShow ? Alignment.topRight : Alignment.bottomRight,
      visible: isPoll 
      ? false
      : widget.isThread
        ? widget.isShow && showMenu && !showEmoji && widget.id != null
        : showMenu && !showEmoji && widget.id != null && !widget.isViewMention && (selectedTab == "channel" ),
      portal: MouseRegion(
        onEnter: (event) {
          if (Utils.checkedTypeEmpty(widget.id) && widget.success) setState(() {showMenu = true; rebuild = false;});
        },
        onExit: (event) {
          if (!showEmoji && widget.id != null && widget.success) setState(() {showMenu = false; rebuild = false;});
        },
        child: Container(
          height: 35,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
              border: Border.all(
                color: isDark ? Color(0xff5E5E5E) : Color(0xffA6A6A6),
                width: 0.5
              )
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!widget.isChannel && widget.userId == auth.userId && Utils.checkedTypeEmpty(widget.id)) 
                HoverItem(
                  colorHover: isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8,vertical: 8),
                    child: getReadMessageConversation(widget.id, widget.conversationId)
                  ),
                ),
                if ((selectedTab == "channel" || selectedTab == "thread" || selectedTab == "mention") && widget.isChannel) 
                HoverItem(
                  colorHover: isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onPressed: () {
                      if (!widget.isChannel) return;
                      setState(()  {rebuild = false;showEmoji = true;});
                      var box = context.findRenderObject();
                      var si = context.size;
                      var t  =  box == null ? Offset.zero : (box as RenderBox).localToGlobal(Offset.zero);
                      var isOpenThread  =  Provider.of<Messages>(context, listen: false).openThread;
                      showPopover(
                        context: context,
                        direction: isOpenThread && !widget.isChildMessage ? PopoverDirection.right : PopoverDirection.top,
                        transitionDuration: Duration(milliseconds: 0),
                        arrowDyOffset: isOpenThread && !widget.isChildMessage 
                          ? 0
                          : t.dy < 380 ? -si!.height : 0,
                        arrowWidth: 0, 
                        arrowHeight: 0,
                        arrowDxOffset: isOpenThread && !widget.isChildMessage ? -320 : 0,
                        shadow: [],
                        // barrierColor: null,
                        onPop: (){
                          if (this.mounted) this.setState(() {
                            showMenu = false;
                            showEmoji= false;
                          });
                        },
                        bodyBuilder: (context) => Emoji(
                          // can check lai workspaceId
                          workspaceId: workspaceId,
                          onSelect: (emoji){
                            Provider.of<Messages>(context, listen: false)
                              .handleReactionMessage({
                              "message_id": widget.id,
                              "channel_id": widget.channelId,
                              "workspace_id": workspaceId,
                              "token": Provider.of<Auth>(context, listen: false).token,
                              "emoji_id": emoji.id
                            });
                          },
                        onClose: (){
                          Navigator.pop(context);
                          if (mounted) {
                            setState(() {
                              showEmoji= false;
                              showMenu = false;
                            });}
                          }
                        )
                      );
                    },
                    icon: SvgPicture.asset('assets/icons/happy_light.svg', color: isDark ? Color(0xffA6A6A6) : Color(0xff828282))
                  ),
                ),
                if ((selectedTab == "channel" || selectedTab == "thread" || selectedTab == "mention") && !widget.isChildMessage) 
                HoverItem(
                  colorHover: isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
                  child: IconButton(
                    icon: SvgPicture.asset('assets/icons/bubble_chat.svg', color: isDark ? Color(0xffA6A6A6) : Color(0xff828282)),
                    padding: EdgeInsets.zero,
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onPressed: () { 
                      openThreadAction(context);
                    }
                  ),
                ),
                if (canEdit && !Utils.checkedTypeEmpty(widget.isUnsent) && widget.isChannel) 
                HoverItem(
                  colorHover: isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
                  child: IconButton(
                    icon: SvgPicture.asset('assets/icons/edited.svg', color: isDark ? Color(0xffA6A6A6) : Color(0xff828282)),
                    padding: EdgeInsets.zero,
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onPressed: () {
                      message["attachments"].indexWhere((e) => e["type"] == "bot");
                      handleUpdateMessage(context, message, widget.updateMessage);
                      if (Utils.checkedTypeEmpty((widget.conversationId)) && widget.onEditMessage != null){
                        widget.onEditMessage(widget.id);
                      }
                    }
                  ),
                ),
                if ((selectedTab == "channel" || selectedTab == "thread" || selectedTab == "mention") && !widget.isChildMessage && (widget.isChannel == true || widget.isDirect == true)) 
                HoverItem(
                  colorHover: isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
                  child: IconButton(
                    icon: Icon(CupertinoIcons.arrowshape_turn_up_right, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282), size: 17),
                    padding: EdgeInsets.zero,
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onPressed: () {
                      widget.onShareMessage!({"mime_type": "share", "data": message});
                    }
                  ),
                ),
                if (selectedTab == "channel" || selectedTab == "thread" || selectedTab == "mention") StatefulBuilder(
                  builder: (context, setState) {
                    return HoverItem(
                      colorHover: isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        focusColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        onPressed: () {
                          message = {...message, "parentId": widget.parentId};
                          if (isChecked) {
                            Provider.of<User>(context, listen: false).unMarkSavedMessage(token, message);
                          } else {
                            Provider.of<User>(context, listen: false).markSavedMessage(token, message);
                          }
                          setState(() => isChecked = !isChecked);
                        },
                        icon: isChecked
                          ? Icon(CupertinoIcons.bookmark_fill, color: Colors.red, size: 17)
                          : Icon(CupertinoIcons.bookmark, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282), size: 17)
                      ),
                    );
                  }
                ),
                if (selectedTab == "channel" || selectedTab == "thread" || selectedTab == "mention") 
                HoverItem(
                  colorHover: isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onPressed: () => setState(() {showMore = !showMore; rebuild = false;}),
                    icon: Icon(CupertinoIcons.ellipsis_vertical, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282), size: 15,),
                  ),
                ),
                if (showMore) Container(width: 0.5, height: 16, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282), margin: EdgeInsets.only(left: 10, right: 10),),
                if (showMore)
                HoverItem(
                  colorHover: isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
                  child: IconButton(
                    icon: Icon(PhosphorIcons.shareNetwork, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282), size: 12),
                    onPressed: () => showDialogForwardMessage(message),
                  ),
                ),
                if (showMore && (selectedTab == "channel" || selectedTab == "thread" || selectedTab == "mention") && checkPinMessage() && !(widget.isThread && widget.isChildMessage) && widget.conversationId == null) 
                HoverItem(
                  colorHover: isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onPressed: () {
                      Provider.of<Channels>(context, listen: false).pinMessage(token, workspaceId, channelId, message["id"], true);
                    },
                    icon: SvgPicture.asset('assets/icons/Pushpin.svg', color: isDark ? Color(0xffA6A6A6) : Color(0xff828282))
                  ),
                ),
                if (showMore) 
                HoverItem(
                  colorHover: isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onPressed: () {
                      createIssueFromMessage(message);
                    },
                    icon: Icon(Icons.add_task_rounded, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282), size: 17)
                  ),
                ),
                if (showMore && currentUser["id"] == message["userId"] && !Utils.checkedTypeEmpty(widget.isUnsent)) 
                HoverItem(
                  colorHover: isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onPressed: () {
                      if (widget.isChannel)
                        Provider.of<Messages>(context, listen: false).deleteChannelMessage(token, workspaceId, channelId, message["id"]);
                      else {
                        Provider.of<DirectMessage>(context, listen: false).deleteMessage(token, widget.conversationId, {
                          "id": message["id"],
                          "current_time": widget.currentTime,
                          "parent_id": widget.parentId,
                        });
                      }
                    },
                    icon: SvgPicture.asset('assets/icons/delete.svg', color: isDark ? Color(0xffA6A6A6) : Color(0xff828282)),
                  ),
                ),
                if (showMore && !(widget.isChannel)) 
                HoverItem(
                  colorHover: isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onPressed: () {
                      Provider.of<DirectMessage>(context, listen: false).deleteMessage(token, widget.conversationId, {
                        "id": message["id"],
                        "current_time": widget.currentTime,
                        "parent_id": widget.parentId,
                        "sender_id": widget.userId,
                      }, type: "delete_for_me");
                    },
                     icon: SvgPicture.asset('assets/icons/delete.svg', color: Colors.red),
                  ),
                )
              ]
            ),
          ),
        ),  
      ),
      child: ContextMenuRegion(
        contextMenu: GenericContextMenu(
          buttonConfigs: widget.isSystemMessage || isPoll ? [] : [
            if((selectedTab == "channel" || selectedTab == "thread" || selectedTab == "mention") && widget.isChannel) ContextMenuButtonConfig(
              'Emoji',
              icon: SvgPicture.asset(
                "assets/icons/happy_light.svg",
                color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E), width: 12, height: 12
              ),
              onPressed: () {
                if (!widget.isChannel) return;
                setState(()  {rebuild = false;showEmoji = true;});
                var box = context.findRenderObject();
                var si = context.size;
                var t  =  box == null ? Offset.zero : (box as RenderBox).localToGlobal(Offset.zero);
                var isOpenThread  =  Provider.of<Messages>(context, listen: false).openThread;
                showPopover(
                  context: context,
                  direction: isOpenThread && !widget.isChildMessage ? PopoverDirection.right : PopoverDirection.top,
                  transitionDuration: Duration(milliseconds: 0),
                  arrowDyOffset: isOpenThread && !widget.isChildMessage 
                    ? 0
                    : t.dy < 380 ? -si!.height : 0,
                  arrowWidth: 0, 
                  arrowHeight: 0,
                  arrowDxOffset: isOpenThread && !widget.isChildMessage ? -320 : 0,
                  shadow: [],
                  // barrierColor: null,
                  onPop: (){
                    if (this.mounted) this.setState(() {
                      showMenu = false;
                      showEmoji= false;
                    });
                  },
                  bodyBuilder: (context) => Emoji(
                    // can check lai workspaceId
                    workspaceId: workspaceId,
                    onSelect: (emoji){
                      Provider.of<Messages>(context, listen: false)
                        .handleReactionMessage({
                        "message_id": widget.id,
                        "channel_id": widget.channelId,
                        "workspace_id": workspaceId,
                        "token": Provider.of<Auth>(context, listen: false).token,
                        "emoji_id": emoji.id
                      });
                    },
                    onClose: (){
                      Navigator.pop(context);
                      setState(() {
                      showEmoji= false;
                      showMenu = false;
                    });}
                  )
                );
              },
            ),
            if ((selectedTab == "channel" || selectedTab == "thread") && !widget.isChildMessage) ContextMenuButtonConfig(
              'Reply in thread',
              icon: SvgPicture.asset(
                "assets/icons/bubble_chat.svg",
                color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E), width: 12, height: 12
              ),
              onPressed: () => openThreadAction(context),
            ),
            if((selectedTab == "channel" || selectedTab == "thread") && widget.isChannel) ContextMenuButtonConfig(
              'Pin message',
              icon: SvgPicture.asset(
                "assets/icons/Pushpin.svg",
                color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E), width: 12, height: 12
              ),
              onPressed: () => Provider.of<Channels>(context, listen: false).pinMessage(token, workspaceId, channelId, message["id"], true),
            ),
            if(canEdit && !Utils.checkedTypeEmpty(widget.isUnsent) && widget.isChannel) ContextMenuButtonConfig(
              'Edit message',
              icon: SvgPicture.asset(
                "assets/icons/edited.svg",
                color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E), width: 12, height: 12
              ),
              onPressed: () {
                message["attachments"].indexWhere((e) => e["type"] == "bot");
                handleUpdateMessage(context, message, widget.updateMessage);
                if (Utils.checkedTypeEmpty((widget.conversationId)) && widget.onEditMessage != null){
                  widget.onEditMessage(widget.id);
                }
              },
            ),
            if ((selectedTab == "channel" || selectedTab == "thread") && !widget.isChildMessage && widget.isChannel) ContextMenuButtonConfig(
              'Share message',
              icon: Icon(CupertinoIcons.arrowshape_turn_up_right, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282), size: 12),
              onPressed: () => widget.onShareMessage!({"mime_type": "share", "data": message}),
            ),
            ContextMenuButtonConfig(
              'Forward message',
              icon: Icon(PhosphorIcons.shareNetwork, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282), size: 12),
              onPressed: () => showDialogForwardMessage(message),
            ),
            if ((selectedTab == "channel" || selectedTab == "thread") && !widget.isChildMessage) ContextMenuButtonConfig(
              'Create issue',
              icon: Icon(Icons.add_task_rounded, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282), size: 12),
              onPressed: () => createIssueFromMessage(message),
            ),
            if (currentUser["id"] == message["userId"] && !Utils.checkedTypeEmpty(widget.isUnsent)) ContextMenuButtonConfig(
              'Delete message',
              icon: SvgPicture.asset(
                "assets/icons/delete.svg",
                color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E), width: 12, height: 12
              ),
              onPressed: () {
                if (widget.isChannel)
                  Provider.of<Messages>(context, listen: false).deleteChannelMessage(token, workspaceId, channelId, message["id"]);
                else {
                  Provider.of<DirectMessage>(context, listen: false).deleteMessage(token, widget.conversationId, {
                    "id": message["id"],
                    "current_time": widget.currentTime,
                    "parent_id": widget.parentId,
                  });
                }
              },
            ),
          ],
        ),
        child: Center(
          child: Opacity(
            opacity: (widget.isBlur == null || !widget.isBlur) ? 1: 0.2,
            child: (widget.isSystemMessage != null && widget.isSystemMessage)
              ? renderSystemMessage(widget.attachments)
              : MouseRegion(
                  onEnter: (event) {
                    Utils.setHoverMessageContext(context);
                    if (Utils.checkedTypeEmpty(widget.id) && widget.success) setState(() {showMenu = true; rebuild = false;}); checkMarkSavedMessage();
                    if (widget.keyScroll != null) widget.keyScroll!.currentState!.onIsVisibleWidget();
                  },
                  onExit: (event) {
                    Utils.setHoverMessageContext(null);
                    if (showMore) setState(() {showMore = false; rebuild = false;});
                    if (!showEmoji && widget.id != null && widget.success) setState(() {showMenu = false; rebuild = false;}); checkMarkSavedMessage();
                    if (widget.keyScroll != null) widget.keyScroll!.currentState!.onIsVisibleWidget();
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 1000),
                    child: Stack(
                      fit: StackFit.passthrough,
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          children: [
                          if(widget.isFetchingDown) shimmerEffect(context, number: 5),
                            (Utils.checkedTypeEmpty(widget.id) && widget.id == lastMessageReaded && !widget.isThread && !widget.isViewMention && !widget.firstMessage) ? Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.red[400],
                                    height: 1,
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(left: 10, right: 20), 
                                  child: Text("NEW", style: TextStyle(color: Colors.red)),
                                )
                              ]
                            ) : Container(),
                            Container(
                              decoration: BoxDecoration(
                                color: (isHighlightMessage == true) && Utils.checkedTypeEmpty(widget.id)
                                    ? isDark ? Palette.borderSideColorDark : Color(0xffEDEDED)
                                    : showMenu && (selectedTab == "channel" || selectedTab == "thread")
                                      ? !isDark ? Color(0xffF8F8F8) : Color(0xff353535)
                                      : widget.isThread || widget.isViewThread || widget.isViewMention
                                        ? Colors.transparent
                                        : isDark ? Palette.backgroundRightSiderDark : Palette.backgroundRightSiderLight 
                              ),
                              // margin: EdgeInsets.only(bottom: widget.isLast ? 6 : 0, left: 0),
                              padding: EdgeInsets.only(
                                top: widget.isViewThread && !widget.isChildMessage
                                  ? 14
                                  : (widget.isFirst || widget.showHeader || widget.showNewUser || widget.isAfterThread) ? 4 : 0,
                                bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 18,),
                                  Container(
                                    child: widget.isFirst || widget.showHeader || widget.showNewUser || widget.isAfterThread
                                      ? InkWell(
                                          onTap: () {
                                            if (currentUser["id"] != widget.userId) {
                                              onShowUserInfo(context, widget.userId);
                                            }
                                          },
                                          child: CachedAvatar(
                                            widget.avatarUrl ?? getUser(widget.userId)["avatar_url"],
                                            height: 36, width: 36,
                                            isRound: true,
                                            name: widget.fullName ?? getUser(widget.userId)["full_name"],
                                            isAvatar: true,
                                            fontSize: 16,
                                          )
                                        )
                                      : showMenu ? Container(
                                        alignment: Alignment.center,
                                        margin: EdgeInsets.only(top: 6),
                                        width: 34,
                                        child: Text(
                                          messageTime,
                                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Color(0xFF323F4B)),
                                        ),
                                      ) : Container(width: 34,),
                                  ),
                                  SizedBox(width: 8,),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        (widget.isFirst || widget.showHeader || widget.showNewUser || widget.isAfterThread) && (!widget.isChannel ? (widget.id != null && widget.id != 1 ) : widget.isChannel)
                                        ? Container(
                                          margin: EdgeInsets.only(bottom: 4),
                                          child: RichTextWidget(
                                            TextSpan(
                                               style: TextStyle(
                                                  color: widget.isChannel
                                                    ? widget.userId == currentUser["id"] && (widget.customColor != "default" && widget.customColor != null)
                                                      ? Color(int.parse("0xFF${widget.customColor}"))
                                                      : Constants.checkColorRole(getUser(widget.userId)["role_id"], isDark)
                                                    : widget.userId == currentUser["id"]
                                                      ? Colors.lightBlue
                                                      : isDark
                                                        ? Palette.defaultTextDark
                                                        : Palette.defaultTextLight,
                                                ),
                                              children: [
                                                TextSpan(
                                                  text: widget.fullName ?? getUser(widget.userId)["full_name"],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14
                                                  ),
                                                  mouseCursor: currentUser["id"] != widget.userId ? SystemMouseCursors.click : SystemMouseCursors.text,
                                                  recognizer: TapGestureRecognizer()..onTapUp = currentUser["id"] != widget.userId && !isShift
                                                    ? (_) => onShowUserInfo(context, widget.userId)
                                                    : null,
                                                ),
                                                if((widget.isChannel && widget.accountType != null && widget.accountType != "user")) WidgetSpan(
                                                  child: Container(
                                                    margin: EdgeInsets.only(left: 5),
                                                    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey,
                                                      borderRadius: BorderRadius.all(Radius.circular(4))
                                                    ),
                                                    child: Text(widget.accountType.toString().toUpperCase(), style: TextStyle(fontSize: 9),)
                                                  )
                                                ),
                                                TextSpan(
                                                  text: Utils.checkedTypeEmpty(showDateThread) ? "   $showDateThread" : DateFormat('kk:mm').format(DateTime.now()),
                                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Color(0xFF323F4B),),
                                                ),
                                              ]
                                            ),
                                            isDark: isDark,
                                            key: Key('ChatItemName${widget.id}')
                                          )
                                        ) : Container(),
                                        Utils.checkedTypeEmpty(widget.isUnsent) || Utils.checkedTypeEmpty(widget.waittingForResponse)
                                          ? Container(
                                            height: 19,
                                            child: TextWidget(
                                              (Utils.checkedTypeEmpty(widget.isUnsent) ? "[This message was deleted.]"
                                              : Utils.checkedTypeEmpty(widget.waittingForResponse)? "[Waitting for response, tap to learn more.]"
                                              : ""),
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                color: Color(isDark ? 0xffe8e8e8 : 0xff898989)
                                              ),
                                            )
                                          )
                                          : (widget.message != "" && widget.message != null)
                                            ? Container(
                                              padding: EdgeInsets.only(left: widget.isFirst || widget.showNewUser || widget.isAfterThread ? 0 : 3, right: 24),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: indexFromThread != -1
                                                ? [
                                                  widget.attachments != null && widget.attachments.length > 0
                                                    ? AttachmentCardDesktop(
                                                      blockCode: widget.blockCode,
                                                      snippet: widget.snippet,
                                                      attachments: widget.attachments,
                                                      isChannel: widget.isChannel,
                                                      id: widget.id,
                                                      isChildMessage: widget.isChildMessage,
                                                      isThread: widget.isThread,
                                                      lastEditedAt: parseTime(widget.lastEditedAt),
                                                      message: message
                                                    )
                                                    : Container(),
                                                  MessageCardDesktop(message: widget.message, id: widget.id, lastEditedAt: parseTime(widget.lastEditedAt))
                                                ]
                                                : [
                                                  MessageCardDesktop(message: widget.message, id: widget.id, lastEditedAt: parseTime(widget.lastEditedAt)),
                                                  widget.attachments != null && widget.attachments.length > 0
                                                    ? AttachmentCardDesktop(blockCode: widget.blockCode,
                                                    snippet: widget.snippet,
                                                    attachments: widget.attachments,
                                                    isChannel: widget.isChannel,
                                                    id: widget.id,
                                                    isChildMessage: widget.isChildMessage,
                                                    isThread: widget.isThread,
                                                    lastEditedAt: parseTime(widget.lastEditedAt),
                                                    message: message
                                                  )
                                                    : Container()
                                                ],
                                              ),
                                            )
                                            : widget.attachments != null && widget.attachments.length > 0
                                              ? Container(
                                                padding: EdgeInsets.only(left: widget.isFirst ? 0 : 3, right: 24),
                                                child: AttachmentCardDesktop(
                                                  blockCode: widget.blockCode,
                                                  snippet: widget.snippet,
                                                  attachments: widget.attachments,
                                                  isChannel: widget.isChannel,
                                                  id: widget.id,
                                                  isChildMessage: widget.isChildMessage,
                                                  isThread: widget.isThread,
                                                  conversationId: widget.conversationId,
                                                  lastEditedAt: parseTime(widget.lastEditedAt),
                                                  message: message
                                                )
                                              )
                                              : Container(),
                                        (widget.isThread == false || widget.isThread == true && widget.isChildMessage == true) ? renderReactions(widget.reactions ?? [], []) : Container(),
                                        (widget.count != null) && (widget.count > 0) && widget.infoThread.length > 0 ? renderInfoThread() : Container()
                                      ]
                                    )
                                  )
                                ]
                              )
                            ),
                            if(widget.isFetchingUp) shimmerEffect(context, number: 5),
                          ]
                        ), 
                      ],
                    ),
                  )
              )
            ),
        ),
      )
      )
    );
  }
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

handleUpdateMessage(context, message, updateMessage) {
  final userId = Provider.of<Auth>(context, listen: false).userId;
  if (userId == message["userId"] && message["isChannel"]) {
    updateMessage(message);
  }
}