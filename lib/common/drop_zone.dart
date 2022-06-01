import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imgLib;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'package:workcake/common/palette.dart';

typedef void HighlightBoxCallback(value);
class StreamDropzone extends ValueNotifier<bool>{
  static final channel = MethodChannel("drop_zone");
  static final instance = StreamDropzone();

  final _droppedController = StreamController<List>.broadcast(sync: false);
  final _stringController = StreamController<String>.broadcast(sync: false);
  final _focusedController = StreamController<bool>.broadcast(sync: false);
  StreamDropzone() : super(false){
    channel.setMethodCallHandler((call) async{
      switch (call.method){
        case "entered":
          value = true;
          break;
        case "exited":
          value = false;
          _droppedController.add(["-1:-1"]);
          break;
        case "updated":
          _droppedController.add(call.arguments);
          break;
        case "dropped":
          _droppedController.add(call.arguments);
          value = false;
          break;
        case "change_theme":
          _stringController.add(call.arguments);
        break;
        case "is_focused":
          _focusedController.add(call.arguments);
        break;
      }

      return null;
    });
  }

  Stream<List> get dropped => _droppedController.stream;
  Stream<String> get currentTheme => _stringController.stream;
  Stream<bool> get isFocusedApp => _focusedController.stream;
  initDrop(){
    _droppedController.add([]);
  }
}

class DropZone<T, S> extends StatefulWidget{
  DropZone({
    Key? key,
    this.stream,
    this.initialData,
    this.onHighlightBox,
    this.shouldBlock = false,
    this.useCustomHighlight = false,
    this.customOverlay,
    @required this.builder
  });

  final stream;
  final builder;
  final initialData;
  final HighlightBoxCallback? onHighlightBox;
  final shouldBlock;
  final useCustomHighlight;
  final Widget? customOverlay;
  @override
  State<StatefulWidget> createState() => _DropZoneState();
}

