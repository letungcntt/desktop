import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/common/validators.dart';
import 'package:workcake/components/friends/friend_list.dart';
import 'package:workcake/components/message_item/attachments/text_file.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/providers/providers.dart';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';
import '../common/cached_image.dart';
import 'package:http/http.dart' as http;


class InviteMemberMacOS extends StatefulWidget {
  final type;
  final isKeyCode;

  InviteMemberMacOS(
    {
      this.type,
      this.isKeyCode
    }
  );
  @override
  _InviteMemberMacOSState createState() => _InviteMemberMacOSState();
}
extension ListX on List {
  List filter(String text) {
    final _text = Utils.unSignVietnamese(text);
    return this.where((element) => (Utils.unSignVietnamese(element["full_name"])?? "").contains(_text) 
    || (element[""] ?? "").contains(_text) 
    || (element[""] ?? "").contains(_text))
    .toList();
  }
}

extension Unique<E, Id> on List<E> {
  List<E> unique([Id Function(E element)? id, bool inplace = true]) {
    final ids = Set();
    var list = inplace ? this : List<E>.from(this);
    list.retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
    return list;
  }
}
class _InviteMemberMacOSState extends State<InviteMemberMacOS> {
  final TextEditingController _invitePeopleController = TextEditingController();
  final TextEditingController _inviteEmailController = TextEditingController();
  final TextEditingController _inviteByCode = TextEditingController();

  List members = [];
  var _debounce;
  var textCode;
  var auth;
  Map currentWorkspace = {};
  Map currentChannel = {};
  bool searching = false;
  bool validEmailOrNumberPhone = true;
  String messageInvite = "";
  var errorMessage = "";
  List friendList = [];
  String token = "";
  bool doneChecking = false;
  bool sentToAnonymous = false;
  List friends = [];
  List workspaceMembers = [];
  var keyCode;
  String textSearch = "";


  @override
  void dispose() {
    _invitePeopleController.dispose();
    _inviteEmailController.dispose();
    _inviteByCode.dispose();
    super.dispose();
  }

  getMembersWorkspaceAndFriends() {
    workspaceMembers = Provider.of<Workspaces>(context, listen: false).members;
    friends = Provider.of<User>(context, listen: false).friendList;
  }

