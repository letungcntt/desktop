import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workcake/channels/create_channel_desktop.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/drop_zone.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/drop_target.dart';
import 'package:workcake/components/dropdown_overlay.dart';
import 'package:workcake/components/widget_text.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/markdown/style_sheet.dart';
import 'package:workcake/markdown/widget.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/service_locator.dart';
import 'package:workcake/workview_desktop/history_issue.dart';
import 'package:workcake/workview_desktop/select_attribute.dart';
import 'package:workcake/workview_desktop/transfer_issue.dart';
import 'comment_text_field.dart';
import 'issue_timeline.dart';
import 'markdown_attachment.dart';
import 'markdown_checkbox.dart';
import 'package:http/http.dart' as http;

class CreateIssue extends StatefulWidget {
  const CreateIssue({
    Key? key,
    this.issue,
    this.comments,
    this.timelines,
    this.fromMentions
  }) : super(key: key);

  final issue;
  final comments;
  final timelines;
  final fromMentions;

  get selectedLabels => null;

  @override
  _CreateIssueState createState() => _CreateIssueState();
}

class _CreateIssueState extends State<CreateIssue> {
  FocusNode focusNode = FocusNode();
  FocusNode _titleNode = FocusNode();
  FocusNode _searchChannelName = FocusNode();
  final TextEditingController _searchChannelNameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  List assignees = [];
  List selectedLabels = [];
  List selectedMilestone = [];
  String text = "";
  bool onEdit = true;
  var issue;
  var selectedComment;
  bool editTitle = false;
  bool editDescription = false;
  String description = "";
  String draftComment = "";
  // List timelines = [];
  ScrollController controller = ScrollController();
  var isClosed = false;
  var channel;
  bool isFocusApp = true;
  var box;
  String? selectedChannel;
  final GlobalKey<DropdownOverlayState> _assignKey = GlobalKey<DropdownOverlayState>();
  final GlobalKey<DropdownOverlayState> _labelKey = GlobalKey<DropdownOverlayState>();
  final GlobalKey<DropdownOverlayState> _milestoneKey = GlobalKey<DropdownOverlayState>();
  final GlobalKey<CommentTextFieldState> _textFieldKey = GlobalKey<CommentTextFieldState>();
  bool collapseDescription = true;
  var selectedWorkspace;
  int indexWorkspaceSelected = 0;
  ScrollController issueScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.issue["id"] != null) {
      if (widget.fromMentions != null && widget.fromMentions) getDataIssue();

      setState(() {
        assignees = widget.issue["assignees"] ?? [];
        selectedLabels = widget.issue["labels"] ?? [];
        selectedMilestone = widget.issue["milestone_id"] != null ? [widget.issue["milestone_id"]] : [];
        // timelines = widget.timelines != null ? widget.timelines : [];
        isClosed = false;
      });

    } else {
      if (widget.issue['message'] != null) {
        var isKanbanMode = Provider.of<Channels>(context, listen: false).currentChannel["kanban_mode"];
        if (widget.issue['message']['isChannel'] && !isKanbanMode) {
          selectedChannel = Provider.of<Channels>(context, listen: false).currentChannel['id'].toString();
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final data = Provider.of<Channels>(context, listen: false).data;
            onShowModalSelectChannel(context, data);
          });
        }
      }

      description = widget.issue["description"];
      assignees = widget.issue["assignees"] ?? [];
      selectedLabels = widget.issue["labels"] ?? [];
      selectedMilestone = widget.issue["milestone"] is int ? [widget.issue["milestone"]] : widget.issue["milestone"] ?? [];
      // timelines = [];
    }

    draftComment = widget.issue["draftComment"] ?? "";
    if (widget.issue["from_message"] == null) {
      _titleController.text = widget.issue["title"] ?? "";
    }
    issue = widget.issue;

    Timer.run(() async {
      box = await Hive.openBox("draftsIssue");
    });

    focusNode = FocusNode(onKey: (node, RawKeyEvent keyEvent) {
      if (keyEvent is RawKeyDownEvent) {
        if (keyEvent.isKeyPressed(LogicalKeyboardKey.enter)) {
          handleEnterEvent();
        } else if (keyEvent.isMetaPressed) {
          if (keyEvent.isKeyPressed(LogicalKeyboardKey.backspace)) {
            var newString = _titleController.text.substring(_titleController.selection.extentOffset, _titleController.text.length);
            _titleController.text = newString;
            _titleController.selection = TextSelection.fromPosition(const TextPosition(offset: 0));
          }
        }
      }

      return KeyEventResult.ignored;
    });

    _titleNode = FocusNode(onKey: (node, RawKeyEvent keyEvent) {

      if (keyEvent.isKeyPressed(LogicalKeyboardKey.tab) && _titleNode.hasFocus && keyEvent is RawKeyDownEvent) {
        _textFieldKey.currentState!.focusTextField();
        return KeyEventResult.handled;
      }

      return KeyEventResult.ignored;
    });

    _searchChannelName = FocusNode(onKey: (node, RawKeyEvent keyEvent) {
      if (keyEvent.isKeyPressed(LogicalKeyboardKey.tab) && _searchChannelName.hasFocus && keyEvent is RawKeyDownEvent) {
        Navigator.of(context).pop();
        handleOpenAssigneeDropdown();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    });

    channel = Provider.of<Auth>(context, listen: false).channel;
    channel.on("update_issue", (dataIssue, _j, _r) {
      if (!mounted || dataIssue["id"] != issue["id"]) return;
      updateIssue(dataIssue);
    });
  }

  updateIssue(dataIssue) {
    var data = dataIssue["data"];
    final type = dataIssue["type"];
    final userId = Provider.of<Auth>(context, listen: false).userId;

    if (type == "update_timeline") {
      final index = issue["timelines"].indexWhere((e) => e["id"] == data["id"]);
      if (index == -1) issue["timelines"].add(data);
    } else if (type == "add_assignee") {
      final index = issue["assignees"].indexWhere((e) => e == data);

      if (index == -1) {
        issue["assignees"].add(data);
      }
    } else if (type == "add_label") {
      final index = issue["labels"].indexWhere((e) => e == data);

      if (index == -1) {
        issue["labels"].add(data);
      }
    } else if (type == "add_milestone") {
      issue["milestone_id"] = data;
    } else if (type == "remove_assignee") {
      final index = issue["assignees"].indexWhere((e) => e == data);

      if (index != -1) {
        issue["assignees"].removeAt(index);
      }
    } else if (type == "remove_label") {
      final index = issue["labels"].indexWhere((e) => e == data);

      if (index != -1) {
        issue["labels"].removeAt(index);
      }
    } else if (type == "remove_milestone") {
      issue["milestone_id"] = null;
    } else if (type == "add_comment") {
      final index = issue["comments"].indexWhere((e) => e["id"] == data);

      if (index == -1) {
        issue["comments"].add(data["comment"]);
        issue["users_unread"] = data["users_unread"];

        if (issue["comments_count"] != null) {
          issue["comments_count"] += 1;
        }
      }
    } else if (type == "delete_comment") {
      final index = issue["comments"].indexWhere((e) => e["id"] == data);

      if (index != -1) {
        issue["comments"].removeAt(index);
      }
    } else if (type == "close_issue") {
      issue["is_closed"] = data;
    } else if (type == "update_issue_title") {
      issue["title"] = data["title"];
      issue["last_edit_description"] = data["last_edit_description"];
      issue["last_edit_id"] = data["last_edit_id"];

      if (userId != data["last_edit_id"]) {
        issue["description"] = data["description"];
      }
    } else if (type == "update_comment") {
      final indexComment = issue["comments"].indexWhere((e) => e["id"] == data["id"]);

      if (indexComment != -1) {
        if (userId != data["last_edit_id"]) {
          issue["comments"][indexComment] = data;
        }
      }
    }
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.issue["id"] != null && oldWidget.issue["id"] != widget.issue["id"]) {
      getDataIssue();
    }

    if (oldWidget.selectedLabels != selectedLabels) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  getDataIssue() async {
    var issueData = widget.issue;
    var auth = Provider.of<Auth>(context, listen: false);
    var resData = await Dio().post("${Utils.apiUrl}workspaces/${issueData["workspace_id"]}/channels/${issueData["channel_id"]}/issues?token=${auth.token}", data: {"issue_id": issueData["id"]});
    if (resData.data["success"] && resData.data["issues"].length > 0) {
      if (!mounted) return;
      setState(() {
        issue = Utils.mergeMaps([issue, resData.data["issues"][0]]);
        issue["comments"] = [];
        assignees = issue["assignees"];
        selectedLabels = issue["labels"];
        selectedMilestone = issue["milestone_id"] != null ? [issue["milestone_id"]] : [];
      });

      Provider.of<Channels>(context, listen: false).setLabelsAndMilestones(issueData["channel_id"], resData.data["labels"], resData.data["milestones"]);
      var resComment = await Dio().post("${Utils.apiUrl}workspaces/${issueData["workspace_id"]}/channels/${issueData["channel_id"]}/issues/update_unread_issue?token=${auth.token}",
        data: {
          "issue_id": issueData["id"]
        }
      );
      if (resComment.data["success"]) {
        if (!mounted) return;
        setState(() {
          issue["comments"] = resComment.data["comments"];
        });
      }
    }
  }

  getCurrentWorkspace() {
    if (issue["id"] == null) {
      final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;

      if (currentWorkspace["id"] != null) {
        return currentWorkspace["id"];
      } else {
        return selectedWorkspace;
      }
    } else {
      return issue["workspace_id"];
    }
  }

  getCurrentChannel() {
    if (selectedChannel != null) {
      return selectedChannel;
    } else if (issue["id"] == null) {
      return Provider.of<Channels>(context, listen: false).currentChannel["id"];
    } else {
      return issue["channel_id"];
    }
  }

  getCurrentChannelName(workspaceId, channelId) {
    var wsId = workspaceId;
    var cId = channelId;

    if(workspaceId.runtimeType.toString() == "String") {
      wsId = int.parse(workspaceId);
    }

    if(channelId.runtimeType.toString() == "String") {
      cId = int.parse(channelId);
    }
    final data = Provider.of<Channels>(context, listen: false).data;
    var index = data.indexWhere((element) {
      return element["id"] == cId && element["workspace_id"] == wsId;
    }
    );
    return data[index]["name"];
  }

  getCurrentChannelType(workspaceId, channelId) {
    var wsId = workspaceId;
    var cId = channelId;

    if(workspaceId.runtimeType.toString() == "String") {
      wsId = int.parse(workspaceId);
    }

    if(channelId.runtimeType.toString() == "String") {
      cId = int.parse(channelId);
    }
    final data = Provider.of<Channels>(context, listen: false).data;
    var index = data.indexWhere((element) {
      return element["id"] == cId && element["workspace_id"] == wsId;
    }
    );
    return data[index]["is_private"];
  }

  handleEnterEvent() {
    List listText = text.split("\n");
    final selection = _commentController.selection;
    bool check = false;

    if (_commentController.value.text.length >= selection.baseOffset) {
      if (listText.isNotEmpty) {
        String lastText = listText[listText.length - 1];

        if (lastText.length > 6) {
          if (lastText.substring(0, 6) == "- [ ] ") {
            listText.add("- [ ] ");
            check = true;
          } else if (lastText.length > 2) {
            if (lastText.substring(0, 2) == "- " && !lastText.contains("- [ ]")) {
              listText.add("- ");
              check = true;
            }
          }
        } else if (lastText.length > 2) {
          if (lastText.substring(0, 2) == "- " && !lastText.contains("- [ ]")) {
            listText.add("- ");
            check = true;
          }
        } else {
          RegExp exp = RegExp(r"[0-9]{1,}.\s");
          Iterable<RegExpMatch> matches = exp.allMatches(lastText);

          if (matches.isNotEmpty) {
            int index = lastText.indexOf(".");
            int subString = int.parse(lastText.substring(0, index));
            listText.add("${subString + 1}. ");
            check = true;
          }
        }
      }

      if (check) {
        setState(() {
          text = listText.join("\n");
        });

        _commentController.value = _commentController.value.copyWith(
          text: listText.join("\n"),
          selection: TextSelection.collapsed(
            offset: listText.join("\n").length,
          ),
        );
      }
    }
  }

  onSubmitNewIssue(text) {
    final auth = Provider.of<Auth>(context, listen: false);
    final token = auth.token;
    final userId = auth.userId;
    final channelId = getCurrentChannel();
    final workspaceId = getCurrentWorkspace();
    final channelName = getCurrentChannelName(workspaceId, channelId);
    final channelType = getCurrentChannelType(workspaceId, channelId);

    if (widget.issue['message'] != null && selectedChannel == null) {
      sl.get<Auth>().showAlertMessage(S.current.pleaseSelectChannel, true);
      return;
    }

    if (_titleController.text.trim() != "") {
      var milestone = selectedMilestone.isNotEmpty ? selectedMilestone[0] : null;
      var result = Provider.of<Messages>(context, listen: false).checkMentions(text);
      var listMentionsNew = result["success"] ? result["data"].where((e) => e["type"] == "user").toList().map((e) => e["value"]).toList() : [];
      Map issue = {
        "key": Utils.getRandomString(20),
        "title": _titleController.text,
        "description": text,
        "labels": selectedLabels,
        "milestone": milestone,
        "users": assignees,
        "list_mentions_old": [],
        "list_mentions_new": listMentionsNew,
        "type": "issues",
        "message": widget.issue['message'],
        "is_closed": false,
        "author_id": userId,
        "assignees": assignees
      };

      var boxRecent = Hive.box("recentIssueCreated");
      var recentList = boxRecent.get("recent_channel");
      var infoChannel = [];

      Provider.of<Channels>(context, listen: false).createIssue(token, workspaceId, channelId, issue).then((res) {
        if (res["success"] == true) {
          box.delete(issue["id"] != null ? issue["id"].toString() : channelId.toString());
        }
      });
      Provider.of<Channels>(context, listen: false).onChangeOpenIssue(null);

      if (widget.issue["from_message"] ?? false) {
        Provider.of<Workspaces>(context, listen: false).changeToMessageView(true);
        Navigator.pop(context);
      }
      if(recentList != null) {
        infoChannel = recentList.where((element) {
          return element["channel_id"].toString() != channelId.toString();
        }).toList();
        infoChannel.insert(0, {"workspace_id": workspaceId, "channel_id": channelId, "name": channelName, "is_private": channelType});
      } else {
        infoChannel.add({"workspace_id": workspaceId, "channel_id": channelId, "name": channelName, "is_private": channelType});
      }

      boxRecent.put("recent_channel", infoChannel);
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            content: TextWidget("Title cannot be empty"),
          );
        },
      );
    }
  }

  onSaveDraftIssue(channelId) {
    var draftIssue = {
      "id": issue["id"] ?? channelId,
      "description": description,
      "editDescription": editDescription,
      "draftComment": draftComment,
      "title": _titleController.text,
      "assignees": assignees,
      "labels": selectedLabels,
      "milestone": selectedMilestone
    };

    box.put(issue["id"] != null ? issue["id"].toString() : channelId.toString(), draftIssue);
  }

  onUpdateIssue(title, description, isCancel) async {
    final auth = Provider.of<Auth>(context, listen: false);
    final channelId = getCurrentChannel();
    final workspaceId = getCurrentWorkspace();

    if (isCancel) {
      setState(() {
        editDescription = false;
        description = issue["description"];
      });
    }

    if (title != "") {
      var result = Provider.of<Messages>(context, listen: false).checkMentions(description);
      var listMentionsNew = result["success"] ? result["data"].where((e) => e["type"] == "user").toList().map((e) => e["value"]).toList() : [];
      var dataDescription = {
        "description": description,
        "channel_id": channelId,
        "workspace_id": workspaceId,
        "user_id": auth.userId,
        "type": "issues",
        "from_issue_id": issue["id"],
        "from_id_issue_comment": issue["id"],
        "list_mentions_old": issue["mentions"],
        "list_mentions_new": listMentionsNew
      };

      Provider.of<Channels>(context, listen: false).updateIssueTitle(auth.token, workspaceId, channelId, issue["id"], title, dataDescription).then((value) {
        setState(() {
          issue["title"] = title;
          issue["description"] = description;
          editDescription = false;
        });
      });
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: TextWidget(S.current.inputCannotEmpty),
          );
        },
      );

      setState(() {
        editDescription = false;
      });
    }
  }

  changeAssignees(user) {
    final token = Provider.of<Auth>(context, listen: false).token;
    List list = List.from(assignees);
    final index = list.indexWhere((e) => e == user["id"]);
    final channelId = getCurrentChannel();
    final workspaceId = getCurrentWorkspace();

    if (index != -1) {
      list.removeAt(index);
      if (issue["id"] != null) {
        Provider.of<Channels>(context, listen: false).removeAttribute(token, workspaceId, channelId, widget.issue["id"], "assignee", user["id"]);
      }
    } else {
      list.add(user["id"]);
      if (issue["id"] != null) {
        Provider.of<Channels>(context, listen: false).addAttribute(token, workspaceId, channelId, widget.issue["id"], "assignee", user["id"]);
      }
    }

    setState(() {
      assignees = list;
      if (issue["id"] == null) onSaveDraftIssue(channelId);
    });
  }

  changeLabels(label) {
    final token = Provider.of<Auth>(context, listen: false).token;
    List list = List.from(selectedLabels);
    final index = list.indexWhere((e) => e == label["id"]);
    final channelId = getCurrentChannel();
    final workspaceId = getCurrentWorkspace();

    if (index != -1) {
      list.removeAt(index);
      if (issue["id"] != null) {
        Provider.of<Channels>(context, listen: false).removeAttribute(token, workspaceId, channelId, widget.issue["id"], "label", label["id"]);
      }
    } else {
      list.add(label["id"]);

      if (issue["id"] != null) {
        Provider.of<Channels>(context, listen: false).addAttribute(token, workspaceId, channelId, widget.issue["id"], "label", label["id"]);
      }
    }

    setState(() {
      selectedLabels = list;
      if (issue["id"] == null) onSaveDraftIssue(channelId);
    });
  }

  changeMilestone(milestone) {
    final token = Provider.of<Auth>(context, listen: false).token;
    final channelId = getCurrentChannel();
    final workspaceId = getCurrentWorkspace();

    if (selectedMilestone.isEmpty) {
      setState(() {
        selectedMilestone = [milestone["id"]];
      });

      if (issue["id"] != null) {
        Provider.of<Channels>(context, listen: false).addAttribute(token, workspaceId, channelId, widget.issue["id"], "milestone", milestone["id"]);
      }

      Navigator.of(context, rootNavigator: true).pop("Discard");
    } else {
      if (selectedMilestone[0] == milestone["id"]) {
        setState(() {
          selectedMilestone = [];
        });

        if (issue["id"] != null) {
          Provider.of<Channels>(context, listen: false).removeAttribute(token, workspaceId, channelId, widget.issue["id"], "milestone", milestone["id"]);
        }
      } else {
        setState(() {
          selectedMilestone = [milestone["id"]];
        });

        if (issue["id"] != null) {
          Provider.of<Channels>(context, listen: false).addAttribute(token, workspaceId, channelId, widget.issue["id"], "milestone", milestone["id"]);
        }

        Navigator.of(context, rootNavigator: true).pop("Discard");
      }
    }

    if (issue["id"] == null) onSaveDraftIssue(channelId);
  }

  onCommentIssue(text) {
    final auth = Provider.of<Auth>(context, listen: false);
    final channelId = getCurrentChannel();
    final workspaceId = getCurrentWorkspace();
    var result = Provider.of<Messages>(context, listen: false).checkMentions(text);
    var listMentionsNew = result["success"] ? result["data"].where((e) => e["type"] == "user").toList().map((e) => e["value"]).toList() : [];

    var dataComment = {
      "comment": text,
      "channel_id": channelId,
      "workspace_id": workspaceId,
      "user_id": auth.userId,
      "type": "issue_comment",
      "from_issue_id": issue["id"],
      "list_mentions_old": [],
      "list_mentions_new": listMentionsNew
    };

    if (text.trim() != "") {
      Provider.of<Channels>(context, listen: false).submitComment(auth.token, dataComment);
    }
  }

  onChangeCheckBox(value, elText, commentId) {
    final auth = Provider.of<Auth>(context, listen: false);
    int indexComment = issue["comments"].indexWhere((e) => e["id"].toString() == commentId.toString());
    final channelId = getCurrentChannel();
    final workspaceId = getCurrentWorkspace();

    if (elText.length >= 1) {
      if (indexComment != -1) {
        var issueComment = issue["comments"][indexComment];
        String comment = issue["comments"][indexComment]["comment"];
        var startIndex = getStartIndex(comment, elText);
        int indexElText = comment.indexOf(elText, startIndex);
        String subString = comment.substring(0, indexElText);
        List listSubString = subString.split('');
        var index;

        for (var i = listSubString.length - 1; i >= 0; i--) {
          if (listSubString[i] == "]") {
            index = i - 1;
            break;
          }
        }
        if (index == -1 || index == null) return;

        String newText = comment.replaceRange(index, index + 1, value ? "x" : " ");
        issue["comments"][indexComment]["comment"] = newText;
        var result = Provider.of<Messages>(context, listen: false).checkMentions(newText);
        var listMentionsNew = result["success"] ? result["data"].where((e) => e["type"] == "user").toList().map((e) => e["value"]).toList() : [];

        var dataComment = {
          "comment": newText,
          "channel_id": channelId,
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
        var startIndex = getStartIndex(description, elText);
        int indexElText = description.indexOf(elText.trim(), startIndex);
        String subString = description.substring(0, indexElText);
        List listSubString = subString.split('');
        var index;

        for (var i = listSubString.length - 1; i >= 0; i--) {
          if (listSubString[i] == "]") {
            index = i - 1;
            break;
          }
        }
        if (index == -1 || index == null) return;

        String newText = description.replaceRange(index, index + 1, value ? "x" : " ");
        issue["description"] = newText;
        var result = Provider.of<Messages>(context, listen: false).checkMentions(newText);
        var listMentionsNew = result["success"] ? result["data"].where((e) => e["type"] == "user").toList().map((e) => e["value"]).toList() : [];

        var dataDescription = {
          "description": newText,
          "channel_id": channelId,
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

  onUpdateComment(comment, text) {
    final auth = Provider.of<Auth>(context, listen: false);
    final channelId = getCurrentChannel();
    final workspaceId = getCurrentWorkspace();

    var result = Provider.of<Messages>(context, listen: false).checkMentions(text);
    var listMentionsNew = result["success"] ? result["data"].where((e) => e["type"] == "user").toList().map((e) => e["value"]).toList() : [];
    var dataComment = {
      "comment": text,
      "channel_id": channelId,
      "workspace_id": workspaceId,
      "user_id": auth.userId,
      "type": "issue_comment",
      "from_issue_id": issue["id"],
      "from_id_issue_comment": comment["id"],
      "list_mentions_old": comment["mentions"] ?? [],
      "list_mentions_new": listMentionsNew
    };

    if (comment["comment"] != text) {
      Provider.of<Channels>(context, listen: false).updateComment(auth.token, dataComment);
    }

    setState(() {
      _commentController.text = comment["comment"];
      selectedComment = null;
    });
  }

  getMember(userId) {
    final members = Provider.of<Workspaces>(context, listen: false).members;
    final indexUser = members.indexWhere((e) => e["id"] == userId);
    if (indexUser != -1) {
      return  {
        ...members[indexUser],
        "full_name": members[indexUser]["nickname"] ?? members[indexUser]["full_name"]
      };
    } else {
      return {};
    }
  }

  parseMention(comment, channelId) {
    var parse = Provider.of<Messages>(context, listen: false).checkMentions(comment);
    if (parse["success"] == false) return comment;
    return Utils.getStringFromParse(parse["data"]);
  }

  parseDatetime(time) {
    if (time != "" && time != null) {
      DateTime offlineTime = DateTime.parse(time).add(const Duration(hours: 7));
      DateTime now = DateTime.now();
      final difference = now.difference(offlineTime).inMinutes;
      final int hour = difference ~/ 60;
      final int minutes = difference % 60;
      final int day = hour ~/ 24;

      if (day > 0) {
        int month = day ~/ 30;
        int year = month ~/ 12;
        if (year >= 1) {
          return S.current.countYearAgo(year);
        } else {
          if (month >= 1) {
            return S.current.countMonthAgo(month);
          } else {
            return S.current.countDayAgo(day);
          }
        }
      } else if (hour > 0) {
        return S.current.countHourAgo(hour);
      } else if(minutes <= 1) {
        return S.current.momentAgo;
      } else {
        return S.current.countMinuteAgo(minutes);
      }
    } else {
      return S.current.offline;
    }
  }

  parseComment(comment, bool value, isDescription) {
    final channelId = getCurrentChannel();
    var commentMention = value ? parseMention(comment, channelId) : comment;
    List list = commentMention.split("\n");

    if (list.isNotEmpty) {
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
            if (list[i + 1].trim() == "") {
              list[i + 1] = "\n";
            }
          }
        } else {
          if (i < list.length - 1 && list[i] == "" && list[i + 1] == "") {
            list[i] = "```";
            list[i + 1] = "```";
          }
        }
      }
    }

    return list.join("\n");
  }

  listAssignee() {
    final members = Provider.of<Channels>(context, listen: true).listChannelMember;
    final channelId = getCurrentChannel();
    final index = members.indexWhere((e) => e["id"].toString() == channelId.toString());
    final workspaceMember = index == -1 ? [] : members[index]["members"];

    return workspaceMember;
  }

  onSelectChannel(workspaceId, channelId) async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/get_labels_and_milestones?token=$token');

    Navigator.pop(context);

    try {
      final response = await http.get(url, headers: Utils.headers);
      final responseData = json.decode(response.body);

      if (responseData["success"]) {
        await Provider.of<Channels>(context, listen: false).setLabelsAndMilestones(channelId, responseData["labels"], responseData["milestones"]);
        setState(() {
          selectedChannel = channelId;
          selectedWorkspace = workspaceId;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  handleOpenAssigneeDropdown() {
    _assignKey.currentState!.handleOnTap();
  }

  nextDropdown(type) {
    if (type == "Assignees") {
      _labelKey.currentState!.handleOnTap();
    } else if (type == "Labels") {
      _milestoneKey.currentState!.handleOnTap();
    }
  }

  getImageUrl(description) {
    RegExp exp = RegExp(r"!(\[)[^\]]{0,}(\])((\()(https)[^\)]{0,}(\)))");
    final matches = exp.allMatches(description).map((m) => m.group(0)).toList();
    List list = [];

    for (var item in matches) {
      try {
        var name = (item ?? "").split("](")[0].substring(2);
        var url1 = (item ?? "").split("](")[1];
        var url2 = url1.substring(0, url1.length - 1);
        list.add({"name": name, "content_url": url2});
      } catch (e) {
        print(e.toString());
      }
    }

    return list;
  }

  goToChannelMessage(data) async {
    await Provider.of<Messages>(context, listen: false).handleProcessMessageToJump(data, context);

    Navigator.pop(context);
  }

  goDirectMessage(data) async {
    final auth = Provider.of<Auth>(context, listen: false);
    Provider.of<Workspaces>(context, listen: false).tab = 0;
    bool hasConv = await Provider.of<DirectMessage>(context, listen: false).getInfoDirectMessage(auth.token, data["conversation_id"]);
    if (!hasConv) return;
    await Provider.of<DirectMessage>(context, listen: false).processDataMessageToJump(data, auth.token, auth.userId);

    Navigator.pop(context);
  }

  parseAttachments(dataM) {
    var message = dataM["message"] ?? "";
    var mentions = dataM["attachments"] != null ? dataM["attachments"].where((element) => element["type"] == "mention").toList() : [];

    if (mentions.length > 0) {
      var mentionData = mentions[0]["data"];
      message = "";
      for (var i = 0; i < mentionData.length; i++) {
        if (mentionData[i]["type"] == "text") {
          message += mentionData[i]["value"];
        } else {
          message += "=======${mentionData[i]["trigger"] ?? "@"}/${mentionData[i]["value"]}^^^^^${mentionData[i]["name"]}^^^^^${mentionData[i]["type"] ?? ((mentionData[i]["id"].length < 10) ? "all" : "user")}+++++++";
        }
      }
    }

    var parse = Provider.of<Messages>(context, listen: false).checkMentions(message);
    if (parse["success"] == false) return message;
    return Utils.getStringFromParse(parse["data"]);
  }

  onShowModalSelectChannel(context, data) {
    var boxRecent = Hive.box("recentIssueCreated");
    var recentList = boxRecent.get("recent_channel") ?? [];
    final dataWorkspaces = Provider.of<Workspaces>(context, listen: false).data;

    var recentListFilter = recentList.where((ele) => ele["workspace_id"] == dataWorkspaces[indexWorkspaceSelected]["id"]).toList();

    List channelsFilter = data.where((ele) => ele["workspace_id"] == dataWorkspaces[indexWorkspaceSelected]["id"] && !ele["kanban_mode"]).toList();
    if(widget.issue['message'] != null && widget.issue['message']['isChannel']) {
      final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      channelsFilter = (issue["from_message"] != null && issue["from_message"]) ? data.where((e) => e["workspace_id"] == currentWorkspace["id"] && !e["kanban_mode"]).toList() : [];
      recentListFilter = recentList.where((ele) => ele["workspace_id"] == currentWorkspace["id"]).toList();
    }

    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5))
        ),
        insetPadding: const EdgeInsets.all(0),
        contentPadding: const EdgeInsets.all(0),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              width: 620,
              height: MediaQuery.of(context).size.height * 0.85,
              constraints: const BoxConstraints(
                maxHeight: 634
              ),
              child: Column(
                children: [
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff5E5E5E) : const Color(0xffF3F3F3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4.0),
                        topRight: Radius.circular(4.0)
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: TextWidget(S.current.selectChannel, style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          padding: const EdgeInsets.only(right: 16),
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            child: HoverItem(
                              colorHover: Palette.hoverColorDefault,
                              child: const Icon(
                                PhosphorIcons.xCircle,
                                size: 20.0,
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                          )
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CupertinoTextField(
                          focusNode: _searchChannelName,
                          controller: _searchChannelNameController,
                          padding: const EdgeInsets.all(12),
                          placeholder: S.current.searchChannel,
                          placeholderStyle: TextStyle(color: isDark ? const Color(0xffA6A6A6) : const Color(0xff5E5E5E), fontSize: 14, fontFamily: "Roboto"),
                          autofocus: true,
                          prefix: Container(
                            padding: const EdgeInsets.only(left: 12),
                            child: SvgPicture.asset('assets/icons/search.svg', color: isDark ? const Color(0xffA6A6A6) : const Color(0xff5E5E5E))),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isDark ? const Color(0xFF353535) : const Color(0xffFAFAFA),
                            border: Border.all(color: isDark ? const Color(0xff5E5E5E) : const Color(0xffC9C9C9))
                          ),
                          onChanged: (value) {
                            final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
                            setState(() {
                              channelsFilter = data.where((ele) {
                                final bool check = Utils.unSignVietnamese(ele['name']).contains(Utils.unSignVietnamese(value)) && (widget.issue['message'] != null && widget.issue['message']['isChannel'] ? ele["workspace_id"] == currentWorkspace["id"] : ele["workspace_id"] == dataWorkspaces[indexWorkspaceSelected]["id"]) && !ele["kanban_mode"];
                                return check;
                              }).toList();

                              recentListFilter = recentList.where((ele) {
                                final bool check = Utils.unSignVietnamese(ele['name']).contains(Utils.unSignVietnamese(value)) && widget.issue['message'] != null && (widget.issue['message']['isChannel'] ? ele["workspace_id"] == currentWorkspace["id"] : ele["workspace_id"] == dataWorkspaces[indexWorkspaceSelected]["id"]);
                                return check;
                              }).toList();
                            });
                          },
                          style: TextStyle(fontFamily: "Roboto", color: isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.85), fontSize: 14.0),
                        ),
                      ],
                    ),
                  ),
                  widget.issue['message'] != null && widget.issue['message']['isChannel'] ? const SizedBox() : Container(
                    margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isDark ? const Color(0xff5E5E5E) : const Color(0xffEAE8E8),
                    ),
                    width: 600, height: 40,
                    child: ScrollConfiguration(
                      behavior: MyCustomScrollBehavior(),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: dataWorkspaces.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                indexWorkspaceSelected = index;
                                channelsFilter = data.where((ele) {
                                  final bool check = Utils.unSignVietnamese(ele['name']).toLowerCase().contains(Utils.unSignVietnamese(_searchChannelNameController.text )) && ele["workspace_id"] == dataWorkspaces[index]["id"] && !ele["kanban_mode"];
                                  return check;
                                }).toList();

                                recentListFilter= recentList.where((ele) {
                                  final bool check = Utils.unSignVietnamese(ele['name']).toLowerCase().contains(Utils.unSignVietnamese(_searchChannelNameController.text )) && ele["workspace_id"] == dataWorkspaces[index]["id"];
                                  return check;
                                }).toList();
                              });
                            },
                            child: WorkspaceItem(
                              imageUrl: dataWorkspaces[index]["avatar_url"] ?? "",
                              workspaceName: dataWorkspaces[index]["name"] ?? "",
                              isSelected: indexWorkspaceSelected == index,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: isDark ? const Color(0xff2E2E2E) : Colors.white,
                                border: isDark ? null : Border.all(color: const Color(0xffC9C9C9))
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.only(top: 12, bottom: 12, left: 16),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(3),
                                        topRight: Radius.circular(3),
                                      ),
                                      color: isDark ? const Color(0xff4C4C4C) : const Color(0xffF8F8F8),
                                    ),
                                    child: TextWidget(S.current.recentChannel, style: TextStyle(color: isDark ? Colors.white :  const Color(0xff3D3D3D), fontWeight: FontWeight.w500, fontSize: 14))
                                  ),
                                  Expanded(
                                    child: Container(
                                      decoration: isDark ? null : BoxDecoration(
                                        border: Border(top: isDark ? BorderSide.none : const BorderSide(color: Color(0xffC9C9C9))),
                                      ),
                                      child: ListView.builder(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        itemCount: recentListFilter.length,
                                        itemBuilder: (context, index) {
                                          return InkWell(
                                            onTap: () => onSelectChannel(recentListFilter[index]['workspace_id'], recentListFilter[index]['channel_id'].toString()),
                                            child: HoverItem(
                                              colorHover: Palette.hoverColorDefault,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                child: Row(
                                                  children: [
                                                    recentListFilter[index]['is_private']
                                                      ? SvgPicture.asset('assets/icons/Locked.svg', color: isDark ? const Color(0xffDBDBDB) : const Color(0xff3D3D3D))
                                                      : SvgPicture.asset('assets/icons/iconNumber.svg', width: 13, color: isDark ? const Color(0xffDBDBDB) : const Color(0xff3D3D3D)),
                                                    const SizedBox(width: 8,),
                                                    TextWidget(recentListFilter[index]["name"] ?? "", overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? const Color(0xffDBDBDB) : const Color(0xff3D3D3D), fontSize: 14,)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16,),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: isDark ? const Color(0xff2E2E2E) : Colors.white,
                                border: isDark ? null : Border.all(color: const Color(0xffC9C9C9)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.only(top: 12, bottom: 12, left: 16),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xff4C4C4C) : const Color(0xffF8F8F8),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(3),
                                        topRight: Radius.circular(3),
                                      )
                                    ),
                                    child: TextWidget(S.current.listChannel, style: TextStyle(color: isDark ? Colors.white :  const Color(0xff3D3D3D), fontWeight: FontWeight.w500, fontSize: 14))
                                  ),
                                  Expanded(
                                    child: Container(
                                      decoration: isDark ? null : BoxDecoration(
                                        border: Border(top: isDark ? BorderSide.none : const BorderSide(color: Color(0xffC9C9C9))),
                                      ),
                                      child: ListView.builder(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        itemCount: channelsFilter.length,
                                        controller: ScrollController(),
                                        itemBuilder: (context, index) {
                                          int indexWorkspace = dataWorkspaces.indexWhere((ele) => ele['id'] == channelsFilter[index]['workspace_id']);
                                          if (indexWorkspace == -1) {
                                            return Container();
                                          }

                                          return InkWell(
                                            onTap: () => onSelectChannel(channelsFilter[index]['workspace_id'],channelsFilter[index]['id'].toString()),
                                            child: HoverItem(
                                              colorHover: Palette.hoverColorDefault,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                child: Row(
                                                  children: [
                                                    channelsFilter[index]['is_private']
                                                      ? SvgPicture.asset('assets/icons/Locked.svg', color: isDark ? const Color(0xffDBDBDB) : const Color(0xff3D3D3D))
                                                      : SvgPicture.asset('assets/icons/iconNumber.svg', width: 13, color: isDark ? const Color(0xffDBDBDB) : const Color(0xff3D3D3D)),
                                                    const SizedBox(width: 8,),
                                                    TextWidget(channelsFilter[index]['name'], overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? const Color(0xffDBDBDB) : const Color(0xff3D3D3D), fontSize: 14,),),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          }
        ),
      );
    });
  }

  getUser(userId) {
    List users = Provider.of<Workspaces>(context, listen: false).members;
    int index = users.indexWhere((e) => e["id"] == userId || e["user_id"] == userId);
    if (index != -1) {
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

  onGetHistory(commentId) async{
    final auth = Provider.of<Auth>(context, listen: false);
    final token = auth.token;
    final bool isDark = auth.theme == ThemeType.DARK;
    final issue = widget.issue;
    final workspaceId = issue['workspace_id'];
    final channelId = issue['channel_id'];
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/get_history_issue?token=$token&issue_id=${issue['id']}&issue_comment_id=$commentId';

    try {
      final response = await http.get(Uri.parse(url), headers: Utils.headers);

      final responseData = json.decode(response.body);

      if (responseData["success"] == true) {
        List _histories = responseData['data'];

        showDialog(
          context: context,
          builder: (context) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return AlertDialog(
                  contentPadding: EdgeInsets.zero,
                  backgroundColor: isDark ? Color(0xff1E1E1E) : Color(0xffDBDBDB),
                  content: Container(
                    height: 810,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Theme.of(context).dividerColor)
                            )
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: TextWidget(
                                  'History edit',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.grey[800]
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  PhosphorIcons.xCircle, size: 24,
                                  color: isDark ? Colors.white70 : Colors.grey[800],
                                ),
                              )
                            ],
                          )
                        ),
                        Container(
                          width: 750, height: 750,
                          color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
                          child: ListView.builder(
                            itemCount: _histories.length,
                            itemBuilder: (BuildContext context, int index) {

                              final messageTime = DateFormat('Hm').format(DateTime.parse(_histories[index]['inserted_at']).add(Duration(hours: 7)));
                              final locale = auth.locale;
                              DateTime dateTime = DateTime.parse(_histories[index]['inserted_at']);
                              final dayTime = DateFormatter().getVerboseDateTimeRepresentation(dateTime.add(Duration(hours: 7)), locale);
                              var timeRender = (dayTime == "Today" ? "Today" : DateFormatter().renderTime(DateTime.parse(_histories[index]['inserted_at']), type: "MMMd")) + " at $messageTime";
                              List images = getImageUrl(parseMention(_histories[index]['last_edited_text'], channelId));
                              String textRender = parseMention(_histories[index]['last_edited_text'], channelId).toString().split('\n').map((ele) {
                                RegExp exp = RegExp(r"!(\[)[^\]]{0,}(\])((\()(https)[^\)]{0,}(\)))");
                                final matches = exp.allMatches(ele);

                                return matches.length > 0 ? '' : ele;
                              }).toList().join('\n');

                              return HistoryIssue(
                                images: images,
                                history: _histories[index],
                                editor: getUser(_histories[index]['user_id']),
                                text: textRender,
                                dateTime: timeRender
                              );
                            }
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            );
          }
        );
      } else {
        print("onGetHistory: ${responseData['message']}");
      }
    } catch (e) {
       print("onGetHistory: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final token = auth.token;
    final directMessage = Provider.of<DirectMessage>(context, listen: true).directMessageSelected;
    final channelId = getCurrentChannel();
    final data = Provider.of<Channels>(context, listen: true).data;
    final index = data.indexWhere((e) => e["id"].toString() == (issue["id"] != null ? issue["channel_id"].toString() : channelId.toString()));
    final labels = index == -1 ? [] : data[index]["labels"] ?? [];
    final milestones = index == -1 ? [] : data[index]["milestones"] ?? [];
    var author = issue["id"] != null ? getMember(issue["author_id"]) : null;
    var editer = issue["id"] != null && issue["last_edit_id"] != null ? getMember(issue["last_edit_id"]) : null;
    final isDark = auth.theme == ThemeType.DARK;
    final comments = issue["id"] != null ? issue["comments"] : [];
    List commentsAndTimelines = (widget.fromMentions != null && widget.fromMentions ? issue["comments"] : comments) + (issue["timelines"] ?? []);
    commentsAndTimelines.sort((a, b) => a["inserted_at"].compareTo(b["inserted_at"]));
    final message = issue['message'];
    String descriptionMessage = '';

    if (message != null) {
      descriptionMessage = (message["message"] != "") ? message["message"] : message["attachments"].length > 0 ? parseAttachments(message) : "";
    }

    List asigneesSlected = [];
    for (int i = 0; i < assignees.length; i++) {
      if ((listAssignee().indexWhere((e) => e["id"] == assignees[i])) != -1) {
        asigneesSlected.add(assignees[i]);
      }
    }

    return StreamBuilder<bool>(
      stream: StreamDropzone.instance.isFocusedApp,
      builder: (context, snapshot) {
        if (snapshot.data != null) {
          Provider.of<Auth>(context, listen: false).focusApp(snapshot.data);
          if (isFocusApp != snapshot.data && ModalRoute.of(context) != null && ModalRoute.of(context)!.isCurrent) {
            isFocusApp = snapshot.data!;
            isFocusApp ? FocusScope.of(context).requestFocus() : FocusScope.of(context).unfocus();
          }
        }

        return Scaffold(
          body: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Palette.backgroundRightSiderDark,
                  border: Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Colors.transparent))
                ),
                padding: const EdgeInsets.all(11.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 12, left: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xff2E2E2E),
                        borderRadius: BorderRadius.all(Radius.circular(2))),
                      height: 32,
                      width: 90,
                      child: InkWell(
                        onTap: () {
                          widget.fromMentions != null && widget.fromMentions ? Navigator.of(context, rootNavigator: true) .pop("Discard") : Provider.of<Channels>(context, listen: false).onChangeOpenIssue(null);
                        },
                        child: HoverItem(
                          colorHover: Colors.white.withOpacity(0.15),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SvgPicture.asset('assets/icons/backDark.svg', color: Palette.defaultTextDark),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: TextWidget(S.current.back, style: TextStyle(color: Colors.white))
                                )
                              ],
                            ),
                          ),
                        )
                      )
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          (editTitle && issue["id"] != null) ? Expanded(
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 1 / 5),
                                    color: Palette.darkTextField,
                                    height: 32,
                                    child: TextFormField(
                                      autofocus: true,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Palette.darkTextField)),
                                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Palette.darkTextField)),
                                        hintText: widget.issue["title"]),
                                      focusNode: focusNode,
                                      controller: _titleController,
                                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500)
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  InkWell(
                                    onTap: () {
                                      onUpdateIssue(_titleController.text, issue["description"], false);
                                      setState(() {
                                        editTitle = false;
                                      });
                                    },
                                    child: Container(
                                      height: 32,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(color: Palette.buttonColor,
                                          borderRadius: BorderRadius.circular(4)),
                                      child: TextWidget(S.current.save),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        editTitle = false;
                                      });
                                    },
                                    child: Container(
                                      height: 32,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2), border: Border.all(color: const Color(0xffFF7875))),
                                      child: TextWidget(S.current.cancel, style: TextStyle(color: Color(0xffFF7875)))
                                    )
                                  )
                                ]
                            ),
                          ) : (issue["id"] != null && !editTitle) ? Row(
                            children: [
                              InkWell(
                                onTap: () => Clipboard.setData(ClipboardData(text: "${issue["title"]} #${issue["unique_id"]}")),
                                child: Tooltip(
                                  message: S.current.copyToClipboard,
                                  child: TextWidget("${issue["title"]} #${issue["unique_id"]}",
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,)),
                                ),
                              ),
                              const SizedBox(width: 10,),
                              HoverItem(
                                colorHover: Palette.hoverColorDefault,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        editTitle = true;
                                      });
                                    },
                                    child: Icon(Icons.edit, color: isDark ? Colors.white : Colors.white, size: 17)
                                  ),
                                ),
                              ),
                            ],
                          ) : TextWidget(S.current.newIssue, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, cts) {
                    var collapse = false;
                    String text = S.current.selectChannel;
                    if (cts.maxWidth < 650) {
                      collapse = true;
                    } else {
                      collapse = false;
                    }
                    if (selectedChannel != null && selectedChannel != '') {
                      int index = data.indexWhere((ele) => ele['id'].toString() == selectedChannel);
                      if (index != -1) text = data[index]['name'];
                    }
                    var listSelectedAttribute = Container(
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight))),
                      constraints: BoxConstraints(
                      maxWidth: collapse ? double.infinity : cts.maxWidth > 800 ? 300 : cts.maxWidth * 0.38
                      ),
                      child: SingleChildScrollView(
                        controller: issueScrollController,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.issue["from_message"] ?? false) Container(
                                margin: const EdgeInsets.only(bottom: 36),
                                child: HighLightButton(onTap: () => onShowModalSelectChannel(context, data), channelName: text,),
                              ),
                              Container(
                                constraints: const BoxConstraints(maxWidth: double.infinity),
                                child: SelectAttribute(
                                  dropdownKey: _assignKey,
                                  nextDropdown: nextDropdown,
                                  issue: issue,
                                  title: "Assignees",
                                  icon: Icon(
                                    CupertinoIcons.person_crop_circle_badge_plus,
                                    color: isDark ? Colors.white : const Color.fromRGBO(0, 0, 0, 0.65), size: 18
                                  ),
                                  listAttribute: listAssignee(),
                                  selectedAtt: asigneesSlected,
                                  selectAttribute: changeAssignees,
                                  fromMessage: issue["from_message"]
                                ),
                              ),
                              Container(
                                constraints: const BoxConstraints(maxWidth: double.infinity),
                                child: SelectAttribute(
                                  nextDropdown: nextDropdown,
                                  dropdownKey: _labelKey,
                                  issue: issue,
                                  title: "Labels",
                                  icon: Icon(CupertinoIcons.tag, color: isDark ? Colors.white : const Color.fromRGBO(0, 0, 0, 0.65), size: 18),
                                  listAttribute: labels,
                                  selectedAtt: selectedLabels,
                                  selectAttribute: changeLabels,
                                  fromMessage: issue["from_message"]
                                )
                              ),
                              Container(
                                constraints: const BoxConstraints(maxWidth: double.infinity),
                                child: SelectAttribute(
                                  dropdownKey: _milestoneKey,
                                  issue: issue,
                                  title: "Milestone",
                                  icon: Icon(CupertinoIcons.flag, color: isDark ? Colors.white : const Color.fromRGBO(0, 0, 0, 0.65), size: 18),
                                  listAttribute: milestones.where((e) => e["is_closed"] == false).toList(),
                                  selectedAtt: selectedMilestone,
                                  selectAttribute: changeMilestone,
                                  fromMessage: issue["from_message"]
                                )
                              ),
                              issue["id"] != null ? TransferIssue(issue: issue) : InkWell(
                                onTap: () {
                                  Map draftIssue = {
                                    'id': channelId,
                                    'type': 'create',
                                    'description': '',
                                    'title': '',
                                    'is_closed': false,
                                    'assignees': [],
                                    'labels': [],
                                    'milestone': []
                                  };

                                  _titleController.clear();
                                  _textFieldKey.currentState?.key.currentState?.controller?.clear();

                                  setState(() {
                                    assignees = [];
                                    selectedLabels = [];
                                    selectedMilestone = [];
                                  });

                                  box.put(channelId.toString(), draftIssue);
                                },
                                child: Container(
                                  height: 32,
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Color(0xffFF7875)),
                                    borderRadius: BorderRadius.all(Radius.circular(4))
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextWidget(
                                        'Clear issue',
                                        style: TextStyle(
                                          color: Color(0xffFF7875), fontSize: 14
                                        )
                                      ),
                                      SizedBox(width: 4),
                                      Icon(PhosphorIcons.trash, color: Color(0xffFF7875), size: 16)
                                    ],
                                  )
                                )
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                    return Container(
                      color: isDark ? Palette.backgroundRightSiderDark : Palette.backgroundRightSiderLight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              controller: controller,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        if(issue["id"] == null) Container(
                                          height: 48,
                                          color: isDark ? Palette.backgroundTheardDark : Colors.white,
                                          child: TextFormField(
                                            focusNode: _titleNode,
                                            autofocus: true,
                                            controller: _titleController,
                                            decoration: InputDecoration(
                                              hintText: (widget.issue["from_message"] != null && widget.issue["title"] != null && widget.issue["title"] != "") ? widget.issue["title"] .length > 47 ? (widget.issue["title"].substring(0, 47) + "...") : widget .issue["title"] : "Title",
                                              hintStyle: TextStyle(
                                                color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w300),
                                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight),
                                                borderRadius: const BorderRadius.all(Radius.circular(2))
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight),
                                                borderRadius: const BorderRadius.all(Radius.circular(2))
                                              ),
                                            ),
                                            style: TextStyle(color: isDark ? Colors.white : const Color.fromRGBO( 0, 0, 0, 0.65), fontSize: 15, fontWeight: FontWeight.normal),
                                            onChanged: (value) {
                                              onSaveDraftIssue(channelId);
                                            },
                                          ),
                                        ),
                                        if(issue["id"] != null) Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                              decoration: BoxDecoration(
                                                color: (issue["is_closed"] != null && issue["is_closed"]) ? const Color(0xff27AE60) : Palette.buttonColor,
                                                borderRadius: BorderRadius.circular(20)),
                                              child: Row(children: [
                                                Icon(
                                                  (issue["is_closed"] != null && issue["is_closed"]) ? Icons.check_circle_outline: Icons.info_outline, color: Colors.white, size: 17),
                                                const SizedBox(width: 4),
                                                TextWidget((issue["is_closed"] != null && issue["is_closed"]) ? S.current.tClosed : S.current.tOpen, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                              ])
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: RichText(
                                                text: TextSpan(
                                                  style: TextStyle(color: isDark ? Colors.white : const Color.fromRGBO(0, 0, 0, 0.65)),
                                                  children: [
                                                    TextSpan(text: "${getMember(issue["author_id"])["full_name"]} "),
                                                    TextSpan(text: S.current.openThisIssue(parseDatetime(issue["inserted_at"]))),
                                                    TextSpan(text: S.current.countComments(comments.length)) 
                                                  ]
                                                )
                                              )
                                            )
                                          ]
                                        ),
                                        const SizedBox(height: 24),
                                        author == null ? Container() : Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight),
                                            color: isDark ? const Color(0xff2E2E2E) : const Color(0xffEDEDED),
                                          ),
                                          child: Column(children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: isDark ? Palette.borderSideColorDark : Palette.backgroundTheardLight,
                                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(4),topRight: Radius.circular(4)),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                              child: Row(children: [
                                                Expanded(
                                                  child: SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    child: Row(
                                                      children: [
                                                        CachedImage(
                                                          author["avatar_url"],
                                                          width: 26,
                                                          height: 26,
                                                          radius: 50,
                                                          name: author["full_name"],
                                                        ),
                                                        const SizedBox(width: 4),
                                                        RichText(
                                                          text: TextSpan(
                                                            children: [
                                                              TextSpan(
                                                                text: "${author["full_name"]}",
                                                                style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color.fromRGBO(0, 0, 0, 0.65))
                                                              ),
                                                              WidgetSpan(child: SizedBox(width: 4)),
                                                              TextSpan(
                                                                text: S.current.commented(parseDatetime(issue["inserted_at"])),
                                                                style: TextStyle(color: isDark ? Colors.white : const Color.fromRGBO(0, 0, 0, 0.65))
                                                              ),
                                                              WidgetSpan(child: SizedBox(width: 6)),
                                                              WidgetSpan(
                                                                child: InkWell(
                                                                  onTap: () => onGetHistory(null),
                                                                  child: RichText(
                                                                    text: TextSpan(
                                                                      children: [
                                                                        TextSpan(
                                                                          text: issue["last_edit_description"] != null
                                                                            ? editer != null
                                                                              ? S.current.editedBy
                                                                              : S.current.edited
                                                                            : '',
                                                                        ),
                                                                        TextSpan(
                                                                          text: editer != null ? " ${editer["full_name"]}" : "",
                                                                          style: TextStyle(fontWeight: FontWeight.w700)
                                                                        ),
                                                                      ],
                                                                      style: TextStyle(
                                                                        color: isDark ? Palette.calendulaGold : Palette.dayBlue, fontSize: 13.5
                                                                      ),
                                                                    ),
                                                                  ),
                                                                )
                                                              ),
                                                              WidgetSpan(child: SizedBox(width: 6)),
                                                              TextSpan(
                                                                text: issue["last_edit_description"] != null ? " ${parseDatetime(issue["last_edit_description"])}" : '',
                                                                style: TextStyle(
                                                                  fontSize: 13, color: isDark ? Colors.white : const Color.fromRGBO(0, 0, 0, 0.65)
                                                                )
                                                              ),
                                                            ]
                                                          )
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Row(children: [
                                                  SizedBox(
                                                    width: 30,
                                                    child: IconButton(
                                                      focusColor: Colors.transparent,
                                                      hoverColor: Colors.transparent,
                                                      highlightColor:Colors.transparent,
                                                      splashColor:Colors.transparent,
                                                      icon: Icon(Icons.edit, color: isDark ? Colors.white : const Color.fromRGBO(0, 0, 0, 0.65), size: 17),
                                                      onPressed: () {
                                                        setState(() {
                                                          if (editDescription == true) {
                                                            description = issue["description"];
                                                            FocusScope.of(context).unfocus();
                                                          }
                                                          editDescription = !editDescription;
                                                        });
                                                      }
                                                    )
                                                  )
                                                ])
                                              ])),
                                            Container(color: isDark ? Palette.borderSideColorDark : Palette .borderSideColorLight, height: 1),
                                            editDescription ? Container(
                                              padding: const EdgeInsets.all(8),
                                              child: StreamBuilder(
                                                stream: DropTarget.instance.dropped,
                                                initialData: const [],
                                                builder: (context, files) {
                                                  return CommentTextField(
                                                    handleOpenAssigneeDropdown: handleOpenAssigneeDropdown,
                                                    initialValue: issue["description"],
                                                    editComment: true,
                                                    issue: issue,
                                                    isDescription: true,
                                                    onUpdateComment: onUpdateIssue,
                                                    onChangeText: (value) {
                                                      description = value;
                                                      onSaveDraftIssue(channelId);
                                                    },
                                                    dataDirectMessage: directMessage,
                                                  );
                                                }
                                              )
                                            ) : Column(
                                              children: [
                                                Markdown(
                                                  softLineBreak: true,
                                                  physics: const NeverScrollableScrollPhysics(),
                                                  imageBuilder: (uri, title, alt) {
                                                    return MarkdownAttachment(alt: alt, uri: uri);
                                                  },
                                                  shrinkWrap: true,
                                                  styleSheet: MarkdownStyleSheet(
                                                    p: TextStyle(
                                                      fontSize: 16.5,
                                                      height: 1.1,
                                                      color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight
                                                    ),
                                                    a: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, decoration: TextDecoration.underline, height: 1.3),
                                                    code: const TextStyle(fontSize: 13, color: Color(0xff40A9FF), fontFamily: "Menlo", height: 1.67,),
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
                                                    return MarkdownCheckbox( value: value, variable: variable, onChangeCheckBox: onChangeCheckBox, isDark: isDark);
                                                  },
                                                  data: (issue["description"] != null && issue["description"] != "") ? parseComment(issue["description"], false, true) : S.current.noDescriptionProvided,
                                                ),
                                              ]
                                            )
                                          ]
                                        )),
                                        if (message != null && issue['id'] != null) IssueTimeline(
                                          timelines: [
                                            {
                                              'data': {
                                                'type': 'create_message',
                                                'description': descriptionMessage,
                                              },
                                              'inserted_at': issue['inserted_at'], 'user_id': issue['author_id']
                                            }
                                          ],
                                          issue: issue,
                                          onTap: () {
                                            final data = widget.issue['message'];
                                            final message = {
                                              'id': data['id'],
                                              "avatarUrl": data["avatarUrl"] ?? "",
                                              "fullName": data["fullName"] ?? "",
                                              "workspace_id": data["workspaceId"],
                                              "channel_id": data["channelId"],
                                              'conversation_id': data['conversationId'],
                                              'inserted_at': data['insertedAt'],
                                              'current_time': data['current_time'] ?? DateTime.parse(data['insertedAt']).toUtc().microsecondsSinceEpoch
                                            };
                                            if (data['isChannel']) {
                                              final List dataChannels = Provider.of<Channels>(context, listen: false).data;
                                              int indexChannel = dataChannels.indexWhere((ele) => ele['id'] == message['channel_id']);
                                              if (indexChannel != -1) {
                                                goToChannelMessage(message);
                                              } else {
                                                sl.get<Auth>().showAlertMessage('You aren\'t in Channel', true);
                                              }
                                            } else {
                                              final List dataDMS = Provider.of<DirectMessage>(context, listen: false).data;
                                              int indexDMS = dataDMS.indexWhere((e) => e.id == message['conversation_id']);
                                              if (indexDMS != -1) {
                                                goDirectMessage(message);
                                              } else {
                                                sl.get<Auth>().showAlertMessage('You aren\'t in Conversation', true);
                                              }
                                            }
                                          },
                                        ),
                                        if (issue["id"] != null) Column(
                                          children: commentsAndTimelines.map<Widget>((e) {
                                          if (e == null) return Container();
                                          if (e["comment"] != null) {
                                            var comment = e;
                                            var author = getMember(comment["author_id"]);
                                            var lastEditedUser = comment["last_edited_id"] != null ? getMember(comment["last_edited_id"]) : null;

                                            return Container(
                                              margin: const EdgeInsets.symmetric(vertical: 12),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xff2E2E2E) : const Color(0xffEDEDED),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration( color: isDark ? Palette.borderSideColorDark : Palette.backgroundTheardLight,
                                                      borderRadius: const BorderRadius.only(topRight: Radius.circular(4), topLeft: Radius.circular(4))
                                                    ),
                                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: SingleChildScrollView(
                                                            scrollDirection: Axis.horizontal,
                                                            child: Row(
                                                              children: [
                                                                CachedImage(
                                                                  author["avatar_url"],
                                                                  width: 26,
                                                                  height: 26,
                                                                  radius: 50,
                                                                  name: author["full_name"],
                                                                ),
                                                                SizedBox(width: 4),
                                                                RichText(
                                                                  text: TextSpan(
                                                                    children: [
                                                                      TextSpan(
                                                                        text: "${author["full_name"]}",
                                                                        style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color.fromRGBO(0, 0, 0, 0.65))
                                                                      ),
                                                                      WidgetSpan(child: SizedBox(width: 4)),
                                                                      TextSpan(
                                                                        text: S.current.commented(parseDatetime(comment["inserted_at"])),
                                                                        style: TextStyle(color: isDark ? Colors.white : const Color.fromRGBO(0, 0, 0, 0.65))
                                                                      ),
                                                                      WidgetSpan(child: SizedBox(width: 6)),
                                                                      WidgetSpan(
                                                                        child: InkWell(
                                                                          onTap: () => onGetHistory(comment['id']),
                                                                          child: RichText(
                                                                            text: TextSpan(
                                                                              children: [
                                                                                TextSpan(
                                                                                  text: comment["last_edited_id"] != null
                                                                                    ? lastEditedUser != null
                                                                                      ? S.current.editedBy
                                                                                      : S.current.edited
                                                                                    : '',
                                                                                ),
                                                                                TextSpan(
                                                                                  text: lastEditedUser != null ? " ${lastEditedUser["full_name"]}" : "",
                                                                                  style: TextStyle(fontWeight: FontWeight.w700)
                                                                                ),
                                                                              ],
                                                                              style: TextStyle(
                                                                                color: isDark ? Palette.calendulaGold : Palette.dayBlue, fontSize: 13.5
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        )
                                                                      ),
                                                                      WidgetSpan(child: SizedBox(width: 6)),
                                                                      TextSpan(
                                                                        text: comment["last_edited_id"] != null ? " ${parseDatetime(comment["updated_at"])}" : '',
                                                                        style: TextStyle(
                                                                          fontSize: 13, color: isDark ? Colors.white : const Color.fromRGBO(0, 0, 0, 0.65)
                                                                        )
                                                                      ),
                                                                    ]
                                                                  )
                                                                ),
                                                              ]
                                                            )
                                                          )
                                                        ),
                                                        comment["author_id"] == auth.userId ? Row(
                                                          children: [
                                                            SizedBox(
                                                              width: 30,
                                                              child: IconButton(
                                                                focusColor: Colors.transparent,
                                                                hoverColor: Colors.transparent,
                                                                highlightColor: Colors.transparent,
                                                                splashColor: Colors.transparent,
                                                                icon: Icon(Icons.edit, color: isDark ? Colors.white : const Color.fromRGBO(0, 0, 0, 0.65), size: 17),
                                                                onPressed: () {
                                                                  if (selectedComment == comment["id"]) {
                                                                    setState(() {
                                                                      _commentController.text = comment["comment"];
                                                                      selectedComment = null;
                                                                      FocusScope.of(context).unfocus();
                                                                    });
                                                                  } else {
                                                                    setState(() {
                                                                      selectedComment = comment["id"];
                                                                    });
                                                                  }
                                                                }
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width: 30,
                                                              child: IconButton(
                                                              focusColor: Colors.transparent,
                                                              hoverColor: Colors.transparent,
                                                              highlightColor: Colors.transparent,
                                                              splashColor: Colors.transparent,
                                                              icon: Icon(Icons.delete_outline, color: isDark ? Colors.white : const Color.fromRGBO(0, 0, 0, 0.65), size: 18),
                                                              onPressed: () {
                                                                showDialog(
                                                                  context: context,
                                                                  builder: (context) {
                                                                    return AlertDialog(
                                                                      contentPadding: const EdgeInsets.all(0),
                                                                      content: Container(
                                                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                                                        width: 200,
                                                                        height: 94,
                                                                        child: Column(
                                                                          children: [
                                                                            TextWidget(S.current.deleteComment),
                                                                            const SizedBox(height: 6),
                                                                            const Divider(),
                                                                            Row(
                                                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                              children: [
                                                                                TextButton(
                                                                                  onPressed: () {
                                                                                    Navigator.of(context, rootNavigator: true).pop("Discard");
                                                                                  },
                                                                                  child: TextWidget(S.current.cancel),
                                                                                ),
                                                                                TextButton(
                                                                                  onPressed: () {
                                                                                    Provider.of<Channels>(context, listen: false).deleteComment(token, widget.issue["workspace_id"], widget.issue["channel_id"], comment["id"], issue["id"]);
                                                                                    Navigator.of(context, rootNavigator: true).pop("Discard");
                                                                                  },
                                                                                  child: TextWidget(S.current.delete, style: TextStyle(color: Colors.redAccent)),
                                                                                )
                                                                              ],
                                                                            )
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }
                                                                );
                                                              }
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      : Container(),
                                                      ],
                                                    )
                                                  ),
                                                  Container(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight, height: 1),
                                                  selectedComment == comment["id"] ? Container(
                                                    padding: const EdgeInsets.all(8),
                                                    child: CommentTextField(
                                                      handleOpenAssigneeDropdown: handleOpenAssigneeDropdown,
                                                      initialValue: _commentController.text,
                                                      comment: comment,
                                                      editComment: true,
                                                      issue: issue,
                                                      isDescription: false,
                                                      onUpdateComment: onUpdateComment,
                                                      onChangeText: (value) {
                                                        _commentController.text = value;
                                                      },
                                                      dataDirectMessage: directMessage,
                                                    ),
                                                  ) : Markdown(
                                                    physics: NeverScrollableScrollPhysics(),
                                                    softLineBreak: true,
                                                    imageBuilder: (uri, title, alt) {
                                                      return MarkdownAttachment(alt: alt, uri: uri);
                                                    },
                                                    shrinkWrap: true,
                                                    styleSheet: MarkdownStyleSheet(
                                                      p: TextStyle(fontSize: 16.5, height: 1.1, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                                      a: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, decoration: TextDecoration.underline, height: 1.3),
                                                      code: const TextStyle(fontSize: 13, color: Color(0xff40A9FF), fontFamily: "Menlo", height: 1.67,),
                                                      codeblockDecoration: BoxDecoration(
                                                        color: Colors.red
                                                      )),
                                                  
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
                                                        value:value,
                                                        variable: variable,
                                                        onChangeCheckBox: onChangeCheckBox,
                                                        commentId: comment["id"],
                                                        isDark: isDark
                                                      );
                                                    },
                                                    data: parseComment(comment["comment"], false, false),
                                                  )
                                                ],
                                              )
                                            );
                                          } else {
                                            var times = [e];
                                            return IssueTimeline(
                                              timelines: times,
                                              issue: issue
                                            );
                                          }
                                        }).toList()),
                                        Container(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: CommentTextField(
                                            key: _textFieldKey,
                                            handleOpenAssigneeDropdown: widget.issue["from_message"] ?? false ? () {
                                              onShowModalSelectChannel(context, data);
                                            } : handleOpenAssigneeDropdown,
                                            onChangeText: (value) {
                                              if (issue["id"] == null) {
                                                description = value;
                                              } else {
                                                draftComment = value;
                                              }
                                              onSaveDraftIssue(channelId);
                                            },
                                            initialValue: issue["id"] != null
                                              ? draftComment
                                              : description,
                                            editComment: false,
                                            issue: issue,
                                            isDescription: widget.issue["id"] == null,
                                            onSubmitNewIssue: onSubmitNewIssue,
                                            onCommentIssue: onCommentIssue,
                                            dataDirectMessage: directMessage,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (collapse) listSelectedAttribute
                                ],
                              ),
                            ),
                          ),
                          if (!collapse) listSelectedAttribute
                        ],
                      ),
                    );
                  }
                ),
              )
            ],
          ),
        );
      }
    );
  }
}

