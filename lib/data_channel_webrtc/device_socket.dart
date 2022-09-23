import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phoenix_wings/phoenix_wings.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/providers/providers.dart';
import '../E2EE/key.dart';
import '../E2EE/x25519.dart';
import '../common/utils.dart';


class Device {
  late final String deviceId;
  late final String ipAddress;
  late final String platform;
  late final String name;
  late final String pubIdentityKey;
  late final bool readyToUse;
  Device(this.deviceId, this.ipAddress, this.platform, this.name, this.pubIdentityKey, this.readyToUse);
}

class DataWebrtcStreamStatus{
  late String status;
  late String deviceId;
  late String targetDeviceId;
  late String sharedKey;

  DataWebrtcStreamStatus(this.status, this.deviceId, this.targetDeviceId, this.sharedKey);
}

class DeviceSocket {
  static DeviceSocket instance = DeviceSocket();

  DataWebrtcStreamStatus? dataWebrtcStreamStatus;


  // local se dc su dung khi device nay gui yeu cau den device khac
  RTCPeerConnection? localPeerConnection;
  RTCDataChannel? localChannel;
  RTCDataChannelInit? localDdataChannelDict;
  RTCSessionDescription? localOfferSessionDescription;
  RTCSessionDescription? localAnswerSessionDescription;
  PhoenixSocket? socket;
  PhoenixChannel? channel;
  String? deviceId;
  String? targetDevice;
  String? currentDevice;
  String? sharedKeyCurrentVSTarget;
  Function? callback;
  List<RTCIceCandidate> remoteIceCandidates = [];
  List<Map> chunkedFile = [];

  final qrCodeStreamController = StreamController<String?>.broadcast(sync: false);
  final syncDataWebrtcStreamController = StreamController<DataWebrtcStreamStatus>.broadcast(sync: false);
  String? dataQRCode;

  void sendRequestQrCode() async {
    var deviceInfo = await Utils.getDeviceInfo();
    if (channel == null) {
      await Future.delayed(Duration(milliseconds: 2000));
      return sendRequestQrCode();
    }
    channel!.push(event: "gen_qr_code_login_device", payload: {"device_info": deviceInfo});
  }

  void setPairDeviceId(String targetDeviceId, String currentDeviceId, String sharedKey){
    targetDevice = targetDeviceId;
    currentDevice = currentDeviceId;
    sharedKeyCurrentVSTarget = sharedKey;
    dataWebrtcStreamStatus = DataWebrtcStreamStatus("Connecting", currentDeviceId, targetDeviceId, sharedKey);
  }

  Future reconnect() async {
    channel!.leave();
    channel = null;
    dataQRCode = null;
    qrCodeStreamController.add(null);
    socket!.disconnect();
    await Utils.initPairKeyBox();
    await initPanchatDeviceSocket();
  }


