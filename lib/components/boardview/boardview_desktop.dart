import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:popover/popover.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/boardview/card_detail.dart';
import 'package:workcake/components/custom_confirm_dialog.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/providers/providers.dart';

import 'BoardListObject.dart';
import 'CardItem.dart';
import 'board_filter.dart';
import 'board_item.dart';
import 'board_list.dart';
import 'boardview.dart';
import 'boardview_controller.dart';
import 'component/list_archived.dart';
import 'component/models.dart';
import 'create_card_modal.dart';

class BoardViewDesktop extends StatefulWidget {
  const BoardViewDesktop({
		Key? key,
		this.onCollapseListBoard,
		this.collapseListBoard,
    required this.showArchiveBoard,
	}) : super(key: key);

  final onCollapseListBoard;
  final collapseListBoard;
  final bool showArchiveBoard;

  @override
  State<BoardViewDesktop> createState() => BoardViewDesktopState();
}

class BoardViewDesktopState extends State<BoardViewDesktop> {
  BoardViewController boardViewController = new BoardViewController();
  List<BoardListObject> listData = [];
  ScrollController scrollController = ScrollController();
  Map filters = {'noMember': false, 'members': [], 'labels': [], 'priority': null, 'text': "", 'dueDate': {}};
  String filterType = 'exact';
  String showArchive = '';
  TextEditingController searchArchiveController = TextEditingController();
  var cardToRename;
  TextEditingController renameCardController = TextEditingController();

  var debounce;
  var selectedListToAdd;

  selectList(value) {
    this.setState(() {
      selectedListToAdd = value;
    });
  }

  onChangeFilter(newFilters) {
    this.setState(() {
      filters = newFilters;
    });
  }

  onChangeFilterType(value) {
    this.setState(() {
      filterType = value;
    });
  }

  onPassFilter(CardItem card) {
    bool passAllFilter = true;
    bool passText = false;
    bool passNoMember = false;
    bool passMember = false;
    bool passLabel = false;
    bool passPriority = false;
    bool passDueDate = false;

    filters.forEach((key, value) {
      switch (key) {
        case "text":
          if (value.trim() != "") {
            if(!Utils.unSignVietnamese(card.title.toLowerCase()).contains(value)
              && !card.title.toLowerCase().contains(value)
              && !card.description.toLowerCase().contains(value)
              && !Utils.unSignVietnamese(card.description.toLowerCase()).contains(value)) {
              passAllFilter = false;
            } else {
              passText = true;
            }
          }
          break;

        case "noMember":
          if (value) {
            if (card.members.length > 0) {
              passAllFilter = false;
            } else {
              passNoMember = true;
            }
          }
          break;

        case "members":
          for (var i = 0; i < value.length; i++) {
            if (card.members.contains(value[i]) == false) {
              passAllFilter = false;
            } else {
              passMember = true;
            }
          }
          break;

        case "labels":
					for (var i = 0; i < value.length; i++) {
            if (card.labels.contains(value[i]) == false) {
              passAllFilter = false;
            } else {
              passLabel = true;
            }
          }
          break;

				case "priority":
					if (value != null) {
						if (value == 5) {
							if (card.priority != 5 && card.priority != null) {
								passAllFilter = false;
							} else {
                passPriority = true;
              }
						} else {
							if (card.priority != value) {
								passAllFilter = false;
							} else {
                passPriority = true;
              }
						}
					}
					break;
        
        case "dueDate":
          bool passNoDueDate = true;
          bool passOverdue = true;
          bool passAfter = true;
          bool passBefore = true;


          if (value["type"] == "noDueDate") {
            if (card.dueDate != null) {
              passAllFilter = false;
              passNoDueDate = false;
            }
          } else {
            if (value["type"] == "overdue") {
              if (card.dueDate == null) {
                passAllFilter = false;
                passOverdue = false;
              } else {
                if (DateTime.now().compareTo(card.dueDate!) == -1) {
                  passAllFilter = false;
                  passOverdue = false;
                }
              }
            }

            if (value["after"] != null) {
              if (card.dueDate == null) {
                passAllFilter = false;
              } else {
                if(card.dueDate!.compareTo(DateTime.parse(value["after"])) == -1) {
                  passAllFilter = false;
                  passAfter = false;
                }
              }
            }

            if (value["before"] != null) {
              if (card.dueDate == null) {
                passAllFilter = false;
              } else {
                if(card.dueDate!.compareTo(DateTime.parse(value["before"])) == 1) {
                  passAllFilter = false;
                  passBefore = false;
                }
              }
            }
            passDueDate = passAfter && passBefore && passNoDueDate && passOverdue;
          }
          break;

        default:
          break;
      }
    });

    if (filterType == "exact") {
  	  return passAllFilter;
    } else {
      return (passText || passPriority || passLabel || passMember || passNoMember || passDueDate);
    }
  }

