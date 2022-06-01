import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/models/models.dart';

class ChangeChannelInfoMacOS extends StatefulWidget {
  final type;
  ChangeChannelInfoMacOS({Key? key, this.type}) : super(key: key);

  @override
  _ChangeChannelInfoState createState() => _ChangeChannelInfoState();
}

class _ChangeChannelInfoState extends State<ChangeChannelInfoMacOS> {
  TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentWorkspace = Provider.of<Workspaces>(context).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: true).currentChannel;
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final type = widget.type;

    _controller.text = currentChannel["name"];

    onChangeChannelInfo() {
      final auth = Provider.of<Auth>(context, listen: false);

      Provider.of<Channels>(context, listen: false).changeChannelInfo(auth.token, currentWorkspace["id"], currentChannel["id"], currentChannel, context);
      Navigator.pop(context);
    }

    return Container(
      child: type == 1 ? Column(
        children: [
          Text("Rename Channel",
            style: TextStyle(color: isDark ? Color(0xff6B6B6B) : Colors.white70, fontSize: 18, fontWeight: FontWeight.w500)
          ),
          Container(
            margin: EdgeInsets.only(top: 20),
            padding: EdgeInsets.only(left: 8.0),
            decoration: BoxDecoration(
              color: isDark ? Color(0xffE1EFEF) : Colors.grey,
              borderRadius: BorderRadius.all(Radius.circular(32))),
            child: TextField(
              autofocus: true,
              textAlign: TextAlign.center,
              controller: _controller,
              onChanged: (value) {
                currentChannel["name"] = value;
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Type an Rename Channel",
                hintStyle: TextStyle(
                  fontWeight: FontWeight.w100,
                  fontSize: 15.0,
                  color: Color(0xff6B6B6B)
                )
              )
            )
          ),
          Column(
            children: [
              SizedBox(height: 32),
              TextButton(
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                  backgroundColor: MaterialStateProperty.all(Utils.getPrimaryColor()),
                  overlayColor: MaterialStateProperty.all(Color(0xff)),
                  foregroundColor: MaterialStateProperty.all(Color(0xff)),
                  shadowColor: MaterialStateProperty.all(Color(0xff))
                ),
                onPressed: () {
                  if (currentChannel["name"].length < 3 || currentChannel["name"].length > 20) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => CupertinoAlertDialog(
                        title: Icon(Icons.report, size: 25),
                        content: Text("Channel name must be from 3-20 characters")
                      )
                    );
                  } else {
                    onChangeChannelInfo();
                  }
                },
                child: Container(
                  height: 48,
                  width: 56,
                  child: Center(
                    child: Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFFFFFF)
                      ),
                    ),
                  ),
                )
              ),
            ],
          )
        ],
      ) : type == 2 ? Container(
        child: Column(children: <Widget>[
          Container(
              padding: EdgeInsets.all(10),
              child: Text(
              "Channel Type",
              style: TextStyle(
                color: isDark ? Color(0xff6B6B6B) : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500
              )
            ),
          ),
          Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(
              color: isDark ? Colors.black12 : Colors.white54,
              width: 0.5
            ))),
            child: ListTile(
              onTap: (){
                currentChannel["is_private"] = false;
                onChangeChannelInfo();
              },
              title: Text("Regular"), trailing: currentChannel["is_private"] == false ? Icon(Icons.check) : null)
            ),
          Container(child: ListTile(
            onTap: (){
              currentChannel["is_private"] = true;
              onChangeChannelInfo();
            },
            title: Text("Private"), trailing: currentChannel["is_private"] == true ? Icon(Icons.check) : null)
          )
        ])
      ) : Column(children: <Widget>[
          Container(
              padding: EdgeInsets.all(10),
              child: Text(
              "Channel Type",
              style: TextStyle(
                color: isDark ? Color(0xff6B6B6B) : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500
              )
            ),
          ),
          Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(
              color: isDark ? Colors.black12 : Colors.white54,
              width: 0.5
            ))),
            child: ListTile(
              onTap: (){
                currentChannel["kanban_mode"] = true;
                onChangeChannelInfo();
              },
              title: Text("Kanban mode"), trailing: currentChannel["kanban_mode"] == true ? Icon(Icons.check) : null)
            ),
          Container(child: ListTile(
            onTap: (){
              currentChannel["kanban_mode"] = false;
              onChangeChannelInfo();
            },
            title: Text("Dev mode"), trailing: currentChannel["kanban_mode"] == false ? Icon(Icons.check) : null)
          )
        ]
      )
    );
  }
}