  renderKeyCodeInvite() {
    var channelGeneral;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final listChannelGeneral = Provider.of<Channels>(context, listen: false).data.where((e) => e["is_general"] == true).toList();
    final indexChannel = listChannelGeneral.indexWhere((e) => e['workspace_id'] == currentWorkspace["id"]);
    var _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _rnd = Random();
    String getRandomString(int length) => String.fromCharCodes(Iterable.generate(length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
    if (indexChannel != -1) {
      channelGeneral = listChannelGeneral[indexChannel];
    }
    keyCode = (widget.type == "toWorkspace" && channelGeneral != null) ? "${getRandomString(4)}-${currentWorkspace["id"]}-${channelGeneral["id"]}" : "${getRandomString(4)}-${currentWorkspace["id"]}-${currentChannel["id"]}" ;
  }

  onSearchMemberToInvite(token, text) async {
    textSearch = text;
    sentToAnonymous = false;
    switch (widget.type) {
      case "toWorkspace":
        setState(() => members = friends.filter(text).unique((x) => x["id"]));
        break;
      case "toChannel":
        setState(() => members = workspaceMembers.filter(text).unique((x) => x["id"]));
        break;
      default:
    }
  }

  onInviteToChannel(token, workspaceId, channelId, value) async {
    this.setState(() {
      textSearch = value;
    });
    if (value != "") {
       onSearchMemberToInvite(auth.token, value);
    } else {
      setState(() {
        members = [];
      });
    }
  }

 validate(id) {
    final workspaceMembers = Provider.of<Workspaces>(context, listen: true).members;
    final channelMember = Provider.of<Channels>(context, listen: true).channelMember;
    bool check = true;
    List list = widget.type == 'toWorkspace' ? workspaceMembers : channelMember;

    for (var member in list) {
      if (id == member["id"]) {
        check = false;
      }
    }
    return check;
  }

  _invitePeople(token, workspaceId, channelId, text) async {
    final validEmail = Validators.validateEmail(text);
    final validPhoneNumber = Validators.validatePhoneNumber(text);
    if(text==""){
      return setState(() {
        validEmailOrNumberPhone = false;
        messageInvite = S.current.inputCannotEmpty;
      });
    }
    if (validEmail || validPhoneNumber) {
      setState(() {
        validEmailOrNumberPhone = true;
      });
      if (widget.type == 'toWorkspace') {
        messageInvite = await Provider.of<Workspaces>(context, listen: false).inviteToWorkspace(token, workspaceId, text, validEmail ? 1 : 2, null);
      } else {
        messageInvite = await Provider.of<Channels>(context, listen: false).inviteToChannel(token, workspaceId, channelId, text, validEmail ? 1 : 2, null);
      }
      setState(() {});
    } else {
      setState(() {
        validEmailOrNumberPhone = false;
        messageInvite = "Invite Failure";
      });
    }
  }

  checkInvite(userId, workspaceId, channelId) async{
    bool check = false;
    var url;
    var resData;
    if (widget.type == "toWorkspace"){
      url = Utils.apiUrl + "/workspaces/$workspaceId/get_invite?token=$token";
      final response = await http.post(Uri.parse(url),headers: Utils.headers,
        body: json.encode({"user_id": userId})
      );
      resData = json.decode(response.body);
      doneChecking = true;
    }
    else{
      url = Utils.apiUrl + "/workspaces/$workspaceId/channels/$channelId/get_invite?token=$token";
      final response = await http.post(Uri.parse(url), headers: Utils.headers,
        body: json.encode({"user_id": userId})
      );
      resData = json.decode(response.body);
      doneChecking = true;
    }

    if (resData["success"] == true){
      check = resData["is_invited"];
    }
    return check ? "Invited" : "Invite";
  }

  joinChannelByCode() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    String text = '';
    if (Utils.checkedTypeEmpty(textCode)) {
      try {
        var responseMessage = await Provider.of<Channels>(context, listen: false).joinChannelByCode(token, textCode, currentUser);
        Provider.of<Workspaces>(context, listen: false).getInfoWorkspace(token, currentWorkspace['id'], context);
          if (responseMessage == true) {
            Navigator.of(context).pop();
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return CupertinoAlertDialog(
                  title: Text(S.of(context).joinChannelSuccess,style: TextStyle(color: Colors.green),),
                  // content: "Join workspace was successful"
                );
              }
            );
          } else if (responseMessage == false){
            Navigator.of(context).pop();
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return CupertinoAlertDialog(
                  title: Text(S.of(context).joinChannelFail),
                );
              }
            );
          }
          else text = responseMessage["message"];
      } catch (e) {
        text = S.current.syntaxError;
      }
    }
    else text = S.current.inputCannotEmpty;

    setState(() => errorMessage = text);
  }

  