  getListData() {
    List<BoardListObject> listData = [];
    final data = Provider.of<Boards>(context, listen: true).data;
    final selectedBoard = Provider.of<Boards>(context, listen: true).selectedBoard;
    final index = data.indexWhere((e) => e["id"] == selectedBoard["id"]);
    final listCards = index == -1 ? [] : data[index]["list_cards"];

    listCards.sort((a, b) => (selectedBoard["order"] ?? []).indexWhere((e) => e == a["id"]) > (selectedBoard["order"] ?? []).indexWhere((e) => e == b["id"]) ? 1 : -1);

    if (index == -1) return listData;

    for (var i = 0; i < listCards.length; i++) {
      BoardListObject board = BoardListObject(
        id: listCards[i]["id"],
        title: listCards[i]["title"],
        workspaceId: listCards[i]["workspace_id"],
        channelId: listCards[i]["channel_id"],
        boardId: listCards[i]["board_id"],
        cards: getListCard(listCards[i], i, false),
        isArchived: listCards[i]["is_archived"]
      );
      listData.add(board);
    }

    return listData;
  }

  getListCard(listCards, listIndex, isArchived) {
    List<CardItem> cards = [];
    
    if (listCards["sort_by"] == "newest") {
      listCards["cards"].sort((a, b) => DateTime.parse(a["inserted_at"]).compareTo(DateTime.parse(b["inserted_at"])));
    } else if (listCards["sort_by"] == "oldest") {
      listCards["cards"].sort((a, b) => -DateTime.parse(a["inserted_at"]).compareTo(DateTime.parse(b["inserted_at"])));
    } else {
      listCards["cards"].sort((a, b) => listCards["order"].indexOf(a["id"]) > listCards["order"].indexOf(b["id"]) ? 1 : -1);
    }

    for (var i = 0; i < listCards["cards"].length; i++) {
      var e = i < listCards["cards"].length ? listCards["cards"][i] : {};

      CardItem card = CardItem.cardFrom({
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
        "checklists": e["checklists"],
        "attachments": e["attachments"],
        "commentsCount": e["comments_count"],
        "attachmentsCount": e["attachments_count"],
        "tasks": e["tasks"],
        "isArchived": e["is_archived"],
        "priority": e["priority"],
        "dueDate": e["due_date"],
        "author": e["author_id"]
      });

      if (onPassFilter(card)) {
        cards.add(card);
      }
    }

    return cards;
  }

  onArrangeCard(listIndex, itemIndex, oldListIndex, oldItemIndex, CardItem item) {
    if (listIndex == oldListIndex && itemIndex == oldItemIndex) return;
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
    final listCard = selectedBoard["list_cards"].where((e) => e["is_archived"] == false).toList();

    try {
      final card = listCard[oldListIndex]["cards"][oldItemIndex];
      listCard[oldListIndex]["cards"].removeAt(oldItemIndex);
      listCard[listIndex]["cards"].insert(itemIndex, card);
      card["old_list_cards_id"] = listCard[oldListIndex]["id"];
      card["list_cards_id"] = listCard[listIndex]["id"];

      if (listIndex != oldListIndex) {
        updateOrder(listCard[listIndex], card);
        updateOrder(listCard[oldListIndex], card);
      } else {
        if (itemIndex != oldItemIndex) {
          updateOrder(listCard[listIndex], card);
        }
      }
    } catch (e) {
      print("onArrangeCard ${e.toString()}");
    }
  }

  updateOrder(listCard, card) {
    List listOrder = [];
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
    final token = Provider.of<Auth>(context, listen: false).token;
    final cards = listCard["cards"];
    for (var i = 0; i < cards.length; i++) {
      listOrder.add(cards[i]["id"]);
    }
    var updateListCard = {
      "id": listCard["id"],
      "order": listOrder
    };

    Provider.of<Boards>(context, listen: false).arrangeCard(token, selectedBoard["workspace_id"], selectedBoard["channel_id"], selectedBoard["id"], listCard["id"], updateListCard, card);
  }

