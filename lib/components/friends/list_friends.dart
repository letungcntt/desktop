import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/friends/custom_friend_dialog.dart';
import 'package:workcake/components/friends/friends_desktop.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/providers/providers.dart';

class ListMemberFriends extends StatefulWidget {
  const ListMemberFriends({
    Key? key,
    @required
    this.isDark,
    this.back,
    this.friendList,
    this.isRequest,
    this.auth,

  }) : super(key: key);
  final isDark;
  final back;
  final friendList;
  final isRequest;
  final auth;

  @override
  _ListMemberFriends createState() => _ListMemberFriends();
}
sortTimeList(friendList){
  different(time){
    if (time != null) {
      DateTime offlineTime = DateTime.parse(time).add(Duration(hours: 7));
      DateTime now = DateTime.now();
      final difference = now.difference(offlineTime).inMinutes;
      return difference;
    }
    return -1;
  }

  var activeList = friendList.where((element) => element["is_online"] == true).toList();
  var inactiveList = friendList.where((element) => !element["is_online"] == true).toList();

  inactiveList.sort((a,b) => different(a["offline_at"]).compareTo(different(b["offline_at"])));
  return [...activeList, ...inactiveList];
}
class _ListMemberFriends extends State<ListMemberFriends> {
  bool hoverSendButton = false;
  TextEditingController controller = TextEditingController();
  bool selectedFriendRequest = false;
  bool isSendView = false;
  bool selectedSearch = false;
  bool selectedFriends = false;
  List newFriends = [];
  bool isEmoji = false;

  @override
  initState() {
    super.initState();
    RawKeyboard.instance.addListener(handleEvent);
  }