class _DropZoneState<T, S> extends State<DropZone<T, S>>{
  var _subscription;
  var _summary;
  GlobalKey key = GlobalKey();
  var objectSize;
  var wrapperSize;
  var globalPosition;
  var renderBox;
  bool hasFocus = false;
  double? ratioScreen;
  bool highlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      StreamDropzone.instance.initDrop();
      findWidgetPosition();
    });
    _summary = widget.initialData == null ? AsyncSnapshot<T>.nothing() : AsyncSnapshot<T>.withData(ConnectionState.none, widget.initialData);
    _subscribe();
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant var oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(oldWidget.stream != widget.stream){
      if(_subscription != null){
        _unsubscribe();
        _summary = _summary.inState(ConnectionState.none);
      }
      _subscribe();
    }
    if(oldWidget.builder != widget.builder){
      WidgetsBinding.instance.addPostFrameCallback((_){
        StreamDropzone.instance.initDrop();
        findWidgetPosition();
    });
    }
  }

  void _subscribe(){
    if(widget.stream != null){
      _subscription = widget.stream.listen((data) {
        if(data.length != 0 && ModalRoute.of(context) != null && ModalRoute.of(context)!.isCurrent && !widget.shouldBlock) {
          final curStr = data[0].toString();
          if(curStr == "paste_bytes"){
            if(hasFocus){
              final _dataStream = new List<dynamic>.from(data);
              _dataStream.removeAt(0);
              Future.wait(
                (_dataStream).map((bytes) async{
                  DateTime now = DateTime.now();
                  String formatted = DateFormat('yyyy-MM-dd kk-mm-ss').format(now);
                  var name = "Image $formatted";

                  if (Platform.isWindows){
                    var base64encoded = bytes;
                    Uint8List file = base64.decode(base64encoded);
                    try{
                      return {
                        "name": name,
                        "mime_type": "image",
                        "path": sha256.convert(bytes.codeUnits).toString(),
                        "file": file
                      };
                    } catch(e){
                      return null;
                    }
                  } else if(Platform.isMacOS){
                    try{
                      imgLib.Decoder? dec = imgLib.findDecoderForData(bytes);
                      var decode = dec!.decodeImage(bytes);
                      return {
                        "name": name,
                        "mime_type": "image",
                        "path": sha256.convert(bytes).toString(),
                        "file": imgLib.encodePng(decode!)
                      };
                    } catch(e){
                      return null;
                    }
                  }
                })
              ).then((value){
                setState(() {
                  _summary = AsyncSnapshot<T>.withData(ConnectionState.active, value.where((element) => element != null).toList() as T);
                });
              });
            }
          } else if(curStr == "paste"){
            if (hasFocus){
              final _dataStream = new List<dynamic>.from(data);
              _dataStream.removeAt(0);
              Future.wait(
                (_dataStream).map((uro) async{
                  try{
                    var uri = uro.replaceAll("%2520", "%20");
                    File file = File(uri);
                    var name  = file.path.split("\\").last;
                    var type =  name.split(".").last.toLowerCase();
                    if (type  == "png" || type == "jpg" || type == "jpeg" || type == "webp") type = "image";
                    if (type == "") type = "text";

                    return {
                      "name": name,
                      "mime_type": "image",
                      "path": file.path,
                      "file": await file.readAsBytes()
                    };
                  } catch(e){
                    return null;
                  }
                })
              ).then((value){
                setState(() {
                  _summary = AsyncSnapshot<T>.withData(ConnectionState.active, value.where((element) => element != null).toList() as T);
                });
              });
            }
          } else{
            final d = curStr.split(":");
            findWidgetPosition();
            
            final cursor = Offset(double.parse(d[0]), double.parse(d[1]));
            bool checkDropCompleted = data.length >= 2;
            if(!renderBox.contains(cursor)) {
              if (highlight){
                widget.onHighlightBox?.call(false);
                setState(() {
                  highlight = false;
                });
              }
            } else {
              if (!highlight) {
                widget.onHighlightBox?.call(true);
                setState(() {
                  highlight = true;
                });
              } else if (checkDropCompleted) {
                widget.onHighlightBox?.call(false);
                setState(() {
                  highlight = false;
                });
              }
              final _dataStream = new List<dynamic>.from(data);
              _dataStream.removeAt(0);
              Future.wait(
                (_dataStream).map((uro) async{
                  try{
                    var uri = uro.replaceAll("%2520", "%20");
                    File file = Platform.isWindows ? File(uri) : File.fromUri(Uri.parse(uri));
                    var name  = Platform.isWindows ? file.path.split("\\").last :  file.path.split("/").last;
                    var type =  name.split(".").last.toLowerCase();
                    if (type  == "png" || type == "jpg" || type == "jpeg" || type == "webp") type = "image";
                    if (type == "") type = "text";

                    return {
                      "name": name,
                      "mime_type": type,
                      "path": file.path,
                      "file": await file.readAsBytes()
                    };
                  } catch(e){
                    return null;
                  }
                })
              ).then((value){
                setState(() {
                  _summary = AsyncSnapshot<T>.withData(ConnectionState.active, value.where((element) => element != null).toList() as T);
                });
              });
            }
          }
        } else{
          _summary = AsyncSnapshot<T>.withData(ConnectionState.active, [] as T);
        }
      }, onError: (Object error){
        setState(() {
          _summary = AsyncSnapshot<T>.withError(ConnectionState.active, error);
        });
      }, onDone: () {
        setState(() {
          _summary = _summary.inState(ConnectionState.done);
        });
      });
      _summary = _summary.inState(ConnectionState.waiting);
    }
  }
  
  void _unsubscribe(){
    if (_subscription != null){
      _subscription.cancel();
      _subscription = null;
    }
  }

  void findWidgetPosition(){
    if(key.currentContext != null) {
      final renderObject = key.currentContext?.findRenderObject() as RenderBox;
      var translation = renderObject.getTransformTo(null).getTranslation();
      double _ratio =  ratioScreen != null && Platform.isWindows ? ratioScreen! : 1;
      var newObjectSize = Size(renderObject.paintBounds.width * _ratio, renderObject.paintBounds.height * _ratio);
      var newRenderBox = Offset(translation.x * _ratio, translation.y * _ratio) & newObjectSize;

      if (newObjectSize != objectSize || newRenderBox != renderBox) {
        setState(() {
          objectSize = newObjectSize;
          renderBox = newRenderBox;
        });
      }
    }
  }

  Widget get blurOverlay => Container(
    color: Palette.defaultBackgroundDark.withOpacity(0.8),
    child: Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0), 
        duration: Duration(milliseconds: 160), 
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("DROP HERE", style: TextStyle(fontSize: 30, color: Colors.grey, decorationStyle: TextDecorationStyle.dashed)),
                  Icon(Icons.arrow_circle_down_sharp, color: Colors.grey,)
                ],
              ),
            ),
          );
        }
      )
      // child: Center(child: Text("Drop Here", style: TextStyle(fontSize: 40, color: Colors.grey))),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // ratioScreen = MediaQuery.of(context).devicePixelRatio;
    return Focus(
      key: key,
      onFocusChange: (value) {
        if(value){
          hasFocus = true;
        }
        else{
          hasFocus = false;
        }
      },
      child: Container(
        child: Stack(
          children: [
            widget.builder(context, _summary),
            if(highlight && !widget.useCustomHighlight) Positioned(
              top: 0, left: 0, right: 0, bottom: 0,
              child: widget.customOverlay ?? blurOverlay,
            )
          ]
        ),
      ),
    );
  }
}
