import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/channels/change_channel_info_macOS.dart';
import 'package:workcake/channels/render_media_channel.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/styles.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/channel_name_dialog.dart';
import 'package:workcake/components/custom_confirm_dialog.dart';
import 'package:workcake/components/custom_dialog.dart';
import 'package:workcake/components/invite_member_macOS.dart';
import 'package:workcake/components/message_item/attachments/text_file.dart';
import 'package:workcake/components/option_notification_mode.dart';
import 'package:workcake/components/profile/user_profile_desktop.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/service_locator.dart';

import 'apps_channel_macOS.dart';
import 'channel_member.dart';

class ChannelSetting extends StatefulWidget {

  @override
  State<ChannelSetting> createState() => _ChannelSettingState();
}

class _ChannelSettingState extends State<ChannelSetting> {
  bool isSetting = false;
  bool isImage = false;
  bool isShow = false;

  @override
  Widget build(BuildContext context) {
    final currentChannel = Provider.of<Channels>(context, listen: true).currentChannel;
    final currentUserWs = Provider.of<Workspaces>(context, listen: true).currentMember;
    final currentUser = Provider.of<User>(context, listen: true).currentUser;
    final showChannelSetting = Provider.of<Channels>(context, listen: true).showChannelSetting;
    final currentMember = Provider.of<Channels>(context, listen: false).currentMember;
    final channelMember = Provider.of<Channels>(context, listen: true).channelMember;
    final indexMember = channelMember.indexWhere((e) => e["id"] == currentChannel["owner_id"]);
    final ownerChannel = indexMember != -1 ? channelMember[indexMember] : null;
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    final attachmentsChannel = Provider.of<Channels>(context, listen: true).attachmentsChannel;
    List dataImages = attachmentsChannel['image_videos'];
    List dataFiles = attachmentsChannel['files'];

    if(currentChannel['is_general'] ?? false) {
      isSetting = false;
    }

    String assetPath = currentMember["status_notify"] == "OFF"
      ? 'assets/icons/noti_belloff.svg'
      : currentMember["status_notify"] == "MENTION"
        ? 'assets/icons/noti_mentions.svg'
        : currentMember["status_notify"] == "SILENT"
          ? 'assets/icons/noti_silent.svg'
          : 'assets/icons/noti_bell.svg';

    final List allSettingItems = [
      {"leading": Icon(Icons.info_outline, color: Color(0xff334E68)), "title": "About"},
      {"leading": SvgPicture.asset(assetPath, width: 18, color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark), "title": "Notification"},
      {"leading": SvgPicture.asset('assets/icons/app_command.svg', width: 18, color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark), "title": "Apps"},
      {"leading": SvgPicture.asset('assets/icons/setting.svg', width: 18, color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark), "title": "Setting"},
      {"leading": SvgPicture.asset('assets/icons/setting.svg', width: 18, color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark), "title": "Files/Images"},
      {"leading": SvgPicture.asset('assets/icons/LeaveChannel.svg', width: 18, color: Colors.red), "title": "Leave Channel"},
      {"leading": SvgPicture.asset('assets/icons/DeleteChannel.svg', width: 18, color: Colors.red), "title": "Delete Channel"}
    ];
    List listItemSettings = [];
    /*
      Channel thường:
        Full quyền: Workspace owner + Channel owner
        Không có quyền sửa type, delete, archive channel: Admin
        Chỉ có quyền leave: Editor + Member.
      Newsroom:
        Sửa topic, sửa apps, sửa workflow: Workspace owner + channel owner
    */
    if (currentChannel["name"] != "newsroom") {
      switch (currentUserWs["role_id"]) {
        case 1:
          /* Quyền Owner */
          listItemSettings = allSettingItems;
          break;

        case 2:
          /* Quyền Admin */
          if (currentUser["id"] == currentChannel["owner_id"]) {
            /* Owner channel */
            listItemSettings = allSettingItems;
          } else {
            for(int i = 0; i< allSettingItems.length; i++) {
              if(i != 6 && i != 3) {
                listItemSettings.add(allSettingItems[i]);
              }
            }
          }
          break;
        case 3:
        case 4:
          /* Member/Editor */
          if (currentUser["id"] == currentChannel["owner_id"]) {
            listItemSettings = allSettingItems;
          } else {
            for(int i = 0; i< allSettingItems.length; i++) {
              if(i == 0 || i == 1 || i == 5 || i == 4) {
                listItemSettings.add(allSettingItems[i]);
              }
            }
          }
          break;
        default:
          listItemSettings.add(allSettingItems[5]);
      }
    } else {
      for(int j = 0; j < allSettingItems.length; j++){
        if(currentUserWs["role_id"] <= 2) {
          if (j == 2) listItemSettings.add(allSettingItems[j]);
        } else if (currentUserWs["role_id"] == 1) {
          listItemSettings.add(allSettingItems[6]);
        }

        if(j == 0 || j == 1 || j == 4 || j == 5) {
          listItemSettings.add(allSettingItems[j]);
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Column(
              children: [
                Container(
                  height: 56,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Palette.backgroundTheardDark,
                    border: Border(
                      bottom: BorderSide(
                        color: Palette.borderSideColorDark,
                      )
                    )
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset('assets/icons/error_outline.svg'),
                          SizedBox(width: 10),
                          Text(S.current.details, style: TextStyle(color: Color(0xffF0F4F8), fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      HoverItem(
                        colorHover: Palette.hoverColorDefault,
                        child: IconButton(
                          padding: EdgeInsets.only(left: 2),
                          onPressed:(){
                            Provider.of<Channels>(context, listen: false).openChannelSetting(!showChannelSetting);
                          },
                          icon: SvgPicture.asset('assets/icons/newX.svg', height: 14.13)
                        ),
                      ),
                    ]
                  )
                ),
                Expanded(
                  child: Container(
                    color: isDark ? Color(0xFF2e2e2e) : Color(0xFFF3F3F3),
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      shrinkWrap: true,
                      controller: ScrollController(),
                      itemCount: listItemSettings.length,
                      itemBuilder: (BuildContext context, int index) {
                        final action = listItemSettings[index];
                         switch (action["title"]) {
                          case 'About':
                            return Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  margin: EdgeInsets.only(bottom: 12,  top: 18),
                                  child: Row(
                                    children: [
                                      Icon(
                                        PhosphorIcons.diamondsFour,
                                        size: 20.0, color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        action["title"],
                                        style: TextStyle(
                                          fontSize: 16, color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark
                                        )
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? Palette.backgroundRightSiderDark : Palette.topicTile,
                                        borderRadius: BorderRadius.all(Radius.circular(2))
                                      ),
                                      padding: EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      S.current.topic.toUpperCase(),
                                                      style: TextStyle(color: Color(0xFF949494), fontSize: 12,fontWeight: FontWeight.w500),
                                                    ),
                                                    SizedBox(width: 5),
                                                    InkWell(
                                                      hoverColor: Colors.blue,
                                                      onTap: (){
                                                        showEditAboutDialog(context, 1);
                                                      },
                                                      child: ((currentChannel["owner_id"] == currentUser["id"]) || (currentUserWs["role_id"] <= 2))
                                                        ? SvgPicture.asset('assets/icons/EditButton.svg')
                                                        : Container(),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 5),
                                                Container(
                                                  child: SelectableText(
                                                    (currentChannel["topic"] != null && currentChannel["topic"] != "") ? currentChannel["topic"] : S.current.whatForDiscussion,
                                                    style: TextStyle(color: isDark ? Colors.grey[300] : Palette.backgroundRightSiderDark, fontSize: 12, height: 1.5)
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                              ]
                                            ),
                                          )
                                        ]
                                      )
                                    ),
                                    if(ownerChannel != null) SizedBox(height: 10),
                                    ownerChannel == null ? Container() : Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? Palette.backgroundRightSiderDark : Palette.topicTile,
                                      ),
                                      padding: EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(S.current.createBy.toUpperCase(), style: TextStyle(color: Color(0xFF949494), fontSize: 12, fontWeight: FontWeight.w500)),
                                          SizedBox(height: 10),
                                          Row(
                                            children: [
                                              CachedAvatar(
                                                ownerChannel["avatar_url"],
                                                height: 26,
                                                width: 26,
                                                radius: 4,
                                                isAvatar: true,
                                                name: ownerChannel["full_name"]
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  "${ownerChannel["full_name"]} on ${currentChannel['inserted_at'] != null ? DateFormatter().renderTime(DateTime.parse(currentChannel['inserted_at']), type: 'yMMMMd') : " --/--/--"}" ,
                                                  style: TextStyle(color: isDark ? Colors.grey[300] : Palette.backgroundRightSiderDark, fontSize: 12)
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  ]
                                ),
                                SizedBox(height: 20),
                                Divider(height: 0.5),
                                SizedBox(height: 8),
                              ],
                            );
                            case 'Files/Images':
                              return Column(
                                children: [
                                  SizedBox(height: 8),
                                  Divider(height: 0.5),
                                  SizedBox(height: 8),
                                  RenderMediaChannel(
                                    data: dataImages, type: 'image',
                                    onChanged: () {
                                      setState(() {
                                        isImage = true;
                                        isShow = true;
                                      });
                                    },
                                    count: attachmentsChannel['count_images']
                                  ),
                                  SizedBox(height: 10),
                                  RenderMediaChannel(
                                    data: dataFiles, type: 'file',
                                    onChanged: () {
                                      setState(() {
                                        isImage = false;
                                        isShow = true;
                                      });
                                    },
                                    count: attachmentsChannel['count_files']
                                  ),
                                  SizedBox(height: 20),
                                  Divider(height: 0.5),
                                  SizedBox(height: 8),
                                ],
                              );
                          case 'Apps':
                          case 'Notification':
                            return renderAction(action, isDark, context);
                          case 'Setting':
                            return ((currentUserWs["role_id"] == 1 || currentUserWs["role_id"] == 2 || currentUser["id"] == currentChannel["owner_id"]) && currentChannel["name"] != "newsroom") ? renderAction(action, isDark, context) : Container();
                          case 'Leave Channel':
                            return renderAction(action, isDark, context);
                          case 'Delete Channel':
                            return renderAction(action, isDark, context);
                          default:
                            return Container();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            Container(
              height: constraints.maxHeight,
              width: isSetting || isShow ? constraints.maxWidth : 0.0,
              color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
              child: Column(
                children: [
                  Container(
                    height: 56,
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Palette.backgroundTheardDark,
                      border: Border(
                        bottom: BorderSide(
                          color: Palette.borderSideColorDark,
                        )
                      )
                    ),
                    child: Row(
                      children: [
                        HoverItem(
                          colorHover: Palette.hoverColorDefault,
                          isRound: true,
                          radius: 4.0,
                          child: IconButton(
                            padding: EdgeInsets.only(left: 2),
                            onPressed:(){
                              setState(() {
                                isSetting = false;
                                isShow = false;
                              });
                            },
                            icon: SvgPicture.asset('assets/icons/backDark.svg', height: 14.13)
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          isSetting ? S.current.settings : isImage ? 'Photo/Video' : 'Files',
                          style: TextStyle(color: Color(0xffF0F4F8), fontSize: 16, fontWeight: FontWeight.w500)
                        ),

                      ]
                    )
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: ScrollController(),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        child: isSetting ? Column(
                          children: [
                            ListAction(
                              action: '', radius: 4.0, isRound: true,
                              child: InkWell(
                                onTap: () {
                                  showInputDialog(context);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          SvgPicture.asset('assets/icons/EditButton.svg', color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark),
                                          SizedBox(width: 8),
                                          Text('Channel Name', style: TextStyle(color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark)),
                                        ],
                                      ),
                                      SvgPicture.asset('assets/icons/NewRightArrow.svg', color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark, width: 8),
                                    ],
                                  )
                                )
                              ),
                              isDark: isDark
                            ),
                            ListAction(
                              action: '', radius: 4.0, isRound: true,
                              child: InkWell(
                                onTap: () {
                                    showSelectDialog(context);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            PhosphorIcons.arrowsClockwise,
                                            size: 20.0, color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark
                                          ),
                                          SizedBox(width: 8),
                                          Text('Channel Type', style: TextStyle(color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark)),
                                        ],
                                      ),
                                      SvgPicture.asset('assets/icons/NewRightArrow.svg', color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark, width: 8),
                                    ],
                                  )
                                )
                              ),
                              isDark: isDark
                            ),
                            ListAction(
                              action: '', radius: 4.0, isRound: true,
                              child: InkWell(
                                onTap: () {
                                  showWorkflowDialog(context);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            PhosphorIcons.bagSimple,
                                            size: 20.0, color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark
                                          ),
                                          SizedBox(width: 8),
                                          Text('Change workflow', style: TextStyle(color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark)),
                                        ],
                                      ),
                                      SvgPicture.asset('assets/icons/NewRightArrow.svg', color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark, width: 8),
                                    ],
                                  )
                                )
                              ),
                              isDark: isDark
                            ),
                            ListAction(
                              action: '', radius: 4.0, isRound: true,
                              child: InkWell(
                                onTap: () {
                                  String title = (currentChannel["is_archived"] != null && currentChannel["is_archived"]) ? "Unarchive Channel" : "Archive Channel";
                                  onArchiveChannel(context, title);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            PhosphorIcons.archive,
                                            size: 20.0, color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark
                                          ),
                                          SizedBox(width: 8),
                                          Text((currentChannel["is_archived"] != null && currentChannel["is_archived"]) ? "Unarchive Channel" : "Archive Channel", style: TextStyle(color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark)),
                                        ],
                                      ),
                                      SvgPicture.asset('assets/icons/NewRightArrow.svg', color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark, width: 8),
                                    ],
                                  )
                                )
                              ),
                              isDark: isDark
                            ),
                          ],
                        ) : isShow ? Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: isImage ? (isDark ? Color(0xff5E5E5E) : Color(0xff3D3D3D)): (isDark ? Color(0xff1E1E1E) : Color(0xffF8F8F8)),
                                    border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xff3D3D3D), width: 1),
                                    borderRadius: BorderRadius.only(topLeft: Radius.circular(2), bottomLeft: Radius.circular(2))
                                  ),
                                  child: ListAction(
                                    action: '', radius: 4.0, isRound: true,
                                    child: InkWell(
                                      onTap: dataImages.length > 0 ? () {
                                        if(!isImage) setState(() {
                                          isImage = true;
                                        });
                                      } : null,
                                      child: Container(
                                        width: 134, height: 40,
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              PhosphorIcons.imageSquare,
                                              color: isImage ? Palette.defaultTextDark : (isDark ? Palette.defaultTextDark : Palette.defaultTextLight), size: 20
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Photo/Video',
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  color: isImage ? Palette.defaultTextDark : (isDark ? Palette.defaultTextDark : Palette.defaultTextLight)
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        )
                                      )
                                    ),
                                    isDark: isDark
                                  ),
                                ),
                                SizedBox(width: 2),
                                Container(
                                  decoration: BoxDecoration(
                                    color: !isImage ? (isDark ? Color(0xff5E5E5E) : Color(0xff3D3D3D)) : (isDark ? Color(0xff1E1E1E) : Color(0xffF8F8F8)),
                                    border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xff3D3D3D), width: 1),
                                    borderRadius: BorderRadius.only(topRight: Radius.circular(2), bottomRight: Radius.circular(2))
                                  ),
                                  child: ListAction(
                                    action: '', radius: 4.0, isRound: true,
                                    child: InkWell(
                                      onTap: dataFiles.length > 0 ? () {
                                        if(isImage) setState(() {
                                          isImage = false;
                                        });
                                      } : null,
                                      child: Container(
                                        width: 134, height: 40,
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              PhosphorIcons.files,
                                              color: !isImage ? Palette.defaultTextDark : (isDark ? Palette.defaultTextDark : Palette.defaultTextLight), size: 20
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Files',
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                color: !isImage ? Palette.defaultTextDark : (isDark ? Palette.defaultTextDark : Palette.defaultTextLight)
                                              )
                                            ),
                                          ],
                                        )
                                      )
                                    ),
                                    isDark: isDark
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            RenderMediaChannel(data: isImage ? dataImages : dataFiles, type: isImage ? 'image' : 'file', isPreview: false, count: 0),
                          ],
                        ) : Container(),
                      ),
                    )
                  ),
                ],
              ),
            )
          ],
        );
      }
    );
  }

  Widget renderAction(action, isDark, context) {
    final String title = action['title'];
    return Container(
      child: ListAction(
        action: '', radius: 4.0, isRound: true,
        child: InkWell(
          onTap: () {
            final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;

            if (title == "Channel Type" && !currentChannel["is_general"]) {
              showSelectDialog(context);
            } else if(title == "Notification") {
              showOptionNotify(context);
            } else if (title == "Apps") {
              onShowEditAppChannelDialog(context);
            } else if (title == "Leave Channel") {
              showLeaveChannelDialog(context);
            } else if (title == "Archive Channel" || title == "Unarchive Channel") {
              onArchiveChannel(context, title);
            } else if (title == "Delete Channel") {
              showConfirmDialog(context);
            } else if (title == "Change workflow") {
              showWorkflowDialog(context);
            } else {
              setState(() {
                isSetting = true;
              });
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                action['leading'],
                SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: (title == "Leave Channel" || title == "Delete Channel")
                    ? Colors.red
                    : isDark ? Palette.topicTile : Palette.backgroundRightSiderDark
                  )
                )
              ],
            ),
          ),
        ),
        isDark: isDark
      ),
    );
  }
}

