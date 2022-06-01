import 'dart:async';
import 'dart:isolate';
import 'package:workcake/media_conversation/model.dart';
import 'package:workcake/media_conversation/stream_media_downloaded.dart';
import 'package:workcake/objectbox.g.dart';

class IsolateMedia {
  static var mainSendPort;
  static Store? storeObjectBox;
  static Future createIsolate() async {
    Completer completer = new Completer<SendPort>();
    ReceivePort isolateToMainStream = ReceivePort();

    isolateToMainStream.listen((data) {
      if (data is SendPort) {
        SendPort mainToIsolateStream = data;
        completer.complete(mainToIsolateStream);
      } else {
        try {
          if (data is Map && data["type"] == "path_in_device"){
            String remoteUrl = data["remote_url"];
            String pathInDevice =  data["path_in_device"];
            StreamMediaDownloaded.dataStatus[remoteUrl] = {
              "type": "local",
              "path": pathInDevice
            };
            StreamMediaDownloaded.instance.statusMediaDownloadedController.add(StreamMediaDownloaded.dataStatus);
          }          
        } catch (e) {
        }
      }
    });
    await Isolate.spawn(heavyComputationTask, isolateToMainStream.sendPort);
    return completer.future;
  }

  static heavyComputationTask(SendPort isolateToMainStream) async {
    ReceivePort mainToIsolateStream = ReceivePort();
    isolateToMainStream.send(mainToIsolateStream.sendPort);
    mainToIsolateStream.listen((data) {
      if (data["type"] == "get_all_media_from_message"){
        Store store = Store.fromReference(getObjectBoxModel(), data["box_reference"]);
        ServiceMedia.getAllMediaFromMessageIsolate(data["data"], store, data["path_save_file"], isolateToMainStream);
      }
    });
  }
}