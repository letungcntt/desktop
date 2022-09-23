
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:workcake/providers/providers.dart';

import 'boardview_desktop.dart';
import 'list_board_item.dart';

class KanbanView extends StatefulWidget {
  const KanbanView({
    Key? key,
    this.channelId
  }) : super(key: key);

  final channelId;

  @override
  State<KanbanView> createState() => _KanbanViewState();
}

class _KanbanViewState extends State<KanbanView> {
  bool collapseListBoard = true;
  bool showArchiveBoard = false;
  final boardViewKey = GlobalKey<BoardViewDesktopState>();

  @override
  void didUpdateWidget (oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelId != widget.channelId) {
      showArchiveBoard = false;
    }
  }

  onCollapseListBoard() {
    this.setState(() {
      collapseListBoard = !collapseListBoard;
    });
  }

  onShowArchiveBoard(value) async {
    this.setState(() {
      showArchiveBoard = value;
    });
    if (value) {
      Provider.of<Boards>(context, listen: false).onChangeBoard({});
    } else {
      final data = Provider.of<Boards>(context, listen: false).data.where((e) => e["is_archived"] != true).toList();
      final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
      final box = await Hive.openBox("lastSelectedBoard");
      final lastSelectedBoard = box.get(currentChannel["id"].toString());
      final index = data.indexWhere((e) => e["id"] == lastSelectedBoard["id"]);
      Provider.of<Boards>(context, listen: false).onChangeBoard(index == -1 ? data.length > 0 ? data[0] : {} : data[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;

    return InkWell(
      onTap: () {
        boardViewKey.currentState!.selectList(null);
        boardViewKey.currentState!.selectCardToRename(null);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListBoardItem(workspaceId: currentWorkspace["id"], channelId: currentChannel["id"], collapseListBoard: collapseListBoard, onShowArchiveBoard: onShowArchiveBoard, showArchiveBoard: showArchiveBoard),
          BoardViewDesktop(key: boardViewKey, onCollapseListBoard: onCollapseListBoard, collapseListBoard: collapseListBoard, showArchiveBoard: showArchiveBoard)
        ]
      ),
    );
  }
}