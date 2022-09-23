import 'dart:async';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:workcake/components/message_item/attachments/audio_player_message.dart';
import 'package:workcake/media_conversation/model.dart';

import '../common/cached_image.dart';

class StreamMediaDownloaded extends ValueNotifier<bool>{
  static final instance = StreamMediaDownloaded();
  static Map<String, Map> dataStatus = {};
  final _statusMediaDownloadedController = StreamController<Map>.broadcast(sync: false);

  get statusMediaDownloadedController => _statusMediaDownloadedController;

  StreamMediaDownloaded(): super(false);
  Stream<Map> get status => _statusMediaDownloadedController.stream;

  setStreamDownloadedStatus(String remoteUrl) async {
    var pathInDevice = await ServiceMedia.getDownloadedPath(remoteUrl);
    if (pathInDevice != null){
      dataStatus[remoteUrl] = {
        "type": "local",
        "path": pathInDevice
      };
      _statusMediaDownloadedController.add(dataStatus);      
    }
  }

  setStreamOldFileStatus(String remoteUrl) async {
    dataStatus[remoteUrl] = {
      "type": "remote",
      "path": remoteUrl
    };
    _statusMediaDownloadedController.add(dataStatus); 
  }
}


class ImageDirect {
  static Widget build(BuildContext context, String contentUrl, {Function? customBuild}){
    return StreamBuilder(
      stream: StreamMediaDownloaded.instance.status,
      initialData: StreamMediaDownloaded.dataStatus,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) { 
        Map data = snapshot.data ?? {};
        if (data[contentUrl] != null){
          if (data[contentUrl]["type"] == "local"){
            if (customBuild != null){
              return customBuild(data[contentUrl]["path"]);
            }
            return Container(
              alignment: Alignment.centerLeft,
              child: ExtendedImage.file(
                File(data[contentUrl]["path"]),
                fit: BoxFit.contain,
              ),
            );
          }
          return CachedImage(data[contentUrl]["path"]);
        } return Container(
          child: Text("downloading data"),
        );
      }, 
    );
  }
}

class RecordDirect {
  static Widget build(BuildContext context, att, {Function? customBuild}){
    final String contentUrl =  att["content_url"];
    return StreamBuilder(
      stream: StreamMediaDownloaded.instance.status,
      initialData: StreamMediaDownloaded.dataStatus,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) { 
        Map data = snapshot.data ?? {};
        if (data[contentUrl] != null) {
          if (data[contentUrl]["type"] == "local") {
            if (customBuild != null){
              return customBuild(data[contentUrl]["path"]);
            }
            return AudioPlayerMessageDirect(
              path: data[contentUrl]["path"],
              att: att,
            );
          }
          return AudioPlayerMessageDirect(
            path: data[contentUrl]["path"],
            att: att
          );
        }
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                height: 32,
              )
            ],
          ),
        );
      }, 
    );
  }
}