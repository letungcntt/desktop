import 'package:flutter_webrtc/flutter_webrtc.dart';

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

enum PIPViewCorner {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}
const defaultAnimationDuration = Duration(milliseconds: 200);

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