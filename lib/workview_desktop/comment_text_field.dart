import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workcake/common/drop_zone.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/flutter_mention/flutter_mentions.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/markdown/style_sheet.dart';
import 'package:workcake/markdown/widget.dart';
import 'package:workcake/models/models.dart';

import '../components/message_item/attachments/attachments.dart';
import 'list_icons_comment.dart';
import 'markdown_checkbox.dart';

class CommentTextField extends StatefulWidget {
  CommentTextField({
    Key? key,
    this.editComment,
    this.issue,
    this.onSubmitNewIssue,
    this.onCommentIssue,
    this.comment,
    this.onUpdateComment,
    required this.onChangeText,
    this.initialValue,
    this.isDescription,
    this.isThread = false,
    this.handleOpenAssigneeDropdown,
  }) : super(key: key);

  final issue;
  final onSubmitNewIssue;
  final onCommentIssue;
  final editComment;
  final comment;
  final onUpdateComment;
  final Function? onChangeText;
  final initialValue;
  final isDescription;
  final isThread;
  final handleOpenAssigneeDropdown;

  @override
  CommentTextFieldState createState() => CommentTextFieldState();
}

class CommentTextFieldState extends State<CommentTextField> {
  FocusNode focusNode = FocusNode();
  bool onEdit = true;
  String text = "";
  TextEditingController _textController = TextEditingController();
  bool isSelectAll = false;
  bool isShow = false;
  List<Map<String, dynamic>> suggestionMentions = [];
  GlobalKey<FlutterMentionsState> key = GlobalKey<FlutterMentionsState>();
  int spaceKey = 1;
  int lastCursorPosition = 0;
  bool fromPreview = false;
  bool highlightDropfile = false;

  @override
  void initState() { 
    super.initState();

    if (widget.initialValue != null) {
      text = widget.initialValue;
    }

    if (widget.editComment) {
      if (widget.comment != null) {
        this.setState(() {
          text = widget.comment["comment"];
        });

      } else {
        this.setState(() {
          text = (widget.issue["description"] ?? "");
        });
      }
    }
    RawKeyboard.instance.addListener(keyboardListener);
  }

  initValue(){
    try {
      key.currentState!.setMarkUpText(text);
      if (widget.editComment) {
        key.currentState!.focusNode.requestFocus();
      }
    } catch (e) {
    }
  }

  @override
  void didUpdateWidget (oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _textController.dispose();
    RawKeyboard.instance.removeListener(keyboardListener);
    super.dispose();
  }

  parseMention(comment) {
    var parse = Provider.of<Messages>(context, listen: false).checkMentions(comment);
    if (parse["success"] == false) return comment;
    return Utils.getStringFromParse(parse["data"]);
  }

