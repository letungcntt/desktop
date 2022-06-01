import 'dart:async';


import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/http_exception.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/apps/list_app_create.dart';
import 'package:workcake/components/apps/biz_banking_app.dart';
import 'package:workcake/components/create_command_view.dart';
import 'package:workcake/components/custom_confirm_dialog.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/models/models.dart';

class AppsScreenMacOS extends StatefulWidget {
  AppsScreenMacOS();
  @override
  _AppsScreenMacOSState createState() => _AppsScreenMacOSState();
}

class _AppsScreenMacOSState extends State<AppsScreenMacOS>{
  String highLight = "";
  bool isWorkspace = false;
  var idAppSelected;
  List dataApps = [];
  Map dataApp = {
    "channels": [],
    "commands": [],
    "app": {}
  };
  int stateView = 1;

  @override
  void initState() {
    super.initState();
    Timer.run(() async {
      final token = Provider.of<Auth>(context, listen: false).token;
      // get list Apps of user
      getListApps(token);
    });
  }

  getListApps(token)async {
    String url = "${Utils.apiUrl}app?token=$token";

    try {
      var response  =  await Dio().get(url);
      var resData  =  response.data;

      setState(() {
        dataApps =  resData["data"];
      });
    } catch (e) {
      print(e.toString());
    }
  }

  onSuccessCreateApp(app) {
    setState(() {
      dataApps  = [app] + dataApps;
    });

    Navigator.pop(context);
  }

  createOrUpdateCommand(command, isUpdate) {
    if (isUpdate) {
      final index = dataApp["commands"].indexWhere((e) => e["id"] == command["id"]);

      if (index != -1) {
        setState(() {
          dataApp["commands"][index] = command;
        });
      }
    } else {
      setState(() {
        dataApp["commands"]  = [command] + dataApp["commands"];
      });
    }
  }

