import 'package:flutter/material.dart';
import 'package:workcake/providers/providers.dart';

class CustomFriendDialog extends StatefulWidget {
  final title;
  final string;
  final onSaveString;
  final data;

  CustomFriendDialog({key, this.title, this.string, this.onSaveString, this.data}) : super(key: key);

  @override
  _CustomFriendDialogState createState() => _CustomFriendDialogState();
}

class _CustomFriendDialogState extends State<CustomFriendDialog> {
  TextEditingController controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    String _value = widget.string;
    final auth = Provider.of<Auth>(context, listen: true);
    final isDark = auth.theme == ThemeType.DARK;

    return Container(
      child: AlertDialog(
        insetPadding: EdgeInsets.all(20),
        contentPadding: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0), ),
        backgroundColor: isDark ? Color(0xff3D3D3D) : Color(0xffDBDBDB),
        content: Container(
          height: 269,
          width: 448,
          // decoration: BoxDecoration(border: Border.all(width: 1)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    widget.data["success"] ? Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Icon(Icons.check_circle_rounded , color: Color(0xff27AE60) , size: 90,),
                    )
                    : Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Icon(Icons.cancel , color: Color(0xffEB5757) , size: 90,),
                    ),
                    Container(
                      padding: EdgeInsets.only(top: 20,),
                      child: Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                        Text(
                         widget.title,
                         textAlign: TextAlign.center,
                         style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 24, color: isDark ? Colors.grey[300] : Colors.black))
                        ]
                      ),
                      // decoration:  BoxDecoration(border: Border(bottom: BorderSide(width: 0.2, color: Colors.grey))),
                    ),
                    Container(
                      child: Text(_value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5 ,color: !isDark ? Color.fromRGBO(0, 0, 0, 0.65):Colors.white70),),
                    ),
                  ]
                ),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(10),
                width: 260,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(0xff1890FF) ,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop("Discard");
                  },
                  child: Text("Done", style: TextStyle(fontSize: 14, color: Colors.white))
                ),
              ),

            ]
          ),
        ),
      ),
    );
  }
}