  handleEnterEvent() {
    List listText = text.split("\n");
    final selection = key.currentState!.controller!.selection;
    bool check = false;
    int stringLength = 0;
    var currentLine;
    int offset = selection.baseOffset;
    int newOffset = offset;
    RegExp exp = new RegExp(r"[0-9]{1,}.\s");

    for (var i = 0; i < listText.length; i++) {
      var line = listText[i];
      int lineLength = line.length;
      stringLength += lineLength;

      if (offset == stringLength + i) {
        currentLine = i;
        
        break;
      }
    }

    try {
      if (currentLine != null) {
        if (listText[currentLine].trim() == "- [ ]") {
          check = true;
          newOffset = offset - 6;
          listText[currentLine] = "";
        }

        if (listText[currentLine].trim() == "-") {
          check = true;
          newOffset = offset - 2;
          listText[currentLine] = "";
        } else {
          Iterable<RegExpMatch> matches = exp.allMatches(listText[currentLine]);
          
          if (matches.length > 0) {
            if (listText[currentLine].substring(0, 1) != "@") {
              int subString = int.parse(listText[currentLine].substring(0, 1));

              if (listText[currentLine] == "$subString. ") {
                check = true;
                newOffset = offset - 3;
                listText[currentLine] = "";
              }
            }
          }
        }

        if (listText[currentLine].length > 6) {
          if (listText[currentLine].substring(0, 7).contains("- [ ] ")) {
            check = true;
            newOffset = offset + 7;
            listText.insert(currentLine + 1, "- [ ] ");
          } else if (listText[currentLine].substring(0, 7).contains("- [x]")) {
          check = true;
            newOffset = offset + 7;
            listText.insert(currentLine + 1, "- [ ] ");
          } else if (listText[currentLine].substring(0, 2).contains("- ")) {
            check = true;
            newOffset = offset + 3;
            listText.insert(currentLine + 1, "- ");
          } else {
            Iterable<RegExpMatch> matches = exp.allMatches(listText[currentLine]);

            if (matches.length > 0) {
              if (listText[currentLine].substring(0, 1) != "@") {
                int subString = int.parse(listText[currentLine].substring(0, 1));
                check = true;
                newOffset = offset + 4;
                listText.insert(currentLine + 1, "${subString + 1}. ");
              }
            }
          }
        } else if (listText[currentLine].length > 2) {
          if (listText[currentLine].substring(0, 2).contains("- ")) {
            check = true;
            newOffset = offset + 3;
            listText.insert(currentLine + 1, "- ");
          } else {
            Iterable<RegExpMatch> matches = exp.allMatches(listText[currentLine]);

            if (matches.length > 0) {
              int subString = int.parse(listText[currentLine].substring(0, 1));
              check = true;
              newOffset = offset + 4;
              listText.insert(currentLine + 1, "${subString + 1}. ");
            }
          }
        }
      }
    } catch (e) {}

    if (check) {
      this.setState(() {
        text = listText.join("\n");
      });

      key.currentState!.controller!.value = TextEditingValue(text: text);
      key.currentState!.controller!.value = key.currentState!.controller!.value.copyWith(selection: TextSelection.collapsed(offset: newOffset));
      if(Platform.isWindows && key.currentState!.scrollController.offset != 0) key.currentState!.scrollController.jumpTo(key.currentState!.scrollController.offset + 18);
      
      return KeyEventResult.handled;
    } else {
      return KeyEventResult.ignored;
    }
  }

  _surroundTextSelection(String left, String right, type) {
    if (key.currentState!.focusNode.hasFocus) {
      handleAction(left, right, type);
    } else {
      key.currentState!.focusNode.requestFocus();

      Timer(Duration(microseconds: 100), () => {
        handleAction(left, right, type)
      });
    }
  }

  handleAction(left, right, type) {
    final currentTextValue = key.currentState!.controller!.value.text;
    final selection = key.currentState!.controller!.selection;
    final middle = selection.textInside(currentTextValue);
    final before = selection.textBefore(currentTextValue);
    final after = selection.textAfter(currentTextValue);
    var newTextValue;
    var offset;

    if (type == "listDash" || type == "listNumber" || type == "check") {
      List listTextLine = middle.trim().split("\n").where((e) => e.trim() != "").toList();

      if (listTextLine.length > 1) {
        for (var i = 0; i < listTextLine.length; i++) {
          if (listTextLine[i].trim() != "") {
            if (type == "listDash") {
              listTextLine[i] = "- " + listTextLine[i]; 
            } else if (type == "listNumber") {
              listTextLine[i] = "${(i+1)}. " + listTextLine[i]; 
            } else {
              listTextLine[i] = "- [ ] " + listTextLine[i]; 
            }
          }
        }

        newTextValue = before + listTextLine.join("\n") + after; 
        offset = newTextValue.length;
      } else {
        newTextValue = (before.trim() != "" ? before + '\n' : "") + '$left$middle$right' + (after.trim() != "" ? '\n' + after : "");
        offset = selection.baseOffset + left.length + middle.length + (before.trim() == "" ? 0 : 1);
      }
    } else {
      newTextValue = before + '$left$middle$right' + after;
      offset = selection.baseOffset + left.length + middle.length;
    }

    key.currentState!.controller!.value = key.currentState!.controller!.value.copyWith(
      text: newTextValue,
      selection: TextSelection.collapsed(
        offset: offset,
      ),
    );

    applyEditToPreview();
  }

  checkConditions(String string, String nextString) {
    bool check = true;

    if (nextString.length > 0) {
      if (string.contains("- [ ]") || nextString.contains("- [ ]")) {
        check = false;
      } else if (nextString[0] == "-") {
        check = false;
      } else if (string.trim() == "" || nextString.trim() == "") {
        check = false;
      } else if (nextString[0] == "." || string.contains(". ")) {
        check = false;
      }
    }
  
    return check;
  }

