import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:popover/popover.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/components/boardview/card_detail.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/providers/providers.dart';
import 'CardItem.dart';
import 'component/models.dart';

class ListBoardItem extends StatefulWidget {
  const ListBoardItem({
    Key? key,
    this.workspaceId,
    this.channelId,
    this.collapseListBoard,
    this.onShowArchiveBoard,
    required this.showArchiveBoard
  }) : super(key: key);

  final workspaceId;
  final channelId;
  final collapseListBoard;
  final onShowArchiveBoard;
  final bool showArchiveBoard;

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

    Provider.of<Boards>(context, listen: false).getListBoards(token, currentWorkspace["id"], currentChannel["id"]).then((res) {
      final data = Provider.of<Boards>(context, listen: false).data;
      if (data.length == 0) {
        Provider.of<Boards>(context, listen: false).createDefaultBoard(token, currentWorkspace["id"], currentChannel["id"]);
      }
    });
  }

  @override
  void didUpdateWidget (oldWidget) {
    if ((oldWidget.workspaceId != null && oldWidget.workspaceId != widget.workspaceId) || (oldWidget.channelId != null && oldWidget.channelId != widget.channelId)) {
      final token = Provider.of<Auth>(context, listen: false).token;
      final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;

      Provider.of<Boards>(context, listen: false).getListBoards(token, currentWorkspace["id"], currentChannel["id"]).then((e) {
        final data = Provider.of<Boards>(context, listen: false).data;
        if (data.length == 0) {
          Provider.of<Boards>(context, listen: false).createDefaultBoard(token, currentWorkspace["id"], currentChannel["id"]);
        }
      });
    }

    super.didUpdateWidget(oldWidget);
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
    final dataBoard = data.where((e) => e["is_archived"] != true).toList();
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
      child: Stack(
        children: [
          Column(
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
                  children: dataBoard.map<Widget>((e) {
                    int index = dataBoard.indexOf(e);

                    return InkWell(
                      onTap: () {
                        Provider.of<Boards>(context, listen: false).onChangeBoard(e);
                        widget.onShowArchiveBoard(false);
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
          ),
          Positioned(
            bottom: 0,
            child: InkWell(
              onTap: () {
                widget.onShowArchiveBoard(!widget.showArchiveBoard);
              },
              child: Container(
                width: 260,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)
                    )
                  )
                ),
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: widget.collapseListBoard ? 20 : 24),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.archive, size: 20, color: widget.showArchiveBoard ? Color(0xffFAAD14) : null),
                    SizedBox(width: 10),
                    if(!widget.collapseListBoard) Text("Archived Board", style: TextStyle(fontSize: 16, color: widget.showArchiveBoard ? Color(0xffFAAD14) : null))
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
                    style: TextStyle(color: isDark ? Colors.white : Color(0xff3D3D3D)),
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

  onRenameBoard(title) {
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
    final token = Provider.of<Auth>(context, listen: false).token;
    widget.board["title"] = title;
    var newBoard = {...widget.board, "title": title};
    Provider.of<Boards>(context, listen: false).changeBoardInfo(token, selectedBoard["workspace_id"], selectedBoard["channel_id"], newBoard);
    Navigator.pop(context);
  }

  onArchiveBoard(value) {
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;
    final token = Provider.of<Auth>(context, listen: false).token;
    widget.board["is_archived"] = value;
    var newBoard = {...widget.board, "is_archived": value};
    Provider.of<Boards>(context, listen: false).changeBoardInfo(token, selectedBoard["workspace_id"], selectedBoard["channel_id"], newBoard);
    final data = Provider.of<Boards>(context, listen: false).data;
    final index = data.indexWhere((e) => e["is_archived"] != true);
    Provider.of<Boards>(context, listen: false).onChangeBoard(index == -1 ? {} : data[index]);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final selectedBoard = Provider.of<Boards>(context, listen: false).selectedBoard;

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
        child: Center(child: Text(widget.board["title"][0].toUpperCase(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Palette.darkTextField)))
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Wrap(
            children: [
              Container(
                height: 16, width: 16,
                decoration: BoxDecoration(
                  color: Color(int.parse("0xFF${colors[widget.index]}")),
                  borderRadius: BorderRadius.circular(4)
                )
              ),
              SizedBox(width: 12),
              Container(
                width: 160,
                child: Text(widget.board["title"], style: TextStyle(fontSize: 16, overflow: TextOverflow.ellipsis))
              )
            ]
          ),
          if (widget.board["id"] == widget.selectedBoard["id"]) InkWell(
            onTap: () {
              showPopover(
                backgroundColor: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
                context: context,
                transitionDuration: const Duration(milliseconds: 50),
                direction: PopoverDirection.right,
                barrierColor: Colors.transparent,
                arrowHeight: 0,
                arrowWidth: 0,
                radius: 4,
                height: 88,
                width: 168,
                bodyBuilder: (context) => StatefulBuilder(
                  builder: (context, setState) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: isDark ? Color(0XFF4C4C4C) : Color(0xffffffff)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              showDialogCreateBoard(context, widget.board, onRenameBoard);
                            },
                            child: Container(
                              height: 43,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Icon(PhosphorIcons.pencilSimpleLineThin, size: 20),
                                  SizedBox(width: 10),
                                  Text("Rename", style: TextStyle(color: isDark ? null : Color(0xff3D3D3D)))
                                ]
                              )
                            ),
                          ),
                          Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), thickness: 1, height: 0),
                          InkWell(
                            onTap: () {
                              onArchiveBoard(selectedBoard["is_archived"] != null ? !selectedBoard["is_archived"] : true);
                            },
                            child: Container(
                              height: 43,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Icon(PhosphorIcons.archiveThin, size: 20),
                                  SizedBox(width: 10),
                                  Text("Archive Board", style: TextStyle(color: isDark ? null : Color(0xff3D3D3D)))
                                ]
                              )
                            )
                          )
                        ]
                      )
                    );
                  }
                )
              );
            },
            child: Icon(CupertinoIcons.ellipsis, size: 20)
          )
        ]
      )
    );
  }
}

showDialogCreateBoard(context, board, onRenameBoard) {
  final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

  showDialog(
    context: context,
    builder: (BuildContext context) {
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
                child: Text("Rename board", style: TextStyle(fontSize: 14))
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
                    onRenameBoard(controller.text.trim());
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
                          onRenameBoard(controller.text.trim());
                        },
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Palette.dayBlue
                          ),
                          child: Center(child: Text("Rename", style: TextStyle(fontSize: 14, color: Palette.defaultTextDark)))
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