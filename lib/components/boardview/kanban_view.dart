
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/models/models.dart';

import 'boardview_desktop.dart';
import 'list_board_item.dart';

class KanbanView extends StatefulWidget {
  const KanbanView({
    Key? key,
  }) : super(key: key);

  @override
  State<KanbanView> createState() => _KanbanViewState();
}

class _KanbanViewState extends State<KanbanView> {
  bool collapseListBoard = false;

  onCollapseListBoard() {
    this.setState(() {
      collapseListBoard = !collapseListBoard;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: true).currentChannel;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListBoardItem(workspaceId: currentWorkspace["id"], channelId: currentChannel["id"], collapseListBoard: collapseListBoard),
        BoardViewDesktop(onCollapseListBoard: onCollapseListBoard, collapseListBoard: collapseListBoard)
      ]
    );
  }
}