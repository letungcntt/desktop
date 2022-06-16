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
import 'package:provider/provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/focus_inputbox_manager.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/update_services.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/apps/app_screen_macOS.dart';
import 'package:workcake/components/main_menu/file.dart';
import 'package:workcake/components/main_menu/task_download.dart';
import 'package:workcake/components/message_item/attachments/text_file.dart';
import 'package:workcake/components/responsesizebar_widget.dart';
import 'package:workcake/components/right_sider.dart';
import 'package:workcake/components/saved_items/saved_messages.dart';
import 'package:workcake/components/search_bar_navigation.dart';
import 'package:workcake/models/models.dart';
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
    socketListener();
  }

  static String keySend = Utils.getRandomString(16);
  static String? keyReieve;
  int retries = 0;
  static bool lostConnect = false;

  socketListener() {
    try {
      keyReieve = keySend;
      Timer(const Duration(seconds: 5), () {
        if (!mounted) return;
        final listChannelMember = Provider.of<Channels>(context, listen: false).listChannelMember;
        final index = listChannelMember.indexWhere((e) => e["id"].toString() == "1487");
        if (index == -1) return;
        final members = listChannelMember[index]["members"];
        final userId = Provider.of<Auth>(context, listen: false).userId;
        if (members.indexWhere((e) => e["id"] == userId) == -1)  return;

        final auth = Provider.of<Auth>(context, listen: false);
        final channel = auth.channel;
        if (channel == null) return;

        Timer.periodic(new Duration(seconds: 10), (timer) async {
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
                  Phoenix.rebirth(context);
                });
                return;
              } else {
                print("get socket failed");
              }
            } catch (e) { 
              print("${e.toString()} socket error");
              // sl.get<Auth>().showErrorDialog(e.toString());
            }
          } else {
            if (!mounted) return;
            if (keyReieve != keySend) {
              if (retries == 5) {
                lostConnect = true;
                return;
              } else {
                retries += 1;
              }
            } else {
              keySend = Utils.getRandomString(16);
              final channel = auth.channel;
              final userId = auth.userId;

              channel.push(event: "ping", payload: {
                "user_id": userId,
                "key": keySend
              });
              retries = 0;
            }
          }
        });

        channel.on("ping", (data, a, b) {
          keyReieve = data?["key"];
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

  openDialog(context) {
    showGeneralDialog(
      transitionDuration: Duration(milliseconds: 210),
      context: context, 
      pageBuilder: (context, ani1, ani2) {
        return AlertDialog(
          content: EditProfileDialog(),
          contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        );
      },
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: true, 
      transitionBuilder: (context, a1, a2, widget) {
        var begin = 1.3;
        var end = 1.0;
        var curve = Cubic(0.175, 0.885, 0.62, 1.275);
        var curveTween = CurveTween(curve: curve);
        var tween = Tween(begin: begin, end: end).chain(curveTween);
        var offsetAnimation = a1.drive(tween);
        return ScaleTransition(
          scale: offsetAnimation,
          child: FadeTransition(
            opacity: a1.drive(Tween(begin: 0.4, end: 1.0)),
            child: widget
          ),
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
                        Stack(
                          children: [
                            Container(
                              height: 28, width: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                                color: Color(0xff2E2E2E),
                              ),
                              child: ListAction(
                                action: "Friends", isDark: isDark,
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
                        Container(
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
                        SizedBox(width: 6),
                        InkWell(
                          onTap: () => openDialog(context),
                          child: CachedImage(
                            currentUser['avatar_url'],
                            height: 28, width: 30,
                            radius: 4,
                            name: currentUser["full_name"]
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
                                      TextButton(
                                        style: ButtonStyle(
                                          overlayColor: MaterialStateProperty.all(Palette.hoverColorDefault),
                                          padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 22)),
                                        ),
                                        child: SvgPicture.asset('assets/icons/ArchiveBox.svg'),
                                        onPressed: () => UpdateServices.checkForUpdate()
                                      ),
                                      // TextButton(
                                      //   style: ButtonStyle(
                                      //     overlayColor: MaterialStateProperty.all(Palette.hoverColorDefault),
                                      //     padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 22)),
                                      //   ),
                                      //   child: Icon(CupertinoIcons.bookmark, color: Colors.grey),
                                      //   onPressed: () async {
                                      //     openDrawer("savedMessages");
                                      //   }
                                      // ),
                                      TextButton(
                                        style: ButtonStyle(
                                          overlayColor: MaterialStateProperty.all(Palette.hoverColorDefault),
                                          padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 22)),
                                        ),
                                        child: SvgPicture.asset('assets/icons/FM1.svg'),
                                        onPressed: () async {
                                          openDrawer("file");
                                        }
                                      ),
                                      TextButton(
                                        style: ButtonStyle(
                                          overlayColor: MaterialStateProperty.all(Palette.hoverColorDefault),
                                          padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 22)),
                                        ),
                                        child: SvgPicture.asset('assets/icons/app_command.svg'),
                                        onPressed: () async {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              transitionDuration: Duration(milliseconds: 220),
                                              reverseTransitionDuration: Duration(milliseconds: 275),
                                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                var begin = 1.2;
                                                var end = 1.0;
                                                var curve = Curves.easeOutCirc;
                                                var curveTween = CurveTween(curve: curve);
                                                var tween = Tween(begin: begin, end: end).chain(curveTween);
                                                var offsetAnimation = animation.drive(tween);
                                                return ScaleTransition(
                                                  scale: offsetAnimation,
                                                  child: child,
                                                );
                                              },
                                              pageBuilder: (context, a1, a2) {
                
                                                return AppsScreenMacOS();
                                              }
                                            )
                                          );
                                        },
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

  onSelectWorkspace(workspaceId, channelId) async {
    final auth = Provider.of<Auth>(context, listen: false);
    Provider.of<Workspaces>(context, listen: false).setTab(workspaceId);
    Provider.of<Workspaces>(context, listen: false).selectWorkspace(auth.token, workspaceId, context);
    Provider.of<Workspaces>(context, listen: false).getInfoWorkspace(auth.token, workspaceId, context);
    Provider.of<Workspaces>(context, listen: false).getMentions(auth.token, workspaceId, false);
    Provider.of<DirectMessage>(context, listen: false).openDirectSetting(false);
    final selectedMentionWorkspace = Provider.of<Workspaces>(context, listen: false).selectMentionWorkspace;
    if (selectedMentionWorkspace) {
      auth.channel.push(event: "read_workspace_mentions", payload: {"workspace_id": workspaceId});
    }

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
    var snapshot = await Hive.openBox("snapshotData:${currentUser["id"]}");
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
            onReorder: (int oldIndex, int newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = data.removeAt(oldIndex);
                data.insert(newIndex, item);
                snapshotReorderWorkspace(data);
              });
            }, 
          ),
          SizedBox(height: 10,),
          CreateOrJoinWorkspaceMacOs(),
        ]
      ),
    );
  }
}