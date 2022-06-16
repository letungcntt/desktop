import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:workcake/common/utils.dart';
import 'package:http/http.dart' as http;
import 'package:workcake/components/boardview/CardItem.dart';

class Boards extends ChangeNotifier {
  List _data = [];
  Map _selectedBoard = {};
  bool isFetching = false;
  CardItem? _selectedCard;

  List get data => _data; 
  Map get selectedBoard => _selectedBoard;
  CardItem? get selectedCard => _selectedCard;

  onSelectCard(card) {
    _selectedCard = card;
  }

  onChangeBoard(board) async {
    _selectedBoard = board;
    var box = await Hive.openBox("lastSelectedBoard");
    box.put(board["channel_id"].toString(), board);
    notifyListeners();
  }

  getListBoards(token, workspaceId, channelId) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards?token=$token');

    try {
      final box = await Hive.openBox("lastSelectedBoard");
      final dataBoards = await Hive.openBox("dataBoards");
      final lastSelectedBoard = box.get(channelId.toString());
      final response = await http.get(url);
      final responseData = json.decode(response.body);

      if (responseData["success"]) {
        _data = responseData["boards"];
        var boards = dataBoards.get(channelId.toString());
        if (boards != null) {
          for (var i = 0; i < _data.length; i++) {
            var board = boards.firstWhere((e) => e["id"] == _data[i]["id"]);
            _data[i]["order"] = board != null ? board["order"] : i;
          }
          
          _data.sort((a, b) =>  a["order"] < b["order"] ? -1 : 1);
        }
      
        if (lastSelectedBoard != null) {
          final index = _data.indexWhere((e) => e["id"] == lastSelectedBoard["id"]);
          if (index != -1) {
            _selectedBoard = _data[index];
          }
        } else {
          _selectedBoard = _data.length > 0 ? _data[0] : {};
        }
       
        notifyListeners();
      } else {
        print("getListBoards error");
      }
    } catch (e) {
      print("getListBoards error");
      print(e.toString());
    }
  }

  onArrangeBoard(data, channelId) async {
    var box = await Hive.openBox("dataBoards");
    for (var i = 0; i < data.length; i++) {
      data[i]["order"] = i;
    }
    box.put(channelId.toString(), data);
  }

  createNewBoard(token, workspaceId, channelId, title) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/create?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "title": title        
      }));
      final responseData = json.decode(response.body);

      if (responseData["success"]) {
        await getListBoards(token, workspaceId, channelId);
        if (_data.length > 0) {
          _selectedBoard = _data[0];
        }
      } else {
        print("create new board error");
      }
    } catch (e) {
      print("create new board error");
      print(e.toString());
    }
  }

  createNewCardList(token, workspaceId, channelId, boardId, title) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/create?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "title": title
      }));
      final responseData = json.decode(response.body);

      if (responseData["success"]) {
        getListBoards(token, workspaceId, channelId);
      } else {
        print("createNewCardList error");
      }
    } catch (e) {
      print("createNewCardList error");
      print(e.toString());
    }
  }

  createNewCard(token, workspaceId, channelId, boardId, listCardId, card) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/$listCardId/create?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({"card": card}));
      final responseData = json.decode(response.body);

      if (responseData["success"]) {
        getListBoards(token, workspaceId, channelId);
      } else {
        print("createNewCard error");
      }
    } catch (e) {
      print("createNewCard error");
      print(e.toString());
    }
  }

  arrangeCard(token, workspaceId, channelId, boardId, listCardId, order, oldOrder, card) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/$listCardId/arrange_cards?token=$token');

    if (isFetching) return;
    try {
      isFetching = true;
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "card": card,
        "order": order,
        "old_order": oldOrder
      }));
      final responseData = json.decode(response.body);

      if (responseData["success"]) {} else {
        print("arrangeCard error");
      }
      isFetching = false;
    } catch (e) {
      isFetching = false;
      print("arrangeCard error");
      print(e.toString());
    }
  }

  arrangeCardList(token, workspaceId, channelId, boardId, listCard) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/arrange_cards_list?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "list_cards": listCard
      }));
      final responseData = json.decode(response.body);

      if (responseData["success"]) {} else {
        print("arrangeCardList error");
      }
    } catch (e) {
      print("arrangeCardList error");
      print(e.toString());
    }
  }

  updateCardTitleOrDescription(token, workspaceId, channelId, boardId, listCardId, card) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/$listCardId/${card['id']}/update_card?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "card": card,
        "description": card["description"],
        "title": card["title"],
        "priority": card["priority"],
        "due_date": card["dueDate"]
      }));
      final responseData = json.decode(response.body);

      if (responseData["success"]) {
        getListBoards(token, workspaceId, channelId);
      } else {
        print("updateCardDescription error");
      }
    } catch (e) {
      print("updateCardDescription error");
      print(e.toString());
    }
  }

  sendCommentCard(token, workspaceId, channelId, boardId, listCardId, cardId, comment) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/$listCardId/$cardId/send_comment_card?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "comment": comment
      }));
      final responseData = json.decode(response.body);

      if (responseData["success"]) {
        updateCard(workspaceId, channelId, boardId, listCardId, cardId, "sendCommentCard", {"comment": comment});
      } else {
        print("sendCommentCard error");
      }
    } catch (e) {
      print("sendCommentCard error");
      print(e.toString());
    }
  }

  deleteComment(token, workspaceId, channelId, boardId, listCardId, cardId, commentId) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/$listCardId/$cardId/delete_comment?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "comment_id": commentId
      }));
      final responseData = json.decode(response.body);

      if (responseData["success"]) {
        updateCard(workspaceId, channelId, boardId, listCardId, cardId, "deleteComment", {});
      } else {
        print("deleteComment error");
      }
    } catch (e) {
      print("deleteComment error");
      print(e.toString());
    }
  }

  getActivity(token, workspaceId, channelId, boardId, listCardId, cardId) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/$listCardId/$cardId/get_comments_and_attributes?token=$token');

    try {
      final response = await http.get(url);
      final responseData = json.decode(response.body);


      if (responseData["success"]) {
        return responseData;
      } else {
        print("getActivity error");
      }
    } catch (e) {
      print("getActivity error");
      print(e.toString());
    }
  }

  addOrRemoveAttribute(token, workspaceId, channelId, boardId, listCardId, cardId, attributeId, type) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/$listCardId/$cardId/add_or_remove_attribute?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "attribute_id": attributeId,
        "type": type
      }));
      final responseData = json.decode(response.body);

      if (responseData["success"]) {
        notifyListeners();
      } 
      else {
        print("addOrRemoveAttribute error");
      }
    } catch (e) {
      print("addOrRemoveAttribute error");
      print(e.toString());
    }
  }

  createLabel(token, workspaceId, channelId, boardId, title, colorHex, labelId) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/create_label?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "title": title,
        "color_hex": colorHex,
        "label_id": labelId
      }));
      final responseData = json.decode(response.body);

      if (responseData["success"]) {
        final label = responseData["label"];

        if (labelId != null) {
          final indexLabel = selectedBoard["labels"].indexWhere((e) => e["id"] == labelId);
          if (indexLabel != -1) {
            selectedBoard["labels"][indexLabel] = label;
          }
        } else {
          selectedBoard["labels"].insert(0, label);
        }
        
        notifyListeners();
      } else {
        print("createLabel error");
      }
    } catch (e) {
      print("createLabel error");
      print(e.toString());
    }
  }

  createChecklist(token, workspaceId, channelId, boardId, listCardId, cardId, title) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/$listCardId/$cardId/create_checklist?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "title": title
      }));
      final responseData = json.decode(response.body);

      if (responseData["success"]) {
        return responseData;
      } else {
        print("createChecklist error");
      }
    } catch (e) {
      print("createChecklist error");
      print(e.toString());
    }
  }

  createOrChangeTask(token, workspaceId, channelId, boardId, listCardId, cardId, checklistId, title, checked, taskId) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/$listCardId/$cardId/create_or_change_task?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "title": title,
        "checklist_id": checklistId,
        "task_id": taskId,
        "checked": checked
      }));
      final responseData = json.decode(response.body);

      if (responseData["success"]) {
        updateCard(workspaceId, channelId, boardId, listCardId, cardId, "createOrChangeTask", {"taskId": taskId, "task": responseData["task"]});
        return responseData;
      } else {
        print("createOrChangeTask error");
      }
    } catch (e) {
      print("createOrChangeTask error");
      print(e.toString());
    }
  }

  deleteChecklistOrTask(token, workspaceId, channelId, boardId, listCardId, cardId, checklistId, taskId) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/$listCardId/$cardId/delete_checklist_or_task?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "checklist_id": checklistId,
        "task_id": taskId
      }));
      final responseData = json.decode(response.body);

      if (responseData["success"]) {
        updateCard(workspaceId, channelId, boardId, listCardId, cardId, "deleteChecklistOrTask", {"taskId": taskId, "checklistId": checklistId});
        return responseData;
      } else {
        print("deleteChecklistOrTask error");
      }
    } catch (e) {
      print("deleteChecklistOrTask error");
      print(e.toString());
    }
  }

  addAttachment(token, workspaceId, channelId, boardId, listCardId, cardId, contentUrl, type, fileName) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/$listCardId/$cardId/add_attachment?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "content_url": contentUrl,
        "type": type,
        "file_name": fileName
      }));
      final responseData = json.decode(response.body);

      if (responseData["success"]) {
        return responseData;
      } else {
        print("addAttachment error");
        return null;
      }
    } catch (e) {
      print("addAttachment error");
      print(e.toString());
      return null;
    }
  }

  deleteAttachment(token, workspaceId, channelId, boardId, listCardId, cardId, attachmentId) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/$listCardId/$cardId/delete_attachment?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "card_attachment_id": attachmentId,
      }));
      final responseData = json.decode(response.body);

      if (responseData["success"]) {
        return responseData;
      } else {
        print("deleteAttachment error");
      }
    } catch (e) {
      print("deleteAttachment error");
      print(e.toString());
    }
  }

  updateCard(workspaceId, channelId, boardId, listCardId, cardId, type, payload) {
    try {
      final listCardIndex = selectedBoard["list_cards"].indexWhere((e) => e["id"] == listCardId);
      if (listCardIndex == -1) return;
      final cards = selectedBoard["list_cards"][listCardIndex]["cards"];
      final indexCard = cards.indexWhere((e) => e["id"].toString() == cardId.toString());
      if (indexCard == -1) return;
      final card = cards[indexCard];

      if (type == "sendCommentCard") {
        card["comments_count"] +=1;
      } else if (type == "createOrChangeTask") {
        final tasks = card["tasks"];
        final indexTask = tasks.indexWhere((e) => e["id"].toString() == payload["taskId"].toString());

        if (indexTask == -1) {
          tasks.add(payload["task"]);
        }
      } else if (type == "deleteComment") {
        card["comments_count"] -=1;
      } else if (type == "deleteChecklistOrTask") {
        if (payload["taskId"] != null) {
          final indexTask = card["tasks"].indexWhere((e) => e["id"] == payload["taskId"]);
          if (indexTask != -1) card["tasks"].removeAt(indexTask);
        } else {
          card["tasks"] = card["tasks"].where((e) => e["checklist_id"] != payload["checklistId"]).toList();
        }
      }
      notifyListeners();
    } catch (e, trace) {
      print("updateCard error: $e $trace");
    }
  }

  changeListCardTitle(token, workspaceId, channelId, boardId, listCardId, title) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/$listCardId/update_listcard_title?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "title": title        
      }));
      final responseData = json.decode(response.body);
      if (responseData["success"]) {
        return true;
      } else {
        print("changeListCardTitle error");
        return false;
      }
    } catch (e) {
      print("changeListCardTitle error ${e.toString()}");
      return false;
    }
  }

  addOrRemoveTaskAssignee(token, workspaceId, channelId, boardId, listCardId, cardId, taskId, userId) async { 
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/$listCardId/$cardId/add_or_remove_task_assignee?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "user_id": userId,
        "task_id": taskId
      }));
      final responseData = json.decode(response.body);
      if (responseData["success"]) {
      } else {
        print("addOrRemoveTaskAssignee error");
      }
    } catch (e) {
      print("addOrRemoveTaskAssignee error ${e.toString()}");
    }
  }

  addTaskAttachment(token, workspaceId, channelId, boardId, listCardId, cardId, taskId, content) async { 
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/$listCardId/$cardId/add_task_attachment?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "content": content,
        "task_id": taskId
      }));
      final responseData = json.decode(response.body);
      if (responseData["success"]) {
      } else {
        print("addTaskAttachment error");
      }
    } catch (e) {
      print("addTaskAttachment error ${e.toString()}");
    }
  }

  removeTaskAttachment(token, workspaceId, channelId, boardId, listCardId, cardId, taskId, contentId) async { 
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/$listCardId/$cardId/remove_task_attachment?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "content_id": contentId,
        "task_id": taskId
      }));
      final responseData = json.decode(response.body);
      if (responseData["success"]) {
      } else {
        print("removeTaskAttachment error");
      }
    } catch (e) {
      print("removeTaskAttachment error ${e.toString()}");
    }
  }

  checkAllTask(token, workspaceId, channelId, boardId, listCardId, cardId, checklistId, value) async { 
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/$listCardId/$cardId/check_all_task?token=$token');

    try {
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "checklist_id": checklistId,
        "value": value
      }));
      final responseData = json.decode(response.body);
      if (responseData["success"]) {
      } else {
        print("removeTaskAttachment error");
      }
    } catch (e) {
      print("removeTaskAttachment error ${e.toString()}");
    }
  }

  deleteLabel(token, workspaceId, channelId, boardId, labelId) async {
    final url = Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/boards/$boardId/delete_label?token=$token');

    try {
      final indexLabel = selectedBoard["labels"].indexWhere((e) => e["id"] == labelId);
      if (indexLabel == -1) return;
      selectedBoard["labels"].removeAt(indexLabel);
      final response = await http.post(url, headers: Utils.headers, body: json.encode({
        "label_id": labelId
      }));
      final responseData = json.decode(response.body);
      if (responseData["success"]) {
      } else {
        print("deleteLabel error");
      }
    } catch (e) {
      print("deleteLabel error");
      print(e.toString());
    }
    notifyListeners();
  }
}
