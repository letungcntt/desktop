import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/channels/channel_member.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/create_direct_message.dart';
import 'package:workcake/components/crop_image_dialog.dart';
import 'package:workcake/components/custom_confirm_dialog.dart';
import 'package:workcake/components/custom_dialog.dart';
import 'package:workcake/components/message_item/attachments/text_file.dart';
import 'package:workcake/components/modal_invite_desktop.dart';
import 'package:workcake/components/option_notification_mode.dart';
import 'package:workcake/components/profile/user_profile_desktop.dart';
import 'package:workcake/direct_message/render_media.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/models/models.dart';
import '../media_conversation/dm_media.dart';

class DirectInfoDesktop extends StatefulWidget {
  DirectInfoDesktop({Key? key}) : super(key: key);

  @override
  _DirectInfoDesktopState createState() => _DirectInfoDesktopState();
}

class _DirectInfoDesktopState extends State<DirectInfoDesktop> {
  bool selectedFile = false;
  String type  = 'image';

  @override
  initState() {
    super.initState();
    RawKeyboard.instance.addListener(handleEvent);
  }

  KeyEventResult handleEvent(RawKeyEvent event) {
    if(event is RawKeyDownEvent) {
      if(event.isKeyPressed(LogicalKeyboardKey.escape)) {
        if(selectedFile) setState(() => selectedFile = false);
        else {
          Provider.of<Channels>(context, listen: false).openChannelSetting(false);
          Provider.of<DirectMessage>(context, listen: false).openDirectSetting(false);
        }
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(handleEvent);
    super.dispose();
  }

  getListUser(dm) {
    List list= [];
    final user = dm.user;

    user.forEach((e) {
      list.add(e["full_name"]);
    });

    return list.join(', ');
  }

  _setSelectedItem(){
    setState((){
      selectedFile = !selectedFile;
    });
  }

  updateAvatarGroup(uploadFile) async{
    final auth = Provider.of<Auth>(context, listen: false);

    final body = {
      "file": uploadFile,
      "content_type": 'image'
    };

    final urlUploadImage = Utils.apiUrl + 'workspaces/0/contents?token=${auth.token}';
    try {
      final response = await http.post(Uri.parse(urlUploadImage), headers: Utils.headers, body: json.encode(body));
      final responseData = json.decode(response.body);
      final avatarUrl = responseData["content_url"];

      if (responseData["success"] == true) {
        final DirectModel directMessage = Provider.of<DirectMessage>(context, listen: false).directMessageSelected;
        LazyBox box  = Hive.lazyBox('pairKey');

        final urlUploadAvatarGroupDM = "${Utils.apiUrl}direct_messages/${directMessage.id}/update_dm?token=${auth.token}&device_id=${await box.get("deviceId")}";
        Dio().post(urlUploadAvatarGroupDM, data: {"data":  await Utils.encryptServer({"avatar_url": avatarUrl})});
      }
    } catch (e) {
      print(e);
    }
  }

  openFileSelector() async {
    List resultList = [];    
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
        showDialog(
          context: context, 
          builder: (BuildContext context){
            return Dialog(
              child: CropImageDialog(
                image: image,
                onCropped: updateAvatarGroup
              ),
            );
          }
        );
      }
    } on Exception catch (e) {
      print("$e Cancel");
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    final deviceHeight = MediaQuery.of(context).size.height;
    final DirectModel directMessage = Provider.of<DirectMessage>(context, listen: true).directMessageSelected;
    final currentUser = Provider.of<User>(context, listen: true).currentUser;
    final users = directMessage.user;
    final index = users.indexWhere((e) => e["user_id"] != currentUser["id"]);
    final otherUser = index  == -1 ? {} : users[index];

    String status = "NORMAL";
    int indexUser = users.indexWhere((element) => element["user_id"] == auth.userId);
    if (indexUser != -1) {
      status = users[indexUser]["status_notify"] ?? "NORMAL";
    }

    return Container(
      height: deviceHeight,
      width: 330,
      decoration: BoxDecoration(
        color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: isDark ? Border(
                    bottom: BorderSide(color: Palette.borderSideColorDark),
                  ) : Border(),
                  color: Palette.backgroundTheardDark
                ),
                height: 56,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(S.current.details, textAlign: TextAlign.center, style: TextStyle(color: Palette.defaultTextDark, fontSize: 17, fontWeight: FontWeight.w500)),
                    IconButton(
                      onPressed: () {
                        Provider.of<Channels>(context, listen: false).openChannelSetting(false);
                        Provider.of<DirectMessage>(context, listen: false).openDirectSetting(false);
                      },
                      icon: Icon(
                        Icons.close,
                        color: Color(0xffF0F4F8),
                        size: 22
                      ),
                    )
                  ],
                ),
              ),
              Container(
                child: users.length <= 2 ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: isDark ? Colors.transparent : Color(0xffE4E7EB), 
                            width: 0.5
                          )
                        )
                      ),
                      padding: EdgeInsets.only(top: 24, bottom: 12),
                      child: CachedImage(
                        users.length == 2 ? otherUser["avatar_url"] : currentUser['avatar_url'],
                        width: 132,
                        height: 132,
                        radius: 66,
                        name: users.length == 2 ? otherUser["full_name"] : currentUser['full_name'],
                        fontSize: 20
                      )
                    ),

                    Text(
                      (users.length == 2 ? otherUser["full_name"] : currentUser['full_name']) ?? "",
                      style: TextStyle(
                        color: isDark ? Colors.grey[200] : Colors.grey[800],
                        fontSize: 18,
                        fontWeight: FontWeight.w400
                      )
                    ),
                  ],
                ) : Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(top: 14),
                      child: directMessage.avatarUrl != null ? Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(color: isDark ? Colors.transparent : Color(0xffE4E7EB), width: 0.5)
                              )
                            ),
                            padding: const EdgeInsets.only(top: 4),
                            child: CachedImage(
                              directMessage.avatarUrl,
                              width: 132,
                              height: 132,
                              radius: 66,
                              name: directMessage.name,
                              fontSize: 20
                            )
                          ),
                          Positioned(
                            left: 100,
                            bottom: 98,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? Palette.borderSideColorDark : Color(0xffEDEDED),
                                borderRadius: const BorderRadius.all(Radius.circular(16))
                              ),
                              child: HoverItem(
                                colorHover: Palette.hoverColorDefault,
                                isRound: true, radius: 16.0,
                                child: InkWell(
                                  onTap: () => openFileSelector(),
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    child: Icon(PhosphorIcons.cameraThin, color: isDark ? Colors.grey[200] : Colors.grey[800], size: 18)
                                  ),
                                ),
                              ),
                            )
                          )
                        ],
                      ) : ListMember()
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: directMessage.displayName.length * 10 > 200 ? 200 : directMessage.displayName.length * 10,
                            child: Text(
                              directMessage.displayName,
                              style: TextStyle(
                                color: isDark ? Colors.grey[200] : Colors.grey[800],
                                fontSize: 18,
                                fontWeight: FontWeight.w400
                              ), overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 2),
                          HoverItem(
                            colorHover: Palette.hoverColorDefault,
                            isRound: true, radius: 4.0,
                            child: InkWell(
                              onTap: () => showInputDialog(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: SvgPicture.asset('assets/icons/EditButton.svg', color: isDark ? Colors.grey[200] : Colors.grey[800])
                              ),
                            ),
                          ),
                          if(directMessage.avatarUrl == null) HoverItem(
                            colorHover: Palette.hoverColorDefault,
                            isRound: true, radius: 4.0,
                            child: InkWell(
                              onTap: () => openFileSelector(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Icon(PhosphorIcons.cameraThin, color: isDark ? Colors.grey[200] : Colors.grey[800], size: 18)
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Divider(height: 0.5)
              ),
              SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: ScrollController(),
                  child: Column(
                    children: [
                      if(users.length > 2) Container(
                        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: MembersTile(leading: null, isDark: isDark)
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        child: ListAction(
                          action: '', radius: 4.0, isRound: true,  isDark: isDark,
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => NotificationDM(
                                  conversationId: directMessage.id, 
                                  onSave: Provider.of<DirectMessage>(context, listen: false).updateSettingConversationMember
                                )
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              child: Row(
                                children: [
                                  getIconNotificationByStatusDM(status, isDark),
                                  SizedBox(width: 8),
                                  Text('Notification', style: TextStyle(color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark)),
                                ],
                              )
                            )
                          ),
                        )
                      ),
                      SizedBox(height: 4),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        child: ListAction(
                          action: '', radius: 4.0, isRound: true,  isDark: isDark,
                          child: InkWell(
                            onTap: () => inviteDirectModel(context, directMessage),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/Invite.svg',
                                    color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                                    width: 16.0, height: 16.0,
                                  ),
                                  SizedBox(width: 8),
                                  Text(directMessage.user.length > 2 ? 'Invite people' : S.current.createGroup, style: TextStyle(color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      RenderMedia(
                        id: directMessage.id,
                        onChanged: (String  value) => setState(() {
                          type = value;
                          selectedFile  = true; 
                        }),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Divider(height: 0.5)
                      ),
                      SizedBox(height: 24),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        child: ListAction(
                          action: '', radius: 4.0, isRound: true,  isDark: isDark,
                          child: InkWell(
                            onTap: () => showConfirmDialog(context),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Palette.hoverColorDefault,
                                borderRadius: BorderRadius.all(Radius.circular(4.0))
                              ),
                              width: double.infinity,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(users.length > 2 ? S.current.leaveGroup : 'Leave conversation', style: TextStyle(color: Color(0xffEF5350))),
                                  SvgPicture.asset('assets/icons/LeaveChannel.svg', width: 18, color: Colors.red)
                                ],
                              )
                            ),
                          )
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ]
          ),
          AnimatedPositioned(
            curve: Curves.easeOutExpo,
            duration: Duration(milliseconds: 500),
            left: selectedFile  ? 0.0 : 500.0,
            height:  MediaQuery.of(context).size.height - 60,
            // top: 0.0, bottom: 0.0,
            // child: Text("Sdfsdfdsfdsfsdfsdff")
            child: Container(
              child: MediaConversationRender(type: type, id: directMessage.id, back: _setSelectedItem))
          )
        ],
      ),
    );
  }
}

