import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/search_modal.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/flutter_mention/custom_selection.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/providers/providers.dart';

class SearchBarNavigation extends StatefulWidget {
  const SearchBarNavigation({Key? key, required this.tab}) : super(key: key);

  final int tab;

  @override
  _SearchBarNavigationState createState() => _SearchBarNavigationState();
}

class _SearchBarNavigationState extends State<SearchBarNavigation> {
  final TextEditingController _searchQuery = TextEditingController();
  ValueNotifier<bool> showSuggestions = ValueNotifier(false);
  ValueNotifier<bool> _loadingListenable = ValueNotifier(true);
  FocusNode focusNode = FocusNode();
  var _debounce;

  List _allContact = [];
  List _contacts = [];
  List _channels = [];
  List _dataMessageAll = [];
  List _dataSearch = [];
  int _totalPage = 0;
  SearchMode searchMode = SearchMode.DEFAULT;
  bool _isHover = false;
  FocusScopeNode _focusScopeNode = FocusScopeNode();

  Box? _localSearch;

  @override
  void initState() {
    super.initState();
    _getInitData();
    _initLocalBox();
    RawKeyboard.instance.addListener(_handleKey);
    RawKeyboard.instance.addListener(_keyboardListener);
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab != oldWidget.tab) _getInitData();
  }

  _initLocalBox() async {
    _localSearch = await Hive.openBox("localSearch");
  }

  _saveLocalSearch(stringSearch, {where}) {
    final currentUserId = Provider.of<User>(context, listen: false).currentUser["id"];
    List _listSearch = _localSearch?.get(currentUserId, defaultValue: []);
    if (_listSearch.length > 10)
      for (int i = 0 ; i < _listSearch.length; i ++) {
        if (i == _listSearch.length - 1) {
          _listSearch.removeAt(i);
        }
      }
    _listSearch.insert(0, {
      where["type"]: where['where'],
      'text': stringSearch
    });
    _localSearch?.put(currentUserId, _listSearch);
  }

  List _getLocalSearch() {
    final currentUserId = Provider.of<User>(context, listen: false).currentUser["id"];
    if (_localSearch == null) return [];
    return _localSearch!.get(currentUserId) ?? [];
  }

  _handleKey(RawKeyEvent keyEvent) {
    final hotKeyPressed =
        Platform.isMacOS ? keyEvent.isMetaPressed : keyEvent.isControlPressed;
    final keyDrawer = Provider.of<Auth>(context, listen: false).keyDrawer;

    if (keyEvent is RawKeyDownEvent) {
      if (hotKeyPressed &&
          (!Navigator.of(context).canPop() ||
              (keyDrawer.currentState != null &&
                  keyDrawer.currentState!.isEndDrawerOpen))) {
        if (keyEvent.isKeyPressed(LogicalKeyboardKey.keyF)) {
          showSuggestions.value = true;
          Provider.of<Windows>(context, listen: false).openSearchbar = true;
          focusNode.requestFocus();
          setState(() => searchMode = SearchMode.DEFAULT);
        } else if (keyEvent.isKeyPressed(LogicalKeyboardKey.keyT)) {
          showSuggestions.value = true;
          Provider.of<Windows>(context, listen: false).openSearchbar = true;
          focusNode.requestFocus();
          setState(() => searchMode = SearchMode.ANY);
        }
        return KeyEventResult.handled;
      } else if (keyEvent.isKeyPressed(LogicalKeyboardKey.escape)) {
        showSuggestions.value = false;
      }
    }
    return KeyEventResult.ignored;
  }

  _keyboardListener(RawKeyEvent event) {
    final keyId = event.logicalKey.keyId;
    bool openSearchbar =
        Provider.of<Windows>(context, listen: false).openSearchbar;

    if (event is RawKeyDownEvent) {
      if (event.isMetaPressed) {
        if (keyId.clamp(32, 126) == keyId) {
          return KeyEventResult.handled;
        }
      } else if (mounted && keyId.clamp(32, 126) == keyId && openSearchbar) {
        focusNode.requestFocus();
      }
    }
    return KeyEventResult.ignored;
  }

  _getInitData() {
    final directmodels =
        Provider.of<DirectMessage>(context, listen: false).data;
    final currentUserId =
        Provider.of<User>(context, listen: false).currentUser["id"];
    List conversationInfo = directmodels.map((e) {
      var users = e.user.length > 1
          ? e.user.where((item) => item["user_id"] != currentUserId).toList()
          : e.user;

      return {
        "user_id": users[0]["user_id"],
        "conversation_id": users[0]["conversation_id"],
        "name": e.displayName,
        "avatar_url": users[0]["avatar_url"] ?? "",
        "is_online": users[0]["is_online"],
        "members": users.length
      };
    }).toList();

    setState(() {
      _allContact = conversationInfo;
      searchMode = SearchMode.DEFAULT;
      _contacts.clear();
      _channels.clear();
      _dataMessageAll.clear();
      _dataSearch.clear();
      _searchQuery.clear();
    });
  }

  @override
  void dispose() {
    _searchQuery.dispose();
    RawKeyboard.instance.removeListener(_handleKey);
    RawKeyboard.instance.removeListener(_keyboardListener);
    super.dispose();
  }

  _getMembersWorkspace(value) async {
    final token = Provider.of<Auth>(context, listen: false).token;

    try {
      var url =
          Utils.apiUrl + "workspaces/search_users?token=$token&value=$value";

      var response = await Dio().get(url);

      return (response.data)["members"];
    } catch (e) {
      print(e);
      return [];
    }
  }

  _searchContact(value) async {
    var membersWorkspaces = await _getMembersWorkspace(value);
    var contactLocal = _allContact
        .where((element) => Utils.unSignVietnamese(element["name"])
            .contains(Utils.unSignVietnamese(value)))
        .toList();
    var idContactLocal = contactLocal.map((e) => e["user_id"]).toList();

    for (int i = 0; i < membersWorkspaces.length; i++) {
      var isExist = (idContactLocal).indexOf(membersWorkspaces[i]["id"]);

      if (isExist == -1) {
        contactLocal.add(membersWorkspaces[i]);
      }
    }
    return contactLocal;
  }

  _searchChannel(value, searchMode) {
    final tab = Provider.of<Workspaces>(context, listen: false).tab;
    var result = [];
    List listChannel = Provider.of<Channels>(context, listen: false).data;
    result = listChannel
        .where((e) => e["name"].toLowerCase().contains(value))
        .toList();
    if (searchMode == SearchMode.DEFAULT) {
      result = result.where((e) => e["workspace_id"] == tab).toList();
    }
    return result;
  }

  _onSelectDirectMessages(directId, {Map? message}) async {
    final auth = Provider.of<Auth>(context, listen: false);
    var hasConv = await Provider.of<DirectMessage>(context, listen: false)
        .getInfoDirectMessage(auth.token, directId);
    if (hasConv) {
      DirectModel? model = Provider.of<DirectMessage>(context, listen: false)
          .getModelConversation(directId);
      if (model == null) return;
      if (message != null) {
        if (!Utils.checkedTypeEmpty(message["parent_id"])) {
          Provider.of<Workspaces>(context, listen: false).tab = 0;
          await Provider.of<DirectMessage>(context, listen: false)
              .processDataMessageToJump(message, auth.token, auth.userId);
        } else {
          //
          var messageOnIsar =
              await MessageConversationServices.getListMessageById(
                  message["parent_id"], directId);
          final directMessageSelected =
              Provider.of<DirectMessage>(context, listen: false)
                  .getModelConversation(directId);
          if (directMessageSelected == null) return;
          List users = directMessageSelected.user;
          final indexUser =
              users.indexWhere((e) => e["user_id"] == message["user_id"]);

          if (indexUser != -1 && messageOnIsar != null) {
            final user = users[indexUser];
            Map parentMessage = {
              "id": messageOnIsar["id"],
              "message": messageOnIsar["message"],
              "avatarUrl": user["avatar_url"],
              "insertedAt": messageOnIsar["time_create"],
              "fullName": user["full_name"],
              "attachments": messageOnIsar["attachments"],
              "userId": messageOnIsar["user_id"],
              "conversationId": directId,
              "isChannel": false,
              "current_time": messageOnIsar["current_time"],
              "idMessageToJump": message["id"]
            };
            Provider.of<Channels>(context, listen: false)
                .openChannelSetting(false);
            await Provider.of<Messages>(context, listen: false)
                .openThreadMessage(true, parentMessage);
          }
        }
      } else {
        await Provider.of<DirectMessage>(context, listen: false)
            .onChangeSelectedFriend(false);
        await auth.channel
            .push(event: "join_direct", payload: {"direct_id": directId});
        await Provider.of<DirectMessage>(context, listen: false)
            .setSelectedDM(model, auth.token);
      }
    } else {}
  }

  _onSelectMessage(Map message) async {
    final token = Provider.of<Auth>(context, listen: false).token;
    if (!Utils.checkedTypeEmpty(message["channel_thread_id"])) {
      Provider.of<Messages>(context, listen: false)
          .handleProcessMessageToJump(message, Utils.globalContext);
    } else {
      int workspaceId = message["workspace_id"];
      int channelId = message["channel_id"];
      final url = Utils.apiUrl +
          'workspaces/$workspaceId/channels/$channelId/messages/thread?message_id=${message["channel_thread_id"]}&token=$token';
      final response = await Dio().get(url);
      Map parentMessage = response.data["parent_message"] ?? {};
      Map parentMessageData = {
        "id": parentMessage["id"],
        "channelId": channelId,
        "workspaceId": workspaceId,
        "userId": parentMessage["user_id"],
        "fullName": parentMessage["fullName"],
        "avatarUrl": parentMessage["avatarUrl"],
        "isChannel": true,
        "attachments": parentMessage["attachments"],
        "insertedAt": message["inserted_at"],
        "message": parentMessage["message"],
        "current_time": parentMessage["current_time"],
        "idMessageToJump": message["id"]
      };
      Provider.of<Messages>(context, listen: false)
          .openThreadMessage(true, parentMessageData);
      await Provider.of<Threads>(context, listen: false)
          .updateThreadUnread(workspaceId, channelId, parentMessageData, token);
    }
  }

  _onSearchChanged(searchMode) {
    final token = Provider.of<Auth>(context, listen: false).token;

    if (_searchQuery.text.trim() == "") {
      setState(() {
        _dataSearch = [];
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce.cancel();
    _loadingListenable.value = true;
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _search(_searchQuery.text, token, searchMode).then((dataSearch) {
        setState(() {
          _dataSearch = dataSearch;
        });
        _loadingListenable.value = false;
      });
    });
  }

  Future<List> _search(value, token, searchMode,
      {offset = 0, loadMore = false}) async {
    _contacts = await _searchContact(value);
    _channels = _searchChannel(value, searchMode);
    _dataMessageAll = await _searchMessage(token, value, offset, loadMore);
    // _dataMessageAll.forEach((element) {print(element);});
    final __contacts = _contacts.map((e) => {"type": 1, "contact": e}).toList();
    final ___channels = _channels.map((e) => {"type": 2, "channel": e}).toList();
    final ___dataMessageAll =
        _dataMessageAll.map((e) => {"type": 3, "message": e}).toList();

    return __contacts + ___channels + ___dataMessageAll;
  }

  _goDirectMessage(user) async {
    var currentUser = Provider.of<User>(context, listen: false).currentUser;
    var convId = user["conversation_id"];
    if (convId == null) {
      convId = MessageConversationServices.shaString(
          [currentUser["id"], user["user_id"] ?? user["id"]]);
    }

    bool hasConv = await Provider.of<DirectMessage>(context, listen: false)
        .getInfoDirectMessage(
            Provider.of<Auth>(context, listen: false).token, convId);
    var dm;
    if (hasConv) {
      dm = Provider.of<DirectMessage>(context, listen: false)
          .getModelConversation(convId);
    } else {
      dm = DirectModel(
          "",
          [
            {
              "user_id": currentUser["id"],
              "full_name": currentUser["full_name"],
              "avatar_url": currentUser["avatar_url"],
              "is_online": true
            },
            {
              "user_id": user["user_id"] ?? user["id"],
              "avatar_url": user["avatar_url"],
              "full_name": user["full_name"] ?? user["name"],
              "is_online": user["is_online"]
            }
          ],
          "",
          false,
          0,
          {},
          false,
          0,
          {},
          user["full_name"] ?? user["name"],
          null);
    }
    Provider.of<Workspaces>(context, listen: false).setTab(0);
    Provider.of<DirectMessage>(context, listen: false).setSelectedDM(dm, "");
  }

  _onSelectChannel(channelId, workspaceId) async {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    Provider.of<Workspaces>(context, listen: false).setTab(workspaceId);
    Provider.of<Workspaces>(context, listen: false)
        .selectWorkspace(auth.token, workspaceId, context);
    Provider.of<User>(context, listen: false).selectTab("channel");
    await Provider.of<Channels>(context, listen: false)
        .setCurrentChannel(channelId);
    Provider.of<Messages>(context, listen: false)
        .loadMessages(auth.token, workspaceId, channelId);
    await Provider.of<Channels>(context, listen: false)
        .selectChannel(auth.token, workspaceId, channelId);
    Provider.of<Channels>(context, listen: false)
        .loadCommandChannel(auth.token, workspaceId, channelId);
    Provider.of<Channels>(context, listen: false).getChannelMemberInfo(
        auth.token, workspaceId, channelId, currentUser["id"]);
    Provider.of<Workspaces>(context, listen: false)
        .clearMentionWhenClickChannel(workspaceId, channelId);

    auth.channel.push(
        event: "join_channel",
        payload: {"channel_id": channelId, "workspace_id": workspaceId});

    if (Platform.isMacOS) Utils.updateBadge(context);
  }

  _searchMessage(token, value, offset, loadMore, {channelIds, userIds, date}) async {
    final tab = Provider.of<Workspaces>(context, listen: false).tab;
    List _workspaces = [];
    List _messages = [];
    if (tab != 0 && searchMode == SearchMode.DEFAULT) {
      String url =
          "${Utils.apiUrl}/workspaces/$tab/search_message?token=$token";
      try {
        var response = await Dio().post(url, data: json.encode({
          "term": value,
          "offset": offset,
          "filter": {
            "user_ids": userIds,
            "channel_ids": channelIds,
            "date": date
          }
        }));
        var dataRes = response.data;

        if (dataRes["success"]) {
          _workspaces = dataRes["result"];
          _totalPage = dataRes["total"];
        }
      } catch (e) {
        print(e);
      }
    } else {
      List data = await MessageConversationServices.searchMessage(value, userIds: userIds,
          parseJson: true, date: date, limit: 40, offset: offset);

      _messages = data;

      if (searchMode == SearchMode.ANY) {
        String url = "${Utils.apiUrl}search_all?token=$token";
        try {
          final List workspaceIds =
              Provider.of<Workspaces>(context, listen: false)
                  .data
                  .map((e) => e['id'])
                  .toList();
          final List channelIds = Provider.of<Channels>(context, listen: false)
              .data
              .map((e) => e['id'])
              .toList();

          var response = await Dio().post(url, data: {
            "term": value,
            "offset": offset,
            'workspace_ids': workspaceIds,
            "filter": {
              "user_ids": userIds,
              "channel_ids": channelIds,
              "date": date
            }
          });
          var dataRes = response.data;
          if (dataRes["success"]) {
            _workspaces = dataRes["result"];
          }
        } catch (e) {
          print(e);
        }
      }
      _totalPage = _workspaces.length + _messages.length;
    }

    bool needSort = _workspaces.isNotEmpty && _messages.isNotEmpty;

    final dataMessageAll = _workspaces + _messages;
    if (needSort) {
      dataMessageAll.sort((a, b) {
        var timeA = a["time_create"] != null
            ? a["time_create"] == ""
                ? "1900-01-01T00:00:00"
                : a["time_create"]
            : a["_source"]["inserted_at"] != null
                ? a["_source"]["inserted_at"] == ""
                    ? a["_source"]["inserted_at"]
                    : "1900-01-01T00:00:00"
                : "1900-01-01T00:00:00";
        var timeB = b["time_create"] != null
            ? b["time_create"] == ""
                ? "1900-01-01T00:00:00"
                : b["time_create"]
            : b["_source"]["inserted_at"] != null
                ? b["_source"]["inserted_at"] == ""
                    ? b["_source"]["inserted_at"]
                    : "1900-01-01T00:00:00"
                : "1900-01-01T00:00:00";

        return DateTime.parse(timeA).compareTo(DateTime.parse(timeB));
      });
    }
    // dataMessageAll.forEach((element) {
    //   final index = _allContact.indexWhere((e) => e["conversation_id"] == element["conversation_id"]);
    //   print(_allContact[index]["name"]);
    // });
    return dataMessageAll;
  }

  _clearSearch() {
    _searchQuery.clear();
    showSuggestions.value = false;
    _dataSearch = [];
  }

  @override
  Widget build(BuildContext context) {
    final tab = Provider.of<Workspaces>(context, listen: false).tab;
    final listChannel = Provider.of<Channels>(context, listen: false).data;
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final String hotKey = Platform.isMacOS ? 'Cmd' : 'Ctrl';
    final deviceWidth = MediaQuery.of(context).size.width;
    final currentWorkspace = Provider.of<Workspaces>(context).currentWorkspace;

    Widget _searchBox = Container(
      constraints: const BoxConstraints(maxWidth: 1000, minWidth: 500),
      margin: const EdgeInsets.only(top: 7.0, bottom: 6.0),
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          color: const Color(0xff2E2E2E),
          boxShadow: [
            if (_isHover) const BoxShadow(color: Colors.white, blurRadius: 1)
          ]),
      width: deviceWidth / 2,
      child: InkWell(
        onTap: () {
          setState(() {
            showSuggestions.value = true;
            Provider.of<Windows>(context, listen: false).openSearchbar = true;
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.86),
              padding: const EdgeInsets.only(left: 4),
              child: SvgPicture.asset('assets/icons/search.svg'),
              height: double.infinity,
            ),
            Text(
              S.current.searchAnything(hotKey),
              style: const TextStyle(
                  color: Color(0xffA6A6A6),
                  fontSize: 14,
                  fontWeight: FontWeight.w300),
            )
          ],
        ),
      ),
    );

    Widget _columnSearchItems = Expanded(
          child: _dataSearch.isNotEmpty
              ? ListView.builder(
                  itemCount: _dataSearch.length < 6 ? _dataSearch.length : 6,
                  itemBuilder: (context, index) {
                    switch (_dataSearch[index]["type"]) {
                      case 1:
                        return SearchContactItem(
                          contact: _dataSearch[index]["contact"],
                          onSelectContact: (contact) {
                            _saveLocalSearch(_searchQuery.text, where: {
                              'type': 'contact', 
                              'where': contact['name'] ?? contact['full_name']}
                            );
                            _goDirectMessage(contact);
                            _clearSearch();
                          },
                        );
                      case 2:
                        return SearchChannelItem(
                          channel: _dataSearch[index]["channel"],
                          onSelectChannel: (channelId, workspaceId) {
                            _saveLocalSearch(_searchQuery.text, where: {
                              'type': 'channel', 
                              'where': {
                                'name': _dataSearch[index]["channel"]["name"], 
                                'isPrivate': _dataSearch[index]["channel"]['is_private']
                              }
                            });
                            _onSelectChannel(channelId, workspaceId);
                            _clearSearch();
                          },
                        );
                      case 3:
                        final message = _dataSearch[index]["message"];
                        final isDirectMessage = message["time_create"] != null;
                        final isChannelMessage = message["_source"] != null;

                        return SearchMessageItem(
                          message: message,
                          isDirectMessage: isDirectMessage,
                          isChannelMessage: isChannelMessage,
                          allContact: _allContact,
                          listChannel: listChannel,
                          onSelectMessage: (message, isDirectMessage, isChannelMessage) {
                            if (isDirectMessage) {
                              _saveLocalSearch(_searchQuery.text, where: {
                                'type': 'directMessage', 
                                'where': {'conversationId': message['conversation_id']}
                              });
                              _onSelectDirectMessages(
                                message["conversation_id"],
                                message: message
                              );
                            } else if (isChannelMessage) {
                              _saveLocalSearch(_searchQuery.text, where: {
                                'type': 'channelMessage', 
                                'where': {'channelId': message["_source"]["channel_id"], 
                                'workspaceId': message["_source"]["workspace_id"]}
                              });
                              _onSelectMessage({
                                ...message["_source"],
                                "avatarUrl": message["_source"]["avatar_url"] ?? "",
                                "fullName": message["_source"]["full_name"] ?? "",
                                "workspace_id": message["_source"]["workspace_id"],
                                "channel_id": message["_source"]["channel_id"]
                              });
                            }
                            _clearSearch();
                          }
                        );
                      default:
                        return Container();
                    }
                  })
              : Container(),
        );

        Widget _recentSearch = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 15,),
              Text('Recent Searches', style: TextStyle(color: Colors.grey),),
              SizedBox(height: 8.0),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: 150
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._getLocalSearch().map((e) {
                          final type = e.keys.first;
                          final where = e.values.first;
                          final text = e['text'];
                          Widget recentItem() {
                            if (type == 'contact') {
                              return Row(
                                children: [
                                  Container(
                                    alignment: Alignment.center, 
                                    padding: EdgeInsets.all(4), 
                                    decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(5)), 
                                    child: Text('user:${where.toString()}')
                                  ),
                                  SizedBox(width: 10,),
                                  Text("${text.toString()}"),
                                ],
                              );
                            }
                            else if (type == 'channel') {
                              return Row(
                                children: [
                                  Container(
                                    alignment: Alignment.center, 
                                    padding: EdgeInsets.all(4), 
                                    decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(5)), 
                                    child: Row(
                                      children: [
                                        where['isPrivate'] ? SvgPicture.asset('assets/icons/Locked.svg')
                                                          : SvgPicture.asset('assets/icons/iconNumber.svg', width: 13, color: Colors.white),
                                                          SizedBox(width: 3),
                                        Text('${where['name']}')
                                      ],
                                    )
                                  ),
                                  SizedBox(width: 10),
                                  Text('${text.toString()}')
                                ],
                              );
                            }
                            else if (type == 'directMessage') {
                              final conversationName = _getConversationName(where['conversationId']);
                              return Row(
                                children: [
                                  Container(
                                    alignment: Alignment.center, 
                                    padding: EdgeInsets.all(4), 
                                    decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(5)), 
                                    child: Text('in-direct:$conversationName')
                                  ),
                                  SizedBox(width: 10),
                                  Text('${text.toString()}')
                                ],
                              );
                            }
                            else if (type == 'channelMessage') {
                              final channelName = _getChannel(where['channelId'], where['workspaceId'])['name'] ?? "";
                              final isPrivate = _getChannel(where['channelId'], where['workspaceId'])['is_private'] ?? false;
                              return Row(
                                children: [
                                  Container(
                                    alignment: Alignment.center, 
                                    padding: EdgeInsets.all(4), 
                                    decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(5)), 
                                    child: Row(
                                      children: [
                                        Text("in-channel:"),
                                        isPrivate ? SvgPicture.asset('assets/icons/Locked.svg')
                                                          : SvgPicture.asset('assets/icons/iconNumber.svg', width: 13, color: Colors.white),
                                                          SizedBox(width: 3),
                                        Text('$channelName')
                                      ],
                                    )
                                  ),
                                  SizedBox(width: 10),
                                  Text('${text.toString()}')
                                ],
                              );
                            }
                            return Text(text.toString());
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.time, size: 14),
                                SizedBox(width: 10),
                                DefaultTextStyle(
                                  style:  TextStyle(color: isDark ? Colors.white70 : Colors.black) ,
                                  child: CustomSelectionArea(child: recentItem())
                                )
                              ],
                            ),
                          );
                        })
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        );

        Widget _portalTable = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          _textFormFieldSearch(
              currentWorkspace: currentWorkspace, tab: tab, isDark: isDark),
          Divider(color: Colors.white.withOpacity(0.3), height: 0.5),
          SizedBox(height: 8),
          _recentSearch,
          _columnSearchItems
        ]);

    Widget _searchPortal = FocusScope(
      node: _focusScopeNode,
      onKey: (focusNode, rawKeyEvent) {
        if (rawKeyEvent.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
          _focusScopeNode.nextFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      onFocusChange: (value) {
        showSuggestions.value = value;
        if (!value)
          Provider.of<Windows>(context, listen: false).openSearchbar =
              false;
      },
      child: Container(
          width: deviceWidth / 2 + 10,
          padding: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xff353535) /*Color(0xff262626)*/ : Palette
                      .backgroundTheardLight,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.099),
                    blurRadius: 20.0)
              ]),
          constraints: const BoxConstraints(
              maxWidth: 1000, minWidth: 630, maxHeight: 600),
          child: _portalTable),
    );

    return MouseRegion(
      onEnter: (event) {
        setState(() {
          _isHover = true;
        });
      },
      onExit: (event) {
        setState(() {
          _isHover = false;
        });
      },
      child: ValueListenableBuilder(
        valueListenable: showSuggestions,
        builder: (context, show, child) {
          return Barrier(
            visible: showSuggestions.value,
            onClose: () {
              showSuggestions.value = false;
              Provider.of<Windows>(context, listen: false).openSearchbar = false;
            },
            child: PortalTarget(
              visible: showSuggestions.value,
              anchor: Aligned(
                target: Alignment.topCenter,
                follower: Alignment.topCenter
              ),
              child: _searchBox,
              portalFollower: _searchPortal,
            ),
          );
        }
      ),
    );
  }

  Widget _textFormFieldSearch({currentWorkspace, tab, isDark}) {
    final token = Provider.of<Auth>(context, listen: false).token;
    return TextFormField(
      onFieldSubmitted: (searchString) {
        showModal(
          context: context,
          builder: (context) {
            return ValueListenableBuilder<bool>(
              valueListenable: _loadingListenable,
              builder: (context, loading, child) {
                return loading 
                ? AlertDialog(
                  content: SizedBox(
                    height: 100,
                    child: SpinKitFadingCube(color: isDark ? Colors.white : Colors.grey[600]!, size: 18)
                  ),
                )
                : SearchModal(
                  onReloadSearch: (SearchModalState state, loadMore, offsetMessage, userIds, channelIds, date) async {
                    final _reloadDataMessage = await _reloadDataMessageSearch(token, searchString, loadMore, offsetMessage, userIds, channelIds, date);
                    // state.messages = loadMore ? state.messages + _reloadDataMessage : _reloadDataMessage;
                    state.messages = _reloadDataMessage["data"];
                    state.totalMessage = _reloadDataMessage["totalMessage"];
                    state.setState(() {
                      state.loading = false;
                    });
                  },
                  totalMessage: _totalPage,
                  messages: _dataMessageAll,
                  contacts: _contacts,
                  channels: _channels,
                  textSearch: searchString,
                  onSelect: (type, data) {
                    switch (type) {
                      case 1:
                        _goDirectMessage(data);
                        break;
                      case 2:
                        final channelId = data["channelId"];
                        final workspaceId = data["workspaceId"];
                        _onSelectChannel(channelId, workspaceId);
                        break;
                      case 3:
                        final message = data["message"];
                        final isDirectMessage = data["isDirectMessage"];
                        final isChannelMessage = data["isChannelMessage"];
                        if (isDirectMessage) {
                          _onSelectDirectMessages(
                            message["conversation_id"],
                            message: message
                          );
                        } else if (isChannelMessage) {
                          _onSelectMessage({
                            ...message["_source"],
                            "avatarUrl": message["_source"]["avatar_url"] ?? "",
                            "fullName": message["_source"]["full_name"] ?? "",
                            "workspace_id": message["_source"]["workspace_id"],
                            "channel_id": message["_source"]["channel_id"]
                          });
                        }
                        break;
                      default:
                    }
                    _clearSearch();
                    Navigator.pop(context);
                  }
                );
              }
            );
          }
        );
        _saveLocalSearch(searchString, where: {'type': 'typing', 'where': ''});
      },
      autofocus: true,
      cursorWidth: 1.0,
      cursorHeight: 14,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
          constraints: const BoxConstraints(maxHeight: 38),
          hintText: searchMode == SearchMode.ANY 
                      ? S.current.descSearchAll : tab == 0
                      ? S.current.desSearch : S.current.descSearchInCtWs(currentWorkspace["name"] ?? ""),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          hintStyle: const TextStyle(
              color: Color(0xffA6A6A6),
              fontSize: 14,
              fontWeight: FontWeight.w300
          ),
          border: InputBorder.none,
          suffixIcon: _searchQuery.text.isNotEmpty
              ? MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _clearSearch,
                    child: const Icon(Icons.close,
                        size: 14, color: Color(0xffA6A6A6)),
                  ),
                )
              : const SizedBox(width: 15),
          prefixIcon: SvgPicture.asset(
            'assets/icons/search.svg',
            width: 20,
            height: 20,
            fit: BoxFit.none,
          )),
      focusNode: focusNode,
      style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black, fontSize: 14),
      controller: _searchQuery,
      onChanged: (value) {
        _onSearchChanged(searchMode);
        // showSuggestions.value = Utils.checkedTypeEmpty(value);
      },
    );
  }

  _reloadDataMessageSearch(token, value, loadMore, offsetMessage, userIds, channelIds, date) async {
    List _researchResult = await _searchMessage(token, value, offsetMessage, loadMore, channelIds: channelIds, userIds: userIds, date: date);

    return {
      "data": _researchResult,
      "totalMessage": _totalPage
    };
  }

  String _getConversationName(id) {
    if (_allContact.isEmpty) return "";
    final index = _allContact.indexWhere((element) => element["conversation_id"] == id);
    if (index != -1) return _allContact[index]["name"];
    return "";
  }

  Map _getChannel(channelId, workspaceId){
    final channels = Provider.of<Channels>(context, listen: false).data;
    final index = channels.indexWhere((element) => element['id'] == channelId && element['workspace_id'] == workspaceId);
    if (index != -1) return channels[index];
    return {};
  }

  // List _mergeMessages(List dataSearch, researchResult) {
  //   return [];
  // }
}

