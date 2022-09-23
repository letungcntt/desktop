import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/providers/providers.dart';

class CardTimeline extends StatefulWidget {
  CardTimeline({
    Key? key,
    this.onBack,
    required this.timelines
  }) : super(key: key);

  final onBack;
  final List timelines;

  @override
  State<CardTimeline> createState() => _CardTimelineState();
}

class _CardTimelineState extends State<CardTimeline> {
  findUser(id) {
    final members = Provider.of<Workspaces>(context, listen: false).members;
    final indexMember = members.indexWhere((e) => e["id"] == id);

    if (indexMember != -1) {
      return members[indexMember];
    } else {
      return {};
    }
  }

  findLabel(labelId) {
    final selectedBoard = Provider.of<Boards>(context, listen: true).selectedBoard;
    final index = selectedBoard["labels"].indexWhere((e) => e["id"] == labelId);

    if (index == -1) {
      return {};
    } else {
      return selectedBoard["labels"][index];
    }
  }

  renderTimelineItem(payload) {
    final timeline =payload["data"];
    final type = timeline["type"];
    final user = findUser(timeline["userId"]);
    TextSpan data = TextSpan();

    switch (type) {
      case "removeLabel":
      case "addLabel":
        final label = findLabel(timeline["value"]);
        data = TextSpan(
          children: [
            TextSpan(text: type == "removeLabel" ? "removed " : "added "),
            WidgetSpan(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(int.parse("0xFF${label["color_hex"]}")),
                  borderRadius: BorderRadius.circular(16)
                ),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: EdgeInsets.only(right: 4),
                height: 20,
                child: Text(label["name"], style: TextStyle(color: Colors.white, fontSize: 12))
              )
            )
          ]
        );
        break;
      
      case "addMember":
      case "removeMember":
        final member = findUser(timeline["value"]);

        data = TextSpan(
          children: [
            TextSpan(text: type == "removeMember" ? "removed " : "added "),
            TextSpan(
              text: member["full_name"],
              style: TextStyle(color: Color(0xffFAAD14)),
            )
          ]
        );
        break;

      case "changePriority":
        final priority = timeline["value"];

        data = TextSpan(
          children: [
            TextSpan(text: "changed priority to "),
            TextSpan(
              text: "${priority == 1 ? 'Urgent' : priority == 2 ? 'High' : priority == 3 ? 'Medium' :  priority == 4 ? 'Low' : 'None'}",
              style: TextStyle(
                color: Color(priority == 1 ? 0xffFF7875 : priority == 2 ? 0xffFAAD14 : priority == 3 ? 0xff27AE60 : priority == 4 ? 0xff69C0FF : 0xffFFFFFF),
                fontSize: 14
              )
            )
          ]
        );
        break;
      
      case "changeDueDate":
        data = TextSpan(
          children: [
            TextSpan(text: "changed due date to "),
            TextSpan(text: timeline["value"], style: TextStyle(color: Colors.grey[500]))
          ]
        );
        break;

      case "changeTitle":
      case "changeDescription":
        data = TextSpan(
          children: [
            TextSpan(text: type == "changeTitle" ? "changed title to " : "changed description to "),
            TextSpan(text: timeline["value"], style: TextStyle(color: Colors.grey[500]))
          ]
        );
        break;
        
      default:
        break;
    }


    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: user["full_name"],
              style: TextStyle(color: Color(0xffFAAD14)),
            ),
            WidgetSpan(child: Container(width: 3)),
            data,
            TextSpan(
              children: [
                TextSpan(text: " at "),
                TextSpan(
                  style: TextStyle(color: Colors.grey[500]),
                  text: (DateFormatter().renderTime(DateTime.parse(payload["inserted_at"]), type: 'kk:mm dd-MM-yyy'))
                )
              ]
            )
          ]
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              widget.onBack();
            },
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(PhosphorIcons.arrowLeft, size: 19),
                SizedBox(width: 10),
                Text("Back")
              ]
            )
          ),
          SizedBox(height: 18),
          Container(
            height: 560,
            child: ListView.builder(
              shrinkWrap: true,
              controller: ScrollController(),
              itemCount: widget.timelines.length,
              itemBuilder: (BuildContext context, int index) { 
                return renderTimelineItem(widget.timelines[index]);
              }
            )
          )
        ]
      )
    );
  }
}