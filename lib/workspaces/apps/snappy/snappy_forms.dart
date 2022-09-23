import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_confirm_dialog.dart';
import 'package:workcake/components/custom_dialog.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/workspaces/apps/snappy/snappy_request.dart';

import 'snappy_review_request.dart';

class SnappyListForms extends StatefulWidget {
  final Function changeView;
  final int workspaceId;
  const SnappyListForms({Key? key, required this.changeView, required this.workspaceId}) : super(key: key);

  @override
  State<SnappyListForms> createState() => _SnappyListFormsState();
}

class _SnappyListFormsState extends State<SnappyListForms> {
  List groupForms = [];
  List requestSent = [];
  List pending = [];
  List approved = [];
  List canceled = [];

  @override
  void initState() {
    super.initState();
    getSnappyForms();
    getSnappyRequest();

    final channel = Provider.of<Auth>(context, listen: false).channel;

    channel.on("update_group_forms", (data, _ref, _joinRef) {
      final index = groupForms.indexWhere((element) => element["id"] == data["id"]);
      if (index != -1) {
        groupForms[index]["name"] = data["name"];
        setState(() => groupForms);
      } else {
        final add = [data] + groupForms;
        setState(() => groupForms = add);
      }
    });

    channel.on("delete_group_form", (data, _ref, _joinRef) {
      final index = groupForms.indexWhere((element) => element["id"] == data["id"]);
      if (index != -1) {
        groupForms.removeAt(index);
        setState(() => groupForms);
      }
    });

    channel.on("update_forms", (data, _ref, _joinRef) {
      final index = groupForms.indexWhere((element) => element["id"] == data["group_form_id"]);
      if (index != -1) {
        groupForms[index]["forms"] = [data] + groupForms[index]["forms"];
        setState(() => groupForms);
      }
    });

    channel.on("update_pending", (data, _ref, _joinRef) {
      final add = [data] + groupForms;
      setState(() => pending = add);
    });

    channel.on("update_review_request", (data, _ref, _joinRef) {
      final index = requestSent.indexWhere((element) => element["id"] == data["id"]);
      if (index != -1) setState(() => requestSent = requestSent.removeAt(index));
      if (data["status"] == "APPROVED") {
        final add = [data] + approved;
        setState(() => approved = add);
      } else if (data["status"] == "CANCELED") {
        final add = [data] + canceled;
        setState(() => canceled = add);
      }
    });
  }

  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId) {
      final currentWs = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      if (currentWs['app_ids'].contains(1)) {
        getSnappyForms();
        getSnappyRequest();
      } else {
        final auth = Provider.of<Auth>(context, listen: false);
        Provider.of<User>(context, listen: false).selectTab("app");
        auth.channel.push(
          event: "join_channel",
          payload: {"channel_id": 0, "workspace_id": currentWs["id"]}
        );
      }
    }
  }

  Future<dynamic> getSnappyForms() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final workspaceId = currentWorkspace["id"];

    final url = Utils.apiUrl + 'workspaces/$workspaceId/index_group_form?token=$token';

    try {
      final response = await Dio().get(url);
      if (response.data["success"]) {
        final data = response.data["data"];
        if (mounted) setState(() => groupForms = data);
      }
    } catch (e, trace) {
      print("getSnappyForms $e $trace");
    }
  }

  Future<dynamic> getSnappyRequest() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final workspaceId = currentWorkspace["id"];

    final url = Utils.apiUrl + 'workspaces/$workspaceId/index_request?token=$token';

    try {
      final response = await Dio().get(url);
      if (response.data["success"]) {
        if (mounted) {
          setState(() {
            requestSent = response.data["request_sent"];
            pending = response.data["pending"];
            approved = response.data["approved"];
            canceled = response.data["canceled"];
          });
        }
      }
    } catch (e, trace) {
      print("getSnappyRequest $e $trace");
    }
  }

  handleCreateGroupForm(groupForm) {
    final add = [groupForm] + groupForms;
    if (mounted) setState(() => groupForms = add);
  }

  handleUpdateGroupForm(groupForm) {
    final index = groupForms.indexWhere((element) => element["id"] == groupForm["id"]);
    if (index != 1) {
      groupForms[index]['name'] = groupForm["name"];
      if (mounted) setState(() => groupForms);
    }
  }

  handleDeleteGroupForm(id) {
    final index = groupForms.indexWhere((element) => element["id"] == id);
    if (index != 1) {
      groupForms.removeAt(index);
      if (mounted) setState(() => groupForms);
    }
  }

  handleCreateForm(form, key) {
    List newGroupForms = groupForms;
    final index = newGroupForms.indexWhere((element) => element["id"] == form["group_form_id"]);
    if (index != -1) {
      newGroupForms[index]["forms"] = [form] + newGroupForms[index]["forms"];
      setState(() => groupForms = newGroupForms);
    }
  }

  handleUpdateForm(form, groupFormId) {
    List newGroupForms = groupForms;
    final index = newGroupForms.indexWhere((element) => element["id"] == groupFormId);
    if (index != -1) {
      final idx = newGroupForms[index]["forms"].indexWhere((ele) => ele["id"] == form["id"]);
      if (idx != -1) {
        newGroupForms[index]["forms"][idx] = form;
        setState(() => groupForms = newGroupForms);
      }
    }
  }

  handleDeleteForm(form, groupFormId) {
    List newGroupForms = groupForms;
    final index = newGroupForms.indexWhere((element) => element["id"] == groupFormId);
    if (index != -1) {
      final idx = newGroupForms[index]["forms"].indexWhere((ele) => ele["id"] == form["id"]);
      if (idx != -1) {
        newGroupForms[index]["forms"].removeAt(idx);
        setState(() => groupForms = newGroupForms);
      }
    }
  }

  onChangeListRequest(change, type, request) {
    if (change == "add") {
      if (type == "requestSent") {
        final data = [request] + requestSent;
        setState(() => requestSent = data);
      } else if (type == "approved") {
        final data = [request] + approved;
        setState(() => approved = data);
      } else if (type == "canceled") {
        final data = [request] + canceled;
        setState(() => canceled = data);
      }
    } else if (change == "minus") {
      if (type == "pending") {
        final index = pending.indexWhere((element) => element["id"] == request["id"]);
        if (index != -1) {
          final data = pending.removeAt(index);
          setState(() => pending = data);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final currentUserWs = Provider.of<Workspaces>(context, listen: true).currentMember;

    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                margin: EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => widget.changeView(1),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Icon(PhosphorIcons.arrowLeft, size: 20,),
                  ),
                ),
              ),
              Text("Yêu cầu phê duyệt", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
          Wrap(
            children: [
              Container(
                width: 213, height: 58,
                margin: EdgeInsets.only(right: 18, top: 16),
                child: OutlinedButton(
                  onPressed: () => onReviewSnappyRequest(context, requestSent, onChangeListRequest, true),
                  child: Text(
                    'Yêu cầu đã gửi (${requestSent.length})',
                    style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                  ),),
              ),
              if (currentUserWs["role_id"] <= 2) Container(
                width: 213, height: 58,
                margin: EdgeInsets.only(right: 18, top: 16),
                child: OutlinedButton(
                  onPressed: () => onReviewSnappyRequest(context, pending, onChangeListRequest, false),
                  child: Text(
                    'Chờ duyệt (${pending.length})',
                    style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                  ),),
              ),
              Container(
                width: 213, height: 58,
                margin: EdgeInsets.only(right: 18, top: 16),
                child: OutlinedButton(
                  onPressed: () => onReviewSnappyRequest(context, approved, onChangeListRequest, false),
                  child: Text(
                    'Đã duyệt (${approved.length})',
                    style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                  ),),
              ),
              Container(
                width: 213, height: 58,
                margin: EdgeInsets.only(right: 18, top: 16),
                child: OutlinedButton(
                  onPressed: () => onReviewSnappyRequest(context, canceled, onChangeListRequest, false),
                  child: Text(
                    'Từ chối (${canceled.length})',
                    style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                  ),),
              )
            ],
          ),
          if (currentUserWs['role_id'] <= 2) Container(
            margin: EdgeInsets.only(top: 24),
            child: Row(
              children: [
                Container(
                  width: 120, height: 32,
                  margin: EdgeInsets.only(right: 12),
                  child: OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                    ),
                    onPressed: () => onCreateSnappyGroupForm(context, handleCreateGroupForm),
                    child: Text(
                      'Tạo nhóm',
                      style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                    ),),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: groupForms.map((ele) {
                  return Container(
                    width: double.infinity,
                    decoration:  BoxDecoration(border: Border(bottom: BorderSide(width: 0.2, color: Colors.grey))),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(ele["name"].toString(), style: TextStyle(fontSize: 16,)),
                            if (currentUserWs['role_id'] <= 2) Container(
                              width: 20,
                              height: 20,
                              margin: EdgeInsets.only(left: 12),
                              child: TextButton(
                                style: ButtonStyle(
                                  padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                                  overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
                                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
                                ),
                                child: Icon(CupertinoIcons.plus, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                                onPressed: () => onCreateSnappyForm(context, ele, handleCreateForm, false, ele["id"])
                              )
                            ),
                            if (currentUserWs['role_id'] <= 2) Container(
                              width: 20,
                              height: 20,
                              margin: EdgeInsets.only(left: 12),
                              child: TextButton(
                                style: ButtonStyle(
                                  padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                                  overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
                                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
                                ),
                                child: Icon(CupertinoIcons.pencil, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                                onPressed: () => onEditSnappyGroupForm(context, ele, handleUpdateGroupForm)
                              )
                            ),
                            if (currentUserWs['role_id'] <= 2) Container(
                              width: 20,
                              height: 20,
                              margin: EdgeInsets.only(left: 12),
                              child: TextButton(
                                style: ButtonStyle(
                                  padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                                  overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
                                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
                                ),
                                child: Icon(CupertinoIcons.delete, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                                onPressed: () => onDeleteSnappyForm(context, ele, handleDeleteGroupForm)
                              )
                            ),
                          ],
                        ),
                        Wrap(
                          children: [
                            ...ele["forms"].map((e) {
                              return ListForms(e: e, isDark: isDark, onChangeListRequest: onChangeListRequest, handleUpdateForm: handleUpdateForm, handleDeleteForm: handleDeleteForm, groupFormId: ele['id']);
                            }).toList(),
                          ],
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class CreateSnappyForm extends StatefulWidget {
  final isDark;
  final Function? handleForm;
  final groupForm;
  final isUpdate;
  final groupFormId;
  const CreateSnappyForm({Key? key, required bool this.isDark, this.handleForm, this.groupForm, this.isUpdate, this.groupFormId}) : super(key: key);

  @override
  State<CreateSnappyForm> createState() => _CreateSnappyFormState();
}

class _CreateSnappyFormState extends State<CreateSnappyForm> {
  List formsSelected = [];
  bool isLoading = false;
  bool error = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.isUpdate) {
      _controller.text = widget.groupForm['title'];
      setState(() => formsSelected = widget.groupForm['forms']);
    }
  }

  handleAddForm(form) {
    bool checked = false;
    for (var map in formsSelected) {
      if (map["id"] == form["id"]) checked = true;
    }
    if (!checked) {
      final add = formsSelected + [form];
      setState(() => formsSelected = add);
    } else {
      showModal(
        context: context,
        builder: (_) => SimpleDialog(
        children: <Widget>[
            new Center(child: new Container(child: new Text('Form này đã được sử dụng')))
        ])
      );
    }
  }

  handleRemoveForm(form) {
    final index = formsSelected.indexWhere((ele) => ele["id"] == form["id"]);

    if (index != -1) {
      formsSelected.removeAt(index);
      setState(() => formsSelected = formsSelected);
    }
  }

  handleEditTitle(form, value) {
    List newList = formsSelected;
    final newMap = new Map.from(form);

    newMap["label"] = value;
    final index = newList.indexWhere((element) => element["id"] == newMap["id"]);
    if (index != -1) {
      newList[index] = newMap;
      setState(() => formsSelected = newList);
    }
  }

  Future<dynamic> handleCreateForm(value, forms) async {
    setState(() => isLoading = true);
    if (value != "") {
      final token = Provider.of<Auth>(context, listen: false).token;
      final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];

      final body = {
        'title': value,
        'forms': forms,
        'form_id': widget.isUpdate ? widget.groupForm['id'] : null,
        'group_form_id': widget.groupFormId
      };
      final url = Utils.apiUrl + 'workspaces/$workspaceId/create_form?token=$token';
      try {
        final response = await Dio().post(url, data: body);
        var dataRes = response.data;
        if (dataRes["success"]) {
          setState(() => isLoading = false);
          widget.handleForm!(dataRes['data'], widget.groupFormId);
          Navigator.of(context, rootNavigator: true).pop("Discard");
        }
      } catch (e) {
        setState(() => isLoading = false);
        print("Error Channel: $e");
        // sl.get<Auth>().showErrorDialog(e.toString());
      }
    } else {
      setState(() {
        error = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Container(
      width: 800,
      child: Column(
        children: [
          Container(
            height: 36,
            margin: EdgeInsets.all(10),
            color: isDark ? Palette.backgroundTheardDark : Colors.white,
            child: TextFormField(
              autofocus: true,
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Nhập tiêu đề",
                hintStyle: TextStyle(
                  color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w300),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: error ? Colors.red : isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight),
                  borderRadius: const BorderRadius.all(Radius.circular(2))
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight),
                  borderRadius: const BorderRadius.all(Radius.circular(2))
                ),
              ),
              style: TextStyle(color: isDark ? Colors.white : const Color.fromRGBO( 0, 0, 0, 0.65), fontSize: 15, fontWeight: FontWeight.normal),
              onChanged: (value) => setState(() => error = false),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade800),
                          borderRadius: BorderRadius.all(Radius.circular(4))
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                child: Text("Danh sách đã chọn"),
                              ),
                              ...formsSelected.map((e) {
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(e["label"].toString(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                                            Row(
                                              children: [
                                                Container(
                                                  width: 20,
                                                  height: 20,
                                                  child: TextButton(
                                                    style: ButtonStyle(
                                                      padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                                                      overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
                                                      shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
                                                    ),
                                                    child: Icon(CupertinoIcons.eyedropper, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                                                    onPressed: () => onEditTitleForm(context, e, handleEditTitle)
                                                  )
                                                ),
                                                SizedBox(width: 8,),
                                                Container(
                                                  width: 20,
                                                  height: 20,
                                                  child: TextButton(
                                                    style: ButtonStyle(
                                                      padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                                                      overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
                                                      shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
                                                    ),
                                                    child: Icon(CupertinoIcons.delete, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                                                    onPressed: () => handleRemoveForm(e)
                                                  )
                                                )
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                      Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius: BorderRadius.all(Radius.circular(4))
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              }).toList(),
                            ]
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 30,
                      child: Icon(CupertinoIcons.chevron_left_2, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade800),
                          borderRadius: BorderRadius.all(Radius.circular(4))
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                child: Text("Danh sách trường"),
                              ),
                              ...listForms.map((e) {
                                return Card(
                                  child: ListTile(
                                    title: Text(e["label"].toString(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                                    trailing: Container(
                                      width: 20,
                                      height: 20,
                                      child: TextButton(
                                        style: ButtonStyle(
                                          padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                                          overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
                                          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
                                        ),
                                        child: Icon(CupertinoIcons.plus, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                                        onPressed: () => handleAddForm(e)
                                      )
                                    ),
                                  )
                                );
                              }).toList(),
                            ]
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(width: 0.2, color: Colors.grey))),
            padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 100, height: 32,
                  margin: EdgeInsets.only(right: 12),
                  child: OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                    ),
                    onPressed: () => handleCreateForm(_controller.text, formsSelected),
                    child: isLoading
                      ? Center(
                          child: SpinKitFadingCircle(
                            color: widget.isDark ? Colors.white60 : Color(0xff096DD9),
                            size: 15,
                          ))
                      : Text(
                          widget.isUpdate ? 'Cập nhật' : 'Tạo form',
                          style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ListForms extends StatefulWidget {
  final e;
  final isDark;
  final onChangeListRequest;
  final handleUpdateForm;
  final handleDeleteForm;
  final groupFormId;
  const ListForms({Key? key, this.e, this.isDark, this.onChangeListRequest, this.handleUpdateForm, this.handleDeleteForm, this.groupFormId}) : super(key: key);

  @override
  State<ListForms> createState() => _ListFormsState();
}

class _ListFormsState extends State<ListForms> {
  bool isHover = false;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final e = widget.e;
    final currentMember = Provider.of<Workspaces>(context, listen: false).currentMember;

    return HoverItem(
      onHover: () => setState(() => isHover = true),
      onExit: () => setState(() => isHover = false),
      child: Stack(
        children: [
          Container(
            width: 213, height: 45,
            margin: EdgeInsets.only(right: 18, top: 16),
            child: OutlinedButton(
              onPressed: () => onCreateSnappyRequest(context, e, widget.onChangeListRequest),
              child: Text(
                e["title"].toString(),
                style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
              ),),
          ),
          if (isHover && currentMember['role_id'] <= 2) Positioned(
            right: 0, top: 0,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: EdgeInsets.only(right: 3),
                  child: TextButton(
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                      overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
                    ),
                    child: Icon(CupertinoIcons.minus, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                    onPressed: () => onCreateSnappyForm(context, e, widget.handleUpdateForm, true, widget.groupFormId)
                  )
                ),
                Container(
                  width: 20,
                  height: 20,
                  child: TextButton(
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                      overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
                    ),
                    child: Icon(CupertinoIcons.xmark, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                    onPressed: () => showDialogDeleteForm(context, e, widget.handleDeleteForm, widget.groupFormId)
                  )
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

showDialogDeleteForm(context, form, handleDeleteForm, groupFormId) {
  Future<dynamic> deleteForm() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];

    final body = {
      'form_id': form["id"],
    };
    final url = Utils.apiUrl + 'workspaces/$workspaceId/delete_form?token=$token';
    try {
      final response = await Dio().post(url, data: body);
      var dataRes = response.data;
      if (dataRes["success"]) {
        handleDeleteForm(dataRes["data"], groupFormId);
      }
    } catch (e) {
      print("Error Channel: $e");
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  showModal(
    context: context,
    builder: (BuildContext context) {
      return CustomConfirmDialog(
        title: "Xoá form",
        subtitle: "Bạn xác nhận xoá form?",
        onConfirm: deleteForm
      );
    }
  );
}

onCreateSnappyGroupForm(context, handleCreateGroupForm) {

  onSaveGroupFormName(value) async {
    if (value != "") {
      final token = Provider.of<Auth>(context, listen: false).token;
      final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];

      final url = Utils.apiUrl + 'workspaces/$workspaceId/create_snappy_group_name?token=$token';
      try {
        final response = await Dio().post(url, data: {'name': value});
        var dataRes = response.data;
        if (dataRes["success"]) {
          handleCreateGroupForm(dataRes["data"]);
          Navigator.of(context, rootNavigator: true).pop("Discard");
        }
      } catch (e) {
        print("Error Channel: $e");
        // sl.get<Auth>().showErrorDialog(e.toString());
      }
    }
  }

  showModal(
    context: context,
    builder: (BuildContext context) {
      return CustomDialog(title: "Tạo nhóm form", titleField: 'Tạo nhóm form', displayText: "", onSaveString: onSaveGroupFormName);
    }
  );
}

onEditSnappyGroupForm(context, groupForm, handleUpdateGroupForm) {
  onSaveGroupFormName(value) async {
    if (value != "") {
      final token = Provider.of<Auth>(context, listen: false).token;
      final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];

      final url = Utils.apiUrl + 'workspaces/$workspaceId/create_snappy_group_name?token=$token';
      try {
        final response = await Dio().post(url, data: {'name': value, 'group_form_id': groupForm["id"]});
        var dataRes = response.data;
        if (dataRes["success"]) {
          handleUpdateGroupForm(dataRes["data"]);
          Navigator.of(context, rootNavigator: true).pop("Discard");
        }
      } catch (e) {
        print("Error Channel: $e");
        // sl.get<Auth>().showErrorDialog(e.toString());
      }
    }
  }

  showModal(
    context: context,
    builder: (BuildContext context) {
      return CustomDialog(title: "Sửa nhóm form", titleField: 'Sửa nhóm form', displayText: "", onSaveString: onSaveGroupFormName);
    }
  );
}

onDeleteSnappyForm(context, ele, onDeleteSnappyForm) {
  onSaveGroupFormName() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];

    final url = Utils.apiUrl + 'workspaces/$workspaceId/delete_group_form?token=$token';
    try {
      final response = await Dio().delete(url, data: {'group_form_id': ele["id"]});
      var dataRes = response.data;
      if (dataRes["success"]) {
        onDeleteSnappyForm(dataRes["data"]["id"]);
        Navigator.of(context, rootNavigator: true).pop("Discard");
      }
    } catch (e) {
      print("Error Channel: $e");
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  showModal(
    context: context,
    builder: (BuildContext context) {
      return CustomConfirmDialog(
        title: "Xoá group form",
        subtitle: "Bạn xác nhận xoá group form?",
        onConfirm: onSaveGroupFormName
      );
    }
  );
}

onCreateSnappyForm(context, groupForm, handleForm, isUpdate, groupFormId) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;

  showModal(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
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
            child: Text("Tạo mẫu", style: TextStyle(fontSize: 16))
          ),
        ),
        titlePadding: const EdgeInsets.all(0),
        backgroundColor: isDark ? Palette.backgroundTheardDark : Colors.white,
        contentPadding: EdgeInsets.zero,
        content: CreateSnappyForm(isDark: isDark, groupForm: groupForm, handleForm: handleForm, isUpdate: isUpdate, groupFormId: groupFormId),
      );
    }
  );
}

onEditTitleForm(context, form, handleEditTitle) {

  onEditLabel(value) {
    handleEditTitle(form, value);
    Navigator.of(context, rootNavigator: true).pop("Discard");
  }
  showModal(
    context: context,
    builder: (BuildContext context) {
      return CustomDialog(title: "Sưả label", titleField: 'Sưả label', displayText: form["label"], onSaveString: onEditLabel);
    }
  );
}

onCreateSnappyRequest(context, forms, onChangeListRequest) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;

  showModal(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
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
            child: Text("Tạo yêu cầu ${forms['title']}", style: TextStyle(fontSize: 16))
          ),
        ),
        titlePadding: const EdgeInsets.all(0),
        backgroundColor: isDark ? Palette.backgroundTheardDark : Colors.white,
        contentPadding: EdgeInsets.zero,
        content: SnappyRequest(forms: forms["forms"], isDark: isDark, formId: forms["id"], onChangeListRequest: onChangeListRequest),
      );
    }
  );
}

onReviewSnappyRequest(context, requests, onChangeListRequest, isRequestSent) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;

  showModal(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
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
            child: Text("Review", style: TextStyle(fontSize: 16))
          ),
        ),
        titlePadding: const EdgeInsets.all(0),
        backgroundColor: isDark ? Palette.backgroundTheardDark : Colors.white,
        contentPadding: EdgeInsets.zero,
        content: SnappyReviewRequest(requests: requests, isDark: isDark, isRequestSent: isRequestSent, onChangeListRequest: onChangeListRequest),
      );
    }
  );
}