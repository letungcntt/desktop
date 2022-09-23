import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/channels/create_channel_desktop.dart';
import 'package:workcake/channels/list_channels_desktop.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_confirm_dialog.dart';
import 'package:workcake/components/custom_dialog.dart';
import 'package:workcake/components/dropdown_overlay.dart';
import 'package:workcake/components/invite_member_macOS.dart';
import 'package:workcake/components/list_archived.dart';
import 'package:workcake/components/mentions_desktop.dart';
import 'package:workcake/components/threads.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/components/workspace_settings_role.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/workspaces/apps/zimbra/service.dart';

class WorkspaceMessagesViewMacOs extends StatefulWidget {
  final openDrawer;

  WorkspaceMessagesViewMacOs({
    Key? key,
    this.openDrawer
  });
  @override
  _WorkspaceMessagesViewMacOsState createState() => _WorkspaceMessagesViewMacOsState();
}

class _WorkspaceMessagesViewMacOsState extends State<WorkspaceMessagesViewMacOs> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final boxKey = GlobalKey<_WorkspaceMessagesViewMacOsState>();
  final pinChannelKey = GlobalKey();
  final unpinChannelKey = GlobalKey();
  final mentionTabKey = GlobalKey();
  final threadTabKey = GlobalKey();
  bool showUnreadDown = false;
  bool showUnreadUp = false;
  double? scrollOffsetDown;
  double? scrollOffsetUp;
  var oldWorkspaceId;
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Timer.run(() async {
    //   if (mounted && Provider.of<Workspaces>(context, listen: false).tab != 0) {
    //     final token = Provider.of<Auth>(context, listen: false).token;
    //     final tab = Provider.of<Workspaces>(context, listen: false).tab;
    //     Provider.of<Workspaces>(context, listen: false).selectWorkspace(token, tab, context);
    //     Provider.of<Workspaces>(context, listen: false).getInfoWorkspace(token, tab, context);
    //   }
    // });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      scrollController.addListener(findUnreadOffsetViewDown);
      scrollController.addListener(findUnreadOffsetViewUp);
    });
  }

  findUnreadOffsetViewDown() {
    Rect? pinItem = findRenderObject(pinChannelKey);
    Rect? unpinItem = findRenderObject(unpinChannelKey);
    Rect boxObject = findRenderObject(boxKey)!;

    List<Rect?> listItem = [unpinItem] + [pinItem];

    for (var boxItem in listItem) {
      if (boxItem != null) {
        var containItem = boxObject.contains(Offset(boxItem.left, boxItem.bottom - 1/2 * boxItem.height)) || boxObject.bottom > boxItem.bottom - 1/2 * boxItem.height;
        setState(() {
          if (!containItem) {
            showUnreadDown = true;
            scrollOffsetDown = scrollController.offset + boxItem.bottom - boxObject.height;
          }
          else {
            showUnreadDown = false;
          }
        });
        return;
      }
    }
    setState(() {
      showUnreadDown = false;
    });
  }

  findUnreadOffsetViewUp() {
    Rect? mentionTab = findRenderObject(mentionTabKey);
    Rect? threadTab = findRenderObject(threadTabKey);
    Rect? pinItem = findRenderObject(pinChannelKey);
    Rect? unpinItem = findRenderObject(unpinChannelKey);
    Rect boxObject = findRenderObject(boxKey)!;

    List<Rect?> listItem = [mentionTab] + [threadTab] + [pinItem] + [unpinItem];

    for (var boxItem in listItem) {
      if (boxItem != null) {
        var containItem = boxObject.contains(Offset(boxItem.left, boxItem.top)) || boxObject.top < boxItem.top;
        setState(() {
          if (!containItem) {
            showUnreadUp = true;
            scrollOffsetUp = scrollController.offset + boxItem.top - 56;
          } else {
            showUnreadUp = false;
          }
        });
        return;
      }
    }
    setState(() {
      showUnreadUp = false;
    });
  }

  Rect? findRenderObject(GlobalKey key) {
    var renderObject = key.currentContext?.findRenderObject();
    var translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null) {
      var objectSize = Size(renderObject!.paintBounds.width, renderObject.paintBounds.height);
      var offset = Offset(translation.x, translation.y);

      Rect rect = Rect.fromLTWH(offset.dx, offset.dy, objectSize.width, objectSize.height);
      return rect;
    }
    return null;
  }

  void animatedUnreadDown() {
    if (scrollOffsetDown != null) {
      scrollController.animateTo(scrollOffsetDown!, duration: Duration(milliseconds: 200), curve: Curves.ease);
    }
  }

    void animatedUnreadUp() {
    if (scrollOffsetUp != null) {
      scrollController.animateTo(scrollOffsetUp!, duration: Duration(milliseconds: 200), curve: Curves.ease);
    }
  }

  @override
  void didUpdateWidget(covariant WorkspaceMessagesViewMacOs oldWidget) {
    super.didUpdateWidget(oldWidget);
    try {
      findUnreadOffsetViewDown();
      findUnreadOffsetViewUp();

      final currentWorkspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];
      if (currentWorkspaceId != oldWorkspaceId) {
        scrollController.jumpTo(0.0);
      }
    } catch (e) {
      print("workspace message view macos crash didupdate widget ${e.toString()}");
    }
  }

  openFileSelector(workspaceId) async {
    List resultList = [];
    final auth = Provider.of<Auth>(context, listen: false);

    try {

      var myMultipleFiles =  await Utils.openFilePicker([
        XTypeGroup(
          extensions: ['jpg', 'jpeg', 'png'],
        )
      ]);
      for (var e in myMultipleFiles) {
        Map newFile = {
          "name": e["name"],
          "file": e["file"],
          "path": e["path"]
        };
        resultList.add(newFile);
      }

      if(resultList.length > 0) {
        final image = resultList[0];
        String imageData = base64.encode(image["file"]);

        if (image["file"].lengthInBytes > 10000000) {
          final uploadFile = {
            "filename": image["name"],
            "path": imageData,
            "length": imageData.length,
          };
          await Provider.of<Workspaces>(context, listen: false).uploadAvatarWorkspace(auth.token, workspaceId, uploadFile, "image");
        } else {
          final uploadFile = {
            "filename": image["name"],
            "path": imageData,
            "length": imageData.length,
          };
          await Provider.of<Workspaces>(context, listen: false).uploadAvatarWorkspace(auth.token, workspaceId, uploadFile, "image");
        }
      }
    } on Exception catch (e) {
      print("$e Cancel");
    }
  }


  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    final currentMember = Provider.of<Workspaces>(context, listen: false).currentMember;
    final channels = currentWorkspace["id"] != null
      ? Provider.of<Channels>(context, listen: true).data.where((e) => e["workspace_id"] == currentWorkspace["id"] && !Utils.checkedTypeEmpty(e["is_archived"])).toList()
      : [];
    final noBlurChannels = channels.where((c) => c["status_notify"] == "NORMAL" || c["status_notify"] == "SILENT").toList();
    final blurChannels = channels.where((c) => c["status_notify"] == "MENTION" || c["status_notify"] == "OFF").toList();
    final newChannels = noBlurChannels + blurChannels;
    final pinnedChannels = newChannels.where((channel) => channel["pinned"]).toList();
    final unpinChannels = newChannels.where((channel) => !channel["pinned"]).toList();
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    final isDark = auth.theme == ThemeType.DARK;
    oldWorkspaceId = currentWorkspace["id"];
    // final workspaceId = currentWorkspace["id"];
    return Column(
      children: <Widget>[
        currentWorkspace["id"] == null ? Container() : HoverItem(
          colorHover: Colors.white.withOpacity(0.15),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Palette.selectChannelColor),
              ),
            ),
            padding:EdgeInsets.only(left: 24, right: 18),
            height: 56,
            child: DropdownOverlay(
              menuDirection: MenuDirection.end,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "${currentWorkspace["id"] != null ? currentWorkspace["name"] : ''}",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 18, color: Palette.defaultTextDark, fontWeight: FontWeight.w600)
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_down,
                          color: Palette.defaultTextDark,
                          size: 15,
                        ),
                      ]
                    ),
                  ],
                ),
              ),
              childOnTap: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${currentWorkspace["id"] != null ? currentWorkspace["name"] : ''}",
                        style: TextStyle(fontSize: 18, color: Palette.defaultTextDark, fontWeight: FontWeight.w600)
                      ),
                      Icon(
                        CupertinoIcons.clear,
                        color: Palette.defaultTextDark,
                        size: 16,
                      ),
                    ]
                  ),
                ],
              ),
              dropdownWindow: Container(
                decoration: BoxDecoration(
                  color: isDark ? Color(0xff4C4C4C) : Colors.white,
                  borderRadius: BorderRadius.circular(4)
                ),
                width: 130,
                child: Column(
                  children: [
                    if (currentMember['role_id'] != null && currentMember['role_id'] <= 4)
                    HoverItem(
                      colorHover: isDark ? Palette.hoverColorDefault : Color(0xffDBDBDB),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        height: 42,
                        child: InkWell(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(S.of(context).invitePeople),
                              SvgPicture.asset(
                                'assets/icons/invite.svg',
                                color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                                width: 16, height: 16
                              )
                            ],
                          ),
                          onTap: () => onShowInviteWorkspaceDialog(context),
                        ),
                      ),
                    ),
                    if (currentMember['role_id'] != null && currentMember['role_id'] <= 4)
                    HoverItem(
                      colorHover: isDark ? Palette.hoverColorDefault : Color(0xffDBDBDB),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        height: 42,
                        child: InkWell(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(S.current.createChannel),
                              SvgPicture.asset(
                                'assets/icons/create.svg',
                                color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                                width: 16, height: 16
                              )
                            ],
                          ),
                          onTap: () => showDialogCreateChannel(context),
                        ),
                      ),
                    ),
                    HoverItem(
                      colorHover: isDark ? Palette.hoverColorDefault : Color(0xffDBDBDB),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        height: 42,
                        child: InkWell(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(S.current.joinChannel),
                              SvgPicture.asset(
                                'assets/icons/join_channel.svg',
                                color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                                width: 14, height: 14
                              )
                            ],
                          ),
                          onTap: () => showDialogJoinChannel(context),
                        ),
                      ),
                    ),
                    Container(
                      decoration:  BoxDecoration(border: Border(bottom: BorderSide(width: 0.2, color: Colors.grey))),
                    ),
                    if (currentMember['role_id'] != null && currentMember['role_id'] <= 2) HoverItem(
                      colorHover: isDark ? Palette.hoverColorDefault : Color(0xffDBDBDB),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 13),
                        height: 42,
                        child: InkWell(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(S.current.workspaceName),
                              Icon(PhosphorIcons.notePencil, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, size: 18,)
                            ],
                          ),
                          onTap: () {
                            showCustomDialog(context, "Edit Workspace Name");
                          },
                        ),
                      ),
                    ),
                    HoverItem(
                      colorHover: isDark ? Palette.hoverColorDefault : Color(0xffDBDBDB),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        height: 42,
                        child: InkWell(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(S.current.changeNickname),
                              SvgPicture.asset(
                                'assets/icons/EditButton.svg',
                                color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                                width: 16, height: 16
                              )
                            ],
                          ),
                          onTap: () => showDialogChangeName(context),
                        ),
                      ),
                    ),
                    if (currentWorkspace["owner_id"] != null && currentWorkspace["owner_id"] == currentUser["id"])
                    HoverItem(
                      colorHover: isDark ? Palette.hoverColorDefault : Color(0xffDBDBDB),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        height: 42,
                        child: InkWell(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(S.current.changeAvatar),
                              Icon(Icons.photo,size: 18,color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight)
                            ],
                          ),
                          onTap: () {
                            openFileSelector(oldWorkspaceId);
                          },
                        ),
                      ),
                    ),
                    HoverItem(
                      colorHover: isDark ? Palette.hoverColorDefault : Color(0xffDBDBDB),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        height: 42,
                        child: InkWell(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(S.current.listArchive),
                              Icon(Icons.archive_outlined, size: 18, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight)
                            ],
                          ),
                          onTap: () => showDialogArchived(context),
                        ),
                      ),
                    ),
                    if (currentMember['role_id'] != null && currentMember['role_id'] <= 3)
                    HoverItem(
                      colorHover: isDark ? Palette.hoverColorDefault : Color(0xffDBDBDB),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        height: 42,
                        child: InkWell(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(S.current.setrole),
                              Icon(PhosphorIcons.userCircleGear,color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,size: 18,),
                            ],
                          ),
                          onTap: () {
                            showSettingsWs(context);
                          },
                        ),
                      ),
                    ),
                    Container(
                      decoration:  BoxDecoration(border: Border(bottom: BorderSide(width: 0.2, color: Colors.grey))),
                    ),
                    if (currentWorkspace["owner_id"] != null && currentWorkspace["owner_id"] == currentUser["id"])
                    HoverItem(
                      colorHover: isDark ? Palette.hoverColorDefault : Color(0xffDBDBDB),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        height: 42,
                        child: InkWell(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(S.current.deleteWorkspace, style: TextStyle(color: Palette.errorColor),),
                              SvgPicture.asset(
                                'assets/icons/delete_member.svg',
                                color: Palette.errorColor,
                                width: 16, height: 16
                              )
                            ],
                          ),
                         onTap: () => onShowDeleteWorkspaceDialog(context),
                        ),
                      ),
                    ),
                    HoverItem(
                      colorHover: isDark ? Palette.hoverColorDefault : Color(0xffDBDBDB),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.only(left: 14,right: 12),
                        height: 42,
                        // decoration:  BoxDecoration(border: Border(bottom: BorderSide(width: 0.2, color: Colors.grey))),
                        child: InkWell(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(S.current.leaveWorkspace, style: TextStyle(color: Palette.errorColor)),
                              Icon(Icons.output, color: Palette.errorColor, size: 18, )
                            ],
                          ),
                          onTap: () => showDialogLeaveWorkspace(context),
                        )
                      ),
                    )
                  ]
                )
              ),
              isAnimated: true
            )
          )
        ),
        Expanded(
          key: boxKey,
          child: Stack(
            alignment: AlignmentDirectional.topCenter,
            children: [
              SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    MentionsDesktop(mentionTabKey: mentionTabKey),
                    ThreadsTab(threadTabKey: threadTabKey),
                    pinnedChannels.length > 0
                      ? ListChannelDesktop(channels: pinnedChannels, title: S.of(context).pinned, id: currentWorkspace["id"] ?? 0, channelItemKey: pinChannelKey)
                      : Container(),
                    ListChannelDesktop(channels: unpinChannels, title: S.of(context).channels, id: currentWorkspace["id"] ?? 0, channelItemKey: unpinChannelKey),
                    ListAppAdded(id: currentWorkspace["id"], appIds: currentWorkspace["app_ids"] ?? [])
                  ],
                )
              ),
              AnimatedPositioned(
                curve: Curves.easeIn,
                duration: Duration(milliseconds: 300),
                top: showUnreadUp ? 5.0 : -50.0,
                child: TextButton.icon(
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.grey[200]), shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))), padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.fromLTRB(10, 8, 16, 8))),
                  onPressed: animatedUnreadUp,
                  icon: Icon(CupertinoIcons.arrow_up, size: 13, color: Colors.black),
                  label: Text(S.of(context).moreUnread, style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal),),
                ),
              ),
              AnimatedPositioned(
                curve: Curves.easeIn,
                duration: Duration(milliseconds: 300),
                bottom: showUnreadDown ? 10.0 : -50.0,
                child: TextButton.icon(
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.grey[200]), shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))), padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.fromLTRB(10, 8, 16, 8))),
                  onPressed: animatedUnreadDown,
                  icon: Icon(CupertinoIcons.arrow_down, size: 13, color: Colors.black),
                  label: Text(S.of(context).moreUnread, style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal),),
                )
              )
            ]
          )
        )
      ]
    );
  }
}

