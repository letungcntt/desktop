import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/media_conversation/isolate_media.dart';
import 'package:workcake/media_conversation/service_box.dart';
import 'package:workcake/services/queue.dart';
import '../objectbox.g.dart';

@Entity()
class Media{
  @Id(assignable: true)
  late int localId;
  String? pathInDevice;
  @Index()
  late String remoteUrl;
  @Index()
  late String name;
  late String type;
  late String metaData;
  late int size;
  late String keyEncrypt;
  late String status;
  late int? version;

  Media(this.localId, this.pathInDevice, this.remoteUrl, this.name, this.type, this.metaData, this.size, this.keyEncrypt, this.status, this.version);

  static Media? parseFromObj(Map obj){
    try {

      String type = obj["type"] ?? obj["mime_type"];
      switch (type) {
        case 'mp4':
        case 'mov':
        case 'flv':
        case 'avi':
          type = 'video';
          break;
        default:
      }
      return Media(
        obj["content_url"].hashCode,
        "", 
        obj["content_url"], 
        obj["name"], 
        type,
        obj["meta_data"] ?? "",
        obj["size"] ?? 0,
        obj["key_encrypt"] ?? "",
        obj["status"] ?? "not download",
        obj["version"] ?? 1
      );
    } catch (e, trace) {
      print("_________________$e :$trace");
      return null;
    } 
  }

  static Future<Media?> checkFileHasDownloaded(String contentUrl, Store store) async {
    int loaclId = contentUrl.hashCode;
    Box box = store.box<Media>();
    Media? local =  await box.get(loaclId);
    if (local == null) return null;
    if (await checkPathHasExisted(local.pathInDevice ?? "")) return local;
    return null;
  }

  static Future<bool> checkPathHasExisted(String pathInDevice) async {
    return await File(pathInDevice).exists();
  }


  Future<Media?> saveToDisk(Store store, SendPort isolateToMainStream) async {
    try {
      Box box = store.box<Media>();
      box.put(this);
      if (this.status == "downloaded") {
        isolateToMainStream.send({
          "remote_url": this.remoteUrl,
          "path_in_device": this.pathInDevice,
          "type": "path_in_device"
        });
      }
      return this;
    } catch (e) {
      print("saveToDisk: $e");
      return null;
    }
  }

  Future<Media?> downloadToDevice(Store store, String pathSaveFile, SendPort isolateToMainStream) async {
    try {  
      Media? hasExisted = await Media.checkFileHasDownloaded(this.remoteUrl, store);
      if (hasExisted != null) return hasExisted;

      // var appDocDirectory = await getApplicationDocumentsDirectory();
      var path  = pathSaveFile + "/conversation_media";

      Directory directory = await  new Directory(path).create(recursive: true);
      try {
        Response response = await Dio().get(
        this.remoteUrl,
        onReceiveProgress: (count, total) {
          // notifyListeners();
        },
        //Received data with List<int>
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false, 
          receiveTimeout: 0),
        );
        final path = directory.path;
        var checkType = [];
        for (int i = 0; i <= 5; i++) {
          checkType.add(response.data[i]);
        }
        var nameFile = this.name;
        File file = File("$path/${DateTime.now().microsecondsSinceEpoch.toString() + nameFile.replaceAll(" ", "_")}");
        if (Utils.checkedTypeEmpty(this.keyEncrypt)){
          if (this.version == 2) await file.writeAsBytes(await Utils.decryptBytes(response.data, this.keyEncrypt), mode: FileMode.write);
          else await file.writeAsBytes(base64Decode(await Utils.decrypt(base64Encode(response.data), this.keyEncrypt)), mode: FileMode.write);
        }
        else file.writeAsBytes(response.data, mode: FileMode.write);
        this.pathInDevice = file.path;
        this.status = "downloaded";
        this.size = response.data.length;
        return await this.saveToDisk(store, isolateToMainStream);
      } catch (e, t) {
        print("download att $e $t");
        return null;
      }
    } catch (e, trace) {
      print("downloadToDevice: $e  $trace");
      return null;
    }
  }

  Map toJson(){
    return {
      "path_in_device": this.pathInDevice,
      "type": this.type,
      "status": this.status,
      "remote_url": this.remoteUrl,
      "key_encrypt": this.keyEncrypt
    };
  }
}

