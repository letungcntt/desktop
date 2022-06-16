import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/bottom_sheet_server.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';

class CustomConfirmDialog extends StatefulWidget {
  final title;
  final subtitle;
  final onConfirm;
  final onCancel;

  const CustomConfirmDialog({
    Key? key,
    this.title,
    this.subtitle,
    this.onConfirm,
    this.onCancel
  }) : super(key: key);

  @override
  _CustomConfirmDialogState createState() => _CustomConfirmDialogState();
}

class _CustomConfirmDialogState extends State<CustomConfirmDialog> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;

    return AlertDialog(
      insetPadding: EdgeInsets.all(0),
      contentPadding: EdgeInsets.all(0),
      backgroundColor: isDark ? Color(0xFF1F2933) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4))
      ),
      content: Container(
        width: 432,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10)
        ),
        height: 200,
        child: Column(
          children: [
            Container(
              height: 44,
              color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
              padding: EdgeInsets.only(top: 10, bottom: 10, left: 16),
              child: Row(children: [
                Text(widget.title, style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontWeight: FontWeight.w600, fontSize: 15))
              ])
            ),
            Container(
              color: isDark ? Color(0xff3D3D3D) : null,
              width: 432,
              padding: EdgeInsets.only(left: 16, top: 16, right: 16),
              height: 96,
              child: Text(
                widget.subtitle, 
                style: TextStyle(
                  color: isDark ? Color(0xffF5F7FA) : Colors.grey[800], 
                  height: 1.4, 
                  fontSize: 14
                )
              )
            ),
            Divider(height: 1, thickness: 1),
            Container(
              color: isDark ? Color(0xff3D3D3D) : null,
              height: 59,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      border: Border.all(color: Color(0xffCAC2C2))
                    ),
                    width: 80,
                    child: TextButton(
                      onPressed: () { 
                        Navigator.of(context, rootNavigator: true).pop("Discard");
                        if(widget.onCancel != null) widget.onCancel();
                      },
                      child: Text(S.current.cancel, style: TextStyle(color: isDark ? Colors.grey[200] : Colors.grey[800]))
                    ),
                  ),
                  SizedBox(width: 15),
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      border: Border.all(color: Color(0xffF57572))
                    ),
                    margin: EdgeInsets.only(right: 12.0),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop("Discard");
                        widget.onConfirm();
                      },
                      child: Text(widget.title, style: TextStyle(color: Color(0xffF57572), fontSize: 13))
                    ),
                  )
                ],
              ),
            )
          ]
        )
      ),
    );
  }
}