  onArrangeCardList(listIndex, oldListIndex) {
    if (listIndex != oldListIndex) {
      try {
        final token = Provider.of<Auth>(context, listen: false).token;
        final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
        final listCard = selectedBoard["list_cards"].where((e) => e["is_archived"] == false).toList();
        var list = listCard[oldListIndex];
        listCard.removeAt(oldListIndex);
        listCard.insert(listIndex, list);
        List listOrder = [];

        for (var i = 0; i < listCard.length; i++) {
          listOrder.add(listCard[i]["id"]);
        }

        Provider.of<Boards>(context, listen: false).arrangeCardList(token, selectedBoard["workspace_id"], selectedBoard["channel_id"], selectedBoard["id"], listOrder);
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
                    style: TextStyle(fontSize: 14, color: isDark ? Palette.lightTextField : null),
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Name list",
                      contentPadding: EdgeInsets.only(left: 12),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                        borderRadius: BorderRadius.all(Radius.circular(4)
                      )),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? Palette.calendulaGold : Palette.dayBlue),
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
                Divider(
                  color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                  thickness: 1,
                  height: 1
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 1,
                        child: InkWell(
                          onTap: () { Navigator.pop(context); },
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xffFF7875)),
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: Center(
                              child: Text(S.current.cancel, style: TextStyle(color:Color(0xffFF7875)
                            )
                          )
                        ))),
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
                            child: Center(
                              child: Text("Create", style: TextStyle(fontSize: 14, color: Palette.defaultTextDark))
                            )
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

  getArchivedCard() {
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
    List archivedCards = Provider.of<Boards>(context, listen: false).archivedCards["${selectedBoard["id"]}"] ?? [];
    List<CardItem> archivedCard = [];

    for (var index = 0; index < archivedCards.length; index++) {
      var e = archivedCards[index];
      CardItem card = CardItem.cardFrom({
        "id": e["id"],
        "title": e["title"],
        "description": e["description"],
        "workspaceId": e["workspace_id"],
        "channelId": e["channel_id"],
        "boardId": e["board_id"],
        "listCardId": e["list_cards_id"],
        "members": e["assignees"],
        "labels": e["labels"],
        "checklists": e["checklists"],
        "attachments": e["attachments"],
        "commentsCount": e["comments_count"],
        "attachmentsCount": e["attachments_count"],
        "tasks": e["tasks"],
        "isArchived": e["is_archived"],
        "priority": e["priority"],
        "dueDate": e["due_date"],
        "author": e["author_id"]
      });
      archivedCard.add(card);
    }

    return archivedCard;
  }

  getArchivedLists() {
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
    List archivedLists = Provider.of<Boards>(context, listen: false).archivedLists["${selectedBoard["id"]}"] ?? [];
    return archivedLists;
  }

  onSwitchArchiveList(value) {
    this.setState(() {
      showArchive = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<BoardList> _lists = [];
    listData = getListData();
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    for (int i = 0; i < listData.length; i++) {
      _lists.add(_createCardList(listData[i]) as BoardList);
    }

    List<CardItem> archivedCards = showArchive == 'cards' ? getArchivedCard() : [];
    List archivedLists = showArchive == 'lists' ? getArchivedLists() : [];

    return Expanded(
      child: Container(
        height: MediaQuery.of(context).size.height - 38,
        child: Stack(
          children: [
            Column(
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
                                child: Stack(children: [
                                  Icon(
                                    widget.collapseListBoard ? PhosphorIcons.caretRight : PhosphorIcons.caretLeft,
                                    size: 19,
                                    color: isDark ? Palette.calendulaGold : Palette.dayBlue
                                  ),
                                  Positioned(
                                    left: 6,
                                    child: Icon(widget.collapseListBoard ? PhosphorIcons.caretRight : PhosphorIcons.caretLeft,
                                      size: 19,
                                      color: isDark? Palette.calendulaGold: Palette.dayBlue)
                                    )
                                  ]
                                )
                              )
                            )
                          ),
                          widget.showArchiveBoard ? Container() : InkWell(
                            onTap: () {
                              showDialogCreateCardList(context);
                            },
                            child: Container(
                              width: 107,
                              height: 40,
                              margin: EdgeInsets.only(left: 12),
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
                            )
                          )
                        ]
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          BoardFilter(filters: filters, onChangeFilter: onChangeFilter, filterType: filterType, onChangeFilterType: onChangeFilterType),
                          SizedBox(width: 16),
                          InkWell(
                            onTap: () {
                              this.setState(() {
                                showArchive = "cards";
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                              ),
                              child: Center(child: Text("Archived items"))
                            ),
                          )
                        ]
                      )
                    ]
                  )
                ),
                widget.showArchiveBoard ? ListArchived() : Container(
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
                            width: 260 * listData.length.toDouble(),
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
            ),
            if(showArchive != '')Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                color: isDark ? Color(0xff2E2E2E) : Colors.white,
                height: MediaQuery.of(context).size.height,
                width: 340,
                child: Column(
                  children: [
                    SizedBox(height: 38),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      height: 57,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                        )
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(width: 18),
                          Text("Archive", style: TextStyle(fontSize: 16)),
                          InkWell(
                            onTap: () {
                              this.setState(() {
                                showArchive = '';
                              });
                            },
                            child: Icon(PhosphorIcons.x, size: 20)
                          )
                        ]
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 180,
                            height: 36,
                            child: CupertinoTextField(
                              padding: EdgeInsets.only(left: 10, bottom: 3, right: 10),
                              autofocus: false,
                              onChanged: (value) {
                                if (debounce?.isActive ?? false) debounce.cancel();
                                debounce = Timer(const Duration(milliseconds: 200), () {
                                  this.setState(() {});
                                });
                              },
                              controller: searchArchiveController,
                              placeholder: "Search archive...",
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),)
                              ),
                              style: TextStyle(fontSize: 14, color: isDark ? Palette.defaultTextDark: Palette.defaultTextLight),
                            )
                          ),
                          SizedBox(width: 10),
                          InkWell(
                            onTap: () {
                              onSwitchArchiveList(showArchive == 'lists' ? 'cards' : 'lists');
                              searchArchiveController.clear();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? Color(0xff3D3D3D) : Colors.white,
                                borderRadius: BorderRadius.circular(4)
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              height: 36,
                              child: Center(child: Text(showArchive == 'lists' ? "Switch to cards" : "Switch to lists")),
                            )
                          )
                        ]
                      )
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: showArchive == "cards" ? Column(
                        children: archivedCards.map<Widget>((CardItem cardItem) {
                          bool onSearch = searchArchiveController.text.trim() != "" ?
                            Utils.unSignVietnamese(cardItem.title).contains(Utils.unSignVietnamese(searchArchiveController.text.trim())) : true;
                          return onSearch ? buildCardItem(cardItem, true) : Container();
                        }).toList()
                      ) : Column(
                        children: archivedLists.map<Widget>((list) {
                          bool onSearch = searchArchiveController.text.trim() != "" ?
                            Utils.unSignVietnamese(list["title"]).contains(Utils.unSignVietnamese(searchArchiveController.text.trim())) : true;
                          return !onSearch ? Container() : Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            width: 340,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB))
                              )
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 340 - 128 - 24,
                                  child: Text(list["title"], overflow: TextOverflow.ellipsis)
                                ),
                                InkWell(
                                  onTap: () {
                                    BoardListObject listCard = BoardListObject(
                                      id: list["id"],
                                      title: list["title"],
                                      workspaceId: list["workspace_id"],
                                      channelId: list["channel_id"],
                                      boardId: list["board_id"],
                                      isArchived: list["is_archived"]
                                    );
                                    onArchiveListCard(false, listCard);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    height: 32,
                                    width: 128,
                                    decoration: BoxDecoration(
                                      color: isDark ? Color(0xff3D3D3D) : Colors.white,
                                      borderRadius: BorderRadius.circular(4)
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(PhosphorIcons.arrowUUpLeft, size: 15),
                                          Text("Send to board")
                                        ]
                                      )
                                    )
                                  ),
                                )
                              ]
                            )
                          );
                        }).toList()
                      )
                    )
                  ]
                )
              )
            )
          ]
        )
      )
    );
  }

  ////////////////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////////////////////

  var hoveringCard;

  Widget buildCardItem(CardItem cardItem, isArchived) {
    final channelMember = Provider.of<Channels>(context, listen: false).channelMember;
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;

    List labels = cardItem.labels.map((e) {
      var index = selectedBoard["labels"].indexWhere((ele) => ele["id"] == e);
      if (index == -1) return null;
      var item = selectedBoard["labels"][index];
      return Label(
        colorHex: item["color_hex"],
        title: item["name"],
        id: item["id"].toString()
      );
    }).toList().where((e) => e != null).toList();

    List members = cardItem.members.map((e) {
      var index = channelMember.indexWhere((ele) => ele["id"] == e);
      if (index == -1) return null;
      var mem = channelMember[index];
      return CardMember(
        name: mem["full_name"],
        avatarUrl: mem["avatar_url"] ?? "",
        id: mem["id"]
      );
    }).toList().where((e) => e != null).toList();

    List tasks = cardItem.tasks;
    List checkedTasks = tasks.where((e) => e["is_checked"]).toList();

    return isArchived ? InkWell(
      onTap: () async {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(child: CardDetail(card: cardItem));
          }
        ).then((value) {
          Provider.of<Boards>(context, listen: false).onSelectCard(null);
        });
      },
      child: cardContainer(cardItem, isDark, labels, members, checkedTasks, tasks
    )) : BoardItem(
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
            return Dialog(child: CardDetail(card: cardItem));
          }
        ).then((value) {
          Provider.of<Boards>(context, listen: false).onSelectCard(null);
        });
      },
      item: cardContainer(cardItem, isDark, labels, members, checkedTasks, tasks)
    );
  }

  selectCardToRename(card) {
    this.setState(() {
      cardToRename = card != null ? card.id : null;
    });

    if (card != null) {
      renameCardController.text = card.title;
    }
  }

  onRenameCard(CardItem card, title) {
    final token = Provider.of<Auth>(context, listen: false).token;
    var payload = {
      "id": card.id,
      "description": card.description,
      "title": title,
      "is_archived": card.isArchived,
      "due_date": card.dueDate != null ? card.dueDate!.toUtc().millisecondsSinceEpoch~/1000 + 86400 : null,
      "priority": card.priority
    };
    this.setState(() {cardToRename = null;});
    Provider.of<Boards>(context, listen: false).updateCardTitleOrDescription(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card, "cardInfo", payload);
    renameCardController.clear();
  }

  MouseRegion cardContainer(CardItem cardItem, bool isDark, List<dynamic> labels, List<dynamic> members, List<dynamic> checkedTasks, List<dynamic> tasks) {
    return MouseRegion(
      onEnter: (value) {
        this.setState(() {
          hoveringCard = cardItem.id;
        });
      },
      onExit: (value) {this.setState(() {
        hoveringCard = null;
      });},
      cursor: SystemMouseCursors.click,
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          color: isDark ? Color(0xff3D3D3D) : cardItem.isArchived ? Color(0xfff3f3f3) : Colors.white,
          borderRadius: BorderRadius.circular(4)
        ),
        margin: EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if(cardItem.priority != null && cardItem.priority != 5) Container(
            margin: EdgeInsets.only(bottom: 14),
            height: 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                getPriority(cardItem.priority, isDark),
                ShowMoreCard(context: context, onHover: hoveringCard == cardItem.id, card: cardItem, selectCardToRename: selectCardToRename)
              ]
            )
          ),
          cardToRename == cardItem.id ?  Container(
            height: 32,
            child: Focus(
              onFocusChange: (focus) {
                if (!focus) {
                  this.setState(() {
                    cardToRename = null;
                  });
                }
              },
              child: TextField(
                autofocus: true,
                controller: renameCardController,
                cursorColor: isDark ? Color(0xffffffff) : Palette.defaultTextLight,
                style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Enter card title",
                  hintStyle: TextStyle(fontSize: 14),
                  contentPadding: EdgeInsets.only(left: 8, right: 8),
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
                  if (renameCardController.text.trim() != "") {
                    onRenameCard(cardItem, renameCardController.text.trim());
                  }
                }
              )
            )
          ) : Container(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.only(top: 5),
                  width: 172,
                  child: Text(
                    cardItem.title,
                    style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                  )
                ),
                if(cardItem.priority == null || cardItem.priority == 5) ShowMoreCard(context: context, onHover: hoveringCard == cardItem.id, card: cardItem, selectCardToRename: selectCardToRename)
              ]
            )
          ),
          if (labels.length > 0) Container(
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
                }
              ).toList()
            )
          ),
          if (cardItem.commentsCount > 0 ||
              cardItem.tasks.length > 0 ||
              members.length > 0 ||
              cardItem.attachmentsCount > 0
            ) Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: Wrap(children: [
                    if (cardItem.commentsCount > 0)
                      Row(children: [
                        Icon(PhosphorIcons.chatCircleDots,
                            size: 13,
                            color: isDark
                                ? Color(0xffA6A6A6)
                                : Color(0xff828282)),
                        SizedBox(width: 3),
                        Text(cardItem.commentsCount.toString(),
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Color(0xffA6A6A6)
                                    : Color(0xff828282))),
                        SizedBox(width: 10)
                      ]),
                    if (cardItem.tasks.length > 0)
                      Row(children: [
                        Icon(Icons.check_box_outlined,
                            size: 14,
                            color: isDark
                                ? Color(0xffA6A6A6)
                                : Color(0xff828282)),
                        SizedBox(width: 3),
                        Text("${checkedTasks.length}/${tasks.length}",
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Color(0xffA6A6A6)
                                    : Color(0xff828282))),
                        SizedBox(width: 10)
                      ]),
                    if (cardItem.attachmentsCount > 0)
                      Row(children: [
                        Icon(PhosphorIcons.paperclip,
                            size: 14,
                            color: isDark
                                ? Color(0xffA6A6A6)
                                : Color(0xff828282)),
                        SizedBox(width: 3),
                        Text("${cardItem.attachmentsCount}",
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Color(0xffA6A6A6)
                                    : Color(0xff828282)))
                      ])
                  ])),
                  Container(
                    height: 24,
                    width: 68,
                    child: Stack(
                      children: members.map<Widget>((e) {
                        CardMember member = e;
                        double index = members.indexOf(e).toDouble();

                        return index < 3 || (index == 3 && members.length == 4 ) ? Positioned(
                          top: 0,
                          right: 12*index,
                          child: CachedAvatar(member.avatarUrl, name: member.name, width: 24, height: 24, radius: 50)
                        ) : index == 3 ? Positioned(
                          top: 0,
                          right: 12*index,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xff2E2E2E),
                              borderRadius: BorderRadius.circular(50)
                            ),
                            width: 24,
                            height: 24,
                            child: Center(child: Text("+ ${members.length - 3}", style: TextStyle(fontSize: 12)))
                          )
                        ) : Container();
                      }).toList()
                    )
                  )
                ]
              )
            )
          ]
        )
      ),
    );
  }

  var selectedListToEdit;
  onSelectedListToEdit(value, text) {
    this.setState(() {
      selectedListToEdit = value;
    });
    controller.value = controller.value.copyWith(
      text: text ?? "",
      selection: TextSelection.collapsed(
        offset: (text ?? "").length,
      ),
    );
  }
  final controller = TextEditingController();

  onChangeListCardTitle(title, listCard) {
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
    final listCardIndex = selectedBoard["list_cards"].indexWhere((e) => e["id"] == listCard.id);
    if (listCardIndex == -1) return;
    listCard.title = title;
    selectedBoard["list_cards"][listCardIndex]["title"] = title;
    final token = Provider.of<Auth>(context, listen: false).token;
    Provider.of<Boards>(context, listen: false).changeListCardTitle(token, listCard.workspaceId, listCard.channelId, listCard.boardId, listCard.id, title, false);
  }

  onArchiveListCard(value, listCard) {
    final token = Provider.of<Auth>(context, listen: false).token;
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
    if (value) {
      final listCardIndex = selectedBoard["list_cards"].indexWhere((e) => e["id"] == listCard.id);
      if (listCardIndex == -1) return;
      this.setState(() {
        listCard.isArchived = value;
        selectedBoard["list_cards"][listCardIndex]["isArchived"] = value;
      });
    }

    Provider.of<Boards>(context, listen: false).changeListCardTitle(token, listCard.workspaceId, listCard.channelId, listCard.boardId, listCard.id, listCard.title, value);
  }

  onChangeSortType(value, listCard) {
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
    final listCardIndex = selectedBoard["list_cards"].indexWhere((e) => e["id"] == listCard.id);
    if (listCardIndex == -1) return;
    this.setState(() {
      selectedBoard["list_cards"][listCardIndex]["sort_by"] = value;
    });
    Navigator.pop(context);
  }

  Widget _createCardList(BoardListObject listCard) {
    List<BoardItem> cards = [];
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    for (int i = 0; i < listCard.cards!.length; i++) {
      cards.insert(i, buildCardItem(listCard.cards![i], false) as BoardItem);
    }

    return BoardList(
      listId: listCard.id,
      selectedListToAdd: selectedListToAdd,
      selectList: selectList,
      onStartDragList: (int? listIndex) {},
      onTapList: (int? listIndex) async {},
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
            style: TextStyle(fontSize: 14, color: isDark ? Palette.defaultTextDark: Palette.defaultTextLight),
            onEditingComplete: () {
              if (controller.text.trim() != "" && controller.text != listCard.title) {
                onChangeListCardTitle(controller.text.trim(), listCard);
              }
              onSelectedListToEdit(null, listCard.title);
            }
          )
        ) : InkWell(
          onTap: () {
            onSelectedListToEdit(listCard.id, listCard.title);
          },
          child: Container(
            height: 40,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
            padding: const EdgeInsets.only(top: 10, left: 12, right: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 192,
                  child: Text(
                    listCard.title!,
                    style: TextStyle(fontSize: 14, color: isDark ? Palette.defaultTextDark: Palette.defaultTextLight)
                  )
                ),
                ListCardActions(listCard: listCard, onArchiveListCard: onArchiveListCard, onChangeSortType: onChangeSortType)
              ]
            )
          )
        )
      ],
      items: cards
    );
  }
}

