// ignore_for_file: dead_code

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/cache_avatar.dart';
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
import 'package:workcake/workspaces/apps/zimbra/service.dart';

class ForwardMessageMailZimbra extends StatefulWidget {
  final MessageConvZimbra messageMail;
  final int workspaceId;

  ForwardMessageMailZimbra({Key? key, required  this.messageMail, required this.workspaceId}) : super(key: key);

  @override
  State<ForwardMessageMailZimbra> createState() => _ForwardMessageMailZimbraState();
}

class _ForwardMessageMailZimbraState extends State<ForwardMessageMailZimbra> {
  String content = "";
  String to = "";
  bool sending = false;
  late FocusNode toFocus;
  List<Map> selectedEmailToSend = [];
  TextEditingController controllerText = TextEditingController();
  List<Map> fileSelected = [];
  TextEditingController contentController = TextEditingController();
  Scheduler queueSaveDraft = Scheduler();
  final streamSelectedIndex = StreamController<int>.broadcast(sync: false);
  int indexSelected = 0;
  List autoComplete =[];
  late ScrollController controllerScroll;

  @override
  void initState(){
    super.initState();
    controllerScroll = ScrollController();
    toFocus = new FocusNode(onKey: (FocusNode node, RawKeyEvent keyEvent)  {
      if (keyEvent is RawKeyDownEvent)
        if (keyEvent.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
          indexSelected = indexSelected + 1;
          if (indexSelected > autoComplete.length -1) indexSelected = autoComplete.length -1;
           afterHandleArrow();
          return KeyEventResult.handled;    
        }
        if (keyEvent.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
          indexSelected = indexSelected - 1;
          if (indexSelected < 0) indexSelected = 0;
          afterHandleArrow();
         
          return KeyEventResult.handled;    
        }
        if (keyEvent.isKeyPressed(LogicalKeyboardKey.enter)) {
          try {
            onSelectEmail(autoComplete[indexSelected]);
            ServiceZimbra.autoCompleteController.add([]);
            return KeyEventResult.handled;   
          } catch (e) {
            return KeyEventResult.ignored;
          } 
        }
      return KeyEventResult.ignored;

    });

    Timer.run(() async {
      try {
        LazyBox box = Hive.lazyBox("pairKey");
        Map? result = await box.get("zimbra_${widget.workspaceId}");
        Map data = (result ?? {})["forward_${ConfigZimbra.instance.currentAccountZimbra?.email}_${widget.messageMail.id}"] ?? {};
        content = data["content"] ?? "";
        to = data["to"] ?? "";
        selectedEmailToSend = ((data["selected_email_to_send"] ?? []) as List).map((e) => e as Map).toList();
        fileSelected =((data["file_selected"] ?? []) as List).map((e) => e as Map).toList();
        contentController.text = content;
        controllerText.text = to;
        setState(() {

        });
      } catch (e, t) {
        print("init :$e, $t");
      }
    });

    toFocus.addListener(() async {
      await Future.delayed(Duration(milliseconds: 300));
      setState(() {});
      if (toFocus.hasFocus){
        ServiceZimbra.autoComplete(to);
      }
    });
  }

