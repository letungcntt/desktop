import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/models/models.dart';

import 'channel_item_desktop.dart';

class ListChannelDesktop extends StatefulWidget {
  const ListChannelDesktop({
    Key? key,
    @required this.channels, 
    @required this.title,
    this.id,
    this.channelItemKey
  }) : super(key: key);

  final channels;
  final title;
  final id;
  final channelItemKey;

  @override
  _ListChannelDesktopState createState() => _ListChannelDesktopState();
}

class _ListChannelDesktopState extends State<ListChannelDesktop> {
  var open = true;
  List data = [];

  @override
  void initState() { 
    super.initState();

    getStateShowPinned();
  }

  getStateShowPinned() async{
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    var box = await Hive.openBox("stateShowPinned:${currentUser["id"]}");
    data = box.get("data") ?? [];
  }

  showCurrentChannel(currentChannel) {
    if (currentChannel != null) {
      final index = widget.channels.indexWhere((e) => e["id"] == currentChannel["id"]);

      if (!open && index != -1) {
        return true;
      } else {
        return false;
      }
    }
  }

  onChangeStatePinned(value) {
    widget.title == "Channel"
      ? Provider.of<Workspaces>(context, listen: false).onSaveStatePinned(context, widget.id, value, null)
      : Provider.of<Workspaces>(context, listen: false).onSaveStatePinned(context, widget.id, null, value);
    int index = data.indexWhere((e) => e["id"] == widget.id);
    if (index > -1) {
      widget.title == "Channel"
        ? data[index]["isShowChannel"] = value
        : data[index]["isShowPinned"] = value;
    }
    this.setState(() {
      open = value;
    });
  }

  @override
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.id != widget.id) {
      int index = data.indexWhere((ele) => ele["id"] == widget.id);
      if (index > -1) {
        this.setState(() {
          open = widget.title == "Channel" ? data[index]["isShowChannel"] : data[index]["isShowPinned"];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentChannel = Provider.of<Channels>(context, listen: true).currentChannel;
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

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
              widget.title,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w400,
                color: isDark ? Palette.darkTextListChannel : Palette.lightTextListChannel
              )
            ),
            initiallyExpanded: open,
            trailing: Icon(
              open
                ? Icons.keyboard_arrow_down
                : Icons.keyboard_arrow_right,
              color: isDark ? Palette.darkTextListChannel : Palette.lightTextListChannel,
              size: 22
            ),
            children: open ? widget.channels.map<Widget>((e){
              // bool isMention = e == widget.channels.lastWhere((element) => element["status_notify"] != "OFF" && element["new_message_count"] != null && element["new_message_count"] > 0, orElse: () => null);
              bool isLast = e == widget.channels.lastWhere((element) =>
                ((element["status_notify"] == "NORMAL" || element["status_notify"] == "SILENT") && element["seen"] == false) ||
                (element["status_notify"] == "MENTION" && element["new_message_count"] != null && element["new_message_count"] > 0), orElse: () => null);
              return ChannelItemDesktop(key: isLast ? widget.channelItemKey : null, channel: e);
            }).toList() : []
          ),
        ) ,
        if (showCurrentChannel(currentChannel))
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: ChannelItemDesktop(channel: currentChannel)
          )
      ],
    );
  }
}