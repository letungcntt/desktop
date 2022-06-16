import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/channels/channel_info_macOS.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';
enum PollStatus {
  NEW, EDIT, DONE 
}

class PollCard extends StatefulWidget {
  const PollCard({
     Key? key,
     required this.att,
     this.message
    }) : super(key: key);
  
  final att;
  final message;
  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  List selected = [];
  List options = [];
  List added = [];
  List removed = [];
  bool isButtonHovered = false;

  @override
  void initState() {
    final userId = Provider.of<Auth>(context, listen: false).userId;
    options = List.from(widget.att["options"]);
    selected = widget.att["results"].where((e) => e["user_id"] == userId).toList();
    super.initState();
  }

  @override
  void didUpdateWidget (oldWidget) {
    if (widget.att.toString() != oldWidget.att.toString()) {
      final userId = Provider.of<Auth>(context, listen: false).userId;
      selected = widget.att["results"].where((e) => e["user_id"] == userId).toList();
      options = widget.att['options'];
    }
    super.didUpdateWidget(oldWidget);
  }

  onSelectPoll(option) {
    final userId = Provider.of<Auth>(context, listen: false).userId;
    final index = selected.indexWhere((e) => e["id"] == option['id']);

    this.setState(() {
      if (index != -1) {
        selected.removeAt(index);
      } else {
        selected.add({
          'id': option["id"],
          'user_id': userId
        });
      }  
    });
  }

  findUser(id) {
    final members = Provider.of<Workspaces>(context, listen: false).members;
    final indexMember = members.indexWhere((e) => e["id"] == id);

    if (indexMember != -1) {
      return members[indexMember];
    } else {
      return {};
    }
  }

