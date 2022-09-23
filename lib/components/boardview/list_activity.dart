import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/drop_zone.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/common/video_player.dart';
import 'package:workcake/components/custom_confirm_dialog.dart';
import 'package:workcake/components/message_item/attachments/attachments.dart';
import 'package:workcake/flutter_mention/custom_selection.dart';
import 'package:workcake/flutter_mention/flutter_mentions.dart';
import 'package:workcake/providers/providers.dart';

import '../../markdown/style_sheet.dart';
import '../../markdown/widget.dart';
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
  GlobalKey<FlutterMentionsState> key = GlobalKey<FlutterMentionsState>();
  bool onDropFile = false;
  bool onFocus = false;

  getDataMentions(channelId) {
    // get data ChannelMember with channelId
    final channelMembers = Provider.of<Channels>(context, listen: false).getDataMember(channelId);
    List<Map<String, dynamic>> suggestionMentions = [];
    for (var i = 0 ; i < channelMembers.length; i++){
      Map<String, dynamic> item = {
        'id': channelMembers[i]["id"],
        'type': 'user',
        'display': Utils.getUserNickName(channelMembers[i]["id"]) ?? channelMembers[i]["full_name"],
        'full_name': Utils.checkedTypeEmpty(Utils.getUserNickName(channelMembers[i]["id"]))
            ? "${Utils.getUserNickName(channelMembers[i]["id"])} • ${channelMembers[i]["full_name"]}"
            : channelMembers[i]["full_name"],
        'photo': channelMembers[i]["avatar_url"]
      };
      suggestionMentions += [item];
    }

    return suggestionMentions;
  }

  getSuggestionIssue() {
    List preloadIssues = Provider.of<Workspaces>(context, listen: false).preloadIssues;
    List dataList = [];

    for (var i = 0 ; i < preloadIssues.length; i++){
      Map<String, dynamic> item = {
        'id': "${preloadIssues[i]["id"]}-${preloadIssues[i]["workspace_id"]}-${preloadIssues[i]["channel_id"]}",
        'type': 'issue',
        'display': preloadIssues[i]["unique_id"].toString(),
        'title': preloadIssues[i]["title"],
        'channel_name': preloadIssues[i]["channel_name"],
        'is_closed': preloadIssues[i]["is_closed"]
      };

      dataList += [item];
    }

    return dataList;
  }

  parseMention(comment, channelId) {
    var parse = Provider.of<Messages>(context, listen: false).checkMentions(comment);
    if (parse["success"] == false) return comment;
    return Utils.getStringFromParse(parse["data"]);
  }

  onDeleteComment(comment) {
    CardItem card = widget.card;
    final token = Provider.of<Auth>(context, listen: false).token;
    int index = card.activity.indexWhere((e) => e["id"] == comment["id"]);

    if (index == -1) return;

    Provider.of<Boards>(context, listen: false).deleteComment(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id, comment["id"]);
    this.setState(() { card.activity.removeAt(index); });
  }

  onCommentCard() async {
    CardItem card = widget.card;
    if (key.currentState?.controller?.markupText.trim() != "") {
      final token = Provider.of<Auth>(context, listen: false).token;
      await Provider.of<Boards>(context, listen: false).sendCommentCard(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id, key.currentState?.controller?.markupText.trim(), fileItems);
      await Provider.of<Boards>(context, listen: false).getActivity(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id).then((res) {
        this.setState(() {
          card.activity = res["activity"];
          fileItems = [];
        });
      });
      key.currentState?.controller?.clear();
    }
  }

  List fileItems = [];

  uploadCommentAttachment(files) async {
    final token = Provider.of<Auth>(context, listen: false).token;
    for(var i = 0; i < files.length; i++) {
      var file = files[i];
      var existed  =  fileItems.indexWhere((element) => (element["path"] == files[i]["path"] && element['name'] == file['name']));
      if (existed == -1) {
        file["uploading"] = true;
        fileItems += [file];
      }
    }

    for (var i = 0; i < fileItems.length; i++) {
      if (fileItems[i]["uploading"] == true) {
        var uploadFile = await Provider.of<Work>(context, listen: false).getUploadData(fileItems[i]);
        await Provider.of<Work>(context, listen: false).uploadImage(token, widget.card.workspaceId, uploadFile, uploadFile["type"], (value){}).then((res) {
          if (res["success"] == true) {
            this.setState(() {
              fileItems[i] = res;
              fileItems[i]["uploading"] = false;
            });
          }
        });
      }
    }

    if (key.currentState != null) key.currentState!.focusNode.requestFocus();
    StreamDropzone.instance.initDrop();
  }

  onRemoveAttachment(att) {
    final index = fileItems.indexOf(att);
    this.setState(() {
      fileItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User>(context, listen: true).currentUser;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final auth = Provider.of<Auth>(context, listen: false);
    final bool isDark = auth.theme == ThemeType.DARK;
    CardItem card = widget.card;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 10),
          child: Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 20, thickness: 1)
        ),
        SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 1),
              child: CachedAvatar(currentUser["avatar_url"], name: currentUser["full_name"], width: 30, height: 30)
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  DropZone(
                    stream: StreamDropzone.instance.dropped,
                    onHighlightBox: (value) {
                      this.setState(() { onDropFile = value; });
                    },
                    builder: (context, files) {
                      if(files.data != null && files.data.length > 0) {
                        uploadCommentAttachment(files.data ?? []);
                      }
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isDark ? Palette.backgroundTheardDark : Color(0xffF3F3F3),
                          border: Border.all(color: onFocus ? isDark ? Palette.calendulaGold : Palette.dayBlue : isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB))
                        ),
                        child: Column(
                          children: [
                            Focus(
                              onFocusChange: (focus) {this.setState(() { onFocus = focus; });},
                              child: FlutterMentions(
                                onChanged: (value) {
                                  this.setState(() {});
                                },
                                parseMention: Provider.of<Messages>(context, listen: false).checkMentions,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  color: isDark ? Colors.grey[300] : Colors.grey[800]
                                ),
                                key: key,
                                isIssues: true,
                                isUpdate: false,
                                isCodeBlock: false,
                                isShowCommand: false,
                                isKanbanMode: true,
                                autofocus: false,
                                minLines: 2,
                                handleUpdateIssues: () {
                                  onCommentCard();
                                },
                                cursorColor: isDark ? Colors.grey[400] : Colors.black87,
                                isDark: isDark,
                                islastEdited: false,
                                decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.transparent)
                                    // borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.transparent),
                                    // borderSide: BorderSide(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                                    borderRadius: const BorderRadius.all(Radius.circular(4))
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                  hintText: "Write a comment",
                                  hintStyle: TextStyle(fontSize: 13.5)
                                ),
                                suggestionListDecoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                                ),
                                onSearchChanged: (trigger ,value) { },
                                mentions: [
                                  Mention(
                                    markupBuilder: (trigger, mention, value, type) {
                                      return "=======@/$mention^^^^^$value^^^^^$type+++++++";
                                    },
                                    trigger: '@',
                                    style: TextStyle(
                                      color: Colors.lightBlue,
                                    ),
                                    data: getDataMentions(currentChannel['id']),
                                    matchAll: true,
                                  ),
                                  Mention(
                                    markupBuilder: (trigger, mention, value, type) {
                                      return "=======#/$mention^^^^^$value^^^^^$type+++++++";
                                    },
                                    trigger: "#",
                                    style: const TextStyle(color: Colors.lightBlue),
                                    data: getSuggestionIssue(),
                                    matchAll: true
                                  )
                                ]
                              )
                            ),
                            if(fileItems.length > 0) Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB))
                                )
                              ),
                              alignment: Alignment.centerLeft,
                              margin: EdgeInsets.symmetric(horizontal: 10),
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: fileItems.map<Widget>((attachment) {
                                    return CommentAttachment(attachment: attachment, onRemoveAttachment: onRemoveAttachment, onEditComment: true);
                                  }).toList()
                                )
                              )
                            )
                          ]
                        )
                      );
                    }
                  ),
                  if(key.currentState?.controller?.text.trim() != "" || fileItems.length > 0) Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 5),
                        InkWell(
                          onTap: () {
                            key.currentState?.controller?.clear();
                            key.currentState?.focusNode.unfocus();
                          },
                          child: Text("Cancel")
                        ),
                        SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Color(0xffFAAD14)),
                          child: TextButton(
                          onPressed: () async {
                            onCommentCard();
                          },
                          child: Text("Submit", style: TextStyle(color: Colors.white, fontSize: 14)))
                        )
                      ]
                    )
                  )
                ],
              )
            )
          ]
        ),
        SizedBox(height: 20),
        Column(
          children: card.activity.map((e) {
            return CommentActivity(comment: e, card: card, getDataMentions: getDataMentions, getSuggestionIssue: getSuggestionIssue, onDeleteComment: onDeleteComment);
          }).toList(),
        )
      ]
    );
  }
}

