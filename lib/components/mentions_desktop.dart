import 'package:flutter/material.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/providers/providers.dart';

class MentionsDesktop extends StatefulWidget {
  MentionsDesktop({Key? key, this.mentionTabKey}) : super(key: key);
  final mentionTabKey;
  @override
  _MentionsDesktopState createState() => _MentionsDesktopState();
}

class _MentionsDesktopState extends State<MentionsDesktop> {
  bool isHover = false;

  checkUnreadMention(data) {
    for (var i = 0; i < data.length; i++) {
      if (data[i]["unread"] == true) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = Provider.of<User>(context, listen: true).selectedTab;
    final dataMentions = Provider.of<Workspaces>(context, listen: true).mentions;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final keyScaffold = auth.keyDrawer;

    var indexW = dataMentions.indexWhere((element) => "${element["workspace_id"]}" == "${currentWorkspace["id"] ?? "_"}");
    bool unread = checkUnreadMention(indexW == -1 ? [] : dataMentions[indexW]["data"]);

    return InkWell(
      onHover: (hover){
        setState(() {
          isHover = hover;
        });
      },

      onTap: () async {
        Provider.of<Channels>(context, listen: false).clearBadge(null, currentWorkspace['id'], true);
        Provider.of<User>(context, listen: false).selectTab("mention");
        if(keyScaffold.currentState!.isEndDrawerOpen) keyScaffold.currentState!.openDrawer();
        auth.channel.push(
          event: "join_channel",
          payload: {"channel_id": 0, "workspace_id": currentWorkspace["id"]}
        );
      },
      child: Container(
        key: unread ? widget.mentionTabKey : null,
        padding: const EdgeInsets.only(right: 8.0, left: 8.0, top: 12.0),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6),
          decoration: selectedTab == "mention" ? BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(3)),
            color: Palette.selectChannelColor
          )
          : isHover ? BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(3)),
              color: Palette.backgroundRightSiderDark
            )
          : BoxDecoration(),
          height: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 8.0),
                    child: Text(
                      "@",
                      style: TextStyle(
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                        color: selectedTab == "mention"
                            ? Colors.white
                            : unread
                                ? Colors.white
                                : isDark
                                    ? Palette.darkTextListChannel
                                    : Palette.lightTextListChannel
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    S.of(context).mentions,
                    style: TextStyle(
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                      color: selectedTab == "mention"
                          ? Colors.white
                          : unread
                            ? Colors.white
                            : isDark
                                ? Palette.darkTextListChannel
                                : Palette.lightTextListChannel
                    )
                  )
                ]
              )
            ]
          )
        ),
      )
    );
  }
}