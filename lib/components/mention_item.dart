import 'package:context_menus/context_menus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/focus_inputbox_manager.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:workcake/components/custom_context_menu.dart';
import 'package:workcake/components/render_list_emoji.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/flutter_mention/custom_selection.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/markdown/style_sheet.dart';
import 'package:workcake/markdown/widget.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/workview_desktop/markdown_attachment.dart';
import 'package:workcake/workview_desktop/markdown_checkbox.dart';
import 'message_item/chat_item_macOS.dart';

class MentionItem extends StatefulWidget {
  MentionItem({Key? key, this.sourceName, this.mention, this.issueUniq, this.text, this.showDateThread}) : super(key: key);

  final sourceName;
  final mention;
  final issueUniq;
  final text;
  final showDateThread;
  @override
  _MentionItemState createState() => _MentionItemState();
}

class _MentionItemState extends State<MentionItem> {
  bool _isHover = false;
  bool showEmoji = false;

  @override
  void initState() {
    super.initState();
    if (widget.mention["unread"] == true && widget.mention["source_id"] != null) {
      final token = Provider.of<Auth>(context, listen: false).token;
      Provider.of<Workspaces>(context, listen: false).updateUnreadMentionItem(token, widget.mention["workspace_id"], widget.mention["channel_id"], widget.mention);
    }
  }

  parseMention(comment) {
    var parse = Provider.of<Messages>(context, listen: false).checkMentions(comment);
    if (parse["success"] == false) return comment;
    return Utils.getStringFromParse(parse["data"]);
  }

  parseComment(comment, bool value) {
    var commentMention = parseMention(comment);
    List list = value ? commentMention.split("\n") :  comment.split("\n");

    if (list.length > 0) {
      for (var i = 0; i < list.length; i++) {
        var item = list[i];

        if (i - 1 >= 0) {
          if ((list[i-1].contains("- [ ]") || list[i-1].contains("- [x]")) && !(item.contains("- [ ]") || item.contains("- [x]"))) {
            list[i-1] = list[i-1] + " " + item;
            list[i] = "\n";
          }
        }
        if (item.contains("- [ ]") || item.contains("- [x]")) {
          if (i + 2 < list.length) {
            if (list[i+1].trim() == "") {
              list[i+1] = "\n";
            }
          }
        } else {
          if (i < list.length - 1 && list[i] == "" && list[i+1] == "") {
            list[i] = "```";
            list[i+1] = "```";
          }
        }
      }
    }
    return list.join("\n");
  }