  KeyEventResult handleEvent(RawKeyEvent event) {
    if(event is RawKeyDownEvent) {
      if(event.isKeyPressed(LogicalKeyboardKey.escape)) {
        if(selectedFriends) setState(() => selectedFriends = false);
        else {
          Provider.of<Channels>(context, listen: false).openFriends(false);
        }
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(handleEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final auth = Provider.of<Auth>(context);
    final friendList = Provider.of<User>(context, listen: true).friendList.where((e) => e != null).toList();
    final pendingUsers = Provider.of<User>(context, listen: true).pendingList;
    final sendingUsers = Provider.of<User>(context, listen: true).sendingList;

    sendFriendRequest() async {
      final usernameTag = controller.text;
      final data = await Provider.of<User>(context,listen: false).sendFriendRequestTag(usernameTag,auth.token);

      showModal(
        context: context,
        builder: (_) => CustomFriendDialog(
          title: data["success"] ? "Successful" : "Unsuccessful",
          string: data["message"],
          data: data,
        )
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              color: isDark ? Color(0xFF2e2e2e) : Color(0xFFF3F3F3),
              child: Column(
                children: [
                  Container(
                    height: 56,
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Palette.backgroundTheardDark,
                      border: Border(
                        bottom: BorderSide(
                          color: Palette.borderSideColorDark,
                        )
                      )
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset('assets/icons/memberIcon.svg'),
                            SizedBox(width: 10),
                            Text("CONTACT", style: TextStyle(color: Color(0xffF0F4F8), fontSize: 16, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        HoverItem(
                          colorHover: Palette.hoverColorDefault,
                          child: IconButton(
                            onPressed:(){
                              Provider.of<Channels>(context, listen: false).openFriends(false);
                            },
                            icon: SvgPicture.asset('assets/icons/newX.svg', height: 14.13)
                          ),
                        ),
                    ],)
                  ),
                  SizedBox(height: 16,),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: (){
                              setState(() {
                                selectedSearch = !selectedSearch;
                              });
                            },
                            child: Center(
                              child: selectedSearch ? Container(
                                decoration: BoxDecoration(
                                  color: Utils.getPrimaryColor(),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: HoverItem(
                                  colorHover: Color(0xffD9D9D9).withAlpha(20) ,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Center(child: Text("Add Friend", style: TextStyle(fontSize: 14,color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight)
                               )),
                                  ),
                                ),
                              ): Container(
                                decoration: BoxDecoration(
                                  color: isDark ? Color(0xff505050) : Color.fromARGB(255, 211, 207, 207),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: HoverItem(
                                  colorHover: isDark ? Color(0xffD9D9D9).withAlpha(20) : Color.fromARGB(255, 199, 195, 195),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Center(child: Text("Add Friend", style: TextStyle(fontSize: 14,color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight)
                               )),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16,),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => selectedFriendRequest = !selectedFriendRequest),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? Color(0xff505050) : Color.fromARGB(255, 211, 207, 207),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              // padding: EdgeInsets.symmetric(vertical: 8,horizontal: 26),
                              child: HoverItem(
                                colorHover: pendingUsers.length > 0 ? Palette.hoverColorDefault : null, radius: 4.0, isRound: true,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        " Request",
                                        style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 14),
                                       ),
                                       SizedBox(width: 2,),
                                       Text(
                                        "(${pendingUsers.length.toString()})",
                                        style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 11.5),
                                       ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    height: 1,
                    margin: EdgeInsets.only(top: 17),
                    color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                  ),
                  selectedSearch ? Container(
                    margin: EdgeInsets.only(left: 14,right: 14,top: 20,bottom: 6),
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      border: !isDark ? Border.all(width: 1.0,color: Color(0xffE4E7EB)) : null,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      color: isDark ? Color(0xff1D1515) : Colors.white
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            child: Focus(
                              onFocusChange: (value) {
                                Provider.of<Windows>(context, listen: false).isOtherFocus = value;
                              },
                              child: TextFormField(
                                // focusNode: FocusNode(),
                                controller: controller,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.only(left: 10, bottom: 8, top: 8, right: 15),
                                  hintText: "Enter a Username#0000",
                                  hintStyle: TextStyle(fontSize: 14.0, color: isDark ? Colors.white24 : Color.fromRGBO(0, 0, 0, 0.30))
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Expanded(child: Container()),
                        MouseRegion(
                          onEnter: (value) => setState(() => hoverSendButton = true),
                          onExit: (value) => setState(() => hoverSendButton = false),
                          child: TextButton(onPressed: () => controller.text.length > 0 ? sendFriendRequest() : null, child: Icon(PhosphorIcons.plusCircle, color: Color(0xffB0B0B0))),
                        )
                      ],
                    ),
                  ):SizedBox(),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18,vertical: 8),
                            child: Row(
                              children: [
                                Text("All friends",style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: isDark ? Colors.white70 : Color(0xff2E2E2E))),
                                SizedBox(width: 2,),
                                Text("(${friendList.length})",style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: isDark ? Colors.white70 : Color(0xff2E2E2E)))
                              ],
                            ),
                          ),
                          ListFriends(friendList: sortTimeList(friendList), auth: auth, widget: widget, isRequest: false,),
                        ],
                      )
                    ),
                  )
                ],
              ),
            ),
            AnimatedPositioned(
              curve: Curves.easeOutExpo,
              duration: Duration(milliseconds: 500),
              left: selectedFriendRequest  ? 0.0 : 1000.0,
              height:  MediaQuery.of(context).size.height,
              // top: 0.0, bottom: 0.0,
              // child: Text("Sdfsdfdsfdsfsdfsdff")
              child: Container(
                width: selectedFriendRequest ? constraints.maxWidth : 0.0,
                color: isDark ? Color(0xFF2e2e2e) : Color(0xFFF3F3F3),
                margin: EdgeInsets.symmetric(horizontal:2),
                child: Column(
                  children: [
                    Container(
                      height: 56,
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Palette.backgroundTheardDark,
                        border: Border(
                          bottom: BorderSide(
                            color: Palette.borderSideColorDark,
                          )
                        )
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset('assets/icons/memberIcon.svg'),
                              SizedBox(width: 10),
                              Text("CONTACT", style: TextStyle(color: Color(0xffF0F4F8), fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          HoverItem(
                            colorHover: Palette.hoverColorDefault,
                            child: IconButton(
                              onPressed:(){
                                Provider.of<Channels>(context, listen: false).openFriends(false);
                              },
                              icon: SvgPicture.asset('assets/icons/newX.svg', height: 14.13)
                            ),
                          ),
                      ],)
                    ),
                    Expanded(
                      child: Container(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedFriendRequest = false;
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                        child: Icon(PhosphorIcons.arrowLeft, size: 20,),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text("Friend Request", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                      SizedBox(width: 3,),
                                      Text(
                                        " (" + (isSendView ? sendingUsers : pendingUsers).length.toString() + ")",
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 1,
                              margin: EdgeInsets.symmetric(vertical: 10),
                              color: Palette.borderSideColorDark,
                            ),
                            SizedBox(height: 6,),
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight.withOpacity(0.75))
                                ),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        isSendView = false;
                                      });
                                    },
                                    child: Container(
                                      height: 30, width: 60,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border:  Border(
                                          bottom: BorderSide(
                                            width: 1.75,
                                            color: !isSendView ? isDark ? Palette.calendulaGold : Palette.dayBlue : Colors.transparent
                                          )
                                        ),
                                      ),
                                      padding: EdgeInsets.only(bottom: 14),
                                      child: Text(
                                        'Receive',
                                        style: TextStyle(
                                          color: !isSendView ? (isDark ? Palette.calendulaGold : Palette.dayBlue) : (isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                        )
                                      )
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        isSendView = true;
                                      });
                                    },
                                    child: Container(
                                      height: 30, width: 50,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            width: 1.75,
                                            color: isSendView ? isDark ? Palette.calendulaGold : Palette.dayBlue : Colors.transparent
                                          )
                                        ),
                                      ),
                                      padding: EdgeInsets.only(bottom: 14),
                                      child: Text(
                                        'Send',
                                        style: TextStyle(
                                          color: isSendView ? (isDark ? Palette.calendulaGold : Palette.dayBlue) : (isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                        )
                                      )
                                    ),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(height: 4,),
                            !isSendView ? (pendingUsers.length > 0 ? ListFriends(friendList: pendingUsers, auth: auth, widget: widget, isRequest: true) : Container(
                              height: 60,
                              margin: EdgeInsets.only(bottom: 12, top: 14),
                              padding: EdgeInsets.symmetric(horizontal: 44, vertical: 22),
                              decoration: BoxDecoration(
                                color: isDark ? Palette.backgroundRightSiderDark : Palette.topicTile,
                                borderRadius: BorderRadius.all(Radius.circular(2))
                              ),
                              child: Text(
                                'No Incoming Friend Request ....',
                                style: TextStyle(
                                  color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                                  fontSize: 13.5
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )) : (sendingUsers.length > 0 ? ListFriends(friendList: sendingUsers, auth: auth, widget: widget, isRequest: true, isSend: true) : Container(
                              height: 60,
                              margin: EdgeInsets.only(bottom: 12, top: 14),
                              padding: EdgeInsets.symmetric(horizontal: 44, vertical: 22),
                              decoration: BoxDecoration(
                                color: isDark ? Palette.backgroundRightSiderDark : Palette.topicTile,
                                borderRadius: BorderRadius.all(Radius.circular(2))
                              ),
                              child: Text(
                                'No Send Friend Request ....',
                                style: TextStyle(
                                  color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                                  fontSize: 13.5
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        );
      }
    );
  }
}




