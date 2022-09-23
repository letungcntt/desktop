import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:simple_tooltip/simple_tooltip.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row, Border, Stack;
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/flutter_mention/custom_selection.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/workspaces/apps/banking/service.dart';
import 'package:workcake/workspaces/apps/snappy/file_save_helper.dart';

import '../../../components/message_item/attachments/text_file.dart';
import 'banking_info_card.dart';
import 'connection.dart';

class Banking extends StatefulWidget {
  final int workspaceId;
  const Banking({Key? key, required this.workspaceId}) : super(key: key);

  @override
  State<Banking> createState() => _BankingState();
}

class _BankingState extends State<Banking> {
  String bank = 'tcb';
  int tab = 1;

  // didUpdateWidget(oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (oldWidget.workspaceId != widget.workspaceId) {
  //     // print(tab);
  //     final currentWs = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
  //     final auth = Provider.of<Auth>(context, listen: false);
  //     // Provider.of<User>(context, listen: false).selectTab("app");
  //     // auth.channel.push(
  //     //   event: "join_channel",
  //     //   payload: {"channel_id": 0, "workspace_id": currentWs["id"]}
  //     // );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Container(
      margin: EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)
        )
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            // padding: EdgeInsets.only(top: 1, bottom: 1),
            decoration: BoxDecoration(
              color: isDark ? Color(0xff262626) : Color(0xffF3F3F3),
            ),
            width: 64,
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => tab = 1),
                  child: Container(
                    width: 64,
                    height: 50,
                    decoration: BoxDecoration(
                      color: tab == 1 ? isDark ? Color(0xff3D3D3D) : Colors.white : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: tab == 1 ? isDark ? Palette.calendulaGold : Palette.dayBlue : Colors.transparent,
                          width: 2
                        )
                      )
                    ),
                    child: Icon(CupertinoIcons.creditcard),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => tab = 2),
                  child: Container(
                    width: 64,
                    height: 50,
                    decoration: BoxDecoration(
                      color: tab == 2 ? isDark ? Color(0xff3D3D3D) : Colors.white : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: tab == 2 ? isDark ? Palette.calendulaGold : Palette.dayBlue : Colors.transparent,
                          width: 2
                        )
                      )
                    ),
                    child: Icon(CupertinoIcons.briefcase)
                  ),
                ),
                // InkWell(
                //   onTap: () => setState(() => tab = 3),
                //   child: Container(
                //     width: 64,
                //     height: 50,
                //     decoration: BoxDecoration(
                //       color: tab == 3 ? isDark ? Color(0xff3D3D3D) : Colors.white : Colors.transparent,
                //       border: Border(
                //         left: BorderSide(
                //           color: tab == 3 ? isDark ? Palette.calendulaGold : Palette.dayBlue : Colors.transparent,
                //           width: 2
                //         )
                //       )
                //     ),
                //     child: Icon(CupertinoIcons.equal_square)
                //   ),
                // ),
              ],
            ),
          ),
          tab == 1
              ? ListBanking(workspaceId: widget.workspaceId)
              : tab == 2
                ? ListTransactions(workspaceId: widget.workspaceId)
                : Connection()
        ],
      ),
    );
  }
}

class ListBanking extends StatefulWidget {
  final workspaceId;
  ListBanking({Key? key, this.workspaceId}) : super(key: key);

  @override
  State<ListBanking> createState() => _ListBankingState();
}