showSettingsWs(context) {
  Navigator.pop(context);

  showModal(
    context: context,
    builder: (BuildContext context) {
      return WorkspaceSettingsRole();
    }
  );
}

showDialogJoinChannel(context) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;
  Navigator.pop(context);

  showModal(
    context: context,
    builder: (BuildContext context) {
      return Container(
        child: AlertDialog(
          backgroundColor: isDark ? Color(0xff3D3D3D) : Color(0xffF8F8F8),
          contentPadding: EdgeInsets.zero,
          content: Container(
            height: 180.0,
            width: 400.0,
            child: Center(
              child: InviteMemberMacOS(type: 'toChannel', isKeyCode: true),
            )
          ),
        ),
      );
    }
  );
}

showDialogArchived(context) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;
  Navigator.pop(context);

  showModal(
    context: context,
    builder: (BuildContext context) {
      return Container(
        child: AlertDialog(
          backgroundColor: isDark ? Color(0xff3D3D3D) : Color(0xffF8F8F8),
          contentPadding: EdgeInsets.zero,
          content: Container(
            height: 300.0,
            width: 400.0,
            child: Center(
              child: ListArchived(),
            )
          ),
        ),
      );
    }
  );
}


showDialogCreateChannel(context) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;
  Navigator.pop(context);

  showModal(
    context: context,
    builder: (BuildContext context) {
      return Container(
        child: AlertDialog(
          contentPadding: EdgeInsets.zero,
          backgroundColor: isDark ? Color(0xff3D3D3D) : Colors.white,
          content: Container(
            height: 650.0,
            width: 528.0,
            child: Center(
              child: CreateChannelDesktop(),
            )
          ),
        ),
      );
    }
  );
}

