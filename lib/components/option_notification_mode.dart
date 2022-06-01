import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/models/models.dart';

class OptionNotificationMode extends StatefulWidget {
  const OptionNotificationMode({ Key? key }) : super(key: key);

  @override
  _OptionNotificationModeState createState() => _OptionNotificationModeState();
}

class _OptionNotificationModeState extends State<OptionNotificationMode> {
  String? _option;

  @override
  void initState() {
    super.initState();
    final currentMember = Provider.of<Channels>(context, listen: false).currentMember;
    setState(() => _option = currentMember["status_notify"]);
  }

  Widget renderOption(type, value) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return InkWell(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              width: 1,
              color: Palette.borderSideColorLight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: <Widget>[
                  Radio(
                    activeColor: Color(0xff096DD9),
                    value: type == 1
                      ? "NORMAL"
                      : type == 2
                        ? "MENTION"
                        : type == 3
                          ? "SILENT"
                          : "OFF",
                    groupValue: _option,
                    onChanged: (value) {
                      setState(() => _option = value as String? );
                    },
                  ),
                  SizedBox(width: 5),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type == 1
                          ? S.current.normalMode
                          : type == 2
                            ? S.current.mentionMode
                            : type == 3
                              ? S.current.silentMode
                              : S.current.offMode,
                        style: TextStyle(
                          color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark, 
                          fontSize: 14
                        )
                      ),
                      SizedBox(height: 5),
                      Text(
                        type == 1
                          ? S.current.desNormalMode
                          : type == 2
                            ? S.current.desMentionMode
                            : type == 3
                              ? S.current.desSilentMode
                              : S.current.desOffMode,
                        style: TextStyle(
                          color: isDark ? Color(0xffA6A6A6) : Color(0xff828282), 
                          fontSize: 14,
                          overflow: TextOverflow.ellipsis
                        )
                      )
                    ],
                  )
                ]
              ),
              Container(
                child: type == 1
                  ? SvgPicture.asset('assets/icons/noti_bell.svg', color: isDark ? Palette.topicTile : null)
                  : type == 2
                    ? SvgPicture.asset('assets/icons/noti_mentions.svg', color: isDark ? Palette.topicTile : null)
                    : type == 3
                      ? SvgPicture.asset('assets/icons/noti_silent.svg', color: isDark ? Palette.topicTile : null)
                      : SvgPicture.asset('assets/icons/noti_belloff.svg', color: isDark ? Palette.topicTile : null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentMember = Provider.of<Channels>(context, listen: false).currentMember;

    return Container(
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4))
        ),
        titlePadding: const EdgeInsets.all(0),
        contentPadding: EdgeInsets.zero,
        insetPadding: EdgeInsets.zero,
        backgroundColor: isDark ? Color(0xFF3D3D3D ) : Colors.white,
        title: Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xff5E5E5E).withOpacity(0.5) : Color(0xffF3F3F3),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(4.0),
              topLeft: Radius.circular(4.0)
            )
          ),
          child: Container(
            padding: const EdgeInsets.only(top: 9, bottom: 9, left: 16),
            child: Text(S.current.notifySetting, style: TextStyle(fontSize: 16))
          ),
        ),
        content: Container(
          width: 729,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10)
          ),
          height: 340,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    renderOption(1, currentMember["status_notify"]),
                    SizedBox(height: 12),
                    renderOption(2, currentMember["status_notify"]),
                    SizedBox(height: 12),
                    renderOption(3, currentMember["status_notify"]),
                    SizedBox(height: 12),
                    renderOption(4, currentMember["status_notify"])
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1),
              Container(
                height: 59,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 32,
                      width: 80,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          side: BorderSide(color: Color(0xffFF7875))
                        ),
                        onPressed: () { 
                          Navigator.of(context, rootNavigator: true).pop("Discard");
                        },
                        child: Text(S.current.cancel, style: TextStyle(color: Color(0xffFF7875)))
                      ),
                    ),
                    SizedBox(width: 5),
                    Container(
                      height: 32,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      margin: EdgeInsets.only(right: 12.0),
                      // color: Color(0xff1890FF),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Color(0xff1890FF)  
                      ),
                      child: TextButton(
                        onPressed: () {
                          Map member = Map.from(currentMember);
                          member["status_notify"] = _option;

                          Provider.of<Channels>(context, listen: false).changeChannelMemberInfo(auth.token, currentWorkspace["id"], currentChannel["id"], member);
                          Navigator.of(context, rootNavigator: true).pop("Discard");
                        },
                        child: Text(S.current.save, style: TextStyle(color: Colors.white, fontSize: 13))
                      ),
                    )
                  ],
                ),
              )
            ]
          )
        ),
      )
    );
  }
}

