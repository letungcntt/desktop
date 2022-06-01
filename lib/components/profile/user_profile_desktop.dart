import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/splash_screen.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/models/models.dart';

class UserProfileDesktop extends StatefulWidget {
  final userId;

  UserProfileDesktop({Key? key, this.userId}) : super(key: key);

  @override
  _UserProfileDesktopState createState() => _UserProfileDesktopState();
}

class _UserProfileDesktopState extends State<UserProfileDesktop> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool load = true;
  bool isHoverMessenger = false;
  bool isHoverCall = false;
  bool isHoverVideo = false;
  
  void initState() {
    final auth = Provider.of<Auth>(context, listen: false);

    super.initState();
    Timer.run(() async {
      await Provider.of<User>(context, listen: false).getUser(auth.token, widget.userId);
      if (this.mounted) {
        this.setState(() { load = false; });
      }
    });
  }

  goDirectMessage(user) async {
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    var convId = user["conversation_id"];
    if (convId == null){
      convId = MessageConversationServices.shaString([currentUser["id"], user["user_id"] ?? user["id"]]);
    }

    bool hasConv = await Provider.of<DirectMessage>(context, listen: false).getInfoDirectMessage(Provider.of<Auth>(context, listen: false).token, convId);
    var dm;
    if (hasConv){
      dm = Provider.of<DirectMessage>(context, listen: false).getModelConversation(convId);
    } else {
      dm = DirectModel(
        "", 
        [
          {"user_id": currentUser["id"],"full_name": currentUser["full_name"], "avatar_url": currentUser["avatar_url"], "is_online": true}, 
          {"user_id": user["user_id"] ?? user["id"], "avatar_url": user["avatar_url"],  "full_name": user["full_name"] ?? user["name"], "is_online": user["is_online"]}
        ], 
        "", 
        false, 
        0, 
        {}, 
        false,
        0,
        {},
        user["full_name"] ?? user["name"]
      );
    }
    Provider.of<DirectMessage>(context, listen: false).setSelectedDM(dm, "");
    Provider.of<Workspaces>(context, listen: false).setTab(0);
  }

  @override
  Widget build(BuildContext context) {
    var otherUser = Provider.of<User>(context, listen: true).otherUser;
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    String dateString = Utils.checkedTypeEmpty(otherUser) && Utils.checkedTypeEmpty(otherUser!["date_of_birth"])
      ? DateFormatter().renderTime(DateTime.parse(otherUser["date_of_birth"]), type: "dd-MM-yyyy")
      : "Not set";

    bool isVerifyEmail =  Utils.checkedTypeEmpty(otherUser?['is_verified_email']);
    bool isVerifyNumberPhone =  Utils.checkedTypeEmpty(otherUser?['is_verified_phone_number']);

    return Container(
      width: 520, height: 480,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        color: isDark ? Color(0xff3D3D3D) : Color(0xffFFFFFF),
      ),
      child: !load
        ? otherUser != null
          ? Column(
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4), topRight: Radius.circular(4)
                  ),
                  color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 13),
                      child: Text(
                        S.current.userProfile,
                        style: TextStyle(
                          color: isDark ? Color(0xffEDEDED) : Color(0xff3D3D3D),fontSize: 14,fontWeight: FontWeight.w700
                        ),
                      )
                    ),
                    Container(
                      padding: EdgeInsets.only(right: 2),
                      alignment: Alignment.centerRight,
                      child: HoverItem(
                        isRound: true,
                        radius: 5.0,
                        colorHover: isDark ? Color(0xff828282) : Color(0xffDBDBDB),
                        child: IconButton(
                          onPressed: (){
                            Navigator.of(context).pop();
                          },
                          icon: Icon(
                            PhosphorIcons.xCircle,
                            size: 20.0,
                          ),
                        )
                      )
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Color(0xff3D3D3D) : Color(0xffFFFFFF),
                  border: Border(
                    top: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9),width: 1)
                  ),
                ),
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      child:  CachedAvatar(
                        otherUser["avatar_url"],
                        height: 88, width: 88,
                        isRound: true,
                        name: otherUser["full_name"]
                      )
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Container(
                            width: 9, height: 9,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: otherUser['is_online'] ?? false ? Color(0xff27AE60) : Color(0xffbfbfbf)
                            ),
                          ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            otherUser["full_name"],
                            style: TextStyle(
                              color: isDark ? Color(0xffEDEDED) : Color(0xff3D3D3D), 
                              fontWeight: FontWeight.w700, 
                              fontSize: 16
                            )
                          ),
                        ),
                        Text(
                          Utils.checkedTypeEmpty(otherUser["custom_id"]) ? "#${otherUser["custom_id"]}" : "",
                          style: TextStyle(
                            color: isDark ? Color(0xff828282) : Color(0xffA6A6A6), 
                            fontWeight: FontWeight.w500,
                            fontSize: 14
                          )
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 25),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(
                          color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)
                        )),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onHover: (hover){
                              setState(() {
                                isHoverMessenger = hover;
                              });
                            },
                            onTap: () async{
                              await goDirectMessage(otherUser);
                              Navigator.pop(context);
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: isHoverMessenger ? 250 : 100),
                              curve: isHoverMessenger ? Curves.easeOutCubic : Curves.easeInCirc,
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isHoverMessenger ? isDark ? Color(0xffFAAD14) : Color(0xff1890FF)
                                : isDark ? Color(0xff4C4C4C) : Color(0xffF8F8F8),
                                borderRadius: BorderRadius.circular(isHoverMessenger ? 5 : 5 ),
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset('assets/icons/comment.svg', color: isDark ? isHoverMessenger ? Color(0xff3D3D3D) : Color(0xffFAAD14) : isHoverMessenger ? Color(0xffFFFFFF) : Color(0xff1890FF), width: 15, height: 15),
                                  SizedBox(width: 8),
                                  Text(
                                    S.current.messages,
                                    style: TextStyle(
                                      color: isDark ? isHoverMessenger ? Color(0xff3D3D3D) : Color(0xffFAAD14) : isHoverMessenger ? Color(0xffFFFFFF) : Color(0xff1890FF),
                                      fontSize: 14
                                    )
                                  ),
                                ],
                              ),
                            )
                          ),
                          InkWell(
                            onHover: (hover){
                              setState(() {
                                isHoverCall = hover;
                              });
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: isHoverCall ? 250 : 100),
                              curve: isHoverCall ? Curves.easeOutCubic : Curves.easeInCirc,
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isHoverCall ? isDark ? Color(0xffFAAD14) : Color(0xff1890FF)
                                : isDark ? Color(0xff4C4C4C) : Color(0xffF8F8F8),
                                borderRadius: BorderRadius.circular(isHoverCall  ? 5 : 5 ),
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset('assets/icons/phone.svg', color: isDark ? isHoverCall ? Color(0xff3D3D3D) : Color(0xffFAAD14) : isHoverCall ? Color(0xffFFFFFF) : Color(0xff1890FF), width: 15, height: 15),
                                  SizedBox(width: 8),
                                  Text(
                                    S.current.call,
                                    style: TextStyle(
                                      color: isDark ? isHoverCall ? Color(0xff3D3D3D) : Color(0xffFAAD14) : isHoverCall ? Color(0xffFFFFFF) : Color(0xff1890FF),
                                      fontSize: 14
                                    )
                                  ),
                                ],
                              ),
                            )
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              final currentUser = Provider.of<User>(context, listen: false).currentUser;
                              var convId = otherUser["conversation_id"];
                              if (convId == null){
                                convId = MessageConversationServices.shaString([currentUser["id"], otherUser["user_id"] ?? otherUser["id"]]);
                              }
                              p2pManager.createVideoCall(otherUser, convId);
                            },
                            onHover: (hover){
                              setState(() {
                                isHoverVideo = hover;
                              });
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: isHoverVideo ? 250 : 100),
                              curve: isHoverVideo ? Curves.easeOutCubic : Curves.easeInCirc,
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isHoverVideo ? isDark ? Color(0xffFAAD14) : Color(0xff1890FF) 
                                : isDark ? Color(0xff4C4C4C) : Color(0xffF8F8F8),
                                borderRadius: BorderRadius.circular(isHoverVideo  ? 5 : 5 ),
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset('assets/icons/video.svg', color: isDark ? isHoverVideo ? Color(0xff3D3D3D) : Color(0xffFAAD14) : isHoverVideo ? Color(0xffFFFFFF) : Color(0xff1890FF), width: 15, height: 15),
                                  SizedBox(width: 8),
                                  Text(
                                    S.current.videoCall,
                                    style: TextStyle(
                                      color: isDark ? isHoverVideo ? Color(0xff3D3D3D) : Color(0xffFAAD14) : isHoverVideo ? Color(0xffFFFFFF) : Color(0xff1890FF),
                                      fontSize: 14
                                    )
                                  ),
                                ],
                              ),
                            )
                          ),
                          FriendStatus(deviceWidth: 400),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(PhosphorIcons.user,size: 16, color: isDark ? Color(0xff828282) : Color(0xffA6A6A6)),
                                SizedBox(width: 5,),
                                Text(S.current.fullName.toUpperCase(), style: TextStyle(color: isDark ? Color(0xff828282) : Color(0xffA6A6A6), fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            Container(
                              width: 222, height: 40,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              alignment: Alignment.center,
                              child: Text(
                                otherUser["full_name"],
                                style: TextStyle(color: isDark ? Color(0xffEDEDED) : Color(0xff5E5E5E), fontSize: 14, fontWeight: FontWeight.w400),
                              ),
                            )
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                        ),
                        SizedBox(width: 10,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(PhosphorIcons.envelopeSimple, size: 16, color: isDark ? Color(0xff828282) : Color(0xffA6A6A6)),
                                SizedBox(width: 5,),
                                Text(S.current.email.toUpperCase(), style: TextStyle(color: isDark ? Color(0xff828282) : Color(0xffA6A6A6), fontSize: 13, fontWeight: FontWeight.w500)),
                                SizedBox(width: 20),
                                SvgPicture.asset(
                                  'assets/icons/verified_icon.svg',
                                  color: isVerifyEmail ? Palette.successColor : Palette.errorColor
                                )
                              ],
                            ),
                            Container(
                              width: 222, height: 40,
                              padding: EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              child: Text(
                                otherUser["email"] != null ? otherUser["email"] : "Not set",
                                style: TextStyle(color: isDark ? Color(0xffEDEDED) : Color(0xff5E5E5E), fontSize: 14, fontWeight: FontWeight.w400),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Container(
                      height: 1,
                      color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(PhosphorIcons.genderIntersex,size: 16,color: isDark ? Color(0xff828282) : Color(0xffA6A6A6)),
                                SizedBox(width: 5,),
                                Text(S.current.gender.toUpperCase(), style: TextStyle(color: isDark ? Color(0xff828282) : Color(0xffA6A6A6), fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            Container(
                              width: 144, height: 40,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              alignment: Alignment.center,
                              child: Text(
                                otherUser["gender"] != null ? otherUser["gender"] : "Not set",
                                style: TextStyle(color: isDark ? Color(0xffEDEDED) : Color(0xff5E5E5E), fontSize: 14, fontWeight: FontWeight.w400)
                              ),
                            )
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 55,
                          color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(PhosphorIcons.cake,size: 16,color: isDark ? Color(0xff828282) : Color(0xffA6A6A6)),
                                SizedBox(width: 5,),
                                Text(S.current.dateOfBirth.toUpperCase(), style: TextStyle(color: isDark ? Color(0xff828282) : Color(0xffA6A6A6), fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            Container(
                              width: 144, height: 40,
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              child: Text(dateString, style: TextStyle(color: isDark ? Color(0xffEDEDED) : Color(0xff5E5E5E), fontSize: 14,fontWeight: FontWeight.w400))
                            )
                          ],
                        ),
                        SizedBox(width: 10),
                        Container(
                          width: 1,
                          height: 55,
                          color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset('assets/icons/phone.svg', color: isDark ? Color(0xff828282) : Color(0xffA6A6A6), width: 15, height: 15),
                                  SizedBox(width: 4),
                                  Text(S.current.phoneNumber.toUpperCase(), style: TextStyle(color: isDark ? Color(0xff828282) : Color(0xffA6A6A6), fontSize: 12, fontWeight: FontWeight.w500)),
                                  SizedBox(width: 8),
                                  SvgPicture.asset(
                                    'assets/icons/verified_icon.svg',
                                    color: isVerifyNumberPhone ? Palette.successColor : Palette.errorColor
                                  )
                                ],
                              ),
                              Container(
                                width: 144, height: 40,
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                alignment: Alignment.center,
                                child: Text(
                                  (otherUser["phone_number"] == null || otherUser["phone_number"] == "") ? "Not set" : '${otherUser["phone_number"]}',
                                  style: TextStyle(
                                    color: isDark ? Color(0xffEDEDED) : Color(0xff5E5E5E), fontSize: 14,fontWeight: FontWeight.w400
                                  )
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                )
              )
            ],
          )
          : SplashScreen()
        : Center(
          child: SpinKitFadingCircle(
            color: isDark ? Colors.white60 : Color(0xff096DD9),
            size: 35,
          )
        ),
    );
  }
}

