import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:phoenix_wings/phoenix_wings.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:uuid/uuid.dart';
import 'package:workcake/common/utils.dart';



enum SignalingState {
  ConnectionOpen,
  ConnectionClosed,
  ConnectionError,
}

const RTC_CONFIGURATION = {
  "iceServers": [
    {
      'url': "turn:113.20.119.31:3478",
      'username': "panchat",
      'credential': "panchat"
    },
  ]
};

const OFFER_SDP_CONSTRAINTS = {
  "mandatory": {
    "OfferToReceiveAudio": true,
    "OfferToReceiveVideo": true,
  },
  "optional": [],
};

enum CallState {
  CallStateNew,
  CallStateRinging,
  CallStateInvite,
  CallStateReached,
  CallStateConnected,
  CallStateDisconnected,
  CallStateBye,
  CallStateError
}

typedef Future<void> CallStateCallback(CallState state);
typedef void StreamStateCallback(MediaStream stream, List<MediaDeviceInfo> listMediaDevice);
typedef void OtherEventCallback(dynamic event);
typedef void SignalStartCallback(CallState state, [type, user, mediaType, conversationId, callback]);
typedef void ScreenStateCallback(bool collapse);

class P2PManager {
  static P2PManager get instance => _getInstance();
  static P2PManager? _instance;

  static P2PManager _getInstance () {
    if (_instance == null) {
      _instance = P2PManager._internal();
    }
    return _instance!;
  }

  P2PManager._internal();
  Future<void> init(channel, selfId) async {
    this.selfId = selfId;
    this.channel = channel;
    this.deviceId = await Utils.getDeviceId();
  }

  late CallStateCallback onCallStateChange;
  late SignalStartCallback onSignalingStartCallback;
  late StreamStateCallback onLocalStream;
  late StreamStateCallback onAddRemoteStream;
  late StreamStateCallback onRemoveRemoteStream;
  late OtherEventCallback onPeersUpdate;
  // late ScreenStateCallback onScreenStateCallback;

  RTCPeerConnection? peerConnection;
  List<RTCIceCandidate> remoteCandidates = [];
  late PhoenixChannel channel;
  late String deviceId;
  late String selfId;
  String? peerId;
  String sessionId = "";

  MediaStream? localStream;
  List<MediaDeviceInfo> listMediaDevices = [];
  
  bool isMuteMic = false;
  bool isOnVideo = false;

  Future<void> handleMediaEvent (event) async {
    bool correctEvent = validateCorrectEvent(event);
    if (!correctEvent) return;
    
    switch (event['type']) {
      case "offer":
        if (peerId != null) return;
        var peer = event["from"];
        final mediaType = event["mediaType"] ?? "video";
        this.peerId = peer["id"];
        this.sessionId = event["session_id"];
        
        Future<void> callback () async {
          await createConnect(peerId: peerId!, mediaType: mediaType);
          var sdpSession = await jsonDecode(event["description"]);
          String sdp = write(sdpSession, null);
          RTCSessionDescription description = new RTCSessionDescription(sdp, "offer");
          await peerConnection!.setRemoteDescription(description);
          await createAnswer();
          if (remoteCandidates.length > 0) {
            remoteCandidates.forEach((candidate) async {
              try {
                await peerConnection!.addCandidate(candidate);
              } catch (e) {}
            });
            remoteCandidates.clear();
          }
          onCallStateChange.call(CallState.CallStateConnected);
        }
        onSignalingStartCallback.call(CallState.CallStateConnected, "answer", peer, mediaType,"", callback);
        sendMediaEvent('control_event', {
          "from": selfId,
          "to": peerId,
          "event": {
            "type": "reached",
            "data": ""
          }
        });
      break;
      case "answer":
        var sdpSession = await jsonDecode(event["description"]);
        String sdp = write(sdpSession, null);
        RTCSessionDescription description = new RTCSessionDescription(sdp, "answer");
        peerConnection?.setRemoteDescription(description);
        onCallStateChange.call(CallState.CallStateConnected);
      break;
      case "candidate":
        RTCIceCandidate candidate = RTCIceCandidate(event["candidate"], event["sdpMid"], event["sdpMlineIndex"]);
        if (peerConnection != null) {
          try {
            await peerConnection!.addCandidate(candidate);
          } catch (e) {}
        } else {
          remoteCandidates.add(candidate);
        }
      break;
      case "broadcast":
        var otherDevice = event["device_id"];
        if (deviceId != otherDevice) {
          onSignalingStartCallback.call(CallState.CallStateBye);
          releaseConnect();
        }
      break;
      case "control_event":
        handleControlEvent(event["event"]);
      break;
      case "terminate":
        onCallStateChange.call(CallState.CallStateBye).then((_) => onSignalingStartCallback.call(CallState.CallStateBye));
        releaseConnect();
      break;
    }
  }

