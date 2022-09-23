// ignore_for_file: dead_code

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/drop_zone.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/flutter_mention/custom_selection.dart';
import 'package:workcake/flutter_mention/custom_text_field.dart';
import 'package:workcake/services/queue.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/workspaces/apps/zimbra/config.dart';
import 'package:workcake/workspaces/apps/zimbra/conv.dart';
import 'package:workcake/workspaces/apps/zimbra/forward.dart';
import 'package:workcake/workspaces/apps/zimbra/service.dart';

class ReplyMessageMailZimbra extends StatefulWidget {
  final MessageConvZimbra messageMail;
  final String type;
  final int workspaceId;
  final List<Map>? cc;

  ReplyMessageMailZimbra({Key? key, required  this.messageMail, required this.workspaceId, required this.type, this.cc}) : super(key: key);

  @override
  State<ReplyMessageMailZimbra> createState() => _ReplyMessageMailZimbraState();
}

class _ReplyMessageMailZimbraState extends State<ReplyMessageMailZimbra> {
  String content = "";
  bool sending = false;
  List<Map> fileSelected = [];
  TextEditingController contentController = TextEditingController();
  Scheduler queueSaveDraft = Scheduler();

  @override
  void initState(){
    super.initState();
    Timer.run(() async {
      try {
        LazyBox box = Hive.lazyBox("pairKey");
        Map? result = await box.get("zimbra_${widget.workspaceId}");
        Map data = (result ?? {})["reply_${ConfigZimbra.instance.currentAccountZimbra?.email}_${widget.messageMail.id}"] ?? {};
        content = data["content"] ?? "";
        fileSelected =((data["file_selected"] ?? []) as List).map((e) => e as Map).toList();
        contentController.text = content;
        setState(() {

        });
      } catch (e, t) {
        print("init :$e, $t");
      }
    });
  }

  // id  == null => chua upload
  // id = -1 => upload that bai
  processFiles(List<String> data) async {
    try {
      if (data.length == 0) return;
      // uniq path
      fileSelected += data.map<Map?>((e) {
        var index =  fileSelected.indexWhere((element) => element["path"] == e);
        if (index != -1) return null;
        return {
          "path": e,
          "id_uploaded": null
        };
      }).toList().whereType<Map>().toList();
      fileSelected = await Future.wait(fileSelected.map((e) async {
        if (e["id_uploaded"] != null) return e;
        String? idUploaded = await ServiceZimbra.uploadFile(e["path"]);
        e["id_uploaded"] = idUploaded == null ? -1 : idUploaded;
         return e;
      }));
      queueSaveDraft.scheduleOne(() => ServiceZimbra.saveDraft(fileSelected, [], "", content, "", "reply", widget.messageMail, widget.workspaceId), timeDelay:  2);
      setState(() {
      });
    } catch (e, t) {
      print("processFiles, $e, $t");
    }
  }

  removeFileSelectedItem(Map data){
    fileSelected = fileSelected.where((ele) => ele["path"] != data["path"] && ele["id_uploaded"] != data["id_uploaded"]).toList();
    ServiceZimbra.saveDraft(fileSelected, [], "", content, "", "reply", widget.messageMail, widget.workspaceId);
    setState(() {});
  }

