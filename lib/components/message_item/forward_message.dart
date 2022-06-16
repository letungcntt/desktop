import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/channels/create_channel_desktop.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/http_exception.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/flutter_mention/flutter_mentions.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart' hide WorkspaceItem;

import '../../workview_desktop/create_issue.dart';

class ForwardMessage extends StatefulWidget {
  ForwardMessage({
    Key? key,
    required this.message,
  }) : super(key: key);

  final message;

  @override
  _ForwardMessageState createState() => _ForwardMessageState();
}

enum SEARCH {
  DIRERCT,
  CHANNEL
}

class _ForwardMessageState extends State<ForwardMessage> {
  var _debounce;
  List resultMembersSearch = [];
  List channelsFilter = [];
  bool isShow = false;
  var destination;
  GlobalKey<FlutterMentionsState> key = GlobalKey<FlutterMentionsState>();
  TextEditingController controller = TextEditingController();
  SEARCH type = SEARCH.CHANNEL;
  int indexWorkspaceSelected = 0;

  getSuggestionMentions() {
    final auth = Provider.of<Auth>(context, listen: false);
    final dataUserMentions = Provider.of<User>(context, listen: false).userMentionInDirect;
    final directMessage = Provider.of<DirectMessage>(context, listen: false).directMessageSelected;
    var listUser = [] + directMessage.user + dataUserMentions;
    Map index = {};

    List<Map<String, dynamic>> dataList = [];
      for (var i = 0 ; i< listUser.length; i++){
        if (index[listUser[i]["user_id"]] != null) continue;
        Map<String, dynamic> item = {
          'id': listUser[i]["user_id"],
          'type': 'user',
          'display': Utils.getUserNickName(listUser[i]["user_id"]) ?? listUser[i]["full_name"],
          'full_name': Utils.checkedTypeEmpty(Utils.getUserNickName(listUser[i]["user_id"]))
              ? "${Utils.getUserNickName(listUser[i]["user_id"])} • ${listUser[i]["full_name"]}"
              : listUser[i]["full_name"],
          'photo': listUser[i]["avatar_url"]
        };
        index[listUser[i]["user_id"]] = true;

        if (auth.userId != listUser[i]["user_id"]) dataList += [item];
      }

    return dataList;
  }

  renderTextMention(att, isDark) {
    return att["data"].map((e){
      if (e["type"] == "text" && Utils.checkedTypeEmpty(e["value"])) return e["value"];
      if (e["name"] == "all" || e["type"] == "all") return "@all ";

      if (e["type"] == "issue") {
        return "";
      } else {
        return Utils.checkedTypeEmpty(e["name"]) ? "@${e["name"]} " : "";
      }
    }).toList().join("");
  }

  getRandomString(int length){
    const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _rnd = Random();
    return String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }

