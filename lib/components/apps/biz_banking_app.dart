import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/service_locator.dart';
import 'package:http/http.dart' as http;
import 'package:workcake/services/sharedprefsutil.dart';

class BizBanking extends StatefulWidget {
  BizBanking({Key? key}) : super(key: key);

  @override
  _BizBankingState createState() => _BizBankingState();
}

class _BizBankingState extends State<BizBanking> {
  String? errorLogin;
  String? formToken;
  String? counter;
  bool isLgnTech = false;
  bool fetching = false;
  String techAcc = '';
  Map<String, String>? headers;
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

  // newLoginTcb() async {
  //   final String newApi = Utils.apiUrl + 'tcb/auth';

  //   final response  = await Dio().post(newApi, data: {
  //     "username": controller1.text,
  //     "password": controller2.text
  //   });

  //   final resData = response.data;
  // }

  sendRequestLogin() async {
    setState(() {
      fetching = true;
    });
    final url = Uri.parse('https://ib.techcombank.com.vn/servlet/BrowserServlet');

    try {
      final res = await http.get(url);
      var document = parse(res.body);
      List attributes = res.headers["set-cookie"]!.split(";").where((e) => e != " Path=/").toList().join(",").split(",")
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

  @override
  Widget build(BuildContext context) {
    var lengthA = techAcc.length > 4 ? techAcc.length - 4 : 0;
    var newString = techAcc.substring(lengthA);
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 40),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Container(
                width: 80,
                child: Row(
                  children: [
                    Icon(Icons.chevron_left),
                    Text("Back")
                  ],
                ),
              )
            )
          ),
          isLgnTech
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 50),
                    CachedImage(
                      "https://upload.wikimedia.org/wikipedia/commons/7/7c/Techcombank_logo.png",
                      width: 400,
                      height: 200,
                    ),
                    SizedBox(height: 100),
                    Text("Bạn đang đăng nhập với tài khoản ***$newString"),
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
                        onPressed: () => _logoutTechcom(),
                        child: Text(
                          'Logout',
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
              )
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 50,
                    ),
                    CachedImage(
                      "https://upload.wikimedia.org/wikipedia/commons/7/7c/Techcombank_logo.png",
                      width: 400,
                      height: 200,
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
                          ? SpinKitFadingCircle(
                            color: isDark ? Colors.white60 : Color(0xff096DD9),
                            size: 35,
                          )
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
        ],
      ),
      bottomSheet: Container(
        color: Colors.red[800],
        height: 24
      ),
    );
  }
}