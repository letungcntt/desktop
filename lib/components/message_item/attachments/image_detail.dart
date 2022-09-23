import 'dart:async';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/media_conversation/model.dart';
import 'package:workcake/providers/providers.dart';

import '../../../common/utils.dart';
import 'images_gallery.dart';


class ImageDetail extends StatefulWidget {
  final url;
  final id;
  final full;
  final tag;
  final String? keyEncrypt;
  final version;

  ImageDetail({
    Key? key,
    @required this.id,
    @required this.url,
    @required this.tag,
    this.full = false,
    this.keyEncrypt,
    this.version,  
  }) : super(key: key);
  @override
  _ImageDetailState createState() => _ImageDetailState();
}

class _ImageDetailState extends State<ImageDetail> with TickerProviderStateMixin{
  var show = false;
  bool isZoom = false;
  var detailsState;
  TransformationController transformationController = new TransformationController();
  AnimationController? _controller;
  Animation<double>? animation;
  int rotateTime = 0;
  double x = 0;
  int lastTime = 0;
  bool showActionButton = false;
  bool hoveredActionButton = false;
  bool hideCopied = true;
  String id  = "";
  bool hideDowload = true;
  int page = 0;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    animation = Tween(begin: 0.0, end: 1.0).animate(_controller!);
    super.initState();
    Timer(Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        show = true;
      });
    });
  }

  @override
  void dispose() {
    transformationController.dispose();
    _controller!.dispose();
    super.dispose();
  }

  onPointerHover() {
    if(!showActionButton && this.mounted) {
      setState(() {
        showActionButton = true;
      });
      lastTime = DateTime.now().microsecondsSinceEpoch;
      if(!hoveredActionButton) {
        Future.delayed(Duration(seconds: 4), () {
          if(DateTime.now().microsecondsSinceEpoch > (lastTime + 4000000)) {
            if(this.mounted) {
              setState(() {
                showActionButton = false;
              });
            }
          }
        });
      }
    }
  }

  onRotateImage(String action) {
    if (x == 1 || x == -1) x = 0;
    if(action == 'right') {
      animation = Tween<double>(begin: x, end: x + 0.25).animate(_controller!);
      setState(() => x = x + 0.25);
    } else {
      animation = Tween<double>(begin: x, end: x - 0.25).animate(_controller!);
      setState(() => x = x - 0.25);
    }
    _controller!.forward(from: 0);
  }

  void onTapDown(details) {
    if (transformationController.value != Matrix4.identity()) {
      transformationController.value = Matrix4.identity();
    } else {
      final position = details.localPosition;
      transformationController.value = Matrix4.identity()
      ..translate(-position.dx, -position.dy)
      ..scale(2.0);
    }
    this.setState(() {
      detailsState = details;
      isZoom = !isZoom;
    });
  }