showOptionNotify(context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return OptionNotificationMode();
    }
  );
}

class MembersTile extends StatefulWidget {
  const MembersTile({
    Key? key,
    @required this.isDark,
  }) : super(key: key);

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
        if (this.mounted) this.setState(() { open = openMember; });
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

  getChannelMember() {
    final members = Provider.of<Channels>(context, listen: false).channelMember;
    return members;

  }

  deleteMember(token, workspaceId, channelId, userId) {
    Provider.of<Workspaces>(context, listen: false).deleteChannelMember(token, workspaceId, channelId, [userId]);
  }

  Widget renderMembers(members, currentMember, currentUser, currentUserWs, isOwner) {
    final isDark = Provider.of<Auth>(context).theme == ThemeType.DARK;

    return ListView.builder(
      shrinkWrap: true,
      itemCount: members.length,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final member = members[index];
        return TextButton(
          style: ButtonStyle(
            padding: MaterialStateProperty.all(EdgeInsets.all(0)),
          ),
          onPressed: () {
            if (currentUser["id"] != member["id"]) {
              onShowUserInfo(context, member["user_id"] != null
                ? member["user_id"]
                : member["id"]);
            }
          },
          child: ListAction(
            action: "",
            isDark: isDark,
            child: Container(
              padding: EdgeInsets.only(top: 7, bottom: 7, right: 15,left: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          CachedAvatar(
                            member["avatar_url"],
                            width: 30,
                            height: 30,
                            isAvatar: true,
                            name: member["nickname"] ?? member["full_name"]
                          ),
                          Positioned(
                            top: 18, left: 18,
                            child: Container(
                              height: 14, width: 14,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                color: (member['is_online'] ?? false)
                                  ? (isDark ? Color(0xff2e2e2e) : Color(0xFFF3F3F3))
                                  : Colors.transparent
                              ),
                            )
                          ),
                          Positioned(
                            top: 20, left: 20,
                            child: Container(
                              height: 10, width: 10,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: EdgeInsets.all(1),
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: (member['is_online'] ?? false)
                                    ? Color(0xff73d13d)
                                    : Colors.transparent,
                                ),
                              ),
                            )
                          )
                        ],
                      ),
                      SizedBox(width: 10),
                      Row(
                        children: [
                          Text(
                            member["nickname"] ?? member["full_name"],
                            style: TextStyle(
                              fontSize: 15,
                              // color: Constants.checkColorRole(member["role_id"], isDark)
                              color: member['is_online'] ?? false
                                ? Constants.checkColorRole(member["role_id"], isDark)
                                : isDark ? Colors.white60 : Color(0xff3D3D3D)
                            ),
                          ),
                          SizedBox(width: 3),
                          (currentMember["user_id"] != null && currentMember["user_id"] == member["id"])
                              ? Text(
                                "(you)",
                                style: TextStyle(color: member['is_online'] ?? false
                                  ? Constants.checkColorRole(member["role_id"], isDark)
                                  : isDark ? Colors.white60 : Color(0xff3D3D3D))
                              )
                              : Container()
                        ],
                      ),
                    ],
                  ),
                  (isOwner || (member["role_id"] != null && currentUserWs['role_id'] <= 3 && currentUserWs["role_id"] <= member["role_id"])) && (currentMember["user_id"] != member["id"]) && member["account_type"] == "user"
                    ? InkWell(
                      onTap: () {
                        onShowDeleteMember(context, member["id"]);
                      },
                      child: Icon(Icons.close, size: 13))
                    : SizedBox()
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final channelMember = getChannelMember();
    final userMembers = channelMember.where((e) => e["account_type"] == "user").toList();
    final appMembers = channelMember.where((e) => e["account_type"] == "app").toList();
    final onlineMembers = userMembers.where((e) => e["is_online"] == true).toList();
    final ownerMember = onlineMembers.where((e) => e["role_id"] == 1).toList();
    final adminMembers = onlineMembers.where((e) => e["role_id"] == 2).toList();
    final editorMembers = onlineMembers.where((e) => e["role_id"] == 3).toList();
    final fullMembers = onlineMembers.where((e) => e["role_id"] == 4).toList();
    final offlineMembers = userMembers.where((e) => e["is_online"] != true).toList();
    final currentMember = Provider.of<Channels>(context, listen: true).currentMember;
    final currentUserWs = Provider.of<Workspaces>(context, listen: true).currentMember;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final currentUser = Provider.of<User>(context, listen: true).currentUser;
    final isOwner = currentChannel['owner_id'] == currentUser["id"];
    final showChannelMember = Provider.of<Channels>(context, listen: true).showChannelMember;
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;

    return (open == null || channelMember.length == 0)
      ? Column(
        children: [
          Container(
            height: 56,
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Palette.backgroundTheardDark,
              border: Border(
                bottom: BorderSide(
                  color: Palette.borderSideColorDark
                )
              )
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset('assets/icons/memberIcon.svg'),
                    SizedBox(width: 10),
                    Text(S.current.members, style: TextStyle(color: Color(0xffF0F4F8), fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
                IconButton(
                  padding: EdgeInsets.only(left: 2),
                  onPressed:(){
                    Provider.of<Channels>(context, listen: false).openChannelMember(!showChannelMember);
                  },
                  icon: SvgPicture.asset('assets/icons/newX.svg', height: 14.13)
                ),
            ],)
          ),
        ],
      )
      : Column(
        children: [
          Container(
            height: 56,
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Palette.backgroundTheardDark,
              border: Border(
                bottom: BorderSide(
                  color: Palette.borderSideColorDark
                )
              )
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.users,
                      color: Palette.defaultTextDark,
                      size: 18.0,
                    ),
                    SizedBox(width: 8,),
                    Text(
                      "Members",
                      style: TextStyle(
                        color: Palette.defaultTextDark, fontSize: 15, fontWeight: FontWeight.w500,
                        height: 1.1
                      )
                    )
                  ],
                ),
                InkWell(
                  onTap: (){
                    Provider.of<Channels>(context, listen: false).openChannelMember(!showChannelMember);
                  },
                  child: Container(
                    padding: EdgeInsets.only(right: 12),
                    child: SvgPicture.asset('assets/icons/newX.svg', height: 14.13)
                  )
                )
            ],)
          ),
          Expanded(
            child: Container(
              color: isDark ? Color(0xFF2e2e2e) : Color(0xFFF3F3F3),
              padding: EdgeInsets.only(bottom: 15,),
              child: SingleChildScrollView(
                controller: ScrollController(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ownerMember.length > 0 ? Container(
                      padding: EdgeInsets.only(top: 20, bottom: 15, left: 14),
                      child: ownerMember.length > 0 ? Text("OWNER", style: TextStyle(color: isDark ? Color(0xFFFFFFFF) : Color(0xff828282), fontSize: 14, fontWeight: FontWeight.w700)) : Container()
                    ) : Container(),
                    renderMembers(ownerMember, currentMember, currentUser, currentUserWs, isOwner),
                    adminMembers.length > 0 ? Container(
                      padding: EdgeInsets.only(top: 20, bottom: 15, left: 14),
                      child: adminMembers.length > 0 ? Text("ADMINS (${adminMembers.length})", style: TextStyle(color: isDark ? Color(0xFFFFFFFF) : Color(0xff828282), fontSize: 14, fontWeight: FontWeight.w700)) : Container()
                    ) : Container(),
                    renderMembers(adminMembers, currentMember, currentUser, currentUserWs, isOwner),
                    editorMembers.length > 0 ? Container(
                      padding: EdgeInsets.only(top: 20, bottom: 15, left: 14),
                      child: editorMembers.length > 0 ? Text("EDITORS (${editorMembers.length})", style: TextStyle(color: isDark ? Color(0xFFFFFFFF) : Color(0xff828282), fontSize: 14, fontWeight: FontWeight.w700)) : Container()
                    ) : Container(),
                    renderMembers(editorMembers, currentMember, currentUser, currentUserWs, isOwner),
                    fullMembers.length > 0 ? Container(
                      padding: EdgeInsets.only(top: 20, bottom: 15, left: 14),
                      child: fullMembers.length > 0 ? Text("MEMBERS (${fullMembers.length})", style: TextStyle(color: isDark ? Color(0xFFFFFFFF) : Color(0xff828282), fontSize: 14, fontWeight: FontWeight.w700)) : Container()
                    ) : Container(),
                    renderMembers(fullMembers, currentMember, currentUser, currentUserWs, isOwner),
                    offlineMembers.length > 0 ? Container(
                      padding: EdgeInsets.only(top: 20, bottom: 15, left: 14),
                      child: offlineMembers.length > 0 ? Text("OFFLINE (${offlineMembers.length})", style: TextStyle(color: isDark ? Color(0xFFFFFFFF) : Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w700)) : Container()
                    ) : Container(),
                    renderMembers(offlineMembers, currentMember, currentUser, currentUserWs, isOwner),
                    appMembers.length > 0 ? Container(
                      padding: EdgeInsets.only(top: 20, bottom: 15, left: 14),
                      child: appMembers.length > 0 ? Text("APP (${appMembers.length})", style: TextStyle(color: isDark ? Color(0xFFFFFFFF) : Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w700)) : Container()
                    ) : Container(),
                    renderMembers(appMembers, currentMember, currentUser, currentUserWs, isOwner)
                  ],
                ),
              ),
            ),
          ),
        ],
      );
  }
}

