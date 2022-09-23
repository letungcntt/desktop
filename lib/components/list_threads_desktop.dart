import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:workcake/components/thread_issue_item.dart';
import 'package:workcake/components/thread_item_macos.dart';
import 'package:workcake/providers/providers.dart';

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
  bool setLoadMore = false;

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
    if (mounted && controller.position.pixels == controller.position.maxScrollExtent && !setLoadMore) {
      final token = Provider.of<Auth>(context, listen: false).token;
      Provider.of<Threads>(context, listen: false).loadMoreThread(token, widget.workspaceId, (v) {
        setState(() {
          setLoadMore = v;
        });
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    List dataThreads = Provider.of<Threads>(context, listen: true).dataThreads;
    int index = dataThreads.indexWhere((e) => e["workspaceId"] == widget.workspaceId);
    List currentDataThreads = index != -1 ? dataThreads[index]["threads"] : [];
    List channels = Provider.of<Channels>(context, listen: true).data;
    var token = Provider.of<Auth>(context, listen: true).token;
    final directMessage = Provider.of<DirectMessage>(context, listen: true).directMessageSelected;

    return Stack(
      children: [
        index != -1 ? currentDataThreads.length > 0 ? ListView.builder(
          padding: EdgeInsets.all(24),
          shrinkWrap: true,
          controller: controller,
          itemCount: currentDataThreads.length,
          itemBuilder: (BuildContext context, int index) {
            final e = currentDataThreads[index];
            
            final indexChannel = channels.indexWhere((ele) => ele["id"].toString() == e["channel_id"].toString());
            if (indexChannel != -1) e["is_archived"] = channels[indexChannel]["is_archived"];
            if (e["unread"] == true && e["issue_id"] != null) {
              var workspaceId = e["workspace_id"];
              var channelId = e["channel_id"];
              Provider.of<Threads>(context, listen: false).updateThreadUnread(workspaceId, channelId, e, token);
            }

            return e["issue_id"] != null
              ? ThreadIssueItem(issue: e, key: Key(index.toString()))
              : ThreadItemMacos(
                key: Key(index.toString()),
                parentMessage: e, dataDirectMessage: directMessage,
              );
          })
        : Container() : Container(),
        setLoadMore == true ? 
        Positioned(
          bottom: 0, left: 0,right: 0,
          child: Column(
            children: [
              Container(
                height: 50,
                child: Center(
                  child: Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(100)
                    ),
                    child: SpinKitRing(
                      color: Colors.blue,
                      lineWidth: 3,
                      size: 30,
                    ),
                  ),
                ),
              )
            ],
          ),
        ) :Container(),
      ],
    );
  }
}