class HighLightButton extends StatefulWidget {
  const HighLightButton({Key? key, required this.channelName, this.onTap})
      : super(key: key);
  final String channelName;
  final onTap;

  @override
  State<HighLightButton> createState() => _HighLightButtonState();
}

class _HighLightButtonState extends State<HighLightButton> {
  bool isHover = false;
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return InkWell(
      onTap: widget.onTap,
      onHover: (hover) {
        if (isHover != hover) {
          setState(() {
            isHover = hover;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isHover ? isDark ? const Color(0xffFAAD14).withOpacity(0.1) : const Color(0xffE6F7FF) : isDark ? const Color(0xff2E2E2E) : const Color(0xffF8F8F8),
          border: Border.all(
            color: isDark ? const Color(0xffFAAD14) : Utils.getPrimaryColor(),
            style: isHover ? BorderStyle.solid : BorderStyle.none)
          ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWidget(widget.channelName),
            Icon(PhosphorIcons.gear,
              color: isDark ? const Color(0xffFAAD14) : Utils.getPrimaryColor(), size: 18)
          ],
        ),
      ),
    );
  }
}

class WorkspaceItem extends StatelessWidget {
  const WorkspaceItem({Key? key, required this.imageUrl, required this.workspaceName, this.isSelected = false}) : super(key: key);
  final String imageUrl;
  final String workspaceName;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom:  BorderSide(color: isSelected ? isDark ? const Color(0xffFAAD14) : Utils.getPrimaryColor() : Colors.transparent, width: 2))
      ),
      child: Row(
        children: [
          CachedImage(imageUrl, name: workspaceName, width: 24, height: 24, radius: 4),
          const SizedBox(width: 8,),
          isSelected ? TextWidget("$workspaceName  ", style: TextStyle(color: isDark ? Colors.white : const Color(0xff3D3D3D), fontSize: 14, fontWeight: FontWeight.w500)) : const SizedBox()
        ],
      )
    );
  }
}