onShowUserInfo(context, id) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;

  showModal(
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

onShowDeleteMember(context, userId) {
  final auth = Provider.of<Auth>(context, listen: false);
  final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
  final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      onDeleteMember() async {
        await Provider.of<Workspaces>(context, listen: false).deleteChannelMember(auth.token, currentWorkspace['id'], currentChannel['id'], [userId]);
        Navigator.pop(context);
      }

      return AlertDialog(
        content: Container(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      S.current.deleteMembers,
                      style: TextStyle(
                        color: auth.theme == ThemeType.DARK ? Colors.white : Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w500
                      )
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.close, color: auth.theme == ThemeType.DARK ? Colors.white : Colors.black45)
                    )
                  ],
                ),
              ),
              SizedBox(height: 20,),
              Container(
                child: Text(
                  currentChannel['is_general']
                    ? S.current.descDeleteNewsroom
                    : S.current.desDeleteChannel,
                  style: TextStyle(
                    color: auth.theme == ThemeType.DARK ? Colors.white : Colors.black87
                  ),
                ),
              ),
              SizedBox(height: 30,),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          )
                        ),
                        padding: MaterialStateProperty.all(EdgeInsets.only(top: 20, bottom: 20, left: 16.0, right: 16)),
                        backgroundColor: MaterialStateProperty.all(Colors.red),
                        textStyle: MaterialStateProperty.all(
                          TextStyle(
                            color: Colors.white
                          )
                        )
                      ),
                      onPressed: onDeleteMember,
                      child: Text(
                        S.current.deleteMembers,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700
                        ),
                      )
                    )
                  ],
                )
              )
            ],
          )
        ),
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

