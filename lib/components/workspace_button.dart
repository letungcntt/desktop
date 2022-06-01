import 'dart:async';
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:simple_tooltip/simple_tooltip.dart';
import 'package:workcake/common/focus_inputbox_manager.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/components/call_center/room.dart';
import 'package:workcake/models/models.dart';


final noImageAvailable = "https://statics.pancake.vn/web-media/3e/24/0b/bb/09a144a577cf6867d00ac47a751a0064598cd8f13e38d0d569a85e0a.png";

class WorkSpaceButton extends StatefulWidget{
  WorkSpaceButton({
    Key? key,
    required this.onTap,
    this.currentTab,
    this.item,
    this.index,
    this.newMessage,
    this.newBadgeCount,
    this.avtUrl
  }) : super(key: key);

  final VoidCallback onTap;
  final currentTab;
  final item;
  final index;
  final newMessage;
  final newBadgeCount;
  final avtUrl;

  @override
  State<StatefulWidget> createState() {
    return _WorkspaceButtonState();
  }
}
class _WorkspaceButtonState extends State<WorkSpaceButton>{
  bool isHover = false;
  bool isClick = false;

  Widget avatarName() {
    return AnimatedContainer(
      duration: Duration(milliseconds: isHover ? 250 : 100),
      decoration: BoxDecoration(
        color: isHover || isClick || widget.currentTab == widget.item["id"] ? Palette.buttonColor : Color(0xff707070),
        borderRadius: BorderRadius.circular(isHover || isClick || widget.currentTab == widget.item["id"] ? 16 : 40),
      ),
      curve: isHover ? Curves.easeOutCubic : Curves.easeInCirc,
      child: Center(
        child: Text(
          widget.item["name"] != null ? widget.item["name"].substring(0, 1).toUpperCase() : "",
          style: TextStyle(
            color: Color(0xffF0F4F8),
            fontSize: 20.0,
            fontWeight: FontWeight.w400
          ),
        ),
      ),
    );
  }

  var workspaceButton = Container();
  var rebuild = false;

  @override
  void didUpdateWidget(oldWidget) {
    if (widget.item.toString() != oldWidget.item.toString() ||
      widget.avtUrl != oldWidget.avtUrl ||
      widget.currentTab != oldWidget.currentTab ||
      widget.index != oldWidget.index || 
      widget.newBadgeCount != oldWidget.newBadgeCount ||
      widget.newMessage != oldWidget.newMessage
    ) {
      setState(() {
        rebuild = false;
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (!rebuild) {
      try {
        workspaceButton = buildWorkspaceButton();
        rebuild = true;
      } catch (e) {
        workspaceButton = Container(child: Text("${e.toString()}"));
      }
    }
   
    return workspaceButton;
  }

  buildWorkspaceButton() {
    final isDark  = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedContainer(
            curve: Curves.easeOutSine,
            margin: EdgeInsets.only(right: widget.currentTab != widget.item["id"] && !isHover && !widget.newMessage ? 4 : 0),
            duration: Duration(milliseconds: 250),
            width: widget.currentTab == widget.item["id"] || isHover || widget.newMessage ? 4 : 0,
            height: widget.currentTab == widget.item["id"] ? 40 : isHover ? 20 : widget.newMessage ? 10 : 0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
              color: isHover || widget.currentTab == widget.item["id"] || widget.newMessage ? Color(0xffFAFAFA) : Color(0xff1F2933),
            ),
          ),

          JustTheTooltip(
            triggerMode: TooltipTriggerMode.tap,
            preferredDirection: AxisDirection.right,
            backgroundColor: isDark ? Color(0xFF1c1c1c): Colors.white,
            offset: 12,
            tailLength: 10,
            tailBaseWidth: 10,
            fadeOutDuration: Duration(milliseconds: 10),
            content: Material(
              color: Colors.transparent,
              child: Container(
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1c1c1c): Colors.white,
                borderRadius: BorderRadius.circular(5)
              ),
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.item["name"]),
                    SizedBox(width: 8.0),
                    Container(child: Text(Platform.isMacOS ? "⌘" : "Alt", style: TextStyle(fontSize: Platform.isMacOS ? 10.5 : 14.0),), padding: EdgeInsets.symmetric(horizontal: 3.0), decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.grey[200], borderRadius: BorderRadius.circular(2.0))),
                    SizedBox(width: 2.0),
                    Container(child: Text((widget.index + 2).toString()), padding: EdgeInsets.symmetric(horizontal: 3.0), decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.grey[200], borderRadius: BorderRadius.circular(2.0)))
                  ],
                ),
              )
            ),
            child: Stack(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 3),
                  height: 50,
                  width: 50,
                  child: Container(
                    padding: isClick ? EdgeInsets.only(top: 4, bottom: 0, right: 2, left: 2) : EdgeInsets.all(2),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) {
                        setState(() {
                          rebuild = false;
                          isHover = true;
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          rebuild = false;
                          isHover = false;
                        });
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapCancel: () {
                          setState(() {
                            isClick = false;
                          });
                        },
                        onTapDown: (_){
                          setState(() {
                            rebuild = false;
                            isHover = false;
                            isClick = true;
                          });
                          final selectedTab = Provider.of<User>(context, listen: false).selectedTab;
                          if (selectedTab == "channel") FocusInputStream.instance.focusToMessage();
                        },
                        onTapUp: (_){
                          Future.delayed(Duration(milliseconds: 25),(){
                            setState((){
                              rebuild = false;
                              isClick = false;
                            });
                          });
                          widget.onTap();
                        },
                        child: widget.item["avatar_url"] == null || widget.item["avatar_url"].isEmpty  ? 
                        avatarName() : 
                        AnimatedContainer(
                          duration: Duration(milliseconds: isHover ? 250 : 100),
                          curve: isHover ? Curves.easeOutCubic : Curves.easeInCirc,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(isHover || isClick || widget.currentTab == widget.item["id"] ? 16 : 40),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: ExtendedImage.network(
                                widget.avtUrl,
                                fit: BoxFit.cover,
                                repeat: ImageRepeat.noRepeat,
                                cacheHeight: 80,
                                cache: true,
                                cacheMaxAge: Duration(days: 10),
                              ).image
                            )
                          )
                        )
                      ),
                    )
                  )
                ),
                widget.newBadgeCount ? Container () : Positioned(
                  right: 1, top: 36,
                  child: Container(
                    height: 16, width: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: Color(0xff1E1E1E)
                    ),
                  )
                ),
                widget.newBadgeCount ? Container () : Positioned(
                  right: 3, top: 38,
                  child: Container(
                    height: 12, width: 12,
                      decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: EdgeInsets.all(1),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: Colors.red
                      ),
                    ),
                  )
                  // child: IconBadge()
                )
              ],
            ),
          ),
          SizedBox(
            height: 48
          )
        ]
      )
    );
  }
}

