import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:phoenix_wings/phoenix_wings.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/utils.dart';

import 'panchat_webrtc.dart';

const RTC_CONFIGURATION = {
  "iceServers": [
    {
      'url': "turn:113.20.119.31:3478",
      'username': "panchat",
      'credential': "panchat"
    },
    {
      "urls": "stun:stun.l.google.com:19302",
    },
  ],
  "sdpSemantics": "unified-plan"
};

const OFFER_SDP_CONSTRAINTS = {
  "mandatory": {
    "OfferToReceiveAudio": true,
    "OfferToReceiveVideo": true,
  },
  "optional": [],
};

class Room {
  late PhoenixSocket socket;
  late PhoenixChannel webRTCChannel;
  late PanchatWebRTC webRTC;

  List<Peer> peers = [];
  String displayName;
  String room;
  MediaStream? localStream;
  Function? onAddVideoElement;
  Function? onRemoveVideoElement;
  Function? onAttackStream;
  Room(this.room, this.displayName) {
    this.socket = PhoenixSocket(socketRTCUrl);

    this.webRTC = new PanchatWebRTC(
      RTCConfiguration(RTC_CONFIGURATION, OFFER_SDP_CONSTRAINTS),
      Callbacks(
        onSendMediaEvent: (mediaEvent) {
          this.webRTCChannel.push(
            event: "mediaEvent",
            payload: {"data": mediaEvent}
          );
        },
        onJoinSuccess: (peerId, peersInRoom) {
          this.localStream!.getTracks().forEach((track) {
            this.webRTC.addTrack(track, this.localStream!);
          });
          
          this.peers = peersInRoom.map((peerData) => Peer(id: peerData["id"], trackIdToMetadata: peerData["trackIdToMetadata"], metadata: peerData["metadata"])).toList();
          this.peers.forEach((peer) {
            this.onAddVideoElement?.call(peer.id, peer.metadata["displayName"], false);
          });
        },
        onTrackReady: (trackContext){
          this.onAttackStream?.call(trackContext.peer.id, trackContext.stream);
        },
        onPeerJoined: (peer) {
          this.peers.add(peer);
          this.onAddVideoElement?.call(peer.id, peer.metadata["displayName"], false);
        },
        onPeerLeft: (peer) {
          this.peers.removeWhere((localPeer) => localPeer.id == peer.id);
          this.onRemoveVideoElement?.call(peer.id);
        }
      )
    );
  }

  void setDisplayname(String name) {
    this.displayName = name;
  }

  Future<void> connect() async {
    await this.socket.connect();
    this.webRTCChannel = this.socket.channel(this.room);
  }

  Future<void> join () async {
    try {
      this.localStream = await Helper.openCamera({
        'audio': true,
        'video': {
          'mandatory': {
            'minWidth': '1280',
            'minHeight': '720',
            'minFrameRate': '60',
          },
          'optional': []
        },
      });

      await this.onAddVideoElement?.call("LOCAL_PEER_ID", "Me", true);
      this.onAttackStream?.call("LOCAL_PEER_ID", this.localStream);

      this.webRTCChannel.join()?.receive("ok", (response) async => {
        this.webRTC.join({"displayName": this.displayName}),
        print("Join channel completed")
      }).receive("error", (response){
        print("Unable to join $response");
      });
      this.webRTCChannel.on("mediaEvent", (payload, ref, joinRef) {
        this.webRTC.receiveMediaEvent(payload!["data"]);
      });
    } catch (e) {
      print("error ${e.toString()}");
    }
  }
  void leave() {
    this.webRTC.leave();
    this.localStream?.dispose();
    this.webRTCChannel.leave();
    this.socket.disconnect();
  }
}

class RoomUI extends StatefulWidget {
  final roomId;
  final roomName;
  final displayName;
  final terminate;
  const RoomUI({ Key? key, this.roomId, this.roomName, this.displayName, this.terminate }) : super(key: key);

  @override
  State<RoomUI> createState() => _RoomUIState();
}