  Future<bool> createConnect({required String peerId, required mediaType}) async {
    this.peerId = peerId;
    this.localStream = await createStream(mediaType);
    if (this.localStream == null) {
      return false;
    }
    RTCPeerConnection peerConnection = await createPeerConnection({...RTC_CONFIGURATION, "sdpSemantics": "plan-b"}, OFFER_SDP_CONSTRAINTS);
    await peerConnection.addStream(localStream!);
    
    // Timer.periodic(Duration(milliseconds: 500), (timer) {
    //   peerConnection.getStats(localStream!.getAudioTracks()[0]).then((statsList) {
    //   // print("audio input level: ${statsList[15].values["audioInputLevel"]}-----audio output level: ${statsList[33].values["audioOutputLevel"]}");
    //   final indexElementAudioInput = statsList.indexWhere((element) => element.values["audioInputLevel"] != null);
    //   final indexElementAudioOutput = statsList.indexWhere((element) => element.values["audioOutputLevel"] != null);
    //   print("audio input: ${indexElementAudioInput != -1 ?statsList[indexElementAudioInput].values["audioInputLevel"] : "null"}, audio output: ${indexElementAudioOutput != -1 ? statsList[indexElementAudioOutput].values["audioOutputLevel"] : "null"}");
    // });
    // });

    peerConnection.onAddStream = (stream) {
      onAddRemoteStream.call(stream, []);
    };
    peerConnection.onIceCandidate = (e) {
      if (e.candidate != null) {
        sendMediaEvent('candidate', {
          'from': selfId,
          'to': peerId,
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid.toString(),
          'sdpMlineIndex': e.sdpMLineIndex,
          'session_id': sessionId
        });
      }
    };
    peerConnection.onIceConnectionState = (state) {
      print(state.toString());
    };
    this.peerConnection = peerConnection;
    return true;
  }
  Future<void> createOffer(String mediaType) async {
    try {
      RTCSessionDescription description = await peerConnection!.createOffer({'offerToReceiveVideo': 1});
      await peerConnection!.setLocalDescription(description);
      var sdp = parse(description.sdp as String);
      sessionId = Uuid().v4();
      sendMediaEvent('offer', {
        'from': selfId,
        'to': peerId,
        'media_type': mediaType,
        'description': json.encode(sdp),
        "session_id": sessionId
      }); 
    } catch (e) {
      print(StackTrace.fromString(e.toString()));
    }
  }
  Future<void> createAnswer() async {
    if (peerConnection == null) return;
    try {
      RTCSessionDescription description = await peerConnection!.createAnswer({'offerToReceiveVideo': 1});
      await peerConnection!.setLocalDescription(description);
      var sdp = parse(description.sdp as String);
      sendMediaEvent('answer', {
        'from': selfId,
        'to': peerId,
        'description': json.encode(sdp),
        'device_id': deviceId,
        'session_id': sessionId
      });
    } catch (e) {
      print(e.toString());
    }
  }
  Future<MediaStream?> createStream(String mediaType) async {
    listMediaDevices = await navigator.mediaDevices.enumerateDevices();
    final indexCameraDevice = listMediaDevices.lastIndexWhere((device) => device.kind == 'videoinput');
    final indexMicroDevice = listMediaDevices.lastIndexWhere((device) => device.kind == 'audioinput');

    if (indexCameraDevice == -1 && indexMicroDevice == -1) {
      return null;
    }

    MediaStream stream = await Helper.openCamera({
      'audio': true,
      'video': {
        "mandatory": {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30'
        },
        'optional': [
          {'sourceId': indexCameraDevice != -1 ? listMediaDevices[indexCameraDevice].deviceId : ""}
        ]
      },
    });
    
    onLocalStream.call(stream, listMediaDevices);
    return stream;
  }

