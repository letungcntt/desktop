import 'dart:io';

// import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_macos_webview/flutter_macos_webview.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_confirm_dialog.dart';
import 'package:workcake/components/splash_screen.dart';
import 'package:workcake/media_conversation/model.dart' as MC;
import 'package:workcake/models/models.dart';

class VideoPlayer extends StatefulWidget {
  VideoPlayer({
    Key? key,
    this.att
  }) : super(key: key);

  final att;

  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  bool hover = false;
  bool hoverIcon = false;

  Future<void> openWebview(PresentationStyle presentationStyle) async {
    final userId = Provider.of<Auth>(context, listen: false).userId;
    var deviceWidth = MediaQuery.of(context).size.height*.9;
    var deviceHeight = MediaQuery.of(context).size.height*.6;
    deviceWidth = deviceWidth < 1280 ? 1280 : deviceWidth;
    deviceHeight = deviceHeight < 720 ? 720 : deviceHeight;
    var height;
    var width;

    try {
      var imageHeight = Utils.checkedTypeEmpty(widget.att["image_data"]) ? widget.att["image_data"]["height"].toDouble() : 480.toDouble();
      var imageWidth = Utils.checkedTypeEmpty(widget.att["image_data"]) ? widget.att["image_data"]["width"].toDouble() : 720.toDouble();

      height = imageHeight > 720 ? 720.0 : imageHeight > 480 ? imageHeight + 5.0 : 480.toDouble();
      width = imageWidth > 1280 ? 1280.0 : imageWidth > 720 ? imageWidth + 5.0 : 720.toDouble();
    } catch (e) {
      print("videoplayer error ${e.toString()}");
    }

    final webview = FlutterMacOSWebView(
      onWebResourceError: (err) {
        // print('Error: ${err.errorCode}, ${err.errorType}, ${err.domain}, ${err.description}');
      },
    );
    String? pathInDevice = await MC.ServiceMedia.getDownloadedPath(widget.att["content_url"]);
    if (Utils.checkedTypeEmpty(widget.att["key_encrypt"])){
      if (pathInDevice != null)
        // Process.runSync('open', [pathInDevice]);
        Process.runSync('open', [ '-a', 'QuickTime\ Player.app', pathInDevice]);
    } else {
      if(userId == '0c654807-b6cb-4389-b060-fdcb4372ab83' || userId == '773a8131-86d6-416f-918b-dc680b5c2084' || userId == 'b0df54ac-03f5-4110-b17c-29ef7c34d530')
        Process.runSync('open', [ '-a', 'QuickTime\ Player.app', widget.att["content_url"]]);
      else await webview.open(
        url: widget.att["content_url"],
        presentationStyle: presentationStyle,
        modalTitle: "${widget.att["name"]}",
        size: Size(width ?? deviceWidth, height ?? deviceHeight),
      );
    }
  }

