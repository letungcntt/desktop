import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/models/models.dart';

class ListMember extends StatefulWidget {
  const ListMember({
    Key? key,
    this.members,
    this.addOrRemoveMember
  }) : super(key: key);

  final members;
  final addOrRemoveMember;

  @override
  State<ListMember> createState() => _ListMemberState();
}

class _ListMemberState extends State<ListMember> {
  @override
  Widget build(BuildContext context) {
    final channelMember = Provider.of<Channels>(context, listen: false).channelMember;
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: CupertinoTextField(
            decoration: BoxDecoration(
              color: isDark ? Palette.backgroundTheardDark : Color(0xffF3F3F3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB))
            ),
            padding: EdgeInsets.only(top: 6, left: 10, bottom: 4),
            placeholder: "Type or choose a name",
            placeholderStyle: TextStyle(fontSize: 14, color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: channelMember.length,
            itemBuilder: (BuildContext context, int index) {
              return InkWell(
                onTap: () async {
                  setState(() {
                    widget.addOrRemoveMember(channelMember[index]["id"]);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                        width: 1.0
                      )
                    )
                  ),
                  padding: EdgeInsets.symmetric(vertical:  12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          CachedAvatar(channelMember[index]["avatar_url"], name: channelMember[index]["full_name"], width: 24, height: 24),
                          SizedBox(width: 10),
                          Text(channelMember[index]["nickname"] ?? channelMember[index]["full_name"], style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 14))
                        ]
                      ),
                      if(widget.members != null && widget.members.contains(channelMember[index]["id"])) Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xffFAAD14)),
                          borderRadius: BorderRadius.circular(50)
                        ),
                        child: Center(child: Icon(Icons.check, color: Color(0xffFAAD14), size: 11))
                      )
                    ]
                  )
                ),
              );
            }
          )
        )
      ]
    );
  }
}