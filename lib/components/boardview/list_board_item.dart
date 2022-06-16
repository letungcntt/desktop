import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/components/boardview/card_detail.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';
import 'CardItem.dart';
import 'component/models.dart';

class ListBoardItem extends StatefulWidget {
  const ListBoardItem({
    Key? key,
    this.workspaceId,
    this.channelId,
    this.collapseListBoard
  }) : super(key: key);

  final workspaceId;
  final channelId;
  final collapseListBoard;

  @override
  State<ListBoardItem> createState() => _ListBoardItemState();
}

class _ListBoardItemState extends State<ListBoardItem> {
  @override
  void initState() { 
    super.initState();
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;

    Provider.of<Boards>(context, listen: false).getListBoards(token, currentWorkspace["id"], currentChannel["id"]);
  }

  @override
  void didUpdateWidget (oldWidget) {
    if ((oldWidget.workspaceId != null && oldWidget.workspaceId != widget.workspaceId) || (oldWidget.channelId != null && oldWidget.channelId != widget.channelId)) {
      final token = Provider.of<Auth>(context, listen: false).token;
      final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;

      Provider.of<Boards>(context, listen: false).getListBoards(token, currentWorkspace["id"], currentChannel["id"]).then((e) {
        final data = Provider.of<Boards>(context, listen: false).data;
        if (data.length > 0) {
          Provider.of<Boards>(context, listen: false).onChangeBoard(data[0]);
        }
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  getListArchivedCard() {
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
    List<CardItem> archivedCards = [];

    for (var index = 0; index < selectedBoard["list_cards"].length; index++) {
      var listCards = selectedBoard["list_cards"][index];

      for (var i = 0; i < listCards["cards"].length; i++) {
        var e = i < listCards["cards"].length ? listCards["cards"][i] : {};
        if (e["is_archived"] == true) {
          archivedCards.add(CardItem.cardFrom({
            "id": e["id"],
            "title": e["title"],
            "description": e["description"],
            "listIndex": index, 
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
    }

    return archivedCards;
  }

  onShowArchivedCard() {
    List<CardItem> archivedCards = getListArchivedCard();

    showDialog(
      context: context,
      builder: (BuildContext context) {        
        return Dialog(
          backgroundColor: Colors.grey[300],
          child: Container(
            padding: EdgeInsets.only(top: 8, left: 4, right: 4),
            constraints: BoxConstraints(
              maxHeight: 800
            ),
            height: 420,
            width: 300,
            child: Column(
              children: [
                Text(
                  "Archived cards",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700], fontFamily: 'Roboto', fontWeight: FontWeight.w400),
                ),
                SizedBox(height: 4),
                Container(
                  height: 380,
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: archivedCards.length,
                    itemBuilder: (context, index) { 
                      return buildCardItem(archivedCards[index]);
                    }
                  ),
                ),
              ],
            ),
          )
        );
      }
    );
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

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              child: CardDetail(card: cardItem),
            );
          }
        ).then((value) {
          Provider.of<Boards>(context, listen: false).onSelectCard(null);
          Navigator.pop(context);
        });
      },
      child: Card(
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
                      children: [
                        if (cardItem.commentsCount > 0) Row(
                          children: [
                            Icon(PhosphorIcons.chatCircleDots, size: 13, color: isDark ? Color(0xffB7B7B7) : Colors.black.withOpacity(0.45)),
                            SizedBox(width: 3),
                            Text(cardItem.commentsCount.toString(), style: TextStyle(fontSize: 13)),
                            SizedBox(width: 10)
                          ]
                        ),
                        if (cardItem.tasks.length > 0) Row(
                          children: [
                            Icon(Icons.check_box_outlined, size: 14, color: isDark ? Color(0xffB7B7B7) : Colors.black.withOpacity(0.45)),
                            SizedBox(width: 3),
                            Text("${checkedTasks.length}/${tasks.length}", style: TextStyle(fontSize: 13))
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
              )
            ]
          )
        )
      )
    );
  }