class CommentAttachment extends StatefulWidget {
  const CommentAttachment({
    Key? key,
    this.attachment,
    this.onRemoveAttachment,
    this.onEditComment
  }) : super(key: key);

  final attachment;
  final onRemoveAttachment;
  final onEditComment;

  @override
  State<CommentAttachment> createState() => _CommentAttachmentState();
}

class _CommentAttachmentState extends State<CommentAttachment> {
  bool onHover = false;

  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachment;

    return MouseRegion(
      onEnter: (value) { this.setState(() { onHover = true; }); },
      onExit: (value) { this.setState(() { onHover = false; }); },
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
        margin: EdgeInsets.only(right: 12),
        height: 84,
        width: 66,
        child: attachment["uploading"] == true ?
          Icon(PhosphorIcons.spinner, color: Colors.grey[600], size: 32) : Stack(
          children: [
            CachedImage(attachment["content_url"], width: 66, height: 84, radius: 4),
            if (onHover && widget.onEditComment) Positioned(
              right: 2,
              top: 2,
              child: InkWell(
                onTap: () {
                  widget.onRemoveAttachment(widget.attachment);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xff5E5E5E),
                    borderRadius: BorderRadius.circular(16)
                  ),
                  width: 16,
                  height: 16,
                  child: Center(child: Icon(PhosphorIcons.x, size: 13))
                ),
              )
            )
          ]
        )
      ),
    );
  }
}

