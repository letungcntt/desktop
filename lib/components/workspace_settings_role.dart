import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/styles.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/dropdown_overlay.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';

class WorkspaceSettingsRole extends StatefulWidget {
  const WorkspaceSettingsRole({ Key? key }) : super(key: key);

  @override
  _WorkspaceSettingsRoleState createState() => _WorkspaceSettingsRoleState();
}

class _WorkspaceSettingsRoleState extends State<WorkspaceSettingsRole> {
  FocusNode focusNode = FocusNode();
  // final TextEditingController _searchQuery = new TextEditingController();
  ScrollController controller = new ScrollController();
  TextEditingController _passwordController = TextEditingController();
  Timer? _debounce;
  String? filter;
  int action = 0;
  String? selectedId;
  bool loading = false;

  void dispose(){
    controller.dispose();
    _debounce?.cancel();
    _passwordController.dispose();
    // _searchQuery.dispose();
    super.dispose();
  }

  Widget renderRoles(roleMembers, String title, int roleId) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final currentMember = Provider.of<Workspaces>(context, listen: false).currentMember;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;

    return Container(
      margin: EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight),
        color: Colors.transparent
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? Color(0xff4C4C4C) : Color(0xffF8F8F8),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            ),
            padding: EdgeInsets.only(top: 12, bottom: 12, left: 34),
            child: Row(
              children: [
                // Container(
                //   width: 3,
                //   height: 18,
                //   color: Constants.checkColorRole(roleId, isDark),
                //   margin: EdgeInsets.only(right: 8),
                // ),
                Text(title, style: TextStyle(color: Constants.checkColorRole(roleId, isDark), fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Color(0xff2E2E2E) : Color(0xffffffff),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              controller: controller,
              itemCount: roleMembers.length,
              itemBuilder: (BuildContext context, int index) {
                final member = roleMembers[index];
                return Container(
                  padding: EdgeInsets.only(top: 12, left: 16, right: 16, bottom: ((action != 0) && selectedId == member['id']) ? 6 : 12),
                  color: ((action != 0) && selectedId == member['id']) ? Color(0xff5E5E5E).withOpacity(0.8) : Colors.transparent,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    CachedImage(
                                      member['avatar_url'],
                                      width: 30,
                                      height: 30,
                                      isAvatar: true,
                                      radius: 50,
                                      name: member['full_name']
                                    ),
                                    Positioned(
                                      top: 20, left: 20,
                                      child: Container(
                                        height: 10, width: 10,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(width: 1, color: Color(0xffffffff)),
                                          color: member['is_online'] ? Color(0xff73d13d) : Color(0xffbfbfbf)
                                        ),
                                      )
                                    )
                                  ],
                                ),
                                SizedBox(width: 12),
                                Container(
                                  child: Text(
                                    member['full_name'],
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: isDark ? Colors.white : Color(0xff1d1c1d), fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 250,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    member['email'],
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: isDark ? Colors.white70 : Color(0xff616061), fontSize: 15),
                                  ),
                                ),
                                SizedBox(width: 5),
                                if (Utils.checkedTypeEmpty(member['is_verified_email'])) Icon(Icons.verified, color: Colors.green, size: 14)
                              ],
                            ),
                          ),
                          Container(
                            width: 200,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    Utils.checkedTypeEmpty(member['phone_number']) ? member['phone_number'] : 'None',
                                    style: TextStyle(color: isDark ? Colors.white70 : Color(0xff1d1c1d), fontSize: 15),
                                  ),
                                ),
                                SizedBox(width: 5),
                                if (Utils.checkedTypeEmpty(member['is_verified_phone_number'])) Icon(Icons.verified, color: Colors.green, size: 14)
                              ],
                            ),
                          ),
                          Container(
                            width: 80,
                            alignment: Alignment.center,
                            child: currentMember['role_id'] <= member['role_id'] && (currentMember['role_id'] <= 2 || currentMember['user_id'] == member['id'])
                                ? DropActionSetting(
                                  member: member,
                                  onPressed: (value, uid) {
                                    setState(() { action = value; selectedId = uid; });
                                  }
                                )
                                : HoverItem(
                                  showTooltip: true,
                                  tooltip: Container(
                                    color: isDark ? Color(0xFF1c1c1c): Colors.white,
                                    child: Text(
                                      currentMember['role_id'] > member['role_id']
                                        ? S.current.cantActionsForYou(member['full_name'])
                                        : S.current.yourRoleCannotAction
                                    ),
                                  ), 
                                  colorHover: null,
                                  child: Icon(CupertinoIcons.ellipsis, size: 16, color: isDark ? Colors.white24 : Color(0x1d1c1d21))
                                ),
                          ),
                        ]
                      ),
                      if ((action != 0) && selectedId == member['id']) Padding(
                        padding: const EdgeInsets.only(top: 12.0, bottom: 6),
                        child: Divider(color: Color(0xff4C4C4C), height: 0.5),
                      ),
                      if ((action == 1 || action == 2) && selectedId == member['id']) Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            action == 1
                              ? S.current.askDeleteMember
                              : S.current.askLeaveWorkspace
                          ),
                          Row(children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  action = 0;
                                  selectedId = null;
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 12),
                                padding: EdgeInsets.only(top: 5, bottom: 5, left: 16, right: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Color(0xffEDEDED)
                                  ),
                                  borderRadius: BorderRadius.all(Radius.circular(2))
                                ),
                                child: Text(S.current.cancel, style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            SizedBox(width: 5),
                            InkWell(
                              onTap: () async {
                                setState(() { loading = true; });
                                if (action == 1) {
                                  await Provider.of<Workspaces>(context, listen: false).deleteChannelMember(auth.token, currentWorkspace['id'], currentChannel["id"], [member['id']], type: "other")
                                    .then((value) => setState(() { loading = false; }));
                                } else {
                                }
                              },
                              child: Container(
                                width: action == 1 ? 80 : 160,
                                margin: EdgeInsets.symmetric(vertical: 12),
                                padding: EdgeInsets.only(top: 5, bottom: 5, left: 16, right: 16),
                                decoration: BoxDecoration(
                                  color: Color(0xffEB5757),
                                  border: Border.all(
                                    color: Color(0xffEB5757)
                                  ),
                                  borderRadius: BorderRadius.all(Radius.circular(2))
                                ),
                                child: loading
                                  ? SpinKitFadingCircle(
                                    color: isDark ? Colors.white60 : Color(0xff096DD9),
                                    size: 19,
                                  )
                                  : Text(
                                    action == 1
                                      ? S.current.delete
                                      : S.of(context).leaveWorkspace,
                                    style: TextStyle(color: Colors.white)
                                  ),
                              ),
                            )
                          ],)
                        ],
                      ),
                      if ((action == 3) && selectedId == member['id']) LayoutBuilder(
                        builder: (context, contraints) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(S.current.transferTo),
                            SizedBox(width: 5),
                            InkWell(
                              onTap: () {},
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Palette.backgroundTheardDark,
                                  borderRadius: BorderRadius.all(Radius.circular(2))
                                ),
                                height: 32, width: contraints.maxWidth * 1/3,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Container(
                                      child: Text(
                                        S.current.selectMember,
                                        style: TextStyle(
                                          color: Color(0xffF0F4F8),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_drop_down, color: Colors.white, size: 20)
                                  ]
                                )
                              ),
                            ),
                            SizedBox(width: 5),
                            Flexible(
                              child: Container(
                                height: 34,
                                width: contraints.maxWidth * 1/3,
                                decoration: BoxDecoration(
                                  color: isDark ? Color(0xff1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(4.0)
                                ),
                                child: TextFormField(
                                  onChanged: (value) {
                                    this.setState(() {});
                                  },
                                  obscureText: true,
                                  controller: _passwordController,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w300),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(8),
                                    hintText: S.current.enterPassToTransfer,
                                    hintStyle: TextStyle(color: Color(0xff9AA5B1), fontWeight: FontWeight.w300, fontSize: 14.0),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0), borderSide: BorderSide(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0), borderSide: BorderSide(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 5),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  action = 0;
                                  selectedId = null;
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 12),
                                padding: EdgeInsets.only(top: 5, bottom: 5, left: 16, right: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Color(0xffEDEDED)
                                  ),
                                  borderRadius: BorderRadius.all(Radius.circular(2))
                                ),
                                child: Text(S.current.cancel, style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            SizedBox(width: 5),
                            InkWell(
                              onTap: () {},
                              child: Container(
                                width: 100,
                                margin: EdgeInsets.symmetric(vertical: 12),
                                padding: EdgeInsets.only(top: 5, bottom: 5, left: 16, right: 16),
                                decoration: BoxDecoration(
                                  color: Color(0xff1890FF),
                                  border: Border.all(
                                    color: Color(0xff1890FF)
                                  ),
                                  borderRadius: BorderRadius.all(Radius.circular(2))
                                ),
                                child: loading
                                  ? SpinKitFadingCircle(
                                    color: isDark ? Colors.white60 : Color(0xff096DD9),
                                    size: 19,
                                  )
                                  : Text(
                                    S.current.transfer,
                                    style: TextStyle(color: Colors.white)
                                  ),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  )
                );
              },
            ),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final wsMembers = Provider.of<Workspaces>(context, listen: true).members;
    var members = wsMembers.where((ele) => ele["account_type"] == 'user').toList();
    if (Utils.checkedTypeEmpty(filter)) {
      members = members.where((ele) =>
          ele["full_name"].toString().toLowerCase().contains(filter!) || ele["email"].toString().toLowerCase().contains(filter!)
        ).toList();
    }
    final ownerMember = members.where((ele) => ele['role_id'] == 1).toList();
    final adminMember = members.where((ele) => ele['role_id'] == 2).toList();
    final editorMember = members.where((ele) => ele['role_id'] == 3).toList();
    final fullMember = members.where((ele) => ele['role_id'] == 4).toList();

    return Container(
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0)),
        title: Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xff5E5E5E).withOpacity(0.5) : Color(0xffF3F3F3),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(4.0),
              topLeft: Radius.circular(4.0)
            )
          ),
          child: Container(
            padding: const EdgeInsets.only(top: 9, bottom: 9, left: 16),
            child: Text(S.current.roles, style: TextStyle(fontSize: 16))
          ),
        ),
        titlePadding: const EdgeInsets.all(0),
        backgroundColor: isDark ? Palette.backgroundTheardDark : Colors.white,
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 12),
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Palette.backgroundTheardDark : Palette.backgroundRightSiderLight,
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.only(left: 10),
                  margin: EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xff828282), width: 0.5),
                    borderRadius: BorderRadius.all(Radius.circular(4))
                  ),
                  child: Row(
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 10),
                        child: SvgPicture.asset('assets/icons/search.svg',)
                      ),
                      Expanded(
                        child: TextFormField(
                          autofocus: true,
                          cursorWidth: 1.0,
                          cursorHeight: 14,
                          decoration: InputDecoration(
                            hintText: S.current.searchMember,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            hintStyle: TextStyle(color: Color(0xffA6A6A6), fontSize: 14, fontWeight: FontWeight.w300),
                            border: InputBorder.none,
                          ),
                          focusNode: focusNode,
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black, fontSize: 14),
                          // controller: _searchQuery,
                          onChanged: (value) {
                            if (_debounce?.isActive ?? false) _debounce?.cancel();
                              _debounce = Timer(const Duration(milliseconds: 500), () {
                                  setState(() {
                                    filter = value.toLowerCase().trim();
                                  });
                              });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        renderRoles(ownerMember, "OWNER", 1),
                        Padding(padding: EdgeInsets.all(10)),
                        renderRoles(adminMember, "ADMINS", 2),
                        Padding(padding: EdgeInsets.all(10)),
                        renderRoles(editorMember, "EDITORS", 3),
                        Padding(padding: EdgeInsets.all(10)),
                        renderRoles(fullMember, "MEMBERS", 4),
                        Padding(padding: EdgeInsets.all(10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        )
      ),
    );
  }
}

