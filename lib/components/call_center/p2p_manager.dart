import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:phoenix_wings/phoenix_wings.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:uuid/uuid.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/call_center/call_view.dart';
import 'package:workcake/components/call_center/enums_consts.dart';

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
  late StreamStateCallback onLocalStream;
  late StreamStateCallback onAddRemoteStream;
  late StreamStateCallback onRemoveRemoteStream;
  late OtherEventCallback onPeersUpdate;

  RTCPeerConnection? _peerConnection;
  List<RTCIceCandidate> remoteCandidates = [];
  late PhoenixChannel channel;
  late String deviceId;
  late String selfId;
  String? peerId;
  String sessionId = "";
  Map<String, dynamic> _peerIdToPeer = {};
  Map<String, dynamic> _sessionWithMetadata = {};

  MediaStream? localStream;
  List<MediaDeviceInfo> listMediaDevices = [];
  OverlayEntry? screenOverlayEntry;
  
  bool isMuteMic = false;
  bool isOnVideo = false;

  Future<void> handleMediaEvent (event) async {
    bool correctEvent = _validateCorrectEvent(event);
    if (!correctEvent) return;
    
    switch (event['type']) {
      case "offer":
        if (sessionId != "") return;
        var peer = event["from"];
        this.sessionId = event["session_id"];
        this.peerId = peer["id"];
        final mediaType = event["mediaType"] ?? "video";
        
        _peerIdToPeer[peerId!] = peer;
        _sessionWithMetadata.addEntries([MapEntry(sessionId, new Map())]);
        _sessionWithMetadata[sessionId]["mediaType"] = mediaType;
        _sessionWithMetadata[sessionId]["type"] = "answer";
        
        Future<void> _ifReadyViewCallback () async {
          await _createConnect();
          var sdpSession = await jsonDecode(event["description"]);
          String sdp = write(sdpSession, null);
          RTCSessionDescription description = new RTCSessionDescription(sdp, "offer");
          await _peerConnection!.setRemoteDescription(description);
          await _createAnswer();
          if (remoteCandidates.length > 0) {
            remoteCandidates.forEach((candidate) async {
              try {
                await _peerConnection!.addCandidate(candidate);
              } catch (e) {}
            });
            remoteCandidates.clear();
          }
          onCallStateChange.call(CallState.CallStateConnected);
        }
        _addViewOverlay(Utils.globalContext, _ifReadyViewCallback);
        
        sendMediaEvent('control_event', {
          "from": selfId,"to": peerId,
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
        _peerConnection?.setRemoteDescription(description);
        onCallStateChange.call(CallState.CallStateConnected);
      break;
      case "candidate":
        RTCIceCandidate candidate = RTCIceCandidate(event["candidate"], event["sdpMid"], event["sdpMlineIndex"]);
        if (_peerConnection != null) {
          try {
            await _peerConnection!.addCandidate(candidate);
          } catch (e) {}
        } else {
          remoteCandidates.add(candidate);
        }
      break;
      case "broadcast":
        var otherDevice = event["device_id"];
        if (deviceId != otherDevice) {
          _removeViewOverlay();
          _releaseConnect();
        }
      break;
      case "control_event":
        handleControlEvent(event["event"]);
      break;
      case "terminate":
        _removeViewOverlay();
        _releaseConnect();
      break;
    }
  }

  Future<bool> _createConnect() async {
    assert(sessionId != "", "[_sessionId must be initialized]");
    assert(peerId != null, "[PeerId must be initialized]");
    assert(_sessionWithMetadata[sessionId]["mediaType"] != null, "[Media Type not special]");

    this.localStream = await _createStreamWithMediaType(_sessionWithMetadata[sessionId]["mediaType"]);

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
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        peerConnection.getLocalStreams().forEach((stream) {
          print(stream!.id);
          stream.getTracks().forEach((track) {
            print("track: ${track.id}, ${track.kind}, ${track.label}");
          });
        });
      }
    };
    this._peerConnection = peerConnection;
    return true;
  }
  Future<void> _createOffer() async {
    assert(sessionId != "", "[_sessionId must be initialized]");
    assert(_sessionWithMetadata[sessionId]["mediaType"] != null, "[Media Type not special]");

    try {
      RTCSessionDescription description = await _peerConnection!.createOffer({'offerToReceiveVideo': 1});
      await _peerConnection!.setLocalDescription(description);
      var sdp = parse(description.sdp as String);

      sendMediaEvent('offer', {
        'from': selfId,
        'to': peerId,
        'media_type': _sessionWithMetadata[sessionId]["mediaType"],
        'description': json.encode(sdp),
        "session_id": sessionId
      }); 
    } catch (e) {
      print(StackTrace.fromString(e.toString()));
    }
  }
  Future<void> _createAnswer() async {
    assert(this._peerConnection != null, "[peerConnection must be initialized]");
    try {
      RTCSessionDescription description = await _peerConnection!.createAnswer({'offerToReceiveVideo': 1});
      await _peerConnection!.setLocalDescription(description);
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
  Future<MediaStream?> _createStreamWithMediaType(String mediaType) async {
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

  void _addViewOverlay(context, callback) {
    assert(context != null, "[context is null]");
    assert(sessionId != "", "[_sessionId must be initialized]");
    assert(_sessionWithMetadata[sessionId]["mediaType"] != null, "[Media Type not special]");
    assert(_sessionWithMetadata[sessionId]["type"] != null, "[Type not special]");
    screenOverlayEntry = OverlayEntry(
      builder: (context) {
        return P2PCallView(
          user: _peerIdToPeer[peerId!], 
          type: _sessionWithMetadata[sessionId]["type"], 
          mediaType: _sessionWithMetadata[sessionId]["mediaType"],
          conversationId: _sessionWithMetadata[sessionId]["conversationId"],
          callback: callback
        );
      }
    );
    Overlay.of(context)!.insert(screenOverlayEntry!);
  }

  void _removeViewOverlay() {
    this.screenOverlayEntry?.remove();
  }

  void terminateConnect () {
    _removeViewOverlay();
    sendMediaEvent('terminate', {
      'from': selfId,
      'to': peerId,
      "session_id": sessionId,
      'device_id': deviceId
    });
    _releaseConnect();
  }

  Future<void> _releaseConnect() async {
    await localStream?.dispose();
    await _peerConnection?.close();
    _peerConnection = null;
    localStream = null;
    remoteCandidates.clear();
    peerId = null;
  }

  Future<void> createVideoCall (context, peer, conversationId) async {
    if (_peerConnection != null) return;
    
    final _peerId = peer["user_id"] ?? peer["id"];
    this.peerId = _peerId;
    sessionId = Uuid().v4();
    _sessionWithMetadata.addEntries([MapEntry(sessionId, new Map())]);
    _peerIdToPeer[_peerId] = peer;
    _sessionWithMetadata[sessionId]["mediaType"] = "video";
    _sessionWithMetadata[sessionId]["type"] = "offer";
    _sessionWithMetadata[sessionId]["conversationId"] = conversationId;

    Future<void> ifReadyCallback() async {
      bool success = await _createConnect();
      if (!success) {
        onCallStateChange.call(CallState.CallStateError);
        return;
      }
      _createOffer();
      onCallStateChange.call(CallState.CallStateNew);
    }
    _addViewOverlay(context, ifReadyCallback);
  }

  Future<void> createAudioCall (context, peer, conversationId) async {
    if (_peerConnection != null) return;
    
    final _peerId = peer["user_id"] ?? peer["id"];
    sessionId = Uuid().v4();
    _sessionWithMetadata.addEntries([MapEntry(sessionId, new Map())]);
    _peerIdToPeer[_peerId] = peer;
    _sessionWithMetadata[sessionId]["mediaType"] = "audio";
    _sessionWithMetadata[sessionId]["type"] = "offer";
    _sessionWithMetadata[sessionId]["conversationId"] = conversationId;
    Future<void> ifReadyCallback() async {
      bool success = await _createConnect();
      if (!success) {
        onCallStateChange.call(CallState.CallStateError);
        return;
      }
      _createOffer();
      onCallStateChange.call(CallState.CallStateNew);
    }
    _addViewOverlay(context, ifReadyCallback);
  }

  void handleControlEvent(event) {
    switch (event["type"]) {
      case "reached":
        onCallStateChange.call(CallState.CallStateReached);
        break;
      default:
    }
  }
  

  bool _validateCorrectEvent(event) {
    final type = event["type"];
    final peer = event["from"];
    final peerId = peer == null ? null : peer is Map ? peer["id"] : peer;
    
    if (type == "offer") return true;
    else if (type == "answer") {
      if (this._peerConnection == null) return false;
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
      localStream!.getVideoTracks()[0].stop();
    }
  } 

  void sendMediaEvent(event, data) {
    Timer.run(() {
      channel.push(event: event, payload: data);
    });
  }
}
final p2pManager = P2PManager.instance;