class RandomQuote extends StatefulWidget {
  const RandomQuote({Key? key}) : super(key: key);

  @override
  State<RandomQuote> createState() => _RandomQuoteState();
}

class _RandomQuoteState extends State<RandomQuote> {
  List quote = [
    S.current.enjoyToSearch,
    S.current.findEverything,
    S.current.findAll,
    S.current
        .useShotKeyboardSearchAnything(Platform.isWindows ? "Ctrl" : "CMD"),
    S.current.useShotKeyboardQuickSearch(Platform.isWindows ? "Ctrl" : "CMD")
  ];
  int indexQuote = 0;
  @override
  void initState() {
    super.initState();
    indexQuote = Random().nextInt(quote.length);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.search_sharp,
          size: 40,
          color: Colors.grey[700],
        ),
        Center(
            child: Text(quote[indexQuote],
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w300))),
      ],
    );
  }
}

// enum SearchType {
//   MESSAGE,
//   CONTACT,
//   CHANNEL,
//   ALL
// }
enum SearchMode { DEFAULT, ANY }

class Barrier extends StatelessWidget {
  const Barrier({
    Key? key,
    required this.onClose,
    required this.visible,
    required this.child,
  }) : super(key: key);

  final Widget child;
  final VoidCallback onClose;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return PortalTarget(
      visible: visible,
      closeDuration: kThemeAnimationDuration,
      portalFollower: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: Container(),
      ),
      child: child,
    );
  }
}

