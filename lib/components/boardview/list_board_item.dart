import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/components/boardview/card_detail.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';
import 'CardItem.dart';
import 'component/models.dart';

class ListBoardItem extends StatefulWidget {
  const ListBoardItem({
    Key? key,
    this.workspaceId,
    this.channelId
  }) : super(key: key);

  final workspaceId;
  final channelId;

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

  onArrangeBoard(data) async {
    setState(() {});
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    Provider.of<Boards>(context, listen: false).onArrangeBoard(data, currentChannel["id"]);
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<Boards>(context, listen: true).data;
    final selectedBoard = Provider.of<Boards>(context, listen: true).selectedBoard;
    final isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;

    return Container(
      padding: EdgeInsets.only(top: 8, left : 12),
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Your boards:", style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700], fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(3)
                    ),
                    child: TextButton(
                      style: ButtonStyle(overlayColor: MaterialStateProperty.all(Colors.transparent)),
                      onPressed: () {  
                        showDialogCreateBoard(context);
                      },
                      child: Text("Add New Board", style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[800], fontSize: 15))
                    )
                  ),
                  Container(
                    width: 500,
                    height: 34,
                    child: ReorderableListView(
                      scrollDirection: Axis.horizontal,
                      children: data.map<Widget>((e) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 6),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: selectedBoard["id"] == e["id"] ? Colors.blue : Colors.grey),
                            borderRadius: BorderRadius.circular(3)
                          ),
                          key: Key("${e["id"]}"), 
                          child: TextButton(
                            style: ButtonStyle(overlayColor: MaterialStateProperty.all(Colors.transparent)),
                            onPressed: () {  
                              Provider.of<Boards>(context, listen: false).onChangeBoard(e);
                            },
                            child: Text(e["title"], style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[800], fontSize: 15))
                          )
                        );
                      }).toList(),

                      onReorder: (int start, int current) {
                        if (start < current) {
                          int end = current - 1;
                          var startItem = data[start];
                          int i = 0;
                          int local = start;
                          do {
                            data[local] = data[++local];
                            i++;
                          } while (i < end - start);
                          data[end] = startItem;
                        } else if (start > current) {
                          var startItem = data[start];
                          for (int i = start; i > current; i--) {
                            data[i] = data[i - 1];
                          }
                          data[current] = startItem;
                        }

                        onArrangeBoard(data);
                      }
                    )
                  )
                ]
              ),
              Container(
                margin: EdgeInsets.only(right: 10),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(3)
                ),
                child: TextButton(
                  style: ButtonStyle(overlayColor: MaterialStateProperty.all(Colors.transparent)),
                  onPressed: () {  
                    onShowArchivedCard();
                  },
                  child: Text("Archived cards", style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[800], fontSize: 15))
                )
              ),
            ]
          ),
          SizedBox(height: 8),
          Divider(height: 5, thickness: 1)
        ]
      )
    );
  }

  showDialogCreateBoard(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final token = Provider.of<Auth>(context, listen: false).token;
        final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
        final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
        final controller = TextEditingController();
        final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

        return Dialog(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            width: 220,
            height: 156,
            child: Column(
              children: [
                Text(S.current.createNewBoard, style: TextStyle(fontSize: 16, color: isDark ? Colors.grey[300] : Colors.grey[800])),
                SizedBox(height: 16),
                CupertinoTextField(
                  autofocus: true,
                  style: TextStyle(color: Colors.grey[700]),
                  controller: controller,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[500]!),
                    color: isDark ? Colors.grey[300] : Colors.white
                  ),
                  onEditingComplete: () async {
                    if (controller.text.trim() == "") return;
                    await Provider.of<Boards>(context, listen: false).createNewBoard(token, currentWorkspace["id"], currentChannel["id"], controller.text);
                    Navigator.pop(context);
                  },
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
                        await Provider.of<Boards>(context, listen: false).createNewBoard(token, currentWorkspace["id"], currentChannel["id"], controller.text);
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