class ListMember extends StatelessWidget {
  const ListMember({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DirectModel directMessage = Provider.of<DirectMessage>(context, listen: true).directMessageSelected;
    // .getUser() de lay tat ca nguoi dang trong hoi thoaij
    // .user lay tat ca nguoi dung (trong ht va da roi hoi thoai)
    final users = directMessage.getUser();
    final isDark = Provider.of<Auth>(context).theme == ThemeType.DARK;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      width: users.length > 3 ? 280 : 240,
      height: 100,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          users.length <= 4 ? Container() :
          Positioned(
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white60,
                border: Border.all(
                  color: isDark ? Color(0xff5E5E5E ) : Color(0xffC9C9C9),
                  width: 0.5
                )
              ),
              padding: EdgeInsets.all(1),
              width: 96,
              height: 96,
              child: Center(
                child: Text(" +${users.length - 4}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400))
              )
            )
          ),
          users.length <= 3 ? Container() : 
          Positioned(
            right: users.length > 3 ? 70 : 0,
            child: CachedImage(
              users[3]["avatar_url"],
              width: 96,
              height: 96,
              radius: 66,
              name: users[3]["full_name"],
              fontSize: 20
            )
          ),
          users.length <= 2 ? Container() : 
          Positioned(
            right: users.length > 3 ? 100 : 60,
            child: CachedImage(
              users[2]["avatar_url"],
              width: 96,
              height: 96,
              radius: 66,
              name: users[2]["full_name"],
              fontSize: 20
            )
          ),
          users.length <= 1 ? Container() : 
          Positioned(
            right: users.length > 3 ? 140 : 100,
            child: CachedImage(
              users[1]["avatar_url"],
              width: 96,
              height: 96,
              radius: 66,
              name: users[1]["full_name"],
              fontSize: 20
            ),
          ),
          users.length == 0 ? Container() :
          CachedImage(
            users[0]["avatar_url"],
            width: 96,
            height: 96,
            radius: 66,
            name: users[0]["full_name"],
            fontSize: 20
          ),
        ]
      ),
    );
  }
}