List optionNotificationDM = [
  {"value": "NORMAL", "description": S.current.desNormalMode, "label": S.current.normalMode, "short_label": "Normal"},
  {"value": "MENTION", "description": S.current.desMentionMode, "label": S.current.mentionMode,  "short_label": "Mention"},
  {"value": "OFF", "description": S.current.desOffMode, "label": S.current.offMode,  "short_label": "Off"},
];

SvgPicture getIconNotificationByStatusDM(String status, bool isDark){
  switch (status) {
    case "NORMAL": return SvgPicture.asset('assets/icons/noti_bell.svg', color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight);
    case "MENTION": return  SvgPicture.asset('assets/icons/noti_mentions.svg', color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight);
    case "OFF": return  SvgPicture.asset('assets/icons/noti_silent.svg', color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight);
    default: return SvgPicture.asset('assets/icons/noti_bell.svg', color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight);
  }
}

String getShortLabelNotificationStatusDM(String value){
  int index = optionNotificationDM.indexWhere((element) => element["value"] == value);
  if (index != -1) return optionNotificationDM[index]["short_label"];
  return "";
}
// for dm

class NotificationDM extends StatefulWidget {
  final String conversationId;
  final Function onSave;
  
  const NotificationDM({ Key? key, required this.conversationId, required this.onSave }) : super(key: key);

  @override
  _NotificationDMState createState() => _NotificationDMState();
}

class _NotificationDMState extends State<NotificationDM> {
  String? notificationStatus;
   
  @override
  initState(){
    super.initState();
    DirectModel? dm = Provider.of<DirectMessage>(context, listen: false).getModelConversation(widget.conversationId);
    var userId  = Provider.of<Auth>(context, listen: false).userId;
    if (dm != null){
      var indexUser = dm.user.indexWhere((element) => element["user_id"] == userId);
      if (indexUser != -1) {
        print(dm.user[indexUser]);
        notificationStatus = dm.user[indexUser]["status_notify"] ?? "NORMAL";
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
     return Container(
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4))
        ),
        titlePadding: const EdgeInsets.all(0),
        contentPadding: EdgeInsets.zero,
        insetPadding: EdgeInsets.zero,
        backgroundColor: isDark ? Color(0xFF3D3D3D ) : Colors.white,
        title: Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xff5E5E5E).withOpacity(0.5) : Color(0xffF3F3F3),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(4.0),
              topLeft: Radius.circular(4.0)
            )
          ),
          child: Container(
            padding: const EdgeInsets.only(top: 9, bottom: 9, left: 16),
            child: Text(S.current.notifySetting, style: TextStyle(fontSize: 16))
          ),
        ),
        content: Container(
          width: 729,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10)
          ),
          height: 240,
          child: notificationStatus == null ? Container(
            child: Text("You can't change settings"),
          ) : Column(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 24, right: 24, top:24, bottom: 12),
                child: Column(
                  children: optionNotificationDM.map(
                    (option) => GestureDetector(
                      onTap: () {
                        setState(() {
                          notificationStatus = option["value"];
                        });
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 1, horizontal: 16),
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              width: 1,
                              color: Palette.borderSideColorLight,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Radio<String>(
                                activeColor: Color(0xff096DD9),
                                value: option["value"],
                                groupValue: notificationStatus,
                                onChanged: (value) {
                                  setState(() => notificationStatus = value );
                                },
                              ),
                              Container(
                                child: getIconNotificationByStatusDM(option["value"], isDark),
                              ),
                              SizedBox(width: 5),
                              Text(option["label"],
                                style: TextStyle(
                                  color: isDark ? Palette.topicTile : Palette.backgroundRightSiderDark, 
                                  fontSize: 14
                                )
                              ),
                              SizedBox(width: 10),
                              Text(option["description"],
                                style: TextStyle(
                                  color: isDark ? Color(0xffA6A6A6) : Color(0xff828282), 
                                  fontSize: 14,
                                  overflow: TextOverflow.ellipsis
                                )
                              )
                            ]
                          ),
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ),
              Divider(height: 1, thickness: 1),
              Container(
                height: 59,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 32,
                      width: 80,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          side: BorderSide(color: Color(0xffFF7875))
                        ),
                        onPressed: () { 
                          Navigator.of(context, rootNavigator: true).pop("Discard");
                        },
                        child: Text(S.current.cancel, style: TextStyle(color: Color(0xffFF7875)))
                      ),
                    ),
                    SizedBox(width: 5),
                    Container(
                      height: 32,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      margin: EdgeInsets.only(right: 12.0),
                      // color: Color(0xff1890FF),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Color(0xff1890FF)  
                      ),
                      child: TextButton(
                        onPressed: (){
                          widget.onSave(widget.conversationId, {
                            "status_notify": notificationStatus
                          }, auth.token, auth.userId);
                          Navigator.pop(context);
                        },
                        child: Text(S.current.save, style: TextStyle(color: Colors.white, fontSize: 13))
                      ),
                    )
                  ],
                ),
              )
            ]
          )
        ),
      )
    );
  }
}
