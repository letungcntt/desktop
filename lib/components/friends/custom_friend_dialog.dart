import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/utils.dart';

import 'package:workcake/models/models.dart';

class CustomFriendDialog extends StatefulWidget {
  final title;
  final string;
  final onSaveString;

  CustomFriendDialog({key, this.title, this.string, this.onSaveString}) : super(key: key);

  @override
  _CustomFriendDialogState createState() => _CustomFriendDialogState();
}

class _CustomFriendDialogState extends State<CustomFriendDialog> {
  @override
  Widget build(BuildContext context) {
    String _value = widget.string;
    final auth = Provider.of<Auth>(context, listen: true);
    final isDark = auth.theme == ThemeType.DARK;

    return Container(
      child: AlertDialog(
        insetPadding: EdgeInsets.all(20),
        contentPadding: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0),side: BorderSide(width: 0.5, color: Colors.white70) ),
        backgroundColor: isDark ? Color(0xFF1F2933) : Colors.white,
        content: Container(
          height: 202,
          width: 448,
          // decoration: BoxDecoration(border: Border.all(width: 1)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(top: 10, bottom: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16, color: isDark
                                  ? Colors.grey[300]
                                  : Colors.black))
                        ]
                      ),
                      // decoration:  BoxDecoration(border: Border(bottom: BorderSide(width: 0.2, color: Colors.grey))),
                    ),
                  ]
                ),
              ),
              Container(
                child: Text(_value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, height: 1.5 ,color: !isDark ? Color.fromRGBO(0, 0, 0, 0.65):Colors.white70),),
              ),
              Container(
                padding: EdgeInsets.all(10),
                width: MediaQuery.of(context).size.width,
                color: isDark ? Color(0xff19DFCB) : Utils.getPrimaryColor(),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop("Discard");
                  },
                  child: Text("Okay", style: TextStyle(fontSize: 12, color: isDark ? Colors.black87 : Colors.white))
                ),
              ),
              
            ]
          ),
        ),
      ),
    );
  }
}