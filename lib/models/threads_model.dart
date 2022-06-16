import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/utils.dart';
import 'package:http/http.dart' as http;
import 'package:workcake/isar/message_conversation/service.dart';

import 'models.dart';

class Threads extends ChangeNotifier {
  List _dataThreads = [];
  bool _isOnThreads = false;

  List get dataThreads => _dataThreads;
  bool get isOnThreads => _isOnThreads;

  Future getThreadsDesktop(String token, workspaceId, isUpdate) async{
    final url = Utils.apiUrl + 'workspaces/$workspaceId/get_threads_workspace_v3?token=$token';
    final index = _dataThreads.indexWhere((e) => e["workspaceId"] == workspaceId);

    try {
      final response = await Utils.getHttp(url);

      if (response["success"] == true) {
        if (index == -1) {
          final newdata = {
            "workspaceId" : workspaceId,
            "threads": await processDataThread(response["threads"]),
            "page": 1,
            "lastLength": response["threads"].length
          };
          _dataThreads.add(newdata);
        } else {
          if (isUpdate) {
            _dataThreads[index] = {
              "workspaceId" : workspaceId,
              "threads": await processDataThread(response["threads"]),
              "page": 1,
              "lastLength": response["threads"].length
            };
          }
        }

        notifyListeners();
      } else {
        throw HttpException(response['message']);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<List> processDataThread(List threads) async {
    return await Future.wait(threads.map((t) async{
      if (Utils.checkedTypeEmpty(t["issue_id"])) return t;
      return {
        ...t,
        "reactions": MessageConversationServices.processReaction(t["reactions"]),
        "children": await MessageConversationServices.processBlockCodeMessage(t["children"])
      };
    }));
  }

  loadMoreThread(token, workspaceId) async {
    final index = _dataThreads.indexWhere((e) => e["workspaceId"] == workspaceId);

    if (index != -1 && _dataThreads[index]["lastLength"] >= 6) {
      var page = _dataThreads[index]["page"] + 1;
      final url = Utils.apiUrl + 'workspaces/$workspaceId/get_threads_workspace_v3?token=$token&page=$page';

      try {
        final response = await Utils.getHttp(url);

        if (response["success"] == true) {
          _dataThreads[index]["page"] = page;
          _dataThreads[index]["threads"] = _dataThreads[index]["threads"] + await processDataThread(response["threads"]);
          _dataThreads[index]["lastLength"] = response["threads"].length;

          notifyListeners();
        } else {
          throw HttpException(response['message']);
        }
      } catch (e) {
        print(e);
      }
    }
  }

  updateThread(token, data, type, context) async {
    final selectedTab = Provider.of<User>(context, listen: false).selectedTab;
    final userId = Provider.of<Auth>(context, listen: false).userId;
    final workspaceId = data["workspace_id"];
    final index = _dataThreads.indexWhere((e) => e["workspaceId"] == workspaceId);
    final newMessage = data["message"];

    if (type == "newMessage") {
      if (data["channel_thread_id"] != null) {
        if (index != -1) {
          final indexThread = _dataThreads[index]["threads"].indexWhere((e) => e["id"] == data["channel_thread_id"]);

          if (indexThread != -1) {
            final notify = _dataThreads[index]["threads"][indexThread]["notify"];
            final indexMention = (data["users_in_mention"] ?? []).indexWhere((e) => e == userId);
            final unread = _dataThreads[index]["threads"][indexThread]["unread"];
            var mentionCount = _dataThreads[index]["threads"][indexThread]["mention_count"] ?? 0;

            _dataThreads[index]["threads"][indexThread]["unread"] = (notify == null || notify) ? newMessage["user_id"] != userId : indexMention != -1 ? true : unread ? newMessage["user_id"] != userId : false;
            _dataThreads[index]["threads"][indexThread]["mention_count"] = indexMention != -1 ? mentionCount +=1 : newMessage["user_id"] == userId ? 0 : mentionCount;
            _dataThreads[index]["threads"][indexThread]["children"].add(newMessage);
            _dataThreads[index]["threads"][indexThread]["count_child"] +=1; 

            if (selectedTab != "thread") {
              final test = Map.from(_dataThreads[index]["threads"][indexThread]);
              _dataThreads[index]["threads"].removeAt(indexThread);
              _dataThreads[index]["threads"].insert(0, test);
            }
            notifyListeners();
          } else {
            await getThreadsDesktop(token, workspaceId, true);
            Utils.updateBadge(context);
          }
        } else {
          await getThreadsDesktop(token, workspaceId, true);
          Utils.updateBadge(context);
        }
      }
    } else if (type == "delete_message") {
      if (index != -1) {
        if (data["channel_thread_id"] != null) {
          final indexThread = _dataThreads[index]["threads"].indexWhere((e) => e["id"] == data["channel_thread_id"]); 

          if (indexThread != -1) {
            final indexMessage = _dataThreads[index]["threads"][indexThread]["children"].indexWhere((e) => e["id"] == data["message_id"]);

            if (indexMessage != -1) {
              _dataThreads[index]["threads"][indexThread]["children"].removeAt(indexMessage);

              if (_dataThreads[index]["threads"][indexThread]["children"].length == 0) {
                _dataThreads[index]["threads"].removeAt(indexThread);
              }

              notifyListeners();
            }
          }
        } else {
          final indexThread = _dataThreads[index]["threads"].indexWhere((e) => e["id"] ==  data["message_id"]);

          if (indexThread != -1) {
            _dataThreads[index]["threads"].removeAt(indexThread);

            notifyListeners();
          }
        }
      }
    } else {
      final reactions = data["reactions"];

      if (reactions["channel_thread_id"] != null) {
        final workspaceId = reactions["workspace_id"];
        final index = _dataThreads.indexWhere((e) => e["workspaceId"].toString() == workspaceId.toString());

        if (index != -1) {
          final indexThread = _dataThreads[index]["threads"].indexWhere((e) => e["id"] == reactions["channel_thread_id"]);

          if (indexThread != -1) {
            final indexMessage = _dataThreads[index]["threads"][indexThread]["children"].indexWhere((e) => e["id"] == reactions["message_id"]);

            if (indexMessage != -1) {
              _dataThreads[index]["threads"][indexThread]["children"][indexMessage]["reactions"] = MessageConversationServices.processReaction(reactions["reactions"]);

              notifyListeners();
            }
          }
        }
      } else {
        // cap nhat reaction cua cha
        final workspaceId = reactions["workspace_id"];
        final index = _dataThreads.indexWhere((e) => e["workspaceId"].toString() == workspaceId.toString());
        if (index != -1){
          var indexParent = _dataThreads[index]["threads"].indexWhere((ele) => ele["id"] == reactions["message_id"]);
          if (indexParent != -1){
            _dataThreads[index]["threads"][indexParent] = Utils.mergeMaps([
              _dataThreads[index]["threads"][indexParent],
              {
                "reactions": MessageConversationServices.processReaction(reactions["reactions"])
              }
            ]);
            notifyListeners();
          }
        }
      }
    }
  }

  onChangeTabs(bool value, token, workspaceId) async {
    _isOnThreads = value;
    await updateClearBadgeCount(workspaceId);
    notifyListeners();

    if (value){
      final url = "${Utils.apiUrl}workspaces/$workspaceId/update_unread_threads?token=$token";

      try {
        final response = await http.get(Uri.parse(url));
        final responseData = json.decode(response.body);

        if (responseData["success"] == true) {
          final index = _dataThreads.indexWhere((e) => e["workspaceId"] == workspaceId);

          if (index != -1) {
            for (var i = 0; i < _dataThreads[index]["threads"].length; i++) {
              if (_dataThreads[index]["threads"][i]["issue_id"] == null) {
                _dataThreads[index]["threads"][i]["unread"] = false;
              }
            }
          }
        }
      } catch (e) {
        print(e.toString());
      }
    } else {
      getThreadsDesktop(token, workspaceId, true);
    }
  }

  updateClearBadgeCount(workspaceId) {
    final index = _dataThreads.indexWhere((e) => e["workspaceId"] == workspaceId);

    if (index != -1) {
      for (var i = 0; i < _dataThreads[index]["threads"].length; i++) {
        _dataThreads[index]["threads"][i]["mention_count"] = 0;
      }
    }
  }

  updateThreadUnread(workspaceId, channelId, message, token) async {
    final url = "${Utils.apiUrl}workspaces/$workspaceId/update_unread_thread?token=$token";
  
    if (workspaceId != null && channelId != null) {
      final index = _dataThreads.indexWhere((e) => e["workspaceId"] == workspaceId);
  
      if (index != -1) {
        final indexThread = _dataThreads[index]["threads"].indexWhere((e) => e["id"] == message["id"]);

        if (indexThread != -1) {
          if (_dataThreads[index]["threads"][indexThread]["unread"] ?? true) {
            _dataThreads[index]["threads"][indexThread]["mention_count"] = 0;
            _dataThreads[index]["threads"][indexThread]["unread"] = false;
            try {
              var response = await Dio().post(url, data: {"message_id": message["issue_id"] != null ? null : message["id"], "channel_id": channelId, "issue_id": message["issue_id"]});
              var dataRes = response.data;
              if (dataRes["success"]) {}

              return [];
            } catch (e) {
              print("error $e");
            }
          }
        }
      }
    }
  }

  changeNotifyThread(token, workspaceId, channelId, messageId, notify) async {
    final url = "${Utils.apiUrl}workspaces/$workspaceId/change_notify?token=$token";
    final index = _dataThreads.indexWhere((e) => e["workspaceId"] == workspaceId);

    if (index != -1) {
      final indexThread = _dataThreads[index]["threads"].indexWhere((e) => e["id"] == messageId);

      if (indexThread != -1) { 
        _dataThreads[index]["threads"][indexThread]["notify"] = notify;
        notifyListeners();

        try {
          var response = await Dio().post(url, data: {"message_id": messageId, "channel_id": channelId, "notify": notify});
          var dataRes = response.data;

          if (dataRes["success"]) {
          
          } else {
            throw HttpException(dataRes['message']);
          }
        } catch (e) {
          print("error $e");
        }
      }
    }
  }

  updateIssueThread(context, token, workspaceId, channelId, issueId, type, payload, userCommentId) async {
    final selectedTab = Provider.of<User>(context, listen: false).selectedTab;
    final userId = Provider.of<Auth>(context, listen: false).userId;
    final index = _dataThreads.indexWhere((e) => e["workspaceId"] == workspaceId);

    if (type == "add_comment") {
      final newComment = payload["data"]["comment"];
      if (index != -1) {
        final indexThread = _dataThreads[index]["threads"].indexWhere((e) => e["id"] == issueId);
        final indexMention = (payload["data"]["users_in_mention"] ?? []).indexWhere((e) => e == userId);

        if (indexThread != -1) {
          var mentionCount = _dataThreads[index]["threads"][indexThread]["mention_count"] ?? 0;
          _dataThreads[index]["threads"][indexThread]["mention_count"] = indexMention != -1 ? mentionCount+=1 : newComment["author_id"] == userId ? 0 : mentionCount;
          _dataThreads[index]["threads"][indexThread]["unread"] = newComment["author_id"] != userId;
          _dataThreads[index]["threads"][indexThread]["children"].add(newComment);
          _dataThreads[index]["threads"][indexThread]["count_child"] +=1; 

          if (selectedTab != "thread") {
            final test = Map.from(_dataThreads[index]["threads"][indexThread]);
            _dataThreads[index]["threads"].removeAt(indexThread);
            _dataThreads[index]["threads"].insert(0, test);
          }

          notifyListeners();
        } else {
          await getThreadsDesktop(token, workspaceId, true);
        }
      } else {
        await getThreadsDesktop(token, workspaceId, true);
      }
      Utils.updateBadge(context);
    } else if (type == "delete_comment") {
      if (index != -1) {
        final indexThread = _dataThreads[index]["threads"].indexWhere((e) => e["id"] == issueId);

        if (indexThread != -1) {
          final indexComment = _dataThreads[index]["threads"][indexThread]["children"].indexWhere((e) => (e["id"] == payload["data"]));
          _dataThreads[index]["threads"][indexThread]["count_child"] = 
              (_dataThreads[index]["threads"][indexThread]["count_child"] ?? 0) > 0 ? 
              _dataThreads[index]["threads"][indexThread]["count_child"] - 1 : 0;

          if (indexComment != -1) {
            _dataThreads[index]["threads"][indexThread]["children"].removeAt(indexComment);
          } else {
            _dataThreads[index]["threads"][indexThread]["count_child"] -=1; 
          }
          notifyListeners();
        }
      }
    } else if (type == "update_comment") {
      if (index == -1) return;
      final indexThread = _dataThreads[index]["threads"].indexWhere((e) => e["id"] == issueId);

      if (indexThread != -1) {
        final indexComment = _dataThreads[index]["threads"][indexThread]["children"].indexWhere((e) => (e["id"] == payload["data"]["id"]));

        if (indexComment != -1) {
          _dataThreads[index]["threads"][indexThread]["children"][indexComment] = payload["data"];
          notifyListeners();
        } 
      }
    } else if (type == "update_issue_title") {
      if (index == -1) return;
      final indexThread = _dataThreads[index]["threads"].indexWhere((e) => e["id"] == issueId);

      if (indexThread != -1) {
        _dataThreads[index]["threads"][indexThread]["description"] = payload["data"]["description"];
        notifyListeners();
      }
    }
  }

  updateThreadMessage(data) async {
    final index = _dataThreads.indexWhere((e) => e["workspaceId"].toString() == data["workspace_id"].toString());

    if (index == -1) return;
    if (data["source"]["channel_thread_id"] != null) {
      final indexThread = _dataThreads[index]["threads"].indexWhere((e) => e["id"] == (data["source"]["channel_thread_id"]));
      if (indexThread == -1) return; 
      final indexMessage = _dataThreads[index]["threads"][indexThread]["children"].indexWhere((e) => e["id"] == data["id"]);
      if (indexMessage == -1) return;
      _dataThreads[index]["threads"][indexThread]["children"][indexMessage]["message"] = data["message"];
      _dataThreads[index]["threads"][indexThread]["children"][indexMessage]["attachments"] = data["attachments"];
      notifyListeners();
    } else {
      final indexThread = _dataThreads[index]["threads"].indexWhere((e) => e["id"] == (data["id"]));
      if (indexThread == -1) return;
      _dataThreads[index]["threads"][indexThread]["message"] = data["message"];
      _dataThreads[index]["threads"][indexThread]["attachments"] = data["attachments"];
      notifyListeners();
    }
  }
}
