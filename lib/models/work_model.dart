import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/services/download_status.dart';
import 'package:http/http.dart' as http;

class Work with ChangeNotifier {
  List _issues  = [];
  List _taskDownload = [];
  List _listIssueDraft = [];

  // List _labels = [];
  // List _milestones = [];
  bool _issueClosedTab = false;
  bool _isSystemTray = true;

  var _resetFilter = 0;
  
  bool get isSystemTray => _isSystemTray; 

  set isSystemTray(bool i){
    _isSystemTray = i;
    notifyListeners();
  }

  List get taskDownload  => _taskDownload;

  bool get issueClosedTab => _issueClosedTab;

  int get resetFilter => _resetFilter;

  List get listIssueDraft => _listIssueDraft;
  
  set listIssueDraff(List list){
    _listIssueDraft = list;
    notifyListeners();
  }

  loadHiveSystemTray(){
    MethodChannel systemChannel = MethodChannel("system");
    Hive.openBox("system").then((value) {
      var box = value;
      _isSystemTray = box.get("is_tray") ?? false;
      systemChannel.invokeMethod("system_to_tray", [_isSystemTray]);
    });
    notifyListeners();
  }

  loadDraftIssue() async{
    var box = await Hive.openBox("draftsComment");
    var boxGet = box.get("lastEdited");
    if (boxGet != null) {
      _listIssueDraft = List.from(boxGet);
    }
    notifyListeners();
  }

  setIssueClosedTab(bool tab) {
    _issueClosedTab = tab;
    notifyListeners();
  }

  updateResetFilter() {
    _resetFilter++;
    notifyListeners();
  }
  createNewIssue(int channelId, workspaceId){
    // issue moi co trang thai status = "new"
    var currentIndex  =  _issues.indexWhere((element) => element["channelId"] == channelId );
    if (currentIndex == -1){
      Map issue = {
        "channel_id": channelId,
        "workspace_id": workspaceId,
        "id": Utils.getRandomString(10),
        "title": "",
        "description": "",
        "labels": [],
        "milestone": null,
        "is_closed": false,
        "assignees": [],
        "comments": [],
      };
      _issues += [issue];
      return issue;
    }
    return _issues[currentIndex];
  }
   

  updateIssue(Map  issue){
    var currentIndex  =  _issues.indexWhere((element) => element["channelId"] == issue["channelId"]);
    if (currentIndex != -1){
      _issues[currentIndex]  = issue;
    }
  }

  // task download
  // add task download

  addTaskDownload(Map download) async{
    var name = download['name'] != null ? download['name'].replaceAll(":", "-") : Utils.getRandomString(10);
    // gen a new Id
    Map task = Utils.mergeMaps([
      download, {
        "id": Utils.getRandomString(10),
        "status": "downloading",
        "progress": 0.0
      },
      {"name": name}
    ]);
    _taskDownload = _taskDownload + [task];
    notifyListeners();
    // excute download
    await excuteDownload(task);
  }

  excuteDownload(task)async {
    await Future.delayed(Duration(milliseconds: 1000));
    Directory? appDocDirectory;
    if (Platform.isMacOS || Platform.isWindows) appDocDirectory = await getDownloadsDirectory();
    var path  = appDocDirectory!.path;
    new Directory(path).create(recursive: true).then((Directory directory) async {
      try {
        int total = 0;
        int received = 0;
        num percent = 0;

        List<int> bytes = [];
        http.StreamedResponse response;

        response = await http.Client().send(http.Request('GET', Uri.parse(task["content_url"])));
        total = response.contentLength ?? 0;
        response.stream.listen((value) {
          bytes.addAll(value);
          received += value.length;

          if ((received*100/total).round() - percent > 1) {
            percent = (received*100/total).round();
            StreamDownloadStatus.instance.setUploadStatus(task["id"], received/total);
          }
        }).onDone(() async {
          var nameFull = "${task["name"] ?? task["id"]}";
          var name = nameFull.split(".").length > 1 ?  nameFull.split(".")[0] : nameFull;
          String extend = (nameFull.split(".").length > 1 ?  (nameFull.split(".").last) : checkTypeFile(bytes));
          var nameFile = name + ".$extend";
          File file = File("$path/$nameFile");
          int i = 0;
          while(file.existsSync()){
            i++;
            var n = name +  "($i)";
            n = n + ".$extend";
            file = File("$path/$n");
            task["name"] = n; 
          }
          if (Utils.checkedTypeEmpty(task["key_encrypt"]))
            await file.writeAsBytes(base64Decode(await Utils.decrypt(base64Encode(bytes), task["key_encrypt"])), mode: FileMode.write);
          else await file.writeAsBytes(bytes, mode: FileMode.write);
          task["status"] = "done";
          task["uri"] = file.path;
          notifyListeners();
        });

        // Response response = await Dio().get(
        // task["content_url"],
        // onReceiveProgress: (count, total) {
        //   StreamDownloadStatus.instance.setUploadStatus(task["id"], count / total);
        //   // 
        //   // notifyListeners();
        // },
        // //Received data with List<int>
        // options: Options(
        //   responseType: ResponseType.bytes,
        //   followRedirects: false, 
        //   receiveTimeout: 0),
        // );

        // final path = directory.path;
        // var checkType = [];
        // for (int i = 0; i <= 5; i++) {
        //   checkType.add(response.data[i]);
        // }
        // ten file co th bao gom ca type (a.txt, b.png)
        // var name = "${task["name"] ?? task["id"]}";
        // var nameFile = name + (name.split(".").length > 1 ? "" : checkTypeFile(checkType));
        // File file = File("$path/$nameFile");
        // await file.writeAsBytes(response.data, mode: FileMode.write);
        // task["status"] = "done";
        // task["uri"] = "$path/$nameFile";
        // notifyListeners();
      } catch (e) {
        task["status"] = "error";
        task["progress"] = 0.0;
        notifyListeners();
        print("download att $e");
      }
    });
  }

  static checkTypeFile(checkType) {
    if (checkType[0] == 255 && checkType[1] == 216 && checkType[2] == 255) return ".png";
    else if (checkType[0] == 137 && checkType[1] == 80 && checkType[2] == 78) return ".jpg";
    else if (checkType[0] == 77 && checkType[1] == 77 && checkType[2] == 0) return ".png";
    else if (checkType[0] == 73 && checkType[1] == 68 && checkType[2] == 51) return ".mp3";
    else if (checkType[0] == 71 && checkType[1] == 73 && checkType[2] == 70) return ".gif";
    else if (checkType[0] == 77 && checkType[1] == 77 && checkType[2] == 0 && checkType[3] == 42) return ".tif";
    else if (checkType[0] == 0 && checkType[1] == 0 && checkType[2] == 0 && checkType[3] == 32 && checkType[4] == 102 && checkType[5] == 116)
      return ".mp4";
    else return "";
  }

  reDownload(String taskId)async {
    var index  =  _taskDownload.indexWhere((element) => element["id"] == taskId);
    if (index != -1){
      Map task  =  _taskDownload[index];
      task["status"] =  "downloading";
      task["progress"] = 0.0;
      notifyListeners();
      await excuteDownload(task);
    }
  }

}