  getUser(userId) {
    final workspaceMember = Provider.of<Workspaces>(context, listen: false).members;
    int index = workspaceMember.indexWhere((e) => e["id"] == userId);

    if (index != -1) {
      return {
        "avatar_url":workspaceMember[index]["avatar_url"],
        "full_name":workspaceMember[index]["full_name"]
      };
    }else {
      return {
        "avatar_url": "",
        "full_name": "Bot"
      };
    }
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  processDataMessageToJump(Map message , String conversationId) async {
    final auth  = Provider.of<Auth>(context, listen: false);
    bool hasConv = await Provider.of<DirectMessage>(context, listen: false).getInfoDirectMessage(auth.token, message["conversation_id"]);
    if (!hasConv) return;
    Provider.of<DirectMessage>(context, listen: false).processDataMessageToJump({...message, "conversation_id": conversationId}, auth.token, auth.userId);
  }

  onChangeCheckBox(value, elText, commentId) {
    final issue = widget.mention["issue"];
    final auth = Provider.of<Auth>(context, listen: false);
    final workspaceId = widget.mention["workspace_id"];
    final channelId = widget.mention["channel_id"];

    if (elText.length >= 1) {
      String description = issue["description"];
      int index = description.indexOf(elText) - 3;
      String newText = description.replaceRange(index , index + 1, value ? "x" : " ");
      issue["description"] = newText;
      var result = Provider.of<Messages>(context, listen: false).checkMentions(newText);
      var listMentionsNew = result["success"] ? result["data"].where((e) => e["type"] == "user").toList().map((e) => e["value"]).toList() : [];

      var dataDescription = {
        "description": newText,
        "channel_id":  channelId,
        "workspace_id": workspaceId,
        "user_id": auth.userId,
        "type": "issues",
        "from_issue_id": issue["id"],
        "from_id_issue_comment": issue["id"],
        "list_mentions_old": issue["mentions"],
        "list_mentions_new": listMentionsNew
      };

      Provider.of<Channels>(context, listen: false).updateIssueTitle(auth.token, workspaceId, channelId, issue["id"], issue["title"], dataDescription);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final token = auth.token;
    final isDark = auth.theme == ThemeType.DARK;
    final currentUser = Provider.of<User>(context, listen: true).currentUser;
    var mentionInThread = widget.mention["message"] == null ? false: Utils.checkedTypeEmpty(widget.mention["message"]["parent_id"]);
    final customColor = Provider.of<User>(context, listen: false).currentUser["custom_color"];

    return MouseRegion(
      onEnter: (event) => setState(() { _isHover = true; }),
      onExit: (event) => setState(() { _isHover = false; }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(4.0)
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 32,
                  margin: EdgeInsets.only(bottom: 2.0),
                  padding: const EdgeInsets.only(top: 8.0, bottom: 5.0, left: 12.0),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF5E5E5E) : Color(0xFFEAE8E8),
                    borderRadius: BorderRadius.all(
                      Radius.circular(3.0)
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Color(0xFF1F2933)),
                          children: <TextSpan>[
                            TextSpan(text: Utils.getUserNickName(widget.mention["creator_id"]) ?? widget.mention["creator_name"], style: TextStyle(fontWeight: FontWeight.w600)),
                            TextSpan(text: ' mentioned you in '),
                            TextSpan(text: mentionInThread ? "a thread in " : ""),
                            TextSpan(
                              text: widget.sourceName,
                              style: TextStyle(fontWeight: Utils.checkedTypeEmpty(widget.mention["channel_id"])
                                  ? FontWeight.bold
                                  : FontWeight.normal)
                            ),
                            Utils.checkedTypeEmpty(widget.issueUniq) ? TextSpan(
                              text: " #" + widget.issueUniq,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Color(0XFF1F2933)
                              )
                            ) : TextSpan(),
                            (widget.mention["unread"] ?? []) ? TextSpan(
                              text: '   NEW' ,
                              style: TextStyle(
                              fontWeight: FontWeight.w600, 
                              color: Palette.errorColor,fontStyle: FontStyle.italic, fontSize: 10.5)
                            ) :TextSpan(text: ' '),
                          ],
                        ),
                      ),
                      !_isHover ? Container() : Row(
                        children: [
                          widget.mention["conversation_id"] == null
                          ? ContextMenu(
                            child: HoverItem(
                              child: Icon(CupertinoIcons.smiley, size: 18,)
                            ),
                            contextMenu: Container(
                              width: 400, height: 556.75,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color:isDark ? const Color(0xFF3D3D3D) : const Color(0xFFFFFFFF),
                                border: Border.all(width: 0.3, color:isDark ? Colors.grey[700]! : Colors.grey)
                              ),
                              child: ListEmojiWidget(
                                workspaceId: widget.mention["workspace_id"],
                                onSelect: (emoji){
                                  Provider.of<Messages>(context, listen: false).handleReactionMessage({
                                    "message_id": widget.mention["message"]["id"],
                                    "channel_id": widget.mention["channel_id"],
                                    "workspace_id": widget.mention["workspace_id"],
                                    "token": token,
                                    "emoji_id": emoji.id
                                  });
                                },
                                onClose: () {
                                  context.contextMenuOverlay.close();
                                }
                              ),
                            )
                          ) : Container(),
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
                                if ( widget.mention["conversation_id"] == null){
                                  var jumpToIssue = widget.mention["issue"]["id"] != null ? true : false;
                                  if(jumpToIssue) {
                                    var issue = widget.mention["issue"];
                                    if (widget.mention["issue_comment"]["id"] == null)
                                    issue["mention_id"] = widget.mention["issue_comment"]["id"];
                                    issue["channel_id"] = widget.mention["channel_id"];
                                    issue["workspace_id"] = widget.mention["workspace_id"];
                                    issue["is_closed"] = false; // de default tranh trang man hinh
                                    issue["comments"] = [];
                                    issue["is_closed"] = false;
                                    Provider.of<Channels>(context, listen: false).onChangeOpenIssue({...issue!, 'type': 'edited', 'comments': issue['comments'], 'timelines': issue['timelines'], 'fromMentions': true});
                                    Provider.of<Auth>(context, listen: false).keyDrawer.currentState!.openEndDrawer();
                                  } else {
                                    Provider.of<Messages>(context, listen: false).handleProcessMessageToJump(
                                      {
                                        ...widget.mention["message"],
                                        "avatarUrl": widget.mention["creator_url"] ?? "",
                                        "fullName": widget.mention["creator_name"],
                                        "workspace_id": widget.mention["workspace_id"],
                                        "channel_id": widget.mention["channel_id"]
                                      }
                                      , context);
                                  }
                                } else {
                                  var indexConverastion = Provider.of<DirectMessage>(context, listen: false).data.indexWhere((element) => element.id == widget.mention["conversation_id"]);
                                  if (indexConverastion != -1){
                                    // hien tai viec nhay vao hoi thoai co van de =>
                                    // -> doi voi tin nhan trong luong chinj
                                    // chi mo hoi thoai
                                    // -> doi voi tin nhan trong thread
                                    // nhay vao luong chinh, mo thread;

                                    DirectModel dm  = Provider.of<DirectMessage>(context, listen: false).data[indexConverastion];
                                    var dataDMMessages = Provider.of<DirectMessage>(context, listen: false).getCurrentDataDMMessage(widget.mention["conversation_id"]);

                                    if (mentionInThread){
                                      var parentMessage = {
                                        "id": widget.mention["message"]["parent_id"],
                                        "isChannel": false,
                                        "conversationId": widget.mention["conversation_id"],
                                        "attachments": [],
                                        "messsage": "Message is not loaded",
                                        "insertedAt": widget.mention["inserted_at"],
                                      };
                                      var indexMessage = (dataDMMessages["messages"] as List).indexWhere((element) => element["id"] == widget.mention["message"]["parent_id"]);

                                      if (indexMessage == -1){
                                        var messageOnIsar = await MessageConversationServices.getListMessageById(widget.mention["message"]["parent_id"], "");
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
                                      processDataMessageToJump(widget.mention["message"], widget.mention["conversation_id"]);
                                    }
                                    // trong truong hojp hoi thoai chua dc load hoac tin nhan ko trong hoi thoaij
                                    // set ["messages"] = [{tin nhan}]
                                  }
                                }
                              },
                              icon: Icon(CupertinoIcons.arrow_turn_up_left)
                            ),
                          ),
                          if (widget.mention["issue"]["id"] == null )Container(
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
                                var isChild = widget.mention["message"]["parent_id"] != null;
                                var messages;
                                if (isChild) {
                                  messages = widget.mention["parent"];
                                }
                                else {
                                  messages = widget.mention;
                                }

                                final workspaceId = widget.mention["workspace_id"];
                                final channelId = widget.mention["channel_id"];
                                Map parentMessage = {
                                  "id": isChild ? messages["id"] : messages["message"]["id"],
                                  "message": isChild ? messages["message"] : messages["message"]["message"],
                                  "avatarUrl": isChild ? messages["avatar_url"] : messages["creator_url"],
                                  "fullName": isChild ? messages["full_name"] : messages["creator_name"],
                                  "insertedAt": messages["inserted_at"],
                                  "attachments": isChild ? messages["attachments"] : messages["message"]["attachments"],
                                  "userId": isChild ? messages["user_id"] : messages["message"]["user_id"],
                                  "isChannel": true,
                                  "conversationId": null,
                                  "channelId": channelId,
                                  "workspaceId": workspaceId,
                                  "reactions": messages["reactions"],
                                };
                                Provider.of<Messages>(context, listen: false).openThreadMessage(true, parentMessage);
                                Provider.of<Threads>(context, listen: false).updateThreadUnread(workspaceId, channelId, parentMessage, token);
                                FocusInputStream.instance.focusToThread();
                              },
                              icon: Icon(CupertinoIcons.chat_bubble_text)
                            ),
                          ),
                          // Container(
                          //   width: 18,
                          //   margin: EdgeInsets.only(right: 10),
                          //   child: IconButton(
                          //     hoverColor: Colors.transparent,
                          //     focusColor: Colors.transparent,
                          //     highlightColor: Colors.transparent,
                          //     splashColor: Colors.transparent,
                          //     iconSize: 18,
                          //     padding: EdgeInsets.zero,
                          //     onPressed: () {},
                          //     icon: Icon(CupertinoIcons.bookmark)
                          //   )
                          // )
                        ]
                      )
                    ]
                  )
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
                    borderRadius: BorderRadius.all(
                      Radius.circular(4.0)
                    ),
                  ),
                  margin: EdgeInsets.only(top: 2), padding: EdgeInsets.symmetric(vertical: 8),
                  child: widget.mention["type"] == "channel" || widget.mention["conversation_id"] != null ? CustomSelectionArea(
                    child: ChatItemMacOS(
                      conversationId: widget.mention["conversation_id"],
                      id: widget.mention["message"]["id"],
                      userId: widget.mention["message"]["user_id"],
                      isChildMessage: widget.mention["message"]["parent_id"] != null,
                      isMe: widget.mention["message"]["user_id"] == auth.userId,
                      message: widget.mention["message"]["message"] ?? "",
                      avatarUrl: widget.mention["creator_url"] ?? "",
                      insertedAt: widget.mention["message"]["inserted_at"] ?? widget.mention["message"]["time_create"],
                      fullName: Utils.getUserNickName(widget.mention["message"]["user_id"]) ?? widget.mention["creator_name"],
                      attachments: widget.mention["message"]["attachments"],
                      isFirst: true,
                      accountType: widget.mention["message"]["account_type"] ?? "user",
                      isChannel: widget.mention["conversation_id"] == null,
                      isThread: false,
                      count: 0,
                      infoThread:  [],
                      success: true,
                      showHeader: false,
                      showNewUser: true,
                      isLast: true,
                      isBlur: false ,
                      reactions:  Utils.checkedTypeEmpty(widget.mention["message"]["reactions"]) ? widget.mention["message"]["reactions"]  : [],
                      isViewMention: true,
                      channelId: widget.mention["channel_id"],
                      isDark: isDark,
                      customColor: customColor,
                      workspaceId: widget.mention['workspace_id'],
                    ),
                  ) : CustomSelectionArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.only(left: 16, right: 8),
                          child: GestureDetector(
                            onTap: () {
                              if (currentUser["id"] != widget.mention["creator_id"]) {
                                onShowUserInfo(context, widget.mention["creator_id"]);
                              }
                            },
                            child: CachedImage(
                              getUser(widget.mention["creator_id"])["avatar_url"],
                              radius: 34,
                              width: 34,
                              height: 34,
                              name: widget.mention["creator_name"],
                              isAvatar: true
                            )
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (currentUser["id"] != widget.mention["creator_id"]) {
                                        onShowUserInfo(context, widget.mention["creator_id"]);
                                      }
                                    },
                                    child: Text(
                                      Utils.getUserNickName(widget.mention["creator_id"]) ?? widget.mention["creator_name"],
                                      style: TextStyle(
                                        color: widget.mention["creator_id"] == currentUser["id"] ? Colors.lightBlue : isDark ? Color(0xffF5F7FA) : Color(0xff102A43),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(left: 5, top: 2),
                                    child: Text(
                                      widget.showDateThread,
                                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Color(0XFF323F4B)),
                                    ),
                                  )
                                ],
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 4.0, bottom: 8.0),
                                child: Markdown(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  isViewMention: true,
                                  imageBuilder: (uri, title, alt) {
                                    return MarkdownAttachment(alt: alt, uri: uri);
                                  },
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(fontSize: 16.5, height: 1, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                    a: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                    code: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                                    codeblockDecoration: BoxDecoration()
                                  ),
                                  onTapLink: (link, url, uri) async{
                                    if (await canLaunch(url ?? "")) {
                                      await launch(url ?? "");
                                    } else {
                                      throw 'Could not launch $url';
                                    }
                                  },
                                  selectable: true,
                                  extensionSet: md.ExtensionSet(
                                    md.ExtensionSet.gitHubFlavored.blockSyntaxes, [md.EmojiSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
                                  ),
                                  checkboxBuilder: (value, variable) {
                                    return MarkdownCheckbox(
                                      value: value,
                                      variable: variable,
                                      onChangeCheckBox: onChangeCheckBox,
                                      commentId: widget.mention["issue"]["id"] ?? widget.mention["issue_comments"]["id"],
                                      isDark: isDark
                                    );
                                  },
                                  data: parseComment(widget.text, false)
                                ),
                              )
                            ]
                          )
                        )
                      ]
                    )
                  )
                )
              ]
            )
          )
        ]
      )
    );
  }
}
