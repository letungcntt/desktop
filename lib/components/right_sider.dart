import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/channels/channel_info_macOS.dart';
import 'package:workcake/components/friends/list_friends.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/components/dropdown_overlay.dart';
import 'package:workcake/components/filter_mentions.dart';
import 'package:workcake/components/icon_badge.dart';
import 'package:workcake/components/list_mention_conversation.dart';
import 'package:workcake/components/list_mentions_desktop.dart';
import 'package:workcake/components/list_threads_desktop.dart';
import 'package:workcake/components/message_item/attachments/text_file.dart';
import 'package:workcake/components/pinned_message_desktop.dart';
import 'package:workcake/components/responsesizebar_widget.dart';
import 'package:workcake/components/thread_desktop.dart';
import 'package:workcake/direct_message/direct_info_macOS.dart' hide MembersTile;
import 'package:workcake/direct_message/message_view_macOS.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/flutter_mention/custom_selection.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/workspaces/apps/workspace_apps.dart';
import 'package:workcake/workspaces/conversation_macOS.dart';
import 'package:workcake/workspaces/list_app_view.dart';
import 'package:workcake/workview_desktop/create_issue.dart';
import 'package:workcake/workview_desktop/workview_desktop.dart';

import 'call_center/p2p_manager.dart';
import 'call_center/room.dart';
import 'transitions/modal.dart';

class RightSider extends StatefulWidget {
  RightSider({
    Key? key,
  }) : super(key: key);

  @override
  _RightSiderState createState() => _RightSiderState();
}

