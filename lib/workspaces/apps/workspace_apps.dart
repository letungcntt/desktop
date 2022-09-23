import 'package:flutter/material.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/workspaces/apps/snappy/snappy_app.dart';
import 'package:workcake/workspaces/apps/snappy/snappy_folders.dart';
import 'package:workcake/workspaces/apps/snappy/snappy_forms.dart';
import 'package:workcake/workspaces/apps/snappy/snappy_timesheet.dart';
import 'package:workcake/workspaces/apps/zimbra/app.dart';

import 'banking/banking_app.dart';
import 'banking/vib.dart';

class WorkspaceApps extends StatefulWidget {
  final app;
  final workspaceId;
  const WorkspaceApps({Key? key, @required this.app, @required this.workspaceId}) : super(key: key);

  @override
  State<WorkspaceApps> createState() => _WorkspaceAppsState();
}

class _WorkspaceAppsState extends State<WorkspaceApps> {
  int screenNum = 1;

  @override
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.app["id"] != widget.app["id"]) {
      setState(() => screenNum = 1);
    }
    if (widget.workspaceId != oldWidget.workspaceId) {
      final currentWs = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      List appAdded =  currentWs["app_ids"] ?? [];
      if (!appAdded.contains(widget.app["id"])){
        // hien thi view them app
        Provider.of<User>(context, listen: false).selectTab("app");
      }
    }
  }

  _returnApp(id, workspaceId) {
    switch (id) {
      case 1:
        if (screenNum == 1) return SnappyApps(workspaceId: workspaceId, changeView: _changeViewSnappyApp);
        if (screenNum == 2) return SnappyListForms(workspaceId: workspaceId, changeView: _changeViewSnappyApp);
        if (screenNum == 3) return SnappyFolder(workspaceId: workspaceId, changeView: _changeViewSnappyApp);
        if (screenNum == 4) return SnappyTimeSheet(workspaceId: workspaceId, changeView: _changeViewSnappyApp);
        return Container();
      case 3:
        return AppZimbra();
      case 4:
        return Banking(workspaceId: workspaceId);
      case 12:
        return VibApp();
      default:
        return Container();
    }
  }

  _changeViewSnappyApp(num) {
    setState(() => screenNum = num);
  }

  @override
  Widget build(BuildContext context) {
    return _returnApp(widget.app["id"], widget.workspaceId);
  }
}