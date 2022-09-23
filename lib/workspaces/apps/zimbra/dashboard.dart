import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:popover/popover.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/workspaces/apps/zimbra/login_zimbra.dart';
import 'package:workcake/workspaces/apps/zimbra/new_mail.dart';
import 'package:workcake/workspaces/apps/zimbra/service.dart';

import 'config.dart';
import 'conv.dart';

class DashBoardZimbra extends StatefulWidget {
  final int workspaceId;
  const DashBoardZimbra({Key? key, required this.workspaceId}) : super(key: key);

  @override
  State<DashBoardZimbra> createState() => DashBoardZimbraState();
}

class DashBoardZimbraState extends State<DashBoardZimbra> {
  List<Map> headersList = [
    {"id": "inbox", "label": "Inbox"},
    {"id": "sent", "label": "Sent"},
    {"id": "drafts", "label": "Drafts"},
    {"id": "trash", "label": "Trash"}
  ];

  String selectedHeader = "inbox";
  List<MailZimbra> dataMails = [];
  Map folderData = {};
  ScrollController scrollController = new ScrollController();
  bool isFetching = false;
  bool? isLogined;
  int limit = 50;
  Map config = {};

  @override
  void initState(){
    super.initState();
    initAccount();
    scrollController.addListener(() {
      if (scrollController.position.extentAfter < 100){
        getMail({});
      }
    });
  }

