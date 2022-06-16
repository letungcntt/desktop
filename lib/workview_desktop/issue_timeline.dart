import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/models/models.dart';

import 'label.dart';

class IssueTimeline extends StatefulWidget {
  IssueTimeline({
    Key? key,
    this.timelines,
    this.issue,
    this.onTap
  }) : super(key: key);

  final timelines;
  final issue;
  final Function? onTap;

  @override
  _IssueTimelineState createState() => _IssueTimelineState();
}

class _IssueTimelineState extends State<IssueTimeline> {
  findLabel(id) {
    final data = Provider.of<Channels>(context, listen: false).data;
    final index = data.indexWhere((e) => e["id"].toString() == widget.issue["channel_id"].toString());
    final labels = index != -1 ? data[index]["labels"] ?? [] : [];
    final indexLabel = labels.indexWhere((e) => e["id"] == id);

    if (indexLabel != -1) {
      return labels[indexLabel]; 
    } else {
      return null;
    }
  }

  findUser(id) {
    final members = Provider.of<Workspaces>(context, listen: false).members;
    final indexMember = members.indexWhere((e) => e["id"] == id);

    if (indexMember != -1) {
      return members[indexMember];
    } else {
      return {};
    }
  }

  findMilestone(id) {
    final data = Provider.of<Channels>(context, listen: false).data;
    final index = data.indexWhere((e) => e["id"].toString() == widget.issue["channel_id"].toString());
    final milestones = index != -1 ? data[index]["milestones"] ?? [] : [];
    final indexMilestone = milestones.indexWhere((e) => e["id"] == id);

    if (indexMilestone != -1) {
      return milestones[indexMilestone]; 
    } else {
      return null;
    }
  }

  parseDatetime(time) {
    if (time != "") {
      DateTime offlineTime = DateTime.parse(time).add(Duration(hours: 7));
      DateTime now = DateTime.now();
      final difference = now.difference(offlineTime).inMinutes;

      final hour = difference ~/ 60;
      final minutes = difference % 60;
      final day = hour ~/24;

      if (day > 0) {
        int month = day ~/30;
        int year = month ~/12;
        if (year >= 1) return ' ${year.toString().padLeft(1, "")} ${year > 1 ? "years" : "year"} ago';
        else {
          if (month >= 1) return ' ${month.toString().padLeft(1, "")} ${month > 1 ? "months" : "month"} ago';
          else return ' ${day.toString().padLeft(1, "")} ${day > 1 ? "days" : "day"} ago';
        }
      } else if (hour > 0) {
        return ' ${hour.toString().padLeft(1, "")} ${hour > 1 ? "hours" : "hour"} ago';
      } else if(minutes <= 1) {
        return ' moment ago';
      } else {
        return ' ${minutes.toString().padLeft(1, "0")} minutes ago';
      }
    } else {
      return "";
    }
  }

  var timelineItem = Container();
  bool rebuild = false;

  @override
  void didUpdateWidget (oldWidget) {
    rebuild = false;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final members = Provider.of<Workspaces>(context, listen: false).members;
  
    if (!rebuild) {
      try {
        timelineItem = timelineTile(widget.timelines, members, isDark);
      } catch (e) {
        timelineItem = Container(child: Text("Render timeline error"));
      }
      rebuild = true;
    }
  
    return timelineItem;
  }

  getListAttribute(data, type) {
    List list = []; 

    for (var i = 0; i < data.length; i++) {
      var e = data[i];
      var item = type == "labels" ? findLabel(e) : type == "assignees" ? findUser(e) : findMilestone(e);
      if (item != null) list.add(e);
    }

    return list;
  }

