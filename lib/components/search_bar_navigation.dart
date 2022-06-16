import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/focus_inputbox_manager.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/splash_screen.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/models/models.dart';

class SearchBarNavigation extends StatefulWidget {
  const SearchBarNavigation({
    Key? key,
    required this.tab
  }) : super(key: key);

  final int tab;

  @override
  _SearchBarNavigationState createState() => _SearchBarNavigationState();
}
class _SearchBarNavigationState extends State<SearchBarNavigation> {
  final TextEditingController _searchQuery = TextEditingController();
  ValueNotifier<bool> showSuggestions = ValueNotifier(false);
  FocusNode focusNode = FocusNode();
  var _debounce;

  final ScrollController _controller = ScrollController();
  List messages = [];
  List allContact = [];
  List allUser = [];
  List contacts = [];
  List workspaces = [];
  List channels = [];
  bool loading = false;
  SearchType searchType = SearchType.ALL;
  SearchMode searchMode = SearchMode.DEFAULT;
  int  lastLength = 0;
  bool isFetching = false;
  bool isHover = false;
  String contactItemHover = "";
  List dataMessageAll = [];
  int contactsLength = 3;
  FocusScopeNode focusScopeNode = FocusScopeNode();

  @override
  void initState() {
    _controller.addListener(_scrollListener);
    super.initState();
    getInitData();
    RawKeyboard.instance.addListener(handleKey);
    RawKeyboard.instance.addListener(keyboardListener);
  }

  @override
  void didUpdateWidget(oldWidget){
    super.didUpdateWidget(oldWidget);
    if(widget.tab != oldWidget.tab) getInitData();
  }

  handleKey(RawKeyEvent keyEvent) {
    final hotKeyPressed = Platform.isMacOS ? keyEvent.isMetaPressed : keyEvent.isControlPressed;
    final keyDrawer = Provider.of<Auth>(context, listen: false).keyDrawer;

    if (keyEvent is RawKeyDownEvent) {
      if(hotKeyPressed && (!Navigator.of(context).canPop() ||(keyDrawer.currentState != null && keyDrawer.currentState!.isEndDrawerOpen))) {
        if(keyEvent.isKeyPressed(LogicalKeyboardKey.keyF)) {
          showSuggestions.value = true;
          Provider.of<Windows>(context, listen: false).openSearchbar = true;
          focusNode.requestFocus();
          setState(() => searchMode = SearchMode.DEFAULT);
        } else if(keyEvent.isKeyPressed(LogicalKeyboardKey.keyT)) {
          showSuggestions.value = true;
          Provider.of<Windows>(context, listen: false).openSearchbar = true;
          focusNode.requestFocus();
          setState(() => searchMode = SearchMode.ANY);
        }
        return KeyEventResult.handled;
      } else if(keyEvent.isKeyPressed(LogicalKeyboardKey.escape)) {
        showSuggestions.value = false;
      }
    }
    return KeyEventResult.ignored;
  }

  keyboardListener(RawKeyEvent event) {
    final keyId = event.logicalKey.keyId;
    bool openSearchbar = Provider.of<Windows>(context, listen: false).openSearchbar;

    if(event is RawKeyDownEvent) {
      if (event.isMetaPressed) {
        if(keyId.clamp(32, 126) == keyId) {
          return KeyEventResult.handled;
        }
      } else if (mounted && keyId.clamp(32, 126) == keyId && openSearchbar) {
        focusNode.requestFocus();
      }
    }
    return KeyEventResult.ignored;
  }

  getInitData() {
    final directmodels = Provider.of<DirectMessage>(context, listen: false).data;
    final currentUserId = Provider.of<User>(context, listen: false).currentUser["id"];
    List conversationInfo = directmodels.map((e) {
      var users = e.user.length > 1 ? e.user.where((item)  => item["user_id"] != currentUserId).toList() : e.user;

      return {
        "user_id": users[0]["user_id"],
        "conversation_id": users[0]["conversation_id"],
        "name": e.displayName,
        "avatar_url": users[0]["avatar_url"] ?? "",
        "is_online": users[0]["is_online"],
        "members": users.length
      };
    }).toList();

    List userInfo = directmodels.map((e) {
      var users = e.user.length == 2 ? e.user.where((item)  => item["user_id"] != currentUserId).toList() : e.user;
      return {
        "user_id": users[0]["user_id"],
        "conversation_id": users[0]["conversation_id"],
        "name": users[0]["full_name"],
        "avatar_url": users[0]["avatar_url"] ?? "",
        "is_online": users[0]["is_online"]
      };
    }).toList();

    setState(() {
      allContact = conversationInfo;
      allUser = userInfo;
      searchType = SearchType.ALL;
      searchMode = SearchMode.DEFAULT;
    });
  }

  @override
  void dispose() {
    _searchQuery.dispose();
    RawKeyboard.instance.removeListener(handleKey);
    RawKeyboard.instance.removeListener(keyboardListener);
    super.dispose();
  }

  getMembersWorkspace(value) async {
    final token = Provider.of<Auth>(context, listen: false).token;

    try {
      var url = Utils.apiUrl + "workspaces/search_users?token=$token&value=$value";
    
      var response = await Dio().get(url);
      
      return (response.data)["members"];

    } catch (e) {
      print(e);
      return [];
    }
  }

