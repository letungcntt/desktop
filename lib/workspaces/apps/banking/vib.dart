import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:html/dom.dart' hide Text;
import 'package:html/parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/login/submit_button.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/providers/providers.dart';

class VibApp extends StatefulWidget {
  const VibApp({Key? key}) : super(key: key);

  @override
  State<VibApp> createState() => _VibAppState();
}

class _VibAppState extends State<VibApp> {
  Map<String, dynamic> _loginFormData = {};
  bool _isAuthority = false;
  String usernameKey = "";
  String passworkKey = "";
  String errorText = "";
  List _menus = [];
  List _accountList = [];
  List _transaction = [];
  Map _accountDetails = {};
  Map _userInfors = {};
  Map _currentAccountItem = {};
  String? currentTimeTransaction;

  List _listAccountForTransfer = [];
  Map? _currentClaimAccount;
  String? _currentClaimMonth;
  List _listClaim = [];

  final Dio _dio = Dio();
  late PersistCookieJar _persistCookieJar;
  final String vibDomain = "https://ib.vib.com.vn";
  Document _currentDocs = Document();
  String _currentPath = "";
  String catchError = "";

  @override
  void initState() {
    _loadAuthority();
    super.initState();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<Directory> get _localCoookieDirectory async {
    final _currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final path = await _localPath;
    final Directory dir = new Directory('$path\_cookies\_${_currentWorkspace["id"]}');
    await dir.create();
    return dir;
  }

  String getCookies(List<Cookie> cookies) {
    return cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
  }

  String? get _getModuleId {
    final regexModId = RegExp(r'rbSkinPageV2.Init\(([0-9]+)\)');
    final firstMatch = regexModId.firstMatch(_currentDocs.outerHtml);
    if (firstMatch != null) return firstMatch.group(1);
    return null;
  }

  String? get _getTabId {
    final regexTabId = RegExp(r'`sf_tabId`\:`([0-9]+)`');
    final dnnElement = _currentDocs.querySelector("input[id='__dnnVariable']")?.attributes["value"];
    if (dnnElement != null) {
      final firstMatch = regexTabId.firstMatch(dnnElement);
      if (firstMatch != null) {
        return firstMatch.group(1);
      }
    }
    return null;
  }

  _loadAuthority() async {
    _dio.options = new BaseOptions(
      baseUrl: vibDomain,
      connectTimeout: 5000,
      receiveTimeout: 100000,
      followRedirects: false,
      validateStatus: (status) { return status != null && status < 500; },
      headers: {
        HttpHeaders.userAgentHeader: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36',
        // HttpHeaders.cookieHeader: '__utma=252501329.432169834.1659319582.1659322030.1659327179.3;__utmb=252501329.7.10.1659327179;__utmc=252501329;__utmt=1;__utmz=252501329.1659327179.3.2.utmcsr=vib.com.vn|utmccn=(referral)|utmcmd=referral|utmcct=/;RT="z=1&dm=ib.vib.com.vn&si=fdd5bd63-e664-4a77-a9da-3abbb2d3b080&ss=l6a8k527&sl=0&tt=0";VIBJqcZVcZPSr=c6294c7c2d244352961ceb7bfdd7f2b6;_gcl_au=1.1.1081101038.1659319917;_gid=GA1.3.258442234.1659319917;ADRUM=s=1659327181863&r=https%3A%2F%2Fwww.vib.com.vn%2Fvn%2Fhome;__RequestVerificationToken=j1cn8de9ufCVfIcc97d9GNO09ELGrQD41Tqwl96yffKnt9WFRJO45mwHt96Htu9noVBJNA2;.ASPXANONYMOUS=LntRLmowyYJcs3kqT3ZXz8KW0msOGSIhCqfw2TSHKBSFZXOLMCqavPPQ4Mb1RdaLsqF5IV5kJM4v1rqeHLTlFntmtrAH9NrpvltK67EdwlSA73u00;.IBVIB=AC2A22FA5C726C5A0446519CEA2D6A069C5B676FEABCAD7C832C93330CAA4265F220ADC9350240E15BAD887E9BDDA24A53D745F055A51EF321151BC86FCFF4506A6234B3C486B9861EF4E07C634BBB235D45D05A;ASP.NET_SessionId=3qwyyycjecrn2baymk3v0uuc;authentication=DNN;CurrentUserId=421218;f5_cspm=1234;f5_cspm=1234;f5avraaaaaaaaaaaaaaaa_session_=CCAEDPADAIBICDJBINKPIPIAEBDPPCCNBMGPKECCDPDJJABMAIFDDCCBLFIDMJJHNLDDGMAGKEJFFNPHEHPAJJCNGFCMJKJBEOEODGAGFDPPDAPKIMLLPNNKDFNPOHLL;f5avraaaaaaaaaaaaaaaa_session_=OPNKHMGPCKBLAGBDLECKILDFJGPIAFOHJPLKJCCLCKFDNCNAIIFHDBJPJAMOKKGPJKHDDFMFFEGCIHEPPEKAKCMDHFCPPPOPCOHLBKGDEMGBODIFDFBGHKGALCOGMFHJ;f5avraaaaaaaaaaaaaaaa_session_=OPHIABFCIPJOALJBFFKIMGCNKBHCNNCJIJHCMLJKLFAGNDJELHHBGGHNNGIKFODAOPLDEEBMBEMBNCDPOMPAFCJPNDMHKGEPOLPKGIECOEILIBDKMBKDICBGIJAOHEGJ;IsPostBack=true;language=vi-VN;LastPageId=0:588;SameSite=None;'
      }
    );
    final Directory dir = await _localCoookieDirectory;
    final cookiePath = dir.path;
    _persistCookieJar = PersistCookieJar(storage: FileStorage(cookiePath));
    _dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) {
        final _setCookieHeader = response.headers[HttpHeaders.setCookieHeader];
        if (response.requestOptions.uri.path == "/vi-vn/login2020.aspx" && response.requestOptions.method == "POST" && _setCookieHeader != null) {
          final indexUnsafetyHeader = _setCookieHeader.indexWhere((cookie) {
            List keyValue = _parseSetCookieValue(cookie);
            if (keyValue.length != 2) return false;
            var value = keyValue[1];
            return !_validateValue(value);
          });
          if (indexUnsafetyHeader != -1) _setCookieHeader.removeAt(indexUnsafetyHeader);
          response.headers.set(HttpHeaders.setCookieHeader, _setCookieHeader);
        }
        if (response.statusCode != 200 && response.statusCode != 302) {
          print(response.data);
        }
        handler.next(response);
      },
      onError: (e, handler) {
        if(e.response != null) {
          final response = e.response!;
          final _setCookieHeader = response.headers[HttpHeaders.setCookieHeader];
          if (response.requestOptions.uri.path == "/vi-vn/login2020.aspx" && response.requestOptions.method == "POST" && _setCookieHeader != null) {
            final indexUnsafetyHeader = _setCookieHeader.indexWhere((cookie) {
              List keyValue = _parseSetCookieValue(cookie);
              if (keyValue.length != 2) return false;
              var value = keyValue[1];
              return !_validateValue(value);
            });
            if (indexUnsafetyHeader != -1) print(_setCookieHeader.removeAt(indexUnsafetyHeader));
            response.headers.set(HttpHeaders.setCookieHeader, _setCookieHeader);
            handler.next(DioError(
              requestOptions: e.response!.requestOptions,
              response: response
            ));
            return;
          }
        }
        handler.next(e);
      },
    ));

    _dio.interceptors.add(CookieManager(_persistCookieJar));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        _dio.options.headers = options.headers;
        // print(_dio.options.headers[HttpHeaders.cookieHeader]);
        handler.next(options);
      },
    ));

    try {
      final res = await _dio.get("/vi-vn/canhan2020v2/taikhoan.aspx");
      if (res.statusCode != 200 || res.statusCode == 302 || res.data == null ) {
        _currentPath = res.requestOptions.path;
        // print(res.requestOptions.headers[HttpHeaders.cookieHeader]);
        print("=====> Authorization failed, redirect to: ${res.headers.map[HttpHeaders.locationHeader]}");
        _loadLoginDataForm();
      }
      else {
        var document = parse(res.data);
        _currentDocs = document;
        _currentPath = "/vi-vn/canhan2020v2/taikhoan.aspx";
        setState(() {
          _isAuthority = true;
        });
        await _getMenuList();
        await _getAccountList();
        await _getListUserInfo();

      }
    } catch (e, trace) {
      print("$e\n$trace");
    }
  }

  _loadLoginDataForm() async {
    setState(() {
      _isAuthority = false;
    });
    try {
      final res = await _dio.get("/vi-vn/login2020.aspx");
      var document = parse(res.data);
      final eventTarget = document.querySelector("input[name='__EVENTTARGET']") ?? document.getElementById("__EVENTTARGET");
      final eventArgument = document.querySelector("input[name='__EVENTARGUMENT']") ?? document.getElementById("__EVENTARGUMENT");
      final viewState = document.querySelector("input[name='__VIEWSTATE']") ?? document.getElementById("__VIEWSTATE");
      final viewGenerate = document.querySelector("input[name='__VIEWSTATEGENERATOR']") ?? document.getElementById("__VIEWSTATEGENERATOR");
      final viewEncrypted = document.querySelector("input[name='__VIEWSTATEENCRYPTED']") ?? document.getElementById("__VIEWSTATEENCRYPTED");
      final eventValidation = document.querySelector("input[name='__EVENTVALIDATION']") ?? document.getElementById("__EVENTVALIDATION");
      final scrollTop = document.querySelector("input[name='ScrollTop']") ?? document.getElementById('ScrollTop');
      final dnnVariable = document.querySelector("input[name='__dnnVariable']") ?? document.getElementById('__dnnVariable');
      final uid = document.querySelector("input[name='_uid']") ?? document.getElementById('_uid');
      final requestVerificationToken = document.querySelector("input[name='__RequestVerificationToken']");

      final usernameField = document.getElementById('Username');
      final passwordField = document.getElementById('Password');

      _loginFormData["__EVENTTARGET"] = eventTarget?.attributes["value"];
      _loginFormData["__EVENTARGUMENT"] = eventArgument?.attributes["value"];
      _loginFormData["__VIEWSTATE"] = viewState?.attributes["value"];
      _loginFormData["__VIEWSTATEGENERATOR"] = viewGenerate?.attributes["value"];
      _loginFormData["__VIEWSTATEENCRYPTED"] = viewEncrypted?.attributes["value"];
      _loginFormData["__EVENTVALIDATION"] = eventValidation?.attributes["value"];
      _loginFormData["__dnnVariable"] = dnnVariable?.attributes["value"];
      _loginFormData["ScrollTop"] = scrollTop?.attributes["value"];
      _loginFormData["_uid"] = uid?.attributes["value"];
      _loginFormData["__RequestVerificationToken"] = requestVerificationToken?.attributes["value"];

      usernameKey = usernameField!.attributes["name"]!;
      passworkKey = passwordField!.attributes["name"]!;

    } catch (e, trace) {
      print("$e\n$trace");
    }
  }

  _loginVIBAccount(username, password) async {
    _loginFormData[usernameKey] = username;
    _loginFormData[passworkKey] = password;

    final res = await _dio.post(
      "/vi-vn/login2020.aspx",
      data: FormData.fromMap(_loginFormData),
      options: Options(
        followRedirects: false,
        validateStatus: (status) { return status != null && status < 500; }
      ),
    );

    final document = parse(res.data, generateSpans: true, sourceUrl: vibDomain+"/vi-vn/login2020.aspx");
    if (res.statusCode == 302) {
      var location = res.headers.map[HttpHeaders.locationHeader]![0];
      setState(() {
        _isAuthority = true;
      });
      await _loadPage(Uri.parse(location).path);
      await _getMenuList();
      await _getAccountList();
      await _getListUserInfo();
      return;
    }
    final errorDialog = document.querySelector("p[class='error']");
    if (errorDialog != null) {
      setState(() {
        errorText = errorDialog.text.trim();
      });
    } else {
      // print(res.data);
    }
  }

  _loadPage(String path) async {
    try {
      final _res = await _dio.get(path);
      var document = parse(_res.data);
      setState(() {
        _currentDocs = document;
        _currentPath = path;
      });
    } catch (e) {

    }
  }

  _loadTemplate(String path) async {
    switch (path) {
      case "/vi-vn/canhan2020v2/taikhoan.aspx":
        await _getAccountList();
        break;
      case "/vi-vn/canhan2020v2/trasoat.aspx":
        await _getAccountForTransfer();
        break;
      default:
    }
  }

  _getMenuList() async {
    try {
      final res = await _dio.get(
        "/API/MenuController/Menu/List",
        options: Options(
          headers: {
            "referer": "https://ib.vib.com.vn/vi-vn/canhan2020v2/taikhoan.aspx"
          }
        )
      );
      if (res.data["STATUSCODE"] == "000000") {
        setState(() => _menus = res.data["DATA"]);
      }
    } catch (e, trace) {
      print("$e\n$trace");
    }
  }

  _getListUserInfo() async {
    try {
      final res = await _dio.get("/API/UserController/User/Info");
      if (res.data["STATUSCODE"] == "000000") {
        setState(() {
          _userInfors = Map.from(res.data["DATA"]);
        });
        // print(_userInfors);
      }
    } catch (e) {

    }
  }

  _getAccountList() async {
    try {
      final res = await _dio.get(
        "/API/AccountController/Account/List",
        options: Options(
          headers: {
            "referer": "https://ib.vib.com.vn/vi-vn/canhan2020v2/taikhoan.aspx",
            "moduleid": _getModuleId,
            "tabid": _getTabId
          }
        )
      );
      if (res.data["STATUSCODE"] == "000000") {
        setState(() => _accountList = res.data["DATA"]);
        if (_accountList.isNotEmpty) {
          final _firstItem = _accountList.first;
          if (_firstItem["producttype"] == "CA")
            await _getAccountItem(_firstItem);
          else if (_firstItem["producttype"] == "CARD")
            await _getCardItem(_firstItem);
        }
      }
    } catch (e, trace) {
      print("$e\n$trace");
      _loadLoginDataForm();
    }
  }

  _getAccountItem(item) async {
    final path =  "/API/AccountController/Account/Detail";
    _currentAccountItem = item;
    try {
      final res = await _dio.get(
        path,
        queryParameters: {
          "id": item["id"]
        },
        options: Options(
          headers: {
            "referer": "https://ib.vib.com.vn/vi-vn/canhan2020v2/taikhoan.aspx",
            "moduleid": _getModuleId,
            "tabid": _getTabId
          }
        )
      );
      if (res.data["STATUSCODE"] == "000000") {
        setState(() {
          _accountDetails = Map.from(res.data["DATA"]);
        });
      }
      final acctInfo = _getAcctInfo(item, "${DateTime.now().month}-${DateTime.now().year}");
      await _getListTransaction(item["id"], item["servicetype"], acctInfo["timetype"], 0, acctInfo["dtfrom"], acctInfo["dtto"]);

    } catch (e, trace) {
      print("$e\n$trace");
      _loadLoginDataForm();
    }
  }

  _getCardItem(item) async {
    _currentAccountItem = item;
  }

  _getListTransaction(acctId, acctType, timeType, pageIndex, dtFrom, dtTo) async {
    try {
      final res = await _dio.get(
        "/API/AccountController/Account/ListTrans",
        options: Options(
          headers: {
            "referer": "https://ib.vib.com.vn/vi-vn/canhan2020v2/taikhoan.aspx",
            "moduleid": _getModuleId,
            "tabid": _getTabId
          }
        ),
        queryParameters: {
          "acctid": acctId,
          "accttype": acctType,
          "timetype": timeType,
          "pageindex": pageIndex,
          "dtfrom": dtFrom,
          "dtto": dtTo
        }
      );
      if (res.data is Map && res.data["STATUSCODE"] == "000000") {
        setState(() => _transaction = res.data["DATA"]);
        print(_transaction);
      }
    } catch (e, trace) {
      print("$e\n$trace");
      _loadLoginDataForm();
    }
  }

  __loadTransaction(String dtFrom) async {

    final acctId = _currentAccountItem["id"];
    final acctType = _currentAccountItem["servicetype"];
    final timeType = "month";
    final pageIndex = 0;
    final acctInfo = _getAcctInfo(_currentAccountItem, dtFrom);

    _getListTransaction(acctId, acctType, timeType, pageIndex, dtFrom, acctInfo["dtto"]);
  }

  _getAcctInfo(item, dtFrom) {
    var dtFromMonth = dtFrom.split("-")[0];
    var dtFromYear = dtFrom.split("-")[1];
    final dtToTime = DateTime(int.parse(dtFromYear), int.parse(dtFromMonth) + 1);
    final dtTo = "${dtToTime.month}-${dtToTime.year}";
    final timeType = "month";
    currentTimeTransaction = dtFrom;
    return {
      "acctid": item["id"],
      "accttype": item["servicetype"],
      "timetype": timeType,
      "dtfrom": dtFrom,
      "dtto": dtTo
    };
  }

  _getAccountForTransfer() async {
    try {
      final res = await _dio.get(
        "/API/AccountController/Account/AccountForTransfer?module=TRANSACTIONCLAIM",
        options: Options(
          headers: {
            "referer": "https://ib.vib.com.vn/vi-vn/canhan2020v2/trasoat.aspx",
            "moduleid": _getModuleId,
            "tabid": _getTabId
          }
        )
      );
      if (res.statusCode == 200 && res.data["STATUSCODE"] == "000000") {
        setState(() => _listAccountForTransfer = List.from(res.data["DATA"]));
        if (_listAccountForTransfer.isNotEmpty) {
          var _firstAccount = _listAccountForTransfer.first;
          var monthNow = "${DateTime.now().month}/${DateTime.now().year}";
          _currentClaimAccount = _firstAccount;
          _getListClaim(_firstAccount, monthNow);
        }
      }
    } catch (e, trace) {
      print("$e\n$trace");
    }
  }

  _exportCookie() async {
    try {
      final res = await _dio.get("/");

      showModal(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: SizedBox(
              width: 500,
              // height: 500,
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: "Cookie",
                  labelStyle: TextStyle(fontSize: 16) ,
                  contentPadding: EdgeInsets.all(16)
                ),
                readOnly: true,
                minLines: 20,
                maxLines: 30,
                initialValue: "${res.requestOptions.headers[HttpHeaders.cookieHeader]}",
              ),
            ),
          );
        }
      );
    } catch (e) {

    }
  }

  _getListClaim(account, date) async {
    try {
      if (account == null) return;
      final res = await _dio.get(
        "/API/TransactionController/OnlineClaim/List",
        queryParameters: {
          "acctno": account["Value"],
          "month": date ?? "${DateTime.now().month}/${DateTime.now().year}"
        },
        options: Options(
          headers: {
            "referer": "https://ib.vib.com.vn/vi-vn/canhan2020v2/trasoat.aspx",
            "moduleid": _getModuleId,
            "tabid": _getTabId
          }
        )
      );

      if (res.statusCode == 200 && res.data["STATUSCODE"] == "000000") {
        setState(() => _listClaim = res.data["DATA"]);
        print(_listClaim);
      }

    } catch (e, trace) {
      print("$e\n$trace");
    }
  }

  _logoutVIBAccount() async {
    try {
      final _res = await _dio.get(
        "/vi-vn/canhan2020v2/tabid/588/ctl/Logoff/language/vi-VN/Default.aspx",
      );
      print(_res.statusCode);
      _loadLoginDataForm();
    } catch (e, trace) {
      print("$e\n$trace");
    }
  }

  _sendToChannel(dio, date) {
    showModal(
      context: context,
      builder: (context) {
        return InvestModal(date: date, transactions: _transaction,);
      }
    );
  }

  _buildLoginPage() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(fit: BoxFit.cover,
          image: NetworkImage("https://ib.vib.com.vn/Portals/_default/skins/vib-rb-2020v2/img/bg-login.jpg")
        )
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 470,
            maxHeight: 340
          ),
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7)
          ),
          child: Column(
            children: [
              Image(image: NetworkImage("https://ib.vib.com.vn/images/logo-n-text.png"), width: 100, height: 100),
              VibLoginForm(
                onSubmit: _loginVIBAccount
              ),
              Text(errorText, style: TextStyle(color: Colors.black),),
            ],
          ),
        ),
      ),
    );
  }

  _buildDashboard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLeftSider(),
        Expanded(
          child: _buildRightSider(_currentPath),
        )
      ],
    );
  }

  _buildLeftSider() {
    var pathBackground = _userInfors["ImageBackground"];
    var backgroundImageUrl = pathBackground == null ? null : vibDomain + pathBackground;
    return Container(
      constraints: BoxConstraints(
        maxWidth: 200
      ),
      decoration: backgroundImageUrl != null ? BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(backgroundImageUrl),
          fit: BoxFit.cover,
        )
      ) : BoxDecoration(),
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image(image: NetworkImage("https://ib.vib.com.vn/Portals/_default/Skins/VIB-RB-2020/img/logo-white.png"), width: 40, height: 40,),
          ..._menus.map((e) {
            var path = e["url"].split(vibDomain)[1];
            var iconUrl = vibDomain + e["icon"];
            try {
              return InkWell(
                onTap: () {
                  _loadPage(path).then((_) => _loadTemplate(path));
                },
                child: SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: Row(
                    children: [
                      CachedImage(iconUrl, height: 40,),
                      Text(e["name"])
                    ],
                  ),
                ),
              );
            } catch (e, trace) {
              _catchTraceError(e, trace);
              return _errorWidget;
            }
          }),
          Expanded(child: Container()),
          OutlinedButton(
            style: ButtonStyle(
              // maximumSize:,
              backgroundColor: MaterialStateProperty.all(Colors.blue),
              minimumSize:  MaterialStateProperty.all(Size(double.infinity, 40)),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))
            ),
            onPressed: _exportCookie,
            child: Text("Export Cookie", style: TextStyle(color: Colors.white),),
          ),
          SizedBox(height: 20,),
          OutlinedButton(
            style: ButtonStyle(
              // maximumSize:,
              backgroundColor: MaterialStateProperty.all(Colors.red),
              minimumSize:  MaterialStateProperty.all(Size(double.infinity, 40)),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))
            ),
            onPressed: _logoutVIBAccount,
            child: Text("Logout", style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }
  Widget _buildRightSider(String path) {
    try {
      switch (path) {
        case "/vi-vn/canhan2020v2/taikhoan.aspx":
          return _buildAccountRightSider();
        case "/vi-vn/canhan2020v2/trasoat.aspx":
          return _buildInvestRightSider();
        default:
          return Container(
            color: Colors.white,
            child: Center(
              child: Text("Phần này chưa hỗ trợ xem bây giờ, vui lòng liên lạc với người phụ trách", style: TextStyle(color: Colors.black),),
            ),
          );
      }
    } catch (e, trace) {
      _catchTraceError(e, trace);
      return _errorWidget;
    }
  }

  _buildAccountRightSider() {
    return Column(
      children: [
        Container(
          height: 60,
          color: Colors.white,
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(10),
            color: Color(0xffF2F2F2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeftAccountContent(),
                Expanded(child: _buildRightAccountContent()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _buildInvestRightSider() {
    return Container(
      color: Color(0xffF2F2F2),
      child: Column(
        children: [
          Container(
            height: 60,
            color: Colors.white,
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(10),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: Colors.black
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {},
                            child: Text("Yêu cầu tra soát"),
                          ),
                          InkWell(
                            onTap: () {},
                            child: Text("Lịch sử tra soát"),
                          )
                        ],
                      ),
                    ),
                    Text(
                      "Tính năng tra soát không áp dụng cho các giao dịch chuyển tiền nội địa thường, chuyển tiền nội bộ VIB, giao dịch phi tài chính.",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          height: 60,
                          child: DropdownButton<String>(
                            value: _currentClaimMonth,
                            iconEnabledColor: Colors.black,
                            hint: Text("Choose month", style: TextStyle(color: Colors.black)),
                            dropdownColor: Colors.white,
                            items: _generateListMonth(2, '/'),
                            onChanged: (value) {
                              _currentClaimMonth = value;
                              _getListClaim(_currentClaimAccount, value);
                            },
                          ),
                        ),
                        SizedBox(
                          height: 60,
                          child: DropdownButton<Map>(
                            style: TextStyle(color: Colors.black),
                            iconEnabledColor: Colors.black,
                            alignment: Alignment.center,
                            dropdownColor: Colors.white,
                            hint: Text("Choose account", style: TextStyle(color: Colors.black),),
                            value: _currentClaimAccount,
                            items: _listAccountForTransfer.map((e) => DropdownMenuItem<Map>(child: Text(e["Text"]), value: e)).toList(),
                            onChanged: (value) {
                              // print(value);
                              // print(_listAccountForTransfer);
                              _currentClaimAccount = value;
                              _getListClaim(value, _currentClaimMonth);
                            },
                          ),
                        )
                      ],
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 150,
                                child: Text("Ngày giao dịch"),
                              ),
                              Expanded(
                                child: Text("Nội dung"),
                              ),
                              SizedBox(
                                width: 150,
                                child: Text("Số tiền"),
                              )
                            ],
                          ),
                          ..._listClaim.map((e) {
                            try {
                              return Row(
                                children: [
                                  SizedBox(
                                    width: 150,
                                    child: Text(e["trandatestr"]),
                                  ),
                                  Expanded(
                                    child: Text(e["description"]),
                                  ),
                                  SizedBox(
                                    width: 150,
                                    child: Text(e["amount"]),
                                  )
                                ],
                              );
                            } catch (e, trace) {
                              _catchTraceError(e, trace);
                              return _errorWidget;
                            }
                          })
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _buildLeftAccountContent() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.all(10),
      width: 200,
      height: double.infinity,
      child: Column(
        children: [
          ..._accountList.map((e) {
            try {
              return  Container(
                color: Colors.grey[200],
                width: double.infinity,
                height: 60,
                child: InkWell(
                  onTap: () {
                    if (e["producttype"] == "CA")
                      _getAccountItem(e);
                    else if (e["producttype"] == "CARD")
                      _getCardItem(e);
                  },
                  child: Row(
                    children: [
                      CachedImage(vibDomain+e["productactiveicon"]),
                      Expanded(
                        child: Text("${e["producttitle"]} ${e["balance"]} ${e["ccy"]}", style: TextStyle(color: Color(0xff0066B3)))
                      ),
                    ],
                  )
                ),
              );
            } catch (e, trace) {
              _catchTraceError(e, trace);
              return _errorWidget;
            }
          }),
        ],
      ),
    );
  }
  _buildRightAccountContent() {
    if (_currentAccountItem["producttype"] == "CA")
      if (_accountDetails.isNotEmpty) return _buildAccountDetails();
      else return Container();
    else if (_currentAccountItem["producttype"] == "CARD")
      return Container(child: Center(child: Text("Thông tin CARD ACCOUNT")));
    else
      return Container(child: Center(child: Text("Thông tin chưa hỗ trợ xem bây giờ")));
  }

  _buildAccountDetails() {
    try {
      return DefaultTextStyle(
        style: TextStyle(color: Colors.black),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 40,
                  child: Text("THÔNG TIN TÀI KHOẢN", style: TextStyle(fontSize: 16))
                ),
                SizedBox(
                  height: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Số tài khoản"),
                      Text(_accountDetails["acctid"]),
                    ],
                  ),
                ),
                SizedBox(
                  height: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Số dư hiện tại"),
                      Text("${_accountDetails["balance"]} ${_accountDetails["ccy"]}"),
                    ],
                  ),
                ),
                SizedBox(
                  height: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Số dư khả dụng"),
                      Text("${_accountDetails["availbalance"]} ${_accountDetails["ccy"]}"),
                    ],
                  ),
                ),
                SizedBox(
                  height: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Chi nhánh"),
                      Text(_accountDetails["branchname"]),
                    ],
                  ),
                ),
              ],
            ),
            Divider(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("LỊCH SỬ GIAO DỊCH"),
                  ),
                  DropdownButton<String>(
                    dropdownColor: Colors.white,
                    iconEnabledColor: Colors.pink,
                    hint: Text("Choose timerange"),
                    value: currentTimeTransaction,
                    items: _generateListMonth(6, '-'),
                    onChanged: (value) {
                      __loadTransaction(value!);
                    },
                  ),
                  ..._transaction.map((e) {
                    try {
                      return Row(
                        children: [
                          Text(e["EffectDate"]),
                          SizedBox(width: 30),
                          Expanded(child: Text(e["Desc"])),
                          if (e["TranType"] == "Credit") Text("${e["strAmount"]} ${e["CCY"]}"),
                          if (e["TranType"] == "Debit") Text("-${e["strAmount"]} ${e["CCY"]}")
                        ],
                      );
                    } catch (e, trace) {
                      _catchTraceError(e, trace);
                      return _errorWidget;
                    }
                  })
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                style: ButtonStyle(
                  // maximumSize:,
                  backgroundColor: MaterialStateProperty.all(Colors.blue),
                  fixedSize:  MaterialStateProperty.all(Size(100, 40)),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)))
                ),
                onPressed: (){
                  _sendToChannel(_dio, currentTimeTransaction);
                },
                child: Text("Send", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    } catch (e, trace) {
      _catchTraceError(e, trace);
      return _errorWidget;
    }
  }

  List<DropdownMenuItem<String>> _generateListMonth(length, dash) {
    final _now = DateTime.now();
    List<DropdownMenuItem<String>> result = [];

    for (var i = 0; i < length; i++) {
      final subtractMonth = DateTime(_now.year, _now.month - i);
      final value = "${subtractMonth.month}$dash${subtractMonth.year}";
      result.add(DropdownMenuItem<String>(child: Text(value, style: TextStyle(color: Colors.black),), value: value));
    }
    return result;
  }

  Widget get _errorWidget => Text("Error widget", style: TextStyle(color: Colors.red));
  _catchTraceError(e, StackTrace trace) {
    catchError += e.toString() + "\n" + trace.toString() +"\n";
  }

  @override
  Widget build(BuildContext context) {
    return !_isAuthority ? _buildLoginPage() : _buildDashboard();
  }
}