  timelineTile(timelines, members, isDark) {
    return Container(
      margin: EdgeInsets.only(left: 6),
      child: Column(
        children: timelines.map<Widget>((e) {
          final timeline = e;

          if (timeline["data"] == null) {
            return Container();
          } else {
            final type = timeline["data"]["type"];
            List added = getListAttribute(timeline["data"]["added"] ?? [], type);
            List removed = getListAttribute(timeline["data"]["removed"] ?? [], type);
            final indexMember = members.indexWhere((e) => e["id"] == timeline["user_id"]);
            final author = indexMember != -1 ? members[indexMember] : null;

            if(type == 'create_message') {
              return TimelineTile(
                indicatorStyle: IndicatorStyle(
                  width: 25,
                  color: isDark ? Palette.backgroundRightSiderDark : Colors.white,
                  iconStyle: IconStyle(
                    iconData: Icons.person_outline,
                    fontSize: 18,
                    color: isDark ? Colors.white : Color(0xff2A5298)
                  )
                ),
                beforeLineStyle: LineStyle(color: isDark ? Palette.borderSideColorDark : Color(0xffCBD2D9), thickness: 1),
                afterLineStyle: LineStyle(color: isDark ? Palette.borderSideColorDark : Color(0xffCBD2D9), thickness: 1),
                endChild: Container(
                  margin: EdgeInsets.only(left: 12),
                  padding: EdgeInsets.symmetric(vertical: 8),
                  width: MediaQuery.of(context).size.width,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: CachedImage(author["avatar_url"] ?? "", height: 28, width: 28, radius: 50, name: author["full_name"] ?? "P"),
                        ),
                        TextSpan(
                          text: ' ${author["full_name"]}  ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65),
                          )
                        ),
                        TextSpan(
                          text: 'Created by message: ${timeline['data']['description']}',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            height: 1.25,
                            fontWeight: FontWeight.w300
                          ),
                          recognizer: TapGestureRecognizer()..onTap = () => widget.onTap != null ? widget.onTap!() : null,
                        ),
                      ],
                    ),
                    
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  )
                )
              );
            }