  searchContact(value) async {
    var membersWorkspaces = await getMembersWorkspace(value);
    var contactLocal = allContact.where((element) => Utils.unSignVietnamese(element["name"]).contains(Utils.unSignVietnamese(value))).toList();
    var idContactLocal = contactLocal.map((e) => e["user_id"]).toList();

    for(int i = 0; i < membersWorkspaces.length; i++) {
      var isExist = (idContactLocal).indexOf(membersWorkspaces[i]["id"]);
      
      if(isExist == -1) {
        contactLocal.add(membersWorkspaces[i]);
      }
    }
    return contactLocal;
  }

  searchChannel(value, searchMode) {
    final tab = Provider.of<Workspaces>(context, listen: false).tab;
    var result = [];
    List listChannel = Provider.of<Channels>(context, listen: false).data;
    result = listChannel.where((e) => e["name"].toLowerCase().contains(value)).toList();
    if (searchMode == SearchMode.DEFAULT) {
      result = result.where((e) => e["workspace_id"] == tab).toList();
    }
    return result;
  }

  String renderNameConversation(users) {
    String name = "";
    for(int i = 0; i < users.length; i++) {
      name += users[i]["full_name"] ;
      if(i != users.length - 1) {
        name += " , ";
      }
    }
    return name;
  }

  _scrollListener() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    var triggerFetchMoreSize = 0.9 * _controller.position.maxScrollExtent;