@Entity()
class MediaConversation {
  @Id(assignable: true)
  late int localId;
  late String messageId;
  late String userId;
  @Index()
  late String conversationId;
  late String insertedAt;
  late String keyDecrypt;
  late int currentTime;
  final media = ToOne<Media>();


  MediaConversation(
    int localId,
    String messageId,
    String userId,
    String conversationId,
    String insertedAt,
    int currentTime,
    String keyDecrypt
  ){
    this.localId = localId;
    this.messageId = messageId;
    this.userId = userId;
    this.conversationId = conversationId;
    this.insertedAt = insertedAt;
    this.currentTime = currentTime;
    this.keyDecrypt = keyDecrypt;
  }

  static MediaConversation? parseFromObj(Map obj){
    try {
      return MediaConversation(
        obj["local_id"] ?? 0,
        obj["id"],
        obj["user_id"] ?? obj["userId"],
        obj["conversation_id"] ?? obj["conversationId"] ?? '',
        obj["inserted_at"] ?? obj["time_create"] ?? obj["insertedAt"] ?? obj["timeCreate"],
        DateTime.parse(obj["inserted_at"] ?? obj["time_create"] ?? obj["insertedAt"] ?? obj["timeCreate"]).microsecondsSinceEpoch,
        obj["key_decrypt"] ?? "",
      );
    } catch (e, trace) {
      print(">>>>>>>>>>$e $obj  $trace");
    }
    return null; 
  }

  Map toJson(){
    return {
      "local_id": this.localId,
      "message_id": this.messageId,
      "user_id": this.userId,
      "conversation_id": this.conversationId,
      "inserted_at": this.insertedAt,
      "key_decrypt": this.keyDecrypt,
    };
  }


}


class ServiceMedia {

// dam bao ko co qua nhieu task chajy trong 1 thoi gian
  static Scheduler task = new Scheduler();

  static deleteMediaByDeleteTime(int deleteTime, String conversationId, Store store) async {
    try {
      if (deleteTime == 0) return;
      // delete mediaConversation
      Box boxMediaConversation = store.box<MediaConversation>();
      Box boxMedia = store.box<Media>();
      var mediaConversationQuery = MediaConversation_.conversationId.equals(conversationId)
      .and(MediaConversation_.currentTime.lessThan(deleteTime));

      List finded = boxMediaConversation.query(mediaConversationQuery).build().find();
      await Future.wait(
        finded.map((e) async {
          String? pathInDevice = e.media.target?.pathInDevice;
          // delete files on device
          if (pathInDevice != null && (await File.fromUri(Uri.parse(pathInDevice)).exists())) await (File.fromUri(Uri.parse(pathInDevice))).delete();
          // delete media
          if (e.media.target != null)  boxMedia.remove(e.media.target.localId);
          // delete media conversation
          boxMediaConversation.remove(e.localId);
          return null;
        })
      );      
    } catch (e, t) {
      print("deleteMediaByDeleteTime: $e, $t");
    }
  }
  
  static getNumberOfConversation(String conversationId) async {
    Store store =  await ServiceBox.getObjectBox();
    Box box = store.box<MediaConversation>();
    var qCountImage  = box.query(
      MediaConversation_.conversationId.equals(conversationId)
    );
    qCountImage.link(MediaConversation_.media, Media_.type.equals("image").or(Media_.type.equals("video")));
    int count = qCountImage.build().count();

    var qCountFile  = box.query(
      MediaConversation_.conversationId.equals(conversationId)
    );
    qCountFile.link(MediaConversation_.media, Media_.type.notEquals("image").and(Media_.type.notEquals("video")));
    int countFile = qCountFile.build().count();

    return {
      "images": count,
      "files": countFile
    };
  }