class AboutTile extends StatefulWidget {
  const AboutTile({
    Key? key,
    @required this.leading,
    @required this.isDark,
  }) : super(key: key);

  final leading;
  final isDark;

  @override
  _AboutTileState createState() => _AboutTileState();
}

class _AboutTileState extends State<AboutTile> {
  var open;

  @override
  void initState() {
    super.initState();
    Timer.run(() async {
      var box = await Hive.openBox('drafts');
      var openAbout = box.get('openAbout');

      if (openAbout == null) {
        this.setState(() { open = false; });
      } else {
        this.setState(() { open = openAbout; });
      }
    });
  }

  onExpand(value) async{
    var box = await Hive.openBox('drafts');
    box.put('openAbout', value);

    this.setState(() {
      open = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final DirectModel directMessage = Provider.of<DirectMessage>(context, listen: true).directMessageSelected;
    final currentUser = Provider.of<User>(context, listen: true).currentUser;
    final users = directMessage.user;
    final index = users.indexWhere((e) => e["user_id"] != currentUser["id"]);
    var otherUser = index == -1 ? {} : users[index];
    if (users.length == 1) otherUser = users[0];
    // print(users);

    return open == null ? Container() : ExpansionTile(
      childrenPadding: EdgeInsets.only(bottom: 16, left: 16, right: 16),
      tilePadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      initiallyExpanded: open,
      leading: widget.leading,
      title: Text(S.current.about, style: TextStyle(fontSize: 14.5, color: isDark ? Colors.grey[300] : Color(0xff3D3D3D))),
      trailing: Icon(open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, color: isDark ? Colors.grey[300] : Color(0xff3D3D3D), size: 24),
      onExpansionChanged: (value) {
        onExpand(value);
      },
      children: [
        Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: widget.isDark ? Palette.backgroundRightSiderDark : Palette.topicTile,
              ),
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.current.displayName,
                          style: TextStyle(color: Color(0xFF949494), fontSize: 12,fontWeight: FontWeight.w500),
                        ),
                        Container(
                          margin: EdgeInsets.all(4),
                          child: Text(
                            "${directMessage.name != "" ? directMessage.name : otherUser["full_name"]}",
                            style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[800], fontSize: 14.5)
                          )
                        ),
                      ]
                    ),
                  )
                ]
              )
            ),
            users.length == 2 ? SizedBox(height: 8) : Container(),
            users.length == 2 ? Container(
              decoration: BoxDecoration(
                color: widget.isDark ? Palette.backgroundRightSiderDark : Palette.topicTile,
              ),
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.current.emailAddress,
                          style: TextStyle(color: Color(0xFF949494), fontSize: 12,fontWeight: FontWeight.w500),
                        ),
                        Container(
                          margin: EdgeInsets.all(4),
                          child: Text(
                            otherUser["email"] ?? '',
                            style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[800], fontSize: 14.5)
                          )
                        ),
                      ]
                    ),
                  )
                ]
              )
            ) : Container(),
          ],
        )

      ],
    );
  }
}

