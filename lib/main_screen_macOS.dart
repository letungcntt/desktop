import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:simple_tooltip/simple_tooltip.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/focus_inputbox_manager.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/update_services.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/apps/app_screen_macOS.dart';
import 'package:workcake/components/call_center/p2p_manager.dart';
import 'package:workcake/components/custom_dialog.dart';
import 'package:workcake/components/main_menu/file.dart';
import 'package:workcake/components/main_menu/task_download.dart';
import 'package:workcake/components/message_item/attachments/text_file.dart';
import 'package:workcake/components/responsesizebar_widget.dart';
import 'package:workcake/components/right_sider.dart';
import 'package:workcake/components/saved_items/saved_messages.dart';
import 'package:workcake/components/search_bar_navigation.dart';
import 'package:workcake/components/transitions/fade_scale_transition.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/services/socket.dart';
import 'components/notification_macOS.dart';
import 'components/notify_focus_app.dart';
import 'components/profile/edit_profile_dialog.dart';
import 'components/workspace_button.dart';
import 'direct_message/direct_messages_view_macOS.dart';
import 'workspaces/create_or_join_workspace_macOS.dart';
import 'workspaces/workspace_messages_view_macOS.dart';

class MainScreenMacOS extends StatefulWidget {
  @override
  _MainScreenMacOSState createState() => _MainScreenMacOSState();
}

