import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/boardview/card_detail.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';

import 'BoardListObject.dart';
import 'CardItem.dart';
import 'board_item.dart';
import 'board_list.dart';
import 'boardview.dart';
import 'boardview_controller.dart';
import 'component/models.dart';
import 'create_card_modal.dart';

class BoardViewDesktop extends StatefulWidget {
  const BoardViewDesktop({
    Key? key,
    this.onCollapseListBoard,
    this.collapseListBoard
  }) : super(key: key);

  final onCollapseListBoard;
  final collapseListBoard;

  @override
  State<BoardViewDesktop> createState() => _BoardViewDesktopState();
}

class _BoardViewDesktopState extends State<BoardViewDesktop> {
  BoardViewController boardViewController = new BoardViewController();
  List<BoardListObject> listData = [];
  ScrollController scrollController = ScrollController();

  getListData() {
    List<BoardListObject> listData = [];
    final data = Provider.of<Boards>(context, listen: true).data;
    final selectedBoard = Provider.of<Boards>(context, listen: true).selectedBoard;
    final index = data.indexWhere((e) => e["id"] == selectedBoard["id"]);
    final listCards = index == -1 ? [] : data[index]["list_cards"];

    if (index == -1) return listData;

    for (var i = 0; i < listCards.length; i++) {
      final id = listCards[i]["id"];
      final workspaceId = listCards[i]["workspace_id"];
      final channelId = listCards[i]["channel_id"];
      final boardId = listCards[i]["board_id"];

      listData.add(
        BoardListObject(
          id: id,
          title: listCards[i]["title"], 
          workspaceId: workspaceId,
          channelId: channelId,
          boardId: boardId,
          cards: getListCard(listCards[i], i)
        )
      );
    }

    return listData;
  }

  getListCard(listCards, listIndex) {
    List<CardItem> cards = [];

    for (var i = 0; i < listCards["cards"].length; i++) {
      var e = i < listCards["cards"].length ? listCards["cards"][i] : {};
      if (e["is_archived"] == false) {
        cards.add(CardItem.cardFrom({
          "id": e["id"],
          "title": e["title"],
          "description": e["description"],
          "listIndex": listIndex, 
          "itemIndex": i,
          "workspaceId": listCards["workspace_id"],
          "channelId": listCards["channel_id"],
          "boardId": listCards["board_id"],
          "listCardId": listCards["id"],
          "members": e["assignees"],
          "labels": e["labels"],
          "checklists" : e["checklists"],
          "attachments" : e["attachments"],
          "commentsCount" : e["comments_count"],
          "tasks": e["tasks"],
          "isArchived": e["is_archived"],
          "priority": e["priority"],
          "dueDate": e["due_date"]
        }));
      }
    }

    return cards;
  }

  onArrangeCard(listIndex, itemIndex, oldListIndex, oldItemIndex, CardItem item) {
    if (listIndex == oldListIndex && itemIndex == oldItemIndex) return;

    final token = Provider.of<Auth>(context, listen: false).token;
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
    final listCard = selectedBoard["list_cards"];

    try {
      var item = listCard[oldListIndex]["cards"][oldItemIndex];
      listCard[oldListIndex]["cards"].removeAt(oldItemIndex);
      listCard[listIndex]["cards"].insert(itemIndex, item);
      item["old_list_cards_id"] = listCard[oldListIndex]["id"];
      item["list_cards_id"] = listCard[listIndex]["id"];
      
      if (listIndex != oldListIndex) {
        for (var i = 0; i < listCard[listIndex]["cards"].length; i++) {
          listCard[listIndex]["cards"][i]["order"] = i;
        }
        
        Provider.of<Boards>(context, listen: false).arrangeCard(token, selectedBoard["workspace_id"], selectedBoard["channel_id"], selectedBoard["id"], listCard[listIndex]["id"], itemIndex, oldItemIndex, item);
      } else {
        if (itemIndex != oldItemIndex) {
          for (var i = 0; i < listCard[listIndex]["cards"].length; i++) {
            listCard[listIndex]["cards"][i]["order"] = i;
          }

          Provider.of<Boards>(context, listen: false).arrangeCard(token, selectedBoard["workspace_id"], selectedBoard["channel_id"], selectedBoard["id"], listCard[listIndex]["id"], itemIndex, oldItemIndex, item);
        }
      }

    } catch (e) {
      print("onArrangeCard ${e.toString()}");
    }
  }

