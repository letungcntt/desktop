import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:simple_tooltip/simple_tooltip.dart';
import 'package:workcake/common/focus_inputbox_manager.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/message_item/chat_item_macOS.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/flutter_mention/custom_selection.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/providers/providers.dart';

class SavedMessages extends StatefulWidget {
  const SavedMessages({ Key? key }) : super(key: key);

  @override
  State<SavedMessages> createState() => _SavedMessagesState();
}

class _SavedMessagesState extends State<SavedMessages> {
  ScrollController controller = new ScrollController();
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    final savedMessages = Provider.of<User>(context, listen: true).savedMessages;
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Container(
      // margin: EdgeInsets.symmetric(vertical: 12.0),
      // padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 56,
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Palette.backgroundTheardDark,
              border: Border(
                bottom: BorderSide(
                  color: Palette.borderSideColorDark
                )
              )
            ),
            child: Center(child: Text("SAVED MESSAGES", style: TextStyle(color: Color(0xffF0F4F8), fontSize: 16, fontWeight: FontWeight.w500)))
          ),
          savedMessages.length > 0
            ? Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  shrinkWrap: true,
                  controller: controller,
                  itemCount: savedMessages.length,
                  itemBuilder: (context, index) {
                    final savedItem = savedMessages[index];
                    final message = savedItem["attachments"];
                    String wsName = '';
                    String cName = '';
                    bool isPrivate = false;
                    if (Utils.checkedTypeEmpty(message["workspaceId"]) && Utils.checkedTypeEmpty(message["channelId"])) {
                      final workspaces = Provider.of<Workspaces>(context, listen: false).data;
                      final idxWs = workspaces.indexWhere((element) => element["id"] == message["workspaceId"]);
                      if (idxWs != -1) wsName = workspaces[idxWs]["name"];

                      final channels = Provider.of<Channels>(context, listen: false).data;
                      final idxC = channels.indexWhere((element) => element["id"] == message["channelId"]);
                      if (idxC != -1) {
                        cName = channels[idxC]["name"];
                        isPrivate = channels[idxC]["is_private"];
                      }
                    }

                    return SavedItem(key: Key(savedItem["id"]), message: message, wsName: wsName, cName: cName, isPrivate: isPrivate);
                  },
                ),),
            )
            : Expanded(
              child: Container(
                height: MediaQuery.of(context).size.height,
                child: Center(
                  child: Text(
                    "Saved messages library is empty",
                    style: TextStyle(
                      fontSize: 20,
                      color: isDark ? Colors.white70 : Color(0xFF323F4B)
                    ),
                  ),
                ),
              ),
            ),
        ],
      )
    );
  }
}

class SavedItem extends StatefulWidget {
  SavedItem({ Key? key, this.message, this.cName, this.isPrivate,  this.wsName }) : super(key: key);

  final message;
  final wsName;
  final cName;
  final isPrivate;

  @override
  State<SavedItem> createState() => _SavedItemState();
}

class _SavedItemState extends State<SavedItem> {
  bool isHover = false;
  bool tooltipSaved = false;