  @override
  void didUpdateWidget(oldWidget){
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId) initAccount();
  }

  Future initAccount() async {
    try {
      dataMails = [];
      LazyBox box = Hive.lazyBox("pairKey");
      Map? data = await box.get("zimbra_${widget.workspaceId}");
      Map? curentAccount = (data ?? {})["current_account_zimbra"];
      if (curentAccount != null){
        // setCurrentAccount
        var indexCurrentAccount = ConfigZimbra.instance.accounts.indexWhere((element) => element.email == curentAccount["email"] && element.workspaceId == widget.workspaceId);
        if (indexCurrentAccount !=  -1) {
          ConfigZimbra.instance.currentAccountZimbra =  ConfigZimbra.instance.accounts[indexCurrentAccount];
          ConfigZimbra.instance.currentAccountZimbra!.convIdUnread = [];
          ServiceZimbra.streamAccounts.add(ConfigZimbra.instance.accounts);
        }
        getMail({});
        isLogined = true;
      } else {
        isLogined = false;
        ConfigZimbra.instance.currentAccountZimbra = null;
      }
      setState(() { });
    } catch (e) {
       setState(() {

        });
    }
  }

  Future getDataFolder() async {
    folderData = await ServiceZimbra.getFolderData();
  }

  Future getMail(Map config) async {
    if (isFetching) return;
    isFetching = true;
    try {
      getDataFolder();
      config = {
        "auth_token": "",
        "limit": limit,
        "offset": dataMails.length,
        "query": "in:$selectedHeader",
        "workspace_id": widget.workspaceId,
        "recip": selectedHeader == "inbox" ? "0" : 1,
      };
      var data = await ServiceZimbra.getMail(config);
      var total = dataMails +  data["convs"];
      Map<int, MailZimbra> index= {};
      for (var i = 0; i < total.length; i++){
        if (index[total[i].id] == null) index[total[i].id] = total[i];
      }
      dataMails = index.values.toList();
      setState(() {

      });
      isFetching = false;
    } catch (e, t) {
      print("_____________$e $t");
      isFetching = false;
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    var isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;
    return isLogined ==  null ? Container() : !isLogined! ? LoginZimbra(workspaceId: widget.workspaceId, onLoginSuccess: initAccount) : Container(
      child: Column(
        children:[
          Container(
            height: 56,
            padding: EdgeInsets.symmetric(horizontal: 24),
            color: isDark ? Color(0xFF4c4c4c) : Color(0xFFededed),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Row(
                      children: headersList.map<Widget>((e){
                        bool isSelected = selectedHeader == e["id"];
                        int numUnread = folderData[e["id"]]?["unread_count"] ?? 0;
                        return GestureDetector(
                          onTap: () {
                            selectedHeader = e["id"];
                            dataMails = [];
                            getMail({});
                            setState(() {

                            });
                          },
                          child: HoverItem(
                            child: Container(
                              height: 56,
                              margin: EdgeInsets.only(right: 32),
                              decoration: BoxDecoration(
                                border: isSelected ? Border(
                                  bottom:  BorderSide(
                                    color: isSelected ?
                                      isDark ?Color(0xFFFAAD14) : Color(0xFF1890ff)
                                      : isDark ? Color(0xFF4c4c4c) : Color(0xFFededed),
                                    width: 2
                                  )
                                ) : null
                              ),
                              child: Center(child: Text("${e["label"]} ${numUnread > 0 ? "($numUnread)" : ""}" , style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500, color: isSelected ? isDark ?Color(0xFFFAAD14) : Color(0xFF1890ff) :  isDark ? Color(0xFFc9c9c9) : Color(0xFF828282),
                              ))),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                     GestureDetector(
                      onTap: (){
                        showDialog(
                          context: context,
                          builder: (BuildContext c) {
                            return Dialog(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.all(Radius.circular(8))
                                ),
                                height: MediaQuery.of(context).size.height* 0.85,
                                width: MediaQuery.of(context).size.width* 0.85,
                                child: NewMailZimbra(workspaceId: widget.workspaceId,),
                              ),
                            );
                          }
                        );
                      },
                      child: HoverItem(
                        child: Text("New"),
                      )
                    ),
                  ],
                ),
                AccountView(workspaceId: widget.workspaceId,)
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: dataMails.length,
              itemBuilder: (BuildContext context, int index) {
                MailZimbra e = dataMails[index];
                // print(e.emailAdds);
                return GestureDetector(
                  onTap:(){
                    // open mail
                    showDialog(
                      context: context,
                      builder: (BuildContext c) {
                        return AlertDialog(
                          backgroundColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                          content: Container(
                            height: MediaQuery.of(context).size.height* 0.8,
                            width: MediaQuery.of(context).size.width* 0.8,
                            child: ConvDetailZimbra(key: ServiceZimbra.convDetailZimbra, conv: e, workspaceId: widget.workspaceId,),
                          ),
                        );
                      }
                    );
                  },
                  child: HoverItem(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom:  BorderSide(
                            color: isDark ? Color(0xFF5e5e5e) : Color(0xFFdbdbdb),
                            width: 1
                          )
                        )
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 200,
                            child: Row(
                              children: [
                                Transform.scale(
                                  scale: 0.8,
                                  child: Checkbox(
                                    activeColor: Color(0xFFFAAD14),
                                    checkColor: Color(0xFF4c4c4c),
                                    value: false, onChanged: (value) {

                                  }),
                                ),
                                Container(width: 16,),
                                e.emailAdds.length > 0 ? Stack(
                                  children: e.emailAdds.map((ea) => Center(child: CachedAvatar(null, name: (ea.displayName ?? "").split("").first, width: 24, height: 24))).toList(),
                                ) : Container(),
                                Container(width: 8,),
                                // avatr
                                Expanded(
                                  child: Container(
                                    child: Text(e.emailAdds.map((em) => em.partName ?? em.displayName ?? em.address.split("@").first).join(", "), style: TextStyle(
                                      overflow: TextOverflow.ellipsis, fontSize: 12,
                                      fontWeight: e.unreadMessagesChild > 0 ? FontWeight.w500 : FontWeight.w200,
                                      color: isDark ? Color(0xFFffffff) : Color(0xFF3d3d3d)
                                    )),
                                  ),
                                ),
                                Container(
                                  child: Text(e.countMessagesChild > 1 ? " (${e.countMessagesChild })" : "", style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w200,
                                    color: isDark ? Color(0xFFffffff) : Color(0xFF3d3d3d)
                                  )),
                                ),
                                Container(width: 8,),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.only(left: 24, right: 24),
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(width: 1, color: isDark ? Color(0xFF5e5e5e) : Color(0xFFdbdbdb)),
                                  right: BorderSide(width: 1, color: isDark ? Color(0xFF5e5e5e) : Color(0xFFdbdbdb)),
                                )
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  e.subject == "" && e.snippet == "" ? Container() : Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(text: e.subject, style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: e.unreadMessagesChild > 0 ? FontWeight.w500 : FontWeight.w300,
                                          color: isDark
                                            ? e.unreadMessagesChild > 0 ? Color(0xFFffffff) : Color(0xFF828282)
                                            : e.unreadMessagesChild > 0 ? Color(0xFF3d3d3d) : Color(0xFF828282)
                                        )),
                                        TextSpan(text: e.subject == "" ? "" : "   "),
                                        TextSpan(text: e.snippet, style: TextStyle(
                                          overflow: TextOverflow.ellipsis, fontSize: 12,
                                          fontWeight: FontWeight.w200,
                                          color: isDark
                                            ? e.unreadMessagesChild > 0 ? Color(0xFFffffff) : Color(0xFF828282)
                                            : e.unreadMessagesChild > 0 ? Color(0xFF3d3d3d) : Color(0xFF828282)
                                        ))
                                      ]
                                    ),
                                    maxLines: 1,
                                  ),
                                  e.hasAtts ? Wrap(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(top: e.subject == "" && e.snippet == "" ? 0 : 8),
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(Radius.circular(16)),

                                          border: Border.all(width: 1, color: Color(0xFF5e5e5e))
                                        ),
                                        child: Text("atts", style: TextStyle(color: Color(0xFFa6a6a6))),
                                      ),
                                    ],
                                  ) : Container()
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 120,
                            alignment: Alignment.centerRight,
                            child: Text(DateFormatter().renderTime(DateTime.fromMicrosecondsSinceEpoch(e.currentTime * 1000), type: "yMMMMd"), style: TextStyle(fontSize: 12, color: isDark ? Color(0xFFffffff) : Color(0xFF3d3d3d))),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ]
      )
    );
  }
}