class _RoomUIState extends State<RoomUI> {
  List peersElement = [];
  Room? room;
  double top = 0;
  double left = 0;
  double right = 0;
  double bottom = 0;
  bool fullScreen = true;

  @override
  void initState() {
    super.initState();
    room = new Room("room:${widget.roomId}", widget.displayName);
    room!.setDisplayname(widget.displayName);
    room!.onAddVideoElement = (id, metadata, localPeer) async {
      RTCVideoRenderer newPeerRender = new RTCVideoRenderer();

      await newPeerRender.initialize();
      final newPeer = {"id": id, "metadata": metadata, "renderer": newPeerRender};
      setState(() => peersElement.add(newPeer));
    };
    room!.onAttackStream = (id, stream) {
      final indexPeerElement = peersElement.indexWhere((element) => element["id"] == id);
      if (indexPeerElement != -1) {
        setState(() {
          (peersElement[indexPeerElement]["renderer"] as RTCVideoRenderer).srcObject = stream;
        });
      }
    };
    room!.onRemoveVideoElement = (id) {
      final indexPeerElement = peersElement.indexWhere((element) => element["id"] == id);
      if (indexPeerElement != -1) {
        try {
          var _tempElement = peersElement[indexPeerElement]["renderer"];
          this.setState(() {
            peersElement[indexPeerElement]["renderer"] = null;
            peersElement = peersElement.where((element) => element["renderer"] != null).toList();
          });
          Future.delayed(const Duration(milliseconds: 200), () {
            _tempElement.srcObject = null;
            _tempElement.dispose();
          });
        } catch (e, trace) {
          print("$e\n$trace");
        }
      }
      
    };

    room!.connect().then((_) => room!.join());
  }

  void toggleView() {
    fullScreen = !fullScreen;
    if (fullScreen) {
      setState(() {
        top = 0;
        left = 0;
        bottom = 0;
        right = 0;
      });
    } else {
      setState(() {
        top = 20;
        left = MediaQuery.of(context).size.width - 500 - 20;
        bottom = MediaQuery.of(context).size.height - 300 - 20;
        right = 20;
      });
    }
  }

