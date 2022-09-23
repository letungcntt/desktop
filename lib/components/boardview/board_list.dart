
// ignore_for_file: must_call_super

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/workspaces/apps/zimbra/import_provider.dart';

import 'board_item.dart';
import 'boardview.dart';

typedef void OnDropList(int? listIndex,int? oldListIndex);
typedef void OnTapList(int? listIndex);
typedef void OnStartDragList(int? listIndex);

class BoardList extends StatefulWidget {
  final List<Widget>? header;
  final Widget? footer;
  final List<BoardItem>? items;
  final Color? backgroundColor;
  final Color? headerBackgroundColor;
  final BoardViewState? boardView;
  final OnDropList? onDropList;
  final OnTapList? onTapList;
  final OnStartDragList? onStartDragList;
  final bool draggable;
  final listId;
  final selectedListToAdd;
  final selectList;

  const BoardList({
    Key? key,
    this.header,
    this.items,
    this.footer,
    this.backgroundColor,
    this.headerBackgroundColor,
    this.boardView,
    this.draggable = true,
    this.index, this.onDropList, this.onTapList, this.onStartDragList,
    this.listId,
    this.selectedListToAdd,
    this.selectList
  }) : super(key: key);

  final int? index;

  @override
  State<StatefulWidget> createState() {
    return BoardListState();
  }
}

class BoardListState extends State<BoardList> with AutomaticKeepAliveClientMixin{
  List<BoardItemState> itemStates = [];
  ScrollController boardListController = new ScrollController();

  void onDropList(int? listIndex) {
    if(widget.onDropList != null){
      widget.onDropList!(listIndex,widget.boardView!.startListIndex);
    }
    widget.boardView!.draggedListIndex = null;
    if(widget.boardView!.mounted) {
      widget.boardView!.setState(() {

      });
    }
  }

