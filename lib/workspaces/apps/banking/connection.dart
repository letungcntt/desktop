
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/providers/providers.dart';

class Connection extends StatefulWidget {
  const Connection({Key? key}) : super(key: key);

  @override
  State<Connection> createState() => _ConnectionState();
}

class _ConnectionState extends State<Connection> {
  // is_send_transaction_id => tuỳ chọn có gửi mã giao dịch không (true false)
  // is_send_balance => tuỳ chọn có gửi số dư không (true false)
  // send_bank_acc_id (0 => tất cả NH đã connect, else: workspace_bank_id)
  // send_only_incoming => tuỳ chọn gửi loại tiền ra vào (0: tất cả, 1: tiền vào, 2: tiền ra)
  List data = [];
  bool isCollapse = true;

  @override
  void initState() {
    super.initState();
    _loadingData();
  }

  Future<dynamic> _loadingData() async {
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];
    final auth = context.read<Auth>();

    final url = Utils.apiUrl + "workspaces/$workspaceId/integrations?token=${auth.token}";
    try {
      final response = await Dio().get(url);
      if (response.data["success"]) {
        if (mounted) setState(() => data = response.data["data"]);
      } else {
        // showModal(
        //   context: context,
        //   builder: (_) => SimpleDialog(
        //   children: <Widget>[
        //       new Center(child: new Container(child: new Text(response.data["message"])))
        //   ])
        // );
      }
    } catch (e, trace) {
      print("$e\n$trace");
    }
  }

  Future<dynamic> _deleteBankConnected(id) async {
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];
    final auth = context.read<Auth>();

    final url = Utils.apiUrl + "workspaces/$workspaceId/delete_integration?token=${auth.token}";
    try {
      final response = await Dio().delete(url, data: {'bank_connection_id': id});
      if (response.data["success"]) {
        final index = data.indexWhere((element) => element["id"] == id);
        if (index != 1) {
          data.removeAt(index);
          if (mounted) setState(() => data);
        }
      } else {
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
              new Center(child: new Container(child: new Text(response.data["message"])))
          ])
        );
      }
    } catch (e, trace) {
      print("$e\n$trace");
    }
  }

  TextStyle style(double? size, {color, weight = FontWeight.w500}) {
    final isDark = context.read<Auth>().theme == ThemeType.DARK;
    return GoogleFonts.nunito(
      textStyle: Theme.of(context).textTheme.headline4,
      fontSize: size,
      fontWeight: weight,
      color: color ?? (isDark ? Color(0xFFFFFFFF) : Color(0xff000000)),
    );
  }

  handleAddData(d) {
    final index = data.indexWhere((ele) => ele["id"] == d["id"]);

    if (index != -1) {
      List cloneData = data;
      cloneData[index] = d;
      setState(() => data = cloneData);
    } else {
      final newData = [d] + data;
      setState(() => data = newData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    final currentMember = Provider.of<Workspaces>(context, listen: false).currentMember;
    final channels = currentWorkspace["id"] != null
      ? Provider.of<Channels>(context, listen: true).data.where((e) => e["workspace_id"] == currentWorkspace["id"] && !Utils.checkedTypeEmpty(e["is_archived"])).toList()
      : [];

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                child: Text(
                  "Tích hợp",
                  style: style(18)
                )
              ),
              SizedBox(height: 15),
              Container(
                child: Text(
                  "Khi có một giao dịch mới được tải về Pancake Chat, Thì Pancake Chat sẽ thực hiện gửi thông tin giao dịch tới các kênh sau:",
                  style: style(14)
                )
              ),
              SizedBox(height: 15),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 1.0, color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                    left: BorderSide(width: 1.0, color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                    right: BorderSide(width: 1.0, color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                  ),
                ),
                child: Column(
                  children: [
                    ...data.map((d) {
                      final channel = {
                        "id": d["channel_id"],
                        "name": d["channel_name"]
                      };
                      return Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(width: 1.0, color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)))
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        d["channel_name"] ?? "",
                                        style: style(16),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        d["is_enable"] ? "Đang kích hoạt" : "Chưa kích hoạt",
                                        style: style(16, color: d["is_enable"] ? Palette.calendulaGold : Colors.red),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(right: 5),
                                        padding: EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                                        decoration: BoxDecoration(
                                          color: Color(0xffdbeddb),
                                          borderRadius: BorderRadius.all(Radius.circular(100))
                                        ),
                                        child: Text(
                                          d["send_bank_acc_id"] == 0 ? "Tất cả" : d["account_name"].toString().toUpperCase(),
                                          style: style(12, color: Colors.black),
                                        )
                                      ),
                                      if (d["send_only_incoming"] != 0) Container(
                                        margin: EdgeInsets.only(right: 5),
                                        padding: EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                                        decoration: BoxDecoration(
                                          color: Color(0xffd3e5ef),
                                          borderRadius: BorderRadius.all(Radius.circular(100))
                                        ),
                                        child: Text(
                                          d["send_only_incoming"] == 1 ? "Tiền vào" : "Tiền ra",
                                          style: style(12, color: Colors.black),
                                        )
                                      ),
                                      if (d["is_send_balance"]) Container(
                                        margin: EdgeInsets.only(right: 5),
                                        padding: EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                                        decoration: BoxDecoration(
                                          color: Color(0xffe8deee),
                                          borderRadius: BorderRadius.all(Radius.circular(100))
                                        ),
                                        child: Text(
                                          "Số dư",
                                          style: style(12, color: Colors.black),
                                        )
                                      ),
                                      if (d["is_send_transaction_id"]) Container(
                                        padding: EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                                        decoration: BoxDecoration(
                                          color: Color(0xffe3e2e0),
                                          borderRadius: BorderRadius.all(Radius.circular(100))
                                        ),
                                        child: Text(
                                          "Mã GD",
                                          style: style(12, color: Colors.black),
                                        )
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            if (currentMember["role_id"] <= 1) Container(
                              margin: EdgeInsets.only(right: 15),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    margin: EdgeInsets.only(right: 12),
                                    child: TextButton(
                                      style: ButtonStyle(
                                        padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                                        overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
                                        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
                                      ),
                                      child: Icon(CupertinoIcons.pencil, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                                      onPressed: () => showConnectionChannel(context, handleAddData, channel, d)
                                    )
                                  ),
                                  Container(
                                    width: 30,
                                    height: 30,
                                    child: TextButton(
                                      style: ButtonStyle(
                                        padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                                        overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
                                        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
                                      ),
                                      child: Icon(CupertinoIcons.delete, size: 18, color: Colors.red),
                                      onPressed: () => _deleteBankConnected(d["id"])
                                    )
                                  )
                                ],
                              ),
                            )
                          ],
                        )
                      );
                    })
                  ],
                ),
              ),
              if (currentMember["role_id"] <= 1) Center(
                child: Container(
                  margin: EdgeInsets.only(top: 15),
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                    ),
                    onPressed: () => setState(() => isCollapse = !isCollapse),
                    child: Text(
                      'Thêm tích hợp',
                      style: style(14, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight)
                    ),),
                ),
              ),
              if (!isCollapse) Center(
                child: Container(
                  width: 500,
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 1.0, color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)
                    ),
                  ),
                  margin: EdgeInsets.only(top: 15),
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Container(
                        child: Text(
                          "Chọn kênh để tích hợp",
                          style: style(14)
                        )
                      ),
                      SizedBox(height: 20),
                      Wrap(
                        children: [
                          ...channels.map((c) {
                            return Container(
                              // width: 213, height: 45,
                              margin: EdgeInsets.only(right: 5),
                              child: OutlinedButton(
                                onPressed: () => showConnectionChannel(context, handleAddData, c, null),
                                child: Text(
                                  c["name"].toString(),
                                  style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                ),),
                            );
                          })
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        )
      ),
    );
  }
}