showLeaveChannelDialog(context) {
  final auth = Provider.of<Auth>(context, listen: false);
  final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
  final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;

  onSelectedChannel(workspaceId, channelId) async {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    Provider.of<Channels>(context, listen: false).onChangeLastChannel(workspaceId, channelId);
    Provider.of<Messages>(context, listen: false).loadMessages(auth.token, workspaceId, channelId);
    Provider.of<Channels>(context, listen: false).selectChannel(auth.token, workspaceId, channelId);
    Provider.of<Channels>(context, listen: false).loadCommandChannel(auth.token, workspaceId, channelId);
    Provider.of<Channels>(context, listen: false).getChannelMemberInfo(auth.token, workspaceId, channelId, currentUser["id"]);
    Provider.of<Workspaces>(context, listen: false).clearMentionWhenClickChannel(workspaceId, channelId);

    auth.channel.push(
      event: "join_channel",
      payload: {"channel_id": channelId, "workspace_id": workspaceId}
    );
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {

      onLeaveChannel() {
        Provider.of<Channels>(context, listen: false).leaveChannel(auth.token, currentWorkspace["id"], currentChannel["id"]).then((value) {
          if(value != null) onSelectedChannel(value['workspace_id'], value['id']);
        });
        // Navigator.pop(context);
      }

      return CustomConfirmDialog(
        title: S.current.leaveChannel,
        subtitle: S.current.descLeaveChannel,
        onConfirm: onLeaveChannel,
      );
    }
  );
}

