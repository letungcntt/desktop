import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/providers/providers.dart';

class ListArchived extends StatefulWidget {
  const ListArchived({
    Key? key,
  }) : super(key: key);

  @override
  State<ListArchived> createState() => _ListArchivedState();
}

class _ListArchivedState extends State<ListArchived> {

  onUnarchiveBoard(board, value) {
    final token = Provider.of<Auth>(context, listen: false).token;
    board["is_archived"] = value;
    var newBoard = {...board, "is_archived": value};
    Provider.of<Boards>(context, listen: false).changeBoardInfo(token, board["workspace_id"], board["channel_id"], newBoard);
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<Boards>(context, listen: false).data;
    final boardData = data.where((e) => e["is_archived"] == true).toList();
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Row(
      children: [
        Container(
          width: 360,
          padding: EdgeInsets.only(top: 12, left: 12, right: 12),
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isDark ? Color(0xff262626) : Color(0xffEAE8E8)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Archived Board", style: TextStyle(color: isDark ? null : Color(0xff3D3D3D), fontWeight: FontWeight.w500)),
              SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: boardData.map<Widget>((board) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isDark ? Color(0xff3D3D3D) : Colors.white
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(board["title"]),
                        InkWell(
                          onTap: () {
                            onUnarchiveBoard(board, false);
                          },
                          child: Icon(PhosphorIcons.uploadSimple, size: 18)
                        )
                      ]
                    )
                  );
                }).toList()
              )
            ]
          )
        )
      ]
    );
  }
}