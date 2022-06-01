import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/emoji/itemEmoji.dart';
import 'package:workcake/models/models.dart';
class ReactionsDialog extends StatefulWidget {
  final reactions;
  final channelId;
  const ReactionsDialog({ Key? key, required this.reactions, required this.channelId }) : super(key: key);

  @override
  _ReactionsDialogState createState() => _ReactionsDialogState();
}

class _ReactionsDialogState extends State<ReactionsDialog> {
  var indexReactions;

  @override
  void initState() {
    indexReactions = 0;
    super.initState();
  }

  renderReactionPeople(user) {
    List member = Provider.of<Workspaces>(context, listen: false).members;
    final isDark  = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;
    var index = member.indexWhere((element) => element["id"] == user);
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CachedAvatar(member[index]["avatar_url"], name: member[index]["nickname"] ?? member[index]["full_name"], width: 30, height: 30),
          SizedBox(width: 8),
          Text(member[index]["nickname"] ?? member[index]["full_name"], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Color(0xffFFFFFF) : Color(0xff3D3D3D)))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    final reactions = widget.reactions;
    return Container(
      width: MediaQuery.of(context).size.width * 1/3,
      height: MediaQuery.of(context).size.height * 2/5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isDark ? Color(0xff3D3D3D) : Color(0xffFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Reactions", style: TextStyle(fontSize: 16, color: isDark ? Color(0xffEDEDED) : Color(0xff3D3D3D), fontWeight: FontWeight.w700)),
                HoverItem(
                  colorHover: Colors.grey.withOpacity(0.5),
                  child: Container(
                    margin: EdgeInsets.all(4),
                    width: 20,
                    height: 20,
                    child: InkWell(
                      child: Container(
                        child: Center(child: Icon(PhosphorIcons.xCircle, size: 18, color: isDark ? Color(0xffEDEDED) : Color(0xff3D3D3D)))
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 16, right: 16),
                    width: double.infinity,
                    color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      }),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: reactions.map<Widget>((e){
                            var index = reactions.indexOf(e);
                            return Container(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.start,
                                alignment: WrapAlignment.center,
                                children: [
                                  HoverItem(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          indexReactions = index;
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.only(bottom: 8, top: 13),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(width: 2.5, color: index == indexReactions ? isDark ? Color(0xffFAAD14) : Color(0xff1890FF) : Colors.transparent)
                                          )
                                        ),
                                        child: Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.start,
                                          alignment: WrapAlignment.center,
                                          children: [
                                            Container(
                                              child: e["emoji"] is ItemEmoji
                                                ? e["emoji"].render(size: 20.0, padding: 0.0, isEnableHover: false, heightLine: 1.0)
                                                : e["emoji"]["type"] == "default"
                                                    ? Text("${e["emoji"]["value"]}", style: TextStyle(fontSize: 20, height: 1.0))
                                                    : CachedImage(e["emoji"]["url"], height: 40, width: 40,)
                                            ),
                                            SizedBox(width: 4),
                                            e["count"] > 0 ? Text("  ${e["count"]}", style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Color(0xff5E5E5E), fontWeight: FontWeight.w700)): Text(""),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 24)
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      child: ListView.builder(
                        itemCount: reactions[indexReactions]["users"].length,
                        itemBuilder: (BuildContext context, int index) {
                          return renderReactionPeople(reactions[indexReactions]["users"][index]);
                        }
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}