class MembersTile extends StatefulWidget {
  const MembersTile({
    Key? key,
    @required this.leading,
    @required this.isDark,
  }) : super(key: key);

  final leading;
  final isDark;

  @override
  _MembersTileState createState() => _MembersTileState();
}

class _MembersTileState extends State<MembersTile> {
  var open;

  @override
  void initState() {
    super.initState();
    Timer.run(() async {
      var box = await Hive.openBox('drafts');
      var openMember = box.get('openMember');

      if (openMember == null) {
        this.setState(() { open = false; });
      } else {
        this.setState(() { open = openMember; });
      }
    });
  }

  onExpand(value) async{
    var box = await Hive.openBox('drafts');
    box.put('openMember', value);

    this.setState(() {
      open = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User>(context, listen: true).currentUser;
    final DirectModel directMessage = Provider.of<DirectMessage>(context, listen: true).directMessageSelected;
    final users = directMessage.getUser();

    return open == null ? Container() : ExpansionTile(
      childrenPadding: EdgeInsets.symmetric(horizontal: 16),
      tilePadding: EdgeInsets.symmetric(horizontal: 16),
      initiallyExpanded: open,
      leading: widget.leading,
      title: Row(
        children: [
          SvgPicture.asset('assets/icons/memberIcon.svg', width: 16, height: 16, color: widget.isDark ? Color(0xffF5F7FA) : Color(0xff334E68)),
          SizedBox(width: 8),
          Text(S.current.members, style: TextStyle(fontSize: 14.5, color: widget.isDark ? Color(0xffF5F7FA) : Color(0xff334E68))),
          Text(' (${users.length})', style: TextStyle(fontSize: 12, color: widget.isDark ? Color(0xffF5F7FA) : Color(0xff334E68)))
        ],
      ),
      trailing: Icon(open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,  color: widget.isDark ?  Color(0xffF5F7FA) : Color(0xff334E68), size: 24),
      onExpansionChanged: (value) {
        onExpand(value);
      },
      children: [
        Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                if (users[index]["status"] == "leave_conversation") return Container();
                return TextButton(
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(EdgeInsets.all(0))
                  ),
                  onPressed: () {
                    onShowUserInfo(context, users[index]["user_id"] ?? users[index]["id"]);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        CachedImage(
                          users[index]["avatar_url"],
                          width: 30,
                          height: 30,
                          radius: 15,
                          isAvatar: true,
                          name: users[index]["full_name"]
                        ),
                        SizedBox(width: 10),
                        Row(
                          children: [
                            Text(
                              users[index]["full_name"],
                              style: TextStyle(
                                fontSize: 15
                              ),
                            ),
                            SizedBox(width: 3),
                            (currentUser["id"] == users[index]["user_id"]) ? Text("(you)") : Container()
                          ],
                        ),
                        SizedBox(width: 10),
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            color: users[index]["is_online"] != null && users[index]["is_online"] ? Color(0xff73d13d) : Color(0xffd4d7dc)
                          )
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

onShowUserInfo(context, id) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: isDark ? Color(0xFF36393f) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
        insetPadding: EdgeInsets.all(0),
        contentPadding: EdgeInsets.all(0),
        content: UserProfileDesktop(userId: id),
      );
    }
  );
}

onShowMemberChannelDialog(context) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: isDark ? Color(0xFF36393f) : Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 20),
        content: Container(
          height: 465.0,
          width: 400.0,
          child: Center(
            child: ChannelMember(isDelete: false),
          )
        ),
      );
    }
  );
}

