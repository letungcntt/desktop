import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:workcake/common/focus_inputbox_manager.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/providers/providers.dart';

class ListArchived extends StatefulWidget {
  @override
  _ListArchivedState createState() => _ListArchivedState();

}
class _ListArchivedState extends State<ListArchived>{
  final TextEditingController _searchQuery = new TextEditingController();
  ValueNotifier<bool> showSuggestions = ValueNotifier(false);
  List channels = [];
  List contacts = [];
  List workspaces = [];
  List messages = [];
  List dataMessageAll = [];
  int contactsLength = 3;


  onSelectChannel(channelId, workspaceId) async {
    final auth = Provider.of<Auth>(context, listen: false);
    Provider.of<Workspaces>(context, listen: false).setTab(workspaceId);
    Provider.of<Workspaces>(context, listen: false).selectWorkspace(auth.token, workspaceId, context);
    Provider.of<User>(context, listen: false).selectTab("channel");
    await Provider.of<Channels>(context, listen: false).setCurrentChannel(channelId);
    Provider.of<Messages>(context, listen: false).loadMessages(auth.token, workspaceId, channelId);
    await Provider.of<Channels>(context, listen: false).selectChannel(auth.token, workspaceId, channelId);
    auth.channel.push(
      event: "join_channel",
      payload: {"channel_id": channelId, "workspace_id": workspaceId}
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    channels = Provider.of<Channels>(context, listen: true).data.where((ele) => (ele["is_archived"] && ele['workspace_id'] == currentWorkspace['id'])).toList();
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xff3D3D3D) : Color(0xffFFFFFFF),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          Container(
            height: 35,
            padding: EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("List Archive Channel", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
          Container(
            child: Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(top: 4),
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    return HoverItem(
                      colorHover: isDark ? Color(0xff828282) : Color(0xffDBDBDB),
                      child: TextButton(
                        onPressed: () {
                          onSelectChannel(channel["id"], channel["workspace_id"]);
                          _searchQuery.clear();
                          showSuggestions.value = false;
                          FocusScope.of(context).unfocus();
                          FocusInputStream.instance.focusToMessage();
                          Navigator.pop(context);
                          setState(() {
                            workspaces = [];
                            messages = [];
                            contacts = [];
                            dataMessageAll = [];
                            contactsLength = 3;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 8, top: 8,left: 4),
                          child: Row(
                            children: [
                              channel["is_private"] ? SvgPicture.asset('assets/icons/Locked.svg', color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight) : SvgPicture.asset('assets/icons/iconNumber.svg', width: 13, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                              SizedBox(width: 4.0),
                              Text("${channel["name"]} ${channel["is_archived"] == true ? "(archived)" : ""}", style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Color(0xFF1F2933), fontWeight: FontWeight.w600)),
                            ]
                          ),
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}