  void terminateConnect () {
    sendMediaEvent('terminate', {
      'from': selfId,
      'to': peerId,
      "session_id": sessionId,
      'device_id': deviceId
    });
    releaseConnect();
  }

  Future<void> releaseConnect() async {
    await localStream?.dispose();
    await peerConnection?.close();
    peerConnection = null;
    localStream = null;
    remoteCandidates.clear();
    peerId = null;
  }

  Future<void> createVideoCall (peer, conversationId) async {
    if (peerConnection != null) return;
    final mediaType = "video";
    Future<void> ifReadyCallback() async {
      bool success = await createConnect(peerId: peer["user_id"] ?? peer["id"], mediaType: mediaType);
      if (!success) {
        onCallStateChange.call(CallState.CallStateError);
        return;
      }
      createOffer(mediaType);
      onCallStateChange.call(CallState.CallStateNew);
    }
    onSignalingStartCallback.call(CallState.CallStateRinging, "offer", peer, mediaType, conversationId, ifReadyCallback);
  }

  Future<void> createAudioCall (peer, conversationId) async {
    if (peerConnection != null) return;
    final mediaType = "audio";
    Future<void> ifReadyCallback() async {
      bool success = await createConnect(peerId: peer["user_id"] ?? peer["id"], mediaType: mediaType);
      if (!success) {
        onCallStateChange.call(CallState.CallStateError);
        return;
      }
      createOffer(mediaType);
      onCallStateChange.call(CallState.CallStateNew);
    }
    onSignalingStartCallback.call(CallState.CallStateRinging, "offer", peer, mediaType, conversationId, ifReadyCallback);
  }

  void handleControlEvent(event) {
    switch (event["type"]) {
      case "reached":
        onCallStateChange.call(CallState.CallStateReached);
        break;
      default:
    }
  }

  bool validateCorrectEvent(event) {
    final type = event["type"];
    final peer = event["from"];
    final peerId = peer == null ? null : peer is Map ? peer["id"] : peer;
    
    if (type == "offer") return true;
    else if (type == "answer") {
      if (this.peerConnection == null) return false;
    }
    else if (type == "terminate") {
      if (this.peerId == null || this.peerId != peerId) return false;
    }
    else if (type == "broadcast") {
      return this.peerId != null;
    }
    return this.peerId == null || this.peerId == peerId;
  }

  Future<void> switchDevice(deviceId, deviceType) async {
    switch (deviceType) {
      case 'videoinput':
        Helper.switchCamera(localStream!.getVideoTracks()[0], deviceId);
        break;
      case 'audioinput':
        break;
      default:
    }
  }

  Future<void> setEnableMic(value) async {
    if (localStream != null) {
      localStream!.getAudioTracks()[0].enabled = value;
    }
  }

  void setEnableVideo(value) {
    if (localStream != null && localStream!.getVideoTracks().length > 0) {
      localStream!.getVideoTracks()[0].enabled = value;
    }
  } 

  void sendMediaEvent(event, data) {
    Timer.run(() {
      channel.push(event: event, payload: data);
    });
  }
}
class P2PModel extends ChangeNotifier {
  dynamic _state;
  dynamic _type;
  dynamic _peer;
  dynamic _mediaType;
  dynamic _conversationId;
  late VoidCallback callback;

  get state => _state;
  get type => _type;
  get peer => _peer;
  get mediaType => _mediaType;
  get conversationId => _conversationId;

  set state(state) {
    this._state = state;
    notifyListeners();
  }

  set type(type) {
    this._type = type;
    notifyListeners();
  }

  set peer(peer) {
    this._peer = peer;
    notifyListeners();
  }
  
  void initStartCallback() {
    p2pManager.onSignalingStartCallback = (state, [type, peer, mediaType, conversationId, callback]) {
      this._state = state;
      if (type != null) this._type = type;
      if (peer != null) this._peer = peer;
      if (mediaType != null) this._mediaType = mediaType;
      if (conversationId != null) this._conversationId = conversationId;
      if (callback != null) this.callback = callback;
      notifyListeners();
    };
  }
  void onMediaEvent(message) {
    p2pManager.handleMediaEvent(message);
  }
}

final p2pManager = P2PManager.instance;