class ListCardActions extends StatefulWidget {
  ListCardActions({
    this.listCard,
    this.onArchiveListCard,
    this.onChangeSortType,
    Key? key
  }) : super(key: key);

  final listCard;
  final onArchiveListCard;
  final onChangeSortType;

  @override
  State<ListCardActions> createState() => _ListCardActionsState();
}

class _ListCardActionsState extends State<ListCardActions> {
  bool onSort = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return InkWell(
      onTap: () {
        showPopover(
          backgroundColor: isDark ? Color(0xff4C4C4C) : Colors.white,
          radius: 4,
          context: context,
          transitionDuration: const Duration(milliseconds: 30),
          direction: PopoverDirection.bottom,
          barrierColor: Colors.transparent,
          width: 264,
          height: 176,
          arrowHeight: 0,
          arrowWidth: 0,
          bodyBuilder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: Center(child: onSort ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  onSort = false;  
                                });
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                child: Icon(PhosphorIcons.caretLeft, size: 18)
                              )
                            ),
                            Text("Sort list"),
                            Container(width: 44)
                          ]
                        ) : Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Text("List actions"))
                        )
                      ),
                      Divider(color: Color(0xffA6A6A6), thickness: 0.5, height: 0.5),
                      onSort ? Column(
                        children: [
                          InkWell(
                            onTap: () {
                              widget.onChangeSortType("newest", widget.listCard);
                            },
                            child: Container(
                              width: 264,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              height: 43, child: Text("Date created (newest first)")
                            )
                          ),
                          InkWell(
                            onTap: () {
                              widget.onChangeSortType("oldest", widget.listCard);
                            },
                            child: Container(
                              width: 264,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              height: 43, child: Text("Date created (oldest first)")
                            )
                          )
                        ]
                      ) : Column(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              showDialogCreateCard(context, widget.listCard.id);
                            },
                            child: Container(
                              width: 264,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              height: 43, child: Text("Add card")
                            )
                          ),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (dialogContex)  {
                                  return CustomConfirmDialog(
                                    title: "Archive list",
                                    subtitle: "Do you want to archive this list.",
                                    onConfirm: () async {
                                      widget.onArchiveListCard(true, widget.listCard);
                                      Navigator.pop(context);
                                    }
                                  );
                                }
                              );
                            },
                            child: Container(
                              width: 264,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              height: 43, child: Text("Archive list")
                            )
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                onSort = true;
                              });
                            },
                            child: Container(
                              width: 264,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              height: 43,
                              child: Text("Sort by...")
                            )
                          )
                        ]
                      )
                    ]
                  )
                );
              }
            );
          }
        ).then((value) {onSort = false;});
      },
      child: Container(
        height: 28,
        width: 28,
        child: Icon(CupertinoIcons.ellipsis, size: 18)
      )
    );
  }
}

