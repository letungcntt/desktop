import 'dart:async';
import 'dart:math';
// import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/common/window_manager.dart';
import 'package:workcake/models/models.dart';

class P2PCallView extends StatefulWidget {
  P2PCallView({required this.user, required this.type, required this.mediaType, required this.callback, this.collapse, this.screenStateCallback, this.conversationId});
  final user;
  final type;
  final mediaType;
  final conversationId;
  final callback;
  final collapse;
  final screenStateCallback;

  @override
  State<P2PCallView> createState() => _P2PCallViewState();
}

class _P2PCallViewState extends State<P2PCallView> {
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  List<MediaDeviceInfo> listCameraDevices = [];
  List<MediaDeviceInfo> listAudioDevices = [];
  late final user;
  bool callConnected = false;
  bool isMicEnable = true;
  bool isVideoEnable = true;
  bool isSpeakerEnable = true;
  bool collapse = false;
  var hover= false;
  double ratioLocalVideoRenderer = 1.0;
  double ratioRemoteVideoRenderer = 1.0;
  String timer = "0:00";
  // Player? player;
  Timer? _timerRinging;
  TimerCounter _timerCounter = new TimerCounter();
  
  
  
  @override
  void initState() {
    super.initState();
    _localRenderer.initialize();
    _remoteRenderer.initialize();
    user = widget.user;
    collapse = widget.collapse;
    // player = Player(id: 0);
    ringing();

    p2pManager.onCallStateChange = ((state) async {
      if (state == CallState.CallStateReached) {
        // player?.stop();
        // player?.open(Media.asset('assets/musics/outcoming_sound.mp3'));
        // player?.play();
      }
      else if (state == CallState.CallStateConnected) {
        setState(() => callConnected = true);
        _timerCounter.startTimeout().onChange = (second) {
          if (this.mounted) setState(() {
            timer = second;
          });
        };
        _timerRinging?.cancel();
        // player?.stop();
      } else if (state == CallState.CallStateBye) {
        if (widget.type == "offer") await createEndMessage();
        setState(() => callConnected = false);
      }
    });

    p2pManager.onLocalStream = ((stream, listMediaDevices) {
      listCameraDevices = listMediaDevices.where((device) => device.kind == 'videoinput').toList();
      listAudioDevices = listMediaDevices.where((device) => device.kind == 'audioinput').toList();
      
      _localRenderer.onResize = () {
        // setState(() => ratioLocalVideoRenderer = _localRenderer.value.aspectRatio);
      };
      setState(() => _localRenderer.srcObject = stream);
    });

    p2pManager.onAddRemoteStream = ((stream, __) {
      _remoteRenderer.onResize = () {
        // setState(() => ratioRemoteVideoRenderer = _remoteRenderer.value.aspectRatio);
      };
      setState(() => _remoteRenderer.srcObject = stream);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.type == "offer") widget.callback();
    });
  }

  void ringing() {
    _timerRinging = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timer.tick >= 30) {
        timer.cancel();
        p2pManager.terminateConnect();
        p2pManager.onCallStateChange.call(CallState.CallStateBye).then((value) => p2pManager.onSignalingStartCallback(CallState.CallStateBye));
        callConnected = false;
      }
    });

    // if (widget.type == "answer") {
    //   player?.open(Media.asset('assets/musics/incoming_sound.mp3'));
    //   player?.play();
    //   player?.playbackStream.listen((playback) {
    //     if (playback.isCompleted) player?.play();
    //   });
    //   windowManager.wakeUp();
    // } else if (widget.type == "offer") {
    //   player?.open(Media.asset('assets/musics/waiting_sound.wav'));
    //   player?.play();
    //   player?.playbackStream.listen((playback) {
    //     if (playback.isCompleted) player?.play();
    //   });
    // }
  }

  Future<void> createEndMessage() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    var dataMessage = {
      "message": widget.mediaType == "video" ? "Cuộc gọi video đã kết thúc" : "Cuộc gọi audio đã kết thúc",
      "attachments": [{"type": "call_terminated", "data": {"timerCounter": timer, "mediaType": widget.mediaType}}], 
      "title": "",
      "conversation_id": widget.conversationId,
      "show": true,
      "id": "",
      "user_id": Provider.of<Auth>(context, listen: false).userId,
      "avatar_url": user["avatar_ur"],
      "full_name": user["full_name"],
      "time_create": DateTime.now().add(new Duration(hours: -7)).toIso8601String(),
      "count": 0,
      "sending": true,
      "success": true,
      "fake_id": Utils.getRandomString(20),
      "current_time": DateTime.now().millisecondsSinceEpoch * 1000,
      "isSend": true,
      "isDesktop": true
    };
    Provider.of<DirectMessage>(context, listen: false).handleSendDirectMessage(dataMessage, token);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    p2pManager.releaseConnect();
    // player?.stop();
    // player?.dispose();
    // player = null;
    _timerRinging?.cancel();
    _timerRinging = null;
    _timerCounter.destroy();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant P2PCallView oldWidget) {
    super.didUpdateWidget(oldWidget);
    collapse = widget.collapse;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    return Scaffold(
      body: collapse ? collapseView(widget.mediaType) : Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 100.0, vertical: 20.0),
        color: isDark ? Color(0xff3D3D3D) : Color(0xffE5E5E5),
        child: !callConnected ? widget.type == "offer" ? outComingCall(widget.mediaType) : inComingCall(widget.mediaType) : callingView(widget.mediaType)
      ),
    );
  }
  Widget outComingCall(String mediaType) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 10),
        Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    collapse = !collapse;
                    widget.screenStateCallback(collapse);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xff5E5E5E) : Color(0xffFFFFFF),
                      borderRadius: BorderRadius.circular(19)
                    ),
                    width: 38,
                    height: 38,
                    child: Icon(PhosphorIcons.arrowLeft, size: 20, color: isDark ? Color(0xffEDEDED) : Color(0xff5E5E5E),),
                  ),
                ),
                Column(
                  children: [
                    if (mediaType == "video") optionCameraDevices(),
                    optionAudioDevice()
                  ],
                )
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(5),
                    child: Text(user["full_name"], style: TextStyle(fontSize: 18, color: isDark ? Color(0xffDBDBDB) : Color(0xff3D3D3D))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text("Calling...", style: TextStyle(fontSize: 14, color: Color(0xff40A9FF))),
                  ),
                ],
              ),
            )
          ],
        ),
        
        Expanded(
          child: isVideoEnable && mediaType == "video" ? Container(
            decoration: BoxDecoration(border: Border.all(width: 1)),
            child: RTCVideoView(_localRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover, mirror: true)
          ) : Stack(
            children: [
              Center(
                child: Container(
                  width: 250 * 2.5,
                  height: 250 * 2.5,
                  child: Lottie.network("https://assets8.lottiefiles.com/temp/lf20_PeIV5A.json"),
                ),
              ),
              Center(
                child: Container(
                  child: CachedAvatar(
                    user["avatar_url"], 
                    name: user["full_name"], 
                    width: 200, height: 200,
                  ),
                ),
              ),
            ],
          )
        ),
        actionButton()
      ],
    );
  }
  Widget inComingCall(String mediaType) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Expanded(
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Center(
                            child: Container(
                              width: 300,
                              height: 300,
                              child: Lottie.network("https://assets8.lottiefiles.com/temp/lf20_PeIV5A.json"),
                            ),
                          ),
                          Positioned(
                            left: 0, top: 0, bottom: 0, right: 0,
                            child: Center(
                              child: CachedAvatar(
                                user["avatar_url"], 
                                name: user["full_name"], 
                                width:100, height:100
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.all(5),
                        child: Text(user["full_name"], style: TextStyle(fontSize: 18, color: isDark ? Color(0xffDBDBDB) : Color(0xff3D3D3D))),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text("is calling you...", style: TextStyle(fontSize: 14, color: Color(0xff40A9FF))),
                      ),
                    ],
                  ),
                ),
                actionButton()
              ]
            ),
          ),
        )
      ],
    );
  }
  Widget callingView(String mediaType) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                collapse = !collapse;
                widget.screenStateCallback(collapse);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Color(0xff5E5E5E) : Color(0xffFFFFFF),
                  borderRadius: BorderRadius.circular(19)
                ),
                width: 38,
                height: 38,
                child: Icon(PhosphorIcons.arrowLeft, size: 20, color: isDark ? Color(0xffEDEDED) : Color(0xff5E5E5E),),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(5),
                  child: Text(user["full_name"], style: TextStyle(fontSize: 18, color: isDark ? Color(0xffDBDBDB) : Color(0xff3D3D3D))),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(timer.toString())
                ),
              ],
            ),
            InkWell(
              onTap: () {
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Color(0xff5E5E5E) : Color(0xffFFFFFF),
                  borderRadius: BorderRadius.circular(19)
                ),
                width: 38,
                height: 38,
                child: SvgPicture.asset('assets/icons/settings.svg')
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        mediaType == "video" ? Expanded(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth,
                    height: constraints.maxWidth / ratioRemoteVideoRenderer,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: RTCVideoView(_remoteRenderer),
                  );
                }
              ),
              if (!collapse) Positioned(
                right: 20,
                top: 20,
                child: isVideoEnable ?  Container(
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.white, width: 2.0)
                  ),
                  width: 140 * ratioLocalVideoRenderer,
                  height: 140,
                  child: RTCVideoView(_localRenderer, mirror: true,objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,),
                ) : Container(),
              ),
            ],
          ),
        ) : Expanded(
          child: Center(
            child: CachedAvatar(
              user["avatar_url"], 
              name: user["full_name"], 
              width: 250, height: 250
            ),
          ),
        ),
        actionButton()
      ],
    );
  }

  Widget collapseView(String mediaType) {
    return StatefulBuilder(
      builder: (context, _setState) {
        return MouseRegion(
          onEnter: (event) => _setState(() => hover = true),
          onExit:(event) => _setState(() => hover = false),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: mediaType == "video" ?
                 callConnected ? 
                  RTCVideoView(_remoteRenderer) :
                  widget.type == "offer" && isVideoEnable ?
                  RTCVideoView(_localRenderer, mirror: true) :
                  Stack(
                    children: [
                      Center(
                        child: Container(
                          child: Lottie.network("https://assets8.lottiefiles.com/temp/lf20_PeIV5A.json"),
                        ),
                      ),
                      Center(
                        child: Container(
                          child: CachedAvatar(
                            user["avatar_url"], 
                            name: user["full_name"], 
                            width: 130, height: 130,
                          ),
                        ),
                      ),
                    ],
                  )
                  : mediaType == "audio" ? 
                  callConnected ?  Center(
                    child: Container(
                      child: CachedAvatar(
                        user["avatar_url"], 
                        name: user["full_name"], 
                        width: 130, height: 130,
                      ),
                    ),
                  ) : Stack(
                    children: [
                      Center(
                        child: Container(
                          child: Lottie.network("https://assets8.lottiefiles.com/temp/lf20_PeIV5A.json"),
                        ),
                      ),
                      Center(
                        child: Container(
                          child: CachedAvatar(
                            user["avatar_url"], 
                            name: user["full_name"], 
                            width: 130, height: 130,
                          ),
                        ),
                      ),
                    ],
                  )
                  : Container()
              ),
              hover ? Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  padding: EdgeInsets.only(bottom: 10.0),
                  child: Center(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          p2pManager.terminateConnect();
                          p2pManager.onCallStateChange.call(CallState.CallStateBye).then((_) => p2pManager.onSignalingStartCallback(CallState.CallStateBye));
                          callConnected = false;
                        });
                      } ,
                      child: Container(child: Center(child: Icon(PhosphorIcons.phoneDisconnectThin, color: Colors.white)), width: 55, height: 55, decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Color(0xffEB5757))),
                    )
                  ),
                )
              ) : Container()
            ],
          ),
        );
      }
    );
  }

  Widget optionCameraDevices() {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final OutlineInputBorder borderStyle = OutlineInputBorder(borderRadius: BorderRadius.circular(2.0), borderSide: BorderSide(color: Color(0xff3D3D3D), style: BorderStyle.solid, width: 1.0));
    return Container(
      width: MediaQuery.of(context).size.width / 4.2,
      constraints: BoxConstraints(maxWidth: 300, minWidth: 250),
      margin: EdgeInsets.only(bottom: 10.0),
      child: DropdownButtonFormField(
        style: TextStyle(color: isDark ? Color(0xffF5F7FA) : Color(0xff243B53), fontSize: 14, fontWeight: FontWeight.w400),
        dropdownColor: isDark ? Color(0xff1F2933) : Color(0xffF5F7FA),
        icon: Icon(Icons.expand_more, size: 20, color: isDark ? Color(0xffF5F7FA) : Color(0xff243B53)),
        decoration: InputDecoration(
          isCollapsed: true,
          filled: true,
          fillColor: isDark ? Color(0xff2E2E2E) : Colors.transparent,
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          enabledBorder: isDark ? InputBorder.none : borderStyle,
        ),
        items: [
          ...listCameraDevices.map((cameraDevice){
            return DropdownMenuItem(
              child: Text(cameraDevice.label, overflow: TextOverflow.ellipsis),
              value: cameraDevice.deviceId,
            );
          })
        ], 
        value: listCameraDevices.length > 0 ? listCameraDevices.last.deviceId : "",
        onChanged: onChangeCameraDevice
      ),
    );
  }
  Widget optionAudioDevice() {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final OutlineInputBorder borderStyle = OutlineInputBorder(borderRadius: BorderRadius.circular(2.0), borderSide: BorderSide(color: Color(0xff3D3D3D), style: BorderStyle.solid, width: 1.0));
    return Container(
      width: MediaQuery.of(context).size.width / 4.2,
      constraints: BoxConstraints(maxWidth: 300, minWidth: 250),
      margin: EdgeInsets.only(bottom: 10.0),
      child: DropdownButtonFormField(
        style: TextStyle(color: isDark ? Color(0xffF5F7FA) : Color(0xff243B53), fontSize: 14, fontWeight: FontWeight.w400),
        dropdownColor: isDark ? Color(0xff1F2933) : Color(0xffF5F7FA),
        icon: Icon(Icons.expand_more, size: 20, color: isDark ? Color(0xffF5F7FA) : Color(0xff243B53)),
        decoration: InputDecoration(
          isCollapsed: true,
          filled: true,
          fillColor: isDark ? Color(0xff2E2E2E) : Colors.transparent,
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          enabledBorder: isDark ? InputBorder.none : borderStyle,
        ),
        items: [
          ...listAudioDevices.map((cameraDevice){
            return DropdownMenuItem(
              child: Text(cameraDevice.label),
              value: cameraDevice.deviceId,
            );
          })
        ], 
        value: listAudioDevices.length > 0 ? listAudioDevices.last.deviceId : "",
        onChanged: onChangeAudioDevice
      ),
    );
  }
  Widget actionButton() {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return Container(
      width: 300,
      margin: EdgeInsets.only(top: 20),
      height: 70,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (widget.mediaType == "video" && (callConnected || widget.type == "offer")) InkWell(
              onTap: () {
                setState(() {
                  isVideoEnable = !isVideoEnable;
                  p2pManager.setEnableVideo(isVideoEnable);
                });
              } ,
              child: Container(child: Center(child: Icon( isVideoEnable ? PhosphorIcons.videoCameraThin : PhosphorIcons.videoCameraSlashThin, size: 30, color: !isVideoEnable && !isDark ? Color(0xff3D3D3D) : Colors.white)), width: 50, height: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: isVideoEnable ? Color(0xff1890FF) : isDark ? Color(0xff2E2E2E) : Color(0xffC9C9C9))),
            ),
            if (callConnected || widget.type == "offer") InkWell(
              onTap: () {},
              child: Container(child: Center(child: Icon(PhosphorIcons.chatsCircleFill, color: isDark ? Color(0xffEDEDED) : Color(0xffFFFFFF),)), width: 50, height: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: isDark ? Color(0xff2E2E2E) : Color(0xffC9C9C9))),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  p2pManager.terminateConnect();
                  p2pManager.onCallStateChange.call(CallState.CallStateBye).then((value) => p2pManager.onSignalingStartCallback(CallState.CallStateBye));
                  
                  callConnected = false;
                  // player?.stop();
                });
              } ,
              child: Container(child: Center(child: Icon(PhosphorIcons.phoneDisconnectThin, color: Colors.white)), width: 55, height: 55, decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Color(0xffEB5757))),
            ),
            if (callConnected || widget.type == "offer") InkWell(
              onTap: () {
                setState(() {
                  isMicEnable = !isMicEnable;
                  p2pManager.setEnableMic(isMicEnable);
                });
              } ,
              child: Container(child: Center(child: Icon( isMicEnable ? PhosphorIcons.microphoneThin : PhosphorIcons.microphoneSlashThin, size: 30, color: !isMicEnable && !isDark ? Color(0xff3D3D3D) : Colors.white)), width: 50, height: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: isMicEnable ? Color(0xff1890FF) : isDark ? Color(0xff2E2E2E) : Color(0xffC9C9C9))),
            ),
            if(widget.type == "answer" && !callConnected) InkWell(
            onTap: () {
              setState(() {
                widget.callback();
              });
            } ,
            child: Container(child: Center(child: Icon(PhosphorIcons.phoneCallFill, color: Colors.white)), width: 55, height: 55, decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Color(0xff27AE60))),
          ),
            if (callConnected || widget.type == "offer") InkWell(
              onTap: () {} ,
              child: Container(child: Center(child: Icon( isSpeakerEnable ? PhosphorIcons.speakerHighFill : PhosphorIcons.speakerSlashFill, size: 30, color: Colors.white)), width: 50, height: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), color: isDark ? Color(0xff2E2E2E) : Color(0xffC9C9C9))),
            ),
          ],
        ),
      ),
    );
  }
  void onChangeCameraDevice(deviceId) {
    p2pManager.switchDevice(deviceId, 'videoinput');
  }
  void onChangeAudioDevice(deviceId) {
    p2pManager.switchDevice(deviceId, 'audioinput');
  }
}

