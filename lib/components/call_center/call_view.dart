import 'dart:async';
// import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/common/window_manager.dart';
import 'package:workcake/components/call_center/enums_consts.dart';
import 'package:workcake/components/call_center/p2p_manager.dart';
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

class _P2PCallViewState extends State<P2PCallView> with TickerProviderStateMixin {
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  List<MediaDeviceInfo> listCameraDevices = [];
  List<MediaDeviceInfo> listAudioDevices = [];
  late final user;
  bool callConnected = false;
  bool isMicEnable = true;
  bool isVideoEnable = true;
  bool isSpeakerEnable = true;
  var hover= false;
  double ratioLocalVideoRenderer = 1.0;
  double ratioRemoteVideoRenderer = 1.0;
  String timer = "0:00";
  // Player? player;
  Timer? _timerRinging;
  TimerCounter _timerCounter = new TimerCounter();

  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;
  Map<PIPViewCorner, Offset> _offsets = {};
  late PIPViewCorner _corner;
  bool isFloating = false;
  late final AnimationController _toggleFloatingAnimationController;
  late final AnimationController _dragAnimationController;
  
  
  
  @override
  void initState() {
    super.initState();
    () async {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      if (widget.type == "offer") {
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.callback());
      }
    }.call();
    
    user = widget.user;
    // player = Player(id: 10);
    _ringing();
    _initP2PCallListener();