            return ((type != "close_issue" && type != "open_issue" && added.length == 0 && removed.length == 0)) ? Container() : TimelineTile(
              indicatorStyle: IndicatorStyle(
                width: 25,
                color: isDark ? Palette.backgroundRightSiderDark : Colors.white,
                iconStyle: IconStyle(
                  iconData: type == "labels" ? Icons.local_offer_outlined : type == "assignees" ? Icons.person_outline : type == "milestone" ? Icons.flag_outlined : type == "close_issue" ? Icons.do_disturb_alt_outlined : Icons.radio_button_checked_outlined,
                  fontSize: type == "labels" || type =="close_issue" ? 18 : 19,
                  color: isDark ? Colors.white : Color(0xff2A5298)
                )
              ),
              beforeLineStyle: LineStyle(color: isDark ? Palette.borderSideColorDark : Color(0xffCBD2D9), thickness: 1),
              afterLineStyle: LineStyle(color: isDark ? Palette.borderSideColorDark : Color(0xffCBD2D9), thickness: 1),
              endChild: Container(
                margin: EdgeInsets.only(left: 12),
                padding: EdgeInsets.symmetric(vertical: 8),
                width: MediaQuery.of(context).size.width,
                child: Wrap(
                  direction: Axis.horizontal,
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    type == "close_issue" ? Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AuthorTimeline(author: author, isDark: isDark, showAction: false),
                        Text(" closed this", style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65))),
                      ],
                    ) : Text(""),
                    type == "open_issue" ? Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AuthorTimeline(author: author, isDark: isDark, showAction: false),
                        Text(" reopened this", style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65))),
                      ],
                    ) : Text(""),
                    type == "close_issue" || type == "open_issue" ? Text(parseDatetime(timeline["inserted_at"]), style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65))) : Text(""),
                    
                    added.length > 0 ? Wrap(
                      direction: Axis.horizontal,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: added.map((e) {
                            final index = added.indexWhere((ele) => ele == e);
                            var label = type == "labels" ? findLabel(e) : null;
                            var user = type == "assignees" ? findUser(e) : null;
                            var milestone = type == "milestone" ? findMilestone(e) : null;

                            if (label != null || user != null || milestone != null) {
                              return type == "labels" && label != null ? Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (index == 0) AuthorTimeline(author: author, isDark: isDark, type: "added"),
                                  LabelDesktop(labelName: label["name"], color: int.parse("0XFF${label["color_hex"]}")),
                                ]
                              ) : type == "assignees" ? Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (index == 0) AuthorTimeline(author: author, isDark: isDark, type: "added"),
                                    Container(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            SizedBox(width: 2),
                                            CachedImage(user?["avatar_url"] ?? "", height: 28, width: 28, radius: 50, name: user["nickname"] ?? user?["full_name"] ?? "P"),
                                            SizedBox(width: 4),
                                            Text("${user["nickname"] ?? user["full_name"]}", style: TextStyle( fontWeight: FontWeight.w700, color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65)),),
                                          ]
                                        )
                                      )
                                    )
                                  ]
                                ) : milestone != null ? Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (index == 0) AuthorTimeline(author: author, isDark: isDark, type: "added"),
                                    Container(
                                      margin: EdgeInsets.only(bottom: 2),
                                      child: RichText(
                                        text: TextSpan(
                                          children: <TextSpan>[
                                            TextSpan(
                                              text: milestone["due_date"] != null ? (DateFormatter().renderTime(DateTime.parse(milestone["due_date"]), type: "MMMd")) : "",
                                              style: TextStyle(fontFamily: "Roboto", color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65), fontSize: 14,height: 1.57, fontWeight: FontWeight.w700)
                                            ),
                                            TextSpan(text: ' milestone', style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65)))
                                          ]
                                        )
                                      ),
                                    )
                                  ]
                                ) : Container();
                            } else {
                              return SizedBox();
                            }
                          }).toList()
                        ),
                        SizedBox(width: 3),
                        removed.length == 0 ? Text(parseDatetime(timeline["inserted_at"]), style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65))) : SizedBox()
                      ]
                    ) : Text(""),

                    removed.length > 0 ? Wrap(
                      direction: Axis.horizontal,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(added.length > 0 ? "and" : "", style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65))),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: removed.map((e) {
                            var label = findLabel(e);
                            var user = findUser(e);
                            var milestone = type == "milestone" ? findMilestone(e) : null;
                            final index = removed.indexWhere((ele) => ele == e);

                            if (label != null || user != null || milestone != null) {
                              return type == "labels" && label != null ? Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (index == 0) AuthorTimeline(author: author, isDark: isDark, type: "removed", showAuthor: !(added.length > 0)),
                                  LabelDesktop(labelName: label["name"], color: int.parse("0XFF${label["color_hex"]}")),
                                ]
                              ) : 
                                type == "assignees" ? Container(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        if (index == 0) AuthorTimeline(author: author, isDark: isDark, type: "removed", showAuthor: !(added.length > 0)),
                                        CachedImage(user?["avatar_url"] ?? "", height: 28, width: 28, radius: 50, name: user?["full_name"] ?? "P"),
                                        SizedBox(width: 8),
                                        Text("${user["nickname"] ?? user["full_name"]} ", style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ) : milestone != null ?
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (index == 0) AuthorTimeline(author: author, isDark: isDark, type: "removed", showAuthor: !(added.length > 0)),
                                    Text(
                                      milestone["due_date"] != null ? (DateFormatter().renderTime(DateTime.parse(milestone["due_date"]), type: "MMMd")) : "",
                                      style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65), fontSize: 14, fontWeight: FontWeight.w700)
                                    ),
                                    Text(' milestone', style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65)))
                                  ],
                                ) : Container();
                            } else {
                              return SizedBox();
                            }
                          }).toList()
                        ),
                        SizedBox(width: 1),
                        Text(parseDatetime(timeline["inserted_at"]), style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65)))
                      ]
                    ) : SizedBox()
                  ]
                )
              )
            );
          }
        }).toList()
      )
    );
  }
}

class AuthorTimeline extends StatelessWidget {
  const AuthorTimeline({
    Key? key,
    required this.author,
    required this.isDark,
    this.type = "added",
    this.showAuthor = true,
    this.showAction = true
  }) : super(key: key);

  final author;
  final isDark;
  final type;
  final showAuthor;
  final showAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showAuthor) CachedImage(author?["avatar_url"] ?? "", height: 28, width: 28, radius: 50, name:author?["nickname"] ?? author?["full_name"] ?? "P"),
        if (showAuthor) SizedBox(width: 8),
        if (showAuthor) Text(
          author?["nickname"] ?? author?["full_name"] ?? "Unknown",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65))
        ),
        if (showAction) Text(type == "added" ? " added " : " removed ",style: TextStyle(fontSize: 14),)
      ]
    );
  }
}