class _RightSiderState extends State<RightSider> {
  GlobalKey<ScaffoldState> keyScaffold = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener(handleKey);
  }

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    final keyScaffoldByAuth = Provider.of<Auth>(context, listen: false).keyDrawer;

    if(keyScaffold != keyScaffoldByAuth) {
      Provider.of<Auth>(context, listen: false).onChangeKeyDrawer(keyScaffold);
    }
  }

  handleKey(RawKeyEvent keyEvent) {
    final Map? issuesSelected = Provider.of<Channels>(context, listen: false).issueSelected;
    final bool isShowMention = Provider.of<Auth>(context, listen: false).isShowMention;
    final int tab = Provider.of<Workspaces>(context, listen: false).tab;
    final bool openSearchbar = Provider.of<Windows>(context, listen: false).openSearchbar;
    final bool isBlockEscape = Provider.of<Windows>(context, listen: false).isBlockEscape;

    if(keyEvent.isKeyPressed(LogicalKeyboardKey.escape) && keyEvent is RawKeyDownEvent) {
      if(openSearchbar) {
        Provider.of<Windows>(context, listen: false).openSearchbar = false;
        return KeyEventResult.ignored;
      }
      if (issuesSelected != null) {
        final NavigatorState stateNavigator = Navigator.maybeOf(context)!;
        final OverlayState? overlayState = stateNavigator.overlay;
        int lengthLayout = 0;
        try {
         lengthLayout = int.parse(overlayState.toString().split(' ').toList()[2]);
        } catch (e) {
          lengthLayout = 0;
        }
        if(stateNavigator.focusScopeNode.children.length == 1 && (lengthLayout == 0 || lengthLayout == 1) && !isShowMention) {
          if(tab == 0) Navigator.pop(context);
          Provider.of<Channels>(context, listen: false).onChangeOpenIssue(null);
        }
      } else {
        bool isOpenDrawer = (keyScaffold.currentState?.isEndDrawerOpen) ?? false;
        bool isOpenThread = Provider.of<Messages>(context, listen: false).openThread;
        Map messageImage = Provider.of<Messages>(context, listen: false).messageImage;
        if (isOpenDrawer && !isBlockEscape) {
          Navigator.maybePop(context);
        } else if (isOpenThread && messageImage['id'] == null && !isBlockEscape) {
          Provider.of<Messages>(context, listen: false).openThreadMessage(false, {});
        }
        //
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(handleKey);
    super.dispose();
  }

  getFieldOfListUser(List data, String field) {
    if (data.length  == 0 ) return "";
    var result = "";
    for (var i = 0; i < data.length; i++) {
      if (i != 0) result += ", ";
      result += (data[i]![field] ?? "");
    }
    if (result.length > 20) {
      return result.substring(0, 20) + "...";
    }
    return result;
  }

  rightSideInfo(openThread, showDirectSetting, parentMessage , showFriends , showChannelPinned, showChannelMember, showChannelSetting, isDark, deviceHeight) {
    final directMessage = Provider.of<DirectMessage>(context, listen: true).directMessageSelected;

    return (openThread || showChannelSetting ||showFriends || showChannelMember || showChannelPinned) ? showFriends ?
     Container(
       width: 330,
       child: ListMemberFriends(isDark: isDark,))
       :ResponseSidebarItem(
        itemKey: 'rightSider',
        separateSide: 'left',
        canZero: false,
        constraints: BoxConstraints(minWidth: 300, maxWidth: 700),
        elevation: 1,
        callOnRemove: () {
          Provider.of<Channels>(context, listen: false).openChannelSetting(false);
          Provider.of<Channels>(context, listen: false).openChannelPinned(false);
          Provider.of<Channels>(context, listen: false).openChannelMember(false);
          Provider.of<Messages>(context, listen: false).openThreadMessage(false, {});
        },
        child: openThread
          ? ThreadDesktop(parentMessage: parentMessage, dataDirectMessage: directMessage,)
          : Container(
            color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
            child: showChannelPinned
              ? PinnedMessage(isDark: isDark)
              : showChannelSetting
                ? ChannelSetting()
                : showChannelMember
                  ? MembersTile(isDark: isDark)
                  : showFriends
                    ? ListMemberFriends(isDark: isDark,)
                    : Container()

              ),
      ) : (directMessage.id != "") ? DirectInfoDesktop()
        : Container();
  }

  Widget _headerMentionsOrThread() {
    final selectedTab = Provider.of<User>(context, listen: true).selectedTab;
    final currentApp = Provider.of<Channels>(context, listen: false).currentApp;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            selectedTab == "mention"
                ? S.of(context).mentions
                : selectedTab == "thread"
                  ? S.of(context).threads
                  : selectedTab == "appItem"
                    ? currentApp["name"]
                    : "Add apps",
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 17,
              color: Color(0xffF0F4F8),
            ),
          ),
          selectedTab == "mention" ? DropdownOverlay(
            width: 200,
            menuDirection: MenuDirection.end,
            dropdownWindow: FilterMentions(),
            child: SvgPicture.asset('assets/icons/Adjustment.svg', color: Palette.defaultTextDark, width: 24, height: 24)
          ) : Container()
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentChannel = Provider.of<Channels>(context, listen: true).currentChannel;
    final currentApp = Provider.of<Channels>(context, listen: false).currentApp;
    final directMessage = Provider.of<DirectMessage>(context, listen: true).directMessageSelected;
    final selectedMentionDM = Provider.of<DirectMessage>(context, listen: true).selectedMentionDM;
    var currentTab = Provider.of<Workspaces>(context, listen: true).tab;
    final data = Provider.of<DirectMessage>(context, listen: true).data;
    final idMessageToJump  =  Provider.of<DirectMessage>(context, listen: true).idMessageToJump;
    final selectedTab = Provider.of<User>(context, listen: true).selectedTab;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    final showChannelSetting = Provider.of<Channels>(context, listen: true).showChannelSetting;
    final showChannelPinned = Provider.of<Channels>(context, listen: true).showChannelPinned;
    final showChannelMember = Provider.of<Channels>(context, listen: true).showChannelMember;
    final openThread = Provider.of<Messages>(context, listen: true).openThread;
    final parentMessage = Provider.of<Messages>(context, listen: true).parentMessage;
    final showDirectSetting = Provider.of<DirectMessage>(context, listen: true).showDirectSetting;
    final showFriends = Provider.of<Channels>(context, listen: true).showFriends;
    final auth = Provider.of<Auth>(context, listen: true);
    final isDark = auth.theme == ThemeType.DARK;
    final issuesSelected = Provider.of<Channels>(context, listen: true).issueSelected;
    final changeToMessage =  Provider.of<Workspaces>(context, listen: false).changeToMessage;
    final deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      key: keyScaffold,
      endDrawerEnableOpenDragGesture: false,
      endDrawer: LayoutBuilder(
        builder: (context, constraint) {
          final maxWidth = constraint.maxWidth <= 800 ? constraint.maxWidth : constraint.maxWidth * 0.9;
          return Container(
            color: isDark ? Palette.backgroundRightSiderDark : Color(0xffF3F3F3),
            width: maxWidth,
            child: Stack(
              children: [
                Container(
                  width: maxWidth,
                  child: WorkviewDesktop()
                ),
                Positioned(
                  top: 60,
                  right: 20,
                  child: FlashMessage()
                ),
                AnimatedPositioned(
                  curve: Curves.easeOutExpo,
                  duration: Duration(milliseconds: 500),
                  left: issuesSelected != null ? 0 : constraint.maxWidth,
                  child: Container(
                    height: constraint.maxHeight,
                    width: maxWidth,
                    child: issuesSelected != null ?
                      CustomSelectionArea(child: CreateIssue(issue: issuesSelected, fromMentions: issuesSelected['fromMentions']))
                      : Container(width: constraint.maxWidth)
                  )
                )
              ]
            )
          );
        }
      ),
      onEndDrawerChanged: (value) async {
        if (changeToMessage != value) Provider.of<Workspaces>(context, listen: false).changeToMessageView(!value);
        if(!value && issuesSelected != null) {
          Timer(Duration(milliseconds: 300), () => Provider.of<Channels>(context, listen: false).onChangeOpenIssue(null));
        }

        if (!value && currentTab != 0) {
          var draftIssue;

          if (issuesSelected != null && issuesSelected["type"] == "create") {
            var box = await Hive.openBox("draftsIssue");
            var boxDraftIssue = box.get(currentChannel["id"].toString());
            String description = '';
            String title = '';
            List assignees = [];
            List labels = [];
            List milestone = [];

            if (boxDraftIssue != null) {
              description = boxDraftIssue["description"] ?? "";
              title = boxDraftIssue["title"] ?? "";
              assignees = boxDraftIssue["assignees"] ?? [];
              labels = boxDraftIssue["labels"] ?? [];
              milestone = boxDraftIssue["milestone"] ?? [];
            }

            draftIssue = {
              'type': 'create',
              'description': description,
              'title': title,
              'is_closed': false,
              'assignees': assignees,
              'labels': labels,
              'milestone': milestone
            };
          }

          currentTab = Provider.of<Workspaces>(context, listen: false).tab;
          final lastFilters = Provider.of<Channels>(context, listen: false).lastFilters;
          Provider.of<Channels>(context, listen: false).tempIssueState = currentTab == 0
              ? {"issueSelected": draftIssue ?? issuesSelected, "channel_id": currentChannel["id"], "listIssueOpen": !value, 'lastPage': lastFilters["page"] ?? 1}
              : null;
        }
      },
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Palette.borderSideColorDark),
                    ),
                    color: Palette.backgroundRightSiderDark,
                  ),
                  height: 56,
                  child: Row(
                    children: [
                      ForceShowButtonForItemResponseSidebar(itemKey: 'leftSider'),
                      Expanded(
                        child: selectedTab != "channel"
                        ? _headerMentionsOrThread()
                        : Provider.of<Workspaces>(context, listen: false).tab == 0
                            ? CoverHeaderMenu() : WorkspaceName(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: isDark ? Palette.backgroundRightSiderDark : Palette.backgroundRightSiderLight,
                    child: currentTab == 0 ?
                      selectedMentionDM
                        ? CustomSelectionArea(child: ListMentionsConversation())
                        : (data.length > 0)
                          ? MessageViewMacOS(
                            dataDirectMessage: directMessage,
                            id: directMessage.id,
                            name: getFieldOfListUser(directMessage.user, "full_name"),
                            avatarUrl: "",
                            idMessageToJump: idMessageToJump
                          ) : Container() : Container(
                          child: selectedTab == "mention"
                            ? ListMentionsDesktop()
                            : selectedTab == "thread"
                              ? ListThreadsDesktop(workspaceId: currentWorkspace["id"])
                              : selectedTab == "app"
                                ? ListApp(workspaceId: currentWorkspace["id"])
                                : selectedTab == "appItem"
                                  ? WorkspaceApps(app: currentApp, workspaceId: currentWorkspace["id"])
                                  : currentChannel["id"] != null
                                    ? ConversationMacOS(id: currentChannel['id'], name: currentChannel['name'])
                                    : Container()
                    )
                  ),
                ),
              ],
            ),
          ),
          (selectedTab == "channel" || selectedTab == "mention") && (openThread || showDirectSetting || showChannelPinned || showFriends || showChannelMember || showChannelSetting)
            ? rightSideInfo(openThread, showChannelSetting, parentMessage, showFriends, showChannelPinned, showChannelMember, showChannelSetting, isDark, deviceHeight) : Container(),
        ],
      ),
    );
  }
}

