import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/drop_zone.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/widget_text.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/flutter_mention/custom_selection.dart';
import 'package:workcake/flutter_mention/flutter_mentions.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/markdown/style_sheet.dart';
import 'package:workcake/markdown/widget.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/workview_desktop/comment_text_field.dart';
import 'package:workcake/workview_desktop/markdown_attachment.dart';
import 'package:workcake/workview_desktop/markdown_checkbox.dart';
import 'message_item/chat_item_macOS.dart';

class ThreadIssueItem extends StatefulWidget {
  ThreadIssueItem({
    Key? key,
    this.issue
  }) : super(key: key);

  final issue;

  @override
  _ThreadIssueItemState createState() => _ThreadIssueItemState();
}

class _ThreadIssueItemState extends State<ThreadIssueItem> {
  GlobalKey<FlutterMentionsState> key = GlobalKey<FlutterMentionsState>();
  bool islastEdited = false;
  String draftComment = "";
  bool onHighlight = false;
  GlobalKey<CommentTextFieldState> _commentThreadKey = GlobalKey<CommentTextFieldState>();
  bool onEdit = false;
  var selectedComment;
  String itemHover = "";
  bool rebuild = false;

  getMember(userId) {
    final members = Provider.of<Workspaces>(context, listen: false).members;
    final indexUser = members.indexWhere((e) => e["id"] == userId);

    if (indexUser != -1) {
      return members[indexUser];
    } else {
      return {};
    }
  }