List _parseSetCookieValue(String s) {
  int index = 0;

  bool done() => index == s.length;

  String parseName() {
    int start = index;
    while (!done()) {
      if (s[index] == "=") break;
      index++;
    }
    return s.substring(start, index).trim();
  }

  String parseValue() {
    int start = index;
    while (!done()) {
      if (s[index] == ";") break;
      index++;
    }
    return s.substring(start, index).trim();
  }

  var _name = parseName();
  if (done() || _name.isEmpty) {
    return [];
  }
  index++;
  var _value = parseValue();
  return [_name, _value];
}

_validateValue(String newValue) {
  int start = 0;
  int end = newValue.length;
  if (2 <= newValue.length &&
      newValue.codeUnits[start] == 0x22 &&
      newValue.codeUnits[end - 1] == 0x22) {
    start++;
    end--;
  }

  for (int i = start; i < end; i++) {
    int codeUnit = newValue.codeUnits[i];
    if (!(codeUnit == 0x21 ||
        (codeUnit >= 0x23 && codeUnit <= 0x2B) ||
        (codeUnit >= 0x2D && codeUnit <= 0x3A) ||
        (codeUnit >= 0x3C && codeUnit <= 0x5B) ||
        (codeUnit >= 0x5D && codeUnit <= 0x7E))) {
      return false;
    }
  }
  return true;
}
// ignore: must_be_immutable
class VibLoginForm extends StatefulWidget {
  VibLoginForm({Key? key, this.onSubmit}) : super(key: key);
  Function(String, String)? onSubmit;