class ButtonOpenView extends StatefulWidget {
    const ButtonOpenView({
    Key? key,
    required this.isTap
  }) : super(key: key);

  final bool isTap;

  @override
  _ButtonOpenViewState createState() => _ButtonOpenViewState();
}

class _ButtonOpenViewState  extends State<ButtonOpenView> {

  @override
  Widget build(context) {
    final numberUnreadIssues = Provider.of<Channels>(context, listen: true).numberUnreadIssues;
    final keyScaffold = Provider.of<Auth>(context, listen: true).keyDrawer;

    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(top: 12, bottom: 10),
          decoration: BoxDecoration(
            color: !widget.isTap ? Colors.transparent : Color(0xff2E2E2E),
            border: !widget.isTap ? Border.all(
              color: Color(0xff828282)
            ) : Border(),
            borderRadius: BorderRadius.all(Radius.circular(2))
          ),
          width: 100,

          child: HoverItem(
            colorHover: !widget.isTap ? Palette.hoverColorDefault : Colors.white.withOpacity(0.15),
            child: InkWell(
              onTap: () => {
                Provider.of<Workspaces>(context, listen: false).changeToMessageView(false),
                widget.isTap ? Navigator.pop(context) : keyScaffold.currentState!.openEndDrawer()
              },
              child: Container(
                padding: EdgeInsets.all(6),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SvgPicture.asset('assets/icons/Issue.svg'),
                    Text(S.current.issues, style: TextStyle(color: Colors.white)),
                    Container()
                  ],
                ),
              )
            ),
          ),
        ),
        if (numberUnreadIssues > 0) Positioned(
          top: 10,
          right: 0,
          child: IconBadge()
        ),
      ],
    );
  }
}