class _ListBankingState extends State<ListBanking> {
  // connect_status trạng thái kết nối (0 => ngắt kết nối, 1 => đang kết nối)
  List bankConnected = [];

  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId) {
      _loadingBankConnected();
    }
  }

  @override
  void initState() {
    final channel = Provider.of<Auth>(context, listen: false).channel;
    _loadingBankConnected();

    channel.on("update_bank_connected", (data, _ref, _joinRef) {
      final add = [data] + bankConnected;
      setState(() => bankConnected = add);
    });

    super.initState();
  }

  Future<dynamic> _loadingBankConnected() async {
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];
    final auth = context.read<Auth>();

    final url = Utils.apiUrl + "workspaces/$workspaceId/connect?token=${auth.token}";
    try {
      final response = await Dio().get(url);
      if (response.data["success"]) {
        final data = response.data["data"];
        if (mounted) setState(() => bankConnected = data);
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

  handleConnectBank(bank) {
    final add = [bank] + bankConnected;
    if (mounted) setState(() => bankConnected = add);
  }

  TextStyle style(double? size, {color}) {
    final isDark = context.read<Auth>().theme == ThemeType.DARK;
    return GoogleFonts.nunito(
      textStyle: Theme.of(context).textTheme.headline4,
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color ?? (isDark ? Color(0xFFFFFFFF) : Color(0xff000000)),
    );
  }

  handleRemoveBank(id) {
    _loadingBankConnected();
    // final index = bankConnected.indexWhere((element) => element["id"] == id);
    // if (index != 1) {
    //   bankConnected.removeAt(index);
    //   if (mounted) setState(() => bankConnected);
    // }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final currentMember = Provider.of<Workspaces>(context, listen: false).currentMember;

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              child: Text(
                "Danh sách tài khoản ngân hàng",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300)
              )
            ),
            SizedBox(height: 20),
            Wrap(
              children: [
                ...bankConnected.map((bank) {
                  final index = listBanking.indexWhere((element) => element["id"] == bank["bank_id"]);
                  var bankInfo = index != -1 ? listBanking[index] : {};

                  return InkWell(
                    onTap: () => showCardInfo(context, bank, bankInfo, handleRemoveBank),
                    child: Container(
                      width: 220,
                      height: 120,
                      child: Card(
                        color: Color(bankInfo["color_card"] ?? 0xff008fd5),
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
                                      color: bank["connect_status"] == 1 ? Colors.green : Colors.grey,
                                    ),
                                    child: Text(bank["connect_status"] == 1 ? "Kết nối" : "Tạm dừng", style: style(8)),
                                  ),
                                  Container(
                                    child: Text(bankInfo["short_name"].toString().toUpperCase(), style: style(10))
                                  )
                                ],
                              ),
                              SizedBox(height: 10),
                              Center(
                                child: Text(bank["bank_account_name"].toString().toUpperCase(), style: style(12))
                              ),
                              SizedBox(height: 5),
                              Center(
                                child: Text(
                                  bank["bank_sub_acc_id"] ?? "",
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
                  );
                }),
              ],
            ),
            SizedBox(height: 20),
            if (currentMember["role_id"] <= 2) Expanded(
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB))
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        child: Text(
                          "Chọn ngân hàng bạn muốn thêm",
                          style: TextStyle(fontWeight: FontWeight.w300)
                        )
                      ),
                      SizedBox(height: 20),
                      Wrap(
                        children: [
                          ...listBanking.map((e) {
                            return Stack(
                              children: [
                                Container(
                                  width: 110,
                                  margin: EdgeInsets.symmetric(horizontal: 8),
                                  child: TextButton(
                                    style: ButtonStyle(
                                      padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                                      overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
                                      shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0))),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            child: Image.asset(
                                              e["logo"].toString(),
                                              width: 40,
                                              height: 40,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(e["short_name"], style: style(14)),
                                          Text(e["bank_type"] == "personal" ? "Cá nhân" : "Doanh nghiệp", style: style(14, color: Colors.green))
                                        ],
                                      ),
                                    ),
                                    onPressed: () => showLoginBanking(context, e, handleConnectBank)
                                  ),
                                ),
                                if (e["is_verified"]) Positioned(
                                  top: 0,
                                  right: 10,
                                  child: Icon(CupertinoIcons.checkmark_seal_fill, color: Palette.calendulaGold, size: 20),
                                )
                              ],
                            );
                          }),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        )
      ),
    );
  }
}

showCardInfo(context, card, bankInfo, handleRemoveBank) {
  showModal(
    context: context,
    builder: (BuildContext context) {
      return BankingCardInfo(card: card, bankInfo: bankInfo, handleRemoveBank: handleRemoveBank);
    }
  );
}

class ListTransactions extends StatefulWidget {
  final workspaceId;
  ListTransactions({Key? key, this.workspaceId}) : super(key: key);