  handleKeyEvent(event) {
    var keyDown = event is RawKeyDownEvent;

    if (keyDown) { 
      var keyPresed = event.logicalKey.debugName == "Space";

      if (keyPresed) {
        this.setState(() {
          spaceKey = spaceKey + 1;
        }); 
      } else {
        this.setState(() {
          spaceKey = 0;
        });
      }
    }
  }

  keyboardListener(RawKeyEvent event) {
    final keyId = event.logicalKey.keyId;
    if (event is RawKeyDownEvent) {
      if (event.isMetaPressed) {
        if(keyId.clamp(33, 126) == keyId) {
          // return KeyEventResult.handled;
        }
      } else if (this.mounted && keyId.clamp(33, 126) == keyId) {
        // GlobalKey<ScaffoldState> keyScaffold = Provider.of<Auth>(context, listen: false).keyDrawer;
        // final selectedTab = Provider.of<User>(context, listen: false).selectedTab;
        // if (!(FocusManager.instance.primaryFocus?.context?.widget is EditableText) && selectedTab == "channel" && keyScaffold.currentState != null && keyScaffold.currentState!.isEndDrawerOpen && key.currentState != null && !widget.editComment) {
        //   // if (key.currentState!.isFocus) return KeyEventResult.ignored;
        //   bool openSearchbar = Provider.of<Windows>(context, listen: false).openSearchbar;
        //   if(!openSearchbar) {
        //     // key.currentState!.focusNode.requestFocus();
        //   }
        // }
      } else if(event.isKeyPressed(LogicalKeyboardKey.tab) && key.currentState!.isFocus) {
        widget.handleOpenAssigneeDropdown();
      }
    }

    return KeyEventResult.ignored;
  }

  applyEditToPreview() {
    if (key.currentState == null) return;
    text = key.currentState!.controller!.text;

    if (widget.onChangeText != null) {
      final currentTextValue = key.currentState!.controller!.text;
      if (_textController.text == "" || key.currentState!.controller!.text == "") {
        setState(() { _textController.text = currentTextValue; });
      } else {
        _textController.text = currentTextValue;
      }
    
      widget.onChangeText!(currentTextValue);
    }
  }

  handleUpdateIssues() {
    if (widget.issue["id"] == null) {
      widget.onSubmitNewIssue(key.currentState!.controller!.markupText);
    } else if (widget.editComment) {
      if (widget.comment != null) {
        widget.onUpdateComment(widget.comment, key.currentState!.controller!.markupText);
      } else {
        widget.onUpdateComment(widget.issue["title"], key.currentState!.controller!.markupText, false);
      }
    } else {
      widget.onCommentIssue(key.currentState!.controller!.markupText);

      final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      Provider.of<Workspaces>(context, listen: false).updateUnreadMention(currentWorkspace["id"], widget.issue["id"], true);

      key.currentState!.controller!.clear();
    }
  }

  onChangeCheckBox(value, elText, commentId) {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    int indexComment = widget.issue["comments"].indexWhere((e) => e["id"] == commentId);
    
    if (indexComment != -1) {
      var issueComment = widget.issue["comments"][indexComment];
      String comment = widget.issue["comments"][indexComment]["comment"];
      int index = comment.indexOf(elText) - 3;
      String newText = comment.replaceRange(index , index + 1, value ? "x": " ");
      widget.issue["comments"][indexComment]["comment"] = newText;
      var result = Provider.of<Messages>(context, listen: false).checkMentions(newText);
      var listMentionsNew = result["success"] ? result["data"].where((e) => e["type"] == "user").toList().map((e) => e["value"]).toList() : [];
      var dataComment = {
        "comment": newText,
        "channel_id":  currentChannel["id"],
        "workspace_id": currentWorkspace["id"],
        "user_id": auth.userId,
        "type": "issue_comment",
        "from_issue_id": widget.issue["id"],
        "from_id_issue_comment": commentId,
        "list_mentions_old": issueComment["mentions"] ?? [],
        "list_mentions_new": listMentionsNew
      };

      Provider.of<Channels>(context, listen: false).updateComment(auth.token, dataComment);
    }
  }