class WorkspaceName extends StatefulWidget {
  @override
  State<WorkspaceName> createState() => _WorkspaceNameState();
}

class _WorkspaceNameState extends State<WorkspaceName> {
  bool tooltipMember = false;
  bool tooltipPinMessage = false;
  bool tooltipChannelInfo = false;
  bool tooltipPinButton = false;
  bool tooltipInviteMember = false;

  @override
  Widget build(BuildContext context) {
    final currentChannel = Provider.of<Channels>(context, listen: true).currentChannel;
    final showChannelSetting = Provider.of<Channels>(context, listen: true).showChannelSetting;
    final showChannelPinned = Provider.of<Channels>(context, listen: true).showChannelPinned;
    final showChannelMember = Provider.of<Channels>(context, listen: true).showChannelMember;
    final showDirectSetting = Provider.of<DirectMessage>(context, listen: true).showDirectSetting;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    final currentMember = Provider.of<Channels>(context, listen: true).currentMember;
    final currentMemWs = Provider.of<Workspaces>(context, listen: false).currentMember;
    final members = Provider.of<Channels>(context, listen: false).channelMember;
    final auth = Provider.of<Auth>(context, listen: true);
    final selectedTab = Provider.of<User>(context, listen: true).selectedTab;
    final isDark  = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Flexible(
                  child: Container(
                    child: Text(
                      currentChannel["id"] != null ? "${currentChannel["name"]}" : "",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: Palette.defaultTextDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                JustTheTooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  preferredDirection: AxisDirection.down,
                  backgroundColor: isDark ? Color(0xFF1c1c1c): Colors.white,
                  offset: 8,
                  tailLength: 10,
                  tailBaseWidth: 10,
                  fadeOutDuration: Duration(milliseconds: 10),
                  content: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Material(
                      child: Text(currentChannel["pinned"] == true ? S.of(context).unPinThisChannel : S.of(context).pinThisChannel),
                      color: Colors.transparent
                    ),
                  ),
                  child: HoverItem(
                    colorHover: Palette.hoverColorDefault,
                    child: Container(
                      width: 30, height: 30,
                      child: Transform.rotate(
                        angle: 5.6,
                        child: InkWell(
                          onHover: (hover) => setState(() {
                            tooltipPinButton = hover;
                          }),
                          onTap: () {
                            Map member = Map.from(currentMember);
                            member["pinned"] = !member["pinned"];
                            Provider.of<Channels>(context, listen: false).changeChannelMemberInfo(auth.token, currentWorkspace["id"], currentChannel["id"], member, "pin");
                          },
                          child: Icon(currentChannel["pinned"] == true ? CupertinoIcons.pin : CupertinoIcons.pin_slash, size: 15, color: Palette.topicTile),
                        ),
                      ),
                    ),
                  ),
                ),
                JustTheTooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  preferredDirection: AxisDirection.down,
                  backgroundColor: isDark ? Color(0xFF1c1c1c): Colors.white,
                  offset: 8,
                  tailLength: 10,
                  tailBaseWidth: 10,
                  fadeOutDuration: Duration(milliseconds: 10),
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Material(child: Text("Invite People"), color: Colors.transparent,),
                  ),
                  child: HoverItem(
                    colorHover: Palette.hoverColorDefault,
                    child: InkWell(
                      onHover: (hover) => setState(() {
                        tooltipInviteMember = hover;
                      }),
                      onTap: () {
                        currentMemWs["role_id"] <= 2 || currentMemWs['user_id'] == currentChannel['owner_id']
                          ? onShowInviteChannelDialog(context)
                          : showModal(
                              context: context,
                              builder: (_) => SimpleDialog(
                              children: <Widget>[
                                  new Center(child: new Container(child: new Text('Bạn không có đủ quyền để thực hiện thao tác')))
                              ])
                            );
                      },
                      child: Container(
                        width: 30, height: 30,
                        child: Icon(PhosphorIcons.userPlus, size: 17, color: Palette.topicTile),
                      ),
                    )
                  ),
                )
              ],
            ),
          ),
          Row(
            children: [
              ListAction(
                action: S.current.members,
                child: InkWell(
                  onTap: () {
                    Provider.of<Channels>(context, listen: false).openChannelMember(!showChannelMember);
                    Provider.of<Messages>(context, listen: false).changeOpenThread(false);
                  },
                  child: Container(
                    margin: EdgeInsets.all(8),
                    child: Row(
                      children: [
                        SvgPicture.asset('assets/icons/memberIcon.svg', color: showChannelMember ? Colors.blue : Palette.topicTile),
                        SizedBox(width: 1),
                        Text(members.length.toString(), style: TextStyle(fontSize: 10.5, color: Palette.topicTile),)
                      ],
                    ),
                  ),
                ),
                isDark: isDark,
                arrowTipDistance: 6
              ),
              SizedBox(width: 4),
              ListAction(
                action: S.current.pinMessages,
                child: InkWell(
                  onTap: () {
                    Provider.of<Channels>(context, listen: false).openChannelPinned(!showChannelPinned);
                    Provider.of<Messages>(context, listen: false).changeOpenThread(false);
                  },
                  child: Container(
                    margin: EdgeInsets.all(8),
                    child: SvgPicture.asset('assets/icons/pinned.svg', color: showChannelPinned? Colors.blue : Palette.topicTile),
                  ),
                ),
                isDark: isDark,
                arrowTipDistance: 6
              ),
              SizedBox(width: 4),
              (selectedTab == "channel" && showDirectSetting) ? Container() : ListAction(
                action: S.current.details,
                child: InkWell(
                  onTap: () {
                    Provider.of<Channels>(context, listen: false).openChannelSetting(!showChannelSetting);
                    Provider.of<Messages>(context, listen: false).changeOpenThread(false);
                  },
                  child: Container(
                    margin: EdgeInsets.all(8),
                    child: SvgPicture.asset('assets/icons/error_outline.svg', color: showChannelSetting ? Colors.blue : Palette.topicTile),
                  ),
                ),
                isDark: isDark,
                arrowTipDistance: 6
              ),
              SizedBox(width: 12),
              ButtonOpenView(isTap: false)
            ],
          )
        ],
      ),
    );
  }
}