  @override
  State<VibLoginForm> createState() => _VibLoginFormState();
}

class _VibLoginFormState extends State<VibLoginForm> {
  TextEditingController _userTextController = TextEditingController();

  TextEditingController _passwordTextController = TextEditingController();

  bool checkSaveData = false;



  _getSaveLoginData() async {
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    var box = await Hive.openBox("vib_${currentWorkspace["id"]}");
    final isSave = box.get("isSave");
    final username = box.get("username");
    final password = box.get("password");

    if (isSave != null && username != null && password != null) {
      if (isSave) setState(() {
        checkSaveData = isSave;
        _userTextController.text = username;
        _passwordTextController.text = password;
      });
    }
  }

  _saveSaveLoginDate(isSave) async {
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    var box = await Hive.openBox("vib_${currentWorkspace["id"]}");
    if (isSave) {
      final username = _userTextController.text;
      final password = _passwordTextController.text;
      box.put('username', username);
      box.put('password', password);
      box.put('isSave', true);
    } else {
      box.put('isSave', false);
    }
    setState(() {
      checkSaveData = isSave;
    });
  }

  @override
  void initState() {
    _getSaveLoginData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _userTextController,
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: "Tên đăng nhập",
            hintStyle: TextStyle(color: Colors.grey)
          ),
        ),
        TextFormField(
          controller: _passwordTextController,
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: "Mật khẩu",
            hintStyle: TextStyle(color: Colors.grey)
          ),
        ),

        SizedBox(height: 20,),
        SubmitButton(
          onTap: (){
            widget.onSubmit?.call(_userTextController.text, _passwordTextController.text);
          },
          text: "Login"
        ),
        SizedBox(height: 10),
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Transform.scale(
                scale: 0.9,
                child: Checkbox(
                  activeColor: Colors.blue,
                  side: BorderSide(color: const Color(0xff1F2933)),
                  splashRadius: 1.0,
                  value: checkSaveData,
                  onChanged: _saveSaveLoginDate
                ),
              ),
            ),
            const SizedBox(width: 8.0,),
            Text("Remember me", style: TextStyle(color: const Color(0xff1F2933), fontSize:  13),)
          ],
        )
      ],
    );
  }
}