  getDataMentions(channelId, auth) {
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
  convertVideoFile(file) async {
    var pathOther = await getTemporaryDirectory();
    var bytesFile;
    var data;
    String out = pathOther.path + "/${file["name"].toString().toLowerCase().replaceAll(" ", "").replaceAll(".mov", "")}.mp4";
    File tempFile = File(file["path"]);
    bytesFile = await tempFile.readAsBytes();
    File newFile = File(pathOther.path +  "/${file["name"].toString().toLowerCase().replaceAll(" ", "")}");
    await newFile.writeAsBytes(bytesFile, mode: FileMode.write);
    await FFmpegKit.execute('-y -i ${newFile.path} -c copy $out').then((session) async {
      final returnCode = await session.getReturnCode();
      if(ReturnCode.isSuccess(returnCode)) {
        File u = File(out);
        data = base64Encode(u.readAsBytesSync());
        await u.delete();
        print("Converted Successfully");
      }
      else if (ReturnCode.isCancel(returnCode)) {
        print("Session Cancel");
      }
      else {
        print("Convert Failed");
      }
    });
    await newFile.delete();
    return data;
  }

  openFileSelector() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    List resultList = [];
    List text = [];

    final currentTextValue = key.currentState!.controller!.text;
    final selection = key.currentState!.controller!.selection;
    final before = selection.baseOffset == -1 ? "" : selection.textBefore(currentTextValue);
    final after = selection.baseOffset == -1 ? "" : selection.textAfter(currentTextValue);
    
    try {
      var myMultipleFiles = await Utils.openFilePicker([
        // XTypeGroup(
        //   extensions: ['jpg', 'jpeg', 'gif', 'png', 'mov', 'mp4'],
        // )
      ]);
      for (var e in myMultipleFiles) {
        Map newFile = {
          "filename": e["name"],
          "path": e["mime_type"].toString().toLowerCase() == "mov" ? await convertVideoFile(e) : base64.encode(e["file"])
        };
        resultList.add(newFile);
        text.add("\n![Uploading ${e["name"]}...]()");
      }

      String newText = before + text.join("\n") + after;

      key.currentState!.controller!.value = key.currentState!.controller!.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(
          offset: newText.length
        ),
      );

     for (var i = 0; i < resultList.length; i++) {
        var file = resultList[i];
        
        final url = Utils.apiUrl + 'workspaces/${currentWorkspace["id"]}/contents?token=$token';
        final body = {
          "file": file,
          "content_type": "image",
          "mime_type": "image",
          "filename": file["filename"]
        };
        Dio().post(url, data: json.encode(body)).then((response) {
          final responseData = response.data;
          final fileName = file["filename"];
          String text = key.currentState!.controller!.text;
          text = text.replaceAll("[Uploading $fileName...", "[$fileName");
          int index = text.indexOf(fileName);

          if (index != -1) {
            var first = index + fileName.length;
            var last = index + fileName.length;
            text = text.replaceRange(int.parse(first.toString()) + 2, int.parse(last.toString()) + 2, Uri.parse(responseData["content_url"]).toString());

            key.currentState!.controller!.value = key.currentState!.controller!.value.copyWith(
              text: text,
              selection: TextSelection.collapsed(
                offset: text.length - after.length
              )
            );
          }
        });
      }

      StreamDropzone.instance.initDrop();
    } on Exception catch (e) {
      print("$e Cancel");
    }
  }

  onPasteImage(listFiles) async {
    
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    List resultList = [];
    List text = [];

    final currentTextValue = key.currentState!.controller!.text;
    final selection = key.currentState!.controller!.selection;
    final before = selection.baseOffset == -1 ? "" : selection.textBefore(currentTextValue);
    final after = selection.baseOffset == -1 ? "" : selection.textAfter(currentTextValue);
    try { 
      for (var e in listFiles) {
        Map newFile = {
          "filename": e["name"],
          "mime_type": "image",
          "path": (e["mime_type"].toString().toLowerCase() == "mov" && !Platform.isWindows) ? await convertVideoFile(e) : base64.encode(e["file"])
        };

        var existed = resultList.indexWhere((element) => element["path"] == newFile["path"]);
        if(existed == -1) {
          resultList.add(newFile);
          text.add("\n![Uploading ${e["name"]}...]()");
        }
      }

      String newText = before + text.join("\n") + after;

      key.currentState!.controller!.value = key.currentState!.controller!.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(
          offset: newText.length
        ),
      );

      for (var i = 0; i < resultList.length; i++) {
        var file = resultList[i];
        final url = Utils.apiUrl + 'workspaces/${currentWorkspace["id"]}/contents?token=$token';
        final body = {
          "file": file,
          "content_type": "image",
          "mime_type": "image",
          "filename": file["filename"]
        };

        Dio().post(url, data: json.encode(body)).then((response) {
          final responseData = response.data;
          final fileName = file["filename"];
          String text = key.currentState!.controller!.text;
          text = text.replaceAll("[Uploading $fileName...", "[$fileName");
          int index = text.indexOf(fileName);

          if (index != -1) {
            var first = index + fileName.length;
            var last = index + fileName.length;
            text = text.replaceRange(int.parse(first.toString()) + 2, int.parse(last.toString()) + 2, Uri.parse(responseData["content_url"]).toString());

            key.currentState!.controller!.value = key.currentState!.controller!.value.copyWith(
              text: text,
              selection: TextSelection.collapsed(
                offset: text.length - after.length
              )
            );
          }
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  pasteImageFromParent(files) {
    List listFiles = [];
    if (files.data != null && files.data.length > 0) {
      for (var item in files.data) {
        int index = listFiles.indexWhere((e) => e["path"] == item["path"]);
        if (index == -1) {
          listFiles.add(item);
        }
      }
    }
    if (listFiles.length > 0) {
      if (key.currentState!.focusNode.hasFocus) {
        onPasteImage(listFiles);
      } else{
        key.currentState!.focusNode.requestFocus();
        key.currentState!.controller!.value = key.currentState!.controller!.value.copyWith(
          text: key.currentState!.controller!.text,
          selection: TextSelection.collapsed(offset: key.currentState!.controller!.text.length)
        );
        onPasteImage(listFiles);
      }
    
      listFiles = [];
      StreamDropzone.instance.initDrop();
    }
  }

  parseComment(comment, bool value) {
    var commentMention = parseMention(comment);
    List list = value ? commentMention.split("\n") : comment.split("\n");

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

  focusTextField() {
    if(!key.currentState!.focusNode.hasFocus) {
      key.currentState!.focusNode.requestFocus();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final auth = Provider.of<Auth>(context, listen: true);
    final isDark = auth.theme == ThemeType.DARK;
    final channelId = widget.issue["id"] != null ? widget.issue['channel_id'] : currentChannel['id'];

    return !widget.isThread ? Container(
      height: widget.issue["id"] == null ? 525 : 350,
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: widget.isThread ? 8 : 16, vertical: widget.isThread ? 8 : 12),
      decoration: BoxDecoration(
        // boxShadow: [BoxShadow(blurRadius: 1.0, color: Colors.green)],
        border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isThread) Container(
            width: (MediaQuery.of(context).size.width)*(3/4),
            child: Wrap(
              direction: Axis.horizontal,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  height: 32,
                  width: 268,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3)
                  ),
                  child: Row(
                    children: [
                      HoverItem(
                        colorHover: Palette.hoverColorDefault,
                        child: InkWell(
                          focusNode: FocusNode()..skipTraversal = true,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: onEdit ? (isDark ? Palette.backgroundTheardDark : Color(0xffEDEDED)) : Colors.transparent,
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              widget.isDescription ? S.current.description : S.current.editComment,
                              style: TextStyle(
                                color: onEdit ? (!isDark ? Color.fromRGBO(0, 0, 0, 0.65) : Colors.white70) : (!isDark ? Color.fromRGBO(0, 0, 0, 0.55) : Colors.grey[400]),
                                fontWeight: onEdit ? FontWeight.w500 : FontWeight.w400
                              )
                            ),
                          ),
                          onTap: () {
                            this.setState(() {
                              if (!onEdit) onEdit = true;
                              fromPreview = true;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 2),
                      Expanded(
                        child: HoverItem(
                          colorHover: Palette.hoverColorDefault,
                          child: InkWell(
                            focusNode: FocusNode()..skipTraversal = true,
                            child: Container(
                              decoration: BoxDecoration(
                                color: !onEdit ? (isDark ? Palette.backgroundTheardDark : Color(0xffEDEDED)) : Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                widget.isDescription ? S.current.preview : S.current.previewComment,
                                style: TextStyle(
                                  color: !onEdit ? (!isDark ? Color.fromRGBO(0, 0, 0, 0.65) : Colors.white70) : (!isDark ? Color.fromRGBO(0, 0, 0, 0.55) : Colors.grey[400]),
                                  fontWeight: !onEdit ? FontWeight.w500 : FontWeight.w400
                                )
                              )
                            ),
                            onTap: () {
                              if (onEdit) {
                                this.setState(() {
                                  onEdit = false;
                                  fromPreview = false;
                                });
                                FocusScope.of(context).unfocus();
                              }
                            },
                          ),
                        ),
                      )
                    ]
                  ),
                ),
                !onEdit ? Container(height: 40, width: 280) : ListIcons(surroundTextSelection: _surroundTextSelection, isDark: isDark),
              ],
            ),
          ),
          SizedBox(height: 2),
          !onEdit ? Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9)),
              color: isDark ? Palette.borderSideColorDark : Palette.backgroundTheardLight
            ),
            height: widget.issue["id"] == null ? 439 : 260,
            child: Markdown(
              controller: ScrollController(),
              imageBuilder: (uri, title, alt) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title != null ? Text(title) : Container(),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: 400,
                        maxWidth: 750
                      ),
                      child: ImageItem(tag: uri, img: {'content_url': uri.toString(), 'name': alt}, previewComment: true, isConversation: false)
                    )
                  ]
                );
              },
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(fontSize: 15, height: 1.2, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                a: TextStyle(fontSize: 15, color: Colors.blue, decoration: TextDecoration.underline),
                code: TextStyle(fontSize: 15, fontStyle: FontStyle.italic,color:Colors.blue,fontFamily: "Menlo",height: 1.57),
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
                md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                [md.EmojiSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
              ),
              checkboxBuilder: (value, variable) {
                return MarkdownCheckbox(value: value, variable: variable, onChangeCheckBox: onChangeCheckBox, commentId: null, isDark: isDark);
              },
              data: parseComment(text, false),
              
            )
          ) : Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4)
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: DropZone(
                      stream: StreamDropzone.instance.dropped,
                      initialData: [],
                      onHighlightBox: (value) => setState(() => highlightDropfile = value),
                      builder: (context, files){
                        if (!widget.isThread) { 
                          pasteImageFromParent(files); 
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
                            boxShadow: [if (highlightDropfile) BoxShadow(color: isDark ? Colors.white : Palette.backgroundRightSiderDark, blurRadius: 3.0)]
                            // boxShadow: [if (highlightDropfile) BoxShadow(color: Colors.white, blurRadius: 3.0, blurStyle: BlurStyle.solid)]
                          ),
                          child: RawKeyboardListener(
                            focusNode: focusNode,
                            onKey: (event) async {
                              if (event.logicalKey.debugName == "Space") {
                                await handleKeyEvent(event);
                              } else {
                                if (spaceKey != 0) {
                                  this.setState(() {
                                    spaceKey = 0;
                                  });
                                }
                              }
                            },
                            child: FlutterMentions(
                              afterFirstFrame: initValue,
                              parseMention: Provider.of<Messages>(context, listen: false).checkMentions,
                              style: TextStyle(
                                fontSize: 15.5,
                                color: auth.theme == ThemeType.DARK ? Colors.grey[300] : Colors.grey[800]
                              ),
                              controller: _textController,
                              key: key,
                              isIssues: true,
                              isUpdate: false,
                              isCodeBlock: false,
                              isShowCommand: false,
                              autofocus: false,
                              handleCodeBlock: (value) { },
                              handleEnterEvent: handleEnterEvent,
                              cursorColor: auth.theme == ThemeType.DARK ? Colors.grey[400] : Colors.black87,
                              onChanged: (value) {
                                Timer(Duration(milliseconds: 0), () {
                                  applyEditToPreview();
                                });
                              },
                              handleUpdateIssues: handleUpdateIssues,
                              isDark: auth.theme == ThemeType.DARK,
                              islastEdited: false,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                contentPadding: EdgeInsets.only(left: 10, bottom: 10, top: 16),
                                hintText: S.current.addDetail,
                                hintStyle: TextStyle(
                                  color: isDark ? Color(0xFFD9D9D9) : Color.fromRGBO(0, 0, 0, 0.35),
                                  fontSize: 14, fontWeight: FontWeight.w300
                                )
                              ),
                              suggestionListDecoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                              ),
                              onSearchChanged: (trigger,value) { },
                              mentions: [
                                Mention(
                                  markupBuilder: (trigger, mention, value, type) {
                                    return "=======@/$mention^^^^^$value^^^^^$type+++++++";
                                  },
                                  trigger: '@',
                                  style: TextStyle(
                                    color: Colors.lightBlue,
                                  ),
                                  data: getDataMentions(channelId, auth),
                                  matchAll: true,
                                ),
                                 Mention(
                                  markupBuilder: (trigger, mention, value, type) {
                                    return "=======#/$mention^^^^^$value^^^^^$type+++++++";
                                  },
                                  trigger: "#",
                                  style: TextStyle(color: Colors.lightBlue),
                                  data: getSuggestionIssue(),
                                  matchAll: true
                                )
                              ]
                            )
                          )
                        );
                      }
                    )
                  ),
                  SizedBox(height: widget.isThread ? 10 : 16),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              height: 32,
                              child: TextButton(
                                focusNode: FocusNode()..skipTraversal = true,
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(Color.fromRGBO(39, 174, 96, 0.2)),
                                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(3),
                                    side: BorderSide(color: Color(0xff27AE60))
                                  )),
                                  padding: MaterialStateProperty.all(
                                    EdgeInsets.symmetric(horizontal: 20)
                                  )
                                ),
                                onPressed: () {  
                                  if (key.currentState!.focusNode.hasFocus) {
                                    openFileSelector();
                                  } else {
                                    key.currentState!.focusNode.requestFocus();

                                    Timer(Duration(microseconds: 100), () => {
                                      openFileSelector()
                                    });
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(S.current.upload, style: TextStyle(color: Color(0xff27AE60), fontWeight: FontWeight.w400)),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(child: Text(S.current.attachImageToComment, style: TextStyle(color: isDark ? Color(0xffD9D9D9) : Colors.black45, overflow: TextOverflow.ellipsis)))
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (widget.issue["id"] != null && !widget.isThread) Container(
                            height: 32,
                            child: TextButton(
                              focusNode: FocusNode()..skipTraversal = true,
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 16)),
                                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                  side: widget.issue["is_closed"] ? BorderSide(color: Color(0xff9AA5B1)) :BorderSide(color: Color(0xffFF7875))
                                )),
                                backgroundColor: MaterialStateProperty.all(isDark ? Colors.transparent : (widget.issue["is_closed"] ? Color(0xffF5F7FA) : Color(0xffFFF1F0))),
                              ),
                              onPressed: () async {
                                if (widget.editComment) {
                                  if (widget.comment != null) {
                                    widget.onUpdateComment(widget.comment, widget.comment["comment"]);
                                  } else {
                                    widget.onUpdateComment(widget.issue["title"], widget.issue["description"], true);
                                  }
                                } else {
                                  var text = (key.currentState != null && key.currentState!.controller!.markupText != "") ? key.currentState!.controller!.markupText : "";

                                  if (text != "") {
                                    var result = Provider.of<Messages>(context, listen: false).checkMentions(text);
                                    var listMentionsNew = result["success"] ? result["data"].where((e) => e["type"] == "user").toList().map((e) => e["value"]).toList() : [];
                                    var dataComment = {
                                      "comment": text,
                                      "channel_id":  currentChannel["id"],
                                      "workspace_id": currentWorkspace["id"],
                                      "user_id": auth.userId,
                                      "from_issue_id": widget.issue["id"],
                                      "list_mentions_old": [],
                                      "list_mentions_new": listMentionsNew
                                    };

                                    await Provider.of<Channels>(context, listen: false).submitComment(token, dataComment);
                                    key.currentState!.controller!.clear();
                                  }

                                  var isClosed = !widget.issue["is_closed"];
                                  this.setState(() {
                                    widget.issue["is_closed"] = isClosed;
                                  });

                                  final issueClosedTab = Provider.of<Work>(context, listen: false).issueClosedTab;
                                  await Provider.of<Channels>(context, listen: false).closeIssue(token, currentWorkspace["id"], widget.issue["channel_id"], widget.issue["id"], isClosed, issueClosedTab);
                                }
                                FocusScope.of(context).unfocus();
                              }, 
                              child: !widget.issue["is_closed"] ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(bottom: 3),
                                    child: !widget.editComment ? Icon(CupertinoIcons.exclamationmark_circle, size: 17, color: Color(0xffFF7875)) : Container(),
                                  ),
                                  SizedBox(width: !widget.editComment ? 8 : 0),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      widget.editComment ? S.current.cancel : 
                                      (key.currentState != null && key.currentState!.controller!.value.text != "") ?
                                      S.current.closeWithComment : S.current.closeIssue,
                                      style: TextStyle(color: Color(0xffFF7875), fontWeight: FontWeight.w400)
                                    ),
                                  ),
                                ],
                              ) : Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  S.current.reopenIssue,
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Color(0xff9AA5B1),
                                    fontWeight: FontWeight.w400
                                  )
                                ),
                              ),
                            ),
                          ),
                          widget.issue["id"] != null ? Container() : Container(
                            height: 32,
                            child: TextButton(
                              focusNode: FocusNode()..skipTraversal = true,
                              style: ButtonStyle(
                                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                  side: BorderSide(color: Color(0xffFF7875))
                                )),
                                backgroundColor: MaterialStateProperty.all(isDark ? Colors.transparent : Color(0xffFFF1F0)),
                              ),
                              onPressed: () => Provider.of<Channels>(context, listen: false).onChangeOpenIssue(null),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(S.current.cancel, style: TextStyle(color: Color(0xffFF7875), fontWeight: FontWeight.w400)),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            height: 32,
                            child: TextButton(
                              focusNode: FocusNode()..skipTraversal = true,
                              style: ButtonStyle(
                                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                )),
                                backgroundColor: MaterialStateProperty.all(Palette.buttonColor),
                                overlayColor: MaterialStateProperty.all(Color(0xff0969DA))
                              ),
                              onPressed: () {
                                handleUpdateIssues();
                                FocusScope.of(context).unfocus();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                child: Text(
                                  widget.editComment ? S.current.updateComment : widget.issue["id"] != null ? S.current.comment : S.current.submitNewIssue,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400
                                  )
                                )
                              )
                            )
                          )
                        ]
                      )
                    ]
                  )
                ]
              )
            ),
          )
        ]
      ),
    ) : Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xff1E1E1E) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: isDark ? null : Border.all(
          color: Color(0xffA6A6A6), width: 0.5
        ),
      ),
      child: RawKeyboardListener(
        focusNode: focusNode,
        onKey: (event) async {
          if (event.logicalKey.debugName == "Space") {
            await handleKeyEvent(event);
          } else {
            if (spaceKey != 0) {
              this.setState(() {
                spaceKey = 0;
              });
            }
          }
        },
        child: Column(
          children: [
            FlutterMentions(
              afterFirstFrame: initValue,
              parseMention: Provider.of<Messages>(context, listen: false).checkMentions,
              style: TextStyle(
                fontSize: 15.5,
                color: auth.theme == ThemeType.DARK ? Colors.grey[300] : Colors.grey[800]
              ),
              controller: _textController,
              key: key,
              isIssues: false,
              isUpdate: false,
              isCodeBlock: false,
              isShowCommand: false,
              isViewThread: true,
              autofocus: false,
              handleCodeBlock: (value) { },
              sendMessages: handleUpdateIssues,
              cursorColor: auth.theme == ThemeType.DARK ? Colors.grey[400] : Colors.black87,
              onChanged: (value) {
                Timer(Duration(milliseconds: 0), () {
                  applyEditToPreview();
                });
              },
              isDark: auth.theme == ThemeType.DARK,
              islastEdited: false,
              decoration: InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.only(left: 5, bottom: 12, top: 12),
                hintText: S.current.addDetail,
                hintStyle: TextStyle(
                  color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65), fontSize: 13.5
                )
              ),
              suggestionListHeight: 200,
              suggestionListDecoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
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
                  data: getDataMentions(channelId, auth),
                  matchAll: true,
                ),
                Mention(
                  markupBuilder: (trigger, mention, value, type) {
                    return "=======#/$mention^^^^^$value^^^^^$type+++++++";
                  },
                  trigger: "#",
                  style: TextStyle(color: Colors.lightBlue),
                  data: getSuggestionIssue(),
                  matchAll: true
                )
              ]
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  margin: EdgeInsets.only(left: 5),
                  child: TextButton(
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                      overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
                    ),
                    child: Icon(CupertinoIcons.plus, color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65), size: 18),
                    onPressed: () {
                      openFileSelector();
                    }
                  )
                ),
                IconButton(
                  icon: Icon(Icons.send,
                    color: const Color(0xffFAAD14),
                    size: 18
                  ),
                  onPressed: handleUpdateIssues,
                ),
              ],
            )
          ],
        )
      )
    );
  }
}