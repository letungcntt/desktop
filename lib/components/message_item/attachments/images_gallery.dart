// ignore_for_file: body_might_complete_normally_nullable

import 'dart:convert';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/common/video_player.dart';
import 'package:workcake/components/custom_confirm_dialog.dart';
import 'package:workcake/components/image_reply.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/media_conversation/model.dart';
import 'package:workcake/media_conversation/stream_media_downloaded.dart';
import 'package:workcake/models/models.dart';
import 'package:crypto/crypto.dart';

class ImagesGallery extends StatefulWidget {
  ImagesGallery({
    var key,
    this.att,
    this.isChildMessage,
    this.isThread,
    this.message,
    this.fromIssue = false,
    required this.isConversation
  }) : super(key: key);

  final att;
  final isChildMessage;
  final isThread;
  final message;
  final fromIssue;
  final bool isConversation;

  @override
  _ImagesGalleryState createState() => _ImagesGalleryState();
}

class _ImagesGalleryState extends State<ImagesGallery> {
  var show = false;
  int page = 0;
  late List<String> tags;

  @override
  void initState() {
    super.initState();
    tags = List.generate(widget.att["data"].length, (index) => Utils.getRandomString(10));
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    var oldWidgetHash = sha256.convert(utf8.encode(oldWidget.att.toString()));
    var widgetHash = sha256.convert(utf8.encode(widget.att.toString()));

    if (oldWidgetHash != widgetHash) {
      tags = List.generate(widget.att["data"].length, (index) => Utils.getRandomString(10));
    }
  }

  onTapImage(img) {
    final index = widget.att["data"].indexWhere((e) => e["content_url"] == img["content_url"]);

    this.setState(() {
      page = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final messageImage = Provider.of<Messages>(context, listen: true).messageImage;

    return Container(
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4)
      ),
      constraints: !(widget.isChildMessage || Utils.checkedTypeEmpty(widget.isThread)) ? BoxConstraints(
        maxWidth: widget.fromIssue ? double.infinity : 380,
      ) : BoxConstraints(),
      child: Wrap(
        alignment: WrapAlignment.start,
        children: widget.att["data"].map<Widget>((img) {
          var index = (widget.att["data"] as List).indexOf(img);

          return widget.fromIssue ? Container(
            height: 160,
            width: 160,
            margin: EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: img["content_url"].toString().toLowerCase().split(".").last == "mov" ? null : () async{
                onTapImage(img);
                if(Utils.checkedTypeEmpty(widget.message)) Provider.of<Messages>(context, listen: false).onChangeMessageImage((widget.message['isChildMessage'] ?? false) ? messageImage : (widget.message ?? {}));
                Navigator.push(context, PageRouteBuilder(
                  barrierColor: Colors.black.withOpacity(1.0),
                  barrierLabel: '',
                  opaque: false,
                  barrierDismissible: true,
                  pageBuilder: (context,_, __) => (Utils.checkedTypeEmpty(widget.message) && !widget.message['isChildMessage'])
                    ? ImageReply(page: page, tags: tags, att: widget.att)
                    : Gallery(
                      page: page,
                      tags: tags,
                      att: widget.att,
                      isShowThread: false,
                      isChildMessage: true,
                      isConversation: widget.isConversation
                    )
                )).then((value) {
                  if (widget.message == null) return;
                  Provider.of<Messages>(context, listen: false).onChangeMessageImage(widget.message['isChildMessage'] ? messageImage : {});
                });
              },
              child: img["content_url"] == null
              ? Text("Message unavailable", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13, fontWeight: FontWeight.w200))
              : img["content_url"].toString().toLowerCase().split(".").last == "mov" || img["content_url"].toString().toLowerCase().split(".").last == "mp4" ? VideoPlayer(att: img) : ImageItem(tag: tags[index], img: img, isThread: widget.isThread, previewComment: true, isConversation: widget.isConversation)
            ),
          ) : Container(
            child: GestureDetector(
              onTap: img["content_url"].toString().toLowerCase().split(".").last == "mov" ? null : () async{
                onTapImage(img);
                if(Utils.checkedTypeEmpty(widget.message)) Provider.of<Messages>(context, listen: false).onChangeMessageImage(
                  (widget.message['isChildMessage'] ?? false)
                  ? (messageImage['id'] != null ?  messageImage : widget.message)
                  : (widget.message ?? {})
                );
                if(Utils.checkedTypeEmpty(widget.message)) Navigator.push(context, PageRouteBuilder(
                  barrierColor: Colors.black.withOpacity(1.0),
                  barrierLabel: '',
                  opaque: false,
                  barrierDismissible: true,
                  pageBuilder: (context,_, __) => (Utils.checkedTypeEmpty(widget.message) && !widget.message['isChildMessage'])
                    ? ImageReply(page: page, tags: tags, att: widget.att)
                    : Gallery(
                      page: page,
                      tags: tags,
                      att: widget.att,
                      isShowThread: false,
                      isChildMessage: true,
                      isConversation: widget.isConversation,
                    )
                )).then((value) {
                  Provider.of<Messages>(context, listen: false).onChangeMessageImage(
                    widget.message != null && (widget.message['isChildMessage'] ?? false)
                    ? (messageImage['id'] != null ? (messageImage['id'] ==  widget.message['id'] ? {} : messageImage) : {})
                    : {}
                  );
                }
                );
              },
              child: img["content_url"] == null
                ? Text("Message unavailable", style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13, fontWeight: FontWeight.w200))
                : img["content_url"].toString().toLowerCase().split(".").last == "mov" || img["content_url"].toString().toLowerCase().split(".").last == "mp4" ? VideoPlayer(att: img) : ImageItem(tag: tags[index], img: img, isThread: widget.isThread, isConversation: widget.isConversation)
            )
          );
        }).toList()
      )
    );
  }
}
class ImageItem extends StatefulWidget {
  const ImageItem({
    Key? key,
    required this.tag,
    this.img,
    this.previewComment = false,
    this.isThread,
    this.fromIssue = false,
    required this.isConversation
  }) : super(key: key);