  afterHandleArrow(){
    streamSelectedIndex.add(indexSelected);
    var offset = indexSelected * 60.0;
    if (offset > controllerScroll.position.maxScrollExtent) offset = controllerScroll.position.maxScrollExtent;
    else if (offset < 100) offset = 0.0;
    else offset = offset - 100;
    controllerScroll.animateTo(offset , duration: Duration(milliseconds: 100), curve: Curves.easeIn);
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
      ServiceZimbra.saveDraft(fileSelected, selectedEmailToSend, to, content, "", "forward", widget.messageMail, widget.workspaceId);
      setState(() {
      });
    } catch (e, t) {
      print("processFiles, $e, $t");
    }
  }

  removeFileSelectedItem(Map data){
    fileSelected = fileSelected.where((ele) => ele["path"] != data["path"] && ele["id_uploaded"] != data["id_uploaded"]).toList();
    ServiceZimbra.saveDraft(fileSelected, selectedEmailToSend, to, content, "", "forward", widget.messageMail, widget.workspaceId);
    setState(() {});
  }

  onSelectEmail(Map e) {
    int index =  selectedEmailToSend.indexWhere((element) => element["email"] == e["email"]);
    if (index == -1) {
      controllerText.clear();
      selectedEmailToSend += [e];
    }
    else selectedEmailToSend.removeAt(index);
    ServiceZimbra.saveDraft(fileSelected, selectedEmailToSend, to, content, "", "forward", widget.messageMail, widget.workspaceId);
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
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            color: isDark ? Color(0xFF2e2e2e) : Color(0xFFffffff),
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
                          color: isDark ? Color(0xFF4c4c4c) : Color.fromARGB(255, 208, 208, 208),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                        ),
                        padding: EdgeInsets.only(left: 16),
                        alignment: Alignment.centerLeft,
                        child: Text("Forward mail", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDark ? Color(0xFFffffff): Color(0xFF5e5e5e)))
                      ),
                      Container(
                        height: 55,
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
                            Container(
                              child: Row(
                                children: selectedEmailToSend.map((e) => RenderSelectedEmail(
                                  email: e["email"] ?? "", 
                                  isDark: isDark,
                                  name: e["name"] ?? '', 
                                  onSelectEmail: () {
                                    onSelectEmail(e);
                                  },
                                )).toList(),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                // width: MediaQuery.of(context).size.width * 0.8,
                                padding: EdgeInsets.only(top: 5),
                                child: Wrap(
                                  children: [
                                    CustomTextField(
                                      controller: controllerText,
                                      onChanged: (String text){
                                        to = text;
                                        indexSelected = 0;
                                        streamSelectedIndex.add(0);
                                        ServiceZimbra.autoComplete(text);
                                        queueSaveDraft.scheduleOne(() => ServiceZimbra.saveDraft(fileSelected, selectedEmailToSend, to, content, "", "forward", widget.messageMail, widget.workspaceId), timeDelay: 2);
                                      },
                                      style: TextStyle(fontSize: 14, color: Color(0xFF5e5e5e)),
                                      focusNode: toFocus,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        isDense: true,
                                        enabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        contentPadding: const EdgeInsets.only(left: 5, bottom: 10, top: 5),
                                        hintText: "To ...                                                   ",
                                        hintStyle: TextStyle(color:  const Color(0xff9AA5B1), fontSize: 13.5, height: 1)
                                      ),
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
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
                              child: Text(widget.messageMail.subject.startsWith("Fw") ? widget.messageMail.subject : "Fw: ${widget.messageMail.subject}", style: TextStyle(color: isDark ? Color(0xFFDBDBDB) : Color(0xFF5e5e5e), fontSize: 14, fontWeight: FontWeight.w500)),
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

                                              border: Border.all(width: 1, color: e["id_uploaded"] == -1 ? Color(0xFFff4d4f) : e["id_uploaded"] == null ? Color(0xFFfafafa) : Color(0xFF5e5e5e))
                                            ),
                                            child: Wrap(
                                              //  alignment: WrapAlignment.start,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                Text("${e["id_uploaded"] == null ? 'Uploading' : e["id_uploaded"] == -1 ? 'Upload fail' :  ''} ${e["path"].split('/').last}", style: TextStyle(color: isDark ? Color(0xFFDBDBDB) : Color(0xFF5e5e5e))),
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
                                                queueSaveDraft.scheduleOne(() => ServiceZimbra.saveDraft(fileSelected, selectedEmailToSend, to, content, "", "forward", widget.messageMail, widget.workspaceId), timeDelay: 2);
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
                                                hintStyle: TextStyle(color:  const Color(0xff9AA5B1), fontSize: 13.5, height: 1)
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
                                if (await ServiceZimbra.forwardMessage(widget.messageMail, "w", content, selectedEmailToSend, fileSelected)){
                                  ServiceZimbra.deleteDraft(widget.workspaceId, "forward", parentMessageId: widget.messageMail.id);
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
                        RenderMessageConv(messConv: widget.messageMail, workspaceId: widget.workspaceId)
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        toFocus.hasFocus ? Positioned(
          left: 200, top: 100,
          // top: 0, left: 0, bottom: 0, right: 0,
          child: StreamBuilder(
            stream: streamSelectedIndex.stream,
            initialData: 0,
            builder: (context, snapshot) {
              int indexSelected = (snapshot.data as int?) ?? 0;
              return StreamBuilder(
                initialData: <Map>[],
                stream: ServiceZimbra.autoCompleteController.stream,
                builder: (BuildContext c, AsyncSnapshot data){
                  autoComplete = data.data;
                  if (data.data.length == 0) return Container();
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:  autoComplete.length  <= 5 ? autoComplete.length * 60 : 290,
                      maxWidth: 300
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        color: isDark ? Color(0xff4c4c4c) : Color(0xffffffff),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        itemCount: autoComplete.length,
                        controller: controllerScroll,
                        itemBuilder: (BuildContext context, int index) { 
                          Map e  = data.data[index];
                          return RenderAutoComplete(
                            email: e["email"] ?? "", 
                            isDark: isDark, 
                            isSelected: index == indexSelected , 
                            name: e["name"] ?? '', 
                            onSelectEmail: () {
                              onSelectEmail(e);
                            },
                          );
                        }
                      )
                    ),
                  );
                },
              );
            }
          ),
        ) : Container()
      ],
    );

  }
}