    _corner = PIPViewCorner.topRight;
    _toggleFloatingAnimationController = AnimationController(
      duration: defaultAnimationDuration,
      vsync: this,
    );
    _dragAnimationController = AnimationController(
      duration: defaultAnimationDuration,
      vsync: this,
    );
  }


  //<------------P2PCallmanager start in here------------->
  void _initP2PCallListener() {
    p2pManager.onCallStateChange = ((state) async {
      if (state == CallState.CallStateReached)
        _ringWithReached();
      else if (state == CallState.CallStateConnected) {
        setState(() => callConnected = true);
        _stopRingAndStartCounter();
      } else if (state == CallState.CallStateBye) {
        if (widget.type == "offer") await createEndMessage();
        setState(() => callConnected = false);
      }
    });

    p2pManager.onLocalStream = ((stream, listMediaDevices) {
      listCameraDevices = listMediaDevices.where((device) => device.kind == 'videoinput').toList();
      listAudioDevices = listMediaDevices.where((device) => device.kind == 'audioinput').toList();
      
      if (this.mounted) setState(() => _localRenderer.srcObject = stream);
    });

    p2pManager.onAddRemoteStream = ((stream, __) {
      if (this.mounted) setState(() => _remoteRenderer.srcObject = stream);
    });
  }

  void _ringing() {
    _timerRinging = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timer.tick >= 30) {
        timer.cancel();
        p2pManager.terminateConnect();
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

  void _ringWithReached() {
    // player?.stop();
    // player?.open(Media.asset('assets/musics/outcoming_sound.mp3'));
    // player?.play();
  }

  void _stopRingAndStartCounter() {
    _timerCounter.startTimeout().onChange = (second) {
      if (this.mounted) setState(() {
        timer = second;
      });
    };
    // _timerRinging?.cancel();
    // player?.stop();
  }
  //<------------------------------------------------------->

  //<--------------Animation layout start here-------------->
  void _updateCornersOffsets({
    required Size spaceSize,
    required Size widgetSize,
    required EdgeInsets windowPadding,
  }) {
    _offsets = _calculateOffsets(
      spaceSize: spaceSize,
      widgetSize: widgetSize,
      windowPadding: windowPadding,
    );
  }
  bool _isAnimating() {
    return _toggleFloatingAnimationController.isAnimating ||
      _dragAnimationController.isAnimating;
  }
  void startFloating() {
    if (_isAnimating() || isFloating) return;
    dismissKeyboard(context);
    setState(() {
      isFloating = true;
    });
    _toggleFloatingAnimationController.forward();
  }
  void stopFloating() {
    if (_isAnimating() || !isFloating) return;
    dismissKeyboard(context);
    _toggleFloatingAnimationController.reverse().whenCompleteOrCancel(() {
      if (mounted) {
        setState(() {
          isFloating = false;
        });
      }
    });
  }
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragOffset = _dragOffset.translate(
        details.delta.dx,
        details.delta.dy,
      );
    });
  }

  void _onPanCancel() {
    if (!_isDragging) return;
    setState(() {
      _dragAnimationController.value = 0;
      _dragOffset = Offset.zero;
      _isDragging = false;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    final nearestCorner = _calculateNearestCorner(
      offset: _dragOffset,
      offsets: _offsets,
    );
    setState(() {
      _corner = nearestCorner;
      _isDragging = false;
    });
    _dragAnimationController.forward().whenCompleteOrCancel(() {
      _dragAnimationController.value = 0;
      _dragOffset = Offset.zero;
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (_isAnimating()) return;
    setState(() {
      _dragOffset = _offsets[_corner]!;
      _isDragging = true;
    });
  }
  //<-------------------------------------------------->

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
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;

    final mediaQuery = MediaQuery.of(context);
    var windowPadding = mediaQuery.padding;
    windowPadding += mediaQuery.viewInsets;

    return LayoutBuilder(
      builder: ((context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        double floatingWidth = 500.0;
        double floatingHeight = height / width * floatingWidth;

        final floatingWidgetSize = Size(floatingWidth, floatingHeight);
        final fullWidgetSize = Size(width, height);

        _updateCornersOffsets(
          spaceSize: fullWidgetSize,
          widgetSize: floatingWidgetSize,
          windowPadding: windowPadding,
        );
        final calculatedOffset = _offsets[_corner];
        final widthRatio = floatingWidth / width;
        final heightRatio = floatingHeight / height;
        final scaledDownScale = widthRatio > heightRatio
            ? floatingWidgetSize.width / fullWidgetSize.width
            : floatingWidgetSize.height / fullWidgetSize.height;

        return Stack(
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([
                _toggleFloatingAnimationController,
                _dragAnimationController
              ]),
              builder: (context, child) {
                final animationCurve = CurveTween(curve: Curves.linearToEaseOut);
                final dragAnimationValue = animationCurve.transform(_dragAnimationController.value);
                final toggleFloatingAnimationValue = animationCurve.transform(_toggleFloatingAnimationController.value);
                final floatingOffset = _isDragging
                    ? _dragOffset
                    : Tween<Offset>(
                      begin: _dragOffset,
                      end: calculatedOffset,
                    ).transform(_dragAnimationController.isAnimating ? dragAnimationValue : toggleFloatingAnimationValue);
                final borderRadius = Tween<double>(
                  begin: 0,
                  end: 10
                ).transform(toggleFloatingAnimationValue);
                final width = Tween<double>(
                  begin: fullWidgetSize.width,
                  end: floatingWidgetSize.width
                ).transform(toggleFloatingAnimationValue);
                final height = Tween<double>(
                  begin: fullWidgetSize.height,
                  end: floatingWidgetSize.height,
                ).transform(toggleFloatingAnimationValue);
                final scale = Tween<double>(
                  begin: 1,
                  end: scaledDownScale,
                ).transform(toggleFloatingAnimationValue);
                return Positioned(
                  left: floatingOffset.dx,
                  top: floatingOffset.dy,
                  child: GestureDetector(
                    onPanStart: isFloating ? _onPanStart : null,
                    onPanUpdate: isFloating ? _onPanUpdate : null,
                    onPanCancel: isFloating ? _onPanCancel : null,
                    onPanEnd: isFloating ? _onPanEnd : null,
                    onTap: isFloating ? stopFloating : null,
                    child: Material(
                      elevation: 10,
                      borderRadius: BorderRadius.circular(borderRadius),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(borderRadius)
                        ),
                        width: width,
                        height: height,
                        child: Transform.scale(
                          scale: scale,
                          child: OverflowBox(
                            maxHeight: fullWidgetSize.height,
                            maxWidth: fullWidgetSize.width,
                            child: IgnorePointer(
                              ignoring: isFloating,
                              child: child,
                            ),
                          ),
                        )
                      ),
                    ),
                  ),
                );
              },
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                home: Scaffold(
                  body: SafeArea(
                    child: Material(
                      color: Colors.black,
                      child: Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(horizontal: 100.0, vertical: 20.0),
                        color: isDark ? Color(0xff3D3D3D) : Color(0xffE5E5E5),
                        child: !callConnected ? widget.type == "offer" ? _buildOutComing() : _buildIncoming() : _buildInCall()
                      )
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
  Widget _buildOutComing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBackButton(),
                _buildOptionMediaDevices()
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: _buildNameWithTimer(null),
            )
          ],
        ),

        Expanded(
          child: isVideoEnable && widget.mediaType == "video" 
          ? _buildLocalRenderer()
          : _buildAvatarWithLottieOnRinging(),
        ),
        _buildListActionButton()
      ],
    );
  }
  Widget _buildIncoming() {
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
                      _buildAvatarWithLottieOnRinging(),
                      _buildNameWithTimer(null)
                    ],
                  ),
                ),
                _buildListActionButton()
              ]
            ),
          ),
        )
      ],
    );
  }
  Widget _buildInCall() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBackButton(),
                 _buildOptionMediaDevices()
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: _buildNameWithTimer(timer),
            ),
          ],
        ),
        SizedBox(height: 20),
        widget.mediaType == "video" ? Expanded(
          child: Stack(
            children: [
              Positioned(
                left: 0, top: 0, right: 0, bottom: 0,
                child: _buildRemoteRenderer(),
              ),
              Positioned(
                right: 20,
                top: 20,
                width: 300,
                height: 200,
                child: _buildLocalRenderer(),
              )
            ],
          ),
        ) : Expanded(
          child: _buildAvatarOnAudioConnected(),
        ),
        _buildListActionButton()
      ],
    );
  }

  Widget _buildLocalRenderer() {
    return Container(
      decoration: BoxDecoration(border: Border.all(width: 1)),
      child: RTCVideoView(_localRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover, mirror: true)
    );
  }
  Widget _buildRemoteRenderer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child: RTCVideoView(_remoteRenderer)
    );
  }
  Widget _buildAvatarWithLottieOnRinging() {
    return Stack(
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
    );
  }
  Widget _buildAvatarOnAudioConnected() {
    return Center(
      child: CachedAvatar(
        user["avatar_url"], 
        name: user["full_name"], 
        width: 250, height: 250
      ),
    );
  }
  Widget _buildBackButton() {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return InkWell(
      onTap: startFloating,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xff5E5E5E) : Color(0xffFFFFFF),
          borderRadius: BorderRadius.circular(19)
        ),
        width: 38,
        height: 38,
        child: Icon(PhosphorIcons.arrowLeft, size: 20, color: isDark ? Color(0xffEDEDED) : Color(0xff5E5E5E),),
      ),
    );
  }

  Widget _buildNameWithTimer(timer) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(5),
          child: Text(user["full_name"], style: TextStyle(fontSize: 18, color: isDark ? Color(0xffDBDBDB) : Color(0xff3D3D3D))),
        ),
        Padding(
          padding: const EdgeInsets.all(5),
          child: timer != null ? Text(timer.toString()) : Text(widget.type == "offer" ? "Calling..." : "is calling you...", style: TextStyle(fontSize: 14, color: Color(0xff40A9FF)))
        ),
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

  Widget _buildOptionCameraDevices() {
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
  Widget _buildOptionAudioDevices() {
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

  Widget _buildOptionMediaDevices() {
    return Column(
      children: [
        if (widget.mediaType == "video") _buildOptionCameraDevices(),
        _buildOptionAudioDevices()
      ],
    );
  }
  Widget _buildListActionButton() {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return Container(
      width: 300,
      margin: EdgeInsets.only(top: 20),
      height: 70,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (widget.mediaType == "video" && (callConnected || widget.type == "offer"))
              _buildActionButton(
                enableIcon: PhosphorIcons.videoCameraThin,
                disableIcon: PhosphorIcons.videoCameraSlashThin,
                defaultState: isVideoEnable,
                backgroundColor: isDark ? Color(0xff2E2E2E) : Color(0xffC9C9C9),
                color: isDark ? Colors.white : Color(0xff3D3D3D),
                onAction: (value) {
                  setState(() {
                    isVideoEnable = value;
                    p2pManager.setEnableVideo(isVideoEnable);
                  });
                }
              ),
            _buildActionButton(
              enableIcon: PhosphorIcons.phoneDisconnectThin,
              disableIcon: PhosphorIcons.phoneDisconnectThin,
              color: Colors.white,
              backgroundColor: Color(0xffEB5757),
              onAction: (_) {
                setState(() {
                  p2pManager.terminateConnect();
                  
                  callConnected = false;
                  // player?.stop();
                });
              }
            ),
            if (callConnected || widget.type == "offer")
              _buildActionButton(
                enableIcon: PhosphorIcons.microphoneThin,
                disableIcon: PhosphorIcons.microphoneSlashThin,
                color: !isMicEnable && !isDark ? Color(0xff3D3D3D) : Colors.white,
                backgroundColor: isMicEnable ? Color(0xff1890FF) : isDark ? Color(0xff2E2E2E) : Color(0xffC9C9C9),
                defaultState: isMicEnable,
                onAction: (value) {
                  setState(() {
                    isMicEnable = !isMicEnable;
                    p2pManager.setEnableMic(isMicEnable);
                  });
                }
              ),
            if(widget.type == "answer" && !callConnected)
              _buildActionButton(
                enableIcon: PhosphorIcons.phoneCallFill,
                disableIcon: PhosphorIcons.phoneCallFill,
                color: Colors.white,
                backgroundColor: Color(0xff27AE60),
                onAction: (_) {
                  setState(() {
                    widget.callback();
                  });
                }
              ),
            if (callConnected || widget.type == "offer")
              _buildActionButton(
                enableIcon: PhosphorIcons.speakerHighFill,
                disableIcon: PhosphorIcons.speakerSlashFill,
                color: Colors.white,
                backgroundColor: isDark ? Color(0xff2E2E2E) : Color(0xffC9C9C9),
                defaultState: isSpeakerEnable,
                onAction: (_) {

                }
              )
          ],
        ),
      ),
    );
  }
  ActionButton _buildActionButton({enableIcon, disableIcon, defaultState, color, backgroundColor, onAction}) {
    return ActionButton(
      enableIcon: enableIcon,
      disableIcon: disableIcon,
      defaultState: defaultState,
      color: color,
      backgroundColor: backgroundColor,
      onAction: onAction,
    );
  }
  void onChangeCameraDevice(deviceId) {
    p2pManager.switchDevice(deviceId, 'videoinput');
  }
  void onChangeAudioDevice(deviceId) {
    p2pManager.switchDevice(deviceId, 'audioinput');
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

Map<PIPViewCorner, Offset> _calculateOffsets({
  required Size spaceSize,
  required Size widgetSize,
  required EdgeInsets windowPadding,
}) {
  Offset getOffsetForCorner(PIPViewCorner corner) {
    final spacing = 16;
    final left = spacing + windowPadding.left;
    final top = spacing + windowPadding.top;
    final right =
        spaceSize.width - widgetSize.width - windowPadding.right - spacing;
    final bottom =
        spaceSize.height - widgetSize.height - windowPadding.bottom - spacing;

    switch (corner) {
      case PIPViewCorner.topLeft:
        return Offset(left, top);
      case PIPViewCorner.topRight:
        return Offset(right, top);
      case PIPViewCorner.bottomLeft:
        return Offset(left, bottom);
      case PIPViewCorner.bottomRight:
        return Offset(right, bottom);
      default:
        throw Exception('Not implemented.');
    }
  }

  final corners = PIPViewCorner.values;
  final Map<PIPViewCorner, Offset> offsets = {};
  for (final corner in corners) {
    offsets[corner] = getOffsetForCorner(corner);
  }

  return offsets;
}
void dismissKeyboard(BuildContext context) {
  FocusScope.of(context).requestFocus(FocusNode());
}

PIPViewCorner _calculateNearestCorner({
  required Offset offset,
  required Map<PIPViewCorner, Offset> offsets,
}) {
  _CornerDistance calculateDistance(PIPViewCorner corner) {
    final distance = offsets[corner]!
        .translate(
          -offset.dx,
          -offset.dy,
        )
        .distanceSquared;
    return _CornerDistance(
      corner: corner,
      distance: distance,
    );
  }

  final distances = PIPViewCorner.values.map(calculateDistance).toList();

  distances.sort((cd0, cd1) => cd0.distance.compareTo(cd1.distance));

  return distances.first.corner;
}

class _CornerDistance {
  final PIPViewCorner corner;
  final double distance;

  _CornerDistance({
    required this.corner,
    required this.distance,
  });
}
class ActionButton extends StatefulWidget {
  const ActionButton({ Key? key, this.enableIcon = Icons.abc, this.disableIcon = Icons.abc, this.color = Colors.black, this.backgroundColor = Colors.white, this.defaultState, required this.onAction }) : super(key: key);
  final IconData enableIcon;
  final IconData disableIcon;
  final Color color;
  final backgroundColor;
  final defaultState;
  final onAction;
  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _value = true;
  @override
  void initState() {
    if (widget.defaultState != null) _value = widget.defaultState;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      clipBehavior: Clip.antiAlias,
      color: widget.backgroundColor,
      borderRadius: BorderRadius.circular(50),
      elevation: 10,
      child: InkWell(
        onTap: () {
          setState(() {
            _value = !_value;
            widget.onAction.call(_value);
          });
        },
        child: Container(
          margin: EdgeInsets.all(13),
          child: Icon(
            widget.defaultState != null ? widget.defaultState ? widget.enableIcon : widget.disableIcon :
            _value? widget.enableIcon : widget.disableIcon,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}