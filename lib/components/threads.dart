import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/focus_inputbox_manager.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';

class ThreadsTab extends StatefulWidget {
  ThreadsTab({Key? key, this.threadTabKey}) : super(key: key);
  final threadTabKey;

  @override
  _ThreadsTabState createState() => _ThreadsTabState();
}

class _ThreadsTabState extends State<ThreadsTab> {
  bool isHover = false;

  checkUnreadThread(dataThreads) {
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];
    final index = dataThreads.indexWhere((e) => e["workspaceId"] == workspaceId);
    num count = 0;
    bool unread = false;

    if (index != -1) {
      final threadsWorkspace = dataThreads[index]["threads"];

      for (var i = 0; i < threadsWorkspace.length; i++) {
        count += (threadsWorkspace[i]["mention_count"]) ?? 0;

        if (threadsWorkspace[i]["unread"] ?? false) {
          unread = true;
        }
      }
    }

    return {
      "unread": unread,
      "count": count
    };
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = Provider.of<User>(context, listen: true).selectedTab;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final dataThreads = Provider.of<Threads>(context, listen: true).dataThreads;
    final threadStatus = checkUnreadThread(dataThreads);
    final unreadThread = threadStatus["unread"];
    final mentionCount = threadStatus["count"];
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final keyScaffold = auth.keyDrawer;
    final token = auth.token;

    return Container(
      key: unreadThread ? widget.threadTabKey : null,
      height: 32.0,
      decoration: selectedTab == "thread" ? BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(3)),
        color: Palette.selectChannelColor
      ) 
      : isHover ? BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(3)),
          color: Palette.backgroundRightSiderDark
      ) : BoxDecoration(),
      
      margin: EdgeInsets.only(top: 4, right: 8, left: 8, bottom: 4),
      child: InkWell(
        onHover: (value) => setState(() => isHover = value),
        onTap: () {
          Provider.of<User>(context, listen: false).selectTab("thread");
          Provider.of<Threads>(context, listen: false).onChangeTabs(true, token, currentWorkspace["id"]);
          FocusInputStream.instance.dropStream();
          Utils.updateBadge(context);
          if(keyScaffold.currentState!.isEndDrawerOpen) keyScaffold.currentState!.openDrawer();
          auth.channel.push(
            event: "join_channel",
            payload: {"channel_id": 0, "workspace_id": currentWorkspace["id"]}
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  SizedBox(width: 6),
                    SvgPicture.asset(
                      'assets/icons/bubble_chat.svg',
                      width: 16, height: 16,
                      color: selectedTab == "thread"
                        ? Colors.white
                        : unreadThread
                            ? Colors.white
                            : isDark
                              ? Palette.darkTextListChannel
                              : Palette.lightTextListChannel,
                  ),
                  SizedBox(width: 10),
                  Text(
                    S.of(context).threads,
                    style: TextStyle(
                      fontWeight: unreadThread ? FontWeight.w700 : FontWeight.w400,
                      color: selectedTab == "thread"
                          ? Colors.white
                          : unreadThread
                            ? Colors.white
                            : isDark
                              ? Palette.darkTextListChannel
                              : Palette.lightTextListChannel,
                    )
                  ),
                ]
              ),
              mentionCount > 0 ? Container(
                margin: EdgeInsets.only(right: 2),
                padding: EdgeInsets.only(left: 9, right: 9),
                height: 18,
                decoration: BoxDecoration(
                  color: Palette.errorColor,
                  borderRadius: BorderRadius.circular(16)
                ),
                child: Center(
                  child: Text(
                    mentionCount.toString(),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ) : Container()
            ]
          )
        ),
      ),
    );
  }
}