class _MainScreenMacOSState extends State<MainScreenMacOS> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  String drawerType = "file";
  var subscriptionNetwork;

  @override
  void initState() {
    super.initState();
    Utils.globalMaterialContext = context;
    Timer.run(() async {
      final token = Provider.of<Auth>(context, listen: false).token;
      Provider.of<User>(context, listen: false).fetchUserMentionInDirect(token);
      // await _initImages();var connectivityResult = await (Connectivity().checkConnectivity());

      var boxKey = Hive.lazyBox("pairKey");
      var deviceId = await boxKey.get('deviceId');
      var identityKey = await boxKey.get("identityKey");
      var signedKey  = await boxKey.get("signedKey");
      if (deviceId == null || identityKey ==  null ||  signedKey == null) {
        Provider.of<Auth>(context, listen: false).logout();
      } else {
        if (mounted) {
          final auth = Provider.of<Auth>(context, listen: false);
          Provider.of<Auth>(context, listen: false).connectSocket(auth.userId, {}, contextToSync: context);
        }
      }
      var box = await Hive.openBox('direct');
      if (mounted) {
        Provider.of<DirectMessage>(context, listen: false).setData(box.values.toList(), currentUserId: Provider.of<Auth>(context, listen: false).userId);
        if (Platform.isWindows) Provider.of<Work>(context, listen: false).loadHiveSystemTray();
        Provider.of<Windows>(context, listen: false).loadResponsiveBarFromHive();
      }
      await Utils.uploadDeviceInfo(token);
      subscriptionNetwork = Connectivity().onConnectivityChanged.listen(_handleChangeConnect);
    });
    FocusInputStream.instance.initObject();
    P2PManager.setCallContext(context);
    socketListener();
  }

  static int sendCount = 0;
  static int receiveCount = 0;
  static bool lostConnect = false;

  socketListener() {
    try {
      Timer(const Duration(seconds: 5), () {
        if (!mounted) return;
        List userIds = [
          'f70d3820-bcc9-4a95-8137-cc22ab4e001f',
          '9b2ead87-ca88-4b77-87eb-aa558af0b5e4',
          'b0df54ac-03f5-4110-b17c-29ef7c34d530',
          '773a8131-86d6-416f-918b-dc680b5c2084',
          '70bf28a9-5be4-4c57-a563-9cad1085b1c5 '
        ];
        final userId = Provider.of<Auth>(context, listen: false).userId;
        final index = userIds.indexWhere((e) => e == userId);
        if (index == -1) return;

        final auth = Provider.of<Auth>(context, listen: false);
        final channel = auth.channel;
        if (channel == null) return;

        Timer.periodic(new Duration(seconds: 6), (timer) async {
          if (lostConnect) {
            try {
              final url = Utils.apiUrl + 'users/me?token=${auth.token}';
              var options = BaseOptions(
                baseUrl: url,
                connectTimeout: 5000,
                receiveTimeout: 5000,
              );

              var response = await Dio(options).get(url);
              var dataRes = response.data;

              if (dataRes['success'] == true && lostConnect && mounted) {
                lostConnect = false;
                final socket = Provider.of<Auth>(Utils.getGlobalContext(), listen: false).socket;
                socket?.disconnect();
                channel.leave();
                Timer(const Duration(seconds: 2), () {
                  print("reconnect socket..........");
                  sendCount = 0;
                  receiveCount = 0;
                  Phoenix.rebirth(context);
                });
                return;
              } else {
                print("check socket via api failed");
              }
            } catch (e) {
              print("${e.toString()} socket error");
              // sl.get<Auth>().showErrorDialog(e.toString());
            }
          } else {
            if (!mounted) return;
            if (sendCount - receiveCount > 15) {
              lostConnect = true;
            } else {
              final channel = auth.channel;
              final userId = auth.userId;

              channel.push(event: "ping", payload: {
                "user_id": userId
              });
              sendCount +=1;
            }
          }
        });

        channel.on("ping", (data, a, b) {
          if (receiveCount < sendCount) {
            receiveCount +=1;
          }
        });
      });
    } catch (e) {
      print(e.toString());
    }
  }

  _handleChangeConnect(state){
    StreamStatusConnection.instance.setConnectionStatus(state != ConnectivityResult.none);
  }

  @override
  void dispose(){
    if(subscriptionNetwork != null) subscriptionNetwork.cancel();
    super.dispose();
  }

  getFieldOfListUser(List data, String field) {
    if (data.length  == 0 ) return "";
    var result = "";
    for (var i = 0; i < data.length; i++) {
      if (i != 0) result += ", ";
      result += data[i][field];
    }
    if (result.length > 20) {
      return result.substring(0, 20) + "...";
    }
    return result;
  }


  parseDatetime(time) {
    if (time != "") {
      DateTime offlineTime = DateTime.parse(time).add(Duration(hours: 7));
      DateTime now = DateTime.now();
      final difference = now.difference(offlineTime).inMinutes;

      final hour = difference ~/ 60;
      final minutes = difference % 60;
      final day = hour ~/24;
      final hourLeft = hour % 24 + 1;

      if (day > 0) {
        return 'Active ${day.toString().padLeft(2, "")} ${day > 1 ? "days" : "day"} and ${hourLeft.toString().padLeft(2, "")} ${hourLeft > 1 ? "hours" : "hour"} hours ago';
      } else if (hour > 0) {
        return 'Active ${hour.toString().padLeft(2, "")} ${hour > 1 ? "hours" : "hour"} ago';
      } else {
        if (minutes <= 1) return "moment ago";
        else return 'Active ${minutes.toString().padLeft(2, "0")} minutes ago';
      }
    } else {
      return "Offline";
    }
  }

  openDrawer(type) {
    setState(() => drawerType = type);

    if (drawerType == "file") {
      _scaffoldKey.currentState!.openDrawer();
    } else if (drawerType == "savedMessages") {
      _scaffoldKey.currentState!.openDrawer();
    } else {
      _scaffoldKey.currentState!.openEndDrawer();
    }
  }
  onChangeUsernameDialog(value) async {
    if(RegExp(r'[^a-zA-Z0-9\_\.\-]').hasMatch("$value") == false && value.length > 2) {
      final auth = Provider.of<Auth>(context, listen: false);
      final currentUser = Provider.of<User>(context, listen: false).currentUser;
      currentUser["username"] = value;
      var res = await Provider.of<User>(context, listen: false).changeProfileInfo(auth.token, currentUser);
      if(res["success"] == true) {
        Navigator.pop(context);
        openEditProfileDialog();
      }
      else if (res["success"] == false) {
        print(res);
        showDialog(
          context: context,
          builder: (BuildContext context) => CupertinoAlertDialog(
            title: Icon(Icons.report, size: 25),
            content: Text("This user name and tag already exist !!!")
          )
        );
      }
      else {
        print(res);
        showDialog(
          context: context,
          builder: (BuildContext context) => CupertinoAlertDialog(
            title: Icon(Icons.report, size: 25),
            content: Text("Server Error !!!")
          )
        );
      }
    }
    else {
      print("Tên chứa ký tự đặc biệt hoặc ít hơn 2 ký tự");
      showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: Icon(Icons.report, size: 25),
          content: Text("User name must be more than 2 characters and contains no special characters !!!")
        )
      );

    }
  }

  openEditProfileDialog() {
     final currentUser = Provider.of<User>(context, listen: false).currentUser;
    showModal(
      configuration: FadeScaleOutTransitionConfiguration(
        barrierDismissible: true,
        reverseTransitionDuration: Duration(milliseconds: 100)
      ),
      context: context,
      builder: (context) {
        return currentUser["username"] != null
        ?
        AlertDialog(
          content: EditProfileDialog(),
          contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        )
        : 
        CustomDialog(
          title: "Validation", 
          displayText: "", 
          onSaveString: onChangeUsernameDialog,
          titleField: "You need a user name before viewing and changing profiles"
        );
      },
    );
  }

  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;
    final currentUser = Provider.of<User>(context).currentUser;
    final tab = Provider.of<Workspaces>(context, listen: true).tab;
    final pendingUsers = Provider.of<User>(context, listen: true).pendingList;
    final showFriends = Provider.of<Channels>(context, listen: true).showFriends;
    super.build(context);

    return currentUser["id"] == null ? Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network("https://assets6.lottiefiles.com/datafiles/hYQRPx1PLaUw8znMhjLq2LdMbklnAwVSqzrkB4wG/bag_error.json"),
            Container(
              margin: EdgeInsets.only(top: 50),
              width: 200,
              height: 50,
              child: TextButton(
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.0),
                    )
                  ),
                  padding: MaterialStateProperty.all(EdgeInsets.all(8.0)),
                  backgroundColor: MaterialStateProperty.all(Utils.getPrimaryColor()),
                  textStyle: MaterialStateProperty.all(
                    TextStyle(
                      color: Colors.white
                    )
                  )
                ),

                onPressed: () {
                  Provider.of<Auth>(context, listen: false).logout();
                },
                child: Text(
                  'Logout',
                  style: GoogleFonts.roboto(
                    textStyle: Theme.of(context).textTheme.headline4,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              )
            )
          ],
        )
      ),
    ) : Scaffold(
      // key: _scaffoldKey,
      // drawer: Container(
      //   color: isDark ? Palette.backgroundRightSiderDark : Color(0xffF3F3F3),
      //   width: MediaQuery.of(context).size.width * 0.7,
      //   child: SavedMessages(),
      // ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: Palette.backgroundSideBar,
                height: 38,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WindowTitleBarBox(
                      child: MoveWindow(
                        child: Container(width: 90,),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        child: WindowTitleBarBox(
                          child: MoveWindow(),
                        ),
                      )
                    ),
                    SearchBarNavigation(tab: tab),
                    Expanded(
                      child: Container(
                        child: WindowTitleBarBox(
                          child: MoveWindow(),
                        ),
                      )
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                         Tooltip(
                          message: "Contact support",
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            gradient:LinearGradient(colors: isDark ? <Color>[Color(0xff2E2E2E), Color(0xff2E2E2E)] : <Color>[Color(0xffF3F3F3), Color(0xffF3F3F3)]),
                          ),
                          padding: const EdgeInsets.all(8.0),
                          preferBelow: false,
                          textStyle: const TextStyle(
                            fontSize: 12,
                          ),
                          child: Container(
                            height: 28, width: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                              color: Color(0xff2E2E2E),
                            ),
                            child: ListAction(
                              action: "", isDark: isDark,
                              colorHover: Palette.hoverColorDefault,
                              child: InkWell(
                                onTap: () async {
                                  Map user = {
                                    "user_id": "9e702ec5-7a22-42ed-a289-3c8c55692523",
                                    "full_name": "Pancake Chat Support",
                                    "is_online": true
                                  };
                                  final currentUser = Provider.of<User>(context, listen: false).currentUser;
                                  var convId = user["conversation_id"];
                                  if (convId == null){
                                    convId = MessageConversationServices.shaString([currentUser["id"], user["user_id"] ?? user["id"]]);
                                  }

                                  bool hasConv = await Provider.of<DirectMessage>(context, listen: false).getInfoDirectMessage(Provider.of<Auth>(context, listen: false).token, convId);
                                  var dm;
                                  if (hasConv){
                                    dm = Provider.of<DirectMessage>(context, listen: false).getModelConversation(convId);
                                  } else {
                                    dm = DirectModel(
                                      "",
                                      [
                                        {"user_id": currentUser["id"],"full_name": currentUser["full_name"], "avatar_url": currentUser["avatar_url"], "is_online": true},
                                        {"user_id": user["user_id"] ?? user["id"], "avatar_url": user["avatar_url"],  "full_name": user["full_name"] ?? user["name"], "is_online": user["is_online"]}
                                      ],
                                      "", false, 0, {}, false, 0, {}, user["full_name"] ?? user["name"], null
                                    );
                                  }
                                  Provider.of<DirectMessage>(context, listen: false).setSelectedDM(dm, "");
                                  Provider.of<Workspaces>(context, listen: false).setTab(0);
                                },
                                child: Icon(CupertinoIcons.question_circle, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        Stack(
                          children: [
                            Container(
                              height: 28, width: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                                color: Color(0xff2E2E2E),
                              ),
                              child: Tooltip(
                                message: "Friends",
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  gradient:LinearGradient(colors: isDark ? <Color>[Color(0xff2E2E2E), Color(0xff2E2E2E)] : <Color>[Color(0xffF3F3F3), Color(0xffF3F3F3)]),
                                ),
                                padding: const EdgeInsets.all(8.0),
                                preferBelow: false,
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                ),
                                child: ListAction(
                                  action: "", isDark: isDark,
                                  colorHover: Palette.hoverColorDefault,
                                  child: InkWell(
                                    onTap: () {
                                      Provider.of<Channels>(context, listen: false).openFriends(!showFriends);
                                      Provider.of<Messages>(context, listen: false).changeOpenThread(false);
                                      Provider.of<DirectMessage>(context, listen: false).openDirectSetting(false);
                                    },
                                    child: Icon(CupertinoIcons.person_2, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ),
                            if (pendingUsers.length > 0) Positioned(
                              right: 0.5,
                              bottom: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: new BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              )
                            ),
                          ],
                        ),
                        SizedBox(width: 6),
                        Tooltip(
                          message: "Saved Messages",
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            gradient:LinearGradient(colors: isDark ? <Color>[Color(0xff2E2E2E), Color(0xff2E2E2E)] : <Color>[Color(0xffF3F3F3), Color(0xffF3F3F3)]),
                          ),
                          padding: const EdgeInsets.all(8.0),
                          preferBelow: false,
                          textStyle: const TextStyle(
                            fontSize: 12,
                          ),
                          child: Container(
                            height: 28, width: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                              color: Color(0xff2E2E2E),
                            ),
                            child: ListAction(
                              action: "", isDark: isDark,
                              colorHover: Palette.hoverColorDefault,
                              child: InkWell(
                                onTap: () async {
                                  openDrawer("savedMessages");
                                },
                                child: Icon(CupertinoIcons.bookmark, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        Tooltip(
                          message: "Profile",
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            gradient:LinearGradient(colors: isDark ? <Color>[Color(0xff2E2E2E), Color(0xff2E2E2E)] : <Color>[Color(0xffF3F3F3), Color(0xffF3F3F3)]),
                          ),
                          padding: const EdgeInsets.all(8.0),
                          preferBelow: false,
                          textStyle: const TextStyle(
                            fontSize: 12,
                          ),
                          child: InkWell(
                            onTap: () => openEditProfileDialog(),
                            child: CachedImage(
                              currentUser['avatar_url'],
                              height: 28, width: 30,
                              radius: 4,
                              name: currentUser["full_name"]
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        WindowTitleBarBox(
                          // height: double.infinity,
                          child: MoveWindow(
                            child: Platform.isMacOS ? Container(width: 16) : WindowButtons()
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Scaffold(
                  key: _scaffoldKey,
                  drawerEnableOpenDragGesture: false,
                  drawer: Container(
                    color: isDark ? Palette.backgroundRightSiderDark : Color(0xffF3F3F3),
                    width: drawerType == "file" ? 360 : MediaQuery.of(context).size.width * 0.7,
                    child: drawerType == "file" ? File() : SavedMessages(),
                  ),
                  body: Row(
                    children: <Widget>[
                      NotificationMacOS(),
                      NotifyFocusApp(),
                      ResponseSidebarItem(
                        separateSide: "right",
                        constraints: BoxConstraints(maxWidth: 1000, minWidth: 240),
                        itemKey: 'leftSider',
                        zeroSize: 70,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Palette.backgroundTheardDark,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 70,
                                child: Container(
                                  color: Color(0xff1E1E1E),
                                  child: Column(
                                    children: <Widget>[
                                      Expanded(child: LeftSider()),
                                      Divider(
                                        thickness: 1.0,
                                        indent: 9.0,
                                        endIndent: 9.0,
                                        color: Color(0xff5E5E5E),
                                      ),
                                      ListAction(
                                        action: 'Update version',
                                        isDark: isDark,
                                        tooltipDirection: TooltipDirection.right,
                                        colorTooltip: isDark ? Color(0xFF1c1c1c): Colors.white,
                                        child: TextButton(
                                          style: ButtonStyle(
                                            overlayColor: MaterialStateProperty.all(Colors.transparent),
                                            padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 22)),
                                          ),
                                          child: SvgPicture.asset('assets/icons/ArchiveBox.svg'),
                                          onPressed: () => UpdateServices.checkForUpdate()
                                        ),
                                      ),
                                      ListAction(
                                        action: 'Files',
                                        isDark: isDark,
                                        tooltipDirection: TooltipDirection.right,
                                        colorTooltip: isDark ? Color(0xFF1c1c1c): Colors.white,
                                        child: TextButton(
                                          style: ButtonStyle(
                                            overlayColor: MaterialStateProperty.all(Colors.transparent),
                                            padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 22)),
                                          ),
                                          child: SvgPicture.asset('assets/icons/FM1.svg'),
                                          onPressed: () async {
                                            openDrawer("file");
                                          }
                                        ),
                                      ),
                                      ListAction(
                                        action: 'Apps command',
                                        isDark: isDark,
                                        tooltipDirection: TooltipDirection.right,
                                        colorTooltip: isDark ? Color(0xFF1c1c1c): Colors.white,
                                        child: TextButton(
                                          style: ButtonStyle(
                                            overlayColor: MaterialStateProperty.all(Colors.transparent),
                                            padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 22)),
                                          ),
                                          child: SvgPicture.asset('assets/icons/app_command.svg'),
                                          onPressed: () async {
                                            Navigator.push(context,
                                              MaterialPageRoute(
                                                builder: (context) {
                                                  return AppsScreenMacOS();
                                                }
                                              )
                                            );
                                          },
                                        ),
                                      ),
                                      SizedBox(height: 4)
                                    ]
                                  )
                                )
                              ),
                              Expanded(
                                child: Stack(
                                  children: [
                                      tab != 0
                                        ? WorkspaceMessagesViewMacOs(openDrawer: openDrawer)
                                        : DirectMessagesViewMacOS(),
                                    Positioned(
                                      bottom: 0, left: 0, right: 0,
                                      child: TaskDownload(),
                                    ),
                                    Positioned(
                                      bottom: 0, left: 0, right: 0,
                                      child: StatusConnectionView(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ),
                      ),
                      Expanded(
                        child: RightSider()
                      ),
                    ]
                  ),
                ),
              ),
            ],
          ),
        ],
      )
    );
  }
  @override
  bool get wantKeepAlive => true;
}
class WindowButtons extends StatefulWidget{
  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 38, child: MinimizeWindowButton(colors: WindowButtonColors(iconNormal: Colors.white))),
        SizedBox(width: 38, child: appWindow.isMaximized ?
          RestoreWindowButton(colors: WindowButtonColors(iconNormal: Colors.white),
           onPressed: () => setState((){
             appWindow.maximizeOrRestore();
           }),
          )
          : MaximizeWindowButton(colors: WindowButtonColors(iconNormal: Colors.green[300], mouseOver: Colors.grey[400]),
            onPressed: () => setState(() {
              appWindow.maximizeOrRestore();
            }))
          ),
        SizedBox(width: 38, child: CloseWindowButton(colors: WindowButtonColors(iconNormal: Colors.white, mouseOver: Colors.red)))
      ],
    );
  }
}