  void _startDrag(Widget item, BuildContext context) {
    if (widget.boardView != null && widget.draggable) {
      if(widget.onStartDragList != null){
        widget.onStartDragList!(widget.index);
      }
      widget.boardView!.startListIndex = widget.index;
      widget.boardView!.height = context.size!.height;
      widget.boardView!.draggedListIndex = widget.index!;
      widget.boardView!.draggedItemIndex = null;
      widget.boardView!.draggedItem = item;
      widget.boardView!.onDropList = onDropList;
      widget.boardView!.run();
      if(widget.boardView!.mounted) {
        widget.boardView!.setState(() {});
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  createNewCard(title) async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;

    if (widget.index == null) return;
    if (title.trim() == "") return;

    var card = {
      "id": Utils.getRandomNumber(10),
      "title": title,
      "description": "",
      "checklists": [],
      "members": [],
      "labels": [],
      "priority": 5,
      "due_date": null,
      "attachments": []
    };
    Provider.of<Boards>(context, listen: false).createNewCard(token, selectedBoard["workspace_id"], selectedBoard["channel_id"], selectedBoard["id"], widget.listId, card);
    setState(() {
      controller.clear();
      widget.selectList(null);
    });
  }

  TextEditingController controller = TextEditingController();
  Timer? timer;
  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    List<Widget> listWidgets = [];

    if (widget.header != null) {
      listWidgets.add(GestureDetector(
        onTap: (){
          if(widget.onTapList != null){
            widget.onTapList!(widget.index);
          }
        },
        onTapDown: (otd) {
          if(widget.draggable) {
            RenderBox object = context.findRenderObject() as RenderBox;
            Offset pos = object.localToGlobal(Offset.zero);
            widget.boardView!.initialX = pos.dx;
            widget.boardView!.initialY = pos.dy;

            widget.boardView!.rightListX = pos.dx + object.size.width;
            widget.boardView!.leftListX = pos.dx;
          }
        },
        onTapCancel: () {},
        onPanDown: (_) {
          timer = Timer(Duration(milliseconds: 100), () {
            if(!widget.boardView!.widget.isSelecting && widget.draggable) {
              _startDrag(widget, context);
            }
          });
        },
        onPanStart: (e) {
          timer = Timer(Duration(milliseconds: 100), () {
            if(!widget.boardView!.widget.isSelecting && widget.draggable) {
              _startDrag(widget, context);
            }
          });
        },
        onPanCancel: () => timer?.cancel(),
        child: Container(
          color: widget.headerBackgroundColor,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.header!
          )
        )
      ));
    }
    if (widget.items != null) {
      listWidgets.add(Container(
        padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
        child: Wrap(
          children: [
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height - 250,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                controller: boardListController,
                itemCount: widget.items!.length,
                itemBuilder: (ctx, index) {
                  if (widget.items![index].boardList == null ||
                      widget.items![index].index != index ||
                      widget.items![index].boardList!.widget.index != widget.index
                      // || widget.items![index].boardList != this
                    ) {
                    widget.items![index] = new BoardItem(
                      boardList: this,
                      item: widget.items![index].item,
                      draggable: widget.items![index].draggable,
                      index: index,
                      onDropItem: widget.items![index].onDropItem,
                      onTapItem: widget.items![index].onTapItem,
                      onDragItem: widget.items![index].onDragItem,
                      onStartDragItem: widget.items![index].onStartDragItem,
                    );
                  }
                  if (widget.boardView!.draggedItemIndex == index &&
                      widget.boardView!.draggedListIndex == widget.index) {
                    return Opacity(
                      opacity: 0.0,
                      child: widget.items![index]
                    );
                  } else {
                    return widget.items![index];
                  }
                }
              )
            ),
            Container(
              margin: EdgeInsets.only(top: 12),
              width: double.infinity,
              child: widget.selectedListToAdd == widget.listId ? Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 34,
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      cursorColor: isDark ? Color(0xffffffff) : Palette.defaultTextLight,
                      style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Enter card title",
                        hintStyle: TextStyle(fontSize: 14),
                        contentPadding: EdgeInsets.only(left: 8, bottom: 2),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                          borderRadius: BorderRadius.all(Radius.circular(4))
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                          borderRadius: BorderRadius.all(Radius.circular(4))
                        )
                      ),
                      onEditingComplete: () {
                        if (controller.text.trim() != "") createNewCard(controller.text);
                      }
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          widget.selectList(null);
                          controller.clear();
                        },
                        child: Icon(Icons.close, color: Colors.grey[600], size: 20)
                      ),
                      SizedBox(width: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        color: isDark ? Color(0xffFAAD14) : Colors.lightBlue,
                        child: TextButton(
                          onPressed: () {
                            createNewCard(controller.text);
                          },
                          child: Text("Add card", style: TextStyle(color: Colors.white, fontSize: 12))
                        )
                      ),
                      SizedBox(width: 1)
                    ]
                  )
                ]
              ) : InkWell(
                onTap: () {
                  widget.selectList(widget.listId);
                },
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xff2E2E2E) : Colors.white,
                    borderRadius: BorderRadius.circular(4)
                  ),
                  child: Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(PhosphorIcons.plusCircle, size: 18, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                        SizedBox(width: 10),
                        Text("Add Card", style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontWeight: FontWeight.w400, fontSize: 13))
                      ]
                    )
                  )
                )
              )
            )
          ]
        )
        )
      );
    }

    if (widget.footer != null) {
      listWidgets.add(widget.footer!);
    }

    Color? backgroundColor = Color.fromARGB(255, 255, 255, 255);

    if (widget.backgroundColor != null) {
      backgroundColor = widget.backgroundColor;
    }
    if (widget.boardView!.listStates.length > widget.index!) {
      widget.boardView!.listStates.removeAt(widget.index!);
    }
    widget.boardView!.listStates.insert(widget.index!, this);

    return Container(
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4)
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: listWidgets
        )
      )
    );
  }
}
