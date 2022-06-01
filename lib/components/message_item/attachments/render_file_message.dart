import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/models/models.dart';

import 'attachments.dart';

class RenderFile extends StatefulWidget {
  const RenderFile({ Key? key, @required this.att, this.isDark }) : super(key: key);

  final att;
  final isDark;

  @override
  State<RenderFile> createState() => _RenderFileState();
}

class _RenderFileState extends State<RenderFile> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    final att = widget.att;
    final isDark = widget.isDark;
    final urlSplit = att["content_url"].toString().split(".").last.toUpperCase();

    return Container(
        margin: EdgeInsets.only(top: 5, bottom: 5),
        child: InkWell(
          onHover: (e) => setState(() => isHover = e),
          mouseCursor: att['mime_type'] == 'pdf' ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onTap: () {
            if(att['mime_type'] != 'pdf') return;

            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  contentPadding: EdgeInsets.zero,
                  content: Container(
                    width: 820, height: 1000,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? Color(0xff1E1E1E) : Color(0xffDBDBDB),
                            border: Border(
                              bottom: BorderSide(color: Theme.of(context).dividerColor)
                            )
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  att['name'],
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.grey[800]
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ListAction(
                                    action: 'Download file',
                                    isDark: isDark,
                                    child: IconButton(
                                      hoverColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onPressed: () {
                                        final url = att['content_url'];
                                        Provider.of<Work>(context, listen: false).addTaskDownload({'content_url': url, 'name': att['name'],  "key_encrypt": widget.att["key_encrypt"],});
                                        Navigator.pop(context);
                                      },
                                      icon: Icon(
                                        PhosphorIcons.downloadSimple,
                                        size: 20.0,
                                        color: isDark ? Colors.white70 : Colors.grey[800],
                                      )
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: Icon(
                                      PhosphorIcons.xCircle, size: 20,
                                      color: isDark ? Colors.white70 : Colors.grey[800],
                                    ),
                                  )
                                ],
                              )
                            ],
                          )
                        ),
                        Expanded(
                          child: SfPdfViewer.network(
                            att['content_url'],
                            initialZoomLevel: 1.35,
                            onZoomLevelChanged: (PdfZoomDetails zoomDetails) { },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            );
          },
          child: Container(
            constraints: BoxConstraints(maxWidth: 330, minWidth: 250, maxHeight: 68),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Color(0X55D1D2D3)
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Container(
                        child: Icon(CupertinoIcons.doc_fill, size: 30.0, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight)
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                att["name"] ?? "",
                                style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15
                                )
                              ),
                              SizedBox(height: 2),
                              Text(
                                "$urlSplit file",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Palette.defaultTextDark.withOpacity(0.7) : Palette.defaultTextLight,
                                  fontWeight: FontWeight.w300
                                )
                              )
                            ]
                          )
                        )
                      )
                    ]
                  )
                ),
                if (isHover) Container(
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
                    border: Border.all(
                      color: isDark ? Color(0xff5E5E5E) : Color(0xffA6A6A6),
                      width: 0.5
                    )
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onPressed: () {
                      final url = att["content_url"];
                      Provider.of<Work>(context, listen: false).addTaskDownload({"content_url": url, 'name': att["name"],  "key_encrypt": widget.att["key_encrypt"],});
                    },
                    icon: Icon(CupertinoIcons.cloud_download, size: 15, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282))
                    // icon: SvgPicture.asset('assets/icons/Pushpin.svg', color: isDark ? Color(0xffA6A6A6) : Color(0xff828282))
                  )
                )
              ]
            )
          )
        )
    );
  }
}