onShowEditAppChannelDialog(context) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: isDark ? Color(0xFF3D3D3D) : Color(0xffFFFFFF),
        contentPadding: EdgeInsets.zero,
        content: Container(
          height: 470.0,
          width: 470.0,
          child: Center(
            child: ChannelAppMacOS(),
          )
        ),
      );
    }
  );
}

onShowInviteChannelDialog(context) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;
  Map currentChannel = {};
  currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
  showModal(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Container(
          height: 450.0,
          width: 528.0,
          child: Column(
            children: [
              Container(
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
                        S.current.inviteTo(currentChannel["name"]),
                        style: TextStyle(color: isDark ? Palette.defaultTextDark : Color(0xff1F2933), fontSize: 14.0, fontWeight: FontWeight.w700, overflow: TextOverflow.ellipsis)
                      ),
                    ),
                    Container(
                      height: 35,
                      width: 35,
                      child: HoverItem(
                        colorHover: isDark ? Color(0xff828282) : Color(0xffDBDBDB),
                        child: InkWell(
                          onTap: (){Navigator.of(context).pop();},
                          child: Icon(PhosphorIcons.xCircle,size: 18,)),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(child: InviteMemberMacOS(type: 'toChannel', isKeyCode: false)),
            ],
          )
        ),
      );
    }
  );
}