class CoverHeaderMenu extends StatefulWidget {
  @override
  State<CoverHeaderMenu> createState() => _CoverHeaderMenuState();
}

class _CoverHeaderMenuState extends State<CoverHeaderMenu> {
  bool tooltip = false;
  OverlayEntry? roomEntry;

  getRoomActive(id) {
    return Provider.of<RoomsModel>(context, listen: true).rooms.any((element) => element["id"] == id && element["isActive"] == true);
  }

  @override
  Widget build(BuildContext context) {
    final selectedFriend = Provider.of<DirectMessage>(context, listen: true).selectedFriend;
    final directMessage = Provider.of<DirectMessage>(context, listen: true).directMessageSelected;
    final showDirectSetting = Provider.of<DirectMessage>(context, listen: true).showDirectSetting;
    final isDark  = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;

    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: !selectedFriend
              ? Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  directMessage.displayName,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white
                  ),
                )
              ): Container()
          ),
          if (!selectedFriend && directMessage.user.length == 2) TextButton(
            child: Icon(PhosphorIcons.phoneLight, color: Colors.white, size: 22),
            style: ButtonStyle(
              fixedSize: MaterialStateProperty.all(Size(35, 35)),
              shape: MaterialStateProperty.all(CircleBorder()),
              overlayColor: MaterialStateProperty.all(Palette.hoverColorDefault)
            ),
            onPressed: () {
              final currentUser = Provider.of<User>(context, listen: false).currentUser;
              final users = directMessage.user;
              if (users.length == 2) {
                final index = users.indexWhere((e) => e["user_id"] != currentUser["id"]);
                final otherUser = index  == -1 ? {} : users[index];
                p2pManager.createAudioCall(context, otherUser, directMessage.id);
              }
            }
          ),
          if (!selectedFriend) TextButton(
            child: getRoomActive(directMessage.id) ? Icon(PhosphorIcons.videoCameraFill, color: Colors.red, size: 22) : Icon(PhosphorIcons.videoCameraLight, color:Colors.white, size: 22,),
            style: ButtonStyle(
              fixedSize: MaterialStateProperty.all(Size(35, 35)),
              shape: MaterialStateProperty.all(CircleBorder()),
              overlayColor: MaterialStateProperty.all(Palette.hoverColorDefault)
            ),
            onPressed: () {
              final currentUser = Provider.of<User>(context, listen: false).currentUser;
              final users = directMessage.user;
              if (users.length == 2) {
                final index = users.indexWhere((e) => e["user_id"] != currentUser["id"]);
                final otherUser = index  == -1 ? {} : users[index];
                p2pManager.createVideoCall(context, otherUser, directMessage.id);
              } else if (users.length > 2) {
                String roomCreated = directMessage.id.toString();

                roomEntry = OverlayEntry(
                  builder: (context) {
                    return RoomUI(roomId: roomCreated, roomName: directMessage.name , displayName: currentUser["full_name"], terminate: () => roomEntry?.remove());
                  }
                );
                Overlay.of(context)!.insert(roomEntry!);
              }
            },
          ),
          SizedBox(width: 20),
          JustTheTooltip(
            triggerMode: TooltipTriggerMode.tap,
            preferredDirection: AxisDirection.left,
            backgroundColor: isDark ? Color(0xFF1c1c1c): Colors.white,
            offset: 12,
            tailLength: 10,
            tailBaseWidth: 10,
            fadeOutDuration: Duration(milliseconds: 10),
            content: Material(
              child: Container(
                padding: EdgeInsets.all(8),
                child: Text(S.current.directSettings)
              ),
              color: Colors.transparent
            ),
            child: InkWell(
              onHover: (hover) => setState(() {
                tooltip = hover;
              }),
              onTap: () {
                Provider.of<DirectMessage>(context, listen: false).openDirectSetting(!showDirectSetting);
                Provider.of<Messages>(context, listen: false).changeOpenThread(false);
                Provider.of<Channels>(context, listen: false).openFriends(false);
              },
              child: Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 24),
                child: SvgPicture.asset('assets/icons/error_outline.svg', color: showDirectSetting ? Colors.blue : Palette.topicTile),
              ),
            ),
          )
        ]
      ),
    );
  }
}

class FlashMessage extends StatelessWidget {
  const FlashMessage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final showFlashMessage = Provider.of<Channels>(context, listen: true).showFlashMessage;

    return showFlashMessage ? Container(
      height: 60,
      width: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: Offset(1, 3),
            blurRadius: 8
          )
        ]
      ),
      child: Row(
        children: [
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(7), bottomLeft: Radius.circular(7) ),
              color: Color(0xff42b873),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle
              ),
              width: 20,
              height: 20,
              child: Icon(PhosphorIcons.checkBold, size: 15, color: Color(0xff42b873),)
            ),
          ),
          SizedBox(width: 12,),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(S.current.success, style: TextStyle(color: Color(0xff42b873), fontSize: 15, fontWeight: FontWeight.w500),),
              SizedBox(height: 4,),
              Text(S.current.issueCreateSuccess, style: TextStyle(color: Color(0xff727f94)),)
            ],
          )
        ],
      ),
    ) : SizedBox();
  }
}