  onArrangeCardList(listIndex, oldListIndex) {
    if (listIndex != oldListIndex) {
      try {
        final token = Provider.of<Auth>(context, listen: false).token;
        final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
        final listCard = selectedBoard["list_cards"];
        var list = listCard[oldListIndex];
        listCard.removeAt(oldListIndex);
        listCard.insert(listIndex, list);
        List cardList = [];

        for (var i = 0; i < listCard.length; i++) {
          if (listCard[i]["order"] == null || listCard[i]["order"] != i) {
            listCard[i]["order"] = i;
            cardList.add(listCard[i]);
          }
        }

        if (cardList.length > 0) Provider.of<Boards>(context, listen: false).arrangeCardList(token, selectedBoard["workspace_id"], selectedBoard["channel_id"], selectedBoard["id"], cardList);
      } catch (e) {
        print("onArrangeCardList ${e.toString()}");
      }
    }
  }


  createNewCard(cardItem, title) {
    final token = Provider.of<Auth>(context, listen: false).token;
    if (title.trim() == "") return;
    Provider.of<Boards>(context, listen: false).createNewCard(token, cardItem.workspaceId, cardItem.channelId, cardItem.boardId, cardItem.listCardId, title);
  }

  showDialogCreateCardList(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final auth = Provider.of<Auth>(context, listen: false);
        final bool isDark = auth.theme == ThemeType.DARK;
        final String token = auth.token;
        final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
        final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
        final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
        final controller = TextEditingController();

        return Dialog(
          child: Container(
            width: 332,
            height: 184,
            child: Column(
              children: [
                Container(
                  width: 332,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  height: 40,
                  color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                  child: Text("Create new list", style: TextStyle(fontSize: 14))
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: TextFormField(
                    autofocus: true,
                    style: TextStyle(fontSize: 14, color: Palette.lightTextField),
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Name list",
                      contentPadding: EdgeInsets.only(left: 12),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                        borderRadius: BorderRadius.all(Radius.circular(4))
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                        borderRadius: BorderRadius.all(Radius.circular(4))
                      )
                    ),
                    cursorColor: isDark ? Colors.white : null,
                    onEditingComplete: () async {
                      if (controller.text.trim() == "") return;
                      await Provider.of<Boards>(context, listen: false).createNewCardList(token, currentWorkspace["id"], currentChannel["id"], selectedBoard["id"], controller.text);
                      Navigator.pop(context);
                    }
                  )
                ),
                Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), thickness: 1, height: 1),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 1,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          }, 
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xffFF7875)),
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: Center(child: Text(S.current.cancel, style: TextStyle(color: Color(0xffFF7875))))
                          )
                        ),
                      ),
                      SizedBox(width: 16),
                      Flexible(
                        flex: 1,
                        child: InkWell(
                          onTap: () async {
                            if (controller.text.trim() == "") return;
                            await Provider.of<Boards>(context, listen: false).createNewCardList(token, currentWorkspace["id"], currentChannel["id"], selectedBoard["id"], controller.text);
                            Navigator.pop(context);
                          }, 
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Utils.getPrimaryColor()
                            ),
                            child: Center(child: Text("Create", style: TextStyle(fontSize: 14, color: Palette.defaultTextDark)))
                          )
                        )
                      )
                    ]
                  )
                )
              ]
            )
          )
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    List<BoardList> _lists = [];
    listData = getListData();
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    for (int i = 0; i < listData.length; i++) {
      _lists.add(_createCardList(listData[i]) as BoardList);
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)
                )
              )
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                  children: [
                    InkWell(
                      onTap: () {
                        widget.onCollapseListBoard();
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 11, horizontal: 7.5),
                          child: Stack(
                            children: [
                              Icon(widget.collapseListBoard ? PhosphorIcons.caretRight : PhosphorIcons.caretLeft, size: 19, color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                              Positioned(
                                left: 6,
                                child: Icon(widget.collapseListBoard ? PhosphorIcons.caretRight : PhosphorIcons.caretLeft, size: 19, color: isDark ? Palette.calendulaGold : Palette.dayBlue)
                              )
                            ]
                          )
                        )
                      ),
                    ),
                    SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        showDialogCreateCardList(context);
                      },
                      child: Container(
                        width: 107,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(PhosphorIcons.plus, size: 17),
                              SizedBox(width: 10),
                              Text("New List", style: TextStyle(fontSize: 14))
                            ]
                          )
                        )
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: Center(
                        child: Icon(PhosphorIcons.magnifyingGlass, size: 17)
                      )
                    )
                  ]
                ),
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text("Label"),
                          Icon(Icons.arrow_drop_down)
                        ]
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text("Priority"),
                          Icon(Icons.arrow_drop_down)
                        ]
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text("Assignee"),
                          Icon(Icons.arrow_drop_down)
                        ]
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text("Sort"),
                          Icon(Icons.arrow_drop_down)
                        ]
                      )
                    )
                  ]
                )
              ]
            )
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            alignment: Alignment.centerLeft,
            height: MediaQuery.of(context).size.height - 110,
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              thickness: 6,
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.only(bottom: 20),
                      width: 260*listData.length.toDouble(),
                      child: BoardView(
                        scrollbar: true,
                        width: 260,
                        lists: _lists,
                        boardViewController: boardViewController,
                        dragDelay: 0
                      )
                    ),
                    // ButtonAddCardList()
                  ]
                )
              )
            )
          )
        ]
      )
    );
  }

  ////////////////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////////////////////
  
  getPriority(priority) {
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    Widget icon = priority == 1 ? Icon(PhosphorIcons.fire, color: Color(0xffFF7875), size: 19) 
      : priority == 2 ? 
        Container(
          height: 28,
          child: Stack(children: [
            Positioned(child: Icon(PhosphorIcons.caretUpThin, size: 18.5, color: Color(0xffFAAD14))),
            Positioned(top: 4, child: Icon(PhosphorIcons.caretUpThin, size: 18.5, color: Color(0xffFAAD14))),
            Positioned(top: 8, child: Icon(PhosphorIcons.caretUpThin, size: 18.5, color: Color(0xffFAAD14)))
          ]),
        ) 
      : priority == 3 ? 
        Container(
          height: 22,
          child: Stack(children: [
            Positioned(child: Icon(PhosphorIcons.caretUpThin, size: 18.5, color: Color(0xff27AE60))),
            Positioned(top: 4, child: Icon(PhosphorIcons.caretUpThin, size: 18.5, color: Color(0xff27AE60)))
          ]),
        ) 
      : priority == 4 ? 
        Icon(PhosphorIcons.caretUpThin, size: 18.5, color: Color(0xff69C0FF))
      : Icon(PhosphorIcons.minus, size: 19);

    Widget text = Text(
      priority == 1 ? "Urgent" : priority == 2 ? 'High' : priority == 3 ? 'Medium' : priority == 4 ? 'Low' : 'None',
      style: TextStyle(
        color: priority == 1
        ? Color(0xffFF7875)
        : priority == 2
          ? Palette.calendulaGold
          : priority == 3
            ? Color(0xff27AE60)
            : priority == 4
              ? Color(0xff69C0FF)
              : (isDark ? Palette.defaultTextDark : Palette.defaultTextLight)
      )
    );

    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
      icon,
      SizedBox(width: 8),
      text
    ]);
  }

  Widget buildCardItem(CardItem cardItem) {
    final channelMember = Provider.of<Channels>(context, listen: true).channelMember;
    final selectedBoard = Provider.of<Boards>(context, listen: true).selectedBoard;
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    
    List labels = cardItem.labels.map((e) {
      var index = selectedBoard["labels"].indexWhere((ele) => ele["id"] == e);
      if (index == -1) return null;
      var item = selectedBoard["labels"][index];
      return Label(colorHex: item["color_hex"], title: item["name"], id: item["id"].toString());
    }).toList().where((e) => e != null).toList();

    List members = cardItem.members.map((e) {
      var index = channelMember.indexWhere((ele) => ele["id"] == e);
      if (index == -1) return null;
      var mem = channelMember[index];
      return CardMember(name: mem["full_name"], avatarUrl: mem["avatar_url"], id: mem["id"]);
    }).toList().where((e) => e != null).toList();

    List tasks = cardItem.tasks;
    List checkedTasks = tasks.where((e) => e["is_checked"]).toList();

    return BoardItem(
      onStartDragItem: (int? listIndex, int? itemIndex, BoardItemState? state) {},
      onDropItem: (int? listIndex, int? itemIndex, int? oldListIndex, int? oldItemIndex, BoardItemState? state) {
        var item = listData[oldListIndex!].cards![oldItemIndex!];
        listData[oldListIndex].cards!.removeAt(oldItemIndex);
        listData[listIndex!].cards!.insert(itemIndex!, item);
        onArrangeCard(listIndex, itemIndex, oldListIndex, oldItemIndex, item);
      },
      onTapItem: (int? listIndex, int? itemIndex, BoardItemState? state) async {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              child: CardDetail(card: cardItem)
            );
          }
        ).then((value) {
          Provider.of<Boards>(context, listen: false).onSelectCard(null);
        });
      },
      item: Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xff3D3D3D) : Colors.white,
          borderRadius: BorderRadius.circular(4)
        ),
        margin: EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 8),
              height: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      getPriority(cardItem.priority),
                    ]
                  ),
                  ShowMoreCard(context: context)
                ]
              )
            ),
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(cardItem.title, style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),)
            ),
            if(labels.length > 0) Container(
              margin: EdgeInsets.only(bottom: 4),
              child: Wrap(
                children: labels.map<Widget>((label) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Color(int.parse("0xFF${label.colorHex}")),
                      borderRadius: BorderRadius.circular(3)
                    ),
                    margin: EdgeInsets.only(right: 8, top: 4),
                    height: 6,
                    width: 32
                  );
                }).toList()
              )
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: Wrap(
                      children: [
                        if (cardItem.commentsCount > 0) Row(
                          children: [
                            Icon(PhosphorIcons.chatCircleDots, size: 13, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282)),
                            SizedBox(width: 3),
                            Text(cardItem.commentsCount.toString(), style: TextStyle(fontSize: 12, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282))),
                            SizedBox(width: 10)
                          ]
                        ),
                        if (cardItem.tasks.length > 0) Row(
                          children: [
                            Icon(Icons.check_box_outlined, size: 14, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282)),
                            SizedBox(width: 3),
                            Text("${checkedTasks.length}/${tasks.length}", style: TextStyle(fontSize: 12, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282)))
                          ]
                        )
                      ]
                    )
                  ),
                  Container(
                    child: Wrap(
                      children: members.map((e) {
                        CardMember member = e;
                        return Container(margin: EdgeInsets.only(right: 4) ,child: CachedAvatar(member.avatarUrl, name: member.name, width: 24, height: 24, radius: 50));
                      }).toList(),
                    )
                  )
                ]
              ),
            )
          ]
        )
      )
    );
  }

  var selectedListToEdit;

  onChangeListCardTitle(title, listCard) {
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
    final listCardIndex = selectedBoard["list_cards"].indexWhere((e) => e["id"] == listCard.id);
    if (listCardIndex == -1) return;
    selectedBoard["list_cards"][listCardIndex]["title"] = title;
    final token = Provider.of<Auth>(context, listen: false).token;
    Provider.of<Boards>(context, listen: false).changeListCardTitle(token, listCard.workspaceId, listCard.channelId, listCard.boardId, listCard.id, title);
  }

  Widget _createCardList(BoardListObject listCard) {
    final controller = TextEditingController(text: listCard.title ?? "");
    List<BoardItem> cards = [];
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    for (int i = 0; i < listCard.cards!.length; i++) {
      cards.insert(i, buildCardItem(listCard.cards![i]) as BoardItem);
    }

    return BoardList(
      onStartDragList: (int? listIndex) {

      },
      onTapList: (int? listIndex) async {

      },
      onDropList: (int? listIndex, int? oldListIndex) {
        var list = listData[oldListIndex!];
        listData.removeAt(oldListIndex);
        listData.insert(listIndex!, list);
        onArrangeCardList(listIndex, oldListIndex);
      },
      backgroundColor: isDark ? Color(0xff262626) : Color(0xffDBDBDB),
      header: [
        selectedListToEdit == listCard.id ? Container(
          width: 224,
          height: 40,
          padding: EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            padding: EdgeInsets.only(left: 1, bottom: 4),
            autofocus: true,
            controller: controller,
            placeholder: S.current.enterListTitle,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.transparent)
            ),
            style: TextStyle(fontSize: 14, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
            onEditingComplete: () { 
              setState(() { selectedListToEdit = null; });
              if (controller.text.trim() != "" && controller.text != listCard.title) { 
                onChangeListCardTitle(controller.text.trim(), listCard);
              }
            }
          ),
        ) : InkWell(
          onTap: () {
            setState(() {
              selectedListToEdit = listCard.id;
            });
          },
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4)
            ),
            padding: const EdgeInsets.only(top: 10, left: 12, right: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 192,
                  child: Text(
                    listCard.title!,
                    style: TextStyle(fontSize: 14, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight)
                  )
                ),
                Wrap(
                  children: [
                    InkWell(
                      onTap: () {
                        showDialogCreateCard(context, listCard.id);
                      },
                      child: Container(
                        height: 28,
                        width: 28,
                        child: Icon(PhosphorIcons.plus, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, size: 18)
                      )
                    ),
                    // Container(
                    //   height: 24,
                    //   width: 24,
                    //   child: Icon(Icons.more_horiz, color: Color(0xffDBDBDB), size: 18)
                    // )
                  ]
                )
              ]
            ),
          )
        )
      ],
      items: cards,
    );
  }
}

