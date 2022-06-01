import 'dart:async';
import 'dart:io';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/media_conversation/dm_media.dart';
import 'package:workcake/media_conversation/model.dart';
import 'package:workcake/models/models.dart';

class RenderMedia extends StatefulWidget {
  final String id;
  final ValueChanged<String> onChanged;

  const RenderMedia({
    Key? key,
    required this.id,
    required this.onChanged
  }) : super(key: key);

  @override
  State<RenderMedia> createState() => _RenderMediaState();
}

class _RenderMediaState extends State<RenderMedia> {
  List<MediaConversation> data =[];
  int totalImages = 0;
  int totalFiles = 0;
  Map<String, List<MediaConversation>> dataMedia = {
    "image": [],
    "file": []
  };

  @override
  void didUpdateWidget(oldWidget){
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id){
      resetData();
      getDataType('file');
      getDataType('image');
    }
  }


  @override
  void initState(){
    super.initState();
    Timer.run(() async{
      resetData();
    });
  }

  resetData() async {
      var id  =  widget.id;
      dataMedia = {
        "image": [],
        "file": []
      };
      totalImages =  0;
      totalFiles = 0;
      Map d = await ServiceMedia.getNumberOfConversation(widget.id);
      getDataType('file');
      getDataType('image');
      if (widget.id != id) return;
      setState(() {
        totalImages = d["images"];
        totalFiles = d["files"];
      });
  }


  getDataType(String type) async {
    var id  =  widget.id;
    List<MediaConversation> t = (await ServiceMedia.loadConversationMedia(widget.id, 8, getLastCurrentTimeOfType(type), type))["data"];
    if (widget.id != id) return;
    
    setState(() {
      dataMedia[type] = t;
    });
  }

  int getLastCurrentTimeOfType(String type){
    try {
      return dataMedia[type]!.last.currentTime;
    } catch (e) {
      return DateTime.now().microsecondsSinceEpoch;
    }
  }

  Widget renderListItem(String type, List data, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 14.5, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                    ),
                    children: [
                      WidgetSpan(
                        child: Container(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            type == 'file' ? PhosphorIcons.filesThin : PhosphorIcons.imageSquareThin,
                            color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, size: 22
                          ),
                        )
                      ),
                      TextSpan(
                        text: type == 'file' ? 'Files' :'Photo/Video'
                      ),
                      TextSpan(
                        text: ' (${type == 'file' ? totalFiles : totalImages})',
                        style: TextStyle(fontSize: 12)
                      ),
                    ]
                  )
                ),
                HoverItem(
                  colorHover: data.length > 0 ? Palette.hoverColorDefault : null, radius: 4.0, isRound: true,
                  child: InkWell(
                    onTap: data.length > 0 ? () => widget.onChanged(type) : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        'View all',
                        style: TextStyle(fontSize: 12.5, color: Color(0xff838383)),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          data.length == 0 ? Container(
            padding: EdgeInsets.symmetric(horizontal: 44, vertical: 22),
            decoration: BoxDecoration(
              color: isDark ? Palette.backgroundRightSiderDark : Palette.topicTile,
              borderRadius: BorderRadius.all(Radius.circular(2))
            ),
            child: Text(
              'No file is shared in this conversation',
              style: TextStyle(
                color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                fontSize: 13.5
              ),
              textAlign: TextAlign.center,
            ),
          ) : Container(
            height: data.length >= 5 ? 146 : (data.length >= 1 ? 70 : 0),
            child: GridView.builder(
              controller: ScrollController(),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 75,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: data.length >= 8 ? 8 : data.length,
              itemBuilder: (BuildContext context, int indexItem) {
                final entry = data[indexItem]; final e = entry.value;
                final index = entry.key;
                final String type = Utils.getLanguageFile(e.media.target!.type);
                bool isVideo = false;
                PhosphorIconData icon = PhosphorIcons.files;

                switch (type.toLowerCase()) {
                  case 'mov':
                  case 'mp4':
                  case 'flv':
                  case 'avi':
                    isVideo = true;
                    icon = PhosphorIcons.fileVideo;
                    break;
                  case 'js': 
                  case 'ts':
                  case 'dart':
                  case 'ex':
                  case 'c':
                  case 'sql':
                  case 'json':
                  case 'txt':
                  case 'text':
                    icon = PhosphorIcons.fileText;
                    break;
                  default:
                }

                return e.media.target!.status == 'downloaded' ? HoverItem(
                  colorHover: isDark ? Palette.calendulaGold : Palette.dayBlue,
                  isRound: type != 'image', radius: 4.0,
                  child: (type == 'image' ? InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            barrierDismissible: true,
                            barrierLabel: '',
                            opaque: false,
                            barrierColor: Colors.black.withOpacity(1.0),
                            pageBuilder: (context, _, __) => Scaffold(
                              backgroundColor: Colors.transparent,
                              body: ImageViewer(listImage: dataMedia['image'] ?? [], index: index),
                            )
                          )
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.all(1.75),
                        child: ExtendedImage.file(
                          File(e.media.target!.pathInDevice ?? ""),
                          fit: BoxFit.cover,
                          clearMemoryCacheWhenDispose: true
                        ),
                      ),
                    ) : InkWell(
                      onTap: () {
                        try {
                          if (isVideo) {
                            Process.runSync('open', [e.media.target!.pathInDevice ?? ""]);
                          } else {
                            Process.runSync('open', ['-R', e.media.target!.pathInDevice ?? ""]);
                          }
                        } catch (e) {}
                      },
                      child: Container(
                        width: 44, height: 44,
                        margin: EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xFF3d3d3d) : Color(0xFFbfbfbf),
                          borderRadius: BorderRadius.all(Radius.circular(4))
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              size: 22.0, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight
                            ),
                            SizedBox(height: 2),
                            Text(
                              (e.media.target?.type ?? "").toString().toUpperCase(),
                              style: TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w500, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ),
                ) : Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.transparent.withOpacity(isDark ? 0.45 : 0.2),
                    borderRadius: BorderRadius.all(Radius.circular(4))
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Has deleted', style: TextStyle(
                      fontWeight: FontWeight.w500, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 12
                    ),
                    textAlign: TextAlign.center,
                  )
                );
              }
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    List dataImages = (dataMedia['image'] ?? []).asMap().entries.toList();
    List dataFiles = (dataMedia['file'] ?? []).asMap().entries.toList();

    return Column(
      children: [
        SizedBox(height: 10),
        renderListItem('image', dataImages, isDark),
        SizedBox(height: 20),
        renderListItem('file', dataFiles, isDark),
        SizedBox(height: 10),
      ],
    );
  }
}