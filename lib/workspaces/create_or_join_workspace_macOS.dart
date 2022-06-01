import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_tooltip/simple_tooltip.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';

import 'create_or_join_dialog_macOS.dart';

class CreateOrJoinWorkspaceMacOs extends StatefulWidget {
  @override
  _CreateOrJoinWorkspaceMacOsState createState() =>
      _CreateOrJoinWorkspaceMacOsState();
}

class _CreateOrJoinWorkspaceMacOsState extends State<CreateOrJoinWorkspaceMacOs> {
  bool isHover = false;
  bool isCreate = false;
  bool isClick = false;
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<Auth>(context, listen: false).theme;
    final isDark  = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOutSine,
          margin: EdgeInsets.only(right: !isCreate && !isHover ? 4 : 0),
          width: isCreate || isHover ? 4 : 0,
          height: isCreate ? 40 : isHover ? 20 : 0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
            color: isHover || isCreate ? Color(0xfffafafa) : Color(0xff1f2933)
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
          show: isHover,
          content: Material(child: Text("Create workspace"), color: Colors.transparent,),
          child: InkWell(
            onHover: (hover){
              setState(() {
                isHover = !isHover;
              });
            },
            onTap: () {},
            child: GestureDetector(
              onTapDown: (_){
                setState(() {
                  isClick = true;
                });
              },
              onTapUp: (_) async{
                Future.delayed(Duration(milliseconds: 25), (){
                  setState(() {
                    isClick = false;
                  });
                });
                isCreate = true;
                final act = ShowDialog(theme: theme);
                await showGeneralDialog(
                  context: context,
                  barrierLabel: '',
                  barrierColor: Colors.black.withOpacity(0.5),
                  transitionBuilder: (context, a1, a2, widget) {
                    final curvedValue = Curves.easeOutBack.transform(a1.value) -   1.0;
                    return Transform(
                      transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
                      child: Opacity(
                        opacity: a1.value,
                        child: widget
                      ),
                    );
                  }, 
                barrierDismissible: true, 
                pageBuilder: (BuildContext context, ani1, ani2) => act).then((value) => isCreate = false);
              },
              child: AnimatedContainer(
                margin: isClick ? EdgeInsets.only(top: 2) : EdgeInsets.zero,
                duration: Duration(milliseconds: isHover ? 250 : 100),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isCreate || isHover ? 16 : 40),
                  color: Palette.backgroundRightSiderDark
                ),
                curve: isCreate || isHover ? Curves.easeOutCirc : Curves.easeInCirc,
                height: 48,
                width: 48,
                child: Center(
                  child: Icon(
                    Icons.add,
                    color: Color(0xff19DFCB),
                    // color: Utils.getPrimaryColor(),
                  )
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 4,
          height: 48,
        ),
      ],
    );
  }
}

class ShowDialog extends StatelessWidget {
  const ShowDialog({
    Key? key,
    @required this.theme,
  }) : super(key: key);

  final theme;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      content: Container(
        width: 380,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  S.of(context).createWorkspace,
                  style: TextStyle(
                    color: theme == ThemeType.DARK ? Colors.white70 : Color(0xff6B6B6B),
                    fontSize: 20,
                    fontWeight: FontWeight.w500
                  )
                ),
                Container(
                  padding: EdgeInsets.only(top: 16, bottom: 16),
                  child: Text(
                    S.of(context).descCreateWorkspace,
                    style: TextStyle(
                      color: theme == ThemeType.DARK ? Colors.white70 : Color(0xff6B6B6B),
                      fontSize: 16,
                      fontWeight: FontWeight.w100
                    ),
                    textAlign: TextAlign.center
                  ),
                )
              ],
            ),
            Container(
              height: 36,
              width: 320,
              child: TextButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Utils.getPrimaryColor())
                ),
                child: Text(
                  S.of(context).createWorkspace,
                  style: TextStyle(color: Colors.white)
                ),
                onPressed: () {
                  showBottomSheet(context, "create");
                }
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: 16, bottom: 16),
              child: Text(
                S.of(context).haveAnInviteAlready,
                style: TextStyle(
                  color: theme == ThemeType.DARK ? Colors.white70 : Color(0xff6B6B6B),
                  fontSize: 16,
                  fontWeight: FontWeight.w500
                )
              ),
            ),
            Container(
              height: 36,
              width: 320,
              child: TextButton(
                style: ButtonStyle(
                  backgroundColor: (
                    MaterialStateProperty.all(
                      theme == ThemeType.DARK ? Palette.defaultBackgroundDark : Palette.defaultBackgroundLight
                    )
                  ),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    side: BorderSide(color: theme == ThemeType.DARK ? Palette.defaultBackgroundDark : Utils.getPrimaryColor(), width: 2)
                  )),
                ),
                child: Text(
                  S.of(context).joinWorkspace,
                  style: TextStyle(
                    color: theme == ThemeType.DARK ? Palette.defaultTextDark : Utils.getPrimaryColor(), fontSize: 14
                  )
                ),
                onPressed: () {
                  showBottomSheet(context, "join");
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}

showBottomSheet(context, action) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return CreateOrJoinDialogMacOs(action: action);
    });
}