class InvestModal extends StatefulWidget {
  const InvestModal({Key? key,required this.date, required this.transactions}) : super(key: key);
  final String date;
  final List transactions;

  @override
  State<InvestModal> createState() => _InvestModalState();
}

class _InvestModalState extends State<InvestModal> {
  Map? _choosenChannel;
  int _countSuccessMessage = 0;
  int _countErrorMessage= 0;
  String _errorText = "";
  bool isSending = false;
  _generateChannelItem(List channels) {
    return channels.map((e) => DropdownMenuItem<Map>(child: Text(e["name"]), value: e)).toList();
  }
  // _loadListDetailsTransaction() async {

  // }

  _sendToChannel(channelId, workspaceId, token) async {
    setState(() {
      isSending = true;
    });
    for (var e in widget.transactions) {
      var debit = e["TranType"] == "Credit" ? "" : "-";
      var data = {
        'id': e["TranId"],
        'bank': "vib",
        'note': e["Desc"],
        'date': e["strDate"],
        'amount': debit + e["strAmount"].toString(),
        'remain': e["strStmtRunningBal"]
      };
      var c = {};
      c["transfer"] = data;
      var dataMessage = {
        "message": "",
        "attachments": [{"type": "BizBanking", "data": c}],
        "channel_id":  channelId,
        "workspace_id": workspaceId,
        "key": Utils.getRandomString(20),
      };
      final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/messages?token=$token';
      final res = await http.post(Uri.parse(url), headers: Utils.headers, body: json.encode(dataMessage));
      final resData = json.decode(res.body);
      if (resData["success"]) {
        setState(() => _countSuccessMessage ++);
      } else {
        setState(() => _countErrorMessage ++);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    final channels = currentWorkspace["id"] != null
      ? Provider.of<Channels>(context, listen: true).data.where((e) => e["workspace_id"] == currentWorkspace["id"] && !Utils.checkedTypeEmpty(e["is_archived"])).toList()
      : [];
    final token = Provider.of<Auth>(context, listen: true).token;
    return AlertDialog(
      title: Text("Gửi thông tin tra soát"),
      actions: [
        if (!isSending) OutlinedButton(
          onPressed: () async {
            if (_choosenChannel == null) {
              setState(() {
                _errorText = "Vui lòng chọn channel";
              });
            } else {
              _errorText = "";
              _sendToChannel(_choosenChannel!["id"], _choosenChannel!["workspace_id"], token)
                .then((_) => setState(() => isSending = false));
            }
          },
          child: Text("Submit")
        )
      ],
      content: SizedBox(
        width: 300,
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bạn muốn gửi thông tin đối soát của ${widget.date}"),
            Divider(),
            Text("Tới channel"),
            DropdownButton<Map>(
              items: _generateChannelItem(channels),
              hint: Text("Choose channel"),
              value: _choosenChannel,
              onChanged: (value) {
                setState(() {
                  _choosenChannel = value;
                });
              }
            ),
            if (_countSuccessMessage > 0) Text("Gửi message vào channel thành công: $_countSuccessMessage", style: TextStyle(color: Colors.blue),),
            if (_countErrorMessage > 0) Text("Gửi message vào channel thất bại: $_countErrorMessage", style: TextStyle(color: Colors.red),),
            Text(_errorText)

            // Text("Hoặc"),
            // Row(
            //   children: [
            //     Radio<String>(
            //       value: "date",
            //       groupValue: _filterType,
            //       onChanged: (value) {
            //         setState(() {
            //           _filterType = value!;
            //         });
            //       }
            //     ),
            //     Text("Hôm nay")
            //   ],
            // ),
            // Row(
            //   children: [
            //     Radio<String>(
            //       value: "week",
            //       groupValue: _filterType,
            //       onChanged: (value) {
            //         setState(() {
            //           _filterType = value!;
            //         });
            //       }
            //     ),
            //     Text("Tuần này")
            //   ],
            // ),
            // Row(
            //   children: [
            //     Radio<String>(
            //       value: "month",
            //       groupValue: _filterType,
            //       onChanged: (value) {
            //         setState(() {
            //           _filterType = value!;
            //         });
            //       }
            //     ),
            //     Text("Tháng này")
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}



// /API/AccountController/Account/TranDetails
// - {acctid: aWtJV2p2bU1aQkJHWDlHRDhXZ2V3UT09
//     accttype: Dep
//     trantype: Debit
//     tranmode: TRANSFER
//     trandate: 26_07_2022
//     tranno: blE2bmhuQ3l5VTNCcHJzMmZHY2JlQT09
//     refid:
//     ccy: ₫
//   }
// -> {
//     "STATUSCODE": "000000",
//     "MESSAGE": "",
//     "DATA": {
//         "PostedDate": "2022-07-26T00:00:00+07:00",
//         "PostedDateStr": "26/07/2022",
//         "Amount": "100,000 ₫",
//         "FromAcct": {
//             "AcctId": "002704060386297",
//             "AcctName": "TRƯƠNG THU HƯƠNG"
//         },
//         "ToAcct": {
//             "AcctId": "19034281607017",
//             "AcctName": "DAO THI LAM"
//         },
//         "CardNo": null,
//         "CardType": "",
//         "Narrative": "TRUONG THU HUONG chuyen tien toi DAO THI LAM-19034281607017",
//         "Location": null,
//         "Status": "SUCCESSED",
//         "StatusStr": "Detail_SUCCESSED",
//         "TranNo": "4054982024",
//         "BankBenName": "NH TMCP KY THUONG (TECHCOMBANK)",
//         "ORGCCY": "VND",
//         "CCY": "₫"
//     }
// }
// /API/TransactionController/OnlineClaim/TransDetail
// - {
//   id: blE2bmhuQ3l5VTNCcHJzMmZHY2JlQT09
//   acctno: aWtJV2p2bU1aQkJHWDlHRDhXZ2V3UT09
//   trandate: 26/07/2022
// }
// -> {
//     "STATUSCODE": "000000",
//     "DATA": {
//         "id": "blE2bmhuQ3l5VTNCcHJzMmZHY2JlQT09",
//         "seqno": "361596028",
//         "amount": "100,000 ₫",
//         "fromacctno": "002704060386297",
//         "toacctno": "19034281607017",
//         "toacctname": "DAO THI LAM",
//         "bankname": "NH TMCP KY THUONG (TECHCOMBANK)",
//         "description": "TRUONG THU HUONG chuyen tien toi DAO THI LAM-19034281607017",
//         "trandate": "26/07/2022",
//         "allowclaim": true,
//         "allowviewclaim": false,
//         "claimid": ""
//     }
// }