class ShowMoreCard extends StatefulWidget {
  const ShowMoreCard({
    Key? key,
    required this.context,
    required this.onHover,
    this.selectCardToRename,
    this.card
  }) : super(key: key);

  final BuildContext context;
  final bool onHover;
  final card;
  final selectCardToRename;

  @override
  State<ShowMoreCard> createState() => _ShowMoreCardState();
}

class _ShowMoreCardState extends State<ShowMoreCard> {

  onArchiveCard() {
    final token = Provider.of<Auth>(context, listen: false).token;
    CardItem card = widget.card;
    var payload = {
      "id": card.id,
      "description": card.description,
      "title": card.title,
      "is_archived": !card.isArchived,
      "due_date": card.dueDate != null ? card.dueDate!.toUtc().millisecondsSinceEpoch~/1000 + 86400 : null,
      "priority": card.priority
    };
    Provider.of<Boards>(context, listen: false).updateCardTitleOrDescription(token, card.workspaceId, card.channelId, card.boardId, card.listCardId, card, "cardInfo", payload);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    CardItem card = widget.card;
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return InkWell(
      onTap: () {
        showPopover(
          backgroundColor: isDark ? Color(0xff4C4C4C) : Colors.white,
          radius: 4,
          context: context,
          transitionDuration: const Duration(milliseconds: 50),
          direction: PopoverDirection.bottom,
          barrierColor: Colors.transparent,
          width: 148,
          height: 132,
          arrowHeight: 0,
          arrowWidth: 0,
          bodyBuilder: (BuildContext context) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xffA6A6A6)),
                borderRadius: BorderRadius.circular(4)
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      widget.selectCardToRename(card);
                    },
                    child: Container(
                      height: 43,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.pencilSimpleLine, size: 18),
                          SizedBox(width: 8),
                          Text("Rename", style: TextStyle(fontSize: 14))
                        ]
                      )
                    )
                  ),
                  Divider(color: Color(0xffA6A6A6), thickness: 0.5, height: 0.5),
                  InkWell(
                    onTap: () {
                      onArchiveCard();
                    },
                    child: Container(
                      height: 43,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.archive, size: 18),
                          SizedBox(width: 8),
                          Text(card.isArchived ? "Unachive card" : "Archive Card", style: TextStyle(fontSize: 14))
                        ]
                      )
                    ),
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
                  )
                ]
              )
            );
          }
        );
      },
      child: Container(
        height: 24,
        width: 24,
        padding: EdgeInsets.only(bottom: 6),
        child: Center(
          child: Text(widget.onHover  ? "..." : "",
            style: TextStyle(letterSpacing: 2, fontSize: 16)
          )
        )
      )
    );
  }
}