  // socket theo tung device
  Future<void> initPanchatDeviceSocket() async {
    try {
      socket = new PhoenixSocket(
        Utils.socketUrl,
        socketOptions: PhoenixSocketOptions(
          heartbeatIntervalMs: 10000
        )
      );
      await socket!.connect();
      var boxKey  = await Hive.openLazyBox("pairKey");
      var identityKey  = await boxKey.get("identityKey");
      // device_public_key laf signedKey
      currentDevice = await Utils.getDeviceId();
      channel = socket!.channel("device_id:$currentDevice", {
        "device_public_key": identityKey["pubKey"],
        "device_identifier": await Utils.getDeviceIdentifier()
      });
      channel!.join();
      channel!.on("set_ice_candidate", (payload, ref, joinRef) {
        List iceCandidates = payload!["ice_candidates"];
        for (var i = 0; i < iceCandidates.length; i++){
          RTCIceCandidate remote = RTCIceCandidate(
            iceCandidates[i]["candidate"],
            iceCandidates[i]["sdpMid"],
            iceCandidates[i]["sdpMLineIndex"],
          );
          if (localPeerConnection != null) localPeerConnection!.addCandidate(remote);
          else remoteIceCandidates += [remote];
        }
      });

      channel!.on("offer", (payload, ref, joinRef) async {
        print(":offer, $payload");
        chunkedFile = [];
        RTCPeerConnection? peer = localPeerConnection;
        localPeerConnection = null;
        LazyBox box  = Hive.lazyBox('pairKey');
        var idKey =  await box.get("identityKey");
        sharedKeyCurrentVSTarget = (await X25519().calculateSharedSecret(KeyP.fromBase64(idKey["privKey"], false), KeyP.fromBase64(payload!["pub_identity_key"], true))).toBase64();
        if (localChannel != null)  await localChannel!.close();
        await peer!.close();
        await initLocalPeerConnection();
        await localPeerConnection!.setRemoteDescription(
          RTCSessionDescription(
            write(jsonDecode( payload["offer"]["sdp"]), null),
            payload["offer"]["type"]
          )
        );
        targetDevice = payload["device_id_target"];
        await localPeerConnection!.setRemoteDescription(
          RTCSessionDescription(
            write(jsonDecode( payload["offer"]["sdp"]), null),
            payload["offer"]["type"]
          )
        );
        for (int i = 0; i < remoteIceCandidates.length; i++){
          await localPeerConnection!.addCandidate(remoteIceCandidates[i]);
        }
        targetDevice = payload["device_id_target"];
        createAnswer();
      });

      channel!.on("qr_code", (payload, ref, joinRef) {
        if (payload == null) return;
        dataQRCode = payload["qr_code"];
        qrCodeStreamController.add(payload["qr_code"]);
      });

      channel!.on("tranfer_data_qrcode", (payload, ref, joinRef) async {
        try {
          if (payload == null) return;
          String oneTimePublicKey = payload["one_time_public_key"];
          String pubIdentityKey = payload["pub_identity_key"];
          var boxKey = Hive.lazyBox("pairKey");
          var identityKey = await boxKey.get("identityKey");
          var resultDe = jsonDecode(
            await Utils.decrypt(
              payload["data"],
              (await X25519().calculateSharedSecret(
                KeyP.fromBase64(identityKey["privKey"], false),
                KeyP.fromBase64(oneTimePublicKey, true)
              )).toBase64()
            )
          );
          Map dataDirect = resultDe["direct_data"] as Map;
          await Future.wait(dataDirect.keys.map((e) async {
            await boxKey.put(e, dataDirect[e]);
          }));
          Utils.setIdentityKey(pubIdentityKey);

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("userData", jsonEncode({
            ...(resultDe["user_data"] as Map),
            "pub_identity_key": pubIdentityKey
          }));
          // ban 1 event de xac nhan la da luw lai dc thong tin nhan
          pushEndEvent(resultDe["random_string"]);
        } catch (e) {
          print("tranfer_data_qrcode: $e");
        }


      });

      channel!.on("get_list_device", (payload, ref, joinRef){
        List<Device> devices = (payload!["data"] as List).map((e) => Device(
          e["device_id"], e["device_info"]["ip"] ?? "",  e["device_info"]["platform"] ?? "unknown",  e["device_info"]["name"] ?? "", e["pub_identity_key"], e["ready_to_use"]
        )).toList();
        Provider.of<DeviceProvider>(Utils.globalContext!, listen: false).setDevices(devices);
      });


      channel!.on("answer", (payload, ref, joinRef) {
        print("answer: $payload");
        if (payload == null) return;
        localPeerConnection!.setRemoteDescription(
          RTCSessionDescription(
            write(jsonDecode(payload["answer"]["sdp"]), null),
            payload["answer"]["type"])
        );
      });

      channel!.on("login_result", (payload, ref, joinRef) async {
        if (payload == null) return;
        if (payload["success"]) {
          if (Utils.loginContext != null) {
            Phoenix.rebirth(Utils.loginContext!);
          }
          Provider.of<Auth>(Utils.globalContext!, listen: false).tryAutoLogin();
        }
        return;
      });
      initLocalPeerConnection();

    } catch (e, trace) {
      print("initPanchatDeviceSocket: $e  $trace");
    }
  }