class CallLayout extends StatefulWidget {
  CallLayout({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CallLayoutState();
  }
}

class _CallLayoutState extends State<CallLayout> { 
  bool _collapse = false;
  bool _dragging = false;
  Offset? wrapperOffset;
  Offset offset = Offset(50, 50);
  Size boxSizeCollapse = Size(400, 300);
  Rect? boxRectCollapse;
  double marginCorner = 20;

  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final type = Provider.of<P2PModel>(context, listen: true).type;
    final mediaType = Provider.of<P2PModel>(context, listen: true).mediaType;
    final peer = Provider.of<P2PModel>(context, listen: true).peer;
    final conversationId = Provider.of<P2PModel>(context, listen: true).conversationId;
    final callback = Provider.of<P2PModel>(context, listen: false).callback;
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        AnimatedPositioned(
          duration: Duration(milliseconds: _dragging ? 0 : 400),
          curve: Curves.easeInOutCubicEmphasized,
          top: _collapse ? offset.dy : 0,
          right: _collapse ? offset.dx : 0,
          width: _collapse ? boxSizeCollapse.width : size.width,
          height: _collapse ? boxSizeCollapse.height : size.height,
          child: GestureDetector(
            onDoubleTap: () {
              if (_collapse) setState(() {
                _collapse = false;
              });
            },
            onPanStart: startDrag,
            onPanUpdate: updateDrag,
            onPanEnd: endDrag,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black, blurRadius: 5.0, offset: Offset(-2, 2)),
                  // BoxShadow(color: Colors.black, blurRadius: 5.0, blurStyle: BlurStyle.solid, offset: Offset(-2, 2))
                ]
              ),
              child: P2PCallView(user: peer, type: type, mediaType: mediaType, conversationId: conversationId, callback: callback, screenStateCallback: screenStateCallback, collapse: _collapse)
            ),
          )
        )
      ],
    );
  }
  startDrag(DragStartDetails details) {
    wrapperOffset = details.localPosition;
    final appSize = MediaQuery.of(context).size;
    final leftSide = details.globalPosition.dx - wrapperOffset!.dx;
    final bottomSide = appSize.height  - (details.globalPosition.dy + boxSizeCollapse.height - wrapperOffset!.dy);
    final topSide = details.globalPosition.dy - wrapperOffset!.dy;
    final rightSide = appSize.width - (details.globalPosition.dx + 400 - wrapperOffset!.dx);
    boxRectCollapse = Rect.fromLTRB(leftSide, topSide, rightSide, bottomSide);
    _dragging = true;
  }
  updateDrag(DragUpdateDetails details) {
    if (!_collapse) return;
    setState(() {
      final appSize = MediaQuery.of(context).size;
      var leftSide = details.globalPosition.dx - wrapperOffset!.dx;
      var bottomSide = appSize.height  - (details.globalPosition.dy + boxSizeCollapse.height - wrapperOffset!.dy);
      leftSide = max(leftSide, 0);
      bottomSide = max(bottomSide, 0);


      var topSide = appSize.height - bottomSide - boxSizeCollapse.height;
      var rightSide = appSize.width - leftSide - boxSizeCollapse.width;
      topSide = max(topSide, 0);
      rightSide = max(rightSide, 0);

      boxRectCollapse = Rect.fromLTRB(leftSide, topSide, rightSide, bottomSide);
      offset = Offset(rightSide, topSide);
    });
  }
  endDrag(DragEndDetails details) {
    final appSize = MediaQuery.of(context).size;
    Offset centerAppOffset = Offset(appSize.width / 2, appSize.height / 2);
    Offset centerBoxOffset = Offset(boxRectCollapse!.left + boxSizeCollapse.width / 2, boxRectCollapse!.top + boxSizeCollapse.height / 2);
    
    var newTop = 0.0;
    var newRight = 0.0;
    if (centerBoxOffset.dx < centerAppOffset.dx && centerBoxOffset.dy < centerAppOffset.dy) {
      newTop = marginCorner;
      newRight = appSize.width - boxSizeCollapse.width - marginCorner;
    } else if (centerBoxOffset.dx > centerAppOffset.dx && centerBoxOffset.dy < centerAppOffset.dy) {
      newTop = marginCorner;
      newRight = marginCorner;
    } else if (centerBoxOffset.dx > centerAppOffset.dx && centerBoxOffset.dy > centerAppOffset.dy) {
      newTop = appSize.height - boxSizeCollapse.height - marginCorner;
      newRight = marginCorner;
    } else if (centerBoxOffset.dx < centerAppOffset.dx && centerBoxOffset.dy > centerAppOffset.dy) {
      newTop = appSize.height - boxSizeCollapse.height - marginCorner;
      newRight = appSize.width - boxSizeCollapse.width - marginCorner;
    }
    _dragging = false;
    setState(() {
      offset = Offset(newRight, newTop);
    });
  }
  void screenStateCallback(collapse) {
    setState(() {
      this._collapse = collapse;
    });
  }
}
class TimerCounter{
  final interval = const Duration(seconds: 1);
  int currentSeconds = 0;
  Timer? _timer;
  Function? onChange;

  String get timerText =>
      '${(currentSeconds ~/ 60).toString().padLeft(2, '0')}: ${(currentSeconds % 60).toString().padLeft(2, '0')}';
  TimerCounter startTimeout([milliseconds]) {
    var duration = interval;
    _timer = Timer.periodic(duration, (timer) {
      currentSeconds = timer.tick;
      onChange?.call(timerText);
    });
    return this;
  }
  void destroy() {
    _timer?.cancel();
  }
}