import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:workcake/providers/providers.dart';

import 'CardItem.dart';

class ChecklistSelection extends StatefulWidget {
  ChecklistSelection({
    Key? key,
    required this.card
  }) : super(key: key);

  final CardItem card;

  @override
  _ChecklistSelectionState createState() => _ChecklistSelectionState();
}

class _ChecklistSelectionState extends State<ChecklistSelection> {
  TextEditingController controller = TextEditingController(text: "Checklist");

  addChecklistToCard() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    CardItem card = widget.card;
    List checklists = card.checklists;
    int index = checklists.indexWhere((e) => e["title"] == controller.text.trim());

    if (index == -1) {
      await Provider.of<Boards>(context, listen: false).createChecklist(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card.id, controller.text.trim()).then((res) {
        checklists.add(res["checklist"]);
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.only(top: 4),
          child: Center(child: Text("Add checklist", style: TextStyle(color: Colors.grey[700])))
        ),
        Divider(thickness: 1.5, indent: 6, endIndent: 6),
        SizedBox(height: 8),
        Container(margin: EdgeInsets.only(left: 6), alignment: Alignment.centerLeft, child: Text("Title", style: TextStyle(fontSize: 16, color: Colors.grey[700]))),
        SizedBox(height: 4),
        Container(
          height: 36,
          margin: EdgeInsets.only(left: 4),
          child: CupertinoTextField(
            autofocus: true,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3)
            ),
            controller: controller,
            padding: EdgeInsets.only(top: 10, left: 10, bottom: 4),
            placeholderStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          )
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Colors.blueAccent,
          ),
          child: TextButton(
            onPressed: () {
              if (controller.text.trim() != "") {
                addChecklistToCard();
              }
            },
            child: Text("Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400))
          )
        )
      ]
    );
  }
}