  @override
  State<ListTransactions> createState() => _ListTransactionsState();
}

class _ListTransactionsState extends State<ListTransactions> {
  List bankConnected = [];
  List transactions = [];
  bool isLoading = false;
  String? filter;
  FocusNode focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    _loadingBankConnected();
    super.initState();
  }

  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId) {
      setState(() => transactions = []);
      _loadingBankConnected();
    }
  }

  void dispose(){
    _debounce?.cancel();
    super.dispose();
  }

  Future<dynamic> _loadingBankConnected() async {
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];
    final auth = context.read<Auth>();
    setState(() => isLoading = true);

    final url = Utils.apiUrl + "workspaces/$workspaceId/connect?token=${auth.token}";
    try {
      final response = await Dio().get(url);
      if (response.data["success"]) {
        final data = response.data["data"];
        final newData = data.where((d) => d["connect_status"] == 1).toList();
        setState(() => bankConnected = newData);
        for(int i = 0; i < newData.length; i++) {
          switch (data[i]["bank_id"]) {
            case 6:
              await _tcbTransactions(data[i]);
              break;
            case 5:
              List trans = await BankingService.getTransactions(workspaceId, auth.token);
              transactions = Map.fromIterable(transactions + trans, key: (v) => v["transaction_id"], value: (v) => v).values.toList();
              transactions.sort((a, b) => DateTime.parse(b["date"]).compareTo(DateTime.parse(a["date"])));
              break;
            default:
              break;
          }
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
      setState(() => isLoading = false);
    } catch (e, trace) {
      setState(() => isLoading = false);
      print("$e\n$trace");
    }
  }

  Future<dynamic> _tcbTransactions(data) async {
    // final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];
    final auth = context.read<Auth>();

    final url = Utils.apiUrl + "tcb/get_transactions?token=${auth.token}";
    // final url = Utils.apiUrl + "workspaces/$workspaceId/get_transactions?token=${auth.token}";
    try {
      final response = await Dio().post(
        url,
        data: json.encode({
          "username": data["username"],
          "token": data["token"]
        })
      );
      if (response.data["success"]) {
        final data = response.data["data"];
        if(data is List) {
          List trans = [];
          for(int i = 0; i < data.length; i++) {
            for(int j = 0; j < data[i]["transactions"].length; j++) {
              var accountName = data[i]["transactions"][j]["payer"]["accountNumber"];
              if (accountName == "") {
                accountName = data[i]["alias"].split('-')[0].toString();
              }
              final t = {
                "transaction_id": data[i]["transactions"][j]["txnRef"],
                "note": data[i]["transactions"][j]["txnDesc"],
                "amount": data[i]["transactions"][j]["txnAmount"],
                "remain": data[i]["transactions"][j]["balanceAfterTxn"],
                "date": data[i]["transactions"][j]["txnDate"],
                "status": data[i]["transactions"][j]["status"],
                "account_name": accountName
              };
              trans.add(t);
            }
          }
          var all = transactions + trans;
          all.sort((a, b) => DateTime.parse(b["date"]).compareTo(DateTime.parse(a["date"])));
          if (mounted) setState(() => transactions = all);
        } else {
          List trans = [];
          for(int j = 0; j < data["transactions"].length; j++) {
            var accountName = data["transactions"][j]["payer"]["accountNumber"];
              if (accountName == "") {
                accountName = data["alias"].split('-')[0].toString();
              }
            final t = {
              "transaction_id": data["transactions"][j]["txnRef"],
              "note": data["transactions"][j]["txnDesc"],
              "amount": data["transactions"][j]["txnAmount"],
              "remain": data["transactions"][j]["balanceAfterTxn"],
              "date": data["transactions"][j]["txnDate"],
              "status": data["transactions"][j]["status"],
              "account_name": accountName
            };
            trans.add(t);
          }
          var all = transactions + trans;
          all.sort((a, b) => DateTime.parse(b["date"]).compareTo(DateTime.parse(a["date"])));
          if (mounted) setState(() => transactions = all);
        }
      } else {
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
              new Center(child: new Container(child: new Text(response.data["message"] ?? response.data["error"]["value"] ?? "Xảy ra lỗi")))
          ])
        );
      }
    } catch (e, trace) {
      print("$e\n$trace");
    }
  }

  Future<dynamic> exportFile() async {
    // Create a new Excel document.
    final Workbook workbook = new Workbook();
    //Accessing worksheet via index.
    final Worksheet sheet = workbook.worksheets[0];
    //Add Text.
    sheet.getRangeByName('A1').setText('Ngày diễn ra');
    sheet.getRangeByName('B1').setText('Mã tham chiếu');
    sheet.getRangeByName('C1').setText('Nội dung');
    sheet.getRangeByName('D1').setText('Biến động');
    sheet.getRangeByName('E1').setText('Số dư');
    sheet.getRangeByName('F1').setText('Trạng thái');

    for (int i = 0; i < transactions.length; i ++) {
      print(transactions[i]);
      sheet.getRangeByName('A${i + 2}').setText(
        transactions[i]["bank_id"] == 5
          ? DateFormat("dd/MM/yyyy HH:mm").format(DateTime.parse(transactions[i]["date"]))
          : DateFormat("dd/MM/yyyy").format(DateTime.parse(transactions[i]["date"]).add(const Duration(hours: 7)))
      );
      sheet.getRangeByName('B${i + 2}').setText(transactions[i]["transaction_id"]);
      sheet.getRangeByName('C${i + 2}').setText(transactions[i]["note"]);
      sheet.getRangeByName('D${i + 2}').setText(NumberFormat.simpleCurrency(locale: 'vi').format(transactions[i]["amount"]));
      sheet.getRangeByName('E${i + 2}').setText(NumberFormat.simpleCurrency(locale: 'vi').format(transactions[i]["remain"]));
      sheet.getRangeByName('F${i + 2}').setText(transactions[i]["status"] != false ? 'Success' : "Failed");

      sheet.getRangeByName('C${i + 2}').columnWidth = 50;
    }
    // Save the document.
    final List<int> bytes = workbook.saveAsStream();
    // File('AddingTextNumberDateTime.xlsx').writeAsBytes(bytes);
    //Dispose the workbook.
    workbook.dispose();

     await FileSaveHelper.saveAndLaunchFile(bytes, 'transactions.xlsx');
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final currentMember = Provider.of<Workspaces>(context, listen: false).currentMember;
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];
    var trans = transactions;
    if (Utils.checkedTypeEmpty(filter)) {
      trans = trans.where((ele) =>
          ele["note"].toString().toLowerCase().contains(filter!) || ele["transaction_id"].toString().toLowerCase().contains(filter!)
        ).toList();
    }

    return Expanded(
      child: !isLoading
        ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: isDark ?Color(0xFF4c4c4c) : Color(0xFFfafafa),
              height: 36,
              child: TextFormField(
                autofocus: true,
                cursorWidth: 1.0,
                cursorHeight: 14,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB))),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Color(0xfffaad14) : Color(0xFF1890ff))),
                  hintText: "Lọc nhanh",
                  hintStyle: GoogleFonts.nunito(
                    textStyle: Theme.of(context).textTheme.headline4,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ?Colors.white : Color(0xFF5e5e5e),
                  )
                ),
                focusNode: focusNode,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black, fontSize: 14),
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
            Container(
              margin: EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(isDark ? Palette.calendulaGold : Color(0xFF1890ff),),
                    ),
                    onPressed: () {
                      setState(() => transactions = []);
                      _loadingBankConnected();
                    },
                    child: Icon(CupertinoIcons.arrow_2_circlepath, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, size: 15,),
                    // child: Text("Tải lại", style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight)),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 10),
                    child: OutlinedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(isDark ? Palette.calendulaGold : Color(0xFF1890ff),),
                      ),
                      onPressed: () => exportFile(),
                      child: Text("Export", style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight)),
                    )
                  )
                ],
              ),
            ),
            if (bankConnected.length > 1) Container(
              margin: EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  ...bankConnected.map((b) {
                    return Container(
                      margin: EdgeInsets.only(right: 10),
                      child: OutlinedButton(
                        onPressed: () async {
                          setState(() => transactions = []);
                          switch (b["bank_id"]) {
                            case 6:
                              await _tcbTransactions(b);
                              break;
                            case 5:
                              List trans = await BankingService.getTransactions(workspaceId, auth.token);
                              transactions = Map.fromIterable(transactions + trans, key: (v) => v["transaction_id"], value: (v) => v).values.toList();
                              transactions.sort((a, b) => DateTime.parse(b["date"]).compareTo(DateTime.parse(a["date"])));
                              break;
                            default:
                              break;
                          }
                        },
                        child: Text(b["bank_account_name"].toString(), style: TextStyle(fontSize: 12, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight)),
                      )
                    );
                  })
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: <DataColumn>[
                        DataColumn(
                          label: Text(
                            'Ngày diễn ra',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Mã tham chiếu',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Nội dung',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Biến động',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                        if (currentMember["role_id"] <= 2) DataColumn(
                          label: Text(
                            'Số dư',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                        // DataColumn(
                        //   label: Text(
                        //     'Trạng thái',
                        //     style: TextStyle(fontStyle: FontStyle.italic),
                        //   ),
                        // )
                      ],
                      rows: <DataRow>[
                        ...trans.map((t) {
                          final index = listBanking.indexWhere((element) => element["id"] == t["bank_id"]);
                          var bankInfo = index != -1 ? listBanking[index] : {};

                          return DataRow(
                            cells: <DataCell>[
                              DataCell(
                                CustomSelectionArea(
                                  child: Text(
                                    t["bank_id"] == 5
                                      ? DateFormat("dd/MM/yyyy HH:mm").format(DateTime.parse(t["date"]))
                                      : DateFormat("dd/MM/yyyy").format(DateTime.parse(t["date"]).add(const Duration(hours: 7)))),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    CustomSelectionArea(
                                      isRightTap: true,
                                      child: Text(t["transaction_id"].toString())
                                    ),
                                    if (bankInfo["logo"] != null) Container(
                                      margin: EdgeInsets.only(left: 5),
                                      child: ClipRRect(
                                        child: Image.asset(
                                          bankInfo["logo"].toString(),
                                          width: 20,
                                          height: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ),
                              DataCell(
                                Container(
                                  constraints: BoxConstraints(
                                    minWidth: 400,
                                    maxWidth: 500
                                  ),
                                  child: CustomSelectionArea(
                                    isRightTap: true,
                                    child: t["note"].toString().length * 5 > 400 ? ListAction(
                                      isDark: isDark,
                                      colorHover: Colors.transparent,
                                      arrowTipDistance: 3.0,
                                      tooltipDirection: TooltipDirection.up,
                                      action: t["note"].toString(),
                                      child: Text(t["note"].toString(), overflow: TextOverflow.ellipsis,)
                                    ) : Text(t["note"].toString())
                                  )
                                )
                              ),
                              DataCell(
                                CustomSelectionArea(
                                  child: Text(
                                    NumberFormat.simpleCurrency(locale: 'vi').format(t["amount"]),
                                    style: TextStyle(
                                      color: t["amount"] > 0 ? Color(0xff20b2aa) : Color(0xfff08080)
                                    )
                                  ),
                                )
                              ),
                              if (currentMember["role_id"] <= 2) DataCell(
                                CustomSelectionArea(
                                  child: Text(
                                    NumberFormat.simpleCurrency(locale: 'vi').format(t["remain"]),
                                    style: TextStyle(color: Color(0xff15ab64))
                                  ),
                                )
                              ),
                              // DataCell(
                              //   CustomSelectionArea(
                              //     child: Text(
                              //       t["status"] != false ? 'Success' : "Failed",
                              //       style: TextStyle(color: t["status"] != false ? Color(0xff15ab64) : Color(0xfff08080))
                              //     ),
                              //   )
                              // ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
            ),
          ],
        )
        // : Center(
        //   child: Text("Không có giao dịch.", style: GoogleFonts.nunito(
        //     textStyle: Theme.of(context).textTheme.headline4,
        //     fontSize: 14,
        //     fontWeight: FontWeight.w500,
        //     color: Colors.white,
        //   )),
        // )
        : Center(
            child: SpinKitFadingCircle(
              color: isDark ? Colors.white60 : Color(0xff096DD9),
              size: 15,
            )),
    );
  }
}

showLoginBanking(context, bank, handleConnectBank) {
  bank["is_verified"]
    ? showModal(
        context: context,
        builder: (BuildContext context) {
          return LoginFormBanking(bank: bank, handleConnectBank: handleConnectBank);
        }
      )
    : showModal(
        context: context,
        builder: (_) => SimpleDialog(
        children: <Widget>[
            new Center(child: new Container(child: new Text("Vui lòng liên hệ nhân viên Pancake để được hỗ trợ.")))
        ])
      );
}

class LoginFormBanking extends StatefulWidget {
  final bank;
  final handleConnectBank;
  LoginFormBanking({Key? key, this.bank, this.handleConnectBank}) : super(key: key);

  @override
  State<LoginFormBanking> createState() => _LoginFormBankingState();
}

class _LoginFormBankingState extends State<LoginFormBanking> {
  TextStyle style(double? size, {color}) {
    final isDark = context.read<Auth>().theme == ThemeType.DARK;
    return GoogleFonts.nunito(
      textStyle: Theme.of(context).textTheme.headline4,
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color ?? (isDark ? Color(0xFFFFFFFF) : Color(0xff000000)),
    );
  }

  String username = "";
  String password = "";
  final focusPass = FocusNode();
  bool isLoading = false;

  Future<dynamic> handleConnect(bank, auth) async {
    setState(() => isLoading = true);
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];

    final url = Utils.apiUrl + "workspaces/$workspaceId/connect?token=${auth.token}";
    try {
      final response = await Dio().post(
        url,
        data: json.encode({
          "bank_id": bank["id"],
          "username": username,
          "password": password
        })
      );
      if (response.data["success"]) {
        setState(() => isLoading = false);
        widget.handleConnectBank(response.data["data"]);
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
      setState(() => isLoading = false);
      print("$e\n$trace");
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<Auth>();
    final isDark = auth.theme == ThemeType.DARK;
    final bank = widget.bank;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0)),
      titlePadding: const EdgeInsets.all(0),
      backgroundColor: isDark ? Palette.backgroundTheardDark : Colors.white,
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 600,
        constraints: BoxConstraints(minHeight: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Liên kết tài khoản ngân hàng", style: style(18)),
            const SizedBox(height: 10),
            Text(bank["short_name"].toString(), style: style(18)),
            const SizedBox(height: 30),
            ClipRRect(
              child: Image.asset(
                bank["logo"].toString(),
                width: 60,
                height: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(bank["bank_type"] == "personal" ? "Cá nhân" : "Doanh nghiệp", style: style(16, color: Colors.green)),
            const SizedBox(height: 20),
            Container(
              color: isDark ?Color(0xFF4c4c4c) : Color(0xFFfafafa),
              width: 300,
              height: 36,
              child: TextFormField(
                onFieldSubmitted: (v){
                  FocusScope.of(context).requestFocus(focusPass);
                },
                autofocus: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB))),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Color(0xfffaad14) : Color(0xFF1890ff))),
                  hintText: "Tên đăng nhập",
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
                onChanged: (String t) => username = t,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              color: isDark ?Color(0xFF4c4c4c) : Color(0xFFfafafa),
              width: 300,
              height: 36,
              child: TextFormField(
                // autofocus: true,
                focusNode: focusPass,
                onFieldSubmitted:  (v) => handleConnect(bank, auth),
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
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap:() => handleConnect(bank, auth),
              child: HoverItem(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Palette.calendulaGold : Color(0xFF1890ff),
                    borderRadius: BorderRadius.all(Radius.circular(4))
                  ),
                  width: 300,
                  height: 36,
                  child: isLoading
                    ? Center(
                        child: SpinKitFadingCircle(
                          color: isDark ? Colors.white60 : Color(0xff096DD9),
                          size: 15,
                        ))
                    : Center(child: Text("Liên kết", style: TextStyle(color:Color(0xFFf5f5f5)),))
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
}