showSelectDialog(context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
        child: Container(
          width: 398,
          height: 144,
          child: ChangeChannelInfoMacOS(type: 2)
        ),
      );
    }
  );
}

showWorkflowDialog(context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Container(
          width: 398,
          height: 144,
          child: ChangeChannelInfoMacOS(type: 3)
        ),
      );
    }
  );
}

showConfirmDialog(context) {
  final auth = Provider.of<Auth>(context, listen: false);
  final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
  final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
  final listChannelGeneral = Provider.of<Channels>(context, listen: false).data.where((e) => e["is_general"]).toList();
  final indexChannelGeneral = listChannelGeneral.indexWhere((e) => e["workspace_id"] == currentWorkspace["id"]);

  onSelectedChannel(workspaceId, channelId) async{
    final auth = Provider.of<Auth>(context, listen: false);
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    Provider.of<Channels>(context, listen: false).onChangeLastChannel(workspaceId, channelId);
    Provider.of<Messages>(context, listen: false).loadMessages(auth.token, workspaceId, channelId);
    Provider.of<Channels>(context, listen: false).selectChannel(auth.token, workspaceId, channelId);
    Provider.of<Channels>(context, listen: false).loadCommandChannel(auth.token, workspaceId, channelId);
    Provider.of<Channels>(context, listen: false).getChannelMemberInfo(auth.token, workspaceId, channelId, currentUser["id"]);
    Provider.of<Workspaces>(context, listen: false).clearMentionWhenClickChannel(workspaceId, channelId);

    auth.channel.push(
      event: "join_channel",
      payload: {"channel_id": channelId, "workspace_id": workspaceId}
    );
  }

  onDeleteChannel() {
    if(indexChannelGeneral != -1)
      Provider.of<Channels>(context, listen: false).deleteChannel(auth.token, currentWorkspace["id"], currentChannel["id"], listChannelGeneral[indexChannelGeneral]["id"]).then((value) {
        if(value != null) onSelectedChannel(value['workspace_id'], value['id']);
      });
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {

      return CustomConfirmDialog(
        title: S.current.deleteChannel,
        subtitle: S.current.desDeleteChannel,
        onConfirm: onDeleteChannel,
      );
    }
  );
}