@override
  void initState() {
    super.initState();
    renderKeyCodeInvite();
    getMembersWorkspaceAndFriends();
    this.setState(() {
      friendList = Provider.of<User>(context, listen: false).friendList;
      token = Provider.of<Auth>(context, listen: false).token;
      currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    });
    
  }
  _invite(token, workspaceId, channelId , user) async {
    String email = user["email"] ?? "";
    if (widget.type == 'toWorkspace') {
      Provider.of<Workspaces>(context, listen: false).inviteToWorkspace(token, currentWorkspace["id"], email, 1, user["id"]);
    } else {
      if (currentChannel["is_private"]) {
        Provider.of<Channels>(context, listen: false).inviteToChannel(token, currentWorkspace["id"], currentChannel["id"], email, 1, user["id"]);
      } else {
        Provider.of<Channels>(context, listen: false).inviteToPubChannel(token, currentWorkspace["id"], currentChannel["id"], user["id"]);
      }
    }
  }

  getListInvitation(currentWorkspace) {
    var key = "${currentWorkspace['id']}";
    var box = Hive.box('invitationHistory');
    List invitationHistory = box.get(key) ?? [];
    List list = [];

    final members = Provider.of<Workspaces>(context, listen: true).members;

    for (var i = 0; i < invitationHistory.length; i++) {
      if (DateTime.now().isBefore(invitationHistory[i]['date'].add(Duration(days: 29)))) {
        final index = members.indexWhere((e) => e["email"] == invitationHistory[i]['email']);
        bool isAccepted = index != -1;
        invitationHistory[i]['isAccepted'] = isAccepted;
        list.add(invitationHistory[i]);
      }
    }
    
    box.put(key, list);

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    final listChannelGeneral = Provider.of<Channels>(context, listen: false).data.where((e) => e["is_general"] == true).toList();
    final indexChannel = listChannelGeneral.indexWhere((e) => e['workspace_id'] == currentWorkspace["id"]);
    var channelGeneral;

    const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _rnd = Random();

    String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
        length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

    if (indexChannel != -1) {
      channelGeneral = listChannelGeneral[indexChannel];
    }

    final keyCode = (widget.type == "toWorkspace" && channelGeneral != null) ? "${getRandomString(4)}-${currentWorkspace["id"]}-${channelGeneral["id"]}" : "${getRandomString(4)}-${currentWorkspace["id"]}-${currentChannel["id"]}" ;

    List invitationHistory = getListInvitation(currentWorkspace);

    return (widget.isKeyCode != null && !widget.isKeyCode) ? Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xff3D3D3D) : Colors.white,
        borderRadius: BorderRadius.circular(5)
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if(widget.type != "toWorkspace") Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 24,bottom: 14,left: 24),
                  child: Text(S.current.descInvite, style: TextStyle(fontSize: 14,color: isDark ?  Palette.defaultTextDark : Color(0xff323F4B),),),
                ),
                 Container(
                  margin: EdgeInsets.only(bottom: 8, left: 24, right: 24),
                  height: 40,
                  child: CupertinoTextField(
                    placeholder: S.current.searchMember,
                    placeholderStyle: TextStyle(fontFamily: "Roboto", color: isDark ? Colors.white.withOpacity(0.75) : Colors.black.withOpacity(0.65), fontSize: 13.0),
                    style: TextStyle(fontFamily: "Roboto", color: isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.85), fontSize: 13.0),
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    prefix: Container(margin: EdgeInsets.only(left: 12), child: Icon(Icons.search, size: 18, color: isDark ? Colors.white.withOpacity(0.75) : Colors.black.withOpacity(0.65))),
                    autofocus: true,
                    controller: _invitePeopleController,
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color:  Color(0xffA6A6A6)),
                      borderRadius: BorderRadius.circular(4)
                    ),
                    onChanged: (value) {
                    if (_debounce?.isActive ?? false) _debounce.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                          if (value != "") {
                            onSearchMemberToInvite(auth.token, value);
                          } else {
                            setState(() => {members = [], textSearch = ""});
                          }
                        }
                      );
                    },
                  )
                )
              ]
            ),
            Container(
              padding: EdgeInsets.only(top: 12, left: 24, bottom: 8),
              child: Text(
                _invitePeopleController.text == ""
                    ? widget.type == "toWorkspace"
                      ? S.current.yourFriend
                      : S.current.listWorkspaceMember
                    : S.current.results,
                style: TextStyle(color: isDark ? Color(0xffC9C9C9) : Color(0xff828282), fontSize: 13, fontWeight: FontWeight.w400)
              )
            ),
            Container(
              padding: const EdgeInsets.only(left: 10.0, right: 10,top: 4),
              constraints: widget.type == "toWorkspace" ? invitationHistory.length > 0 ?
              BoxConstraints(
                minHeight: 120, maxHeight: 210
              ) : BoxConstraints(
                minHeight: 120, maxHeight: 284
              ) : BoxConstraints(
                minHeight: 120, maxHeight: 210
              ),
              decoration: BoxDecoration( color: isDark ? Color(0xff3D3D3D) : Color(0xffF8F8F8),),
              child: (textSearch != "" ) || members.length > 0 
              ? !searching 
              ? members.length != 0
              ? Container(
                padding: const EdgeInsets.only(left: 13, right: 13),
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    return ListAction(
                      isDark: isDark,
                      action: "",
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 1.0,
                            color:isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9),
                          ),
                        ),
                        child: ListTile(
                          leading: CachedImage(
                            members[index]["avatar_url"],
                            width: 32,
                            height: 32,
                            isAvatar: true,
                            radius: 20,
                            name: members[index]["full_name"]
                          ),
                          title: Text("${Utils.getUserNickName(members[index]["id"]) ?? members[index]["full_name"]}", style: TextStyle(fontSize: 14,fontWeight: FontWeight.w400,color: isDark ? Color(0xffffffff):Color(0xff3D3D3D)),),
                          trailing: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                            ),
                            height: 28, width: 90,
                            child: validate(members[index]["id"]) == false  
                              ? Center(
                                  child: Text( S.current.acceptInvite , 
                                  style: TextStyle(fontSize: 13, color: Colors.grey)
                                )
                              ): members[index]["invite_${currentWorkspace["id"]}_${widget.type == "toChannel"  ? currentChannel["id"] : ""}"] == null 
                              ? TextButton(
                                  child: Center(child: Text(currentChannel["is_private"] ? S.current.invite : S.current.invite, 
                                    style: TextStyle(fontSize: 13, color: isDark ? Color(0xffEAE8E8) : Color(0xff5E5E5E))
                                  )
                                ),
                                onPressed: () {
                                  _invite(auth.token, currentWorkspace["id"], currentChannel["id"], members[index]);
                                  this.setState(() {
                                    members[index]["invite_${currentWorkspace["id"]}_${widget.type == "toChannel"  ? currentChannel["id"] : ""}"] = true;
                                  }); 
                                }
                              ) : Center(
                              child: Text(
                                S.current.invited, style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                ),
              ):Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Column(
                    children: [
                      isDark ? SvgPicture.asset('assets/icons/smileSadDark.svg') : SvgPicture.asset('assets/icons/smileSadLight.svg'),
                      SizedBox(height: 16,),
                      Text(S.current.nothingTurnedUp, style: TextStyle(color: isDark ? Colors.white : Colors.black.withOpacity(0.85), fontSize: 14, fontWeight: FontWeight.w600)),
                      SizedBox(height: 8,),
                      Text(S.current.descNothingTurnedUp, style: TextStyle(color: isDark ? Color(0xffF5F7FA) : Colors.black.withOpacity(0.85), fontSize: 13)),
                    ]
                  )
                )
              ) : Container()
              : Container(
                padding: const EdgeInsets.only(left: 13, right: 13),
                child: FriendList(type: widget.type),
              ),
            ),
            if (widget.type == "toWorkspace") Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 14, left: 24, right: 24, bottom: 10),
                    child: Text(
                      S.current.typeEmailOrPhoneToInvite,
                      style: TextStyle(color: isDark ? Color(0xffC9C9C9): Color(0xff828282), fontSize: 15, fontWeight: FontWeight.w500, fontFamily: "Roboto")
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 24),
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color:  Color(0xffA6A6A6) ),
                        borderRadius: BorderRadius.circular(5)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 285,
                            child: CupertinoTextField(
                              controller: _inviteEmailController,
                              padding: EdgeInsets.only(left: 8),
                              autofocus: true,
                              decoration: BoxDecoration(
                                border: null,
                                borderRadius: BorderRadius.circular(4)
                              ),
                              onChanged: (value) {
                              if (_debounce?.isActive ?? false) _debounce.cancel();
                                _debounce = Timer(const Duration(milliseconds: 500), () {
                                  if (value != "") {
                                    onSearchMemberToInvite(auth.token, value);
                                  } else {
                                    setState(() => {members = [], textSearch = ""});
                                  }
                                });
                              },
                              style: TextStyle(fontFamily: "Roboto", color: isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.85), fontSize: 14.0),
                            ),
                          ),
                          Container(
                            height: 34,
                            width: 80,
                            child: VibrateButton(
                              disableVibration: validEmailOrNumberPhone,
                              style: ButtonStyle(
                                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
                                backgroundColor: MaterialStateProperty.all(Utils.getPrimaryColor() ),
                                overlayColor: MaterialStateProperty.all(Color(0xff))
                              ),
                              onPressed: () {
                                _invitePeople(auth.token, currentWorkspace["id"], currentChannel["id"], _inviteEmailController.text);
                              },
                              child: Text(
                                S.current.invite,
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xffffffff)
                                )
                              )
                            )
                          )
                        ]
                      )
                    )
                  ),
                  if (invitationHistory.length > 0) Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.only(top: 4, left: 24, bottom: 4),
                        child: Text(
                          S.current.invitationHistory,
                          style: TextStyle(color: isDark ? Color(0xffC9C9C9): Color(0xff828282), fontSize: 15, fontWeight: FontWeight.w500, fontFamily: "Roboto")
                        )
                      ),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: 50,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 2, horizontal: 24),
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          itemCount: invitationHistory.length,
                          itemBuilder: (context, index){
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    invitationHistory[index]["email"],
                                    style: TextStyle(color: isDark ? Color(0xffC9C9C9): Color(0xff828282), fontSize: 13.5, fontWeight: FontWeight.w400, fontFamily: "Roboto")
                                  ),
                                  Text(
                                    invitationHistory[index]['isAccepted'] ? S.current.acceptInvite : S.current.sent,
                                    style: TextStyle(color: isDark ? Color(0xffC9C9C9): Color(0xff828282), fontSize: 13.5, fontWeight: FontWeight.w400, fontFamily: "Roboto")
                                  )
                                ]
                              )
                            );
                          }
                        )
                      )
                    ]
                  )
                ]
              ),
            ),
            SizedBox(height: 10) ,
            Container(
              padding: EdgeInsets.only(left: 24, right: 24, bottom: 12),
              child: Row(
                children: [
                  Text(
                    S.current.codeInvite,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Palette.defaultTextDark: Color(0xff1F2933))
                  ),
                  SizedBox(width: 4,),
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(new ClipboardData(text: keyCode));
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            keyCode,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xff27AE60),
                              fontSize: 14.5,
                            )
                          ),
                        ),
                        isDark ? SvgPicture.asset('assets/icons/copyDark.svg') : SvgPicture.asset('assets/icons/copyLight.svg'),
                        SizedBox(width: 4,)
                      ],
                    )
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 200),
                     builder: (context, value, child) {
                       return Container(
                         width: 249,
                         child: Text(messageInvite,
                         style: TextStyle(fontSize: 16,fontWeight: FontWeight.w400,fontStyle: FontStyle.italic , color: validEmailOrNumberPhone ? Colors.blue : Colors.red)),
                       );
                     }
                    )
                ],
              )
            )
          ],
        ),
      )
    ) : Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
          decoration: BoxDecoration(
            color:isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5)
            )
          ),
          width: double.infinity,
          child: Text(
            S.current.joinChannel,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Color(0xffFFFFFF) : Color(0xff3D3D3D)
            )
          ),
        ),

        Container(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: CupertinoTextField(
            placeholder: S.current.insertKeyCodeChannel,
            placeholderStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.65) : Colors.black.withOpacity(0.45), fontSize: 14, fontFamily: "Roboto"),
            style: TextStyle(color: isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.85), fontFamily: "Roboto", fontSize: 14),
            padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            textAlignVertical: TextAlignVertical.center,
            autofocus: true,
            controller: _inviteByCode,
            decoration: BoxDecoration(
              color: isDark ? Color(0xff353535) : Color(0xffEDEDED),
              border: Border.all(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9)),
              borderRadius: BorderRadius.circular(3),
            ),
            onChanged: (value) {
              this.setState(() {
                textCode = value;
              });
            },
          ),
        ),
        errorMessage == ""
        ? Container(height: 5)
        : Container(
            margin: EdgeInsets.only(top: 0,left: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  errorMessage,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: Colors.red,
                    fontStyle: FontStyle.italic
                  ),
                )
              ]
            ),
          ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 12,horizontal: 24),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: isDark? Color(0xFF4C4C4C): Color(0xFFDBDBDB),width: 1),)
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Color(0xFFFF7875),
                    width: 1,
                  )
                ),
                height: 34,
                width: 80,
                child: TextButton(
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))) ,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  S.current.cancel,
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFFF7875)
                  ),
                )
              )
            ),
            SizedBox(width: 8,),
            Container(
              height: 34,
              width: 80,
              child: TextButton(
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))) ,
                  backgroundColor: MaterialStateProperty.all(Utils.getPrimaryColor()),
                  overlayColor: MaterialStateProperty.all(Utils.getPrimaryColor())
                ),
                onPressed: () {
                  joinChannelByCode();
                },
                child: Text(
                  S.current.join,
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFFFFFFF)
                  ),
                )
              )
            ),
            ],
          )
        ),
      ],
    );
  }
}

