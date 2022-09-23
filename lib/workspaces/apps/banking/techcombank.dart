import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/dropdown_overlay.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/service_locator.dart';
import 'package:workcake/services/sharedprefsutil.dart';

class TechcomBank extends StatefulWidget {
  const TechcomBank({Key? key}) : super(key: key);

  @override
  State<TechcomBank> createState() => _TechcomBankState();
}

class _TechcomBankState extends State<TechcomBank> {
  String? errorLogin;
  String? formToken;
  String? counter;
  bool isLgnTech = false;
  bool fetching = false;
  String techAcc = '';
  String techPass = '';
  String techSTK = '';
  Map<String, String>? headers;
  bool error = false;
  int? channelId;
  String? channelName;
  bool isLoading = false;
  List? transfer;
  TextEditingController controller1 = new TextEditingController();
  TextEditingController controller2 = new TextEditingController();

  @override
  void initState() {
    super.initState();
    getLgn().then((value) {
      setState(() {
        isLgnTech = value;
        techAcc = '';
      });
      if (value) {
        getAcc().then((vl) {
          techAcc = vl;
        });
      }
    });
  }

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
    super.dispose();
  }

  Future<bool> getLgn() async {
    final isLgn = sl.get<SharedPrefsUtil>().getIsLogTechcom();
    return isLgn;
  }

  Future<String> getAcc() async {
    final accTech = sl.get<SharedPrefsUtil>().getTechcomAccount();
    return accTech;
  }

  Future<String> getPass() async {
    final passTech = sl.get<SharedPrefsUtil>().getTechcomPassword();
    return passTech;
  }

  Future<String> getSTK() async {
    final stkTech = sl.get<SharedPrefsUtil>().getTechcomSTK();
    return stkTech;
  }

  sendRequestLogin() async {
    setState(() {
      fetching = true;
    });
    final url = Uri.parse('https://ib.techcombank.com.vn/servlet/BrowserServlet');
    // final url = Uri.parse('https://ib.vib.com.vn/vi-vn/loginbasic.aspx');

    try {
      final res = await http.get(url);
      print(res.headers);
      var document = parse(res.body);
      List attributes = res.headers["set-cookie"]!.split(";").where((e) => e != " Path=/").toList().join(",").split(",")
        .where((e) => e != " Domain=.techcombank.com.vn" && e != " Domain=.ib.techcombank.com.vn" && e != " path=/" && e != " Httponly" && e != " HttpOnly" && e != " Secure").toList()
        .reversed.toList();
      formToken = document.querySelector("input[name='formToken']")!.attributes["value"].toString();
      counter = document.querySelector("input[name='counter']")!.attributes["value"].toString();
      // print(attributes.join("; "));
      headers = {
        "Cookie": attributes.join("; "),
        "Accept": "*/*",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "Origin": "https://ib.techcombank.com.vn",
        "User-Agent":
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36"
      };

      String body =
        "formToken=$formToken&command=login&requestType=CREATE.SESSION&counter=$counter&branchAdminLogin=&signOnNameEnabled=Y&signOnName=${controller1.text}&password=${controller2.text}&btn_login=%C4%90%C4%82NG+NH%E1%BA%ACP&MerchantId=&Amount=&Reference=&language=2&UserType=per";

      var response = await http.post(url, body: body, headers: headers);
      final doc = parse(response.body);
      final loginError = doc.querySelector("#lgn_error");
      if (loginError?.text != null) {
        setState(() {
          fetching = false;
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text("${loginError?.text}")
            );
          }
        );
      } else {
        final params = doc.querySelector("td[height='100%']")!.attributes["fragmenturl"].toString();
        List fixed = params.split("&");
        final result = fixed.indexWhere((el) => el.startsWith("routineArgs"));
        fixed[result] = "routineArgs=COS%20AI.QCK.ACCOUNT";
        final newParams = fixed.join("&");

        final urlX = Uri.parse('https://ib.techcombank.com.vn/servlet/' + newParams);
        var responseX = await http.get(urlX, headers: headers);
        final docX = parse(responseX.body);
        final mainBodyCode = docX.querySelectorAll(".fragmentContainer.notPrintableFragment td[height='100%']")
            .map((el) => el.attributes["id"])
            .where((element) => element!.indexOf("MainBody") >= 0).toList()[0];

        final paramsX = docX.querySelectorAll(".fragmentContainer.notPrintableFragment td[height='100%']")
            .map((el) => el.attributes["fragmenturl"])
            .where((element) => element!.indexOf("MainBody") >= 0).toList();
        final compScreen = paramsX[0].toString().split("&").where((el) => el.startsWith("compScreen")).toList()[0].toString();

        final paramsT = "BrowserServlet?method=post&user=${controller1.text}&windowName=$mainBodyCode&WS_FragmentName=$mainBodyCode&contextRoot=&companyId=VN0010001&$compScreen&command=globusCommand&skin=arc-ib&requestType=UTILITY.ROUTINE&routineName=OS.GET.COMPOSITE.SCREEN.XML&routineArgs=AI.QCK.SUM&WS_replaceAll=&WS_parentComposite=$mainBodyCode";
        final urlT = Uri.parse('https://ib.techcombank.com.vn/servlet/' + paramsT);
        var responseT = await http.get(urlT, headers: headers);
        final docT = parse(responseT.body);
        final paramsZ = docT.querySelectorAll("td.fragmentContainer.notPrintableFragment")
            .map((el) => el.attributes["fragmenturl"])
            .where((element) => element!.indexOf("AcctBalance") >= 0).toList()[0].toString();

        final urlZ = Uri.parse('https://ib.techcombank.com.vn/servlet/' + paramsZ);
        var responseZ = await http.get(urlZ, headers: headers);
        final docZ = parse(responseZ.body);
        final soTaiKhoan = docZ.querySelector("tr.colour1 td:first-child");

        sl.get<SharedPrefsUtil>().setTechcomSTK(soTaiKhoan?.text);
        sl.get<SharedPrefsUtil>().setTechcomAccount(controller1.text);
        sl.get<SharedPrefsUtil>().setTechcomPassword(controller2.text);
        sl.get<SharedPrefsUtil>().setIsLogTechcom(true);
        setState(() {
          fetching = false;
          isLgnTech = true;
          techAcc = controller1.text;
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        fetching = false;
      });
    }
  }

  _logoutTechcom() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    String appId = "1889cc30-53cb-4a98-8dba-ca33f8bed6ef";
    sl.get<SharedPrefsUtil>().setTechcomAccount('');
    sl.get<SharedPrefsUtil>().setTechcomPassword('');
    sl.get<SharedPrefsUtil>().setTechcomSTK('');
    sl.get<SharedPrefsUtil>().setIsLogTechcom(false);
    setState(() {
      isLgnTech = false;
    });
    final url = "${Utils.apiUrl}app/$appId/remove_channel?token=$token";
    await Dio().delete(url);
  }

  getTransaction() async {
    getSTK().then((value) {
      techSTK = value;
    });
    getAcc().then((value) {
      techAcc = value;
    });
    getPass().then((value) {
      techPass = value;
    });
    final url = Uri.parse('https://ib.techcombank.com.vn/servlet/BrowserServlet');

    try {
      final resp = await http.get(url);
      var document = parse(resp.body);
      List attributes = resp.headers["set-cookie"]!.split(";").where((e) => e != " Path=/").toList().join(",").split(",")
        .where((e) => e != " Domain=.techcombank.com.vn" && e != " Domain=.ib.techcombank.com.vn" && e != " path=/" && e != " Httponly" && e != " HttpOnly" && e != " Secure").toList()
        .reversed.toList();
      formToken = document.querySelector("input[name='formToken']")!.attributes["value"].toString();
      counter = document.querySelector("input[name='counter']")!.attributes["value"].toString();
      headers = {
        "Cookie": attributes.join("; "),
        "Accept": "*/*",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "Origin": "https://ib.techcombank.com.vn",
        "User-Agent":
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36"
      };
      String body =
        "formToken=$formToken&command=login&requestType=CREATE.SESSION&counter=$counter&branchAdminLogin=&signOnNameEnabled=Y&signOnName=$techAcc&password=$techPass&btn_login=%C4%90%C4%82NG+NH%E1%BA%ACP&MerchantId=&Amount=&Reference=&language=2&UserType=per";
      var response = await http.post(url, body: body, headers: headers);
      // /histories 19033587164015
      final doc = parse(response.body);
      final loginError = doc.querySelector("#lgn_error");
      if (loginError?.text != null) return {"success": false, "message": "Lỗi đăng nhập"};
      final params = doc.querySelector("td[height='100%']")!.attributes["fragmenturl"].toString();
      // print("xxx $functionCode");
      List fixed = params.split("&");
      final result = fixed.indexWhere((el) => el.startsWith("routineArgs"));
      fixed[result] = "routineArgs=COS%20AI.QCK.ACCOUNT";
      final newParams = fixed.join("&");

      final urlX = Uri.parse('https://ib.techcombank.com.vn/servlet/' + newParams);
      // print("urlX $urlX");
      var responseX = await http.get(urlX, headers: headers);
      final docX = parse(responseX.body);
      final mainBodyCode = docX.querySelectorAll(".fragmentContainer.notPrintableFragment td[height='100%']")
          .map((el) => el.attributes["id"])
          .where((element) => element!.indexOf("MainBody") >= 0).toList();
      final paramsX = docX.querySelectorAll(".fragmentContainer.notPrintableFragment td[height='100%']")
          .map((el) => el.attributes["fragmenturl"])
          .where((element) => element!.indexOf("MainBody") >= 0).toList();
      final compScreen = paramsX[0].toString().split("&").where((el) => el.startsWith("compScreen")).toList()[0].toString();
      // print("compScreen ${x[1]}");
      // print("today $today");
      List fixedX = paramsX[0].toString().split("&");
      final resultX = fixedX.indexWhere((el) => el.startsWith("routineArgs"));
      fixedX[resultX] = "routineArgs=AI.QCK.TRANS.STMT.TCB";
      final newParamsX = fixedX.join("&");

      final urlY = Uri.parse('https://ib.techcombank.com.vn/servlet/' + newParamsX.toString());
      var responseY = await http.get(urlY, headers: headers);
      // print("urlY $urlY");
      // print(responseY.body);
      final paramsY = parse(responseY.body).querySelectorAll(".fragmentContainer.notPrintableFragment")
          .map((el) => el.attributes["id"])
          .where((e) => e != null)
          .where((element) => element!.indexOf("STMTSTEPTWO") >= 0).toList();
      final stmtsteptwoCode = paramsY[0].toString();
      final stringToday = DateFormat('yyyyMMdd').format(DateTime.now());
      final stringAgo = DateFormat('yyyyMMdd').format(DateTime.now().subtract(const Duration(days: 90)));

      final bodyHistories =
          "formToken=$formToken&requestType=OFS.ENQUIRY&routineName=&routineArgs=ACCOUNT%20EQ%20$techSTK%20BOOKING.DATE%20RG%20'$stringAgo%20$stringToday'%20TXN.CNT%20EQ%2010&application=&ofsOperation=&ofsFunction=&ofsMessage=&version=&transactionId=&command=globusCommand&operation=&windowName=$mainBodyCode&apiArgument=&name=&enqname=AI.QCK.TRAN.SEARCH.STMT.TCB&enqaction=SELECTION&dropfield=&previousEnqs=&previousEnqTitles=&clientStyleSheet=&unlock=&allowResize=YES&companyId=VN0010001&company=BNK-TECHCOMBANK%20HOI%20SO&user=$techAcc&transSign=&skin=arc-ib&today=15%2F07%2F2021&release=R18&$compScreen&reqTabid=&compTargets=&EnqParentWindow=$stmtsteptwoCode&timing=356-3-3-350-1&pwprocessid=&language=VN&languages=GB%2CVN&savechanges=YES&staticId=&lockDateTime=&popupDropDown=true&allowcalendar=&allowdropdowns=&allowcontext=NO&nextStage=&maximize=true&showStatusInfo=NO&languageUndefined=Language%20Code%20Not%20Defined&expandMultiString=Expand%20Multi%20Value&deleteMultiString=Delete%20Value&expandSubString=Expand%20Sub%20Value&clientExpansion=true&WS_parentWindow=&WS_parent=&WS_dropfield=&WS_doResize=&WS_initState=ENQ%20AI.QCK.TRAN.SEARCH.STMT.TCB%20ACCOUNT%20EQ%20$techSTK%20BOOKING.DATE%20RG%20'$stringAgo%20$stringToday'%20TXN.CNT%20EQ%2010&WS_PauseTime=&WS_multiPane=false&WS_replaceAll=yes&WS_parentComposite=$mainBodyCode&WS_delMsgDisplayed=&WS_FragmentName=$mainBodyCode";
      try {
        var responseZ = await http.post(url, body: bodyHistories, headers: headers)
          .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                return http.Response('Error', 500);
              }
            );
        // Timeout
        if (responseZ.statusCode == 500) return getTransaction();

        final docZ = parse(responseZ.body);
        final message = docZ.querySelector("#message");
        // Tài khoản không tồn tại (E-113653)
        if(message?.text != null) return {"success": false, "message": "Tài khoản không tồn tại"};

        final List colour0 = docZ.querySelectorAll(".colour0").toList();
        final List colour1 = docZ.querySelectorAll(".colour1").toList();
        final List colour = (colour0 + colour1).toList();
        var data = [];
        for (var i = 0; i < colour.length; i++) {
          var columns = colour[i].querySelectorAll("td");
          var row = new Map();
          final List splitIdNote = (columns[1].text).toString().split(" / ");
          row['id'] = splitIdNote[1];
          row['note'] = splitIdNote[0];
          row['date'] = columns[0].text;
          row['amount'] = columns[2].text;
          row['remain'] = columns[3].text;
          data.add(row);
        }
        data.sort((el1, el2) {
          List dateString1 = el1["date"].split('/');
          List dateString2 = el2["date"].split('/');
          String newDate1 = "${dateString1[2]}-${dateString1[1]}-${dateString1[0]}";
          String newDate2 = "${dateString2[2]}-${dateString2[1]}-${dateString2[0]}";
          DateTime dtString1 = DateTime.parse(newDate1);
          DateTime dtString2 = DateTime.parse(newDate2);
          return dtString1.compareTo(dtString2);
        });
        if(this.mounted) setState(() => transfer = data);
        return {"success": true, "data": data};
      } on TimeoutException catch (_) {
        return getTransaction();
      }
    } catch (e, trace) {
      print("$e and $trace");
      return getTransaction();
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  _sendToChannel(workspaceId, token) async {
    if(this.mounted) setState(() => isLoading = true);
    Map transfer = await getTransaction();
    Map c = {};
    if (transfer["success"]) {
      for (var i = 0; i < transfer['data'].length; i++) {
        c["transfer"] = transfer['data'][i];
        var dataMessage  = {
          "message": "",
          "attachments": [{"type": "BizBanking", "data": c }],
          "channel_id":  channelId,
          "workspace_id": workspaceId,
          "key": Utils.getRandomString(20),
        };
        final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/messages?token=$token';
        await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(dataMessage));
      }
    } else {
      c["transfer"] = transfer;
      var dataMessage  = {
        "message": "",
        "attachments": [{"type": "BizBanking", "data": c}],
        "channel_id":  channelId,
        "workspace_id": workspaceId,
        "key": Utils.getRandomString(20),
      };
      final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/messages?token=$token';
      await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(dataMessage));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    var lengthA = techAcc.length > 4 ? techAcc.length - 4 : 0;
    var newString = techAcc.substring(lengthA);
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final channels = currentWorkspace["id"] != null
      ? Provider.of<Channels>(context, listen: false).data.where((e) => e["workspace_id"] == currentWorkspace["id"] && !Utils.checkedTypeEmpty(e["is_archived"])).toList()
      : [];

    return Container(
      child: isLgnTech
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CachedImage(
                "https://upload.wikimedia.org/wikipedia/commons/7/7c/Techcombank_logo.png",
                width: 200,
              ),
              SizedBox(height: 20),
              Text("Chọn channel để gửi đối soát giao dịch trong 90 ngày gần nhất."),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 200,
                    child: DropdownOverlay(
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
                                color: error ? Colors.red : isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:  MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  channelId != null ? channelName! : "Chọn channel",
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
                                          setState(() {
                                            channelId = item["id"];
                                            channelName = item["name"];
                                          });
                                          this.setState(() => error = false);
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
                    ),
                  ),
                  SizedBox(width: 10,),
                  Container(
                    width: 120, height: 32,
                    margin: EdgeInsets.only(right: 12),
                    child: OutlinedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                      ),
                      onPressed: () => _sendToChannel(currentWorkspace["id"], token),
                      child: isLoading
                        ? Center(
                            child: SpinKitFadingCircle(
                              color: isDark ? Colors.white60 : Color(0xff096DD9),
                              size: 15,
                            ))
                        : Text(
                            'Gửi đi',
                            style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Bạn đang đăng nhập với tài khoản ***$newString"),
                  SizedBox(width: 10),
                  Container(
                    width: 120, height: 32,
                    margin: EdgeInsets.only(right: 12),
                    child: OutlinedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red),
                      ),
                      onPressed: () => _logoutTechcom(),
                      child: isLoading
                        ? Center(
                            child: SpinKitFadingCircle(
                              color: isDark ? Colors.white60 : Color(0xff096DD9),
                              size: 15,
                            ))
                        : Text(
                            'Logout',
                            style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                    ),
                  ),
                ],
              ),
            ],
          ))
        : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 50,
              ),
              CachedImage(
                "https://upload.wikimedia.org/wikipedia/commons/7/7c/Techcombank_logo.png",
                width: 200,
              ),
              SizedBox(
                height: 100,
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.5,
                padding: EdgeInsets.only(bottom: 1),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xff1F2933) : Colors.white,
                  border: Border.all(color: Colors.grey[400]!, width: 1.0),
                  borderRadius: BorderRadius.all(Radius.circular(32.0)),
                ),
                child: TextFormField(
                  controller: controller1,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter Username/Mobile number';
                    }
                    return null;
                  },
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                    hintText: "Username/Mobile number",
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none
                  )
                ),
              ),
              SizedBox(height: 25.0),
              Container(
                width: MediaQuery.of(context).size.width * 0.5,
                padding: EdgeInsets.only(bottom: 1),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xff1F2933) : Colors.white,
                  border: Border.all(color: Colors.grey[400]!, width: 1.0),
                  borderRadius: BorderRadius.all(Radius.circular(32.0)),
                ),
                child: TextFormField(
                  controller: controller2,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter password';
                    }
                    return null;
                  },
                  obscureText: true,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                    hintText: "Password (+ token key if using)",
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none
                  ),
                )
              ),
              SizedBox(height: 35.0),
              Container(
                height: 50,
                width: MediaQuery.of(context).size.width * 0.5,
                child: TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red),
                    textStyle: MaterialStateProperty.all(TextStyle(color: Colors.white)),
                    padding: MaterialStateProperty.all(EdgeInsets.all(8.0)),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.0),
                    )),
                  ),
                  onPressed: fetching ? null : () => sendRequestLogin(),
                  child: fetching
                    ? Center(
                    child: SpinKitFadingCircle(
                      color: isDark ? Colors.white60 : Color(0xff096DD9),
                      size: 15,
                    ))
                    : Text(
                      'Login',
                      style: GoogleFonts.roboto(
                        textStyle: Theme.of(context).textTheme.headline4,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                ),
              )
            ],
          ),
        ),
    );
  }
}