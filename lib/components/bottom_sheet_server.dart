import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/providers/providers.dart';

class BottomSheetWorkspace extends StatefulWidget {
  BottomSheetWorkspace({key, this.action}) : super(key: key);
  final action;
  @override
  _BottomSheetWorkspaceState createState() => _BottomSheetWorkspaceState();
}

class _BottomSheetWorkspaceState extends State<BottomSheetWorkspace> {
  String serverName = "";

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: true);
    final token = auth.token;
    double deviceHeight = MediaQuery.of(context).size.height;
    double deviceWidth = MediaQuery.of(context).size.width;
    final isDark = auth.theme == ThemeType.DARK;

    createWorkspace(serverName) async {
      await Provider.of<Workspaces>(context, listen: false).createWorkspace(context, token, serverName, null);
      // Navigator.pushNamed(context, 'dashboard-screen');
      Navigator.pop(context);
    }

    return GestureDetector(
      onTap: () { FocusScope.of(context).unfocus(); },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF353a3e) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10.0),
            topRight: Radius.circular(10.0)
          )
        ),
        height: deviceHeight*0.85,
        padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          children: <Widget>[
            Text("Create a workspace", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 10),
              child: Column(
                children: [
                  Text("Your workspace is where you and your friends hang out.", style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600], fontSize: 12.5)),
                  Text("Make yours and start talking", style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600], fontSize: 12.5))
                ],
              )
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: TextButton(
                onPressed: () async {
                  final act = CupertinoActionSheet(
                    actions: <Widget>[
                      CupertinoActionSheetAction(
                        child: Text("Upload a photo"),
                        onPressed: () {},
                      ),
                      CupertinoActionSheetAction(
                        child: Text("Take a photo"),
                        onPressed: () {},
                      ),
                    ],
                  );
                  await showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) => act
                  );
                },
                child: Stack(
                  children: [
                    CircularBorder(
                      width: 2, size: 100,
                      color: Colors.grey[400]!,
                      icon: Icon(Icons.camera_alt, color: Colors.grey[400], size: 26),
                      title: Text("UPLOAD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[400])),
                    ),
                    Positioned(child: Icon(Icons.add_circle, color: Utils.getPrimaryColor(), size: 40), right: 0)
                  ]
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text("WORKSPACE NAME", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 13, color: isDark ? Colors.grey : Colors.grey[600]))
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10),
              child: CupertinoTextField(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey[300],
                ),
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
                padding: EdgeInsets.all(10),
                clearButtonMode: OverlayVisibilityMode.always,
                onChanged: (value) {
                  this.setState(() {
                    serverName = value;
                  });
                }
              ),
            ), Container(
              margin: EdgeInsets.only(top: 5),
              child: Column(
                children: [
                  Text("By create a workspace, you agree to Pancake's", style: TextStyle(fontSize: 11.6, color: Colors.grey)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Community Guidelines", style: TextStyle(fontSize: 11, color: Colors.blue)),
                      Text(".", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  )
                ],
              )
            ),
            Container(
              margin: EdgeInsets.only(top: 12),
              width: deviceWidth,
              child: TextButton(
                onPressed: () {
                  if (serverName != "") {
                    createWorkspace(serverName);
                  }
                },
                style: ButtonStyle(
                  backgroundColor:  MaterialStateProperty.all(Utils.getPrimaryColor()),
                ),
                child: Text("Create Workspace", style: TextStyle(color: Colors.white))
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CircularBorder extends StatelessWidget {
  final Color color;
  final double size;
  final double width;
  final icon;
  final title;
  const CircularBorder({key, this.color = Colors.blue, this.size = 70, this.width = 7.0, this.icon, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [icon,title],
          ),
          Container(
            padding: EdgeInsets.all(6),
            child: CustomPaint(
              size: Size(size, size),
              foregroundPainter: new MyPainter(
                completeColor: color,
                width: width
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  Color lineColor =  Colors.transparent;
  final completeColor;
  final width;

  MyPainter({
    this.completeColor, this.width
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint complete = new Paint()
      ..color = completeColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    Offset center = new Offset(size.width / 2, size.height / 2);
    double radius = min(size.width / 2, size.height / 2);
    var percent = (size.width *0.0005) / 2;

    double arcAngle = 2 * pi * percent;
    for (var i = 0; i < 36; i++) {
      var init = (-pi /1.5)*(i/6);

      canvas.drawArc(new Rect.fromCircle(center: center, radius: radius),init, arcAngle, false, complete);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}