onShowInviteWorkspaceDialog(context) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;
  Navigator.pop(context);

  showModal(
    context: context,
    builder: (BuildContext context) {
      return Container(
        child: AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Container(
            // constraints: BoxConstraints(
            //   maxHeight: 622.0,
            //   maxWidth: 528.0
            // ),
            height: 510.0,
            width: 528.0,
            child: Column(
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(5),topRight: Radius.circular(5)),
                    color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
                  ),
                  padding: const EdgeInsets.only(left: 16, top: 2,bottom: 2,right: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          S.current.inviteToWorkspace ,
                          style: TextStyle(color: isDark ? Palette.defaultTextDark : Color(0xff1F2933), fontSize: 14.0, fontWeight: FontWeight.w700, overflow: TextOverflow.ellipsis)
                        ),
                      ),
                      Container(
                        height: 35,
                        width: 35,
                        child: HoverItem(
                          colorHover: isDark ? Palette.hoverColorDefault : Color(0xffDBDBDB),
                          child: InkWell(
                            onTap: (){Navigator.of(context).pop();},
                            child: Icon(PhosphorIcons.xCircle,size: 18,)),
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(child: InviteMemberMacOS(type: 'toWorkspace', isKeyCode: false)),
              ],
            )
          ),
        ),
      );
    }
  );
}