  sendForwardMessage() async{
    var auth = Provider.of<Auth>(context, listen: false);
    var user = Provider.of<User>(context, listen: false);
    var providerMessage = Provider.of<Messages>(context, listen: false);
    var result = providerMessage.checkMentions(key.currentState!.controller!.markupText.trim());
    var fakeId = getRandomString(20);

    if(destination == null) return;

    Map dataMessage  = {
      "channel_thread_id": null,
      "key": Utils.getRandomString(20),
      "message": result["success"] ? "" : result["data"],
      "attachments": [] + (result["success"] ? ([{
          "type": "mention",
          "data": result["data"]
        }]) : []) + [{
          "mime_type": "share",
          "data": {
            ...widget.message,
            'conversation_id': destination['id'],
            "channel_id":  destination['id'] ?? 0,
            "workspace_id": destination['workspace_id'] ?? 0,
          }
      }],
      "conversation_id": destination['id'],
      "channel_id":  destination['id'] ?? 0,
      "workspace_id": destination['workspace_id'] ?? 0,
      "count_child": 0,
      "user_id": auth.userId,
      "user": user.currentUser["full_name"] ?? "",
      "avatar_url": user.currentUser["avatar_url"] ?? "",
      "full_name": user.currentUser["full_name"] ?? "",
      "inserted_at": DateTime.now().add(new Duration(hours: -7)).toIso8601String(),
      "is_system_message": false,
      "isDesktop": true,
      "show": true,
      "time_create": DateTime.now().add(new Duration(hours: -7)).toIso8601String(),
      "current_time": DateTime.now().microsecondsSinceEpoch,
      "count": 0,
      "isSend": true,
      "sending": true,
      "success": true,
      "fake_id": fakeId,
    };

    if (!destination['isChannel']) {
      bool isSend = await Provider.of<DirectMessage>(context, listen: false).getInfoDirectMessage(auth.token, destination['id']);
      if(isSend) Provider.of<DirectMessage>(context, listen: false).sendMessageWithImage([], dataMessage, auth.token);
    } else {
      await Provider.of<Workspaces>(context, listen: false).onSelectWorkspace(context, destination['workspace_id']);
      await Provider.of<Channels>(context, listen: false).onSelectedChannel(destination['workspace_id'], destination['id'], auth, providerMessage);
      await Provider.of<Messages>(context, listen: false).sendMessageWithImage([], dataMessage, auth.token);
    }

    Navigator.pop(context);
  }