  showCreateCommands(context, createOrUpdateCommand, command) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: CreateCommandView(createOrUpdateCommand: createOrUpdateCommand, appId: idAppSelected, command: command),
        );
      }
    );
  }

  onDeleteCommand(context, command) {
    showDialog(
      context: context,
      builder: (context) {
        return  CustomConfirmDialog(
          title: "Delete Command",
          subtitle: "Are you sure want to delete this command ? This action cannot be undone",
          onConfirm: () async {
            try {
              final token  =  Provider.of<Auth>(context, listen: false).token;
              String url = "${Utils.apiUrl}app/${dataApp["app"]["id"]}/delete?token=$token";
              var response  = await Dio().post(url, data: {
                "id": command["id"]
              });
              var resData = response.data;

              if (resData["success"]) {
                final commands = dataApp["commands"];
                final index = (commands ?? []).indexWhere((e) => e["id"] == command["id"]);

                if (index != -1) {
                  commands.removeAt(index);
                  setState(() {
                    dataApp["commands"] = commands;
                  });
                }
              } else {
                throw HttpException("Loi khong xac dinh");
              }
            } catch (e) {
              print(e.toString());
            }
          }
        );
      }
    );
  }

  onTapBanking() {
    Navigator.pop(context);
    Navigator.push(context,
      PageRouteBuilder(pageBuilder: (context, _, __) =>
        BizBanking()
      )
    );
  }

  Widget _listApp() {
    final isDark  = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final token = Provider.of<Auth>(context, listen: false).token;

    getDetailApp() async {
      String url = "${Utils.apiUrl}app/$idAppSelected?token=$token";
      try {
        var response  =  await Dio().get(url);
        var resData  =  response.data;
        setState(() {
          dataApp =  resData["data"];
        });
      } catch (e) {
        print(e);
        // sl.get<Auth>().showErrorDialog(e.toString());
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xff3D3D3D) : Color(0xffFFFFFF),
        border: Border(
          top: BorderSide(
            color: isDark ? Palette.darkSelectedChannel.withOpacity(0.5) : Palette.defaultBackgroundLight
          )
        )
      ),
      padding: EdgeInsets.symmetric(horizontal: 100.0, vertical: 50.0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 32.0,
                child: TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                     Color(0xff1890FF)
                    ),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.0))
                    ),
                    padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 20, vertical: 8))
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.plus_circle, color: !isDark ? Color.fromRGBO(0, 0, 0, 0.65) : Colors.white, size: 14),
                      SizedBox(width: 5),
                      Text(
                        "Create app",
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: !isDark ? Color.fromRGBO(0, 0, 0, 0.65) : Colors.white
                        )
                      )
                    ],
                  ),
                  onPressed: () async {
                    showListAppCreate(context, onSuccessCreateApp);
                  },
                ),
              ),
              SizedBox(width: 20,),
              Expanded(
                child: Text(
                  "(*) Sau khi tạo và cài đặt app, bạn có thể chỉnh sửa cấu hình ở trong các channel cụ thể .",
                  style: TextStyle(
                    color: isDark ? Color(0xffFAAD14) : Color(0xff1890FF),
                    fontStyle: FontStyle.italic
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 21),
          Container(
            padding: EdgeInsets.all(24),
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height - 210,
            decoration: BoxDecoration(
              color: isDark ? Color(0xff5E5E5E) : Color(0xffffffff),
              border: Border.all(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9)),
              borderRadius: BorderRadius.all(Radius.circular(4.0)),
            ),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 20.0, runSpacing: 20.0,
                children: dataApps.map<Widget>((ele) {
                  return InkWell(
                    onTap: ele["type"] != "custom" ? null : () async {
                      if(ele["id"] == "1889cc30-53cb-4a98-8dba-ca33f8bed6ef") {
                        List<Map> bankingList = [
                          {"name": "TechcomBank", "avatar": "https://upload.wikimedia.org/wikipedia/commons/7/7c/Techcombank_logo.png"},
                          {"name": "TPBank", "avatar": "https://upload.wikimedia.org/wikipedia/commons/f/ff/Logo-TPB.png"},
                          {"name": "VietinBank", "avatar": "https://ficombank.com.vn/wp-content/uploads/2021/09/logo-vietinbank.jpg"}
                        ];
                        
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Colors.white,
                              content: Container(
                                width: 300,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(4),
                                      child: Text(
                                        "List Banking",
                                        style: TextStyle(
                                          fontSize: 18, color: Colors.black87,
                                          fontWeight: FontWeight.w600
                                        )
                                      ),
                                    ),
                                    Column(
                                      children: bankingList.map((e) {
                                        return InkWell(
                                          onTap: e["name"] != "TechcomBank" ? null : onTapBanking,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: e["name"] == "TPBank" ? Border(
                                                bottom: BorderSide(color: Colors.grey[600]!, width: 0.15),
                                                top: BorderSide(color: Colors.grey[600]!, width: 0.15)
                                              ) : Border()
                                            ),
                                            padding: EdgeInsets.all(16),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              children: [
                                                CachedImage(
                                                  e["avatar"],
                                                  width: 110,
                                                  height: 40,
                        
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList()
                                    ),
                                  ],
                                )
                              ),
                            );
                          }
                        );
                      } else {
                        setState(() {
                          stateView = 2;
                          idAppSelected = ele["id"];
                        });
                        await getDetailApp();
                      }
                    },
                    child: HoverItem(
                      colorHover: isDark ? Color(0xffFAAD14) :Color(0xff1890FF),
                      child: Container(
                        margin: EdgeInsets.all(1.5),
                        padding: EdgeInsets.all(16),
                        width: 193, height: 193,
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? Color(0xff52606D) : Color(0xff9bb7d1), width: 0.4),
                          color: isDark ? Color(0xff3D3D3D) : Color(0xffF3F3F3),
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CachedImage(
                              ele["avatar"],
                              width: 106,
                              height: 106,
                              radius: 53,
                              name: ele["name"],
                              fontSize: 20
                            ),
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(ele["name"]),
                                ),
                                if (ele["type"] != "custom") Text(
                                  "(Ứng dụng mặc định)",
                                  style: TextStyle(
                                    // color: Colors.green,
                                    fontStyle: FontStyle.italic
                                  ),
                                )
                              ],
                            ),
                          ],
                        )
                      ),
                    )
                  );
                }).toList(),
              ),
            ),
          )
        ],
      )
    );
  }

  Widget _appDetail() {
    final isDark  = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Container(
      color: isDark ? Color(0xff3D3D3D): Color(0xffFAFAFA),
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    stateView = 1;
                  });
                },
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xff5E5E5E): Color(0xffEDEDED),
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: Icon(CupertinoIcons.arrow_left, color: isDark ? Color(0xffFFFFFF) : Color(0xff2A5298),size:16,)),
                ),
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Color(0xff1890FF)) , 
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.0))),
                    padding: MaterialStateProperty.all(
                    EdgeInsets.symmetric(vertical: 18, horizontal: 16)
                    )
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.plus_circle, color: !isDark ? Color.fromRGBO(0, 0, 0, 0.65) : Colors.white, size: 14,),
                      SizedBox(width: 5),
                      Text(
                        "New Command",
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: !isDark ? Color.fromRGBO(0, 0, 0, 0.65) : Colors.white
                        )
                      )
                    ],
                  ),
                  onPressed: () async {
                    showCreateCommands(context, createOrUpdateCommand, null);
                }
              )
            ]
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(top: 21, bottom: 22),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Color(0xff5E5E5E) : Color(0xffFFFFFF),
                borderRadius: BorderRadius.all(Radius.circular(5))
              ),
              child: ListView.builder(
                itemCount: dataApp["commands"].length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onHover: (hover) {
                      setState(() {
                        highLight = hover ?  dataApp["commands"][index]["id"] : "";
                      });
                    },
                    onTap: () {
                      showCreateCommands(context, createOrUpdateCommand, dataApp["commands"][index]);
                    },
                    child: Container(
                      margin: EdgeInsets.all(1),
                      padding: EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xff4C4C4C) : Color(0xffF3F3F3),
                        border: Border.all(color: isDark ? highLight== dataApp["commands"][index]["id"] ? Color(0xffFAAD14) : Color(0xff4C4C4C) : highLight == dataApp["commands"][index]["id"] ? Color(0xff1890FF) : Color(0xffF3F3F3), width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("/${dataApp["commands"][index]["short_cut"]}",style: TextStyle(color: isDark ? Color(0xffFAAD14): Color(0xff1890FF)),),
                              SizedBox(height: 5,),
                              Text("(${dataApp["commands"][index]["request_url"]})"),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              onDeleteCommand(context, dataApp["commands"][index]);
                            },
                            child: Icon(PhosphorIcons.trashSimple, size: 20,
                            color: isDark ? highLight== dataApp["commands"][index]["id"] ? Color(0xffEB5757) : Color(0xffEDEDED) : highLight== dataApp["commands"][index]["id"] ? Color(0xffEB5757) : Color(0xff5E5E5E))
                          )
                        ]
                      )
                    )
                  );
                }
              )
            )
          ),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 75,
                      width: 130,
                      decoration: BoxDecoration(
                        color: !isDark ? Color(0xffFFFFFF) : Color(0xff5E5E5E),
                        borderRadius: BorderRadius.circular(5)
                      ),
                      child: Center(child: Text("${dataApp["commands"].length} \n \n Commands",textAlign: TextAlign.center,))
                    ),
                    SizedBox(width: 10),
                    Container(
                      height: 75,
                      width: 130,
                      padding: EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: !isDark ? Color(0xffFFFFFF) : Color(0xff5E5E5E),
                        borderRadius: BorderRadius.circular(5)
                      ),
                      child: Center(child: Text("${dataApp["channels"].length} \n \n Channels installed",textAlign: TextAlign.center))
                    )
                  ],
                ),
                Column(
                  // mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: Row(
                        children: [
                          Text("ID:      ", overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.grey[800],
                              fontWeight: FontWeight.w400,fontSize: 14
                            ),
                          ),
                          SizedBox(width: 50,),
                          Text("${dataApp["app"]["id"] ?? ""}")
                        ],
                      )
                    ),
                    SizedBox(height: 10),
                    Container(
                      child: Utils.checkedTypeEmpty(dataApp["app"]["create_time"])
                        ? Row(
                          children: [
                            Text("Time create:",
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.grey[800],
                                fontWeight: FontWeight.w400,fontSize: 14
                              ),
                            ),
                            SizedBox(width: 10,),
                            Text("${DateFormatter().renderTime(DateTime.parse(dataApp["app"]["create_time"]), type: "dd-MM-yyyy")}")
                          ],
                        )
                        : Text("Time create:   Not set"), 
                    ),
                    SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        text: "Client key:     ",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[800],
                          fontWeight: FontWeight.w400,fontSize: 14
                        ),
                        children: [
                          TextSpan(
                            text: "BEGIN RSA PUBLIC...",
                            style: TextStyle(color: isDark ? Color(0xffEDEDED): Color(0xff3D3D3D))
                          )
                        ]
                      )
                    ),
                  ],
                )
              ],
            )
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      autofocus: true,
      onKey: (node, event) {
        if(event.isKeyPressed(LogicalKeyboardKey.escape)&& event is RawKeyDownEvent) Navigator.pop(context);
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Apps',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: "Roboto",),
          ),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 20),
              child: InkWell(
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                focusColor: Colors.transparent,
                splashColor: Colors.transparent,
                child: Container(
                  child: Icon(CupertinoIcons.xmark_circle, color: Colors.white, size: 20,)  
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
          backgroundColor: Palette.backgroundSideBar,
          automaticallyImplyLeading: false,
        ),
        body: stateView == 1 ? _listApp() : _appDetail()
      ),
    );
  }
}

showListAppCreate(context, onSuccessCreateApp) {
  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: Duration(milliseconds: 80),
    transitionBuilder: (context, a1, a2, widget){
      var begin = 0.5;
      var end = 1.0;
      var curve = Curves.fastOutSlowIn;
      var curveTween = CurveTween(curve: curve);
      var tween = Tween(begin: begin, end: end).chain(curveTween);
      var offsetAnimation = a1.drive(tween);
      return ScaleTransition(
        scale: offsetAnimation,
        child: FadeTransition(
          opacity: a1,
          child: widget,
        ),
      );
    },
    pageBuilder: (BuildContext context, a1, a2) {
      return Container(
        child: Center(
          child: ListAppCreate(onSuccessCreateApp: onSuccessCreateApp),
        ),
      );
    }
  );
}