    if(_controller.position.pixels > triggerFetchMoreSize) {
      if(lastLength >= 40 && !isFetching) {
        isFetching = true;
        search(_searchQuery.text.trim(), token, searchType, searchMode, offset: messages.length, loadMore: true).then((_value) {
          isFetching = false;
        });
      }
    }
  }
  
  onSelectDirectMessages(directId, {Map? message}) async {
    final auth = Provider.of<Auth>(context, listen: false);
    var hasConv = await  Provider.of<DirectMessage>(context, listen: false).getInfoDirectMessage(auth.token, directId);
    if (hasConv) {
      DirectModel? model = Provider.of<DirectMessage>(context, listen: false).getModelConversation(directId);
      if (model == null) return;
      if (message != null){
        if (!Utils.checkedTypeEmpty(message["parent_id"])){
          Provider.of<Workspaces>(context, listen: false).tab = 0;
          await Provider.of<DirectMessage>(context, listen: false).processDataMessageToJump(message, auth.token, auth.userId);          
        } else {
          // 
          var messageOnIsar = await MessageConversationServices.getListMessageById(message["parent_id"], directId);
          final directMessageSelected =  Provider.of<DirectMessage>(context, listen: false).getModelConversation(directId);
          if (directMessageSelected == null) return;
          List users = directMessageSelected.user;
          final indexUser = users.indexWhere((e) => e["user_id"] == message["user_id"]);

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
            // Provider.of<DirectMessage>(context, listen: false).processDataMessageToJump(messageOnIsar, auth.token);
            Provider.of<Channels>(context, listen: false).openChannelSetting(false);
            await Provider.of<Messages>(context, listen: false).openThreadMessage(true, parentMessage);
          }
        }
      }
      else {
        await Provider.of<DirectMessage>(context, listen: false).onChangeSelectedFriend(false);
        await auth.channel.push(event: "join_direct", payload: {"direct_id": directId});
        await Provider.of<DirectMessage>(context, listen: false).setSelectedDM(model, auth.token);
      }
    } else {}
  }

  onSelectMessage(Map message) async {
    final token = Provider.of<Auth>(context, listen: false).token;
    if (!Utils.checkedTypeEmpty(message["channel_thread_id"])){
      Provider.of<Messages>(context, listen: false).handleProcessMessageToJump(message, Utils.globalContext);
    } else {
      int workspaceId = message["workspace_id"];
      int channelId = message["channel_id"];
      final url =  Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/messages/thread?message_id=${message["channel_thread_id"]}&token=$token';
      final response = await Dio().get(url);
      Map parentMessage  = response.data["parent_message"] ?? {};
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
      Provider.of<Messages>(context, listen: false).openThreadMessage(true, parentMessageData);
      await Provider.of<Threads>(context, listen: false).updateThreadUnread(workspaceId, channelId, parentMessageData, token);
    }

  }

  _onSearchChanged(searchType, searchMode) {
    final token = Provider.of<Auth>(context, listen: false).token;

    if(_searchQuery.text.trim() == "") {
      setState(() {
        contacts = [];
        messages = [];
        workspaces = [];
        channels = [];
        dataMessageAll = [];
        contactsLength = 3;
        loading = false;
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      search(_searchQuery.text, token, searchType, searchMode);
    });
  }

  Future<void> search(value, token, searchType, searchMode, {offset = 0, loadMore = false}) async {
    final tab = Provider.of<Workspaces>(context, listen: false).tab;
    if(value == "" || value == null) {
      setState(() {
        loading = false;
      });
      return;
    } else {
      var resultContact = [];
      if (searchType == SearchType.CONTACT || searchType == SearchType.ALL) {
        Future.delayed(Duration.zero, () async {
          resultContact = await searchContact(value);
          setState(() {
            contacts = resultContact;
          });
        });
      }

      if (searchType == SearchType.CHANNEL || searchType == SearchType.ALL) {
        await Future.delayed(Duration.zero, () {
          setState(() {
            channels = searchChannel(value, searchMode);
          });
        });
      }

      setState(() { loading = true; });

      if (searchType == SearchType.MESSAGE || searchType == SearchType.ALL) {
        if (tab != 0 && searchMode == SearchMode.DEFAULT) {
          String url = "${Utils.apiUrl}/workspaces/$tab/search_message?token=$token";
          try {
            var response =  await Dio().post(url, data: { "term": value });
            var dataRes = response.data;

            if (dataRes["success"]) {
              workspaces = dataRes["result"];
            }
          } catch (e) {
            print(e);
          }
        } else {
          List data  = await MessageConversationServices.searchMessage(value, parseJson: true, limit: 40, offset: offset);

          loadMore ? messages += data : messages = data;
          lastLength = data.length;

          if (searchMode == SearchMode.ANY) {
            String url = "${Utils.apiUrl}search_all?token=$token";
            try {
              final List workspaceIds = Provider.of<Workspaces>(context, listen: false).data.map((e) => e['id']).toList();
              final List channelIds = Provider.of<Channels>(context, listen: false).data.map((e)=> e['id']).toList();

              var response =  await Dio().post(url, data: { "term": value, 'workspace_ids': workspaceIds, 'channel_ids': channelIds});
              var dataRes = response.data;
              if (dataRes["success"]) {
                workspaces = dataRes["result"];
              }
            } catch (e) {
              print(e);
            }
          }
        }
      }

      bool needSort = workspaces.isNotEmpty && messages.isNotEmpty;

      dataMessageAll = workspaces + messages;
      if (needSort) {
        dataMessageAll.sort((a,b){
          var timeA = a["time_create"] != null ? a["time_create"] == "" ? "1900-01-01T00:00:00" : a["time_create"] : a["_source"]["inserted_at"] != null ? a["_source"]["inserted_at"] == "" ? a["_source"]["inserted_at"] : "1900-01-01T00:00:00" : "1900-01-01T00:00:00" ;
          var timeB = b["time_create"] != null ? b["time_create"] == "" ? "1900-01-01T00:00:00" : b["time_create"] : b["_source"]["inserted_at"] != null ? b["_source"]["inserted_at"] == "" ? b["_source"]["inserted_at"] : "1900-01-01T00:00:00" : "1900-01-01T00:00:00" ;

          return DateTime.parse(timeA).compareTo(DateTime.parse(timeB));
        });
      }
      setState(() {
        loading = false;
      });
    }
  }

  onChangeWorkspace(workspaceId, channelId) async {
    final token = Provider.of<Auth>(context, listen: false).token;
    Provider.of<Workspaces>(context, listen: false).tab = workspaceId;
    await Provider.of<Workspaces>(context, listen: false).selectWorkspace(token, workspaceId, context);
    if (channelId != null) {
      await Provider.of<Channels>(context, listen: false).selectChannel(token, workspaceId, channelId);
      await Provider.of<Workspaces>(context, listen: false).getInfoWorkspace(token, workspaceId, context);
      await Provider.of<Channels>(context, listen: false).setCurrentChannel(channelId);
      await Provider.of<Messages>(context, listen: false).loadMessages(token, workspaceId, channelId);
    } else {
      final channels = Provider.of<Channels>(context, listen: false).data;
      if (channels.isNotEmpty) {
        final channelId = channels[0]["id"];
        await Provider.of<Channels>(context, listen: false).setCurrentChannel(channelId);
        await Provider.of<Channels>(context, listen: false).selectChannel(token, workspaceId, channelId);
        await Provider.of<Messages>(context, listen: false).loadMessages(token, workspaceId, channelId);
      } else {
        print("Error search bar");
      }
    }
  }

  TextSpan renderText(string) {
    final isDark  = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    RegExp exp = RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
    List list = string.trim().split(" ");

    return TextSpan(
      children: list.map<TextSpan>((e){
        Iterable<RegExpMatch> matches = exp.allMatches(e);
        if (matches.isNotEmpty) {
          return TextSpan(
            text: "$e ", 
            style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                if (await canLaunch(e)) {
                  await launch(e);
                } else {
                  throw 'Could not launch $e';
                }
              }
          );
        } else {
          return TextSpan(text: "$e ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87));
        }
      }).toList()
    );
  }
  
  renderMessage(attachments) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return RichText(text: TextSpan(
      children: attachments.map<TextSpan>((item) {
        if (item["type"] == "text" && Utils.checkedTypeEmpty(item["value"])) {
          return renderText(item["value"]);
        } else if (item["type"] == "text") {
           return TextSpan(text: item["value"]);
        } else if (item["name"] == "all" || item["type"] == "all") {
          return TextSpan(text: "@all ",  style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue));
        } else if(item["type"] == "user") {
          int index = allUser.indexWhere((element) => element["user_id"] == item["value"]);
          if (index != -1) {
            return TextSpan(text: "@${allUser[index]["name"]} ", style: TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue));
          }
          return const TextSpan(text: "");
        } else {
          return const TextSpan();
        }
      }).toList(),
      style: const TextStyle(fontSize: 13)
    ));
  }

  goDirectMessage(user) async {
    var currentUser = Provider.of<User>(context, listen: false).currentUser;
    var convId = user["conversation_id"];
    if (convId == null){
      convId = MessageConversationServices.shaString([currentUser["id"], user["user_id"] ?? user["id"]]);
    }

    bool hasConv = await Provider.of<DirectMessage>(context, listen: false).getInfoDirectMessage(Provider.of<Auth>(context, listen: false).token, convId);
    var dm;
    if (hasConv){
      dm = Provider.of<DirectMessage>(context, listen: false).getModelConversation(convId);
    } else {
      dm = DirectModel(
        "", 
        [
          {"user_id": currentUser["id"],"full_name": currentUser["full_name"], "avatar_url": currentUser["avatar_url"], "is_online": true}, 
          {"user_id": user["user_id"] ?? user["id"], "avatar_url": user["avatar_url"],  "full_name": user["full_name"] ?? user["name"], "is_online": user["is_online"]}
        ], 
        "", 
        false, 
        0, 
        {}, 
        false,
        0,
        {},
        user["full_name"] ?? user["name"], null
      );
    }
    Provider.of<Workspaces>(context, listen: false).setTab(0);
    Provider.of<DirectMessage>(context, listen: false).setSelectedDM(dm, "");
  }

  onSelectChannel(channelId, workspaceId) async {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    Provider.of<Workspaces>(context, listen: false).setTab(workspaceId);
    Provider.of<Workspaces>(context, listen: false).selectWorkspace(auth.token, workspaceId, context);
    Provider.of<User>(context, listen: false).selectTab("channel");
    await Provider.of<Channels>(context, listen: false).setCurrentChannel(channelId);
    Provider.of<Messages>(context, listen: false).loadMessages(auth.token, workspaceId, channelId);
    await Provider.of<Channels>(context, listen: false).selectChannel(auth.token, workspaceId, channelId);
    Provider.of<Channels>(context, listen: false).loadCommandChannel(auth.token, workspaceId, channelId);
    Provider.of<Channels>(context, listen: false).getChannelMemberInfo(auth.token, workspaceId, channelId, currentUser["id"]);
    Provider.of<Workspaces>(context, listen: false).clearMentionWhenClickChannel(workspaceId, channelId);

    auth.channel.push(
      event: "join_channel",
      payload: {"channel_id": channelId, "workspace_id": workspaceId}
    );

    if(Platform.isMacOS) Utils.updateBadge(context);
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
    final currentUser = Provider.of<User>(context).currentUser;
    final sendingList = Provider.of<User>(context, listen: true).sendingList;
    final friendList = Provider.of<User>(context, listen: true).friendList;

    return MouseRegion(
      onEnter: (event){
        setState(() {
          isHover = true;
        });
      },
      onExit: (event) {
        setState(() {
          isHover = false;
        });
      },
      child: PortalEntry(
        portalAnchor: Alignment.topCenter,
        childAnchor: Alignment.topCenter,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 1000,
            minWidth: 500
          ),
          margin: const EdgeInsets.only(top: 7.0, bottom: 6.0),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            color: const Color(0xff2E2E2E),
            boxShadow: [if (isHover) const BoxShadow(color: Colors.white, blurRadius: 1)]
          ),
          width: deviceWidth / 2,
          child: InkWell(
            onTap: (){
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
                Text(S.current.searchAnything(hotKey), style: const TextStyle(color: Color(0xffA6A6A6), fontSize: 14, fontWeight: FontWeight.w300),)
              ],
            ),
          ),
        ),
        portal: ValueListenableBuilder(
          valueListenable: showSuggestions,
          builder: (BuildContext context, bool show, Widget? child) {
            return show ? FocusScope(
              node: focusScopeNode,
              onKey: (focusNode, rawKeyEvent) {
                if (rawKeyEvent.isKeyPressed(LogicalKeyboardKey.arrowDown) && focusScopeNode.focusedChild?.context?.widget is EditableText) {
                  focusScopeNode.nextFocus();
                }
                return KeyEventResult.ignored;
              },
              onFocusChange: (value) {
                showSuggestions.value = value;
                if (!value) Provider.of<Windows>(context, listen: false).openSearchbar = false;
              },
              child: Container(
                width: deviceWidth / 2 + 10,
                height: 400,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff353535) /*Color(0xff262626)*/ : Palette.backgroundTheardLight,
                  borderRadius: const BorderRadius.all(Radius.circular(4)), 
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.099), blurRadius: 20.0)]
                ),
                constraints: const BoxConstraints(
                  maxWidth: 1000,
                  minWidth: 630,
                  maxHeight: 400
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: [
                        searchType != SearchType.ALL ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6),
                          margin: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 13.0),
                          alignment: Alignment.centerRight,
                          width: 100,
                          decoration: BoxDecoration(color: Colors.grey,borderRadius: BorderRadius.circular(3)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(searchType == SearchType.CONTACT ? S.current.contacts : searchType == SearchType.MESSAGE ? S.current.messages : searchType == SearchType.CHANNEL ? S.current.channels : "", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400)),
                              const SizedBox(width: 10.0),
                              InkWell(onTap:() => setState(() {
                                searchType = SearchType.ALL;
                              }),child: const Icon(Icons.close, size: 14, color: Colors.white))
                            ],
                          ),
                        ) : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: SvgPicture.asset('assets/icons/search.svg')
                        ),
                        Expanded(
                          child: TextFormField(
                            autofocus: true,
                            cursorWidth: 1.0,
                            cursorHeight: 14,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              constraints: const BoxConstraints(maxHeight: 38),
                              hintText: searchType == SearchType.CONTACT
                                  ? S.current.descSearchContact
                                  : searchMode == SearchMode.ANY
                                      ? searchType == SearchType.ALL
                                          ? S.current.desSearchAnything
                                          : S.current.descSearchAll
                                      : searchType == SearchType.ALL
                                          ? tab == 0
                                              ? S.current.desSearch
                                              : S.current.descSearchInCtWs(currentWorkspace["name"])
                                          : tab == 0
                                              ? S.current.descSearchDms
                                              : S.current.descSearchInWs(currentWorkspace["name"]),
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                              hintStyle: const TextStyle(color: Color(0xffA6A6A6), fontSize: 14, fontWeight: FontWeight.w300),
                              border: InputBorder.none,
                              suffixIcon: _searchQuery.text.isNotEmpty ? MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    _searchQuery.clear();
                                    FocusScope.of(context).unfocus();
                                    showSuggestions.value = false;
                                    setState(() {
                                      workspaces = [];
                                      messages = [];
                                      contacts = [];
                                      dataMessageAll = [];
                                      contactsLength = 3;
                                    });
                                  },
                                  child: const Icon(Icons.close, size: 14, color: Color(0xffA6A6A6)),
                                ),
                              ) : const SizedBox(width: 15)
                            ),
                            focusNode: focusNode,
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black, fontSize: 14),
                            controller: _searchQuery,
                            onChanged: (value) {
                              _onSearchChanged(searchType, searchMode);
                              // showSuggestions.value = Utils.checkedTypeEmpty(value);
                            },
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Divider(color: Colors.white.withOpacity(0.7), height: 0.5),
                          if (searchType == SearchType.ALL) Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 18 ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Text(S.current.lookingFor, style: const TextStyle(color: Color(0xffA6A6A6), fontWeight: FontWeight.w300)),
                                ),
                                TextButton(
                                  focusNode: FocusNode()..skipTraversal = true,
                                  onPressed: () { 
                                    setState(() {
                                      searchType = SearchType.MESSAGE;
                                    });
                                    _onSearchChanged(searchType, searchMode);
                                  },
                                  style: ButtonStyle(padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 12.0, vertical: Platform.isMacOS || Platform.isWindows ? 12.0 : 8.0)),backgroundColor: MaterialStateProperty.all(isDark ? (searchType == SearchType.MESSAGE ? const Color(0xff19DFCB) : const Color(0xff828282)) : (searchType == SearchType.MESSAGE ? const Color(0xff2A5298) : const Color(0xffF7F7F8)))),
                                  child: Row(
                                    children: [
                                      Icon(CupertinoIcons.chat_bubble_2, size: 18.0, color: searchType == SearchType.MESSAGE? isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.85) : isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.85)),
                                      const SizedBox(width: 8.0,),
                                      Text(S.current.messages, style: TextStyle(color: searchType == SearchType.MESSAGE? isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.85) : isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.85)))
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12.0,),
                                TextButton(
                                  focusNode: FocusNode()..skipTraversal = true,
                                  onPressed: () { 
                                    setState(() {
                                      searchType =  SearchType.CONTACT ;
                                    });
                                    _onSearchChanged(searchType, searchMode);
                                  },
                                  style: ButtonStyle(padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 12.0, vertical: Platform.isMacOS || Platform.isWindows ? 12.0 : 8.0)),backgroundColor: MaterialStateProperty.all(isDark ? (searchType == SearchType.CONTACT? const Color(0xff19DFCB) : const Color(0xff828282)) : (searchType == SearchType.CONTACT ? const Color(0xff2A5298) : const Color(0xffF7F7F8)))),
                                  child: Row(
                                    children: [
                                      Icon(CupertinoIcons.person_2, size: 18.0, color: searchType == SearchType.CONTACT? isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.85) : isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.85)),
                                      const SizedBox(width: 8.0),
                                      Text(S.current.contacts, style: TextStyle(color: searchType == SearchType.CONTACT ? isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.85) : isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.85)))
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                if (tab != 0 || searchMode == SearchMode.ANY) TextButton(
                                  focusNode: FocusNode()..skipTraversal = true,
                                  onPressed: () { 
                                    setState(() {
                                      searchType = SearchType.CHANNEL;
                                    });
                                    _onSearchChanged(searchType, searchMode);
                                  },
                                  style: ButtonStyle(padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 12.0, vertical: Platform.isMacOS || Platform.isWindows ? 12.0 : 8.0)),backgroundColor: MaterialStateProperty.all(isDark ? (searchType == SearchType.MESSAGE ? const Color(0xff19DFCB) : const Color(0xff828282)) : (searchType == SearchType.MESSAGE ? const Color(0xff2A5298) : const Color(0xffF7F7F8)))),
                                  child: Row(
                                    children: [
                                      Icon(CupertinoIcons.list_dash, size: 18.0, color: searchType == SearchType.MESSAGE? isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.85) : isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.85)),
                                      const SizedBox(width: 8.0,),
                                      Text(S.current.channels, style: TextStyle(color: searchType == SearchType.MESSAGE? isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.85) : isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.85)))
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12.0), 
                              ],
                            ),
                          ),
                    
                          if (contacts.isNotEmpty || dataMessageAll.isNotEmpty || channels.isNotEmpty) Expanded(
                            child: SingleChildScrollView(
                              controller: _controller,
                              child: Column(
                                children: [
                                  if (contacts.isNotEmpty && (searchType == SearchType.ALL || searchType == SearchType.CONTACT)) Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8, left: 24, bottom: 8),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(S.current.contacts.toUpperCase(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                        ),
                                      ),
                    
                                      ListView.builder(
                                        padding: const EdgeInsets.only(top: 4, left: 24, right: 24),
                                        physics: const NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount: searchType != SearchType.ALL || contactsLength > contacts.length ? contacts.length : contactsLength ,
                                        itemBuilder: (context, index) {
                                          String _checkFriendStatus(user) {
                                            final indexFriend = friendList.indexWhere((element) => (element["user_id"] ?? element["id"]) == (user["id"] ?? user["user_id"]));
                                            final indexSending = sendingList.indexWhere((element) => (element["user_id"] ?? element["id"]) == (user["id"] ?? user["user_id"]));
                                            if (indexFriend != -1) return "friend";
                                            if (indexSending != -1) return "sending";
                                            return "none";
                                          }
                                          return MouseRegion(
                                            onEnter: (_) {
                                              setState(() => contactItemHover = contacts[index]["id"] ?? contacts[index]["user_id"]);
                                            },
                                            onExit: (_) {
                                              setState(() => contactItemHover = "");
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(bottom: 2.0),
                                              child: TextButton(
                                                onPressed: () {
                                                  goDirectMessage(contacts[index]);
                                                  // onSelectDirectMessages(contacts[index]["conversation_id"]);
                                                  _searchQuery.clear();
                                                  showSuggestions.value = false;
                                                  FocusScope.of(context).unfocus();
                                                  FocusInputStream.instance.focusToMessage();
                                                  setState(() {
                                                    workspaces = [];
                                                    messages = [];
                                                    contacts = [];
                                                    contactsLength = 3;
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 30,
                                                        child: Stack(
                                                          children: [
                                                          (contacts[index]["members"] ?? 1) < 2 ? CachedAvatar((contacts[index]["avatar_url"] ?? ""), name: contacts[index]["name"], width: 28, height: 28)
                                                            : SizedBox(
                                                              width: 28,
                                                              height: 28,
                                                              child: Container(
                                                                decoration: BoxDecoration(
                                                                  color: Color(((index + 1) * pi * 0.1 * 0xFFFFFF).toInt()).withOpacity(1.0),
                                                                  borderRadius: BorderRadius.circular(16)
                                                                ),
                                                                child: const Icon(
                                                                  Icons.group,
                                                                  size: 16,
                                                                  color: Colors.white
                                                                ),
                                                              ),
                                                            ),
                                                            Positioned(
                                                              bottom: 0,
                                                              right: 0,
                                                              child: Container(
                                                                width: 10,
                                                                height: 10,
                                                                decoration: BoxDecoration(
                                                                  borderRadius: BorderRadius.circular(6.0),
                                                                  color: (contacts[index]["members"] ?? 1) < 2 ? (contacts[index]["is_online"] ?? false) ? Colors.green : Colors.transparent : Colors.transparent
                                                                ),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8.0,),
                                                      Expanded(child: Text(contacts[index]["name"] ?? contacts[index]["full_name"] ?? "Error Name", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.85)),overflow: TextOverflow.ellipsis,)),
                                                      _checkFriendStatus(contacts[index]) != "friend" && contactItemHover == (contacts[index]["id"] ?? contacts[index]["user_id"])
                                                        ? ElevatedButton(
                                                            style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.transparent)),
                                                            onPressed: () {
                                                              if (_checkFriendStatus(contacts[index]) == "sending") {
                                                                Provider.of<User>(context, listen: false).removeRequest(auth.token, contacts[index]["id"] ?? contacts[index]["user_id"]);
                                                              } else {
                                                                Provider.of<User>(context, listen: false).addFriendRequest(contacts[index]["id"] ?? contacts[index]["user_id"], auth.token);
                                                              }
                                                            },
                                                            child: Icon(_checkFriendStatus(contacts[index]) == "sending" ? PhosphorIcons.userMinus : PhosphorIcons.userPlus))
                                                        : Container()
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      if (searchType == SearchType.ALL && contactsLength < contacts.length) Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextButton(onPressed: () => setState(() {
                                          contactsLength += 5;
                                          contactsLength = contactsLength >= contacts.length ? contacts.length : contactsLength;
                                        }), child: const SizedBox(
                                          width: double.infinity,
                                          child: Icon(Icons.arrow_drop_down),
                                        ), style: ButtonStyle(overlayColor: MaterialStateProperty.all(Colors.grey[200]), backgroundColor: MaterialStateProperty.all(Colors.transparent), shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            side: BorderSide(color: Colors.black.withOpacity(0.2), width: 2.0)
                                          )
                                        ))),
                                      )
                                    ],
                                  ),
                                  if (channels.isNotEmpty && (searchType == SearchType.ALL || searchType == SearchType.CHANNEL)) Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8, bottom: 8, left: 24),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(S.current.channels.toUpperCase(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                        ),
                                      ),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        padding: const EdgeInsets.only(top: 4, left: 24, right: 24),
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: channels.length,
                                        itemBuilder: (context, index) {
                                          final channel = channels[index];

                                          return TextButton(
                                            onPressed: () {
                                              onSelectChannel(channel["id"], channel["workspace_id"]);
                                              _searchQuery.clear();
                                              showSuggestions.value = false;
                                              FocusScope.of(context).unfocus();
                                              FocusInputStream.instance.focusToMessage();
                                              setState(() {
                                                workspaces = [];
                                                messages = [];
                                                contacts = [];
                                                dataMessageAll = [];
                                                contactsLength = 3;
                                              });
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(bottom: 8, top: 8, left: 12),
                                              child: Row(
                                                children: [
                                                  channel["is_private"] ? SvgPicture.asset('assets/icons/Locked.svg', color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight) : SvgPicture.asset('assets/icons/iconNumber.svg', width: 13, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                                  const SizedBox(width: 4.0),
                                                  Text("${channel["name"]} ${channel["is_archived"] == true ? "(archived)" : ""}", style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1F2933), fontWeight: FontWeight.w600)),
                                                ]
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    ],
                                  ),
                                  if (dataMessageAll.isNotEmpty && (searchType == SearchType.ALL || searchType == SearchType.MESSAGE)) loading ? Center(child: SplashScreen()) : Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8, bottom: 8, left: 24),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(S.current.messages.toUpperCase(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                        ),
                                      ),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        padding: const EdgeInsets.only(top: 4, left: 24, right: 24),
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: dataMessageAll.length,
                                        itemBuilder: (context, index) {
                                          if (dataMessageAll[index]["time_create"] != null) {
                                            var indexContact = allContact.indexWhere((i) {
                                              return i["conversation_id"] == dataMessageAll[index]["conversation_id"];
                                            });
                                            return indexContact != -1 ? Container(
                                              margin: const EdgeInsets.only(bottom: 2.0),
                                              child: TextButton(
                                                onPressed: () {
                                                  onSelectDirectMessages(allContact[indexContact]["conversation_id"], message: dataMessageAll[index]);
                                                  _searchQuery.clear();
                                                  FocusScope.of(context).unfocus();
                                                  FocusInputStream.instance.focusToMessage();
                                                  showSuggestions.value = false;
                                                  setState(() {
                                                    workspaces = [];
                                                    messages = [];
                                                    contacts = [];
                                                    contactsLength = 3;
                                                  });
                                                },
                                                child: Container(
                                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 30,
                                                        child: Stack(
                                                          children: [
                                                            allContact[indexContact]["members"] < 2 ? CachedAvatar(allContact[indexContact]["avatar_url"], name: allContact[indexContact]["name"], width: 28, height: 28)
                                                            : SizedBox(
                                                              width: 28,
                                                              height: 28,
                                                              child: Container(
                                                                decoration: BoxDecoration(
                                                                  color: Color(((index + 1) * pi * 0.1 * 0xFFFFFF).toInt()).withOpacity(1.0),
                                                                  borderRadius: BorderRadius.circular(16)
                                                                ),
                                                                child: const Icon(
                                                                  Icons.group,
                                                                  size: 16,
                                                                  color: Colors.white
                                                                ),
                                                              ),
                                                            ),
                                                            Positioned(
                                                              bottom: 0,
                                                              right: 0,
                                                              child: Container(
                                                                width: 10,
                                                                height: 10,
                                                                decoration: BoxDecoration(
                                                                  borderRadius: BorderRadius.circular(6.0),
                                                                  color: allContact[indexContact]["members"] < 2 ? ( allContact[indexContact]["is_online"] ? Colors.green : Colors.transparent) : Colors.transparent 
                                                                ),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8.0,),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(allContact[indexContact]["name"], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.85)), overflow: TextOverflow.ellipsis,),
                                                            const SizedBox(height: 4,),
                                                            Row(
                                                              children: [
                                                                dataMessageAll[index]["user_id"] == currentUser["id"]
                                                                ? Row(
                                                                  children: [
                                                                    Icon(Icons.subdirectory_arrow_right, size: 14, color: isDark ? Colors.white.withOpacity(0.85) :Colors.black.withOpacity(0.85)),
                                                                    const SizedBox(width: 2,),
                                                                  ],
                                                                ) 
                                                                : const SizedBox(),
                                                                (dataMessageAll[index]["attachments"].length > 0 && dataMessageAll[index]["attachments"][0]["type"] == "mention") 
                                                                ? renderMessage(dataMessageAll[index]["attachments"][0]["data"])
                                                                : Text(dataMessageAll[index]["message"], style: TextStyle(fontSize: 13, color: isDark? Colors.white.withOpacity(0.75) : Colors.black.withOpacity(0.85), fontWeight: FontWeight.w400,), overflow: TextOverflow.ellipsis,)
                                                              ],
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                ),
                                              ),
                                            ) : const SizedBox();
                                          }
                                          if (dataMessageAll[index]["_source"] != null) {
                                            final lastReply = dataMessageAll[index]["_source"]['inserted_at'];
                                            final messageTime = DateFormat('kk:mm').format(DateTime.parse(lastReply).add(const Duration(hours: 7)));
                    
                                            final messageLastTime = "${DateFormatter().renderTime(DateTime.parse(lastReply), type: "MMMd") + " at $messageTime"}";
                                            final channel = listChannel.where((element) => element["id"] == dataMessageAll[index]["_source"]["channel_id"]).toList().first;
                                            return SizedBox(
                                              width: MediaQuery.of(context).size.width *1/3,
                                              child: TextButton(

                                                onPressed: () {
                                                  onSelectMessage({
                                                      ...dataMessageAll[index]["_source"],
                                                      "avatarUrl": dataMessageAll[index]["_source"]["avatar_url"] ?? "",
                                                      "fullName": dataMessageAll[index]["_source"]["full_name"] ?? "",
                                                      "workspace_id": dataMessageAll[index]["_source"]["workspace_id"],
                                                      "channel_id": dataMessageAll[index]["_source"]["channel_id"]
                                                    });
                                                  _searchQuery.clear();
                                                  showSuggestions.value = false;
                                                  FocusScope.of(context).unfocus();
                                                  FocusInputStream.instance.focusToMessage();
                                                  setState(() {
                                                    workspaces = [];
                                                    messages = [];
                                                    contacts = [];
                                                    dataMessageAll = [];
                                                    contactsLength = 3;
                                                  });
                                                },
                                                child: Container(
                                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 30,
                                                        child: Stack(
                                                          children: [
                                                            CachedAvatar(
                                                              dataMessageAll[index]["_source"]["avatar_url"],
                                                              name: dataMessageAll[index]["_source"]["full_name"],
                                                              width: 28,
                                                              height: 28
                                                            ),
                                                            Positioned(
                                                              bottom: 0,
                                                              right: 0,
                                                              child: Container(
                                                                width: 10,
                                                                height: 10,
                                                                decoration: BoxDecoration(
                                                                  borderRadius: BorderRadius.circular(6.0),
                                                                  color: Colors.transparent 
                                                                ),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8.0,),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                channel["is_private"] ? SvgPicture.asset('assets/icons/Locked.svg', color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight) : SvgPicture.asset('assets/icons/iconNumber.svg', width: 13, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                                                const SizedBox(width: 4.0),
                                                                Text(channel["name"], style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1F2933), fontWeight: FontWeight.w600)),
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                                  child: Text(messageLastTime, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w400, color: isDark ? Palette.defaultTextDark.withOpacity(0.65) : Palette.defaultTextLight.withOpacity(0.65))),
                                                                )
                                                              ]
                                                            ),
                                                            const SizedBox(height: 4,),
                                                            (dataMessageAll[index]["_source"]["attachments"] != null && dataMessageAll[index]["_source"]["attachments"].length > 0 && dataMessageAll[index]["_source"]["attachments"][0]["type"] == "mention") 
                                                              ? renderMessage(dataMessageAll[index]["_source"]["attachments"][0]["data"])
                                                              : Text(dataMessageAll[index]["_source"]["message_parse"], style: TextStyle(fontSize: 13, color: isDark? Colors.white.withOpacity(0.75) : Colors.black.withOpacity(0.85), fontWeight: FontWeight.w400,), overflow: TextOverflow.ellipsis,)
                                                          ],
                                                        ),
                                                      ),
                                                      dataMessageAll[index]["_source"]['channel_thread_id'] != null ? Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 15),
                                                        child: Text(S.current.inThread, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w300))
                                                      ) : Container()
                                                    ],
                                                  )
                                                ),
                                              ),
                                            );
                                          }
                                          return Container();
                                        },
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if(dataMessageAll.isEmpty && contacts.isEmpty && channels.isEmpty && !loading) const Expanded(child: const RandomQuote())
                        ],
                      ),
                    )
                  ]
                )
              ),
            ) : Container();
          },
        ),
      ),
    );
  }
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
    S.current.useShotKeyboardSearchAnything(Platform.isWindows ? "Ctrl" : "CMD"),
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
        Icon(Icons.search_sharp, size: 40, color: Colors.grey[700],),
        Center(child: Text(quote[indexQuote], style: TextStyle(fontSize: 20, color: Colors.grey[700], fontWeight: FontWeight.w300))),
      ],
    );
  }
}

enum SearchType {
  MESSAGE,
  CONTACT,
  CHANNEL,
  ALL
}
enum SearchMode {
  DEFAULT,
  ANY
}