  search(value, token) async {
    if(type == SEARCH.CHANNEL) {
      final data = Provider.of<Channels>(context, listen: false).data;
      final dataWorkspaces = Provider.of<Workspaces>(context, listen: false).data;

      setState(() {
        channelsFilter = data.where((ele) {
          final bool check = Utils.unSignVietnamese(ele['name']).toLowerCase().contains(Utils.unSignVietnamese(controller.text.toLowerCase())) && ele["workspace_id"] == dataWorkspaces[indexWorkspaceSelected]["id"] && !ele["is_archived"];
          return check;
        }).toList();
      });
    } else {
      String url = "${Utils.apiUrl}direct_messages/search_conversation?token=$token&text=$value";
      try {
        var response = await Dio().get(url);
        var dataRes = response.data;
        if (dataRes["success"]) {
          setState(() {
            resultMembersSearch = dataRes["data"];
          });
        } else {
          throw HttpException(dataRes["message"]);
        }
      } catch (e) { }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final bool isDark = auth.theme == ThemeType.DARK;
    final dataWorkspaces = Provider.of<Workspaces>(context, listen: false).data;
    final data = Provider.of<Channels>(context, listen: true).data;

    return Container(
      width: 750,
      height: 700,
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor)
              )
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    S.current.forwardThisMessage,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey[800]
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    PhosphorIcons.xCircle, size: 20,
                    color: isDark ? Colors.white70 : Colors.grey[800],
                  ),
                )
              ],
            )
          ),
          Container(
            height: 600,
            child: SingleChildScrollView(
              controller: ScrollController(),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  PortalEntry(
                    visible: isShow,
                    portalAnchor: Alignment.topCenter,
                    childAnchor: Alignment.bottomCenter,
                    portal: Container(
                      margin: EdgeInsets.only(top: destination != null ? 32 : 20),
                      width: 700,
                      decoration: BoxDecoration(
                        border: isDark ? Border() : Border.all(
                          color: Color(0xffA6A6A6), width: 0.2
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                          color: isDark ? Color(0xff2f3136) : Color(0xFFf0f0f0),
                        ),
                      constraints: BoxConstraints(
                        maxHeight: 415,
                        minHeight: 0,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            child: Row(
                              children: [
                                TextButton(
                                  focusNode: FocusNode()..skipTraversal = true,
                                  onPressed: () { 
                                    type = SEARCH.DIRERCT;
                                    search(controller.text, auth.token);
                                  },
                                  child: Row(
                                    children: [
                                      Icon(CupertinoIcons.chat_bubble_2, size: 18.0, color:  isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                      SizedBox(width: 8.0,),
                                      Text(S.current.directMessages, style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight))
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12.0),
                                TextButton(
                                  focusNode: FocusNode()..skipTraversal = true,
                                  onPressed: () { 
                                    type = SEARCH.CHANNEL;
                                    search(controller.text, auth.token);
                                  },
                                  child: Row(
                                    children: [
                                      Icon(CupertinoIcons.list_dash, size: 18.0, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                      SizedBox(width: 8.0,),
                                      Text(S.current.workspace, style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight))
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          type == SEARCH.CHANNEL ? Container(
                            height: 370,
                            child: Column(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: isDark ? const Color(0xff5E5E5E) : const Color(0xffEAE8E8),
                                  ),
                                  height: 40,
                                  child: ScrollConfiguration(
                                    behavior: MyCustomScrollBehavior(),
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: dataWorkspaces.length,
                                      itemBuilder: (context, index) {
                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              indexWorkspaceSelected = index;
                                              channelsFilter = data.where((ele) {
                                                final bool check = Utils.unSignVietnamese(ele['name']).toLowerCase().contains(Utils.unSignVietnamese(controller.text )) && ele["workspace_id"] == dataWorkspaces[index]["id"] && !ele["is_archived"];
                                                return check;
                                              }).toList();
                                            });
                                          },
                                          child: WorkspaceItem(
                                            imageUrl: dataWorkspaces[index]["avatar_url"] ?? "",
                                            workspaceName: dataWorkspaces[index]["name"] ?? "",
                                            isSelected: indexWorkspaceSelected == index,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: isDark ? const Color(0xff2E2E2E) : Colors.white,
                                        border: isDark ? null : Border.all(color: const Color(0xffC9C9C9)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.only(top: 12, bottom: 12, left: 16),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xff4C4C4C) : const Color(0xffF8F8F8),
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(3),
                                                topRight: Radius.circular(3),
                                              )
                                            ),
                                            child: Text(S.current.listChannel, style: TextStyle(color: isDark ? Colors.white :  const Color(0xff3D3D3D), fontWeight: FontWeight.w500, fontSize: 14))
                                          ),
                                          Expanded(
                                            child: Container(
                                              decoration: isDark ? null : BoxDecoration(
                                                border: Border(top: isDark ? BorderSide.none : const BorderSide(color: Color(0xffC9C9C9))),
                                              ),
                                              child: ListView.builder(
                                                padding: const EdgeInsets.symmetric(vertical: 4),
                                                itemCount: channelsFilter.length,
                                                controller: ScrollController(),
                                                itemBuilder: (context, index) {
                                                  int indexWorkspace = dataWorkspaces.indexWhere((ele) => ele['id'] == channelsFilter[index]['workspace_id']);
                                                  if (indexWorkspace == -1) {
                                                    return Container();
                                                  }
                                                  return InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        destination = {
                                                          'id': channelsFilter[index]['id'],
                                                          'isChannel': true,
                                                          'workspace_id': channelsFilter[index]['workspace_id'],
                                                          'name': channelsFilter[index]['name'],
                                                        };
                                                        isShow = false;
                                                      });
                                                      // FocusScope.of(context).unfocus();
                                                    },
                                                    child: HoverItem(
                                                      colorHover: Palette.hoverColorDefault,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                        child: Row(
                                                          children: [
                                                            channelsFilter[index]['is_private']
                                                              ? SvgPicture.asset('assets/icons/Locked.svg', color: isDark ? const Color(0xffDBDBDB) : const Color(0xff3D3D3D))
                                                              : SvgPicture.asset('assets/icons/iconNumber.svg', width: 13, color: isDark ? const Color(0xffDBDBDB) : const Color(0xff3D3D3D)),
                                                            const SizedBox(width: 8),
                                                            Text(channelsFilter[index]['name'], overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? const Color(0xffDBDBDB) : const Color(0xff3D3D3D), fontSize: 14,),),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ) : Container(
                            height: 370,
                            child: ListView.builder(
                              itemCount: resultMembersSearch.length,
                              itemBuilder: (context, index) {
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      destination = {
                                        'id': resultMembersSearch[index]['id'] ?? resultMembersSearch[index]['conversation_id'],
                                        'isChannel': resultMembersSearch[index]['workspace_id'] != null,
                                        'workspace_id': resultMembersSearch[index]['workspace_id'],
                                        'name': resultMembersSearch[index]['name'],
                                        'avatar_url': resultMembersSearch[index]['avatar_url']
                                      };
                                      isShow = false;
                                    });
                                    FocusScope.of(context).unfocus();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: index == resultMembersSearch.length - 1 ? Colors.transparent : Colors.grey[500]!, width: 0.2),
                                        top: BorderSide(color: index == 0 ? Colors.transparent : Colors.grey[500]!, width: 0.2)
                                      )
                                    ),
                                    child: Row(
                                      children: [
                                        CachedAvatar(
                                          resultMembersSearch[index]['avatar_url'],
                                          height: 32, width: 32, radius: 16,
                                          isRound: true,
                                          name: resultMembersSearch[index]["name"],
                                          isAvatar: true
                                        ),
                                        const SizedBox(width: 8),
                                        Text(resultMembersSearch[index]['name'] ?? '')
                                      ],
                                    )
                                  ),
                                );
                              }
                            ),
                          ),
                        ],
                      ),
                    ),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      child: FocusScope(
                        onFocusChange: (value) => setState(() => isShow = value),
                        child: TextFormField(
                          onChanged: (value) {
                            if (_debounce?.isActive ?? false) _debounce.cancel();
                            _debounce = Timer(const Duration(milliseconds: 500), ()async {
                              search(value, auth.token);
                            });
                          },
                          onTap: () {
                            search('', auth.token);
                          },
                          controller: controller,
                          decoration: InputDecoration(
                            hoverColor: isDark ?Color(0xff5E5E5E) : Color(0xffEDEDED),
                            hintText: S.current.searchType(type == SEARCH.CHANNEL ? "Channels" : "Direct"),
                            contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                            filled: true,
                            fillColor: isDark ? Color(0xFF353535) : Color(0xffFAFAFA),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9)),
                              borderRadius: BorderRadius.all(Radius.circular(4))),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9)),
                              borderRadius: BorderRadius.all(Radius.circular(4)))
                          ),
                        ),
                      ),
                    ),
                  ),
                  destination != null
                    ? Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                      child: Row(
                        children: [
                          destination['isChannel'] ? Container(
                            child: Text(
                              destination['name'], overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: isDark ? const Color(0xffDBDBDB) : const Color(0xff3D3D3D), fontSize: 14,)
                            ),
                          ) : Row(
                            children: [
                              CachedAvatar(
                                destination['avatar_url'],
                                height: 20, width: 20, radius: 10,
                                isRound: true,
                                name: destination["name"],
                                isAvatar: true
                              ),
                              const SizedBox(width: 8),
                              Text(destination['name']),
                            ],
                          ),
                          SizedBox(width: 8),
                          InkWell(
                            child: Icon(
                              PhosphorIcons.xCircle, size: 16,
                            ),
                            onTap: () {
                              setState(() => destination = null);
                            },
                          )
                        ],
                      )
                    ) : SizedBox(height: 20),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: isDark ? Palette.backgroundTheardDark : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: isDark ? Border() : Border.all(
                        color: Color(0xffA6A6A6), width: 0.5
                      ),
                    ),
                    child: FlutterMentions(
                      key: key,
                      parseMention: Provider.of<Messages>(context, listen: false).checkMentions,
                      style: TextStyle(fontSize: 15.5, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                      cursorColor: isDark ? Colors.grey[400]! : Colors.black87,
                      autofocus: true,
                      isUpdate: false,
                      isShowCommand: false,
                      isIssues: true,
                      isDark: isDark,
                      islastEdited: false,
                      minLines: 1, maxLines: 4,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.only(left: 10, bottom: 10, top: 16),
                        hintText: S.current.typeMessage,
                        hintStyle: TextStyle(color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65), fontSize: 13.5, height: 1)
                      ),
                      isCodeBlock: false,
                      handleCodeBlock: () {},
                      suggestionListDecoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      onSearchChanged: (trigger, value) { },
                      mentions: [
                        Mention(
                          markupBuilder: (trigger, mention, value, type) {
                            return "=======@/$mention^^^^^$value^^^^^$type+++++++";
                          },
                          trigger: '@',
                          style: TextStyle(
                            color: Colors.lightBlue,
                          ),
                          data: getSuggestionMentions(),
                          matchAll: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
                        borderRadius: BorderRadius.all(Radius.circular(5))
                      ),
                      child: Container(
                        padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: Color(0xffd0d0d0),
                              width: 4.0,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: Row(
                                children: [
                                  Icon(CupertinoIcons.arrowshape_turn_up_left_fill, color: isDark ? Color(0xffA6A6A6) : Color(0xff828282), size: 17),
                                  SizedBox(width: 5,),
                                  Text(S.current.shareMessage, style: TextStyle(fontStyle: FontStyle.italic)),
                                ],
                              ),
                            ),
                            SizedBox(height: 5),
                            Container(
                              child: Row(
                                children: [
                                  CachedAvatar(
                                    widget.message["avatarUrl"],
                                    height: 20, width: 20,
                                    isRound: true,
                                    name: widget.message["fullName"],
                                    isAvatar: true,
                                    fontSize: 13,
                                  ),
                                  SizedBox(width: 5),
                                  Text(widget.message["fullName"])
                                ],
                              ),
                            ),
                            SizedBox(height: 5),
                            Utils.checkedTypeEmpty(widget.message["isUnsent"])
                              ? Container(
                                height: 19,
                                child: Text(
                                  S.current.thisMessageDeleted,
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Color(isDark ? 0xffe8e8e8 : 0xff898989)
                                  ),
                                )
                              )
                              : (widget.message["message"] != "" && widget.message["message"] != null)
                                ? Container(
                                  padding: EdgeInsets.only(left: 3),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(widget.message["message"]),
                                      widget.message["attachments"] != null && widget.message["attachments"].length > 0
                                        ? Text("Attachments")
                                        // ? AttachmentCardDesktop(attachments: widget.message["attachments"], isChannel: widget.message["isChannel"], id: widget.message["id"], isChildMessage: false, isThread: widget.message["isThread"], lastEditedAt: parseTime(widget.message["lastEditedAt"]))
                                        : Container()
                                    ],
                                  ),
                                )
                                : widget.message["attachments"] != null && widget.message["attachments"].length > 0
                                  ? Container(
                                    padding: EdgeInsets.only(left: 3),
                                    child: Text(
                                      Utils.checkedTypeEmpty(widget.message["message"])
                                        ? widget.message["message"]
                                        : widget.message["attachments"][0]["type"] == "mention"
                                            ? renderTextMention(widget.message["attachments"][0], isDark)
                                            : widget.message["attachments"][0]["mime_type"] == "image"
                                                ? widget.message["attachments"][0]["name"]
                                                : "Parent message",
                                    )
                                  ) : Container(),
                          ],
                        )
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                HoverItem(
                  colorHover: Color(0xffFF7875).withOpacity(0.2),
                  child: TextButton(
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(width: 1, color: Colors.red, style: BorderStyle.solid)
                        ),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child:Text(S.current.cancel, style: TextStyle(color: Colors.red))
                  ),
                ),
                SizedBox(width: 7),
                HoverItem(
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.blue),
                      overlayColor: MaterialStateProperty.all(Colors.blue[400]),
                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(width: 1, color: Colors.blue, style: BorderStyle.solid)
                        ),
                      ),
                    ),
                    onPressed: destination != null ?  sendForwardMessage : null,
                    child: Text(S.current.forwardMessage, style: TextStyle(color: Colors.white))
                  ),
                ),
              ],
            )
          )
        ],
      ),
    );
  }
}
