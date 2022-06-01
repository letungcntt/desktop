
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/models/models.dart';

import 'CardItem.dart';

class MemberSelection extends StatefulWidget {
  const MemberSelection({
    Key? key,
    required this.card,
    this.onChangeAttribute
  }) : super(key: key);

  final CardItem card;
  final onChangeAttribute;

  @override
  State<MemberSelection> createState() => _MemberSelectionState();
}

class _MemberSelectionState extends State<MemberSelection> {
  addOrRemoveMember(idx) {
    final channelMember = Provider.of<Channels>(context, listen: false).channelMember;
    final attributeId = channelMember[idx]["id"];

    this.setState(() {
      widget.onChangeAttribute("member", attributeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final channelMember = Provider.of<Channels>(context, listen: true).channelMember;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.only(top: 4),
          child: Center(child: Text("Members", style: TextStyle(color: Colors.grey[700])))
        ),
        Divider(thickness: 1.5),
        CupertinoTextField(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4)
          ),
          padding: EdgeInsets.only(top: 6, left: 10, bottom: 4),
          placeholder: "Search members",
          placeholderStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: channelMember.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                onTap: () async {
                  addOrRemoveMember(index);
                },
                contentPadding: EdgeInsets.symmetric(horizontal: 6),
                leading: CachedAvatar(channelMember[index]["avatar_url"], name: channelMember[index]["full_name"], width: 30, height: 30),
                title: Text(channelMember[index]["full_name"], style: TextStyle(color: Colors.grey[700])),
                trailing: Icon(Icons.check, color: widget.card.members.contains(channelMember[index]["id"]) ? Colors.grey[600] : Colors.transparent, size: 18)
              );
            }
          )
        )
      ]
    );
  }
}