  Widget thumbnailVideo() {
    final isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;
    return MouseRegion(
      onEnter: (value) {
        setState(() { hover = true; });
      },
      onExit: (value) {
        setState(() { hover = false; });
      },
      child: InkWell(
        onTap: () {
          openWebview(PresentationStyle.modal);
        },
        child: Container(
          width: 240,
          height: 240,
          margin: EdgeInsets.symmetric(vertical: 6),
          // padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: isDark ? Colors.grey[hover ? 300 : 400]! : hover ? Colors.grey[700]! : Colors.grey[600]!, width: 1),
            borderRadius: BorderRadius.circular(5)
          ),
          child: Stack(
            children: [
              Container(
                width: 240,
                height: 240,
                child: Image.network(widget.att["url_thumbnail"], fit: widget.att["image_data"]["height"] < widget.att["image_data"]["width"] ? BoxFit.fitWidth : BoxFit.fitHeight)),
              Center(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Center(child: Icon(CupertinoIcons.play_fill, color: Colors.white, size: 25))
                ),
              ),
              if (hover) Positioned(
                right: 2,
                top: 2,
                child: MouseRegion(
                  onEnter: (value) {
                    setState(() { hoverIcon = true; });
                  },
                  onExit: (value) {
                    setState(() { hoverIcon = false; });
                  },
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContex)  {
                          return CustomConfirmDialog(
                            title: "Download attachment",
                            subtitle: "Do you want to download ${widget.att["name"]}",
                            onConfirm: () async {
                              Provider.of<Work>(context, listen: false).addTaskDownload({"content_url": widget.att["content_url"], "name": widget.att["name"], "key_encrypt": widget.att["key_encrypt"],});
                            }
                          );
                        }
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        border: Border.all(color: Colors.grey[500]!, width: 1.2),
                        borderRadius: BorderRadius.circular(4)
                      ),
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      child: Icon(CupertinoIcons.cloud_download, color: hoverIcon ? Colors.blue : isDark ? Colors.grey[400]! : Colors.grey[600]!, size: 20)
                    )
                  )
                )
              )
            ]
          )
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;

   return widget.att["url_thumbnail"] != null ? thumbnailVideo() : MouseRegion(
      onEnter: (value) {
        setState(() { hover = true; });
      },
      onExit: (value) {
        setState(() { hover = false; });
      },
      child: InkWell(
        onTap: () {
          openWebview(PresentationStyle.modal);
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 6),
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? Colors.grey[hover ? 300 : 400]! : hover ? Colors.grey[700]! : Colors.grey[600]!, width: 1),
            borderRadius: BorderRadius.circular(10)
          ),
          child: Stack(
            children: [
              Wrap(
                children: [
                  Icon(CupertinoIcons.play_circle_fill, color: isDark ? Colors.grey[hover ? 300 : 400]! : hover ? Colors.grey[700]! : Colors.grey[600]!, size: 33),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${widget.att["name"]}", style: TextStyle(color: isDark ? Colors.grey[hover ? 300 : 400]! : hover ? Colors.grey[700]! : Colors.grey[600]!, fontSize: 15, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Wrap(
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text("Tap to play video", style: TextStyle(color: isDark ? Colors.grey[hover ? 300 : 400]! : hover ? Colors.grey[700]! : Colors.grey[600]!, fontSize: 11))
                            ]
                          )
                        ]
                      )
                    ]
                  )
                ]
              ),
              if (hover) Positioned(
                right: 0,
                bottom: 2,
                child: MouseRegion(
                  onEnter: (value) {
                    setState(() { hoverIcon = true; });
                  },
                  onExit: (value) {
                    setState(() { hoverIcon = false; });
                  },
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContex)  {
                          return CustomConfirmDialog(
                            title: "Download attachment",
                            subtitle: "Do you want to download ${widget.att["name"]}",
                            onConfirm: () async {
                              Provider.of<Work>(context, listen: false).addTaskDownload({"content_url": widget.att["content_url"], "name": widget.att["name"],  "key_encrypt": widget.att["key_encrypt"],});
                            }
                          );
                        }
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        border: Border.all(color: Colors.grey[500]!, width: 1.2),
                        borderRadius: BorderRadius.circular(4)
                      ),
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      child: Icon(CupertinoIcons.cloud_download, color: hoverIcon ? Colors.blue : isDark ? Colors.grey[400]! : Colors.grey[600]!, size: 20)
                    )
                  )
                )
              )
            ]
          )
        )
      )
    );
  }
}

class PlayerContainer extends StatefulWidget {
  const PlayerContainer({
    Key? key,
    required this.deviceHeight,
    required this.deviceWidth,
    required this.att
  }) : super(key: key);

  final double deviceHeight;
  final double deviceWidth;
  final att;

  @override
  State<PlayerContainer> createState() => _PlayerContainerState();
}

class _PlayerContainerState extends State<PlayerContainer> {
  // Player? player;
  bool init = false;

  @override
  void initState() { 
    super.initState();
    // player = Player(id: 0);
    // Playlist playlist = new Playlist(medias: [
    //   Media.network("${widget.att["content_url"]}")
    // ]);
    // player!.currentStream.listen((current) {
    //   if (current.media != null) {
    //     setState(() {
    //       init = true;
    //     });
    //   }
    // });
    // player!.open(playlist, autoStart: true);
  }

  @override
  void dispose() {
    // player!.remove(0); 
    // player!.stop();
    // player!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
    // return !init || player == null ? Container(width: widget.deviceWidth - 40, height: widget.deviceHeight - 60, child: Center(child: SplashScreen())) : Video(
    //   player: player,
    //   height: widget.deviceHeight - 60,
    //   width: widget.deviceWidth - 40,
    //   volumeThumbColor: Colors.blue,
    //   volumeActiveColor: Colors.blue,
    //   // playlistLength: 1,
    // );
  }
}