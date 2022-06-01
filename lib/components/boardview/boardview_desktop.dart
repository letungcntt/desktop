import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
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

class BoardViewDesktop extends StatefulWidget {
  @override
  State<BoardViewDesktop> createState() => _BoardViewDesktopState();
}

class _BoardViewDesktopState extends State<BoardViewDesktop> {
  BoardViewController boardViewController = new BoardViewController();
  List<BoardListObject> listData = [];

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

  @override
  Widget build(BuildContext context) {
    List<BoardList> _lists = [];
    listData = getListData();

    for (int i = 0; i < listData.length; i++) {
      _lists.add(_createCardList(listData[i]) as BoardList);
    }

    return Container(
      padding: EdgeInsets.all(4),
      alignment: Alignment.centerLeft,
      height: MediaQuery.of(context).size.height - 180,
      child: Scrollbar(
        thickness: 2,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 260*listData.length.toDouble(),
                child: BoardView(
                  scrollbar: true,
                  width: 260,
                  lists: _lists,
                  boardViewController: boardViewController,
                  dragDelay: 0
                )
              ),
              ButtonAddCardList()
            ]
          )
        ),
      )
    );
  }

  ////////////////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////////////////////

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
      item: Card(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if(labels.length > 0) Container(
                margin: EdgeInsets.only(bottom: 8),
                child: Wrap(
                  children: labels.map<Widget>((label) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Color(int.parse("0xFF${label.colorHex}")),
                        borderRadius: BorderRadius.circular(5)
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: EdgeInsets.only(right: 4, top: 4),
                      height: 8,
                      width: 40
                    );
                  }).toList()
                )
              ),
              Container(
                padding: const EdgeInsets.only(bottom: 8, left: 1),
                child: Text(cardItem.title)
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: Wrap(
                      children: members.map((e) {
                        CardMember member = e;
                        return Container(margin: EdgeInsets.only(right: 4) ,child: CachedAvatar(member.avatarUrl, name: member.name, width: 24, height: 24, radius: 50));
                      }).toList(),
                    ),
                  ),
                  Container(
                    child: Wrap(
                      children: [
                        if (cardItem.commentsCount > 0) Row(
                          children: [
                            Icon(CupertinoIcons.bubble_right, size: 13, color: isDark ? Color(0xffB7B7B7) : Colors.black.withOpacity(0.45)),
                            SizedBox(width: 3),
                            Text(cardItem.commentsCount.toString(), style: TextStyle(fontSize: 13))
                          ]
                        ),
                        SizedBox(width: 10),
                        if (cardItem.tasks.length > 0) Row(
                          children: [
                            Icon(Icons.check_box_outlined, size: 14, color: isDark ? Color(0xffB7B7B7) : Colors.black.withOpacity(0.45)),
                            SizedBox(width: 3),
                            Text("${checkedTasks.length}/${tasks.length}", style: TextStyle(fontSize: 13))
                          ]
                        )
                      ]
                    )
                  )
                ]
              )
            ]
          )
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
      headerBackgroundColor: Color.fromARGB(255, 235, 236, 240),
      backgroundColor: Color.fromARGB(255, 235, 236, 240),
      header: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 5, left: 5, right: 5),
            child: selectedListToEdit == listCard.id ?  Container(
              height: 30,
              child: CupertinoTextField(
                padding: EdgeInsets.only(top: 1, bottom: 2, left: 5.5),
                autofocus: true,
                controller: controller,
                placeholder: S.current.enterListTitle,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.blueGrey[300]!)
                ),
                style: TextStyle(fontSize: 16, color: Colors.grey[700], fontFamily: 'Roboto', fontWeight: FontWeight.w400),
                onEditingComplete: () { 
                  setState(() { selectedListToEdit = null; });
                  if (controller.text.trim() != "" && controller.text != listCard.title) { 
                    onChangeListCardTitle(controller.text.trim(), listCard);
                  }
                }
              )
            ) : InkWell(
                onTap: () {
                  setState(() {
                    selectedListToEdit = listCard.id;
                  });
                },
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 6, left: 6, right: 6, bottom: 6),
                    width: 200,
                    constraints: BoxConstraints(maxWidth: 200),
                    child: Text(
                      listCard.title!,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700], fontFamily: 'Roboto', fontWeight: FontWeight.w400),
                    )
                  ),
                  Container(margin: EdgeInsets.only(top: 6), child: Icon(Icons.edit, size: 19, color: Colors.grey[600]))
                ]
              )
            )
          )
        )
      ],
      items: cards,
    );
  }
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
        showDialogCreateCardList(context);
      },
      child: Container(
        alignment: Alignment.centerLeft,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        width: 250,
        height: onAddCard ? 80 : 33,
        decoration: BoxDecoration(
          color: onAddCard ? Colors.white : Color.fromARGB(255, 235, 236, 240),
          borderRadius: BorderRadius.circular(2)
        ),
        child: !onAddCard ? Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.grey[700]),
            Text(S.current.addNewList, style: TextStyle(color: Colors.grey[800], fontSize: 15)),
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

  showDialogCreateCardList(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final token = Provider.of<Auth>(context, listen: false).token;
        final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
        final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
        final controller = TextEditingController();
        final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
        final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;

        return Dialog(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            width: 220,
            height: 156,
            child: Column(
              children: [
                Text(S.current.addNewList, style: TextStyle(fontSize: 16, color: isDark ? Colors.grey[300] : Colors.grey[800])),
                SizedBox(height: 16),
                CupertinoTextField(
                  autofocus: true,
                  style: TextStyle(color: Colors.grey[700]),
                  controller: controller,
                  placeholder: S.current.enterListTitle,
                  placeholderStyle: TextStyle(color: Colors.grey[800]),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[500]!),
                    color: isDark ? Colors.grey[300] : Colors.white
                  ),
                  onEditingComplete: () async {
                    if (controller.text.trim() == "") return;
                    await Provider.of<Boards>(context, listen: false).createNewCardList(token, currentWorkspace["id"], currentChannel["id"], selectedBoard["id"], controller.text);
                    Navigator.pop(context);
                  }
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      }, 
                      child: Text(S.current.cancel, style: TextStyle(color: Colors.grey[800]))
                    ),
                    SizedBox(width: 16),
                    TextButton(
                      onPressed: () async {
                        if (controller.text.trim() == "") return;
                        await Provider.of<Boards>(context, listen: false).createNewCardList(token, currentWorkspace["id"], currentChannel["id"], selectedBoard["id"], controller.text);
                        Navigator.pop(context);
                      }, 
                      child: Text(S.current.confirm, style: TextStyle(color: Colors.lightBlue))
                    )
                  ]
                )
              ]
            )
          )
        );
      }
    );
  }
}