showCustomDialog(context,titleDialog) {
  final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
  final auth = Provider.of<Auth>(context, listen: false);
  String string = titleDialog == "Join to Channel" ? "" : currentWorkspace["name"];
  String title = "WORKSPACE NAME";
  Navigator.pop(context);

  onChangeWorkspaceName(value) async {
    if (value != "") {
      Map workspace = new Map.from(currentWorkspace);
      workspace["name"] = value;
      await Provider.of<Workspaces>(context, listen: false).changeWorkspaceInfo(auth.token, currentWorkspace["id"], workspace);
      Navigator.of(context, rootNavigator: true).pop("Discard");
    }
  }

  showModal(
    context: context,
    builder: (BuildContext context) {
      return CustomDialog(title: title, titleField: 'Workspace name', displayText: string, onSaveString: onChangeWorkspaceName);
    }
  );
}

onShowDeleteWorkspaceDialog(context) {
  final auth = Provider.of<Auth>(context, listen: false);
  final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
  Navigator.pop(context);

  showModal(
    context: context,
    builder: (BuildContext context) {
      return CustomConfirmDialog(
        title: S.of(context).deleteWorkspace,
        subtitle: S.of(context).descDeleteWorkspace,
        onConfirm: () {
          Provider.of<Workspaces>(context, listen: false).deleteWorkspace(auth.token, currentWorkspace["id"], context);
        },
      );
    }
  );
}

