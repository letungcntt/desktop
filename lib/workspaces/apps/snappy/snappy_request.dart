import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/dropdown_overlay.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/providers/providers.dart';

class SnappyRequest extends StatefulWidget {
  final forms;
  final isDark;
  final formId;
  final onChangeListRequest;
  const SnappyRequest({Key? key, @required this.forms, this.isDark, this.formId, this.onChangeListRequest}) : super(key: key);

  @override
  State<SnappyRequest> createState() => _SnappyRequestState();
}

class _SnappyRequestState extends State<SnappyRequest> {
  bool errorField1 = false;
  bool errorField2 = false;
  bool errorField3 = false;
  bool errorField4 = false;
  bool errorField5 = false;
  bool errorField6 = false;
  bool errorField7 = false;
  bool errorField8 = false;
  bool errorField9 = false;
  bool errorField10 = false;
  bool errorField11 = false;
  bool errorField12 = false;
  List attachments = [];
  bool isLoading = false;
  bool onHover = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  DateTime? dateTime;
  TimeOfDay? time;
  DateTimeRange? dateRange;
  int? channelId;
  List approvers = [];

  handleCreateRequest() async {
    setState(() => isLoading = true);
    List newList = new List.from(widget.forms);
    final index1 = newList.indexWhere((ele) => ele["id"] == 1);
    if (index1 != -1) {
      if (_titleController.text != "") {
        newList[index1]["value"] = _titleController.text;
        setState(() => errorField1 = false);
      } else {
        setState(() => errorField1 = true);
      }
    }

    final index2 = newList.indexWhere((ele) => ele["id"] == 2);
    if (index2 != -1) {
      if (_fullNameController.text != "") {
        newList[index2]["value"] = _fullNameController.text;
        setState(() => errorField2 = false);
      } else {
        setState(() => errorField2 = true);
      }
    }

    final index3 = newList.indexWhere((ele) => ele["id"] == 3);
    if (index3 != -1) {
      if (_phoneController.text != "") {
        newList[index3]["value"] = _phoneController.text;
        setState(() => errorField3 = false);
      } else {
        setState(() => errorField3 = true);
      }
    }

    final index4 = newList.indexWhere((ele) => ele["id"] == 4);
    if (index4 != -1) {
      if (dateTime != null) {
        newList[index4]["value"] = dateTime.toString();
        setState(() => errorField4 = false);
      } else {
        setState(() => errorField4 = true);
      }
    }

    final index5 = newList.indexWhere((ele) => ele["id"] == 5);
    if (index5 != -1) {
      if (time != null) {
        newList[index5]["value"] = time?.format(context).toString();
        setState(() => errorField5 = false);
      } else {
        setState(() => errorField5 = true);
      }
    }

    final index6 = newList.indexWhere((ele) => ele["id"] == 6);
    if (index6 != -1) {
      if (_descController.text != "") {
        newList[index6]["value"] = _descController.text;
        setState(() => errorField6 = false);
      } else {
        setState(() => errorField6 = true);
      }
    }

    final index7 = newList.indexWhere((ele) => ele["id"] == 7);
    if (index7 != -1) {
      if (attachments.length > 0) {
        newList[index7]["value"] = attachments;
        setState(() => errorField7 = false);
      } else {
        setState(() => errorField7 = true);
      }
    }

    final index8 = newList.indexWhere((ele) => ele["id"] == 8);
    if (index8 != -1) {
      if (_amountController.text != "") {
        newList[index8]["value"] = _amountController.text;
        setState(() => errorField8 = false);
      } else {
        setState(() => errorField8 = true);
      }
    }

    final index9 = newList.indexWhere((ele) => ele["id"] == 9);
    if (index9 != -1) {
      if (dateRange != null) {
        newList[index9]["value"] = dateRange.toString();
        setState(() => errorField9 = false);
      } else {
        setState(() => errorField9 = true);
      }
    }

    final index10 = newList.indexWhere((ele) => ele["id"] == 10);
    if (index10 != -1) {
      if (_numberController.text != "") {
        newList[index10]["value"] = _numberController.text;
        setState(() => errorField10 = false);
      } else {
        setState(() => errorField10 = true);
      }
    }

    final index11 = newList.indexWhere((ele) => ele["id"] == 11);
    if (index11 != -1) {
      if (channelId != null) {
        newList[index11]["value"] = channelId;
        setState(() => errorField11 = false);
      } else {
        setState(() => errorField11 = true);
      }
    }

    final index12 = newList.indexWhere((ele) => ele["id"] == 12);
    if (index12 != -1) {
      if (approvers.length > 0) {
        newList[index12]["value"] = approvers;
        setState(() => errorField12 = false);
      } else {
        setState(() => errorField12 = true);
      }
    }

    if (errorField1 || errorField2 || errorField3 || errorField4 || errorField5 || errorField6
        || errorField7 || errorField8 || errorField9 || errorField10 || errorField11 || errorField12) {
      setState(() => isLoading = false);
      return;
    } else {
      final token = Provider.of<Auth>(context, listen: false).token;
      final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];

      final body = {
        'form_id': widget.formId,
        'approver_ids': approvers,
        'form_submit': newList
      };
      final url = Utils.apiUrl + 'workspaces/$workspaceId/submit_request?token=$token';
      try {
        final response = await Dio().post(url, data: json.encode(body));
        var dataRes = response.data;
        if (dataRes["success"]) {
          widget.onChangeListRequest("add", "requestSent", dataRes["data"]);
          setState(() => isLoading = false);
          Navigator.of(context, rootNavigator: true).pop("Discard");
        }
      } catch (e, trace) {
        print("Error Channel: $trace");
        setState(() => isLoading = false);
        // sl.get<Auth>().showErrorDialog(e.toString());
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _descController.dispose();
    _amountController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  openFileSelector() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    try {
      var myMultipleFiles = await Utils.openFilePicker([
        XTypeGroup(
          extensions: ['jpg', 'jpeg', 'gif', 'png', 'xlsx', 'json', 'xls', 'zip', 'docs']
        )
      ]);

      for (var e in myMultipleFiles) {
        Map newFile = {
          "filename": e["name"],
          "file_name": e["name"],
          "uploading": true,
          "path":  base64.encode(e["file"])
        };

        setState(() {
          attachments.add(newFile);
          errorField7 = false;
        });
      }

      for (var i = 0; i < attachments.length; i++) {
        if (attachments[i]["uploading"] == true) {
          var file = attachments[i];
          final url = Utils.apiUrl + 'workspaces/${currentWorkspace["id"]}/contents?token=$token';
          final body = {
            "file": file,
            "content_type": "image",
            "mime_type": "image",
            "filename": file["filename"]
          };

          Dio().post(url, data: json.encode(body)).then((response) async {
            final responseData = response.data;
            setState(() {
              attachments[i] = responseData;
            });
          });
        }
      }
    } on Exception catch (e) {
      print("$e Cancel");
    }
  }

  _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != dateTime) {
      setState(() {
        errorField4 = false;
        dateTime = picked;
      });
    }
  }

  _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: time ?? TimeOfDay.now()
    );

    if (picked != null && picked != time) {
      setState(() {time = picked; errorField5 = false;});
    }
  }

  _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022, 1, 1),
      lastDate: DateTime(2030, 1, 31),
      currentDate: DateTime.now(),
      builder: (context, child) {
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: Container(
                height: 450,
                width: 700,
                child: child,
              ),
            ),
          ],
        );
      },
    );

    if (picked != null && picked != dateRange) {
      setState(() {
        dateRange = picked;
        errorField9 = false;
      });
    }
  }

  _renderElement(ele, isDark) {
    switch (ele["id"]) {
      case 1:
        return inputController(_titleController, "Nhập tiêu đề", isDark, errorField1);
      case 2:
        return inputController(_fullNameController, "Nhập họ tên", isDark, errorField2);
      case 3:
        return inputController(_phoneController, "Nhập số điện thoại", isDark, errorField3);
      case 4:
        return Container(
          height: 36,
          padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isDark ? Color(0xff1E1E1E) : Colors.white,
            border: Border.all(color: errorField4 ? Colors.red : isDark ? Color(0xff52606D) : Color(0xffCBD2D9))
          ),
          child: InkWell(
            onTap: () {
              _selectDate(context);
            },
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  dateTime != null
                    ? Text(
                        DateFormatter().renderTime(dateTime!, type: "dd/MM/yyyy"),
                        style: TextStyle(color: isDark ? Colors.white.withOpacity(0.85) : Color(0xff1F2933), fontSize: 13.0, fontWeight: FontWeight.w300)
                      )
                    : Center(
                        child: Text('Press the button to show the picker', style: TextStyle(fontSize: 13, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65),)),
                      ),
                  Icon(Icons.calendar_today_outlined, size: 16.0, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65))
                ],
              ),
            )
          ),
        );
      case 5:
        return Container(
          height: 36,
          padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isDark ? Color(0xff1E1E1E) : Colors.white,
            border: Border.all(color: errorField5 ? Colors.red : isDark ? Color(0xff52606D) : Color(0xffCBD2D9))
          ),
          child: InkWell(
            onTap: () {
              _selectTime(context);
            },
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  time != null
                    ? Text(
                        "${time?.hour}:${time?.minute}",
                        style: TextStyle(color: isDark ? Colors.white.withOpacity(0.85) : Color(0xff1F2933), fontSize: 13.0, fontWeight: FontWeight.w300)
                      )
                    : Center(
                        child: Text('Press the button to show the picker', style: TextStyle(fontSize: 13, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65),)),
                      ),
                  Icon(Icons.calendar_today_outlined, size: 16.0, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65))
                ],
              ),
            )
          ),
        );
      case 6:
        return inputController(_descController, "Nhập lý do/mô tả", isDark, errorField6);
      case 7:
        return InkWell(
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          onTap: () {
            openFileSelector();
          },
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 7, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: errorField7 ? Colors.red : isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(PhosphorIcons.uploadSimple, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                    SizedBox(width: 8),
                    Text("Upload", style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.black54,))
                  ]
                )
              ),
              SizedBox(width: 20),
              ...attachments.map((e) {
                return StatefulBuilder(
                  builder: ((context, setState) {
                    return HoverItem(
                      onHover: () {
                        setState(() => onHover = true);
                      },
                      onExit: () {
                        setState(() => onHover = false);
                      },
                      child: Stack(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 7, horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
                            ),
                            child: Text(e["file_name"], style: TextStyle(fontSize: 15, color: isDark ? Colors.white70 : Colors.black54,))
                          ),
                          if (onHover) Positioned(
                            top: 2,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              margin: EdgeInsets.only(left: 12),
                              child: TextButton(
                                style: ButtonStyle(
                                  padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                                  overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
                                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
                                ),
                                child: Icon(Icons.close, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                                onPressed: () {
                                  final index = attachments.indexOf(e);
                                  if (index == -1) return;
                                  this.setState(() {
                                    attachments.removeAt(index);
                                  });
                                }
                              )
                            ),
                          )
                        ],
                      ),
                    );
                  }),
                );
              })
            ]
          )
        );
      case 8:
        return inputController(_amountController, "Nhập số tiền", isDark, errorField8);
      case 9:
        return Container(
          height: 36,
          padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isDark ? Color(0xff1E1E1E) : Colors.white,
            border: Border.all(color: errorField9 ? Colors.red : isDark ? Color(0xff52606D) : Color(0xffCBD2D9))
          ),
          child: InkWell(
            onTap: () {
              _selectDateRange(context);
            },
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  dateRange == null
                    ? Center(
                        child: Text('Press the button to show the picker', style: TextStyle(fontSize: 13, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65),)),
                      )
                    : Text(
                      "${DateFormatter().renderTime(dateRange!.start, type: "dd/MM/yyyy")} - ${DateFormatter().renderTime(dateRange!.end, type: "dd/MM/yyyy")}",
                      style: TextStyle(color: isDark ? Colors.white.withOpacity(0.85) : Color(0xff1F2933), fontSize: 13.0, fontWeight: FontWeight.w300)
                    ),
                    Icon(Icons.calendar_today_outlined, size: 16.0, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65))
                ],
              ),
            )
          ),
        );
      case 10:
        return inputController(_numberController, "Nhập số lượng", isDark, errorField10);
      case 11:
        final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
        final channels = currentWorkspace["id"] != null
          ? Provider.of<Channels>(context, listen: false).data.where((e) => e["workspace_id"] == currentWorkspace["id"] && !Utils.checkedTypeEmpty(e["is_archived"])).toList()
          : [];
        return DropdownOverlay(
          width: 200,
          isAnimated: true,
          menuDirection: MenuDirection.start,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: HoverItem(
              colorHover: Palette.hoverColorDefault,
              child: Container(
                height: 36,
                constraints: new BoxConstraints(
                  minWidth: 200,
                ),
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    width: 1,
                    color: errorField11 ? Colors.red : isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight
                  ),
                ),
                child: Row(
                  mainAxisAlignment:  MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      channelId != null ? "Đã chọn" : "Chọn channel",
                      style: TextStyle(
                        color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65),
                        fontSize: 14
                      )
                    ),
                    SizedBox(width: 8),
                    Icon(CupertinoIcons.arrowtriangle_down_fill, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65), size: 12),
                  ]
                ),
              ),
            ),
          ),
          dropdownWindow: StatefulBuilder(
            builder: ((context, setState) {
              return Container(
                constraints: new BoxConstraints(
                  maxHeight: 300.0,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Palette.backgroundTheardDark : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: channels.length,
                        itemBuilder: (BuildContext context, int index) {
                          var item = channels[index];

                          return TextButton(
                            style: ButtonStyle(
                              overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                              padding: MaterialStateProperty.all(EdgeInsets.zero)
                            ),
                            onPressed: () {
                              if (channelId != null) setState(() => channelId = null);
                              setState(() => channelId = item["id"]);
                              this.setState(() => errorField11 = false);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: index != channels.length -1 ? Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)) : null,
                              ),
                              padding: EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item["name"],
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(right: 5),
                                    child: channelId == item["id"]
                                      ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                      : Container(width: 16, height: 16)
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                )
              );
            }),
          )
        );
      case 12:
        final wsMembers = Provider.of<Workspaces>(context, listen: true).members;
        final currentUser = Provider.of<User>(context, listen: false).currentUser;
        final members = wsMembers.where((ele) => ele["account_type"] == 'user' && ele["role_id"] <= 2 && ele["id"] != currentUser['id']).toList();
        return DropdownOverlay(
          width: 200,
          isAnimated: true,
          menuDirection: MenuDirection.start,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: HoverItem(
              colorHover: Palette.hoverColorDefault,
              child: Container(
                height: 36,
                constraints: new BoxConstraints(
                  minWidth: 200,
                ),
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    width: 1,
                    color: errorField12 ? Colors.red : isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight
                  ),
                ),
                child: Row(
                  mainAxisAlignment:  MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      approvers.length > 0 ? "Đã chọn ${approvers.length} người" : "Chọn người kiểm duyệt",
                      style: TextStyle(
                        color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65),
                        fontSize: 14
                      )
                    ),
                    SizedBox(width: 8),
                    Icon(CupertinoIcons.arrowtriangle_down_fill, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65), size: 12),
                  ]
                ),
              ),
            ),
          ),
          dropdownWindow: StatefulBuilder(
            builder: ((context, setState) {
              return Container(
                constraints: new BoxConstraints(
                  maxHeight: 300.0,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Palette.backgroundTheardDark : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: members.length,
                        itemBuilder: (BuildContext context, int index) {
                          final item = members[index];

                          return TextButton(
                            style: ButtonStyle(
                              overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                              padding: MaterialStateProperty.all(EdgeInsets.zero)
                            ),
                            onPressed: () {
                              final idx = approvers.indexWhere((e) => e == item["id"]);
                              List approverIds = List.from(approvers);
                              if (idx != -1) approverIds.removeAt(idx);
                              else approverIds.add(item["id"]);
                              setState(() => approvers = approverIds);
                              this.setState(() => errorField12 = false);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: index != members.length -1 ? Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)) : null,
                              ),
                              padding: EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item["full_name"],
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(right: 5),
                                    child: approvers.contains(item["id"])
                                      ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                      : Container(width: 16, height: 16)
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                )
              );
            }),
          )
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Container(
      width: 600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...widget.forms.map((ele) {
                      return Container(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ele["label"].toString(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                            SizedBox(height: 8),
                            Container(
                              margin: EdgeInsets.only(left: 10),
                              child: _renderElement(ele, isDark),
                            )
                          ],
                        ),
                      );
                    }).toList()
                  ]
                ),
              ),
            ),
          ),
          Container(
            decoration:  BoxDecoration(border: Border(top: BorderSide(width: 0.2, color: Colors.grey))),
            padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 120, height: 32,
                  margin: EdgeInsets.only(right: 12),
                  child: OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                    ),
                    onPressed: () => handleCreateRequest(),
                    child: isLoading
                      ? Center(
                          child: SpinKitFadingCircle(
                            color: widget.isDark ? Colors.white60 : Color(0xff096DD9),
                            size: 15,
                          ))
                      : Text(
                          'Tạo yêu cầu',
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

  Widget inputController(controller, hintText, isDark, error) {
    return Container(
      height: hintText == "Nhập lý do/mô tả" ? 100 : 40,
      color: isDark ? Palette.backgroundTheardDark : Colors.white,
      child: TextFormField(
        // focusNode: _titleNode,
        autofocus: true,
        maxLines: hintText == "Nhập lý do/mô tả" ? 4 : 1,
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
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
        onChanged: (value) => {},
      ),
    );
  }
}