  @override
  void dispose() {
    peersElement.forEach((element) {element["renderer"].dispose();});
    peersElement.clear();
    room = null;
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Scaffold(
        body: GestureDetector(
          onDoubleTap: toggleView,
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: fullScreen ? 100.0 : 0, vertical: fullScreen ? 20.0 : 0),
            decoration: BoxDecoration(
              color: const Color(0xff3D3D3D),
              border: fullScreen ? null : Border.all(width: 2, color: Colors.blueAccent),
              borderRadius: fullScreen ? null : BorderRadius.circular(10)
            ),
            child: Column(
              children: [
                SizedBox(height: fullScreen ? 70 : 0),
                if (fullScreen) Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        toggleView();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color:  Color(0xff5E5E5E),
                          borderRadius: BorderRadius.circular(19)
                        ),
                        width: 38,
                        height: 38,
                        child: Icon(PhosphorIcons.arrowLeft, size: 20, color:  Color(0xffEDEDED)),
                      ),
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(5),
                          child: Text(widget.roomName, style: TextStyle(fontSize: 18, color: Color(0xffDBDBDB))),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                      },
                      child: Container(
                        // decoration: BoxDecoration(
                        //   color: Color(0xff5E5E5E),
                        //   borderRadius: BorderRadius.circular(19)
                        // ),
                        width: 38,
                        height: 38,
                        // child: SvgPicture.asset('assets/icons/settings.svg')
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraint) {
                      final int baseLine = fullScreen ? (peersElement.length + 1) ~/ 2 : 1;
                      final int baseColumn = fullScreen ? peersElement.length >= 2 ? 2 : 1 : 1;
                      return Wrap(
                        children: [
                          ...peersElement.map((peer) {
                            final isLastExtend = peersElement.last == peer && peersElement.length.isOdd;
                            final maxWidth = isLastExtend ? constraint.maxWidth : (constraint.maxWidth - (baseColumn - 1) * 20) / baseColumn;
                            final maxHeight = (constraint.maxHeight - (baseLine - 1) * 20) / baseLine;
                            if (!fullScreen && peer["id"] != "LOCAL_PEER_ID") return Container();
                            return Container(
                              color: Colors.black,
                              width: maxWidth,
                              height: maxHeight,
                              child: Stack(
                                children: [
                                  RTCVideoView(
                                    peer["renderer"],
                                    mirror: peer["id"] == "LOCAL_PEER_ID" ? true : false,
                                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                                  ),
                                  Positioned(
                                    right: 30.0,
                                    bottom: 10.0,
                                    child: Text(peer["metadata"], style: const TextStyle(color: Colors.white),)
                                  )
                                ],
                              ),
                            );
                          }),
                        ],
                        spacing: 20.0,
                        runSpacing: 20.0,
                      );
                    }
                  ),
                ),
                InkWell(
                  onTap: () {
                    room!.leave();
                    widget.terminate?.call();
                  } ,
                  child: Container(child: const Center(child: Icon(PhosphorIcons.phoneDisconnectThin, color: Colors.white)), width: 55, height: 55, decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: const Color(0xffEB5757))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RoomsModel extends ChangeNotifier {
  List<Map> _rooms = [];
  bool _directHasRoomActive = false;
  List<PhoenixChannel?> _roomsChannel= [];
  PhoenixSocket? _roomSocket;

  List get rooms => _rooms;
  bool get directHasRoomActive => _directHasRoomActive;
  set rooms (room) {
    _rooms = room;
    notifyListeners();
  }

  set directHasRoomActive(value) {
    _directHasRoomActive = value;
    notifyListeners();
  }

  void getRoomIds(token) async {
    final url = Utils.apiUrl + 'direct_messages/list_group_ids?token=$token';
    try {
      final response = await Dio().get(url);
      final resData = response.data;
      if (resData["success"]) {
        loadRoomJoined(resData["data"]);
      }
    } catch (e,trace) {
      print("$e\n$trace");
    }
  }

  void loadRoomJoined(List conversationIds) {
    List __roomIds = conversationIds;
    this._rooms.addAll(__roomIds.map((roomId) {
      return {"id": roomId, "isActive": false};
    }));
    this.connectRoomSocket();
  }
  void connectRoomSocket() async {
    _roomSocket = new PhoenixSocket(socketRTCUrl);
    await _roomSocket?.connect();
    this._roomsChannel.addAll(this._rooms.map((room) {
      return _roomSocket?.channel("room_notify:${room["id"]}");
    }));
    for (var roomChannel in this._roomsChannel) {
      assert (roomChannel != null);
      roomChannel?.join()?.receive("ok", (response) async => {
        // print("Room join socket channel")
      });
      roomChannel?.on("room_active", (payload, ref, joinRef) {
        final peerLength = payload!["peer_length"];
        final roomId = payload["room_id"];
        notifyRoomActiveOrNot(roomId, peerLength > 0);
      });
    }
  }
  notifyRoomActiveOrNot(roomId, isActive) {
    List<Map> __rooms = _rooms;
    final indexRoom = _rooms.indexWhere((room) => room["id"] == roomId);
    if (indexRoom != -1) {
      __rooms[indexRoom]["isActive"] = isActive;
      _rooms = __rooms;
      directHasRoomActive = __rooms.any((room) => room["isActive"] == true);
      notifyListeners();
    }
  }
}

class RoomActiveButton extends StatefulWidget {
  const RoomActiveButton({ Key? key }) : super(key: key);

  @override
  State<RoomActiveButton> createState() => _RoomActiveButtonState();
}

class _RoomActiveButtonState extends State<RoomActiveButton> with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  )..repeat(reverse: true);
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      child: FadeTransition(
        opacity: _animation,
        child: const Padding(padding: EdgeInsets.all(8), child: Icon(PhosphorIcons.phoneLight, color: Colors.white)),
      ),
    );
  }
}