showInputDialog(context) {
  final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
  final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
  final auth = Provider.of<Auth>(context, listen: false);
  String string = currentChannel["name"];
  String title = S.current.channelName.toUpperCase();

  onChangeChannelInfo(value) {
    Map channel = new Map.from(currentChannel);
    channel["name"] = value;

    Provider.of<Channels>(context, listen: false).changeChannelInfo(auth.token, currentWorkspace["id"], currentChannel["id"], channel, context);
    Navigator.pop(context);
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return CustomDialog(title: title, titleField: S.current.channelName, displayText: string, onSaveString: onChangeChannelInfo);
    }
  );
}

showEditAboutDialog(context, type) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;
  final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
  final TextEditingController topicInputController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  topicInputController.text = currentChannel["topic"] ?? "";

  onChangeChannelInfo() {
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;

    Map channel = new Map.from(currentChannel);
    channel["topic"] = topicInputController.text.trim();

    Provider.of<Channels>(context, listen: false).changeChannelInfo(auth.token, currentWorkspace["id"], currentChannel["id"], channel, context);
    // Navigator.pop(context);
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF3D3D3D) : Colors.white,
            borderRadius: BorderRadius.circular(10)
          ),
          padding: EdgeInsets.all(18),
          height: 236,
          width: 580,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type == 1 ? S.current.editChannelTopic : S.current.editChannelDesc, style: TextStyle(fontSize: 20, color: isDark ? Colors.grey[300] : Color(0xff334E68))),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[400]!, width: 1),
                  color: Colors.transparent
                ),
                child: TextFormField(
                  focusNode: focusNode,
                  autofocus: true,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                  controller: topicInputController,
                  style: TextStyle(color: isDark ? Colors.grey[300] : Color(0xff334E68)),
                  minLines: 3,
                  maxLines: 3,
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Color(0xffF57572), width: 1),
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(S.current.cancel, style: TextStyle(color: Color(0xffF57572))),
                    ),
                  ),
                  SizedBox(width: 20),
                  Container(
                    height: 38,
                    child: TextButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Utils.getPrimaryColor()),
                        padding: MaterialStateProperty.all(EdgeInsets.all(18)),
                      ),
                      onPressed: () async {
                        onChangeChannelInfo();
                        Navigator.pop(context);
                      },
                      child: Text(
                        type == 1 ? S.current.setTopic : S.current.setDesc,
                        style: TextStyle(color: Colors.white)
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      );
    }
  );
}