class ShowMoreCard extends StatefulWidget {
  const ShowMoreCard({
    Key? key,
    required this.context,
  }) : super(key: key);

  final BuildContext context;

  @override
  State<ShowMoreCard> createState() => _ShowMoreCardState();
}

class _ShowMoreCardState extends State<ShowMoreCard> {
  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return InkWell(
      onTap: () {
        showPopover(
          backgroundColor: isDark ? Color(0xff4C4C4C) : Colors.white,
          radius: 4, context: context,
          transitionDuration: const Duration(milliseconds: 50),
          direction: PopoverDirection.bottom,
          barrierColor: Colors.transparent,
          width: 148, height: 89,
          arrowHeight: 0, arrowWidth: 0,
          bodyBuilder: (BuildContext context) {  
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xffA6A6A6)),
                borderRadius: BorderRadius.circular(4)
              ),
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 43,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.archive, size: 18),
                        SizedBox(width: 8),
                        Text("Archived Card", style: TextStyle(fontSize: 14))
                      ]
                    )
                  ),
                  Divider(color: Color(0xffA6A6A6), thickness: 0.5, height: 0.5),
                  Container(
                    height: 43,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.copy, size: 18),
                        SizedBox(width: 8),
                        Text("Duplicated", style: TextStyle(fontSize: 14))
                      ]
                    )
                  ),
                  // Divider(color: Color(0xffA6A6A6), thickness: 0.5, height: 0.5),
                  // Container(
                  //   height: 43,
                  //   padding: EdgeInsets.symmetric(horizontal: 16),
                  //   child: Row(
                  //     children: [
                  //       Icon(PhosphorIcons.trashSimple, size: 18),
                  //       SizedBox(width: 8),
                  //       Text("Delete Card", style: TextStyle(fontSize: 14))
                  //     ]
                  //   )
                  // ),
                ]
              )
            );
          }
        );
      },
      child: Container(
        height: 22,
        width: 22,
        padding: EdgeInsets.only(bottom: 6),
        child: Center(child: Text("...", style: TextStyle(letterSpacing: 2, fontSize: 16)))
      ),
    );
  }
}