    void pushEndEvent(String randomStringFromTranferDataQrCode){
    channel!.push(event: "push_end_login", payload: {
      "random_string": randomStringFromTranferDataQrCode
    });

  }

  Future initLocalPeerConnection() async {
    localPeerConnection = await createPeerConnection(
      {
        'iceServers': [
          {
            'url': "turn:113.20.119.31:3478",
            'username': "panchat",
            'credential': "panchat"
          },
          {
            "urls": "stun:stun.l.google.com:19302",
          },
        ]
      },
      {
        'mandatory': {},
        'optional': [
          {'DtlsSrtpKeyAgreement': true},
        ],
      }
    );

    localPeerConnection!.onIceCandidate = (RTCIceCandidate candidate){
      channel!.push(event: "set_ice_candidate",payload: {
        "ice_candidates": [candidate.toMap()],
        "device_id_target": targetDevice,
        "device_id": currentDevice,
      });
    };

    localPeerConnection!.onIceConnectionState= (RTCIceConnectionState c){
      print("RTCIceConnectionState: $c");
    };

    localPeerConnection!.onConnectionState= (RTCPeerConnectionState state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed){
        syncDataWebrtcStreamController.add(DataWebrtcStreamStatus("Closed", currentDevice ?? "", targetDevice ?? "", sharedKeyCurrentVSTarget ?? ""));
      }
    };

    localDdataChannelDict = RTCDataChannelInit();
    localDdataChannelDict!.id = 1;
    localDdataChannelDict!.ordered = true;
    localDdataChannelDict!.maxRetransmitTime = -1;
    localDdataChannelDict!.maxRetransmits = -1;
    localDdataChannelDict!.protocol = 'sctp';
    localDdataChannelDict!.negotiated = false;


