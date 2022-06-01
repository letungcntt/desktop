import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/drop_zone.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/models/models.dart';

class NotifyFocusApp extends StatefulWidget {
  NotifyFocusApp({Key? key}) : super(key: key);

  @override
  _NotifyFocusAppState createState() => _NotifyFocusAppState();
}

class _NotifyFocusAppState extends State<NotifyFocusApp> {
  bool isFocusApp = true;

  updateUnreadOpenThread() async {
    final token = Provider.of<Auth>(Utils.globalContext!, listen: false).token;
    final parentMessage = Provider.of<Messages>(Utils.globalContext!, listen: false).parentMessage;

    if (parentMessage["id"] != null) {
      var workspaceId = parentMessage["workspaceId"];
      var channelId = parentMessage["channelId"];
      await Provider.of<Threads>(context, listen: false).updateThreadUnread(workspaceId, channelId, parentMessage, token);
      Utils.updateBadge(context);  
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final changeToMessage = Provider.of<Workspaces>(context, listen: true).changeToMessage;
    return Container(
      child: StreamBuilder<bool>(
        stream: StreamDropzone.instance.isFocusedApp,
        builder: (context, snapshot) {
          if (snapshot.data != null) {
            Provider.of<Auth>(context, listen: false).focusApp(snapshot.data);
            if (isFocusApp != snapshot.data && changeToMessage && !Navigator.of(context).canPop()) {
              isFocusApp = snapshot.data!;
              isFocusApp ? FocusScope.of(context).requestFocus() : FocusScope.of(context).unfocus();
            }
            if (isFocusApp) {
              Future.delayed(Duration(milliseconds: 500), () async { 
                updateUnreadOpenThread();
              });
            }
          }

          return Container();
        }
      )
    );
  }
}