showConfirmDialog(context) {
  onLeaveConversation() {
    final DirectModel directMessage = Provider.of<DirectMessage>(context, listen: false).directMessageSelected;
    final auth = Provider.of<Auth>(context, listen: false);
    Provider.of<DirectMessage>(context, listen: false).leaveConversation(directMessage.id, auth.token, auth.userId);
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {

      return CustomConfirmDialog(
        title: S.current.leaveGroup,
        subtitle: S.current.descLeaveGroup,
        onConfirm: onLeaveConversation,
      );
    }
  );
}

showInputDialog(context) {
  final DirectModel directMessage = Provider.of<DirectMessage>(context, listen: false).directMessageSelected;
  final token = Provider.of<Auth>(context, listen: false).token;
  final userId = Provider.of<Auth>(context, listen: false).token;
  String string = directMessage.name;
  String title = S.current.conversationName.toUpperCase();

// chi goi api khi hoi thoai da dc tao
  onChangeConversationName(value) async {
    var currentDm = Provider.of<DirectMessage>(context, listen: false).getCurrentDataDMMessage(directMessage.id);
    if (currentDm == null) return;
    if (currentDm["statusConversation"] == "creating") return;
    if (currentDm["statusConversation"] == "init") {
      Provider.of<DirectMessage>(context, listen: false).changeNameConvDummy(value, directMessage.id);
      return Navigator.pop(context);
    }
    LazyBox box  = Hive.lazyBox('pairKey');
    final url = "${Utils.apiUrl}direct_messages/${directMessage.id}/update?token=$token&device_id=${await box.get("deviceId")}";
    try {
      var response = await Dio().post(url, data: {"data":  await Utils.encryptServer({"name": value})});
      var dataRes = response.data;

      if (dataRes["success"]) {
        Provider.of<DirectMessage>(context, listen: false).getDataDirectMessage(token, userId);
        var newD = DirectModel(
          directMessage.id,
          directMessage.user,
          value,
          directMessage.seen, directMessage.newMessageCount,
          directMessage.snippet, 
          directMessage.archive, 
          directMessage.updateByMessageTime,
          directMessage.userRead,
          directMessage.displayName,
          directMessage.avatarUrl
        );
        Provider.of<DirectMessage>(context, listen: false).setSelectedDM(newD, token);
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }

    Navigator.pop(context);
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return CustomDialog(title: title, titleField: S.current.conversationName, displayText: string, onSaveString: onChangeConversationName);
    }
  );
}

inviteDirectModel(context, directMessage) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;

  if (directMessage.user.length < 3)
    return showDialog(
      context: context, 
      builder: (BuildContext context){
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Container(
            height: 700.0,
            width: 550.0,
            child: CreateDirectMessage(
              defaultList: directMessage.user.map((ele) => Utils.mergeMaps([
                ele, {"id": ele["user_id"]}
              ])).toList(),
            ),
          ),
        );
      }
    );

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: isDark ? Color(0xFF3D3D3D) : Colors.white,
        contentPadding: EdgeInsets.all(0),
        content: Container(
          height: 600.0,
          width: 500.0,
          child: Center(
            child: InviteModalDesktop(directMessage: directMessage)
          )
        )
      );
    }
  );
}