showDialogChangeName(context) {
  final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
  final currentMember = Provider.of<Workspaces>(context, listen: false).currentMember;
  final currentUser = Provider.of<User>(context, listen: false).currentUser;
  final auth = Provider.of<Auth>(context, listen: false);
  String nickname = currentMember["nickname"] ?? currentUser["full_name"];
  String title = S.of(context).changeNickname.toUpperCase();
  Navigator.pop(context);

  onChangeNickname(value) async {
    if (value != "") {
      Map member = new Map.from(currentMember);
      member["nickname"] = value;

      await Provider.of<Workspaces>(context, listen: false).changeWorkspaceMemberInfo(auth.token, currentWorkspace["id"], member);
      Navigator.of(context, rootNavigator: true).pop("Discard");
    }
  }

  showModal(
    context: context,
    builder: (BuildContext context) {
      return CustomDialog(title: title, titleField: 'Your Nickname', displayText: nickname, onSaveString: onChangeNickname);
    }
  );
}

showDialogLeaveWorkspace(context) {
  final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
  final auth = Provider.of<Auth>(context, listen: false);
  Navigator.pop(context);

  onLeaveWorkspace() {
    Provider.of<Workspaces>(context, listen: false).leaveWorkspace(auth.token, currentWorkspace["id"], auth.userId);
  }

  showModal(
    context: context,
    builder: (BuildContext context) {
      return CustomConfirmDialog(
        title: S.of(context).leaveWorkspace,
        subtitle: S.of(context).descLeaveWorkspace,
        onConfirm: onLeaveWorkspace
      );
    }
  );
}