class FriendStatus extends StatefulWidget {
  const FriendStatus({
    Key? key,
    @required this.deviceWidth
  }) : super(key: key);

  final deviceWidth;

  @override
  State<FriendStatus> createState() => _FriendStatusState();
}

class _FriendStatusState extends State<FriendStatus> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    
    final otherUser = Provider.of<User>(context, listen: true).otherUser;
    final isSended = otherUser!["is_sended"] == 1 ? true : false;
    final isRequested = otherUser["is_requested"] == 1 ? true : false;
    final auth = Provider.of<Auth>(context, listen: false);
    final token = auth.token;
    final isDark = auth.theme == ThemeType.DARK;
    return  InkWell(
      onHover: (hover){
        setState(() {
          isHover = hover;
        });
      },
      onTap: () async {
        if (isSended == true && isRequested == true) {
          await showCupertinoModalPopup(
            context: context,
            builder: (BuildContext context) => CupertinoActionSheet(
            actions: <Widget>[
              CupertinoActionSheetAction(
                child: Text(S.current.block, style: TextStyle(color: Color(0xffEF5350))),
                onPressed: () {

                }
              ),
              CupertinoActionSheetAction(
                child: Text(S.current.removeFriend),
                onPressed: () async {
                  await Provider.of<User>(context, listen: false).removeRequest(token, otherUser["id"]);
                  Navigator.pop(context);
                }
              )
            ])
          );
        } else if (isRequested) {
          await showCupertinoModalPopup(
            context: context,
            builder: (BuildContext context) =>  CupertinoActionSheet(
            actions: <Widget>[
              CupertinoActionSheetAction(
                child: Text(S.current.confirm),
                onPressed: () async{
                  await Provider.of<User>(context, listen: false).acceptRequest(token, otherUser["id"]);
                  Navigator.pop(context);
                }
              ),
              CupertinoActionSheetAction(
                child: Text(S.current.reject, style: TextStyle(color: Colors.red[400])),
                onPressed: () async {
                  await Provider.of<User>(context, listen: false).removeRequest(token, otherUser["id"]);
                  Navigator.pop(context);
                }
              )
            ])
          );
        } else if (isSended) {
          await Provider.of<User>(context, listen: false).removeRequest(token, otherUser["id"]);
          Navigator.pop(context);
        } else {
          await Provider.of<User>(context, listen: false).addFriendRequest(otherUser["id"],token);
        }
      },
      child: AnimatedContainer(
        width: 122, height: 38,
        duration: Duration(milliseconds: isHover ? 250 : 100),
        curve: isHover ? Curves.easeOutCubic : Curves.easeInCirc,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isHover ? isDark ? Color(0xffFAAD14) : Color(0xff1890FF)
          : isDark ? Color(0xff4C4C4C) : Color(0xffF8F8F8),
          borderRadius: BorderRadius.circular(isHover ? 5 : 5 ),
        ),
        child: Row(
          children: [
            (isRequested == true && isSended == true)
              ? Icon(Icons.check, size: 16, color: isDark ? isHover ? Color(0xff3D3D3D) : Color(0xffFAAD14) : isHover ? Color(0xffFFFFFF) : Color(0xff1890FF))
              : (isRequested == true || isSended == true)
                ? Icon(Icons.replay, size: 16, color: isDark ? isHover ? Color(0xff3D3D3D) : Color(0xffFAAD14) : isHover ? Color(0xffFFFFFF) : Color(0xff1890FF))
                : SvgPicture.asset('assets/icons/AddMember.svg', color: isDark ? isHover ? Color(0xff3D3D3D) : Color(0xffFAAD14) : isHover ? Color(0xffFFFFFF) : Color(0xff1890FF), width: 15, height: 15),
            SizedBox(width: 8),
            Text(
              (isRequested == true && isSended == true ) ? S.current.accepted : isRequested == true ? S.current.response : isSended ? S.current.cancel : S.current.addFriend,
              style: TextStyle(
                color: isDark ? isHover ? Color(0xff3D3D3D) : Color(0xffFAAD14) : isHover ? Color(0xffFFFFFF) : Color(0xff1890FF),
                fontSize: 14
              )
            ),
          ],
        ),
      )
    );
  }
}