  onArrangeBoard(data) async {
    setState(() {});
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    Provider.of<Boards>(context, listen: false).onArrangeBoard(data, currentChannel["id"]);
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<Boards>(context, listen: true).data;
    final selectedBoard = Provider.of<Boards>(context, listen: true).selectedBoard;
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xff262626) : Color(0xffF3F3F3),
        border: Border(
          right: BorderSide(
            color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)
          )
        )
      ),
      height: MediaQuery.of(context).size.height - 38,
      width: widget.collapseListBoard ? 64 : 256,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.collapseListBoard ? Container(height: 56) : Padding(
            padding: EdgeInsets.only(top: 19, left: 24, bottom: 18),
            child: Container(
              child: Text("BOARD:", style: TextStyle(color: isDark ? Color(0xffC9C9C9) : Color(0xff828282), fontSize: 16, fontWeight: FontWeight.w600))
            )
          ),
          Divider(thickness: 1, color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1),
          Container(
            width: 256,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.map<Widget>((e) {
                int index = data.indexOf(e);

                return InkWell(
                  onTap: () {  
                    Provider.of<Boards>(context, listen: false).onChangeBoard(e);
                  },
                  child: BoardTitle(selectedBoard: selectedBoard, board: e, index: index, collapseListBoard: widget.collapseListBoard)
                );
              }).toList()
            )
          ),
          SizedBox(height: 16),
          widget.collapseListBoard ? InkWell(
            onTap: () {
              showDialogCreateBoard(context);
            },
            child: Container(
              margin: EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: isDark ? Color(0xff4C4C4C) : Color(0xffDBDBDB),
                borderRadius: BorderRadius.circular(4)
              ),
              width: 40,
              height: 40,
              child: Center(child: Icon(PhosphorIcons.plus)),
            ),
          ) : Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: 256 - 48,
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Color(0xff4C4C4C) : Colors.white,
                borderRadius: BorderRadius.circular(4)
              ),
              child: TextButton(
                style: ButtonStyle(overlayColor: MaterialStateProperty.all(Colors.transparent)),
                onPressed: () {  
                  showDialogCreateBoard(context);
                },
                child: Wrap(
                  children: [
                    Icon(PhosphorIcons.plus, size: 18, color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                    SizedBox(width: 12),
                    Text("New Board", style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue, fontSize: 16, fontWeight: FontWeight.w400))
                  ]
                )
              )
            )
          )
        ]
      )
    );
  }

  showDialogCreateBoard(context) {
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
 
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final token = Provider.of<Auth>(context, listen: false).token;
        final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
        final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
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
                  color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
                  child: Text(S.current.createNewBoard, style: TextStyle(fontSize: 14))
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: TextFormField (
                    autofocus: true,
                    controller: controller,
                    style: TextStyle(color: isDark ? Colors.white : Color(0xffA6A6A6)),
                    decoration: InputDecoration(
                      hintText: "Name board",
                      hintStyle: TextStyle(fontSize: 14, color: Color(0xffA6A6A6)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                        borderRadius: BorderRadius.all(Radius.circular(4))
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                        borderRadius: BorderRadius.all(Radius.circular(4))
                      )
                    ),
                    onEditingComplete: () async {
                      if (controller.text.trim() == "") return;
                      await Provider.of<Boards>(context, listen: false).createNewBoard(token, currentWorkspace["id"], currentChannel["id"], controller.text);
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
                              border: Border.all(color: Palette.errorColor),
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: Center(child: Text(S.current.cancel, style: TextStyle(color: Palette.errorColor)))
                          )
                        ),
                      ),
                      SizedBox(width: 16),
                      Flexible(
                        flex: 1,
                        child: InkWell(
                          onTap: () async {
                            if (controller.text.trim() == "") return;
                            await Provider.of<Boards>(context, listen: false).createNewBoard(token, currentWorkspace["id"], currentChannel["id"], controller.text);
                            Navigator.pop(context);
                          }, 
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Palette.dayBlue
                            ),
                            child: Center(child: Text("Create board", style: TextStyle(fontSize: 14, color: Palette.defaultTextDark)))
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
}

class BoardTitle extends StatefulWidget {
  const BoardTitle({
    Key? key,
    required this.selectedBoard,
    required this.board,
    required this.index,
    required this.collapseListBoard
  }) : super(key: key);

  final Map selectedBoard;
  final int index;
  final Map board;
  final bool collapseListBoard;

  @override
  State<BoardTitle> createState() => _BoardTitleState();
}

class _BoardTitleState extends State<BoardTitle> {
  List colors = [
    "5CDBD3", "389E0D", "1890FF", "531DAB", "F759AB", "FAAD14", "D46B08", "FF7875", "D9DBEA", 
    "08979C", "237804", "0050B3", "B37FEB", "9E1068", "D48806", "FFA940", "A8071A", "6B7588",
    "13C2C2", "B7EB8F", "096DD9", "722ED1", "C41D7F", "FFD666", "FA8C16", "F5222D", "8F90A6"
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return widget.collapseListBoard ? Container(
      width: 64,
      height: 48,
      padding: EdgeInsets.only(top: 12, left: 18, right: 20, bottom: 12),
      decoration: BoxDecoration(
        color: widget.board["id"] == widget.selectedBoard["id"] ? isDark ? Color(0xff3D3D3D) : Colors.white : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: widget.board["id"] == widget.selectedBoard["id"] ? isDark ? Palette.calendulaGold : Palette.dayBlue : Colors.transparent,
            width: 2
          )
        )
      ),
      child: Container(
        height: 24, width: 24, 
        decoration: BoxDecoration(
          color: Color(int.parse("0xFF${colors[widget.index]}")),
          borderRadius: BorderRadius.circular(4)
        ),
        child: Center(child: Text("A", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Palette.darkTextField)))
      )
    ) : Container(
      width: 256,
      decoration: widget.board["id"] == widget.selectedBoard["id"] ? BoxDecoration(
        color: isDark ? Color(0xff3D3D3D) : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDark ? Palette.calendulaGold : Palette.dayBlue,
            width: 2
          )
        )
      ) : null,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: widget.board["id"] == widget.selectedBoard["id"] ? 22 : 24),
      child: Wrap(
        children: [
          Container(
            height: 16, width: 16, 
            decoration: BoxDecoration(
              color: Color(int.parse("0xFF${colors[widget.index]}")),
              borderRadius: BorderRadius.circular(4)
            )
          ),
          SizedBox(width: 12),
          Text(widget.board["title"], style: TextStyle(fontSize: 16))
        ]
      )
    );
  }
}