import 'package:flutter/material.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/generated/l10n.dart';

import 'package:workcake/providers/providers.dart';

class CustomDialog extends StatefulWidget {
  final String title;
  final String titleField;
  final String displayText;
  final Function onSaveString;

  CustomDialog({
    key,
    required this.title,
    required this.displayText,
    required this.onSaveString,
    required this.titleField
  }) : super(key: key);

  @override
  _CustomDialogState createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.displayText;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: true);
    final isDark = auth.theme == ThemeType.DARK;

    return Container(
      child: AlertDialog(
        contentPadding: EdgeInsets.zero,
        insetPadding: EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        backgroundColor: isDark ? Color(0xff3D3D3D) : Color(0xffF8F8F8),
        content: Container(
          height: widget.title == "Validation" ? 250 : 218.5,
          width: 398,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
                  borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5)
                )),
                child: Column(
                  children: [
                    Container(
                      decoration:  BoxDecoration(border: Border(bottom: BorderSide(width: 0.2, color: Colors.grey))),
                      padding: EdgeInsets.only(top: 15, bottom: 15,left: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14, color: isDark
                                  ? Color(0xffffffff)
                                  : Color(0xff3D3D3D)))
                        ]
                      ),
                    ),
                  ]
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment:CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.titleField}: ',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w400,color: isDark ?  Color(0xFFC9C9C9): Color(0Xff828282)
                      )
                    ),
                    SizedBox(height: 8),
                    if(widget.title == "Validation") Text(
                      'User name must be more than 2 characters and contains no special characters !!!',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w400,color: isDark ?  Color(0xFFC9C9C9): Color(0Xff828282)
                      )
                    ),
                    SizedBox(height: 8,),
                    Container(
                      height: 40,
                      child: TextField(
                      autofocus: true,
                      controller: _controller,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                          borderSide: BorderSide(color: isDark? Colors.transparent: Color(0xffC9C9C9),style: BorderStyle.solid, width: 1)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                            borderSide: BorderSide(color: isDark? Color(0xff828282): Color(0xffC9C9C9),style: BorderStyle.solid, width: 0.5)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(2)),
                              borderSide: BorderSide(color: isDark? Color(0xff828282): Color(0xffC9C9C9),style: BorderStyle.solid, width: 0.5)),
                        filled: true,
                        fillColor:isDark ? Color(0xFF353535) : Color(0xFFEDEDED),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                ],),
              ),
              Container(
                decoration:  BoxDecoration(border: Border(top: BorderSide(width: 0.2, color: Colors.grey))),
                padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 11),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 32,
                      width: 80,
                      decoration: BoxDecoration(
                        border: Border.all(
                        color: Color(0xFFFF7875),
                        width: 1,
                     ),
                     borderRadius: BorderRadius.circular(4),
                      ),
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop("Discard");
                         },
                        child: Text(S.current.cancel, style: TextStyle(fontSize: 12,color: Color(0xFFFF7875)))
                        ),
                      ),
                      SizedBox(width: 8,),
                      Container(
                        height: 32,
                        width: 80,
                        child: TextButton(
                        style: ButtonStyle(
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(2))) ,
                        backgroundColor: MaterialStateProperty.all(Utils.getPrimaryColor(),),
                        overlayColor: MaterialStateProperty.all(Utils.getPrimaryColor())
                      ),
                      onPressed: () {
                        widget.onSaveString(_controller.text);
                      },
                      child: Text(S.current.save, style: TextStyle(fontSize: 12, color:Color(0xFFFFFFFF)))
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ),
        ),
      ),
    );
  }
}