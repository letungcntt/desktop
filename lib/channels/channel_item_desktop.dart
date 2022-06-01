import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/focus_inputbox_manager.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/invite_member_macOS.dart';
import 'package:workcake/models/models.dart';

class ChannelItemDesktop extends StatefulWidget {
  ChannelItemDesktop({
    Key? key,
    @required this.channel
  }) : super(key: key);

  final channel;

  @override
  _ChannelItemDesktopState createState() => _ChannelItemDesktopState();
}

class _ChannelItemDesktopState extends State<ChannelItemDesktop> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool isHover = false;

  onSelectChannel(channelId) async {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    // neu channel dang dc nhay den 1 tin nhan va current channel hien tai !=  => resetOne
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final dataMessageChannel = Provider.of<Messages>(context, listen: false).data;
    var indexDataMessageChannel = dataMessageChannel.indexWhere((element) => "${element["channelId"]}" == "$channelId");
    if (currentChannel["id"] != channelId && indexDataMessageChannel != -1 && dataMessageChannel[indexDataMessageChannel]["numberNewMessages"] != null)
      Provider.of<Messages>(context, listen: false).resetOneChannelMessage(channelId);

    await Provider.of<Channels>(context, listen: false).setCurrentChannel(channelId);
    Provider.of<Channels>(context, listen: false).onChangeLastChannel(currentWorkspace["id"], channelId);
    Provider.of<Messages>(context, listen: false).loadMessages(auth.token, currentWorkspace["id"], channelId);
    Provider.of<Channels>(context, listen: false).selectChannel(auth.token, currentWorkspace["id"], channelId);
    Provider.of<Channels>(context, listen: false).loadCommandChannel(auth.token, currentWorkspace["id"], channelId);
    Provider.of<Channels>(context, listen: false).getChannelMemberInfo(auth.token, currentWorkspace["id"], channelId, currentUser["id"]);
    Provider.of<Workspaces>(context, listen: false).clearMentionWhenClickChannel(currentWorkspace["id"], channelId);

    auth.channel.push(
      event: "join_channel",
      payload: {"channel_id": channelId, "workspace_id": currentWorkspace["id"]}
    );

    if(Platform.isMacOS) Utils.updateBadge(context);
  }

  onShowInviteChannelDialog(context) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: Duration(milliseconds: 80),
      transitionBuilder: (context, a1, a2, widget){
        var begin = 0.5;
        var end = 1.0;
        var curve = Curves.decelerate;
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
          child: AlertDialog(
          backgroundColor: Colors.transparent,
          content: Container(
            height: 656.0,
            width: 460.0,
            child: Center(
                child: InviteMemberMacOS(type: 'toChannel', isKeyCode: false),
              )
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final currentChannel = Provider.of<Channels>(context, listen: true).currentChannel;
    final selectedTab = Provider.of<User>(context, listen: true).selectedTab;
    final token = Provider.of<Auth>(context, listen: false).token;
    
    return InkWell(
      onHover: (hover) {
        setState(() {
          isHover = hover;
        });
      },
      onTap: () {
        Provider.of<User>(context, listen: false).selectTab("channel");
        onSelectChannel(widget.channel["id"]);
        final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
        if (selectedTab == "thread") Provider.of<Threads>(context, listen: false).onChangeTabs(false, token, currentWorkspace["id"]);
        FocusInputStream.instance.focusToMessage();
      },
      child: Container(
        height: 33,
        decoration: (widget.channel["id"] == currentChannel["id"] && selectedTab == "channel") ? BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(3)),
          color: Palette.selectChannelColor
        )
        : isHover ? BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(3)),
          color: Palette.backgroundRightSiderDark
        )
        : BoxDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 6),
                    child: (widget.channel["id"] == currentChannel["id"] && selectedTab == "channel") || (((Utils.checkedTypeEmpty(widget.channel["seen"]) == false && widget.channel["status_notify"] != "OFF" && widget.channel["status_notify"] != "MENTION")|| (widget.channel["new_message_count"] != null && widget.channel["new_message_count"] > 0 && widget.channel["status_notify"] == "MENTION")))
                      ? widget.channel['is_private']
                        ? SvgPicture.asset('assets/icons/Locked.svg')
                        : SvgPicture.asset('assets/icons/iconNumber.svg', width: 13, color: Colors.white)
                      : widget.channel["status_notify"] == "OFF" || (widget.channel["status_notify"] == "MENTION" && (widget.channel["new_message_count"] != null && widget.channel["new_message_count"] == 0)) 
                        ? widget.channel['is_private']
                          ? SvgPicture.asset('assets/icons/Locked.svg', color: Color(0xff5E5E5E))
                          : SvgPicture.asset('assets/icons/iconNumber.svg', width: 13, color: Color(0xff5E5E5E))
                        : widget.channel['is_private']
                          ? SvgPicture.asset('assets/icons/Locked.svg', color: Color(0xffA6A6A6))
                          : SvgPicture.asset('assets/icons/iconNumber.svg', width: 13, color: Colors.white60)
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.channel['name'] ?? "",
                          style: TextStyle(
                            height: 1,
                            fontWeight: !Utils.checkedTypeEmpty(widget.channel["seen"])
                              ? widget.channel["status_notify"] == "OFF" || (widget.channel["status_notify"] == "MENTION" && (widget.channel["new_message_count"] != null && widget.channel["new_message_count"] == 0))
                                ? FontWeight.w400
                                : FontWeight.w700
                              : FontWeight.w400,
                            fontSize: 14,
                            color: (widget.channel["id"] == currentChannel["id"] && selectedTab == "channel")
                                ? Colors.white.withOpacity(0.8)
                                : (!Utils.checkedTypeEmpty(widget.channel["seen"]) && widget.channel["status_notify"] != "OFF" && (widget.channel["status_notify"] != "MENTION" || (widget.channel["status_notify"] == "MENTION" && (widget.channel["new_message_count"] != null && widget.channel["new_message_count"] > 0))))
                                  ? Colors.white
                                  : widget.channel["status_notify"] == "NORMAL" || widget.channel["status_notify"] == "SILENT" || (widget.channel["status_notify"] == "MENTION" && (widget.channel["new_message_count"] != null && widget.channel["new_message_count"] > 0))
                                    ? isDark
                                      ? Palette.darkTextListChannel
                                      : Palette.lightTextListChannel
                                    : isDark ? Colors.grey[700] : Colors.grey
                          ),
                          overflow: TextOverflow.ellipsis
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            (widget.channel["status_notify"] != "OFF" && widget.channel["new_message_count"] != null && widget.channel["new_message_count"] > 0)
              ? Container(
                margin: EdgeInsets.only(right: 2),
                padding: EdgeInsets.only(left: 9, right: 9),
                height: 18,
                decoration: BoxDecoration(
                  color: Palette.errorColor,
                  borderRadius: BorderRadius.circular(18)
                ),
                child: Center(
                  child: Text(
                    widget.channel['new_message_count'] > 99 ? "99+" : "${widget.channel['new_message_count']}",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              )
              // : widget.channel["status_notify"] == "OFF"
              //   ? Container(child: SvgPicture.asset('assets/icons/noti_belloff.svg', color: isDark ? Colors.grey[700] : Colors.grey),)
                : Container()
          ],
        ),
      ),
    );
  }
}