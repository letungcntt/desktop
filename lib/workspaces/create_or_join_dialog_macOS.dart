import 'dart:math';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';
import 'package:workcake/service_locator.dart';

class CreateOrJoinDialogMacOs extends StatefulWidget {
  final action;
  CreateOrJoinDialogMacOs({Key? key, this.action}) : super(key: key);

  @override
  _CreateOrJoinDialogMacOsState createState() =>
      _CreateOrJoinDialogMacOsState();
}

class _CreateOrJoinDialogMacOsState extends State<CreateOrJoinDialogMacOs> {
  var textCode;
  String contentUrl = "";
  bool isLoading = false;
  var errorMessage = "";

  loadAsset() async {
    final List file = await Utils.openFilePicker([ XTypeGroup( extensions: ['jpg', 'jpeg', 'png'] )]);
    if (file.isNotEmpty) {
      setState(() {
        isLoading = true;
      });
    } else {
      return;
    }
    final token = Provider.of<Auth>(context, listen: false).token;
    var uploadFile = await Provider.of<Messages>(context, listen: false).getUploadData(file[0]);
    var response = await Provider.of<Messages>(context, listen: false).uploadImage(token, 0, uploadFile, "image", (v){});
    if (response['success']) {
        setState(() {
          contentUrl = response['content_url'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        sl.get<Auth>().showAlertMessage('Can\'t load image.', false);
      }
  }

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<Auth>(context).token;
    final theme = Provider.of<Auth>(context, listen: false).theme;
    var workspaceName;
    var checked;

    createWorkspace(workspaceName) async {
      await Provider.of<Workspaces>(context, listen: false).createWorkspace(context, token, workspaceName, contentUrl);
      Navigator.pop(context);
      Navigator.pop(context);
    }

    return AlertDialog(
      contentPadding: EdgeInsets.all(0),
      content: Container(
        width: 420,
        height: widget.action == "create" ? 480 : 374,
        padding: EdgeInsets.all(25),
        child: Column(
          children: <Widget>[
            Text(
              widget.action == "create"
                ? S.of(context).createWorkspace
                : S.of(context).joinWorkspace,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: theme == ThemeType.DARK ? Colors.white70 : Color(0xff6B6B6B)
              )
            ),
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 10),
              child: widget.action == "create"
              ? Text(
                S.of(context).descCreateWorkspace,
                style: TextStyle(
                  color: theme == ThemeType.DARK ? Colors.white70 : Color(0xff6B6B6B),
                  fontSize: 13
                )
              )
              : Text(
                S.of(context).descJoinWs,
                style: TextStyle(color: Colors.grey, fontSize: 13)
              ),
            ),
            widget.action == "create" ? Container(
              margin: EdgeInsets.only(top: 20),
              child: TextButton(
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(EdgeInsets.all(0)),
                ),
                onPressed: loadAsset,
                child: contentUrl.isEmpty
                ? (!isLoading
                  ? Stack(
                    children: [
                      CircularBorder(
                        width: 3.0,
                        size: 100.0,
                        color: Color(0xff6B6B6B),
                        icon: Icon(Icons.camera_alt,
                          color: Color(0xff6B6B6B), size: 26),
                        title: Text(
                          S.of(context).upload,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xff6B6B6B)
                          )
                        ),
                      ),
                      Positioned(
                        child: Icon(
                          Icons.add_circle,
                          color: Utils.getPrimaryColor(),
                          size: 34
                        ),
                        right: 4
                      ),
                    ])
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: CircularProgressIndicator()))
                : CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(contentUrl),
                ),
              ),
            ) : Container(),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(
                      widget.action == "create"
                        ? S.of(context).workspaceName
                        : S.of(context).inviteWsCode,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: theme == ThemeType.DARK ? Colors.white70 : Color(0xff6B6B6B)))
                ],
              ),
            ),
            widget.action == "create" ? Container(
              margin: EdgeInsets.only(top: 10),
              child: CupertinoTextField(
                autofocus: true,
                style: TextStyle(color: Colors.grey),
                padding: EdgeInsets.all(10),
                clearButtonMode: OverlayVisibilityMode.always,
                onChanged: (value) {
                  workspaceName = value;
                }
              ),
            ) : Container(
              margin: EdgeInsets.only(top: 10),
              child: CupertinoTextField(
                autofocus: true,
                style: TextStyle(color: Colors.grey),
                padding: EdgeInsets.all(10),
                clearButtonMode: OverlayVisibilityMode.always,
                onChanged: (value) {
                  textCode = value;
                }
              ),
            ),
            errorMessage == "" 
            ? Container(height: 4)
            : Container(
                margin: EdgeInsets.only(top: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      errorMessage,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: Colors.red,
                        fontStyle: FontStyle.italic
                      ),
                    )
                  ]
                ),
              ),
            widget.action == "create" ? Container(
              margin: EdgeInsets.only(top: 20),
              child: Column(
                children: [
                  checked == false ? Text(S.of(context).workspaceCannotBlank) : Text(""),
                  Text(
                    S.of(context).noteCreateWs,
                    style: TextStyle(
                      fontSize: 11.6,
                      color: Colors.grey
                    )
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        S.of(context).communityGuide,
                        style: TextStyle(
                          fontSize: 11, color: Colors.blue
                        )
                      ),
                      Text(
                        ".",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey
                        )
                      ),
                    ],
                  )
                ],
              )
            ) : Container(
            margin: EdgeInsets.only(top: 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).example.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: Color(0xff6B6B6B)
                      )
                    ),
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(top: 6),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 4),
                          child: Text(
                            S.of(context).inviteLookLike,
                            style: TextStyle(
                              color: Colors.grey, fontSize: 12
                            )
                          )
                        ),
                        Container(
                          margin: EdgeInsets.only(right: 4),
                          child: Text(
                            "https://pancakechat.vn/TK76iu,",
                            style: TextStyle(fontSize: 12)
                          )
                        ),
                      ]),
                ),
                Container(
                  margin: EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 4),
                        child: Text(
                          "/TK76iu,",
                          style: TextStyle(fontSize: 12)
                        )
                      ),
                      Container(
                        margin: EdgeInsets.only(right: 4),
                        child: Text(
                          S.of(context).or,
                          style: TextStyle(
                            color: Colors.grey, fontSize: 12
                          )
                        )
                      ),
                      Container(
                        margin: EdgeInsets.only(right: 4),
                        child: Text(
                          "https://pancakechat.vn/cool-people,",
                          style: TextStyle(fontSize: 12)
                        )
                      ),
                    ]
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            child: Text(
                              S.of(context).inviteCodeWs,
                              style: TextStyle(
                                color: Colors.grey, fontSize: 12
                              )
                            )
                          ),
                          Container(
                            child: Text(
                              "AA-56-123-AA, AA-56-123-AA,",
                              style: TextStyle(fontSize: 12)
                            )
                          )
                        ]
                      ),
                      Container(
                        child: Text(
                          "AA-56-123-AA",
                          style: TextStyle(fontSize: 12)
                        )
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            height: 36,
            width: 255,
            child: TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Utils.getPrimaryColor())
              ),
              onPressed: () {
                if (workspaceName != null) {
                  createWorkspace(workspaceName);
                  checked = true;
                } else {
                   joinWorkspaceByCode();
                }
              },
              child: Text(
                widget.action == "create"
                  ? S.of(context).createWorkspace
                  : S.of(context).joinWorkspace,
                style: TextStyle(color: Color(0xFFffffff))
              )
            ),
          )],
        ),
      ),
    );
  }

 joinWorkspaceByCode() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    String text = '';
    if (Utils.checkedTypeEmpty(textCode)) {
      try {
        var responseMessage = await Provider.of<Workspaces>(context, listen: false).joinWorkByCode(token, textCode, currentUser);
          if (responseMessage == true) {
            Navigator.of(context).pop();
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return CupertinoAlertDialog(
                  title: Text(S.of(context).joinWorkspaceSuccess,style: TextStyle(color: Colors.green),), 
                  // content: "Join workspace was successful"
                );
              }
            );
          } else if (responseMessage == false){
            Navigator.of(context).pop();
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return CupertinoAlertDialog(
                  title: Text(S.of(context).joinWorkspaceFail),
                );
              }
            );
          }
          else text = responseMessage["message"];
      } catch (e) {
        text = 'Syntax code was wrong, try again !';
      }
    }
    else text = S.of(context).workspaceCannotBlank;

    setState(() => errorMessage = text);
  }
}

class CircularBorder extends StatelessWidget {
  final color;
  final size;
  final width;
  final icon;
  final title;
  
  const CircularBorder({
    Key? key,
    this.color = Colors.blue,
    this.size = 70.0,
    this.width = 7.0,
    this.icon,
    this.title
  }) : super(key: key);

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
            children: [icon, title],
          ),
          Container(
            padding: EdgeInsets.all(6),
            child: CustomPaint(
              size: Size(size, size),
              foregroundPainter:
                  new MyPainter(completeColor: color, width: width),
            ),
          ),
        ],
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  final lineColor = Colors.transparent;
  final completeColor;
  final width;

  MyPainter({this.completeColor, this.width});
  @override
  void paint(Canvas canvas, Size size) {
    Paint complete = new Paint()
      ..color = completeColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    Offset center = new Offset(size.width / 2, size.height / 2);
    double radius = min(size.width / 2, size.height / 2);
    var percent = (size.width * 0.0005) / 2;

    double arcAngle = 2 * pi * percent;
    for (var i = 0; i < 36; i++) {
      var init = (-pi / 1.5) * (i / 6);

      canvas.drawArc(new Rect.fromCircle(center: center, radius: radius), init,
          arcAngle, false, complete);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