class AppTab extends StatefulWidget {
  const AppTab({Key? key}) : super(key: key);

  @override
  State<AppTab> createState() => _AppTabState();
}

class _AppTabState extends State<AppTab> {
  bool isHover = false;
  @override
  Widget build(BuildContext context) {
    final selectedTab = Provider.of<User>(context, listen: true).selectedTab;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final keyScaffold = auth.keyDrawer;

    return Container(
      height: 32,
      margin: EdgeInsets.only(right: 8, left: 8, bottom: 4),
      child: InkWell(
        onHover: (hover){
          setState(() {
            isHover = hover;
          });
        },
        onTap: () {
          Provider.of<User>(context, listen: false).selectTab("app");
          if(keyScaffold.currentState!.isEndDrawerOpen) keyScaffold.currentState!.openDrawer();
          auth.channel.push(
            event: "join_channel",
            payload: {"channel_id": 0, "workspace_id": currentWorkspace["id"]}
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8),
          decoration: selectedTab == "app" ? BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(3)),
            color: Palette.selectChannelColor
          )
          : isHover ? BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(3)),
              color: Palette.backgroundRightSiderDark
            )
          : BoxDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  SizedBox(width: 6),
                  ClipRRect(
                    child: SvgPicture.asset(
                      'assets/icons/app_command.svg',
                      width: 14, height: 14,
                      color: selectedTab == "app"
                        ? Colors.white
                        : isDark
                          ? Palette.darkTextListChannel
                          : Palette.lightTextListChannel,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Add apps",
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: selectedTab == "app"
                          ? Colors.white
                          : isDark
                            ? Palette.darkTextListChannel
                            : Palette.lightTextListChannel,
                    )
                  ),
                ]
              ),
            ]
          )
        ),
      ),
    );
  }
}

class ListAppAdded extends StatefulWidget {
  final id;
  final appIds;
  final appItemKey;
  const ListAppAdded({Key? key, this.id, this.appIds, this.appItemKey}) : super(key: key);

  @override
  State<ListAppAdded> createState() => _ListAppAddedState();
}

class _ListAppAddedState extends State<ListAppAdded> {
  var open = true;
  List data = [];

  @override
  void initState() {
    super.initState();

    getStateShowPinned();
  }