  final tag;
  final img;
  final previewComment;
  final isThread;
  final fromIssue;
  final bool isConversation;

  @override
  State<ImageItem> createState() => _ImageItemState();
}

class _ImageItemState extends State<ImageItem> {
  bool failed = false;

  @override
  Widget build(BuildContext context) {
    var img = widget.img;
    final imageData = img["image_data"];
    double? height = (imageData != null && imageData["height"] != null) ? int.parse(imageData["height"].toString()).toDouble() : null;
    double? width = (imageData != null && imageData["width"] != null) ? int.parse(imageData["width"].toString()).toDouble() : null;
    int? cacheWidth = (imageData != null && imageData["width"] != null) ? int.parse(imageData["width"].toString()): null;
    // var cacheHeight = (imageData != null && imageData["height"] != null) ? imageData["height"] : null;
    // var ratio = (cacheWidth != null && cacheHeight != null) ? cacheWidth/cacheHeight : 1;

    return Hero(
      tag: widget.tag,
      child: Container(
        constraints: (widget.isThread != null && widget.isThread)
          ? BoxConstraints(maxHeight: 124, maxWidth: 220)
          : BoxConstraints(maxHeight: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4)
        ),
        height: widget.previewComment ? null : (height == null || height > 220) ? 220 : height,
        width: width,
        margin: EdgeInsets.only(top: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: failed && widget.previewComment ? InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (dialogContex)  {
                  return  CustomConfirmDialog(title: "Download attachment",
                    subtitle: "Do you want to download ${img["name"]}",
                    onConfirm: ()  async {
                      Provider.of<Work>(context, listen: false).addTaskDownload({"content_url": img["content_url"], 'name': img["name"],  "key_encrypt": img["key_encrypt"],});
                    }
                  );
                }
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              height: 160,
              width: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[600]!),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,  
                direction: Axis.vertical,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(CupertinoIcons.cloud_download, color: Colors.grey[600]),
                  Container(width: 140, margin: EdgeInsets.only(top: 4),child: Text(img["name"], style: TextStyle(color: Colors.grey[700]), overflow: TextOverflow.ellipsis))
                ],
              )
            )
          ) :
          widget.isConversation 
          ?  ImageDirect.build(context, img["content_url"])
          :  ExtendedImage.network(
            img["content_url"],
            fit: BoxFit.cover,
            cacheWidth: widget.previewComment ? 400 : cacheWidth == null ? 640 : cacheWidth > 640 ? 640 : cacheWidth,
            repeat: ImageRepeat.repeat,
            cache: true,
            filterQuality: FilterQuality.low,
            retries: 1,
            isAntiAlias: true,
            cacheMaxAge: Duration(days: 10),
            loadStateChanged: (ExtendedImageState state) {
              if (state.extendedImageLoadState == LoadState.loading) {
                return widget.previewComment ? Container(height: 180, width: 180) : Container(
                  height: (height != null && height > 220) ? 220 : height
                );
              } else if (state.extendedImageLoadState == LoadState.failed) {
                failed = true;
                return InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (dialogContex)  {
                        return CustomConfirmDialog(
                          title: "Download attachment",
                          subtitle: "Do you want to download ${img["name"]}",
                          onConfirm: ()  async {
                            var url = img["content_url"];
                            Provider.of<Work>(context, listen: false).addTaskDownload({"content_url": url, 'name': img["name"],  "key_encrypt": img["key_encrypt"],});
                          }
                        );
                      }
                    );
                  },
                  child: !widget.previewComment ? Text("Failed to load image") : InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContex)  {
                          return  CustomConfirmDialog(title: "Download attachment",
                            subtitle: "Do you want to download ${img["name"]}",
                            onConfirm: ()  async {
                              Provider.of<Work>(context, listen: false).addTaskDownload({"content_url": img["content_url"], 'name': img["name"],  "key_encrypt": img["key_encrypt"],});
                            }
                          );
                        }
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[600]!),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,  
                          direction: Axis.vertical,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(CupertinoIcons.cloud_download, color: Colors.grey[600]),
                            Container(width: 140, margin: EdgeInsets.only(top: 4),child: Text(img["name"], style: TextStyle(color: Colors.grey[700]), overflow: TextOverflow.ellipsis))
                          ]
                        )
                      )
                    )
                  )
                );
              }
            }
          )
        )
      )
    );
  }
}
class ImageThumnail extends StatelessWidget {
  final clickCallback;
  final isClick;
  final item;
  final bool isConversation;