class DirectMessageButton extends StatefulWidget{
  DirectMessageButton({this.currentTab, this.onTap});
  final currentTab;
  final onTap;
  @override
  _DirectMessageButtonState createState() => _DirectMessageButtonState();
}

class _DirectMessageButtonState extends State<DirectMessageButton> {
  bool isHover = false;
  bool isClick = false;
  checkDirectStatus() {
    return Provider.of<DirectMessage>(context, listen: true).unreadConversation.unreadCount == 0;
  }
  @override
  Widget build(BuildContext context) {
    final isDark  = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 250),
          curve: Curves.easeOutSine,
          margin: EdgeInsets.only(right: widget.currentTab != 0 && !isHover ? 4 : 0),
          width: widget.currentTab == 0 || isHover ? 4 : 0,
          height: widget.currentTab == 0 ? 40 : isHover ? 20 : 0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
            color: isHover || widget.currentTab == 0 ? Color(0xffFAFAFA) : Color(0xff1F2933)
          ),
        ),
        SimpleTooltip(
          animationDuration: Duration(milliseconds: 100),
          tooltipDirection: TooltipDirection.right,
          borderColor: isDark ? Color(0xFF262626) :Color(0xFFb5b5b5),
          borderWidth: 0.5,
          borderRadius: 5,
          backgroundColor: isDark ? Color(0xFF1c1c1c): Colors.white,
          arrowLength:  14,
          arrowBaseWidth: 10.0,
          ballonPadding: EdgeInsets.zero,
          minimumOutSidePadding: 0.0,
          content: Material(child: Container(color: isDark ? Color(0xFF1c1c1c): Colors.white,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Direct Message"),
                SizedBox(width: 8.0),
                Container(child: Text(Platform.isMacOS ? "⌘" : "Ctrl", style: TextStyle(fontSize: Platform.isMacOS ? 10.5 : 14.0),), padding: EdgeInsets.symmetric(horizontal: 3.0), decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.grey[200], borderRadius: BorderRadius.circular(2.0))),
                SizedBox(width: 2.0),
                Container(child: Text("1"), padding: EdgeInsets.symmetric(horizontal: 3.0), decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.grey[200], borderRadius: BorderRadius.circular(2.0)))
              ],
            ),
          )),
          show: isHover,
          child: Container(
            height: 50,
            width: 50,
            child: Stack(
              children: [
                Container(
                  padding: isClick ? EdgeInsets.only(top: 4, bottom: 0, right: 2, left: 2) : EdgeInsets.all(2),
                    child: InkWell(
                      onHover: (hover){
                        setState(() {
                          isHover = hover;
                        });
                      },
                      onTap: (){},
                      child: GestureDetector(
                        onTapDown: (_){
                          setState(() {
                            isClick = true;
                            isHover = false;
                          });
                          FocusInputStream.instance.focusToMessage();
                        },
                        onTapUp: (_){
                          Future.delayed(Duration(milliseconds: 25), (){
                            setState((){
                              isClick = false;
                            });
                          });
                          widget.onTap();
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: isHover ? 250 : 100),
                          curve: isHover ? Curves.easeOutCubic : Curves.easeInCirc,
                          decoration: BoxDecoration(
                            color: isHover || isClick || widget.currentTab == 0 ? Palette.buttonColor : Color(0xff707070),
                            borderRadius: BorderRadius.circular(isHover || isClick || widget.currentTab == 0 ? 16 : 40)
                          ),
                          child: Center(
                            child: SvgPicture.asset('assets/icons/comment.svg')
                          ),
                        ),
                      ),
                    ),
                ),
                checkDirectStatus() ? Container() : Positioned(
                  right: 1, top: 34,
                  child: Container(
                    height: 16, width: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: Color(0xff1E1E1E)
                    ),
                  )
                ),
                checkDirectStatus() ? Container () : Positioned(
                  right: 3, top: 36,
                  child: Container(
                    height: 12, width: 12,
                      decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: EdgeInsets.all(1),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: Colors.red
                      ),
                    ),
                  )
                  // child: IconBadge()
                ),
                if (Provider.of<RoomsModel>(context, listen: true).directHasRoomActive && widget.currentTab != 0) Positioned(
                  right: 0, top: 0,
                  child: Icon(PhosphorIcons.videoCameraFill, size: 17, color: Color(0xffFAAD14))
                )
              ],
            ),
          ),
        ),
        SizedBox(
          width: 4,
          height: 50,
        ),
      ],
    );
  }
}