  calculatePollSelect(option) {
    List results = widget.att['results'].where((e) => e["id"] == option["id"]).toList();
    final channelMember = Provider.of<Channels>(context, listen: false).channelMember;

    return channelMember.length != 0 ? results.length/channelMember.length : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark  = auth.theme == ThemeType.DARK;
    final currentUser = Provider.of<User>(context, listen: true).currentUser;
    options.sort((b, a) => widget.att["results"].where((e) => e["id"] == a["id"]).toList().length.compareTo(widget.att["results"].where((e) => e["id"] == b["id"]).toList().length));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        width: 420,
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: isDark ? Color(0xff2e2e2e) : Color(0xffdbdbdb)),
          color: isDark ? Color(0xff2E2E2E) : Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Container(
          padding: EdgeInsets.only(left: 24),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: (){
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            child: PollMessage(att: widget.att, message: widget.message)
                          );
                        }
                      );
                    },
                    child: Container(
                      width: 420 - 24*2,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        widget.att["title"], style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, height: 1.3),
                        textAlign: TextAlign.justify,
                      ) // Poll TOPIC
                    ),
                  ),
                  Container(
                    child: Column( // Poll Options
                      children: options.map<Widget>((option) {
                    final result = widget.att["results"].where((e) => e["id"] == option["id"]).toList();
                    final bool isVoted = result.indexWhere((e) => e["user_id"] == auth.userId) != -1;

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(width: 1, color: isDark ? Color(0xff5e5e5e) : Color(0xffdbdbdb)),
                                  borderRadius: BorderRadius.all(Radius.circular(4)),
                                ),
                                width: 380-24*2,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.all(Radius.circular(2)),
                                  child: LinearProgressIndicator(
                                    minHeight: 38,
                                    semanticsLabel: option["title"],
                                    value: calculatePollSelect(option),
                                    valueColor: AlwaysStoppedAnimation<Color>(isVoted ? isDark ?  Palette.calendulaGold.withOpacity(0.85) : Palette.dayBlue.withOpacity(0.35) : (isDark ? Color(0xff5e5e5e) :Color(0xffdbdbdb))),
                                    backgroundColor: isDark ? Color(0xff3D3D3D) : Color(0xfff8f8f8),
                                  )
                                )
                              ),
                              InkWell(
                                onTap: (){
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                        child: PollMessage(att: widget.att, message: widget.message)
                                      );
                                    }
                                  );
                                },
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  width: 380-24*2,
                                  height: 38,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.only(left: 16),
                                        width: 380-24*2-50,
                                        child: Text(
                                          option["title"], style: TextStyle(fontSize: 12),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis
                                        )
                                      ),
                                      Container(
                                        width: 50,
                                        child: InkWell(
                                          onTap: (){
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return voterDialog(option, result, isDark, currentUser);
                                              }
                                            );
                                          },
                                          child: Center(
                                            child: Text(
                                              result.length.toString(),
                                              style: TextStyle(
                                                fontSize: 12, fontWeight: FontWeight.w400
                                              ),
                                            )
                                          ),
                                        )
                                      ),
                                    ]
                                  )
                                ),
                              ),
                            ]
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 10),
                            width: 62,
                            height: 38,
                            child: Stack(
                              alignment: AlignmentDirectional.center,
                              children: result.map<Widget>((e) {
                                var member = findUser(e["user_id"]);
                                var index = result.indexWhere((ele) => ele["user_id"] == member["id"]);

                                return index < 2 || (index == 2 && result.length == 3 ) ? Positioned(
                                    left: 10.0*index,
                                    child: InkWell(
                                      onTap: (){
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return voterDialog(option, result, isDark, currentUser);
                                          }
                                        );
                                      },
                                      child: CachedAvatar(
                                        member["avatar_url"],
                                        width: 20,
                                        height: 20,
                                        isAvatar: true,
                                        name: member["full_name"]
                                      ))
                                  ) : index == 2 ? Positioned(
                                    left: 10.0*index,
                                    child: InkWell(
                                      onTap: (){
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return voterDialog(option, result, isDark, currentUser);
                                          }
                                        );
                                      },
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(Radius.circular(11)),
                                          color: Color(0xff5E5E5E).withOpacity(0.7),
                                        ),
                                        child: Center(child: Text("+ ${result.length - 2}", style: TextStyle(fontSize: (result.length - 2) < 10 ? 12 : (result.length - 2) < 100 ? 9 : 8)))
                                      ),
                                    )
                                  ): Container();                                     
                              }).toList()
                            )
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  )
                  ),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            child: PollMessage(att: widget.att, message: widget.message)
                          );
                        }
                      );
                    },
                    onHover: (hover) {
                      setState((){
                        isButtonHovered = hover;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(top: 10, bottom: 20),
                      alignment: Alignment.center,
                      height: 38,
                      width: 380-24*2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        color: isDark 
                          ? isButtonHovered ? Color(0xff5e5e5e).withOpacity(0.7) : Color(0xff5e5e5e)
                          : isButtonHovered ? Color(0xfff8f8f8).withOpacity(0.7) : Color(0xfff8f8f8)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIcons.plusCircle, size: 15, color: isDark ? Palette.calendulaGold : Colors.blue),
                          SizedBox(width: 8),
                          Text(S.current.addNewOption, style: TextStyle(color: isDark ? Palette.calendulaGold : Colors.blue, fontSize: 13)),
                        ],
                      )
                    ),
                  ),
                ]
              ),
            ],
          ),
        )
      )
    );
  }

  Dialog voterDialog(option, result, isDark, currentUser) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
      backgroundColor: isDark ? Palette.borderSideColorDark : Color(0xfff3f3f3),
      child: Container(
        child: Wrap(
          children:[ 
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Color(0xff5e5e5e) : Color(0xffdbdbdb),
                      )
                    )
                  ),
                  width: 280,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Text(S.current.optionName(option["title"]))
                ),
                ClipRRect(
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4)),
                  child: Container(
                    color: isDark ? Palette.backgroundRightSiderDark : Colors.white,
                    constraints: BoxConstraints(
                      maxHeight: 300,
                      maxWidth: 280
                    ),
                    child: SingleChildScrollView(
                      child: Wrap(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            child: Text("${result.length} voter(s):")
                          ),
                          Column(
                            children: result.map<Widget>((e) {
                              var member = findUser(e["user_id"]);
                              return Container(
                                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                child: InkWell(
                                  onTap: () {
                                    if (currentUser["id"] != member["id"]) {
                                      onShowUserInfo(context, member["user_id"] != null
                                        ? member["user_id"]
                                        : member["id"]);
                                    }
                                  },
                                  child: Container(
                                    child: Row(
                                      children: [
                                        CachedAvatar(
                                          member["avatar_url"],
                                          width: 30,
                                          height: 30,
                                          isAvatar: true,
                                          name: member["full_name"]
                                        ),
                                        SizedBox(width: 6),
                                        Text("${member["nickname"] ?? member["full_name"]}"),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}


class PollMessage extends StatefulWidget {
  const PollMessage({
    Key? key,
    required this.att,
    required this.message
  }) : super(key: key);

  final att;
  final message;

  @override
  State<PollMessage> createState() => _PollMessageState();
}


class _PollMessageState extends State<PollMessage> {
  List selected = [];
  List removed = [];
  List options = [];
  List added = [];
  List displayList = [];
  int currentOptionId = 0;

  onSelectPoll(option) {
    final userId = Provider.of<Auth>(context, listen: false).userId;
    final index = selected.indexWhere((e) => e["id"] == option['id']);

    this.setState(() {
      if (index != -1) {
        selected.removeAt(index);
      } else {
        selected.add({
          'id': option["id"],
          'user_id': userId
        });
      }  
    });
  }

  onSubmitPoll() {
    final token = Provider.of<Auth>(context, listen: false).token;
    final channelId = Provider.of<Channels>(context, listen: false).currentChannel['id'];
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace['id'];
    final messageId = widget.message['id'];

    added = added.where((e) => e["title"].trim() != "").toList();
    added = added.map((e) => {'id': e['id'], 'title': e['title']}).toList();

    Provider.of<Messages>(context, listen: false).onSubmitPoll(token, workspaceId, channelId, messageId, selected, added, removed);
  }

  @override
  void didUpdateWidget (oldWidget) {
    if (widget.att.toString() != oldWidget.att.toString()) {
      final userId = Provider.of<Auth>(context, listen: false).userId;
      selected = widget.att["results"].where((e) => e["user_id"] == userId).toList();
      options = widget.att['options'];
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    final userId = Provider.of<Auth>(context, listen: false).userId;
    options = List.from(widget.att["options"]);
    displayList = options + added;
    added.add({'id': generateOptionID(), 'title': "", 'status': PollStatus.NEW});
    selected = widget.att["results"].where((e) => e["user_id"] == userId).toList();
  }

  calculatePollSelect(option) {
    List results = widget.att['results'].where((e) => e["id"] == option["id"]).toList();
    final channelMember = Provider.of<Channels>(context, listen: false).channelMember;

    return results.length/channelMember.length;
  }

  int generateOptionID(){
    int newID = 0;
    List listID = displayList.map((e) => e["id"]).toList(); 
    while(listID.contains(newID)){
      newID += 1;
    }
    currentOptionId = newID;
    return newID;
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    displayList = options + added;
    return MouseRegion(
      cursor: MouseCursor.defer,
      child: GestureDetector(
        child: Container(
          width: 468,
          margin: EdgeInsets.only(top: 0),
          decoration: BoxDecoration(
            color: isDark ? Palette.borderSideColorDark : Color(0xfff3f3f3),
            borderRadius: BorderRadius.circular(4)
          ),
          child: Wrap(
            children: [
              Container(
                width: 468,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Text(S.current.addNewOption, style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 14, fontWeight: FontWeight.w500)),
                )
              ),
              isDark ? Container() : Container(height: 1, width: 468, color: Color(0xffdbdbdb)),
              Container(
                color: isDark ? Palette.backgroundRightSiderDark : Colors.white,
                constraints: BoxConstraints(
                  maxHeight: 600,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: displayList.map<Widget>((opt) {
                      final title = opt['title'];
                      final _controller = TextEditingController(text: title);

                      switch(opt['status']) {
                        case PollStatus.NEW:
                          return createPollItem(isDark, opt, _controller);
                        case PollStatus.EDIT:
                          return editPollItem(isDark, opt, _controller);
                        case PollStatus.DONE:
                          return InkWell(
                            overlayColor: MaterialStateProperty.all(Colors.grey[400]),
                            onTap: () { 
                              onSelectPoll(opt);
                            },
                            child: Container(
                              alignment: Alignment.centerLeft,
                              constraints: BoxConstraints(
                                minHeight: 40,
                              ),
                              width: 468-12*2,
                              decoration: BoxDecoration(
                                color: (selected.indexWhere((e) => e["id"] == opt["id"]) != -1) 
                                ? isDark ?  Color(0xff5e5e5e) :  Color(0xffdbdbdb)
                                : isDark ? Colors.grey[800] : Color(0xfff8f8f8),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isDark ? Color(0xff3d3d3d) : Color(0xffdbdbdb), 
                                ),
                              ),
                              margin: EdgeInsets.fromLTRB(18,6,18,0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 468-12*2-66,
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Text(title, style:TextStyle(fontSize: 13, inherit: false, height: 1.2))
                                  ),
                                  InkWell(
                                    onTap: () {
                                      currentOptionId = opt['id'];
                                      int _optionIndex = added.indexWhere((e) => e['id'] == currentOptionId);
                                      setState(() {
                                        added[_optionIndex]['status'] = PollStatus.EDIT;
                                      });
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(right: 4),
                                      child: Icon(
                                        PhosphorIcons.pencilSimpleLineThin,
                                        size: 20.0,
                                        color: isDark ? Colors.grey[300] : Color(0xff5e5e5e)
                                      )
                                    )
                                  ),
                                  InkWell(
                                    canRequestFocus: false,
                                    onTap: () {
                                      var removeIndex = added.indexWhere((e) => e == opt);
                                      setState(() {
                                        added.removeAt(removeIndex);
                                        var _index = added.indexWhere((e) => e["title"].trim() == "");
                                        if (_index == -1){
                                          setState(() {
                                            added.add({'id': generateOptionID(), 'title': "", 'status': PollStatus.NEW});
                                          });
                                        }
                                      });
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(right: 2),
                                      child: Icon(
                                        PhosphorIcons.trash,
                                        size: 20.0,
                                        color: isDark ? Colors.grey[300] : Color(0xff5e5e5e)
                                      ))
                                  ),
                                ],
                              )
                            )
                          );
                        default:
                          return InkWell(
                            overlayColor: MaterialStateProperty.all(Colors.grey[400]),
                            onTap: () { 
                              onSelectPoll(opt);
                            },
                            child: Container(
                              alignment: Alignment.centerLeft,
                              constraints: BoxConstraints(
                                minHeight: 40,
                              ),
                              width: 468-12*2,
                              decoration: BoxDecoration(
                                color: (selected.indexWhere((e) => e["id"] == opt["id"]) != -1) 
                                ? isDark ?  Color(0xff5e5e5e) :  Color(0xffdbdbdb)
                                : isDark ? Colors.grey[800] : Color(0xfff8f8f8),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isDark ? Color(0xff3d3d3d) : Color(0xffdbdbdb), 
                                ),
                              ),
                              margin: EdgeInsets.fromLTRB(18,6,18,0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(title, style: TextStyle(fontSize: 13)),
                              )
                            )
                          );
                      }
                    }).toList() + <Widget>[ SizedBox(height: 8) ]
                  ) 
                )
              ),
              isDark ? Container() : Container(height: 1, width: 468, color: Color(0xffdbdbdb)),
              InkWell(
                onTap: () {
                  var _optionIndex = added.indexWhere((e) => e['id'] == currentOptionId);
                  var _index = added.indexWhere((e) => e["title"].trim() == "");
                  if (_index == -1){
                    setState(() {
                      added[_optionIndex]['status'] = PollStatus.DONE;
                      added.add({'id': generateOptionID(), 'title': "", 'status': PollStatus.NEW});
                    });
                  }
                },
                child: Container(
                  child: Container(
                    margin: EdgeInsets.only(top: 12),
                    alignment: Alignment.center,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      color: Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIcons.plusCircle, size: 15, color: isDark ? Palette.calendulaGold : Colors.blue),
                        SizedBox(width: 8),
                        Text(S.current.addNewOption, style: TextStyle(color: isDark ? Palette.calendulaGold : Colors.blue, fontSize: 13)),
                      ],
                    )
                  ),
                )
              ),
              Container(
                width: 468,
                margin: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.redAccent
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: isDark ? Color(0xff3D3D3D) : Colors.white
                      ),
                      width: 212,
                      height: 32,
                      child: TextButton(onPressed: () {Navigator.pop(context);}, child: Text(S.current.cancel, style: TextStyle(color: Colors.redAccent)))
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.blueAccent
                      ),
                      width: 212,
                      height: 32,
                      child: TextButton(onPressed: () {
                        onSubmitPoll();
                        Navigator.pop(context);
                      }, child: Text(S.current.submit, style: TextStyle(color: Colors.white)))
                    ),
                  ],
                )
              )
            ]
          )
        ),
      ),
    );
  }

  FocusScope createPollItem(bool isDark, opt, TextEditingController controller) {
    return FocusScope(
    child: Container(
      margin: EdgeInsets.only(top: 6),
      width: 468-18*2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isDark ? Colors.grey[800] : Color(0xfff8f8f8)
      ),
      height: 39,
      child: Row(
        children: [
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDark ? Color(0xff3d3d3d) : Color(0xffdbdbdb), 
              ),
            ),
            width: 468-18*2,
            child: CupertinoTextField(
              controller: controller,
              key: Key(opt["id"].toString()),
              autofocus: true,
              onChanged: (value) {
                opt['title'] = value;
              },
              padding: EdgeInsets.symmetric(horizontal: 16),
              placeholder: S.current.option,
              placeholderStyle: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Color(0xff828282)),
              style: TextStyle(color: isDark ?Colors.grey[200] : Color(0xff3d3d3d), fontSize: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isDark ? Colors.grey[800] : Color(0xfff8f8f8)
              ),
              onEditingComplete: (){
                var _index = added.indexWhere((e) => e["title"].trim() == "");
                if (_index == -1){
                  setState(() {
                    opt['status'] = PollStatus.DONE;
                    added.add({'id': generateOptionID(), 'title': "", 'status': PollStatus.NEW});
                  });
                }
              },
            )
          ),
        ],
      )
    ),
  );
  }

  FocusScope editPollItem(bool isDark, opt, TextEditingController controller) {
    String _queue = "";

    return FocusScope(
    child: Container(
      margin: EdgeInsets.only(top: 6),
      width: 468-18*2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isDark ? Colors.grey[800] : Color(0xfff8f8f8)
      ),
      height: 39,
      child: Row(
        children: [
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDark ? Color(0xff3d3d3d) : Color(0xffdbdbdb), 
              ),
            ),
            width: 468-18*2,
            child: CupertinoTextField(
              controller: controller,
              key: Key(opt["id"].toString()),
              autofocus: true,
              onChanged: (value) {
                _queue = value;
              },
              padding: EdgeInsets.symmetric(horizontal: 16),
              placeholder: S.current.option,
              placeholderStyle: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Color(0xff828282)),
              style: TextStyle(color: isDark ?Colors.grey[200] : Color(0xff3d3d3d), fontSize: 13, inherit: false),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isDark ? Colors.grey[800] : Color(0xfff8f8f8)
              ),
              onEditingComplete: (){},
              suffix: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (_queue.trim() != ""){
                        setState(() {
                          opt['title'] = _queue;
                          opt['status'] = PollStatus.DONE;
                        });
                      } else {
                        setState((){
                          opt['status'] = PollStatus.DONE;  
                        });
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 4),
                      child: Icon(
                        PhosphorIcons.check,
                        size: 20.0,
                        color: Colors.blue
                      )
                    )
                  ),
                  InkWell(
                    onTap: () {
                      setState((){
                        opt['status'] = PollStatus.DONE;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 4),
                      child: Icon(
                        PhosphorIcons.x,
                        size: 20.0,
                        color: Colors.red
                      )
                    )
                  ),
                  InkWell(
                    canRequestFocus: false,
                    onTap: () {
                      var removeIndex = added.indexWhere((e) => e == opt);
                      setState(() {
                        added.removeAt(removeIndex);
                        var _index = added.indexWhere((e) => e["title"].trim() == "");
                        if (_index == -1){
                          setState(() {
                            added.add({'id': generateOptionID(), 'title': "", 'status': PollStatus.NEW});
                          });
                        }
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 8),
                      child: Icon(
                        PhosphorIcons.trash,
                        size: 20.0,
                        color: isDark ? Colors.grey[300] : Color(0xff5e5e5e)
                      ))
                  ),
                ],
              )
            )
          ),
        ],
      )
    ),
  );
  }

}