  const ImageThumnail({Key? key, this.clickCallback, this.isClick, this.item, required this.isConversation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: clickCallback,
      child: Opacity(
        opacity: isClick ? 1 : 0.5,
        child: Container(
          margin: EdgeInsets.all(5),
          width: 50,
          height: 50,
          child: isConversation ? ImageDirect.build(context, item) : CachedImage(item, fit: BoxFit.cover, radius: 5, width: 10, height: 10,)
        ),
      ),
    );
  }
}
class Gallery extends StatefulWidget {
  const Gallery({
    Key? key,
    this.att,
    this.page,
    this.tags,
    this.onChangePage,
    this.isShowThread,
    this.onChangeIsShowThread,
    this.isChildMessage,
    required this.isConversation
  }) : super(key: key);

  final att;
  final page;
  final tags;
  final onChangePage;
  final isShowThread;
  final onChangeIsShowThread;
  final isChildMessage;
  final bool isConversation;

  @override
  _GalleryState createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> with TickerProviderStateMixin {
  int page = 0;
  double sliderValue = 100;
  var pageController;
  AnimationController? _controller;
  Animation<double>? animation;
  int rotateTime = 0;
  double x = 0;
  bool isRightHovered = false;
  bool isLeftHovered = false;
  bool hideCopied = true;
  bool showActionButton = false;
  int lastTime = 0;
  bool hoveredActionButton = false;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    onPointerHover();
    animation = Tween(begin: 0.0, end: 1.0).animate(_controller!);

    pageController = PageController(initialPage: widget.page);
    RawKeyboard.instance.addListener(handleEvent);
    super.initState();
  }