showConnectionChannel(context, handleAddData, channel, bankConnectSelected) {
  showModal(
    context: context,
    builder: (BuildContext context) {
      return ModelConnectChannel(channel: channel, handleAddData: handleAddData, bankConnectSelected: bankConnectSelected);
    }
  );
}

class ModelConnectChannel extends StatefulWidget {
  final channel;
  final handleAddData;
  final bankConnectSelected;
  ModelConnectChannel({Key? key, this.channel, this.handleAddData, this.bankConnectSelected}) : super(key: key);

  @override
  State<ModelConnectChannel> createState() => _ModelConnectChannelState();
}

class _ModelConnectChannelState extends State<ModelConnectChannel> {
  List bankConnected = [];
  int? _bankConnectionId;
  bool _isSendTransactionId = true;
  bool _isSendBalance = true;
  int _sendOnlyIncoming = 0;
  int _sendBankAccId = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadingBankConnected();
    if (widget.bankConnectSelected != null) {
      setState(() {
        _bankConnectionId = widget.bankConnectSelected["id"];
        _isSendTransactionId = widget.bankConnectSelected["is_send_transaction_id"];
        _isSendBalance = widget.bankConnectSelected["is_send_balance"];
        _sendOnlyIncoming = widget.bankConnectSelected["send_only_incoming"];
        _sendBankAccId = widget.bankConnectSelected["send_bank_acc_id"];
      });
    }
  }

  Future<dynamic> _loadingBankConnected() async {
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];
    final auth = context.read<Auth>();

    final url = Utils.apiUrl + "workspaces/$workspaceId/connect?token=${auth.token}";
    try {
      final response = await Dio().get(url);
      if (response.data["success"]) {
        final data = response.data["data"];
        if (mounted) {
          setState(() => bankConnected = data);
          if (data.length == 1) setState(() => _sendBankAccId = data[0]["id"]);
        }
      } else {
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
              new Center(child: new Container(child: new Text(response.data["message"])))
          ])
        );
      }
    } catch (e, trace) {
      print("$e\n$trace");
    }
  }

  Future<dynamic> _saveConnectChannel() async {
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];
    final auth = context.read<Auth>();
    setState(() => isLoading = true);

    final url = Utils.apiUrl + "workspaces/$workspaceId/update_integration?token=${auth.token}";
    try {

      final data = {
        "bank_connection_id": _bankConnectionId,
        "channel_id": widget.channel["id"],
        "is_send_balance": _isSendBalance,
        "is_send_transaction_id": _isSendTransactionId,
        "send_bank_acc_id": _sendBankAccId,
        "send_only_incoming": _sendOnlyIncoming
      };
      final response = await Dio().post(url, data: json.encode(data));
      if (response.data["success"]) {
        setState(() => isLoading = false);
        widget.handleAddData(response.data["data"]);
        Navigator.of(context, rootNavigator: true).pop("Discard");
      } else {
        setState(() => isLoading = false);
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
              new Center(child: new Container(child: new Text(response.data["message"])))
          ])
        );
      }
    } catch (e, trace) {
      print("$e\n$trace");
      setState(() => isLoading = false);
    }
  }

  TextStyle style(double? size, {color, weight = FontWeight.w500}) {
    final isDark = context.read<Auth>().theme == ThemeType.DARK;
    return GoogleFonts.nunito(
      textStyle: Theme.of(context).textTheme.headline4,
      fontSize: size,
      fontWeight: weight,
      color: color ?? (isDark ? Color(0xFFFFFFFF) : Color(0xff000000)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<Auth>();
    final isDark = auth.theme == ThemeType.DARK;
    final channel = widget.channel;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0)),
      titlePadding: const EdgeInsets.all(0),
      backgroundColor: isDark ? Palette.backgroundTheardDark : Colors.white,
      contentPadding: EdgeInsets.all(16),
      content: bankConnected.length > 0
        ? Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  child: Text(
                    "Khi có giao dịch ngân hàng mới",
                    style: style(14)
                  )
                ),
                Container(
                  width: 450,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    border: Border.all(
                      width: 1.0, color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)
                    ),
                  ),
                  margin: EdgeInsets.only(top: 15, bottom: 15),
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 10),
                        child: Text(
                          "Chọn ngân hàng để nhận tin nhắn",
                          style: style(14)
                        )
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 10),
                        child: Column(
                          children: [
                            if (bankConnected.length > 1) Container(
                              margin: EdgeInsets.only(bottom: 5),
                              child: Row(
                                children: [
                                  Radio<int>(
                                    value: 0,
                                    fillColor: MaterialStateColor.resolveWith((states) => Palette.calendulaGold),
                                    groupValue: _sendBankAccId,
                                    onChanged: (int? value) {
                                      setState(() => _sendBankAccId = value!);
                                    },
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(left: 10),
                                    child: Text('Tất cả', style: style(14))
                                  ),
                                ],
                              ),
                            ),
                            ...bankConnected.map((bank) {
                              final bankInfo = listBanking.singleWhere((element) => element["id"] == bank["bank_id"]);
                              return Container(
                                margin: EdgeInsets.only(bottom: 5),
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      value: bank['id'],
                                      fillColor: MaterialStateColor.resolveWith((states) => Palette.calendulaGold),
                                      groupValue: _sendBankAccId,
                                      onChanged: (int? value) {
                                        setState(() => _sendBankAccId = value!);
                                      },
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(left: 10),
                                      child: Text("${bankInfo['short_name']} - ${bank['bank_account_name']}", style: style(14))
                                    ),
                                  ],
                                ),
                              );
                            })
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 10),
                        child: Text(
                          "Gửi giao dịch",
                          style: style(14)
                        )
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                          border: Border.all(
                            width: 1.0, color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => setState(() => _sendOnlyIncoming = 0),
                              child: Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _sendOnlyIncoming == 0 ? Palette.calendulaGold : Colors.transparent,
                                  border: Border(right: BorderSide(width: 1.0, color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)))
                                ),
                                child: Text("Tất cả", style: style(14))
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _sendOnlyIncoming = 1),
                              child: Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _sendOnlyIncoming == 1 ? Palette.calendulaGold : Colors.transparent,
                                  border: Border(right: BorderSide(width: 1.0, color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)))
                                ),
                                child: Text("Tiền vào", style: style(14))
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _sendOnlyIncoming = 2),
                              child: Container(
                                color: _sendOnlyIncoming == 2 ? Palette.calendulaGold : Colors.transparent,
                                padding: EdgeInsets.all(10),
                                child: Text("Tiền ra", style: style(14))
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(bottom: 10, top: 10),
                        child: Text(
                          "Thông tin đi kèm",
                          style: style(14)
                        )
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  checkColor: Colors.white,
                                  fillColor: MaterialStateColor.resolveWith((states) => Palette.calendulaGold),
                                  value: _isSendTransactionId,
                                  onChanged: (bool? value) {
                                    setState(() => _isSendTransactionId = value!);
                                  },
                                ),
                                Text("Gửi kèm thông tin Mã giao dịch", style: style(14))
                              ],
                            ),
                            Row(
                              children: [
                                Checkbox(
                                  checkColor: Colors.white,
                                  fillColor: MaterialStateColor.resolveWith((states) => Palette.calendulaGold),
                                  value: _isSendBalance,
                                  onChanged: (bool? value) {
                                    setState(() => _isSendBalance = value!);
                                  },
                                ),
                                Text("Gửi kèm thông tin số dư", style: style(14))
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      child: Text(
                        "sẽ gửi đến kênh ",
                        style: style(14)
                      )
                    ),
                    Container(
                      child: Text(
                        channel["name"],
                        style: style(16, color: Palette.calendulaGold)
                      )
                    ),
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 32,
                        margin: EdgeInsets.only(right: 12),
                        child: OutlinedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                          ),
                          onPressed: () => _saveConnectChannel(),
                          child: isLoading
                            ? Center(
                                child: SpinKitFadingCircle(
                                  color: isDark ? Colors.white60 : Color(0xff096DD9),
                                  size: 15,
                                ))
                            : Text(
                                'Lưu',
                                style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),)
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
      : Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Bạn chưa liên kết với bất kỳ ngân hàng nào", style: style(16)),
          ],
        ),
      )
    );
  }
}