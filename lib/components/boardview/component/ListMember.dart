import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/providers/providers.dart';

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
  String textSearch = "";

  @override
  Widget build(BuildContext context) {
    final channelMember = Provider.of<Channels>(context, listen: false).channelMember.where((e) => e["account_type"] == "user").toList();
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: CupertinoTextField(
            onChanged: (value) {
              this.setState(() {
                textSearch = Utils.unSignVietnamese(value).toLowerCase();
              });
            },
            decoration: BoxDecoration(
              color: isDark ? Palette.backgroundTheardDark : Color(0xffF3F3F3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB))
            ),
            padding: EdgeInsets.only(top: 6, left: 10, bottom: 8),
            placeholder: "Type or choose a name",
            style: TextStyle(fontSize: 14, color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65)),
            placeholderStyle: TextStyle(fontSize: 14, color: isDark ? const Color(0xff9AA5B1) : const Color.fromRGBO(0, 0, 0, 0.65)),
          )
        ),
        Expanded(
          child: ListView.builder(
            itemCount: channelMember.length,
            itemBuilder: (BuildContext context, int index) {
              return (textSearch.trim() != "" && !Utils.unSignVietnamese(channelMember[index]["full_name"]).toLowerCase().contains(textSearch)) ? Container() : InkWell(
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
                          border: Border.all(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                          borderRadius: BorderRadius.circular(50)
                        ),
                        child: Center(child: Icon(Icons.check, color: isDark ? Palette.calendulaGold : Palette.dayBlue, size: 11))
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