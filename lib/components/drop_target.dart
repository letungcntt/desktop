import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workcake/common/utils.dart';

class DropTarget extends ValueNotifier<bool> {
  static final channel = MethodChannel('desktop_drop_test');
  static final instance = DropTarget();

  final _droppedController = StreamController<List>.broadcast(sync: false);
  final _stringController = StreamController<String>.broadcast(sync: false);

  DropTarget() : super(false) {
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'entered':
          value = true;
          break;
        case 'exited':
          value = false;
          break;
        case 'updated':
          break;
        case 'paste': 
          var data  =   {
            "name": Utils.getRandomString(10),
            "mime_type": "image",
            "path": base64.encode(call.arguments),
            "file": call.arguments
          };
          _droppedController.add([data]);
          break;
        case 'dropped':
          Future.wait(
            (call.arguments as List).map((uro) async {
              try {
                var uri = uro.replaceAll("%2520", "%20");
                File file = Platform.isWindows ? File(uri) : File.fromUri(Uri.parse(uri));
                var name  = Platform.isWindows ? file.path.split("\\").last :  file.path.split("/").last;
                var type =  name.split(".").last;
                if (type  == "png" || type == "jpg" || type == "jpeg") type = "image";
                if (type == "") type = "text";
                return {
                  "name": name,
                  "mime_type": type,
                  "path": file.path,
                  "file": await file.readAsBytes()
                };
              } catch (e) {
                return null;
              }
              
            })
          ).then((value) {
            _droppedController.add(value.where((element) => element != null).toList());
          });
          value = false;
          break;
        case "change_theme":
          _stringController.add(call.arguments);
        break;
      }
      

      return false;
    });
  }

  void close() {
    _droppedController.close();
  }

  Stream<List> get dropped => _droppedController.stream;
  Stream<String> get currentTheme => _stringController.stream;
  initDrop() {_droppedController.add([]);}
}