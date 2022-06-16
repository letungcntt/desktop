
// ignore_for_file: must_call_super

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/models/models.dart';

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

    final listCardId = selectedBoard["list_cards"][widget.index]["id"];
    final index = selectedBoard["list_cards"][widget.index]["cards"].indexWhere((e) => e["title"].trim() == title.trim());

    if (index != -1) return;
    
    if (title.trim() == "") return;

    await Provider.of<Boards>(context, listen: false).createNewCard(token, selectedBoard["workspace_id"], selectedBoard["channel_id"], selectedBoard["id"], listCardId, title);
    setState(() {
      controller.clear();
      onAddCard = false;
    });
  }

  bool onAddCard = false;
  TextEditingController controller = TextEditingController();
  Timer? timer;
  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    // final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
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
            new ListView.builder(
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
                    child: widget.items![index],
                  );
                } else {
                  return widget.items![index];
                }
              },
            ),
            // Container(
            //   width: double.infinity,
            //   decoration: BoxDecoration(
            //     color: isDark ? Colors.grey[800] : Colors.white,
            //     borderRadius: BorderRadius.circular(3)
            //   ),
            //   child: onAddCard ? Column(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       CupertinoTextField(
            //         padding: EdgeInsets.all(4),
            //         controller: controller,
            //         autofocus: true,
            //         placeholder: "Enter card title",
            //         decoration: BoxDecoration(
            //           color: Colors.white,
            //           borderRadius: BorderRadius.circular(2),
            //           border: Border.all(color: Colors.blueGrey[300]!)
            //         ),
            //         onEditingComplete: () {
            //           if (controller.text.trim() != "") createNewCard(controller.text);
            //         }
            //       ),
            //       SizedBox(height: 8),
            //       Row(
            //         mainAxisAlignment: MainAxisAlignment.start,
            //         crossAxisAlignment: CrossAxisAlignment.center,
            //         children: [
            //           Container(
            //             color: Colors.lightBlue,
            //             child: TextButton(
            //               onPressed: () {
            //                 createNewCard(controller.text);
            //               }, 
            //               child: Text("Add card", style: TextStyle(color: Colors.white))
            //             ),
            //           ),
            //           SizedBox(width: 12),
            //           InkWell(
            //             onTap: () {
            //               setState(() { onAddCard = false; });
            //             },
            //             child: Icon(Icons.close, color: Colors.grey[600], size: 20)
            //           )
            //         ]
            //       )
            //     ]
            //   ) : InkWell(
            //     onTap: () {
            //       setState(() { onAddCard = true; });
            //     }, 
            //     child: Container(
            //       height: 44,
            //       color: Color(0xff2E2E2E),
            //       child: Center(
            //         child: Wrap(
            //           crossAxisAlignment: WrapCrossAlignment.center,
            //           children: [
            //             Icon(PhosphorIcons.plusCircle, size: 18),
            //             SizedBox(width: 10),
            //             Text("Add Card", style: TextStyle(color: isDark ? Colors.white : Colors.grey[800], fontWeight: FontWeight.w400, fontSize: 13))
            //           ],
            //         ),
            //       )
            //     )
            //   )
            // )
          
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