  openFileSelector() async {
    try {
      var files = await Utils.openFilePicker([]);
      processFiles(files.map<String>((ele) => ele["path"] as String).toList());
    } on Exception catch (e) {
      print("$e Cancel");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = false && Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        color:  isDark ? Color(0xFF2e2e2e) : Color(0xFFffffff),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom:  BorderSide(width: 1, color: isDark ? Color(0xFF5e5e5e) : Color(0xFFdbdbdb))
                )
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color:  isDark ? Color(0xFF4c4c4c) : Color.fromARGB(255, 208, 208, 208),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                    ),
                    padding: EdgeInsets.only(left: 16),
                    alignment: Alignment.centerLeft,
                    child: Text("Answer mail", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDark ? Color(0xFFffffff): Color(0xFF5e5e5e)))
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 24),
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom:  BorderSide(width: 1, color: isDark ? Color(0xFF5e5e5e) : Color(0xFFdbdbdb))
                      )
                    ),
                    child: Row(
                      children: [
                        Text("Send :", style: TextStyle(color: isDark ? Color(0xFFDBDBDB) : Color(0xFF828282), fontSize: 14, fontWeight: FontWeight.w500)),
                        Container(width: 8),
                        RenderSelectedEmail(
                          email: widget.messageMail.from!.address,
                          isDark: isDark,
                          name: widget.messageMail.from!.partName ?? widget.messageMail.from!.displayName ?? widget.messageMail.from!.address.split("@").first, 
                          onSelectEmail: () {
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 24),
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom:  BorderSide(width: 1, color: isDark ? Color(0xFF5e5e5e) : Color(0xFFdbdbdb))
                      )
                    ),
                    child: Row(
                      children: [
                        Text("CC :", style: TextStyle(color: isDark ? Color(0xFFDBDBDB) : Color(0xFF828282), fontSize: 14, fontWeight: FontWeight.w500)),
                        Container(width: 8),
                        Container(

                          child: Wrap(
                            children: (widget.cc ?? []).map((e) => RenderSelectedEmail(
                              email: e["address"] ?? "", 
                              isDark: isDark,
                              name: e["part_name"] ?? e["display_name"] ?? e["address"].split("@").first, 
                              onSelectEmail: () { },
                            )).toList(),
                          )
                          // child: Row(
                          //   children: [
                          //     CachedAvatar("", name: widget.messageMail.from!.partName, width: 24, height: 24),
                          //     Container(width: 8),
                          //     Text("${widget.messageMail.from!.partName}", style: TextStyle(color: isDark ? Color(0xFFDBDBDB) : Color(0xFF5e5e5e), fontSize: 14, fontWeight: FontWeight.w500)),
                          //     Container(width: 14),
                          //     Icon(PhosphorIcons.x, size: 10, color: isDark ? Color(0xFFDBDBDB) : Color(0xFF5e5e5e),)
                          //   ],
                          // ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 24),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom:  BorderSide(width: 1, color: isDark ? Color(0xFF5e5e5e) : Color(0xFFdbdbdb))
                      )
                  ),
                    child: Row(
                      children: [
                        Text("Topic :", style: TextStyle(color: isDark ? Color(0xFFDBDBDB) : Color(0xFF828282), fontSize: 14, fontWeight: FontWeight.w500)),
                        Container(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                            // color: Color(0xFF5e5e5e)
                          ),
                          child: Text(widget.messageMail.subject.startsWith("Re") ? widget.messageMail.subject : "Re: ${widget.messageMail.subject}", style: TextStyle(color: isDark ? Color(0xFFDBDBDB) : Color(0xFF828282), fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 24),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      border: Border(
                        // bottom:  BorderSide(width: 1, color: Color(0xFF5e5e5e))
                      )
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 4),
                          child: Text("Content :", style: TextStyle(color: isDark ? Color(0xFFDBDBDB) : Color(0xFF828282), fontSize: 14, fontWeight: FontWeight.w500))),
                        Container(width: 8),
                        DropZone(
                          initialData: [],
                          stream: StreamDropzone.instance.dropped,
                          // onHighlightBox: (value) { setState(() { onHighlight = value; }); },
                          builder: (context, files) {
                            List<String> paths = files.data.map<String>((file) => file["path"].toString()).toList();
                            processFiles(paths);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width - 500,
                                  child: Wrap(
                                    alignment: WrapAlignment.start,
                                    crossAxisAlignment: WrapCrossAlignment.start,
                                    children: fileSelected.map((e) {
                                      return Container(
                                        margin: EdgeInsets.only(right: 8, bottom: 4, top: 4),
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(Radius.circular(16)),

                                          border:  Border.all(width: 1, color: e["id_uploaded"] == -1 ? Color(0xFFff4d4f) : Color(0xFF5e5e5e))
                                        ),
                                        child: Wrap(
                                          //  alignment: WrapAlignment.start,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Text("${e["id_uploaded"] == null ? 'Uploading' : e["id_uploaded"] == -1 ? 'Upload fail' :  ''} ${e["path"].split('/').last}", style: TextStyle(color:  isDark ? Color(0xFFDBDBDB) : Color(0xFF5e5e5e))),
                                            Container(width: 8,),
                                            GestureDetector(
                                              onTap: (){
                                                removeFileSelectedItem(e);
                                              },
                                              child: HoverItem(child: Icon(PhosphorIcons.x, size: 10, color: isDark ? Color(0xFFDBDBDB) : Color(0xFF5e5e5e),)))
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(4)),
                                  ),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width  - 450, height: 210,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: openFileSelector,
                                          child: HoverItem(
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              margin: EdgeInsets.only(bottom: 8),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(Radius.circular(16)),

                                                border:  Border.all(width: 1, color: Color(0xFF5e5e5e))
                                              ),
                                              child:  Wrap(
                                                children: [
                                                  Icon(PhosphorIcons.file, color: isDark ? Color(0xFFDBDBDB): Color(0xFF5e5e5e), size: 15),
                                                  Text(" Attach files here", style: TextStyle(color: isDark ? Color(0xFFDBDBDB): Color(0xFF5e5e5e))),
                                                ],
                                              )
                                            ),
                                          ),
                                        ),
                                        CustomTextField(
                                          onChanged: (String text){
                                            content = text;
                                            queueSaveDraft.scheduleOne(() => ServiceZimbra.saveDraft(fileSelected, [], "", content, "", "reply", widget.messageMail, widget.workspaceId), timeDelay:  2);
                                          },
                                          controller: contentController,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            isDense: true,
                                            enabledBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                            contentPadding: const EdgeInsets.only(left: 5, bottom: 10, top: 5),
                                            hintText: "Enter content or drop files here...",
                                            hintStyle: TextStyle(color: Color(0xff9AA5B1), fontSize: 13.5, height: 1)
                                          ),
                                          maxLines: 10,
                                          style: TextStyle(fontSize: 14, color: Color(0xFF5e5e5e)),
                                        ),
                                      ],
                                    )
                                  )
                                ),
                              ],
                            );
                          }
                        ),

                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical:24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(),
                        GestureDetector(
                          onTap: () async {
                            if (sending) return;
                            setState(() {
                              sending = true;
                            });
                            if (await ServiceZimbra.replyMessage(widget.messageMail, "r", content, fileSelected, widget.cc)){
                              ServiceZimbra.deleteDraft(widget.workspaceId, "reply", parentMessageId: widget.messageMail.id);
                              Navigator.pop(context);
                            }
                            setState(() {
                              sending = false;
                            });
                          },
                          child: HoverItem(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                                color: Color(0xff1890ff),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                              child: Text(sending ? "Sending" : "Send", style: TextStyle(color: Color(0xffffffff))))
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            CustomSelectionArea(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 16),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "On ${DateFormatter().renderTime(DateTime.fromMicrosecondsSinceEpoch(widget.messageMail.currentTime * 1000), type: "yMMMMd")}, ${widget.messageMail.from?.displayName} wrote:",
                          style: TextStyle(color: Color(0xFFFAAD14), fontSize: 13)
                        ),
                      ),
                    ),
                    RenderMessageConv(messConv: widget.messageMail, workspaceId: widget.workspaceId,)
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}