showDialogCreateCard(context, listCardId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: EdgeInsets.all(0),
        child: CreateCard(listCardId: listCardId)
      );
    }
  );
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

    return data.length == 0
        ? Container()
        : InkWell(
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
                    borderRadius: BorderRadius.circular(4)),
                child: !onAddCard
                    ? Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(Icons.add),
                          Text(S.current.addNewList,
                              style: TextStyle(fontSize: 14)),
                        ],
                      )
                    : Container(
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
                                      border: Border.all(
                                          color: Colors.blueGrey[300]!))),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 6),
                                      color: Colors.lightBlue,
                                      child: TextButton(
                                          onPressed: () {
                                            createNewCardList(
                                                token,
                                                currentWorkspace["id"],
                                                currentChannel["id"],
                                                selectedBoard["id"],
                                                controller.text);
                                          },
                                          child: Text(S.current.addList,
                                              style: TextStyle(
                                                  color: Colors.white))),
                                    ),
                                    SizedBox(width: 12),
                                    InkWell(
                                        onTap: () {
                                          onAddCard = false;
                                        },
                                        child: Icon(Icons.close,
                                            color: Colors.grey[600], size: 20))
                                  ])
                            ]))),
          );
  }
}

getPriority(priority, isDark) {
  Widget icon = priority == 1 ? Icon(PhosphorIcons.fire, color: Color(0xffFF7875), size: 19)
    : priority == 2 ? Container(
      height: 28,
      child: Stack(
        children: [
          Positioned(
            child: Icon(PhosphorIcons.caretUpThin,size: 18.5, color: Color(0xffFAAD14))
          ),
          Positioned(
            top: 4,
            child: Icon(PhosphorIcons.caretUpThin, size: 18.5, color: Color(0xffFAAD14))
          ),
          Positioned(
            top: 8,
            child: Icon(PhosphorIcons.caretUpThin, size: 18.5, color: Color(0xffFAAD14))
          )
        ]
      ),
    ) : priority == 3 ? Container(
      height: 22,
      child: Stack(
        children: [
          Positioned(child: Icon(PhosphorIcons.caretUpThin, size: 18.5, color: Color(0xff27AE60))),
          Positioned(top: 4, child: Icon(PhosphorIcons.caretUpThin, size: 18.5, color: Color(0xff27AE60)))
        ]
      ),
    ) : priority == 4 ? Icon(PhosphorIcons.caretUpThin, size: 18.5, color: Color(0xff69C0FF)) : Container();
    //  Icon(PhosphorIcons.minus, size: 19);

  Widget text = Text(priority == 1 ? "Urgent" : priority == 2 ? 'High' : priority == 3 ? 'Medium' : priority == 4 ? 'Low' : '',
    style: TextStyle(color: priority == 1 ? Color(0xffFF7875) : priority == 2 ? Palette.calendulaGold : priority == 3 ?
    Color(0xff27AE60) : priority == 4 ? Color(0xff69C0FF) :
     (isDark ? Palette.defaultTextDark : Palette.defaultTextLight)));

  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [icon, SizedBox(width: 8), text]
  );
}
