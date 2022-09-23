import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_confirm_dialog.dart';
import 'package:workcake/components/widget_text.dart';
import 'package:workcake/media_conversation/model.dart' as MC;
import 'package:workcake/providers/providers.dart';

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

  Widget buttonDownload() {
    return ButtonAction(
      icon: CupertinoIcons.cloud_download,
      onTap: () {
        showDialog(
          context: context,
          builder: (dialogContex)  {
            return CustomConfirmDialog(
              title: "Download attachment",
              subtitle: "Do you want to download ${widget.att["name"]}",
              onConfirm: () async {
                Provider.of<Work>(context, listen: false).addTaskDownload({"content_url": widget.att["content_url"], "name": widget.att["name"],  "key_encrypt": widget.att["key_encrypt"], "version": widget.att["version"]});
              }
            );
          }
        );
      },
    );
  }

  Widget buttonCopyLink() {
    return ButtonAction(
      icon: PhosphorIcons.copyFill,
      onTap: () => Clipboard.setData(new ClipboardData(text: widget.att["content_url"])),
    );
  }

  Widget thumbnailVideo() {
    final isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;
    return MouseRegion(
      onEnter: (value) => setState(() => hover = true),
      onExit: (value) => setState(() => hover = false),
      child: InkWell(
        onTap: openPlayer,
        child: Container(
          width: 240, height: 240,
          margin: EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: isDark ? Colors.grey[hover ? 300 : 400]! : hover ? Colors.grey[700]! : Colors.grey[600]!, width: 1),
            borderRadius: BorderRadius.circular(5)
          ),
          child: Stack(
            children: [
              Container(
                width: 240, height: 240,
                child: Image.network(widget.att["url_thumbnail"], fit: widget.att["image_data"]["height"] < widget.att["image_data"]["width"] ? BoxFit.fitWidth : BoxFit.fitHeight)
              ),
              Center(
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(child: Icon(CupertinoIcons.play_fill, color: Colors.white, size: 26))
                ),
              ),
              if (hover) Positioned(
                right: 2, top: 2,
                child: buttonDownload()
              ),
              if (hover) Positioned(
                right: 2, top: 40,
                child: buttonCopyLink()
              )
            ]
          )
        )
      )
    );
  }

  openPlayer() async {
    try{
      String? pathInDevice = await MC.ServiceMedia.getDownloadedPath(widget.att["content_url"]);
      if (Utils.checkedTypeEmpty(widget.att["key_encrypt"]) && widget.att["key_encrypt"].length > 30){
        if (pathInDevice != null)
          Utils.isWinOrLinux()
          ? Process.runSync('start', ['/d', '%ProgramFiles(x86)%\Windows Media Player', 'wmplayer.exe', pathInDevice], runInShell: true)
          : Process.runSync('open', [ '-a', 'QuickTime\ Player.app', pathInDevice]);
      } else {
        Utils.isWinOrLinux()
        ? Process.runSync('start', ['/d', '%ProgramFiles(x86)%\Windows Media Player', 'wmplayer.exe', widget.att["content_url"]], runInShell: true)
        : Process.runSync('open', [ '-a', 'QuickTime\ Player.app', widget.att["content_url"]]);
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;

    return widget.att["url_thumbnail"] != null ? thumbnailVideo() : MouseRegion(
      onEnter: (value) => setState(() => hover = true),
      onExit: (value) => setState(() => hover = false),
      child: InkWell(
        onTap: openPlayer,
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
                      TextWidget("${widget.att["name"]}", style: TextStyle(color: isDark ? Colors.grey[hover ? 300 : 400]! : hover ? Colors.grey[700]! : Colors.grey[600]!, fontSize: 15, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Wrap(
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              TextWidget("Tap to play video", style: TextStyle(color: isDark ? Colors.grey[hover ? 300 : 400]! : hover ? Colors.grey[700]! : Colors.grey[600]!, fontSize: 11))
                            ]
                          )
                        ]
                      )
                    ]
                  )
                ]
              ),
              if (hover) Positioned(
                right: 0, bottom: 2,
                child: buttonDownload()
              ),
              if (hover) Positioned(
                right: 40, bottom: 2,
                child: buttonCopyLink()
              )
            ]
          )
        )
      )
    );
  }
}

class ButtonAction extends StatefulWidget {
  ButtonAction({
    Key? key,
    required this.icon,
    this.onTap
  }) : super(key: key);

  final IconData icon;
  final Function? onTap;

  @override
  _ButtonActionState createState() => _ButtonActionState();
}

class _ButtonActionState extends State<ButtonAction> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;

    return InkWell(
      onTap: () {
        if(widget.onTap != null) widget.onTap!();
      },
      child: MouseRegion(
        onEnter: (value) => setState(() => hover = true),
        onExit: (value) => setState(() => hover = false),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Palette.defaultTextDark,
            border: Border.all(color: Colors.grey[500]!, width: 1.2),
            borderRadius: BorderRadius.circular(4)
          ),
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Icon(widget.icon, color: hover ? Colors.blue : isDark ? Colors.grey[400]! : Colors.grey[600]!, size: 20)
        )
      ),
    );
  }
}