class CommentActivity extends StatefulWidget {
  CommentActivity({
    this.comment,
    this.card,
    this.getSuggestionIssue,
    this.getDataMentions,
    this.onDeleteComment,
    Key? key
  }) : super(key: key);

  final comment;
  final card;
  final getSuggestionIssue;
  final getDataMentions;
  final onDeleteComment;

  @override
  State<CommentActivity> createState() => _CommentActivityState();
}

class _CommentActivityState extends State<CommentActivity> {
  GlobalKey<FlutterMentionsState> key = GlobalKey<FlutterMentionsState>();
  bool onEditComment = false;
  bool onFocus = false;
  List removeFiles = [];
  List addFiles = [];

  parseTime(comment) {
    final auth = Provider.of<Auth>(context, listen: false);
    DateTime dateTime = DateTime.parse(comment["inserted_at"]);
    final String messageTime = DateFormat('kk:mm').format(DateTime.parse(comment["inserted_at"]).add(Duration(hours: 7)));
    final String dayTime = DateFormatter().getVerboseDateTimeRepresentation(dateTime, auth.locale);

    return (comment["inserted_at"] != "" && comment["inserted_at"] != null)
      ? "${dayTime == "Today" ? messageTime : DateFormatter().renderTime(DateTime.parse(comment["inserted_at"]), type: "MMMd") + " at $messageTime"}"
      : "";
  }

  editComment() async {
    CardItem card = widget.card;
    if (key.currentState?.controller?.markupText.trim() != "") {
      final token = Provider.of<Auth>(context, listen: false).token;
      Provider.of<Boards>(context, listen: false).editCommentCard(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id,
        key.currentState?.controller?.markupText.trim(), widget.comment["id"], addFiles, removeFiles);
      widget.comment["comment"] = key.currentState?.controller?.markupText.trim();
      key.currentState?.controller?.clear();
    }
    this.setState(() {onEditComment = false;});
  }