  processDataMessageToJump(Map message , String conversationId) async {
    final auth  = Provider.of<Auth>(context, listen: false);
    bool hasConv = await Provider.of<DirectMessage>(context, listen: false).getInfoDirectMessage(auth.token, message["conversation_id"]);
    if (!hasConv) return;
    Provider.of<DirectMessage>(context, listen: false).processDataMessageToJump({...message, "conversation_id": conversationId}, auth.token, auth.userId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final token = auth.token;
    final isDark = auth.theme == ThemeType.DARK;
    final message = widget.message;
    final wsName = widget.wsName;
    final cName = widget.cName;
    final isPrivate = widget.isPrivate;

    return MouseRegion(
      onEnter: (e) => setState(() => isHover = true),
      onExit: (e) => setState(() => isHover = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(4.0))
            ),
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 32,
                  margin: EdgeInsets.only(bottom: 2),
                  padding: EdgeInsets.only(top: 8, bottom: 8, left: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xff5E5E5E) : Color(0xFFEAE8E8),
                    borderRadius: BorderRadius.all(Radius.circular(3))
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      (message["isChannel"])
                        ? Container(
                          child:
                            Row(children: [
                              Icon(CupertinoIcons.briefcase, size: 13, color: isDark ? Colors.white70 : Color(0xFF323F4B)),
                              SizedBox(width: 3),
                              Text(wsName, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Color(0xFF323F4B))),
                              SizedBox(width: 5,),
                              Container(width: 1, height: 13, color: isDark ? Colors.white70 : Color(0xFF323F4B)),
                              SizedBox(width: 5,),
                              Utils.checkedTypeEmpty(isPrivate)
                                ? SvgPicture.asset('assets/icons/Locked.svg', width: 11, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight)
                                : SvgPicture.asset('assets/icons/iconNumber.svg', width: 11, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                              SizedBox(width: 3,),
                              Text(cName, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Color(0xFF323F4B)))
                            ]),
                        )
                        : Container(
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.bubble_left_bubble_right, size: 13, color: isDark ? Colors.white70 : Color(0xFF323F4B)),
                                SizedBox(width: 3),
                                Text("Direct Message", style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Color(0xFF323F4B))),
                              ],
                            )
                          ),
                      isHover
                        ? Row(
                          children: [
                            Container(
                              width: 18,
                              margin: EdgeInsets.symmetric(horizontal: 12),
                              child: IconButton(
                                hoverColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  if (message["conversationId"] == null) {
                                    Provider.of<Messages>(context, listen: false).handleProcessMessageToJump(message, context);
                                  } else {
                                    var indexConverastion = Provider.of<DirectMessage>(context, listen: false).data.indexWhere((element) => element.id == message["conversationId"]);
                                    if (indexConverastion != -1){
                                      // hien tai viec nhay vao hoi thoai co van de =>
                                      // -> doi voi tin nhan trong luong chinj
                                      // chi mo hoi thoai
                                      // -> doi voi tin nhan trong thread
                                      // nhay vao luong chinh, mo thread;

                                      DirectModel dm  = Provider.of<DirectMessage>(context, listen: false).data[indexConverastion];
                                      var dataDMMessages = Provider.of<DirectMessage>(context, listen: false).getCurrentDataDMMessage(message["conversationId"]);

                                      if (Utils.checkedTypeEmpty(message["parentId"])){
                                        var parentMessage = {
                                          "id": message["parentId"],
                                          "isChannel": false,
                                          "conversationId": message["conversationId"],
                                          "attachments": [],
                                          "messsage": "Message is not loaded",
                                          "insertedAt": message["insertedAt"],
                                        };
                                        var indexMessage = (dataDMMessages["messages"] as List).indexWhere((element) => element["id"] == message["parentId"]);

                                        if (indexMessage == -1){
                                          var messageOnIsar = await MessageConversationServices.getListMessageById(message["parentId"], "");
                                          if (messageOnIsar != null){
                                            parentMessage = {...parentMessage, ...messageOnIsar,
                                            "insertedAt": messageOnIsar["time_create"],
                                            };
                                          }
                                        } else {
                                          parentMessage = {...parentMessage, ...(dataDMMessages["messages"][indexMessage]),
                                          "insertedAt": dataDMMessages["messages"][indexMessage]["time_create"],
                                          };
                                        }
                                        if (parentMessage["user_id"] != null ){
                                          String fullName = "";
                                          String avatarUrl = "";
                                          var u = dm.user.where((element) => element["user_id"] == parentMessage["user_id"] ).toList();
                                          if (u.length > 0) {
                                            fullName = u[0]["full_name"];
                                            avatarUrl = u[0]["avatar_url"] ?? "";
                                          }
                                          parentMessage = {...parentMessage,
                                            "avatarUrl": avatarUrl,
                                            "fullName": fullName
                                          };
                                        }
                                        Provider.of<DirectMessage>(context, listen: false).setSelectedMention(false);
                                        Provider.of<DirectMessage>(context, listen: false).setSelectedDM(Provider.of<DirectMessage>(context, listen: false).data[indexConverastion], "");
                                        Provider.of<Messages>(context, listen: false).openThreadMessage(true, parentMessage);
                                      } else {
                                        processDataMessageToJump(message, message["conversationId"]);
                                      }
                                      // trong truong hojp hoi thoai chua dc load hoac tin nhan ko trong hoi thoaij
                                      // set ["messages"] = [{tin nhan}]
                                    }
                                  }
                                },
                                icon: Icon(CupertinoIcons.arrow_turn_up_left)
                              ),
                            ),
                            if (!Utils.checkedTypeEmpty(message["isChildMessage"]) && message["isChannel"]) Container(
                              width: 18,
                              margin: EdgeInsets.only(right: 10),
                              child: IconButton(
                                hoverColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  // var isChild = message["parent_id"] != null;
                                  // var messages;
                                  // if (isChild) {
                                  //   messages = message["parent"];
                                  // }
                                  // else {
                                  //   messages = message;
                                  // }

                                  final workspaceId = message["workspaceId"];
                                  final channelId = message["channelId"];
                                  Map parentMessage = {
                                    "id": message["id"],
                                    "message": message["message"],
                                    "avatarUrl": message["avatarUrl"],
                                    "fullName": message["fullName"],
                                    "insertedAt": message["insertedAt"],
                                    "attachments": message["attachments"],
                                    "userId": message["userId"],
                                    "isChannel": message["isChannel"],
                                    "conversationId": null,
                                    "channelId": channelId,
                                    "workspaceId": workspaceId,
                                    "reactions": message["reactions"],
                                  };
                                  Navigator.of(context).pop();
                                  Provider.of<Messages>(context, listen: false).openThreadMessage(true, parentMessage);
                                  Provider.of<Threads>(context, listen: false).updateThreadUnread(workspaceId, channelId, parentMessage, token);
                                  FocusInputStream.instance.focusToThread();
                                },
                                icon: Icon(CupertinoIcons.chat_bubble_text)
                              ),
                            ),
                            SimpleTooltip(
                              tooltipDirection: TooltipDirection.up,
                              animationDuration: Duration(milliseconds: 100),
                              borderColor: isDark ? Color(0xFF262626) :Color(0xFFb5b5b5),
                              borderWidth: 0.5,
                              borderRadius: 5,
                              backgroundColor: isDark ? Color(0xFF1c1c1c): Colors.white,
                              arrowLength:  6,
                              arrowBaseWidth: 6.0,
                              ballonPadding: EdgeInsets.zero,
                              show: tooltipSaved,
                              content: Material(child: Text("Remove from saved items"), color: Colors.transparent),
                              child: HoverItem(
                                colorHover: Palette.hoverColorDefault,
                                child: InkWell(
                                  onHover: (hover) => setState(() => tooltipSaved = hover),
                                  onTap: () {},
                                  child: Container(
                                    width: 18,
                                    margin: EdgeInsets.only(right: 10),
                                    child: IconButton(
                                      hoverColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      splashColor: Colors.transparent,
                                      iconSize: 18,
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        Provider.of<User>(context, listen: false).unMarkSavedMessage(token, message);
                                      },
                                      icon: Icon(CupertinoIcons.bookmark_fill, color: Colors.red)
                                    )
                                  )
                                ),
                              ),
                            ),
                          ],
                        ) : Container()
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Palette.backgroundTheardDark: Palette.backgroundTheardLight,
                    borderRadius: BorderRadius.all(
                      Radius.circular(4)
                    )
                  ),
                  margin: EdgeInsets.only(top: 2), padding: EdgeInsets.symmetric(vertical: 8),
                  child: CustomSelectionArea(
                    child: ChatItemMacOS(
                      conversationId: message["conversationId"],
                      id: message["id"],
                      userId: message["userId"],
                      isChildMessage: message["isChildMessage"],
                      isMe: message["userId"] == auth.userId,
                      message: message["message"] ?? "",
                      avatarUrl: message["avatarUrl"] ?? "",
                      insertedAt: message["insertedAt"] ?? message["timeCreate"],
                      fullName: message["fullName"],
                      attachments: message["attachments"],
                      isFirst: true,
                      accountType: message["accountType"] ?? "user",
                      isChannel: message["isChannel"],
                      isThread: false,
                      count: 0,
                      infoThread: [],
                      success: true,
                      showHeader: false,
                      showNewUser: true,
                      isLast: true,
                      isBlur: false ,
                      reactions: Utils.checkedTypeEmpty(message["reactions"]) ? message["reactions"] : [],
                      isViewMention: true,
                      channelId: message["channelId"],
                      isDark: isDark,
                      customColor: message["customColor"],
                      workspaceId: message['workspaceId'] ?? 0,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}