@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Listener(
            onPointerHover: (event) {
              onPointerHover();
            },
            child: RotationTransition(
              turns: animation!,
              child: ExtendedImageGesturePageView.builder(
                itemBuilder: (BuildContext context, int index) {
                  GestureConfig initGestureConfigHandler(state) {
                      return GestureConfig(
                        minScale: 0.9,
                        animationMinScale: 0.7,
                        maxScale: 3.0,
                        animationMaxScale: 3.5,
                        speed: 1.0,
                        inertialSpeed: 100.0,
                        initialScale: 1.0,
                        inPageView: true,
                        initialAlignment: InitialAlignment.center,
                      );
                  }
                  return Hero(
                    tag: widget.tag,
                    child: ExtendedImage.network(
                      widget.url,
                      fit: BoxFit.contain,
                      cache: true,
                      initGestureConfigHandler: initGestureConfigHandler,
                      clearMemoryCacheWhenDispose: true,
                      mode: ExtendedImageMode.gesture,
                    ),
                  );
                }
              ),
            ),
          ),
          if(showActionButton) AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            top: show ? 0 : -100,
            child: Container(
              color: Color(0xFF000000).withOpacity(0.25),
              height: 50,
              padding: EdgeInsets.only(left: 6, right: 6),
              alignment: Alignment.centerLeft,
              width: MediaQuery.of(context).size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if(hideCopied == false) Text("Image has been copied", style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w700, color: Color(0xff27AE60))),
                        if(hideDowload == false) Text("Image has been downloaded", style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w700, color: Color(0xff27AE60))),
                        SizedBox(width: 8),
                        Container(
                          height: 50,
                          width: 50,
                          child: HoverItem(
                            onHover: () {
                              setState(() {
                                hoveredActionButton = true;
                              });
                            },
                            onExit: () {
                              setState(() {
                                hoveredActionButton = false;
                              });
                            },
                            colorHover: Colors.grey.withOpacity(0.4),
                            child: InkWell(
                              focusNode: FocusNode(skipTraversal: true),
                              highlightColor: Color(0xff27AE60),
                              onTap: () async {
                                setState(() {
                                  hideCopied = false;
                                });
                                MethodChannel channel = MethodChannel("copy");
                                String urlImage = await ServiceMedia.getDownloadedPath(widget.url) ?? widget.url;
                                channel.invokeMethod("copy_image", urlImage);
                                Future.delayed(Duration(milliseconds: 2500), () {
                                  if (!mounted) return;
                                  setState(() {
                                    hideCopied = true;
                                  });
                                });

                              },
                              child: Icon(Icons.copy, size: 20, color: Colors.white,)
                            ),
                          )
                        ),
                        Container(
                          height: 50,
                          width: 50,
                          child: HoverItem(
                            colorHover: Colors.grey.withOpacity(0.4),
                            child: InkWell(
                              onTap: () {
                                setState(() => id = Utils.getRandomString(10));
                                hideDowload = false;
                                Provider.of<Work>(context, listen: false).addTaskDownload({"content_url": widget.url,"id": id,  "key_encrypt": widget.keyEncrypt, "version": widget.version});
                                Future.delayed(Duration(milliseconds: 2500), () {
                                if (!mounted) return;
                                  setState(() => hideDowload = true);
                                });
                              }, 
                              child: Icon(Icons.file_download, size: 20, color: Color(0xFFFFFFFF))
                            ),
                          ),
                        ),
                        Container(
                          height: 50,
                          width: 50,
                          child: HoverItem(
                            colorHover: Colors.grey.withOpacity(0.4),
                            child: TextButton(
                              onPressed: () { },
                              child: Icon(Icons.share, size: 20,  color: Color(0xFFFFFFFF))
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                width: 1,
                                color: Colors.white
                              )
                            )
                          )
                        ),
                        Container(
                          height: 50,
                          width: 50,
                          child: HoverItem(
                            colorHover: Colors.grey.withOpacity(0.4),
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Icon(Icons.close_rounded, size: 24, color: Colors.white)
                            ),
                          )
                        )
                      ]
                    )
                  ),
                ],
              )
            ),
          ),
          if(showActionButton) AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            bottom: 0,
            child: HoverItem(
              onHover: () {
                setState(() {
                  hoveredActionButton = true;
                });
              },
              onExit: () {
                setState(() {
                  hoveredActionButton = false;
                });
              },
              child: Container(
                color: Color(0xFF000000).withOpacity(0.25),
                height: 50,
                alignment: Alignment.centerLeft,
                width: MediaQuery.of(context).size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Container(
                            height: 50,
                            width: 50,
                            child: TextButton(
                              onPressed: () => onRotateImage('left'),
                              child: Icon(Icons.rotate_left, color: Color(0xFFFFFFFF)),
                            ),
                          ),
                          Container(width: 50),
                          Container(
                            height: 50,
                            width: 50,
                            child: TextButton(
                              onPressed: () => onRotateImage('right'),
                              child: Icon(Icons.rotate_right, color: Color(0xFFFFFFFF)),
                            )
                          )
                        ]
                      )
                    )
                  ]
                )
              ),
            )
          ),
          Positioned(
            bottom: 8, right: 8,
            child: Container(
              height: 90,
              child: TaskDownloadImage(idShow: id,)), 
          ),
        ]
      ),
    );
  }
}