class DropActionSetting extends StatefulWidget {
  final member;
  final Function onPressed;
  DropActionSetting({ Key? key, this.member, required this.onPressed }) : super(key: key);

  @override
  _DropActionSettingState createState() => _DropActionSettingState();
}

class _DropActionSettingState extends State<DropActionSetting> {

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final currentMember = Provider.of<Workspaces>(context, listen: false).currentMember;

    return DropdownOverlay(
      menuOffset: 15,
      isAnimated: true,
      menuDirection: MenuDirection.end,
      dropdownWindow: StatefulBuilder(
        builder: (BuildContext context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? Palette.backgroundTheardDark : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
            ),
            child: currentMember['user_id'] == member['id']
              ? Container(
                constraints: BoxConstraints(
                  minWidth: 320
                ),
                child: TextButton(
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(EdgeInsets.all(16))
                  ),
                  child: Row(
                    children: [
                      Text(
                        currentMember['role_id'] != 1 ? S.of(context).leaveWorkspace : S.of(context).transferOwner,
                        style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065), fontWeight: FontWeight.w400)
                      ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (currentMember['role_id'] != 1) {
                      widget.onPressed(2, member['id']);
                    } else {
                      widget.onPressed(3, member['id']);
                    }
                  },
                ),
              )
              : Container(
                child: Column(
                  children: [
                    currentMember['role_id'] <= 2 && currentMember['role_id'] <= member['role_id'] ? Container(
                      constraints: BoxConstraints(
                        minWidth: 320
                      ),
                      child: TextButton(
                        style: ButtonStyle(
                          padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 18, horizontal: 16))
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 12,
                              color: Color(0xff73D13D),
                              margin: EdgeInsets.only(right: 8),
                            ),
                            Text(S.current.setAdmin, style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065), fontWeight: FontWeight.w400)),
                          ],
                        ),
                        onPressed: () async {
                          await Provider.of<Workspaces>(context, listen: false).changeRoleWs(auth.token, member['id'], 2);
                          Navigator.of(context).pop();
                        },
                      ),
                    ) : Container(),
                    currentMember['role_id'] <= 3 && currentMember['role_id'] <= member['role_id'] ? Container(
                      constraints: BoxConstraints(
                        minWidth: 320
                      ),
                      child: TextButton(
                        style: ButtonStyle(
                          padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 18, horizontal: 16))
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 12,
                              color: Color(0xff36CFC9),
                              margin: EdgeInsets.only(right: 8),
                            ),
                            Text(S.current.setEditor, style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065), fontWeight: FontWeight.w400)),
                          ],
                        ),
                        onPressed: () async {
                          await Provider.of<Workspaces>(context, listen: false).changeRoleWs(auth.token, member['id'], 3);
                          Navigator.of(context).pop();
                        },
                      ),
                    ) : Container(),
                    currentMember['role_id'] <= 3 && currentMember['role_id'] <= member['role_id'] ? Container(
                      constraints: BoxConstraints(
                        minWidth: 320
                      ),
                      child: TextButton(
                        style: ButtonStyle(
                          padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 18, horizontal: 16))
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 12,
                              color: isDark ? Color(0xffFFFFFF) : Color(0xff3D3D3D),
                              margin: EdgeInsets.only(right: 8),
                            ),
                            Text(S.current.setMember, style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065), fontWeight: FontWeight.w400)),
                          ],
                        ),
                        onPressed: () async {
                          await Provider.of<Workspaces>(context, listen: false).changeRoleWs(auth.token, member['id'], 4);
                          Navigator.of(context).pop();
                        },
                      ),
                    ) : Container(),
                    currentMember['role_id'] <= 3 && currentMember['role_id'] <= member['role_id'] ? Divider(height: 0) : SizedBox(),
                    currentMember['role_id'] <= 3 && currentMember['role_id'] <= member['role_id'] ? Container(
                      constraints: BoxConstraints(
                        minWidth: 320
                      ),
                      child: TextButton(
                        style: ButtonStyle(
                          padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 16, horizontal: 16))
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 12,
                              color: Colors.red,
                              margin: EdgeInsets.only(right: 8),
                            ),
                            Text(S.current.deleteMembers, style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065), fontWeight: FontWeight.w400)),
                          ],
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onPressed(1, member['id']);
                        },
                      ),
                    ) : Container(),
                    currentMember['role_id'] <= 3 && currentMember['role_id'] <= member['role_id'] ? Divider(height: 0) : SizedBox(),
                  ],
                ),
              ),
          );
        },
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 80,
          alignment: Alignment.center,
          child: Icon(CupertinoIcons.ellipsis, size: 16),
        ),
      ),
    );
  }
}