class RenderAutoComplete extends StatelessWidget {
  const RenderAutoComplete({Key? key, required this.name, required this.email, required this.isDark, required this.onSelectEmail, required this.isSelected}) : super(key: key);
  final String name;
  final String email;
  final bool isDark;
  final Function onSelectEmail;
  final bool isSelected;
  @override
  Widget build(BuildContext context) {
    return  Container(
      height: 60,
      child: GestureDetector(
        onTap: (){onSelectEmail();},
        child: HoverItem(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Color(0xffbfbfbf) : isDark ? Color(0xFF5e5e5e) : Color(0xFFffffff),
              border: Border(
                bottom: BorderSide(width: 1, color: isDark ? Color(0xFF5e5e5e) : Color(0xFFbfbfbf))
              )
            ),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CachedAvatar("", name: name, width: 32, height: 32),
                  Container(width: 12,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(color:  isDark ? Color(0xFFDBDBDB) : Color(0xFF5e5e5e), fontSize: 12, fontWeight: FontWeight.w500)),
                      Text(email, style: TextStyle(color:  isDark ? Color(0xFFDBDBDB) : Color(0xFF5e5e5e), fontSize: 12, fontWeight: FontWeight.w300)),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RenderSelectedEmail extends StatelessWidget {
  const RenderSelectedEmail({Key? key, required this.name, required this.email, required this.isDark, required this.onSelectEmail});
  final bool isDark;
  final Function onSelectEmail;
  final String name;
  final String email;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){onSelectEmail();},
      child: HoverItem(
        isDark: false,
        showTooltip: true,
        tooltip: Text(email, style: TextStyle(color: isDark ? Color(0xFFDBDBDB) : Color(0xFF2e2e2e))),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 4, horizontal:12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            border: Border.all(color: isDark ? Color(0xFF5e5e5e) : Color(0xFFdbdbdbd)),
            color: isDark ? Color(0xFF5e5e5e) : Color(0xFFffffff)
          ),
          margin: EdgeInsets.only(right: 8),
          child: Row(
            children: [
              CachedAvatar("", name: name, width: 24, height: 24),
              Container(width: 8),
              Text(name, style: TextStyle(color: isDark ? Color(0xFFDBDBDB) : Color(0xFF5e5e5e), fontSize: 12, fontWeight: FontWeight.w500)),  
              Container(width: 14),     
              Icon(PhosphorIcons.x, size: 10, color: isDark ? Color(0xFFDBDBDB) : Color(0xFF5e5e5e),)               
            ],
          ),
        ),
      ),
    );
  }
}