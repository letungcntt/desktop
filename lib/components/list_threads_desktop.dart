import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/components/thread_issue_item.dart';
import 'package:workcake/components/thread_item_macos.dart';
import 'package:workcake/models/models.dart';

class ListThreadsDesktop extends StatefulWidget {
  ListThreadsDesktop({
    Key? key,
    @required this.workspaceId
  }) : super(key: key);

  final workspaceId;

  @override
  _ListThreadsDesktopState createState() => _ListThreadsDesktopState();
}

class _ListThreadsDesktopState extends State<ListThreadsDesktop> {
  ScrollController controller = ScrollController();

  @override
  void initState() { 
    super.initState();
    controller..addListener(scrollListener);
  }


  @override
  void didUpdateWidget(covariant ListThreadsDesktop oldWidget) {
    if (oldWidget.workspaceId != widget.workspaceId) {
      if (controller.hasClients) controller.jumpTo(0);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  scrollListener() {
    if (mounted && controller.position.pixels == controller.position.maxScrollExtent) {
      final token = Provider.of<Auth>(context, listen: false).token;
      Provider.of<Threads>(context, listen: false).loadMoreThread(token, widget.workspaceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    List dataThreads = Provider.of<Threads>(context, listen: true).dataThreads;
    int index = dataThreads.indexWhere((e) => e["workspaceId"] == widget.workspaceId);
    List currentDataThreads = index != -1 ? dataThreads[index]["threads"] : [];
    List channels = Provider.of<Channels>(context, listen: true).data;
    // var token = Provider.of<Auth>(context, listen: true).token;

    return index != -1 ? SingleChildScrollView(
      padding: EdgeInsets.all(24),
      controller: controller,
      child: Column(
        children: currentDataThreads.map<Widget>((e) {
          final index = channels.indexWhere((ele) => ele["id"].toString() == e["channel_id"].toString());
          if (index != -1) e["is_archived"] = channels[index]["is_archived"];

          if (e["unread"] == true && e["issue_id"] != null) {
            // var workspaceId = e["workspace_id"];
            // var channelId = e["channel_id"];
            // Provider.of<Threads>(context, listen: false).updateThreadUnread(workspaceId, channelId, e, token);
          }

          return e["issue_id"] != null
            ? ThreadIssueItem(issue: e, key: Key(e["issue_id"].toString()))
            : ThreadItemMacos(
              key: Key(e["id"].toString()),
              parentMessage: e
            );
        }).toList()
      )
    ) : Container();
  }
}