  onRemoveAttachment(att) {
    final index = widget.comment["attachments"].indexOf(att);
    if (index != -1) {
      this.setState(() {
        widget.comment["attachments"].removeAt(index);
      });
      removeFiles.add(att);
    }
  }

  onCancel() {
    key.currentState?.controller?.clear();
    key.currentState?.focusNode.unfocus();
    this.setState(() {
      onEditComment = false;
      widget.comment["attachments"] = widget.comment["attachments"] + removeFiles;
    });
  }

  processFiles(files) async {
    final token = Provider.of<Auth>(context, listen: false).token;
    for(var i = 0; i < files.length; i++) {
      var file = files[i];
      var existed  =  addFiles.indexWhere((element) => (element["path"] == files[i]["path"] && element['name'] == file['name']));
      if (existed == -1) {
        file["uploading"] = true;
        addFiles += [file];
      }
    }

    for (var i = 0; i < addFiles.length; i++) {
      if (addFiles[i]["uploading"] == true) {
        var uploadFile = await Provider.of<Work>(context, listen: false).getUploadData(addFiles[i]);
        await Provider.of<Work>(context, listen: false).uploadImage(token, widget.card.workspaceId, uploadFile, uploadFile["type"], (value){}).then((res) {
          if (res["success"] == true) {
            this.setState(() {
              addFiles[i] = res;
              addFiles[i]["uploading"] = false;
            });
          }
        });
      }
    }

    if (key.currentState != null) key.currentState!.focusNode.requestFocus();
    StreamDropzone.instance.initDrop();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User>(context, listen: true).currentUser;
    final auth = Provider.of<Auth>(context, listen: true);
    final bool isDark = auth.theme == ThemeType.DARK;
    final comment = widget.comment;
    final author = comment["author"];
    final card = widget.card;
    final attachments = (comment["attachments"] ?? []) + addFiles;

    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 2),
            child: CachedAvatar(author["avatar_url"], name: author["full_name"], width: 30, height: 30)
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          Container(
                            margin: EdgeInsets.only(left: 2),
                            child: Text(
                              Utils.getUserNickName(author["id"]) ?? author["full_name"],
                              style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                            )
                          ),
                          SizedBox(width: 10),
                          Text(parseTime(comment), style: TextStyle(color: Color(0xffA6A6A6), fontSize: 13))
                        ]
                      ),
                      if (currentUser["id"] == author["id"] && !onEditComment) Wrap(
                        children: [
                          SizedBox(width: 2),
                          InkWell(
                            onTap: () {
                              this.setState(() {
                                onEditComment = !onEditComment;
                              });
                              Timer(const Duration(milliseconds: 20), () => {
                                key.currentState!.setMarkUpText(comment["comment"])
                              });
                            },
                            child: Icon(PhosphorIcons.pencilSimple, size: 16, color: Colors.grey[isDark ? 500 : 600])
                          ),
                          SizedBox(width: 12),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return CustomConfirmDialog(
                                    title: "Delete comment",
                                    subtitle: "Are you sure you want to delete this comment?",
                                    onConfirm: () async {
                                      widget.onDeleteComment(comment);
                                    }
                                  );
                                }
                              );
                            },
                            child: Icon(PhosphorIcons.trashSimple, size: 16, color: Colors.grey[isDark ? 500 : 600])
                          ),
                          SizedBox(width: 6)
                        ]
                      )
                    ]
                  ),
                  SizedBox(height: 6),
                  Column(
                    children: [
                      DropZone(
                        stream: StreamDropzone.instance.dropped,
                        onHighlightBox: (value) {
                        },
                        builder: (context, files) {
                          if(files.data != null && files.data.length > 0) {
                            processFiles(files.data ?? []);
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? Palette.backgroundTheardDark : Color(0xffF3F3F3),
                              border: Border.all(color: onFocus ? isDark ? Palette.calendulaGold : Palette.dayBlue : isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: Column(
                              children: [
                                onEditComment ? Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4)
                                  ),
                                  child: Focus(
                                    onFocusChange: (value) {
                                      this.setState(() { onFocus = value; });
                                    },
                                    child: FlutterMentions(
                                      onChanged: (value) {
                                        this.setState(() {});
                                      },
                                      parseMention: Provider.of<Messages>(context, listen: false).checkMentions,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        color: isDark ? Colors.grey[300] : Colors.grey[800]
                                      ),
                                      key: key,
                                      isIssues: true,
                                      isUpdate: false,
                                      isCodeBlock: false,
                                      isShowCommand: false,
                                      isKanbanMode: true,
                                      autofocus: true,
                                      handleUpdateIssues: () {
                                        editComment();
                                      },
                                      cursorColor: isDark ? Colors.grey[400] : Colors.black87,
                                      isDark: isDark,
                                      islastEdited: false,
                                      decoration: InputDecoration(
                                        enabledBorder: OutlineInputBorder(
                                          // borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                                          borderSide: BorderSide(color: Colors.transparent),
                                          borderRadius: const BorderRadius.all(Radius.circular(4))
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          // borderSide: BorderSide(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                                          borderSide: BorderSide(color: Colors.transparent),
                                          borderRadius: const BorderRadius.all(Radius.circular(4))
                                        ),
                                        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                        hintText: "Write a comment",
                                        hintStyle: TextStyle(fontSize: 13.5)
                                      ),
                                      suggestionListDecoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                      ),
                                      onSearchChanged: (trigger ,value) { },
                                      mentions: [
                                        Mention(
                                          markupBuilder: (trigger, mention, value, type) {
                                            return "=======@/$mention^^^^^$value^^^^^$type+++++++";
                                          },
                                          trigger: '@',
                                          style: TextStyle(
                                            color: Colors.lightBlue,
                                          ),
                                          data: widget.getDataMentions(card.channelId),
                                          matchAll: true,
                                        ),
                                        Mention(
                                          markupBuilder: (trigger, mention, value, type) {
                                            return "=======#/$mention^^^^^$value^^^^^$type+++++++";
                                          },
                                          trigger: "#",
                                          style: const TextStyle(color: Colors.lightBlue),
                                          data: widget.getSuggestionIssue(),
                                          matchAll: true
                                        )
                                      ]
                                    ),
                                  ),
                                ) : CustomSelectionArea(
                                  child: Container(
                                    padding: EdgeInsets.only(left: 10),
                                    height: 48,
                                    alignment: Alignment.centerLeft,
                                    child: Markdown(
                                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                      physics: NeverScrollableScrollPhysics(),
                                      imageBuilder: (uri, title, alt) {
                                        var tag  = Utils.getRandomString(30);

                                        return ((alt ?? "").toLowerCase().contains('.mp4') || (alt ?? "").contains(".mov")) ? VideoPlayer(att: {"content_url": uri.toString(), "name": alt ?? "video"}) :
                                          GestureDetector(
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
                                        p: TextStyle(fontSize: 14, height: 1.55, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                        a: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, decoration: TextDecoration.underline, fontSize: 14, height: 1.55),
                                        code: TextStyle(fontSize: 15, fontStyle: FontStyle.italic)
                                      ),
                                      checkboxBuilder: (value) {
                                        return Text("- [ ]", style: TextStyle(fontSize: 15.5, height: 1.56));
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
                                  )
                                ),
                                if(attachments.length > 0) Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB))
                                    )
                                  ),
                                  alignment: Alignment.centerLeft,
                                  margin: EdgeInsets.symmetric(horizontal: 10),
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: attachments.map<Widget>((attachment) {
                                        return CommentAttachment(attachment: attachment, onRemoveAttachment: onRemoveAttachment, onEditComment: onEditComment);
                                      }).toList()
                                    )
                                  )
                                )
                              ]
                            )
                          );
                        }
                      ),
                      if(onEditComment) Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(width: 5),
                            InkWell(
                              onTap: () {
                                onCancel();
                              },
                              child: Text("Cancel")
                            ),
                            SizedBox(width: 16),
                            Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Color(0xffFAAD14)),
                              child: TextButton(
                              onPressed: () async {
                                editComment();
                              },
                              child: Text("Submit", style: TextStyle(color: Colors.white, fontSize: 14)))
                            )
                          ]
                        )
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
  }
}