class SpringCurve extends Curve {
  final double a;
  final double w;
  SpringCurve({this.a = 0.15, this.w = 19.4});

  @override
  double transformInternal(double t) {
    return -(pow(e, -t / a)) * sin(t * w);
  }
}

class VibrateButton extends StatefulWidget {
  final disableVibration;
  final Widget child;
  final ButtonStyle? style;
  final Function onPressed;
  const VibrateButton({ Key? key, required this.child, required this.onPressed, this.style, this.disableVibration = false }) : super(key: key);

  @override
  _VibrateButtonState createState() => _VibrateButtonState();
}

class _VibrateButtonState extends State<VibrateButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animatable<double> curveTween;
  @override
  void initState() {
    super.initState();
     curveTween = Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: SpringCurve(a: widget.disableVibration ? 0.0 : 0.45, w: widget.disableVibration ? 0.0 : 28)));
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 500), upperBound: 0.999);
  }
  void _playAnimation() {
    _controller.reset();
    _controller.forward();
  }
  @override
  void didUpdateWidget(covariant VibrateButton oldWidget) {
    curveTween = Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: SpringCurve(a: widget.disableVibration ? 0.0 : 0.45, w: widget.disableVibration ? 0.0 : 28)));
    super.didUpdateWidget(oldWidget);
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(curveTween.evaluate(_controller) * 10, 0),
          child: TextButton(
            style: widget.style,
            onPressed: () {
              widget.onPressed();
              _playAnimation();
            },
            child: widget.child,
          )
        );
      }
    );
  }
}