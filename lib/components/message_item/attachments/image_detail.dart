import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/components/dropdown_overlay.dart';
import 'package:workcake/media_conversation/model.dart';
import 'package:workcake/models/models.dart';

class ImageDetail extends StatefulWidget {
  final url;
  final id;
  final full;
  final tag;
  final String? keyEncrypt;

  ImageDetail({
    Key? key,
    @required this.id,
    @required this.url,
    @required this.tag,
    this.full = false,
    this.keyEncrypt
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

  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          RotationTransition(
            turns: animation!,
            child: Hero(
              tag: widget.tag,
              child: Center(
                child: GestureDetector(
                  onTapDown: onTapDown,
                  child: InteractiveViewer(
                    transformationController: transformationController,
                    boundaryMargin: EdgeInsets.all(50),
                    minScale: 0.5,
                    maxScale: 4,
                    child: CachedImage(widget.url, radius: 10, fit: BoxFit.cover, full: widget.full),
                  )
                )
              )
            ),
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            top: show ? 0 : -100,
            child: Container(
              color: Color(0xFF000000).withOpacity(0.25),
              height: 50,
              padding: EdgeInsets.only(top: 8, left: 6, right: 6),
              alignment: Alignment.centerLeft,
              width: MediaQuery.of(context).size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          height: 50,
                          width: 50,
                          child: DropdownOverlay(
                            width: 60,
                            dropdownWindow: Container(height: 20, color: Colors.black ,child: Center(child: Text("copied", style: TextStyle(color: Colors.white)))),
                            child: Icon(Icons.copy, size: 20, color: Colors.white),
                            onTap: () async {
                              MethodChannel channel = MethodChannel("copy");
                              String urlImage = await ServiceMedia.getDownloadedPath(widget.url) ?? widget.url;
                              channel.invokeMethod("copy_image", urlImage);
                            }
                          )
                        ),
                        Container(
                          height: 50,
                          width: 50,
                          child: TextButton(
                            onPressed: () => Provider.of<Work>(context, listen: false).addTaskDownload({"content_url": widget.url,  "key_encrypt": widget.keyEncrypt,}),
                            child: Icon(Icons.file_download, size: 20, color: Color(0xFFFFFFFF))
                          ),
                        ),
                        Container(
                          height: 50,
                          width: 50,
                          child: TextButton(
                            onPressed: () { },
                            child: Icon(Icons.share, size: 20,  color: Color(0xFFFFFFFF))
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
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Icon(Icons.close_rounded, size: 24, color: Colors.white)
                          )
                        )
                      ]
                    )
                  ),
                ],
              )
            ),
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            bottom: 0,
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
            )
          )
        ]
      )
    );
  }
}