  @override
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.id != widget.id) {
      int index = data.indexWhere((ele) => ele["id"] == widget.id);
      if (index > -1) {
        this.setState(() {
          open = Utils.checkedTypeEmpty(data[index]["isShowAppAdded"]);
        });
      }
    }
  }

  getStateShowPinned() async{
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    var box = await Hive.openBox("stateShowPinned:${currentUser["id"]}");
    data = box.get("data") ?? [];
  }

  showCurrentApp() {
    final currentApp = Provider.of<Channels>(context, listen: false).currentApp;
    if (currentApp != {}) {
      final index = widget.appIds.indexWhere((e) => e == listAllApp);

      if (!open && index != -1) {
        return true;
      } else {
        return false;
      }
    }
  }

  onChangeStatePinned(value) {
    Provider.of<Workspaces>(context, listen: false).onSaveStatePinned(context, widget.id, null, null, value);
    int index = data.indexWhere((e) => e["id"] == widget.id);
    if (index > -1) {
      data[index]["isShowAppAdded"] = value;
    }
    this.setState(() {
      open = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final listActive = listAllApp.where((e) => widget.appIds.contains(e["id"])).toList();
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;

    return Column(
      children: [
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: Key(widget.id.toString()),
            childrenPadding: EdgeInsets.symmetric(horizontal: 12),
            onExpansionChanged: (value) {
              onChangeStatePinned(value);
            },
            title: Text(
              "Apps",
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w400,
                color: isDark ? Palette.darkTextListChannel : Palette.lightTextListChannel
              )
            ),
            initiallyExpanded: Utils.checkedTypeEmpty(open),
            trailing: Icon(
              Utils.checkedTypeEmpty(open)
                ? Icons.keyboard_arrow_down
                : Icons.keyboard_arrow_right,
              color: isDark ? Palette.darkTextListChannel : Palette.lightTextListChannel,
              size: 22
            ),
            children: Utils.checkedTypeEmpty(open) ? listActive.map<Widget>((e){
              return AppItem(app: e);
            }).toList() : []
          ),
        ),
        AppTab(),
      ],
    );
  }
}

class AppItem extends StatefulWidget {
  final app;
  final id;
  const AppItem({Key? key, this.app, this.id}) : super(key: key);

  @override
  State<AppItem> createState() => _AppItemState();
}

class _AppItemState extends State<AppItem> {
  bool isHover = false;

  @override
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if (oldWidget.app["id"] != widget.app["id"]) {
    //   setState(() => appId = widget.app["id"]);
    // }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = Provider.of<User>(context, listen: true).selectedTab;
    final currentApp = Provider.of<Channels>(context, listen: false).currentApp;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final keyScaffold = auth.keyDrawer;

    return Container(
      height: 32,
      child: InkWell(
        onHover: (hover){
          setState(() {
            isHover = hover;
          });
        },
        onTap: () async {
          await Provider.of<Channels>(context, listen: false).setCurrentApp(widget.app);
          Provider.of<User>(context, listen: false).selectTab("appItem");
          if(keyScaffold.currentState!.isEndDrawerOpen) keyScaffold.currentState!.openDrawer();
          auth.channel.push(
            event: "join_channel",
            payload: {"channel_id": 0, "workspace_id": currentWorkspace["id"]}
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8),
          decoration: (selectedTab == "appItem" && currentApp["id"] == widget.app["id"]) ? BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(3)),
            color: Palette.selectChannelColor
          )
          : isHover ? BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(3)),
              color: Palette.backgroundRightSiderDark
            )
          : BoxDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4)
                    ),
                    child: ClipRRect(
                      child: Image.asset(
                        widget.app["avatar_app"].toString(),
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    widget.app["name"].toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: (selectedTab == "appItem" && currentApp["id"] == widget.app["id"])
                          ? Colors.white
                          : isDark
                            ? Palette.darkTextListChannel
                            : Palette.lightTextListChannel,
                    )
                  ),
                ]
              ),
              (widget.app["name"] == "Zimbra") ? Container(
                child: StreamBuilder(
                  stream: ServiceZimbra.streamAccounts.stream,
                  builder: (context, snapshot) {
                    return Container(
                      width:  8, height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        color: ServiceZimbra.getNewMessageCount(currentWorkspace["id"]) > 0 ? Colors.red : null
                      )
                    );
                  }
                ),
              ) : Container()
            ]
          )
        ),
      ),
    );
  }
}