class CustomDialogWs extends StatefulWidget {
  final title;
  final textDisplay;
  final onSaveString;
  final action;
  CustomDialogWs({key, this.title, this.textDisplay, this.onSaveString, this.action}) : super(key: key);
  @override
  _CustomDialogWsState createState() => _CustomDialogWsState();
}
class _CustomDialogWsState extends State<CustomDialogWs> {
  TextEditingController _controller = TextEditingController();
  @override
  void initState(){
    super.initState();
    if(widget.action != "Join or create a workspace"){
      _controller.text = widget.textDisplay;
    }
  }
  showBottomSheet(context, action) {
    showModalBottomSheet(
      isScrollControlled: true,
      enableDrag: true,
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      builder: (BuildContext context) {
        return BottomSheetWorkspace(action: action);
      }
    );
  }
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: true);
    final isDark = auth.theme == ThemeType.DARK;
    final deviceWidth = MediaQuery.of(context).size.width;
    return Container(
      child: AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        backgroundColor: isDark ? Color(0xFF3D3D3D) : Color(0xffFFFFFF),
        content: Container(
          height: widget.action == "Join or create a workspace" ? 274 : 220,
          width: (Platform.isAndroid || Platform.isIOS) ? deviceWidth : 300,
          child: widget.action == "Join or create a workspace"
          //Dialog Create or Join Workspace
          ? Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Create a workspace", 
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.white70 : Color(0xff6B6B6B),
                    fontWeight: FontWeight.w500
                  )
                ),
                SizedBox(height: 12),
                Text(
                  "Your workspace is where you and your friends hang out. Make yours and start talking", 
                  style: TextStyle(
                    color: isDark ? Colors.white : Color(0xff6B6B6B),
                    fontSize: 14,
                    fontWeight: FontWeight.w200
                  ), 
                  textAlign: TextAlign.center
                ),
                SizedBox(height: 12),
                Container(
                  width: 300,
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Utils.getPrimaryColor())
                    ),
                    onPressed: () {
                      showBottomSheet(context, "Create workspace");
                    }, 
                    child: Text(
                      "Create a workspace",
                      style: TextStyle(color: Colors.white)
                    )
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Have an invite already?",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Color(0xff6B6B6B),
                    fontSize: 16,
                    fontWeight: FontWeight.w400
                  )
                ),
                SizedBox(height: 12),
                Container(
                  width: 300,
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        Color(0xff262626)
                      )
                    ),
                    onPressed: () {
                      showBottomSheet(context, "Join workspace");
                    }, 
                    child: Text(
                      "Join a workspace",
                      style: TextStyle(color: Colors.white)
                    )
                  ),
                ),
              ],
            ),
          ) 

          //Dialog Input
          : Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Color(0xff5E5E5E) : Color(0xffFAFAFA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16,vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              height: 1.57,
                              fontSize: 15, color: isDark
                                  ? Color(0xffFFFFFF)
                                  : Color(0xff3D3D3D)))
                        ]
                      ),
                      decoration:  BoxDecoration(border: Border(bottom: BorderSide(width: 0.2, color: Colors.grey))),
                    ),
                  ]
                ),
              ),
              SizedBox(height: 16,),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  autofocus: true,
                  controller: _controller,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark? Color(0xFF2E2E2E): Color(0xFFFAFAFA),
                    contentPadding:EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                    borderSide: BorderSide(color: isDark? Color(0xff5E5E5E): Color(0xffC9C9C9),style: BorderStyle.solid,width: 1)),
                    enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                    borderSide: BorderSide(color: isDark? Color(0xff5E5E5E): Color(0xffC9C9C9),style: BorderStyle.solid, width: 1)),
                    focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all( Radius.circular(2)),
                    borderSide: BorderSide(color: isDark? Color(0xff5E5E5E): Color(0xffC9C9C9),style: BorderStyle.solid,width: 1)),
                  ),
                ),
              ),
              SizedBox(height: 16,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 1,
                  color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9),
                ),
              ),
              SizedBox(height: 16,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: (){
                          Navigator.of(context, rootNavigator: true).pop("Discard");
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                               color: Color(0xffEB5757),
                               width: 1,
                               ),
                               borderRadius: BorderRadius.circular(5),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 10,vertical: 8),
                        child: Center(child: Text("Cancel", style: TextStyle(height: 1.57, fontSize: 12,color: Color(0xffEB5757))))
                   ),
                      ),
                 ),
                 SizedBox(width: 10,),
                 Expanded(
                   child: InkWell(
                     onTap: (){
                       widget.onSaveString(_controller.text);
                     },
                     child: Container(
                       decoration: BoxDecoration(
                         color: Utils.getPrimaryColor(),
                         border: Border.all(
                           color: Utils.getPrimaryColor(),
                           width: 1,
                           ),
                           borderRadius: BorderRadius.circular(5),
                        ),
                      padding: EdgeInsets.symmetric(horizontal: 10,vertical: 8),
                      width: MediaQuery.of(context).size.width,
                      child: Center(child: Text(widget.title == "Join to Channel" ? "Join" : "Save", style: TextStyle(height: 1.57, fontSize: 12, color:Colors.white)))
                     ),
                   ),
                 ),
                ],),
              )
            ]
          ),
        ),
      ),
    );
  }
}