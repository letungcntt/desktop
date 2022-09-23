import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:workcake/E2EE/x25519.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/services/download_status.dart';
import 'package:http/http.dart' as http;
import 'package:workcake/services/upload_status.dart';
import 'package:image/image.dart' as img;

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

  getUploadData(file) async {
    var data = file["file"];
    var imageData = {};
    var thumbnail;
    if (file["type"] == "image") {
      var decodedImage = await decodeImageFromList(file["file"]);
      imageData = {
        "width": decodedImage.width,
        "height": decodedImage.height
      };
    }

    if (["mp4", "mov"].contains((file["mime_type"] ?? "").toLowerCase())) {
      file["type"] = "video";
    }

    if (file["type"] == "video") {
      if (Platform.isMacOS) {
        try {
          Uint8List? bytesThumbnail;
          bytesThumbnail =  await VideoCompress.getByteThumbnail(
            file["path"],
            quality: 90, 
            position: -1 
          ).timeout(Duration(seconds: 1));
        
          var decodedImage = await decodeImageFromList(bytesThumbnail!);
          imageData = {
            "width": decodedImage.width,
            "height": decodedImage.height
          };
          thumbnail = {
            "filename": file["name"],
            "path": bytesThumbnail,
            "image_data": imageData
          };
        } catch (e) {
          print("VideoCompress.getByteThumbnail error: $e, move to getTemporaryDirectory");

          try {
            var pathOther = await getTemporaryDirectory();
            var bytesFile = file["file"];
            String tempPath = pathOther.path + "/${file["name"]}";
            File tempFile = File(tempPath);
            await tempFile.writeAsBytes(bytesFile, mode: FileMode.write);

            Uint8List? bytesThumbnail;
            bytesThumbnail =  await VideoCompress.getByteThumbnail(
              tempPath,
              quality: 90, 
              position: -1 
            ).timeout(Duration(seconds: 1));
          
            var decodedImage = await decodeImageFromList(bytesThumbnail!);
            imageData = {
              "width": decodedImage.width,
              "height": decodedImage.height
            };
            thumbnail = {
              "filename": file["name"],
              "path": bytesThumbnail,
              "image_data": imageData
            };

            tempFile.delete();
          } catch (e, t) {
            print("getTemporaryDirectory $e, $t");
          }
        }
      }

      // if(file["mime_type"].toString().toLowerCase() == "mov"  && !Platform.isWindows) {
      //   var pathOther = await getTemporaryDirectory();
      //   var bytesFile;
      //   String out = pathOther.path + "/${file["name"].toString().toLowerCase().replaceAll(" ", "").replaceAll(".mov", "")}.mp4";
      //   File tempFile = File(file["path"]);
      //   bytesFile = await tempFile.readAsBytes();
      //   File newFile = File(pathOther.path +  "/${file["name"].toString().toLowerCase().replaceAll(" ", "")}");
      //   await newFile.writeAsBytes(bytesFile, mode: FileMode.write);
      //   await FFmpegKit.execute('-y -i ${newFile.path} -c copy $out').then((session) async {
      //     final returnCode = await session.getReturnCode();
      //     if(ReturnCode.isSuccess(returnCode)) {
      //       File u = File(out);
      //       data = u.readAsBytesSync();
      //       await u.delete();
      //     }
      //     else if (ReturnCode.isCancel(returnCode)) {
      //       print("Session Cancel");
      //     }
      //     else {
      //       print("Convert Failed");
      //     }
      //   });
      //   await newFile.delete();
      // }
    }

    imageData = {...imageData, "size": file["size"]};

    return {
      "filename": file["name"],
      "path": data,
      "length": data.length,
      "mime_type": file["mime_type"],
      "type": file["type"],
      'preview': file['preview'],
      "name": file["name"],
      "progress": "0",
      "image_data": imageData,
      "thumbnail" : thumbnail,
    };
  }

  Future<dynamic> uploadThumbnail(String token, workspaceId, file, type) async {
    try {
      if (type != "video") return {};
      var content = await getContentFromApi(token, workspaceId, file["path"]);
      if (content["success"]) {
        return content;
      } else {
        FormData formData = FormData.fromMap({
          "data": MultipartFile.fromBytes(
            file["path"], 
            filename: file["filename"],
          ),
          "content_type": type,
          "filename": file["filename"]
        });

        final url = Utils.apiUrl + 'workspaces/$workspaceId/contents/v2?token=$token';
        final response = await Dio().post(url, data: formData);
        final responseData = response.data;
        return responseData;
      }
    } catch (e) {
      print("uploadThumbnail error: $e");
      return {};
    }
  }
   
  getContentFromApi(token, workspaceId, data) async {
    var bytes = utf8.encode(base64.encode(data)); // data being hashed
    var hashId = sha1.convert(bytes).toString().toLowerCase();

    try {
      final res = await http.get(Uri.parse(Utils.apiUrl + 'workspaces/$workspaceId/contents/$hashId?token=$token'));
      final responseData = json.decode(res.body);
      return responseData;
    } catch (e) {
      print("getContentFromApi error: $e");
      return {'success': false};
    }
  }

  uploadImage(String token, workspaceId, file, type, Function onSendProgress, {String key = "", List? pathFolder, bool isDirect = false}) async {
    Map rootFileData = file;
    var imageData = file["image_data"];

    if (type == "image") {
      var decodedImage = await decodeImageFromList(file["path"]);
      imageData = {
        ...imageData,
        "width": decodedImage.width,
        "height": decodedImage.height
      };

      if (file["path"].length > 2999999) {
        img.Image? imageTemp = img.decodeImage(file["path"]);

        if (imageTemp != null) {
          file["path"] = img.encodeJpg(imageTemp, quality: 70);
        }
      }
    }

    if (isDirect) {
      key = (await X25519().generateKeyPair()).secretKey.toString();
      file = {
        ...file,
        // v1 khoang 1 tuan sau chuyen sang v2
        //  "path": base64Decode((await Utils.encrypt(base64Encode(file["path"]), key)))
        //  v2
        "path": await Utils.encryptBytes(file["path"] as List<int>, key)
      };
    }

    var result  = {};
    try {
      var content = await getContentFromApi(token, workspaceId, file["path"]);

      if (content["success"] && pathFolder == null) {
        var thumbnail = file["thumbnail"] != null ? await uploadThumbnail(token, workspaceId, file["thumbnail"], type) : {};
        result = {
          "success": true,
          "content_url":  content["content_url"],
          "type": file["type"],
          "mime_type": file["mime_type"],
          "name": file["name"] ?? "",
          "image_data": imageData ?? content["image_data"],
          "filename": file["filename"],
          "url_thumbnail" : thumbnail["content_url"]
        };
      } else {
        final url = pathFolder == null 
            ? Utils.apiUrl + 'workspaces/$workspaceId/contents/v2?token=$token' 
            : Utils.apiUrl + 'workspaces/$workspaceId/file_explorers?token=$token';
        num percent = 0;
        FormData formData = FormData.fromMap({
          "data": MultipartFile.fromBytes(
            file["path"], 
            filename: file["filename"],
          ),
          "content_type": type,
          "mime_type": type,
          "image_data" : imageData,
          "filename": file["filename"],
          "path_folder": pathFolder != null ? json.encode(pathFolder) : null,
        });

        final response = await Dio().post(url, data: formData, onSendProgress: (count, total) {
          if ((count*100/total).round() - percent > 1) {
            percent = (count*100/total).round();
            StreamUploadStatus.instance.setUploadStatus(key, count/total);
          }
        });
        final responseData = response.data;
        if (responseData["success"]) {
          result = {
            "success": true,
            "content_url":  Uri.encodeFull(responseData["content_url"]),
            "mime_type": file["mime_type"],
            "name": file["name"] ?? "",
            "image_data": imageData ?? responseData["image_data"],
            "filename": file["filename"],
            "type": file["type"],
            "inserted_at": responseData["inserted_at"],
          };
          if (file["type"] == "video") {
            var res = await uploadThumbnail(token, workspaceId, file["thumbnail"], type);
            result["url_thumbnail"] = res["content_url"];
          }
        } 
        else {
          result =  {
            "success": false,
            "message": responseData["message"],
            "file_data": rootFileData
          };
          print("uploadImage error ${responseData["message"]}");
        }
      }
    } catch (e) {   
      print("uploadImage error:   $e");
      result = {
        "success": false,
        "file_data": rootFileData
      };
    }
    // v1
    // return Utils.mergeMaps([result, {"name": file["filename"], "uploading": false, 'preview': file['preview'], "version": 1, "key_encrypt": isDirect ? key : null}]);
    // v2
    return Utils.mergeMaps([result, {"name": file["filename"], "uploading": false, 'preview': file['preview'], "version": 2, "key_encrypt": isDirect ? key : null}]);
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
    String id  =  download["id"] ??  Utils.getRandomString(10);
    var name = download['name'] != null ? download['name'].replaceAll(":", "-") : Utils.getRandomString(10);
    // gen a new Id
    Map task = Utils.mergeMaps([
      download, {
        "id": id,
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
          if (Utils.checkedTypeEmpty(task["key_encrypt"]) && task["key_encrypt"].length > 30){
            if ( task["version"] == 2) await file.writeAsBytes(await Utils.decryptBytes(bytes, task["key_encrypt"]), mode: FileMode.write);
            else  await file.writeAsBytes(base64Decode(await Utils.decrypt(base64Encode(bytes), task["key_encrypt"])), mode: FileMode.write);
          }
          else await file.writeAsBytes(bytes, mode: FileMode.write);
          task["status"] = "done";
          task["uri"] = file.path;
          notifyListeners();
        });
      } catch (e, t) {
        task["status"] = "error";
        task["progress"] = 0.0;
        notifyListeners();
        print("download att $e $t");
      }
    });
  }

  static checkTypeFile(checkType) {
    if (checkType[0] == 255 && checkType[1] == 216 && checkType[2] == 255) return ".png";
    else if (checkType[0] == 137 && checkType[1] == 80 && checkType[2] == 78) return ".jpg";
    else if (checkType[0] == 77 && checkType[1] == 77 && checkType[2] == 0) return ".png";
    else if (checkType[0] == 73 && checkType[1] == 68 && checkType[2] == 51) return ".mp3";
    else if (checkType[0] == 71 && checkType[1] == 73 && checkType[2] == 70) return ".gif";
    else if (checkType[0] == 66 && checkType[1] == 77) return ".png";
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