    localPeerConnection!.onDataChannel= (RTCDataChannel dataChannel)  {
      print("on DAta chammel;;");
      syncDataWebrtcStreamController.add(DataWebrtcStreamStatus("Connected", currentDevice ?? "", targetDevice ?? "", sharedKeyCurrentVSTarget ?? ""));
      dataChannel.onMessage = (message) async {
        if (message.type == MessageType.text) {
          Map data  = json.decode(message.text);
          if (data["type"] == "message"){

            // dataChannel.send(message);
            chunkedFile += [data];
            if (data["total"] == chunkedFile.length && data["type_transfer"] == "first") {
              chunkedFile.sort((a, b) => int.parse("${a["page"]}").compareTo(int.parse("${b["page"]}")));
              String encrypted = chunkedFile.map((e) => e["data"]).join("");
              DeviceSocket.instance.syncDataWebrtcStreamController.add(DataWebrtcStreamStatus(
                "Processing data",
                currentDevice!,
                targetDevice!,
                sharedKeyCurrentVSTarget ?? ""
              ));
              await Future.delayed(Duration(milliseconds: 500));
              String total = await Utils.decrypt(encrypted, sharedKeyCurrentVSTarget ?? "");
               await Future.delayed(Duration(milliseconds: 500));
              DeviceSocket.instance.syncDataWebrtcStreamController.add(DataWebrtcStreamStatus(
                "Saving",
                currentDevice!,
                targetDevice!,
                sharedKeyCurrentVSTarget ?? ""
              ));
              await MessageConversationServices.saveJsonDataMessage(json.decode(total));

              await Future.delayed(Duration(milliseconds: 500));
              DeviceSocket.instance.syncDataWebrtcStreamController.add(DataWebrtcStreamStatus(
                "Done",
                currentDevice!,
                targetDevice!,
                sharedKeyCurrentVSTarget ?? ""
              ));

              await Future.delayed(Duration(milliseconds: 500));
              DeviceSocket.instance.setPairDeviceId("", "", "");
            }
            else DeviceSocket.instance.syncDataWebrtcStreamController.add(DataWebrtcStreamStatus(
              "Recieving ${chunkedFile.length }/${data["total"]}",
              currentDevice!,
              targetDevice!,
              sharedKeyCurrentVSTarget ?? ""
            ));
          }
        } else {
          // do something with message.binary
        }
      };
    };
  }


  void createAnswer() async {
    RTCSessionDescription answer = await localPeerConnection!.createAnswer();
    localPeerConnection!.setLocalDescription(answer);
    channel!.push(event: "answer", payload: {
      "device_id_target": targetDevice,
      "device_id": currentDevice,
      "session_description": {
        ...(answer.toMap() as Map),
        "sdp":  jsonEncode(parse(answer.sdp as String))
      }
    });
  }

   void createOffer(Function call) async {
    try {
      chunkedFile = [];
      if (localChannel != null) await localChannel!.close();
      await localPeerConnection!.close();
      await initLocalPeerConnection();
      localChannel = await localPeerConnection!.createDataChannel('sendChannel', localDdataChannelDict!);
      syncDataWebrtcStreamController.add(DataWebrtcStreamStatus("Connecting", deviceId ?? "", targetDevice ?? "", sharedKeyCurrentVSTarget ?? ""));
      localChannel!.onMessage = (message) async {
        if (message.type == MessageType.text) {
           Map data  = json.decode(message.text);
            chunkedFile += [data];
            if (data["total"] == chunkedFile.length) {
              chunkedFile.sort((a, b) => int.parse("${a["page"]}").compareTo(int.parse("${b["page"]}")));
              String encrypted = chunkedFile.map((e) => e["data"]).join("");
              String total = await Utils.decrypt(encrypted, sharedKeyCurrentVSTarget ?? "");
              await MessageConversationServices.saveJsonDataMessage(json.decode(total));
              syncDataWebrtcStreamController.add(DataWebrtcStreamStatus("Done", currentDevice ?? "", targetDevice ?? "", sharedKeyCurrentVSTarget ?? ""));
              await Future.delayed(Duration(milliseconds: 1000));
              DeviceSocket.instance.setPairDeviceId("", currentDevice!, "");
            }
            else DeviceSocket.instance.syncDataWebrtcStreamController.add(DataWebrtcStreamStatus(
              "Recieving ${data["page"]}/${data["total"]}",
              currentDevice!,
              targetDevice!,
              sharedKeyCurrentVSTarget ?? ""
            ));
        } else {
          // do something with message.binary
        }
      };

      localChannel!.onDataChannelState = ((RTCDataChannelState state){
        print("state: $state");
        if (state == RTCDataChannelState.RTCDataChannelOpen) {
          syncDataWebrtcStreamController.add(DataWebrtcStreamStatus("Connected", deviceId ?? "", targetDevice ?? "", sharedKeyCurrentVSTarget ?? ""));
          call();
        }
        if (state == RTCDataChannelState.RTCDataChannelClosed) {
          syncDataWebrtcStreamController.add(DataWebrtcStreamStatus("Closed", currentDevice!, targetDevice!, sharedKeyCurrentVSTarget ?? ""));
        }
      });


      localOfferSessionDescription = await localPeerConnection!.createOffer();
      localPeerConnection!.setLocalDescription(localOfferSessionDescription!);
      channel!.push(event: "offer", payload: {
        "device_id_target": targetDevice,
        "device_id": currentDevice,
        "session_description": {
          ...(localOfferSessionDescription!.toMap() as Map),
          "sdp":  jsonEncode(parse(localOfferSessionDescription!.sdp as String))
        }
      });

    } catch (e, trace) {
      print(trace);
    }
  }
  Widget renderQRCode() {
    return Container(
      child: StreamBuilder(
        stream: qrCodeStreamController.stream,
        initialData: dataQRCode,
        builder: (context, snapshot) {
          String? qrCode = snapshot.data as String?;
          if (qrCode == null)
            return Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(4))),
              child: Container(
                child: Opacity(
                  opacity: 0.5,
                  child: SpinKitFadingCircle(
                    color: Color(0xff096DD9),
                    size: 19,
                  ),
                ),
              ),
            );
          return QrImage(
            backgroundColor: Colors.white,
            data: "$currentDevice,$qrCode",
            version: QrVersions.auto,
            size: 200.0,
          );
        }
      ),
    );
  }
}