  static Future<String?> getDownloadedPath(String remoteUrl) async {
    Store store =  await ServiceBox.getObjectBox();
    Box box = store.box<Media>();
    var query = ((box.query(
      Media_.remoteUrl.equals(remoteUrl)
    )));
    final fq = query.build();
    Media? result = fq.findFirst();
    if (result != null) {
      if (await (File(result.pathInDevice ?? "")).exists()){
        return result.pathInDevice;
      }
      return null;
    }
    return null;
  }

  static Future autoDownloadAttDM() async {
    // Store store =  await ServiceBox.getObjectBox();
    // Box box = store.box<Media>();
    // var query = ((box.query(
    //   Media_.status.equals("not download")
    // )));
    // final fq = query.build();
    // List<Media> results = fq.find() as List<Media>;
    // await Future.wait(results.map((e) => e.downloadToDevice()));

  }

  static loadConversationMedia(String conversationId, int limit, int currentTime, String type) async {
    try {
      Store store =  await ServiceBox.getObjectBox();
      Box box = store.box<MediaConversation>();
      var query = ((box.query(
        MediaConversation_.conversationId.equals(conversationId)
        .and(MediaConversation_.currentTime.lessOrEqual(currentTime))  
      ))
      ..order(MediaConversation_.currentTime, flags: Order.descending));
      if (type == "image_video")
        query.link(MediaConversation_.media, Media_.type.equals('image').or(Media_.type.equals('video')));
      else query.link(MediaConversation_.media, Media_.type.notEquals("image").and(Media_.type.notEquals("video")));
      final fq = query.build();
      fq..limit = limit;
      List result = fq.find();
      return {
        "data": result.map((e) {
          final ele = e as MediaConversation;
          ele.media.target!.status = (File(ele.media.target?.pathInDevice ?? "")).existsSync() ? 'downloaded' : 'not download';
          return ele;
        }).toList()
      };      
    } catch (e) {
      return {
        "data": [],
        "message": "false to load data"
      };  
    } 
  }

  static getAllMediaFromMessageViaIsolate(Map message) async {
    // task.schedule(() async {
      var appDocDirectory = await getApplicationDocumentsDirectory();
      IsolateMedia.mainSendPort!.send({
        "type": "get_all_media_from_message",
        "data": message,
        "path_save_file": appDocDirectory.path,
        "box_reference": IsolateMedia.storeObjectBox!.reference
      });
    // });
  }

  static getAllMediaFromMessageIsolate(Map message, Store store, String pathSaveFile, SendPort isolateToMainStream) async {
    try {
      await Future.wait((message["attachments"] as List).map((m) async {
        try {
          if (m["mime_type"] == "share" || m["mime_type"] == "shareforwar"){
            await getAllMediaFromMessageIsolate({
              ...m["data"],
              "conversation_id": message['conversation_id'] ?? message['conversationId'] ?? '',
              "inserted_at": message["time_create"] ?? message["inserted_at"] ?? message["timeCreate"] ?? message["insertedAt"]
            }, store, pathSaveFile, isolateToMainStream); 
          }
          if (!Utils.checkedTypeEmpty(m["content_url"])) return;
          var media = (await Media.checkFileHasDownloaded((m["content_url"]), store)) ?? Media.parseFromObj({
            ...m,
            "meta_data": json.encode({
              "url_thumbnail": m['url_thumbnail'] ?? ''
            }),
            "inserted_at": message["time_create"] ?? message["inserted_at"] ?? message["timeCreate"] ?? message["insertedAt"]
          });  
          MediaConversation? mediaConv = MediaConversation.parseFromObj({
            ...message,
            "local_id": (message["id"] + m["content_url"]).hashCode,
          });
          if (media == null || mediaConv == null) return;
          media.saveToDisk(store, isolateToMainStream);  

          mediaConv.media.target = media;
          store.box<MediaConversation>().put(mediaConv);
          media.downloadToDevice(store, pathSaveFile, isolateToMainStream);
        } catch (e, trace) {
          print(":::::::$e $trace  $m");
        }
        
      }));      
    } catch (e) {
      print("getAllMediaFromMessage: $e");
    }
  }
}