class LeftSider extends StatefulWidget {
  const LeftSider({
    Key? key,

  }) : super(key: key);

  @override
  _LeftSiderState createState() => _LeftSiderState();
}

class _LeftSiderState extends State<LeftSider> {
  bool hoverFriendTab = false;
  bool setLoadMore =false;
  @override
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener(handleKey);
    Timer.run(() {
      goToLastSelected();
    });
  }

  handleKey(RawKeyEvent keyEvent) {
    final data = Provider.of<Workspaces>(context, listen: false).data;
    final listDataDirect = Provider.of<DirectMessage>(context, listen: false).data;
    final currentDirectMessage = Provider.of<DirectMessage>(context, listen: false).directMessageSelected;
    final listMessage = Provider.of<DirectMessage>(context, listen: false).dataDMMessages;
    final hotKeyPressed = Platform.isMacOS ? keyEvent.isMetaPressed : keyEvent.isAltPressed;

    if(hotKeyPressed && keyEvent is RawKeyDownEvent) {
      switch (keyEvent.character) {
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
          int? keyDigital = int.tryParse(keyEvent.character!);
          if (keyDigital != null) {
            if (keyDigital == 1) {
              final keyScaffold = Provider.of<Auth>(context, listen: false).keyDrawer;
              if(keyScaffold.currentState!.isEndDrawerOpen) keyScaffold.currentState!.openDrawer();
              Provider.of<Channels>(context, listen: false).openChannelSetting(false);
              Provider.of<Workspaces>(context, listen: false).tab = 0;
              Provider.of<Workspaces>(context, listen: false).changeToMessageView(true);
              Provider.of<User>(context, listen: false).selectTab("channel");

              if (listDataDirect.length > 0) {
                if (currentDirectMessage.id != "") {
                  onSelectDirectMessage(currentDirectMessage);
                } else {
                  int indexPanchat = listMessage.indexWhere((element) => element["type"] == "panchat");
                  if (indexPanchat == -1) return;
                  final convIdPanchat = listMessage[indexPanchat]["conversation_id"];
                  indexPanchat = listDataDirect.indexWhere((element) => element.id == convIdPanchat);
                  if (indexPanchat == -1) return;
                  final panchatDirect = listDataDirect[indexPanchat];
                  onSelectDirectMessage(panchatDirect);
                }
              }
            } else if (keyDigital - 1 <= data.length) {
              onSelectWorkspace(data[keyDigital - 2]["id"], null);
            }
          }
        break;

        default:
        break;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(handleKey);
    super.dispose();
  }


  goToLastSelected() async  {
    var box = Hive.box('lastSelected');
    var lastConversationId = box.get('lastConversationId');
    var lastChannelId = box.get('lastChannelId');
    var isChannel = box.get('isChannel');
    var lastChannelSelected = box.get("lastChannelSelected");
    Provider.of<Channels>(context, listen: false).setLastChannelFromHive(lastChannelSelected ?? []);
    final channels = Provider.of<Channels>(context, listen: false).data;

    if (this.mounted) {
      if (lastChannelId != null && isChannel == 1) {
        final index = channels.indexWhere((e) => e["id"] == lastChannelId);

        if (index != -1) {
          final channel = channels[index];
          final workspaceId = channel["workspace_id"];

          onSelectWorkspace(workspaceId, lastChannelId);
        } else selectDefaultDirect();
      } else if (lastConversationId != null && isChannel == 0) {
        final auth = Provider.of<Auth>(context, listen: false);
        await Provider.of<DirectMessage>(context, listen: false).getInfoDirectMessage(auth.token, lastConversationId);
        Provider.of<DirectMessage>(context, listen: false).onChangeSelectedFriend(false);
        onSelectDirectMessages(lastConversationId);
      } else selectDefaultDirect();
    }
  }

  selectDefaultDirect() {
    Provider.of<Channels>(context, listen: false).openChannelSetting(false);
    Provider.of<Workspaces>(context, listen: false).tab = 0;
    Provider.of<Workspaces>(context, listen: false).changeToMessageView(true);
    Provider.of<User>(context, listen: false).selectTab("channel");
  }

  onSelectDirectMessages(directId) async {
    if (directId == null) return;
    final auth = Provider.of<Auth>(context, listen: false);
    final listDataDirect = Provider.of<DirectMessage>(context, listen: false).data;
    final index = listDataDirect.indexWhere((ele) => ele.id == directId);

    if (index != -1) {
      await Provider.of<DirectMessage>(context, listen: false).onChangeSelectedFriend(false);
      await auth.channel.push(event: "join_direct", payload: {"direct_id": directId});
      await Provider.of<DirectMessage>(context, listen: false).setSelectedDM(listDataDirect[index], auth.token);
      await Provider.of<DirectMessage>(context, listen: false).getMessageFromApiDown(directId, true, auth.token, auth.userId);
    }
  }

  checkWorkspaceStatus(workspaceId) {
    bool check = true;
    final channels = Provider.of<Channels>(context, listen: true).data;
    List workspaceChannels = channels.where((e) => e["workspace_id"] == workspaceId).toList();

    for (var c in workspaceChannels) {
      if (c["status_notify"] != "OFF" && c["new_message_count"] != null && c["new_message_count"] > 0) {
        check = false;
      }
    }

    return check;
  }

  onSelectDirectMessage(directMessage) {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentDirectMessage = Provider.of<DirectMessage>(context, listen: false).directMessageSelected;
    final channel = auth.channel;

    Provider.of<DirectMessage>(context, listen: false).onChangeSelectedFriend(false);

    if (currentDirectMessage.id == "" || currentDirectMessage.id != directMessage.id) {
      channel.push(event: "join_direct", payload: {"direct_id": directMessage.id});
      Provider.of<DirectMessage>(context, listen: false).setSelectedDM(directMessage, auth.token);
      Provider.of<DirectMessage>(context, listen: false).getMessageFromApiDown(directMessage.id, true, auth.token, auth.userId);
    }

    Utils.updateBadge(context);
  }


  onSelectWorkspace(workspaceId, channelId,) async {
    
    if (Provider.of<DirectMessage>(context, listen: false).directMessageSelected.id != ""){
      Provider.of<DirectMessage>(context, listen: false).removeMarkNewMessage(Provider.of<DirectMessage>(context, listen: false).directMessageSelected.id);
    }

    final auth = Provider.of<Auth>(context, listen: false);
    Provider.of<Workspaces>(context, listen: false).setTab(workspaceId);
    Provider.of<Workspaces>(context, listen: false).selectWorkspace(auth.token, workspaceId, context);
    Provider.of<Workspaces>(context, listen: false).getInfoWorkspace(auth.token, workspaceId, context);
    Provider.of<Workspaces>(context, listen: false).getMentions(auth.token, workspaceId, false, (v) {setState(() {setLoadMore = v; });});
    Provider.of<DirectMessage>(context, listen: false).openDirectSetting(false);

    if (channelId != null) {
      onSelectedChannel(workspaceId, channelId);
    } else {
      final lastChannelSelected = Provider.of<Channels>(context, listen: false).lastChannelSelected;
      int index = lastChannelSelected.indexWhere((e) => e["workspace_id"] == workspaceId);

      if (index == -1) {
        Provider.of<Channels>(context, listen: false).loadChannels(auth.token, workspaceId);
        final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
        onSelectedChannel(workspaceId, currentChannel["id"]);
      } else {
        onSelectedChannel(workspaceId, lastChannelSelected[index]["channel_id"]);
      }
    }

    if(Platform.isMacOS) {
      Timer(Duration(seconds: 0), () {
        Utils.updateBadge(context);
      });
    }
  }

  void openTempIssue(channelId) {
    final tempIssueState = Provider.of<Channels>(context, listen: false).tempIssueState;
    final keyScaffold = Provider.of<Auth>(context, listen: false).keyDrawer;
    if (tempIssueState != null) {
      if (tempIssueState["issueSelected"] != null) {
        if (tempIssueState["issueSelected"]["channel_id"] == channelId || (tempIssueState["channel_id"] == channelId)) {
          keyScaffold.currentState!.openEndDrawer();
          Provider.of<Channels>(context, listen: false).onChangeOpenIssue(tempIssueState["issueSelected"]);
          Provider.of<Channels>(context, listen: false).tempIssueState = {...{"issueSelected": null}};
        }
        return;
      }
      if (tempIssueState["listIssueOpen"] != null && tempIssueState["listIssueOpen"]) {
        keyScaffold.currentState!.openEndDrawer();
        Provider.of<Channels>(context, listen: false).tempIssueState = {...{"listIssueOpen": false, 'lastPage': tempIssueState["lastPage"] ?? 1}};
      }
    }
  }

  onSelectedChannel(workspaceId, channelId) async{
    final auth = Provider.of<Auth>(context, listen: false);
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    Provider.of<Channels>(context, listen: false).setCurrentChannel(channelId);
    Provider.of<Channels>(context, listen: false).onChangeLastChannel(workspaceId, channelId);
    Provider.of<Messages>(context, listen: false).loadMessages(auth.token, workspaceId, channelId);
    Provider.of<Channels>(context, listen: false).selectChannel(auth.token, workspaceId, channelId);
    Provider.of<Channels>(context, listen: false).loadCommandChannel(auth.token, workspaceId, channelId);
    Provider.of<Channels>(context, listen: false).getChannelMemberInfo(auth.token, workspaceId, channelId, currentUser["id"]);
    Provider.of<Workspaces>(context, listen: false).clearMentionWhenClickChannel(workspaceId, channelId);
    openTempIssue(channelId);

    auth.channel.push(
      event: "join_channel",
      payload: {"channel_id": channelId, "workspace_id": workspaceId}
    );
  }

  checkNewMessage(workspaceId) {
    bool check = false;
    final channels = Provider.of<Channels>(context, listen: true).data;
    List workspaceChannels = channels.where((e) => e["workspace_id"] == workspaceId).toList();

    for (var c in workspaceChannels) {
      if (!Utils.checkedTypeEmpty(c["seen"]) && c["status_notify"] != "OFF" && (c["status_notify"] != "MENTION" || (c["status_notify"] == "MENTION" && (c["new_message_count"] != null && c["new_message_count"] > 0)))) {
        check = true;
      }
    }

    return check;
  }

  snapshotReorderWorkspace(data) async {
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    var snapshot = await Hive.openBox("snapshotData_${currentUser["id"]}");
    snapshot.put("workspaces", data);
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<Workspaces>(context).data;
    final currentTab = Provider.of<Workspaces>(context, listen: true).tab;

    return SingleChildScrollView(
      controller: ScrollController(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(vertical: 2),
            child: DirectMessageButton(
              currentTab: currentTab,
              onTap: () {
                final listDataDirect = Provider.of<DirectMessage>(context, listen: false).data;
                final currentDirectMessage = Provider.of<DirectMessage>(context, listen: false).directMessageSelected;
                final listMessage = Provider.of<DirectMessage>(context, listen: false).dataDMMessages;
                final keyScaffold = Provider.of<Auth>(context, listen: false).keyDrawer;
                final auth = Provider.of<Auth>(context, listen: false);

                Provider.of<Workspaces>(context, listen: false).tab = 0;
                if(keyScaffold.currentState!.isEndDrawerOpen) keyScaffold.currentState!.openDrawer();
                Provider.of<Channels>(context, listen: false).openChannelSetting(false);
                Provider.of<Workspaces>(context, listen: false).changeToMessageView(true);
                Provider.of<User>(context, listen: false).selectTab("channel");
                var box  = Hive.box("lastSelected");
                box.put("isChannel", 0);

                if (listDataDirect.length > 0) {
                  if (currentDirectMessage.id != "") {
                    onSelectDirectMessage(currentDirectMessage);
                  } else {
                    var indexPanchat = listMessage.indexWhere((element) => element["type"] == "panchat");
                    if (indexPanchat == -1) return;
                    var convIdPanchat = listMessage[indexPanchat]["conversation_id"];
                    indexPanchat = listDataDirect.indexWhere((element) => element.id == convIdPanchat);
                    if (indexPanchat == -1) return;
                    var panchatDirect = listDataDirect[indexPanchat];
                    onSelectDirectMessage(panchatDirect);
                  }
                }

                auth.channel.push(
                  event: "join_channel",
                  payload: {"channel_id": 0, "workspace_id": 0}
                );
              }
            )
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12),
            height: 2,
            color: Color(0xff9FB3C8)
          ),
          SizedBox(height: 6),
          ReorderableListView(
            buildDefaultDragHandles: false,
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: data.map(
              (item) {
                final index = data.indexOf(item);
                final newBadgeCount = checkWorkspaceStatus(item["id"]);
                final newMessage = checkNewMessage(item["id"]);

                return ReorderableDragStartListener(
                  key: Key('$index'),
                  index: index,
                  child: WorkSpaceButton(
                    onTap: () => onSelectWorkspace(item["id"], null),
                    key: Key(item["id"].toString()),
                    item: item,
                    index: index,
                    currentTab: currentTab,
                    newBadgeCount: newBadgeCount,
                    newMessage: newMessage,
                    avtUrl: item["avatar_url"],
                  ),
                );
              }
            ).toList(),
            onReorder: (int oldIndex, int newIndex) async {
              final auth = Provider.of<Auth>(context, listen: false);
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final item = data.removeAt(oldIndex);
              data.insert(newIndex, item);
              final listId = data.map((e) => e["id"]).toList();
              setState(() {});
              final res = await Provider.of<User>(context, listen: false).changePositionWsp(listId, auth.token);
              if(res["success"] == true) { 
                snapshotReorderWorkspace(data);
              }
            }, 
          ),
          SizedBox(height: 10,),
          CreateOrJoinWorkspaceMacOs(),
        ]
      ),
    );
  }
}