onArchiveChannel(context, title) {
  final auth = Provider.of<Auth>(context, listen: false);
  final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
  final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
  final channels = Provider.of<Channels>(context, listen: false).data
    .where((e) {
      return e["workspace_id"] == currentWorkspace["id"] && (e["is_archived"] == null || !e["is_archived"]);
    }).toList();

  String suffixNameChannel(value) {
    int i = 0;
    String text = value;
    bool check = true;
    while (check) {
      int index = channels.indexWhere((e) => e["name"] == text);
      if (index == -1) break;
      List suffix = text.split("_");
      try{
        int indexCheck = int.parse(suffix.last);
        suffix[suffix.length - 1] = (indexCheck + 1).toString();
        text = suffix.join("_");
      } catch (e) {
        i += 1;
        text = text + "_$i";
      }
    }
    return text;
  }

  archiveChannel() {
    Map channel = new Map.from(currentChannel);
    bool isArchived = channel["is_archived"] != null ? !channel["is_archived"] : true;
    channel["is_archived"] = isArchived;

    int indexChannelArchived = channels.indexWhere((e) => e["name"] == channel["name"]);
    if(indexChannelArchived != -1 && !isArchived) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          String text = suffixNameChannel(currentChannel["name"]);
          return ChannelNameDialog(
            title: S.current.channelName.toUpperCase(),
            displayText: text,
            onSaveString: (value) {
              int index = channels.indexWhere((e) => e["name"] == value);
              if(index == -1) {
                channel["name"] = value;
                Provider.of<Channels>(context, listen: false).changeChannelInfo(auth.token, currentWorkspace["id"], currentChannel["id"], channel, context);
              } else {
                sl.get<Auth>().showAlertMessage(S.current.channelNameExisted, true);
              }
              Timer(Duration(milliseconds: 500), () => Navigator.pop(context));
            }
          );
        }
      );
    } else Provider.of<Channels>(context, listen: false).changeChannelInfo(auth.token, currentWorkspace["id"], currentChannel["id"], channel, context);
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      String string = S.current.descArchiveChannel(currentChannel["name"]);

      return CustomConfirmDialog(title: title, subtitle: string, onConfirm: archiveChannel, onCancel: (){});
    }
  );
}