class AccountView extends StatefulWidget {
  final int workspaceId;
  const AccountView({Key? key, required this.workspaceId}) : super(key: key);

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  @override
  Widget build(BuildContext context) {
    var isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;
    return  ConfigZimbra.instance.currentAccountZimbra == null ? Container() : Container(
      child: Row(
        children: [
          GestureDetector(
            onTap: (){
              showPopover(
                context: context,
                // barrierLabel: Colors.red,
                backgroundColor: isDark ? Color(0xff2E2E2E) : Color(0xFFffffff),
                transitionDuration: const Duration(milliseconds: 50),
                direction: PopoverDirection.bottom,
                barrierColor: Colors.transparent,
                width: 200,
                height: ConfigZimbra.instance.accounts.length * 60 + 80,
                arrowHeight: 0,
                arrowWidth: 0,
                arrowDyOffset: 20,
                arrowDxOffset: -65,
                bodyBuilder: (c) => Container(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Column(
                        children: ConfigZimbra.instance.accounts.map<Widget>((e) {
                          return GestureDetector(
                            onTap: () {
                              ServiceZimbra.switchAccount(e, widget.workspaceId);
                            },
                            child: HoverItem(
                              colorHover: isDark ? Color(0xFF292929) : Color(0xFFffffff),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                                padding: EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    CachedAvatar("", name: e.email, height: 40, width: 40,),
                                    Container(width: 8,),
                                    Container(width: 100, child: Text(e.email, maxLines: 1, style: TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis)))
                                  ],
                                ),
                              ))
                          );
                        }).toList(),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await ServiceZimbra.logout(widget.workspaceId, type: "switch");
                          Navigator.pop(c);
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          child: HoverItem(child: Text("Switch account"))),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await ServiceZimbra.logout(widget.workspaceId);
                          Navigator.pop(c);
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          child: HoverItem(child: Text("Logout"))),
                      )
                    ],
                  ),
                )
              );
            },
            child: HoverItem(child: CachedAvatar("", name: ConfigZimbra.instance.currentAccountZimbra!.email, height: 40, width: 40,)))
        ],
      ),
    );
  }
}
