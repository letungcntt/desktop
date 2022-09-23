import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/providers/providers.dart';

class BankingCardInfo extends StatefulWidget {
  final card;
  final bankInfo;
  final handleRemoveBank;
  BankingCardInfo({Key? key, this.card, this.bankInfo, this.handleRemoveBank}) : super(key: key);

  @override
  State<BankingCardInfo> createState() => _BankingCardInfoState();
}

class _BankingCardInfoState extends State<BankingCardInfo> {
  bool isLoading = false;
  bool isDeleting = false;
  String password = "";
  FocusNode focusPass = FocusNode();
  bool collapse = true;

  TextStyle style(double? size, {color, weight = FontWeight.w500}) {
    final isDark = context.read<Auth>().theme == ThemeType.DARK;
    return GoogleFonts.nunito(
      textStyle: Theme.of(context).textTheme.headline4,
      fontSize: size,
      fontWeight: weight,
      color: color ?? (isDark ? Color(0xFFFFFFFF) : Color(0xff000000)),
    );
  }

  Future<dynamic> handleReconnect(bank, newPass, auth) async {
    setState(() => isLoading = true);
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];

    final url = Utils.apiUrl + "workspaces/$workspaceId/reconnect?token=${auth.token}";
    try {
      final response = await Dio().post(
        url,
        data: json.encode({
          "bank_id": bank["bank_id"],
          "workspace_bank_id": bank["id"],
          "password": newPass
        })
      );
      if (response.data["success"]) {
        setState(() => isLoading = false);
        widget.handleRemoveBank(bank["id"]);
        Navigator.of(context, rootNavigator: true).pop("Discard");
      } else {
        setState(() => isLoading = false);
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
              new Center(child: new Container(child: new Text(response.data["message"] ?? response.data["error"]["value"] ?? "Lỗi kết nối. Vui lòng kiểm tra trên website ngân hàng.")))
          ])
        );
      }
    } catch (e, trace) {
      setState(() => isLoading = false);
      print("$e\n$trace");
    }
  }

  Future<dynamic> handleDisconnect(bank, auth) async {
    setState(() => isLoading = true);
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];

    final url = Utils.apiUrl + "workspaces/$workspaceId/disconnect?token=${auth.token}";
    try {
      final response = await Dio().post(
        url,
        data: json.encode({
          "bank_id": bank["bank_id"],
          "username": bank["username"],
        })
      );
      if (response.data["success"]) {
        setState(() => isLoading = false);
        widget.handleRemoveBank(bank["id"]);
        Navigator.of(context, rootNavigator: true).pop("Discard");
      } else {
        setState(() => isLoading = false);
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
              new Center(child: new Container(child: new Text(response.data["message"] ?? response.data["error"]["value"] ?? "Lỗi kết nối. Vui lòng kiểm tra trên website ngân hàng.")))
          ])
        );
      }
    } catch (e, trace) {
      setState(() => isLoading = false);
      print("$e\n$trace");
    }
  }

  Future<dynamic> deleteBankConnect(bank, auth) async {
    setState(() => isDeleting = true);
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];

    final url = Utils.apiUrl + "workspaces/$workspaceId/delete_connect?token=${auth.token}";
    try {
      final response = await Dio().delete(url, data: {'workspace_bank_id': bank["id"]});
      if (response.data["success"]) {
        setState(() => isDeleting = false);
        widget.handleRemoveBank(bank["id"]);
        Navigator.of(context, rootNavigator: true).pop("Discard");
      } else {
        setState(() => isDeleting = false);
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
              new Center(child: new Container(child: new Text(response.data["message"] ?? response.data["error"]["value"] ?? "Lỗi kết nối. Vui lòng kiểm tra trên website ngân hàng.")))
          ])
        );
      }
    } catch (e, trace) {
      setState(() => isDeleting = false);
      print("$e\n$trace");
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<Auth>();
    final isDark = auth.theme == ThemeType.DARK;
    final card = widget.card;
    final bankInfo = widget.bankInfo;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0)),
      titlePadding: const EdgeInsets.all(0),
      backgroundColor: isDark ? Palette.backgroundTheardDark : Colors.white,
      contentPadding: EdgeInsets.all(16),
      content: Container(
        width: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 220,
                  height: 120,
                  child: Card(
                    color: Color(bankInfo["color_card"]),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(2)),
                                  color: card["connect_status"] == 1 ? Colors.green : Colors.grey,
                                ),
                                child: Text(card["connect_status"] == 1 ? "Kết nối" : "Tạm dừng", style: style(8)),
                              ),
                              Container(
                                child: Text(bankInfo["short_name"].toString().toUpperCase(), style: style(10))
                              )
                            ],
                          ),
                          SizedBox(height: 10),
                          Center(
                            child: Text(card["bank_account_name"].toString().toUpperCase(), style: style(12))
                          ),
                          SizedBox(height: 5),
                          Center(
                            child: Text(
                              card["bank_sub_acc_id"] ?? "",
                              style: GoogleFonts.nunito(
                                textStyle: Theme.of(context).textTheme.headline4,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                letterSpacing: 6
                              )
                            )
                          ),
                        ],
                      ),
                    )
                  ),
                ),
                Column(
                  children: [
                    Container(
                      width: 220,
                      margin: EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Ngân hàng", style: style(15)),
                          Text(bankInfo["short_name"], style: style(15))
                        ],
                      ),
                    ),
                    Container(
                      width: 220,
                      margin: EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Tài khoản", style: style(15)),
                          Text(card["username"], style: style(15))
                        ],
                      ),
                    ),
                    Container(
                      width: 220,
                      margin: EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Mật khẩu", style: style(15)),
                          Text("********", style: style(15))
                        ],
                      ),
                    ),
                    Container(
                      width: 220,
                      margin: EdgeInsets.only(bottom: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Trạng thái", style: style(15)),
                          Text(
                            card["connect_status"] == 1 ? "Kết nối" : "Tạm dừng",
                            style: style(15, color: card["connect_status"] == 1 ? Colors.green : Colors.grey)
                          )
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
            // Container(
            //   margin: EdgeInsets.only(left: 10),
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.all(Radius.circular(5)),
            //     border: Border.all(
            //       width: 1.0, color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)
            //     ),
            //   ),
            //   child: Row(
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            //       Container(
            //         padding: EdgeInsets.all(10),
            //         decoration: BoxDecoration(
            //           border: Border(right: BorderSide(width: 1.0, color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)))
            //         ),
            //         child: Text("Tất cả", style: style(14))
            //       ),
            //       Container(
            //         padding: EdgeInsets.all(10),
            //         decoration: BoxDecoration(
            //           border: Border(right: BorderSide(width: 1.0, color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)))
            //         ),
            //         child: Text("Tiền vào", style: style(14))
            //       ),
            //       Container(
            //         padding: EdgeInsets.all(10),
            //         child: Text("Tiền ra", style: style(14))
            //       )
            //     ],
            //   ),
            // ),
            Container(
              margin: EdgeInsets.only(top: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  !isLoading
                    ? card["connect_status"] == 1
                      ? OutlinedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Colors.grey),
                          ),
                          onPressed: () {},
                          child: Text("Tạm dừng kết nối", style: style(14)),
                      )
                      : OutlinedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Colors.green),
                          ),
                          onPressed: () => setState(() => collapse = !collapse),
                          child: Text("Kết nối lại", style: style(14)),
                      )
                    : Center(
                        child: SpinKitFadingCircle(
                          color: isDark ? Colors.white60 : Color(0xff096DD9),
                          size: 15,
                        )),
                  OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.red),
                    ),
                    onPressed: () => deleteBankConnect(card, auth),
                    child: Text("Xoá tài khoản ngân hàng", style: style(14)),
                  )
                ],
              ),
            ),
            if (!collapse) Container(
              margin: EdgeInsets.only(top: 20),
              color: isDark ?Color(0xFF4c4c4c) : Color(0xFFfafafa),
              width: 300,
              height: 36,
              child: TextFormField(
                // autofocus: true,
                focusNode: focusPass,
                onFieldSubmitted:  (v) => handleReconnect(widget.card, password, auth),
                obscureText: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB))),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Color(0xfffaad14) : Color(0xFF1890ff))),
                  hintText: "Mật khẩu",
                  hintStyle: GoogleFonts.nunito(
                    textStyle: Theme.of(context).textTheme.headline4,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ?Colors.white : Color(0xFF5e5e5e),
                  )
                ),
                style: GoogleFonts.nunito(
                  textStyle: Theme.of(context).textTheme.headline4,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ?Colors.white : Color(0xFF5e5e5e),
                ),
                onChanged: (String t) => password = t,
              ),
            )
          ],
        ),
      )
    );
  }
}