  handleEvent(RawKeyEvent event) {
    if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)){
      if (page < widget.att["data"].length - 1) {
        setState(() { page +=1; x = 0;});
        resetRotate();
        pageController.jumpToPage(page);
      }
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)){
      if (page > 0) {
        setState(() { page -=1; x = 0;});
        resetRotate();
        pageController.jumpToPage(page);
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _controller!.dispose();
    RawKeyboard.instance.removeListener(handleEvent);
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


  resetRotate() {
    animation = Tween<double>(begin: 0, end: 0).animate(_controller!);
    _controller!.forward();
  }

  onEntered(bool isHover, bool isRight) {
    if(isRight == true) {
      setState(() {
        this.isRightHovered = isHover;
      });
    } else{
      setState(() {
        this.isLeftHovered = isHover;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery?.of(context).size.height;
    final url = widget.att["data"][page]["content_url"];
    final name = widget.att["data"][page]["name"] ?? widget.att["data"][page]["filename"];
    final keyEncrypt =  widget.att["data"][page]["key_encrypt"] ?? "";
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Stack(
            children: [
              Listener(
                onPointerHover: (event) {
                  onPointerHover();
                  // print(mou);
                },
                child: RotationTransition(
                  turns: animation!,
                  child: ExtendedImageGesturePageView.builder(
                    itemBuilder: (BuildContext context, int index) {
                      var item = widget.att["data"][index]["content_url"];
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
                      Widget image = ExtendedImage.network(
                        item,
                        fit: BoxFit.contain,
                        cache: true,
                        initGestureConfigHandler: initGestureConfigHandler
                      );
                      image = Container(
                        child: image,
                        padding: EdgeInsets.all(5.0),
                      );
                      if (index == page) {
                        var tag = widget.tags[index];
                        return Hero(
                          tag: tag,
                          child: widget.isConversation ? ImageDirect.build(context, item, customBuild: (String localPath){
                            return ExtendedImage.file(
                              File(localPath),
                              fit: BoxFit.contain,
                              mode: ExtendedImageMode.gesture,
                              initGestureConfigHandler: initGestureConfigHandler
                            );
                          }) : image,
                        );
                      } else {
                        return widget.isConversation ? ImageDirect.build(context, item, customBuild: (String localPath){
                            return ExtendedImage.file(
                              File(localPath),
                              fit: BoxFit.contain,
                              mode: ExtendedImageMode.gesture,
                              initGestureConfigHandler: initGestureConfigHandler
                            );
                          }) : image;
                      }
                    },
                    itemCount: widget.att["data"].length,
                    onPageChanged: (int index) {
                      this.setState(() {
                        page = index;
                      });
                    },
                    controller: pageController,
                    scrollDirection: Axis.horizontal
                  )
                ),
              ),
              (page + 1 < widget.att["data"].length) ? Positioned(
                top: 0, right: 0,
                child: MouseRegion(
                  onEnter: (event) => onEntered(true, true),
                  onExit: (event) => onEntered(false, true),
                  child: Container(
                    color: isRightHovered ? Colors.black.withOpacity(0.2) : Colors.transparent,
                    child: InkWell(
                      focusNode: FocusNode(skipTraversal: true),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        resetRotate();
                        this.setState(() {
                          page +=1; x = 0;
                        });
                        if(page == widget.att["data"].length - 1) {
                          this.setState(() {
                            isRightHovered = false;
                          });
                        }
                        pageController.jumpToPage(page);
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 10),
                        height: deviceHeight,
                        child: Icon(
                          Icons.keyboard_arrow_right,
                          color: isRightHovered ? Colors.white : Colors.white.withOpacity(0.2),
                          size: 50,
                        ),
                      )
                    ),
                  ),
                )
              ) : Positioned(child: Container()),
              
              page > 0 ? Positioned(
                top: 0, left: 0,
                child: MouseRegion(
                  onEnter: (event) => onEntered(true, false),
                  onExit: (event) => onEntered(false, false),
                  child: Container(
                    color: isLeftHovered ? Colors.black.withOpacity(0.2) : Colors.transparent,
                    child: InkWell(
                      focusNode: FocusNode(skipTraversal: true),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        resetRotate();
                        this.setState(() {
                          page -=1; x = 0;
                        });
                        if(page == 0) {
                          setState(() {
                            isLeftHovered = false;
                          });
                        }
                        pageController.jumpToPage(page);
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 10),
                        height: deviceHeight,
                        child: Icon(
                          Icons.keyboard_arrow_left,
                          color: isLeftHovered ? Colors.white : Colors.white.withOpacity(0.2),
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                ),
              ) : Positioned(child: Container()),
              if(showActionButton) AnimatedPositioned(
                duration: Duration(milliseconds: 200),
                top: 0,
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
                    alignment: Alignment.centerRight,
                    width: constraints.maxWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if(hideCopied == false) Text("Image has been copied", style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w700, color: Color(0xff27AE60))),
                        widget.isChildMessage ?? false ? Container() : Container(
                          height: 50, width: 50,
                          child: HoverItem(
                            colorHover: Colors.grey.withOpacity(0.4),
                            child: InkWell(
                              focusNode: FocusNode(skipTraversal: true),
                              highlightColor: Color(0xff27AE60),
                              onTap: () {
                                widget.onChangeIsShowThread(!widget.isShowThread);
                              },
                              child: Icon(PhosphorIcons.chatCircleDots, size: 22, color: Colors.white)
                            ),
                          )
                        ),
                        Container(
                          height: 50,
                          width: 50,
                          child: HoverItem(
                            colorHover: Colors.grey.withOpacity(0.4),
                            child: InkWell(
                              focusNode: FocusNode(skipTraversal: true),
                              highlightColor: Color(0xff27AE60),
                              onTap: () async {
                                setState(() {
                                  hideCopied = false;
                                });
                                MethodChannel channel = MethodChannel("copy");
                                String urlImage = await ServiceMedia.getDownloadedPath(url) ?? url;
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
                              focusNode: FocusNode(skipTraversal: true),
                              highlightColor: Color(0xff27AE60),
                              onTap: () => Provider.of<Work>(context, listen: false).addTaskDownload({"content_url": url, "name": name,  "key_encrypt": keyEncrypt}),
                              child: Icon(Icons.file_download, size: 20, color: Color(0xFFFFFFFF))
                            ),
                          ),
                        ),
                        Container(
                          height: 50,
                          width: 50,
                          child: HoverItem(
                            colorHover: Colors.grey.withOpacity(0.4),
                            child: InkWell(
                              focusNode: FocusNode(skipTraversal: true),
                              highlightColor: Color(0xff27AE60),
                              onTap: () => Navigator.pop(context),
                              child: Icon(Icons.close_rounded, size: 24, color: Colors.white)
                            ),
                          )
                        )
                      ]
                    )
                  ),
                )
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
                    alignment: Alignment.center,
                    width: constraints.maxWidth,
                    child: Column(
                      children: [
                        Container(
                          height: 50,
                          child: Center(
                            child: ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.att["data"].length,
                              itemBuilder: (context, index) => ImageThumnail(isClick: page == index ? true : false, clickCallback: (){
                                setState(() {
                                  page = index;
                                  pageController.jumpToPage(page);
                                });
                              }, item: widget.att["data"][index]["content_url"],
                              isConversation: widget.isConversation
                              )
                            ),
                          )
                        ),
                        Row(
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
                                      focusNode: FocusNode(skipTraversal: true),
                                      onPressed: () => onRotateImage('left'),
                                      child: Icon(Icons.rotate_left, color: Color(0xFFFFFFFF)),
                                    ),
                                  ),
                                  Container(width: 50),
                                  Container(
                                    height: 50,
                                    width: 50,
                                    child: TextButton(
                                      focusNode: FocusNode(skipTraversal: true),
                                      onPressed: () => onRotateImage('right'),
                                      child: Icon(Icons.rotate_right, color: Color(0xFFFFFFFF)),
                                    ),
                                  ),
                                ]
                              )
                            )
                          ]
                        )
                      ]
                    )
                  ),
                )
              ),
            ]
          );
        }
      ),
    );
  }
}