  parseComment(comment, bool value) {
    final issue = widget.issue;
    final channelId = issue["channel_id"];
    var commentMention = value ? parseMention(comment, channelId) : comment;
    List list = commentMention.split("\n");

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

  parseMention(comment, channelId) {
    var parse = Provider.of<Messages>(context, listen: false).checkMentions(comment);
    if (parse["success"] == false) return comment;
    return Utils.getStringFromParse(parse["data"]);
  }

  getStartIndex(text, elText) {
    int line = 0;
    List list = text.split('\n');
    for (var i = 0; i < list.length; i++) {
      if (list[i].split(" ").join("") == "-[]$elText" || list[i].split(" ").join("") == "-[x]$elText") {
        line = i;
        break;
      }
    }

    List newlist = list.sublist(0, line);
    return newlist.join('\n').length;
  }

  createNewText(text, value, elText) {
    var startIndex = getStartIndex(text, elText);
    int indexElText = text.indexOf(elText, startIndex);
    String subString = text.substring(0, indexElText);
    List listSubString = subString.split('');
    var index;

    for (var i = listSubString.length - 1; i >= 0; i--) {
      if (listSubString[i] == "]") {
        index = i - 1;
        break;
      }
    }
    if (index == -1 || index == null) return;

    return text.replaceRange(index, index + 1, value ? "x" : " ");
  }

  onChangeCheckBox(value, elText, commentId) {
    final issue = widget.issue;
    final auth = Provider.of<Auth>(context, listen: false);
    final workspaceId = issue["workspace_id"];
    final channelId = issue["channel_id"];
    int indexComment = (issue["children"] ?? []).indexWhere((e) => e["id"].toString() == commentId.toString());

    if (elText.length >= 1) {
      if (indexComment != -1) {
        var issueComment = widget.issue["children"][indexComment];
        String comment = issue["children"][indexComment]["comment"];
        String newText = createNewText(comment, value, elText);
        issue["children"][indexComment]["comment"] = newText;
        var result = Provider.of<Messages>(context, listen: false).checkMentions(newText);
        var listMentionsNew = result["success"] ? result["data"].where((e) => e["type"] == "user").toList().map((e) => e["value"]).toList() : [];

        var dataComment = {
          "comment": newText,
          "channel_id":  channelId,
          "workspace_id": workspaceId,
          "user_id": auth.userId,
          "type": "issue_comment",
          "from_issue_id": issue["id"],
          "from_id_issue_comment": issueComment["id"],
          "list_mentions_old": issueComment["mentions"] ?? [],
          "list_mentions_new": listMentionsNew
        };

        Provider.of<Channels>(context, listen: false).updateComment(auth.token, dataComment);
      } else {
        String description = issue["description"];
        String newText = createNewText(description, value, elText);
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
  }

  onCommentIssue(text) {
    final issue = widget.issue;
    final auth = Provider.of<Auth>(context, listen: false);
    var result = Provider.of<Messages>(context, listen: false).checkMentions(text);
    var listMentionsNew = result["success"] ? result["data"].where((e) => e["type"] == "user").toList().map((e) => e["value"]).toList() : [];

    var dataComment = {
      "comment": text,
      "channel_id":  issue["channel_id"],
      "workspace_id": issue["workspace_id"],
      "user_id": auth.userId,
      "type": "issue_comment",
      "from_issue_id": issue["id"],
      "list_mentions_old": [],
      "list_mentions_new": listMentionsNew
    };

    if (text.trim() != "") {
      if (onEdit) {
        if (selectedComment == null) return;
        dataComment["from_id_issue_comment"] = selectedComment["id"];
        Provider.of<Channels>(context, listen: false).updateComment(auth.token, dataComment);
        onEdit = false;
        selectedComment = null;
      } else {
        Provider.of<Channels>(context, listen: false).submitComment(auth.token, dataComment);
      }
    }
  }
  onChangeIsHover(String value) {
    setState(() {
      itemHover = value;
      rebuild = false;
    });

    Future.delayed(Duration.zero, () {
      if(this.mounted) {
        setState(() => rebuild = false);
      }
    });
  }
  onEditComment(comment) {
    if (selectedComment == null) {
      this.setState(() {
        onEdit = true;
        selectedComment = comment;
      });
    } else {
      if (comment["id"] == selectedComment["id"]) {
        this.setState(() {
          onEdit = false;
          selectedComment = null;
        });
      } else {
        if (comment["id"] != selectedComment["id"]) {
          this.setState(() {
            onEdit = false;
          });
          Future.delayed(Duration(milliseconds: 50), () {
            this.setState(() {
              onEdit = true;
              selectedComment = comment;
            });
          });
        }
      }
    }
  }

  loadMore() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final workspaceId = widget.issue["workspace_id"];
    final channelId = widget.issue["channel_id"];
    final issueId = widget.issue["id"];

    try {
      var resComment = await Dio().post(
        "${Utils.apiUrl}workspaces/$workspaceId/channels/$channelId/issues/update_unread_issue?token=$token",
        data: {"issue_id": issueId}
      );
      if (resComment.data["success"]){
        setState(() {
          widget.issue["children"] = resComment.data["comments"];
        });
      }
    } catch (e) {
      print("Error load thread: $e");
    }
  }

  getInfoIssue() async {
    widget.issue["timelines"] = [];
    widget.issue["comments"] = [];
    Provider.of<Channels>(context, listen: false).onChangeOpenIssue({...widget.issue!, 'type': 'edited', 'comments': [], 'timelines': [], 'fromMentions': true});
    Provider.of<Auth>(context, listen: false).keyDrawer.currentState!.openEndDrawer();
  }

  getChannel(channelId) {
    List channels = Provider.of<Channels>(context, listen: false).data;
    final index = channels.indexWhere((e) => e["id"] == channelId);

    if (index != -1) {
      return channels[index];
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    final auth = Provider.of<Auth>(context, listen: true);
    final isDark = auth.theme == ThemeType.DARK;
    final author = getMember(issue["author_id"]);
    final editer = issue != null && issue["last_edit_id"] != null ? getMember(issue["last_edit_id"]) : null;
    final children = issue["children"];
    final channel = getChannel(issue['channel_id']);
    final directMessage = Provider.of<DirectMessage>(context, listen: true).directMessageSelected;

    return DropZone(
      stream: StreamDropzone.instance.dropped,
      onHighlightBox: (value) {
        this.setState(() { onHighlight = value; });
      },
      builder: (context, files) {
        if (files != null && _commentThreadKey.currentState != null) {
          _commentThreadKey.currentState?.pasteImageFromParent(files);
        }

        return CustomSelectionArea(
          child: Container(
            margin: EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: isDark ? Palette.backgroundRightSiderDark : Palette.backgroundRightSiderLight,
              boxShadow: [if (onHighlight) BoxShadow(color: isDark ? Colors.white : Palette.backgroundRightSiderDark, blurRadius: 3.0)]
              // boxShadow: [if (onHighlight) BoxShadow(color: Colors.white, blurRadius: 3.0, blurStyle: BlurStyle.solid)]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      height: 32,
                      margin: EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.only(left: 12.0),
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF5E5E5E) : Color(0xFFEAE8E8),
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                      ),
                      child: channel == null ? Container() : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(channel["is_private"] ? CupertinoIcons.lock_fill : CupertinoIcons.number, size: 14),
                              SizedBox(width: 4.0),
                              TextWidget(channel["name"], style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Color(0xFF1F2933), fontWeight: FontWeight.w500)),
                              SizedBox(width: 4.0),
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                width: 1,
                                color: Color(0xFFA6A6A6)
                              ),
                              SizedBox(width: 4.0),
                              InkWell(
                                onTap: () => getInfoIssue(),
                                child: Row(
                                  children: [
                                    TextWidget("${issue["title"]}", style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Color(0xFF1F2933), fontWeight: FontWeight.w500)),
                                    SizedBox(width: 4),
                                    TextWidget("#${issue["unique_id"]}  ", style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Color(0xFF1F2933), fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              )
                            ]
                          ),
                          Container(
                            margin: EdgeInsets.only(right: 8),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => getInfoIssue(),
                                  icon: SvgPicture.asset('assets/icons/Jump.svg', color: !isDark ? Palette.backgroundRightSiderDark : Palette.backgroundRightSiderLight)
                                )
                              ]
                            )
                          )
                        ]
                      )
                    ),
                    SizedBox(height: 2),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        child: Container(

                          padding: EdgeInsets.only(left: 20, bottom: 6, top: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: (issue["unread"] != null && issue["unread"]) ? (isDark ? Palette.calendulaGold : Palette.dayBlue) : Colors.transparent, width: 4
                                )
                              )
                            ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  if (author["id"] != auth.userId) {
                                    onShowUserInfo(context, author["id"]);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.only(right: 10),
                                  child: CachedImage(
                                    author["avatar_url"],
                                    width: 40,
                                    height: 40,
                                    radius: 48,
                                    name: author["nickname"] ?? author["full_name"]
                                  )
                                )
                              ),
                              Expanded(
                                child: Container(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(bottom: 4),
                                        child: Text.rich(
                                          TextSpan(
                                            style: TextStyle(
                                              color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65)
                                            ),
                                            children: [
                                              TextSpan(
                                                text: author["nickname"] ?? author["full_name"],
                                                style: TextStyle(fontWeight: FontWeight.w700),
                                                recognizer: TapGestureRecognizer()..onTap = () => author["id"] != auth.userId ? onShowUserInfo(context, author["id"]) : null
                                              ),
                                              WidgetSpan(
                                                child: Container(width: 6)
                                              ),
                                              TextSpan(
                                                text: S.current.commented(Utils.parseDatetime(issue["inserted_at"])),
                                                style: TextStyle(color: isDark ? Color(0xffB7B7B7) : Color(0xff5E5E5E), fontSize: 12.5)
                                              ),
                                              WidgetSpan(
                                                child: Container(width: 6)
                                              ),
                                              TextSpan(
                                                text: issue["last_edit_description"] != null
                                                  ? editer != null ? S.current.editedBy : S.current.edited
                                                  : '',
                                                style: TextStyle(color: isDark ? Color(0xffB7B7B7) : Color(0xff5E5E5E), fontSize: 12.5)
                                              ),
                                              TextSpan(
                                                text: editer != null
                                                  ? " ${editer["nickname"] ?? editer["full_name"]}" : "",
                                                style: TextStyle(fontWeight: FontWeight.w700)
                                              ),
                                              TextSpan(
                                                text: issue["last_edit_description"] != null
                                                  ? S.current.at(Utils.parseDatetime(issue["last_edit_description"])) : "",
                                                  style: TextStyle(color: isDark ? Color(0xffB7B7B7) : Color(0xff5E5E5E), fontSize: 12.5)
                                              )
                                            ]
                                          ),
                                        )
                                      ),
                                      Markdown(
                                        padding: EdgeInsets.only(bottom: 16, top: 4),
                                        physics: NeverScrollableScrollPhysics(),
                                        imageBuilder: (uri, title, alt) {
                                          return MarkdownAttachment(alt: alt, uri: uri);
                                        },
                                        shrinkWrap: true,
                                        styleSheet: MarkdownStyleSheet(
                                          p: TextStyle(fontSize: 15.5, height: 1, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                          a: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                          code: TextStyle(fontSize: 13,color:Colors.blue,fontFamily: "Menlo",height: 1.57),
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
                                        checkboxBuilder: (value, variable) {
                                          return MarkdownCheckbox(
                                            value: value,
                                            variable: variable,
                                            onChangeCheckBox: onChangeCheckBox,
                                            isDark: isDark
                                          );
                                        },
                                        data: (issue["description"] != null && issue["description"] != "") ? parseComment(issue["description"], false) : "_No description provided._",

                                      )
                                    ]
                                  )
                                )
                              )
                            ]
                          ),
                        ),
                      ),
                    ),
                  ]
                ),
                SizedBox(height: 6),
                Container(
                  padding: EdgeInsets.only(left: 72.0, right: 20.0, top: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                  ),
                  child: Column(
                    children: [
                      if (issue["count_child"] != null && issue["count_child"] > children.length) InkWell(
                        onTap: () {
                          loadMore();
                        },
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(bottom: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: isDark ? Palette.calendulaGold : Palette.dayBlue, width: 0.75)
                              )
                            ),
                            child: Text(
                              S.current.showMoreComments(issue["count_child"] - children.length),
                              style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue)
                            )
                          )
                        )
                      ),
                      Container(
                        child: Column(
                          children: children.map<Widget>((item) {
                            final comment = item;
                            final creator = getMember(comment["author_id"]);

                            return Container(
                              key: Key(comment["id"].toString()),
                              decoration: BoxDecoration(
                                color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                              ),
                              child: HoverItem(
                                colorHover: !isDark ? Color.fromARGB(255, 243, 241, 241) : Color(0xff353535),
                                onHover: () => onChangeIsHover("${comment['id']}"),
                                onExit: () => onChangeIsHover(""),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: creator["id"] != auth.userId ? () => onShowUserInfo(context, creator["id"]) : null,
                                      child: Container(
                                        padding: EdgeInsets.all(9),
                                        child: CachedImage(
                                          creator["avatar_url"],
                                          width: 36,
                                          height: 36,
                                          radius: 48,
                                          name: creator["nickname"] ?? creator["full_name"]
                                        )
                                      )
                                    ),
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.only(right: 8,top: 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  margin: EdgeInsets.only(bottom: 4),
                                                  child: Text.rich(
                                                    TextSpan(
                                                      style: TextStyle(
                                                        color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65)
                                                      ),
                                                      children: [
                                                        TextSpan(
                                                          text: creator["nickname"] ?? creator["full_name"],
                                                          style: TextStyle(fontWeight: FontWeight.w700),
                                                          recognizer: TapGestureRecognizer()..onTap = () => creator["id"] != auth.userId ? onShowUserInfo(context, creator["id"]) : null
                                                        ),
                                                        WidgetSpan(
                                                          child: Container(width: 6)
                                                        ),
                                                        TextSpan(
                                                          text: Utils.parseDatetime(comment["inserted_at"]),
                                                          style: TextStyle(color: isDark ? Color(0xffB7B7B7) : Color(0xff5E5E5E), fontSize: 12.5)
                                                        ),
                                                        WidgetSpan(
                                                          child: Container(width: 4)
                                                        ),
                                                        TextSpan(
                                                          text: comment["last_edited_id"] != null
                                                            ? " •  edited ${Utils.parseDatetime(comment["updated_at"])}"
                                                            : "",
                                                          style: TextStyle(color: isDark ? Color(0xffB7B7B7) : Color(0xff5E5E5E), fontSize: 12.5)
                                                        )
                                                      ]
                                                    )
                                                  )
                                                ),
                                                if (comment["author_id"] == auth.userId ) (itemHover=="${comment['id']}") ? Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(4),
                                                    color: !isDark ? Color(0xffF8F8F8) : Color(0xff353535),
                                                    border: Border.all(
                                                      color: isDark ? Color(0xff5E5E5E) : Color(0xffA6A6A6),
                                                      width: 0.5
                                                    )
                                                  ),
                                                  padding: EdgeInsets.only(top: 1,bottom: 1),
                                                  child: Wrap(
                                                    children: [
                                                      Container(
                                                        width: 30,
                                                        child: InkWell(
                                                          focusColor: Colors.transparent,
                                                          hoverColor: Colors.transparent,
                                                          highlightColor: Colors.transparent,
                                                          splashColor: Colors.transparent,
                                                          child: Icon(Icons.edit, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282), size: 17),
                                                          onTap: () {
                                                            onEditComment(comment);
                                                          }
                                                        )
                                                      ),
                                                      Container(
                                                        width: 30,
                                                        child: InkWell(
                                                          focusColor: Colors.transparent,
                                                          hoverColor: Colors.transparent,
                                                          highlightColor: Colors.transparent,
                                                          splashColor: Colors.transparent,
                                                          child: Icon(Icons.delete_outline, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282), size: 17),
                                                          onTap: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (context) {
                                                                return AlertDialog(
                                                                  contentPadding: EdgeInsets.all(0),
                                                                  content: Container(
                                                                    padding: EdgeInsets.symmetric(vertical: 12),
                                                                    width: 200,
                                                                    height: 94,
                                                                    child: Column(
                                                                      children: [
                                                                        Text(S.current.deleteComment),
                                                                        SizedBox(height: 6),
                                                                        Divider(),
                                                                        Row(
                                                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                          children: [
                                                                            TextButton(
                                                                              onPressed: () {
                                                                                Navigator.of(context, rootNavigator: true).pop("Discard");
                                                                              },
                                                                              child: Text(S.current.cancel),
                                                                            ),
                                                                            TextButton(
                                                                              onPressed: () {
                                                                                Provider.of<Channels>(context, listen: false).deleteComment(auth.token, widget.issue["workspace_id"], widget.issue["channel_id"], comment["id"], issue["id"]);
                                                                                Navigator.of(context, rootNavigator: true).pop("Discard");
                                                                              },
                                                                              child: Text(S.current.delete, style: TextStyle(color: Colors.redAccent)),
                                                                            )
                                                                          ]
                                                                        )
                                                                      ]
                                                                    )
                                                                  )
                                                                );
                                                              }
                                                            );
                                                          }
                                                        )
                                                      )
                                                    ]
                                                  )
                                                ):SizedBox(),
                                              ]
                                            ),
                                            Markdown(
                                              padding: EdgeInsets.symmetric(vertical: 4),
                                              physics: NeverScrollableScrollPhysics(),
                                              imageBuilder: (uri, title, alt) {
                                                return MarkdownAttachment(alt: alt, uri: uri);
                                              },
                                              shrinkWrap: true,
                                              styleSheet: MarkdownStyleSheet(
                                                p: TextStyle(fontSize: 15.5, height: 1, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                                a: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                                code: TextStyle(fontSize: 13,color:Colors.blue,fontFamily: "Menlo",height: 1.57),
                                                codeblockDecoration: BoxDecoration()
                                              ),
                                              onTapLink: (link, url, uri) async {
                                                if (await canLaunch(url ?? "")) {
                                                  await launch(url ?? "");
                                                } else {
                                                  throw 'Could not launch $url';
                                                }
                                              },
                                              selectable: true,
                                              checkboxBuilder: (value, variable) {
                                                return MarkdownCheckbox(
                                                  value: value,
                                                  variable: variable,
                                                  onChangeCheckBox: onChangeCheckBox,
                                                  commentId: comment["id"],
                                                  isDark: isDark
                                                );
                                              },
                                              data: (item["comment"] != null && item["comment"] != "") ? parseComment(item["comment"], false) : "_No description provided._",

                                            ),
                                          ]
                                        )
                                      )
                                    )
                                  ]
                                ),
                              ),
                            );
                          }).toList()
                        )
                      ),
                      !onEdit ? Container(
                        padding: EdgeInsets.only(bottom: 12, top: 4),
                        child: CommentTextField(
                          key: _commentThreadKey,
                          isThread: true,
                          onChangeText: (value) {
                            this.setState(() {
                              draftComment = value;
                            });
                          },
                          initialValue: "",
                          editComment: false,
                          issue: issue,
                          isDescription: widget.issue["id"] == null,
                          onCommentIssue: onCommentIssue,
                          dataDirectMessage: directMessage,
                        )
                      ) : Container(
                        padding: EdgeInsets.only(bottom: 12, top: 4),
                        child: CommentTextField(
                          isThread: true,
                          onChangeText: (value) {
                            this.setState(() {
                              draftComment = value;
                            });
                          },
                          initialValue: selectedComment["comment"],
                          editComment: false,
                          issue: issue,
                          isDescription: widget.issue["id"] == null,
                          onCommentIssue: onCommentIssue,
                          dataDirectMessage: directMessage,
                        )
                      )
                    ]
                  )
                )
              ]
            )
          ),
        );
      }
    );
  }
}