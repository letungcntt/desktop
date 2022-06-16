import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/responsesizebar_widget.dart';
import 'package:workcake/components/thread_desktop.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/models/models.dart';

import 'message_item/attachments/attachments.dart';

class ImageReply extends StatefulWidget {

  ImageReply({
    Key? key,
    this.att,
    this.page,
    this.tags,
    this.onChangePage,
  }) : super(key: key);

  final att;
  final page;
  final tags;
  final onChangePage;

  @override
  _ImageReplyState createState() => _ImageReplyState();
}

class _ImageReplyState extends State<ImageReply> {
  bool isShowThread = false;

  @override
  void initState() {
    final messageImage = Provider.of<Messages>(context, listen: false).messageImage;
    final replyCount = messageImage['count'] ?? 0;

    isShowThread = replyCount > 0;
    super.initState();
  }

  onChangeIsShowThread(bool value) {
    setState(() {
      isShowThread = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final parentMessage = Provider.of<Messages>(context, listen: true).messageImage;
    final auth = Provider.of<Auth>(context, listen: true);

    return ContextMenuOverlay(
      cardBuilder: (_, children) => Container(
        decoration: BoxDecoration(
          color: auth.theme == ThemeType.DARK ? Color(0xff1E1E1E) : Colors.white,
          border: auth.theme != ThemeType.DARK ? Border.all(
            color: Color(0xffEAE8E8)
          ) : null,
          borderRadius: BorderRadius.all(Radius.circular(6))
        ),
        padding: EdgeInsets.all(6),
        child: Column(children: children)
      ),
      buttonBuilder: (_, config, [__]) => Container(
        padding: EdgeInsets.symmetric(vertical: 2),
        child: HoverItem(
          radius: 4.0,
          isRound: true,
          colorHover: auth.theme == ThemeType.DARK ? Color(0xff0050b3) : Color(0xff91d5ff),
          child: InkWell(
            onTap: config.onPressed,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.only(right: 8),
                    child: config.icon,
                  ),
                  Text(
                    config.label,
                    style: TextStyle(
                      color: auth.theme == ThemeType.DARK ? Color(0xffDBDBDB) : Color(0xff5E5E5E),
                      fontSize: 12
                    ),
                  )
                ],
              )
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              // padding: EdgeInsets.symmetric(horizontal: 8),
              child: Gallery(
                page: widget.page,
                tags: widget.tags,
                att: widget.att,
                isShowThread: isShowThread,
                onChangeIsShowThread: onChangeIsShowThread,
                isChildMessage: parentMessage['isChildMessage'],
                isConversation: Utils.checkedTypeEmpty(parentMessage["conversation_id"]),
              )
            )
          ),
          (isShowThread && parentMessage['id'] != null) ? ResponseSidebarItem(
            itemKey: 'rightSider',
            separateSide: 'left',
            canZero: false,
            constraints: BoxConstraints(minWidth: 300, maxWidth: 700),
            elevation: 1,
            deAttackable: false,
            child: Scaffold(
              body: ThreadDesktop(parentMessage: parentMessage, isMessageImage: true)
            )
          ) : Container()
        ],
      ),
    );
  }
}