showDialogCreateCard(context, listCardId) {
  showDialog(context: context, builder: (BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(0),
      child: CreateCard(listCardId: listCardId)
    );
  });
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

class ButtonAddCardList extends StatefulWidget {
  const ButtonAddCardList({
    Key? key,
  }) : super(key: key);

  @override
  State<ButtonAddCardList> createState() => _ButtonAddCardListState();
}

class _ButtonAddCardListState extends State<ButtonAddCardList> {
  bool onAddCard = false;
  final controller = TextEditingController();

  createNewCardList(token, workspaceId, channelId, boardId, title) async {
    if (title.trim() == "") return;
    await Provider.of<Boards>(context, listen: false).createNewCardList(token, workspaceId, channelId, boardId, title);
    controller.clear();
    onAddCard = false;
  }

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<Auth>(context, listen: true).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: true).currentChannel;
    final selectedBoard = Provider.of<Boards>(context, listen: true).selectedBoard;
    final data = Provider.of<Boards>(context, listen: true).data;

    return data.length == 0 ? Container() : InkWell(
      onTap: () { 
        // showDialogCreateCardList(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        margin: EdgeInsets.symmetric(vertical: 0, horizontal: 2),
        width: 224,
        height: onAddCard ? 80 : 52,
        decoration: BoxDecoration(
          color: onAddCard ? Colors.white : Color(0xff2E2E2E),
          borderRadius: BorderRadius.circular(4)
        ),
        child: !onAddCard ? Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.add),
            Text(S.current.addNewList, style: TextStyle(fontSize: 14)),
          ],
        ) : Container(
          padding: EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoTextField(
                padding: EdgeInsets.all(4),
                autofocus: true,
                controller: controller,
                placeholder: S.current.enterListTitle,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.blueGrey[300]!)
                )
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    color: Colors.lightBlue,
                    child: TextButton(
                      onPressed: (){
                        createNewCardList(token, currentWorkspace["id"], currentChannel["id"], selectedBoard["id"], controller.text);
                      }, 
                      child: Text(S.current.addList, style: TextStyle(color: Colors.white))
                    ),
                  ),
                  SizedBox(width: 12),
                  InkWell(
                    onTap: () {onAddCard = false;},
                    child: Icon(Icons.close, color: Colors.grey[600], size: 20)
                  )
                ]
              )
            ]
          )
        )
      ),
    );
  }
}