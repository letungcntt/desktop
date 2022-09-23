import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/login/submit_button.dart';
import 'package:workcake/login_macOS.dart';
import 'package:workcake/providers/providers.dart';

class VerifyOtp extends StatefulWidget {
  final dataUser;
  final bool isResetPassword;
  const VerifyOtp({Key? key, this.dataUser, this.isResetPassword = false}) : super(key: key);

  @override
  _VerifyOtpState createState() => _VerifyOtpState();
}

class _VerifyOtpState extends State<VerifyOtp> {
  String message = '';
  bool invalidCredential = false;
  bool? sentSucess;
  bool loading = false;
  int indexFocus = 0;
  var code;
  final TextEditingController _input1 = TextEditingController();
  final TextEditingController _input2 = TextEditingController();
  final TextEditingController _input3 = TextEditingController();
  final TextEditingController _input4 = TextEditingController();

  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  final FocusNode _focusNode3 = FocusNode();
  final FocusNode _focusNode4 = FocusNode();
  var input = [];
  int timeRequestOtp = 1;

  @override
  void initState() {
    input = [
      {"controller": _input1, "focusNode": _focusNode1},
      {"controller": _input2, "focusNode": _focusNode2},
      {"controller": _input3, "focusNode": _focusNode3},
      {"controller": _input4, "focusNode": _focusNode4},
    ];

    input = input.map((e) {
      int index = input.indexWhere((ele) => ele == e);
      e["focusNode"] = FocusNode(onKey: (node, RawKeyEvent keyEvent) {
        if (keyEvent.isKeyPressed(LogicalKeyboardKey.backspace) && keyEvent is RawKeyDownEvent) {
          e["controller"].clear();
          if (index > 0) FocusScope.of(context).requestFocus(input[index - 1]["focusNode"]);
        }
        return KeyEventResult.ignored;
      });
      return e;
    }).toList();

    super.initState();
  }

  @override
  void dispose() {
    _input1.dispose();
    _input2.dispose();
    _input3.dispose();
    _input4.dispose();

    _focusNode1.dispose();
    _focusNode2.dispose();
    _focusNode3.dispose();
    _focusNode4.dispose();
    super.dispose();
  }

  setInvalidCredential(value) {
    setState(() {
      invalidCredential = value;
    });
  }

  handleSubmitConfirm() async {
    loading = true;
    invalidCredential = false;
      var data;
      if(widget.isResetPassword) {
        data = {
          "phone_number": widget.dataUser["phone_number"],
          "account_id": widget.dataUser["account_id"],
          "otp": code,
          "otp_id": widget.dataUser["otp_id"],
          "new_password": widget.dataUser["new_password"],
          "verification_type": "phone_number",
          "user_id": widget.dataUser["id"] ?? widget.dataUser["user_id"],
        };
      } else {
        data = {
          "email": widget.dataUser["email"],
          "phone_number": widget.dataUser["phone_number"],
          "otp_id": widget.dataUser["otp_id"],
          "otp": code,
          "user_id": widget.dataUser["id"] ?? widget.dataUser["user_id"],
          "account_id": widget.dataUser["account_id"]
        };
      }
      final url = "${Utils.apiUrl}users/verify_otp";

      var res = await Dio().post(url, data: data);

      if(res.data["success"]) {
        await Provider.of<Auth>(context, listen: false).loginUserPassword(widget.dataUser["phone_number"] ?? widget.dataUser["email"], widget.isResetPassword ? widget.dataUser["new_password"] : widget.dataUser["password"], context);
        setState(() {
          loading = false;
        });
        Navigator.pushNamed(context, 'main_screen_macOS');
      } else {
        setState(() {
          timeRequestOtp++;
          invalidCredential = true;
          message = res.data["message"];
          loading = false;
        });
      }

    // }
    return;
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Scaffold(
      backgroundColor: isDark ? Palette.backgroundRightSiderDark : Palette.backgroundRightSiderLight ,
      body: Column(
        children: [
          if (Platform.isWindows) SizedBox(
            height: 32,
            child: Row(
              children: [
                Expanded(
                  child: WindowTitleBarBox(
                    child: MoveWindow(),
                  ),
                ),
                WindowButtons()
              ],
            )
          ),
          SizedBox(
            height: height,
            width: width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: width * 0.41
                  ),
                  padding: EdgeInsets.only(left: width * 0.0695),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: height * 0.24 ,),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Row(
                          children: [
                            isDark ? SvgPicture.asset("assets/icons/backDark.svg") : SvgPicture.asset("assets/icons/backLight.svg"),
                            const SizedBox(width: 12),
                            Text("Back", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xff1F2933), fontSize: 16, fontWeight: FontWeight.w500),)
                          ],
                        ),
                      ),
                      SizedBox(height: height * 0.063,),
                      Text("Enter your code", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xff1F2933)),),
                      SizedBox(height: height * 0.02,),
                      Text("You'll receive a 4 digit code to verify", style: TextStyle(fontSize: 16, color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xff616E7C)),),
                      SizedBox(height: height * 0.04,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: input.map<Widget>((e) {
                        int index = input.indexWhere((ele) => e == ele);
                        return Container(
                          alignment: Alignment.center,
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isDark ? const Color(0xff2E2E2E) : const Color(0xffF5F7FA)
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 26),
                              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xffCBD2D9))),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? const Color(0xff19DFCB) : const Color(0xff2a5298)))
                            ),
                            controller: e["controller"],
                            focusNode: e["focusNode"],
                            autofocus: index == 0,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (str) {
                              if (str.length > 1) {
                                e["controller"].text  = str[str.length - 1];
                                e["controller"].selection = TextSelection.fromPosition(const TextPosition(offset: 1));
                              }
                              if (Utils.checkedTypeEmpty(str)) {
                                if (index < 3) {
                                  FocusScope.of(context).requestFocus(input[index + 1]["focusNode"]);
                                } else if (str.isNotEmpty && index == 3) {
                                  setState(() {
                                    code = _input1.text + _input2.text + _input3.text + _input4.text;
                                  });
                                  handleSubmitConfirm();
                                }
                              }
                            },
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                          )
                        );
                      }).toList(),
                      ),
                      SizedBox(height: height * 0.0267,),
                      SubmitButton(
                        isDisable: timeRequestOtp <= 3 ? false : true ,
                        onTap: timeRequestOtp <= 3 ? () {
                          invalidCredential = false;
                          handleSubmitConfirm();
                        } : null,
                        text: "Send", isLoading: loading,
                      ),
                      SizedBox(height: height * 0.04,),
                      invalidCredential ? Container(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: Column(
                          children: [
                            Text(message, style: TextStyle(fontWeight: FontWeight.w400, color: sentSucess != null && sentSucess == true ? const Color(0xff5ac45a) : const Color(0xffEB5757))),
                          ],
                        )
                      ) : const SizedBox(),
                      const SizedBox(height: 24,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "If you didn't receive a code /",
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Colors.white : const Color(0xff1F2933),
                            )
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          GestureDetector(
                            onTap: () async {
                              final url = "${Utils.apiUrl}users/create_otp";

                              await Dio().post(url, data: {
                                "email": widget.dataUser["email"],
                                "phone_number": widget.dataUser["phone_number"],
                                "user_id": widget.dataUser["id"] ?? widget.dataUser["user_id"]
                              });
                              setState(() {
                                message = '';
                                timeRequestOtp = 1;
                              });
                            },
                            child: Text(
                              'Resend',
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? const Color(0xff19DFCB) :  const Color(0xff2A5298),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: width * 0.2,),
                Container(
                  padding: EdgeInsets.only(top: height * 0.0445, bottom: height * 0.0445, right: 14),
                  child: const Image(image: AssetImage("assets/images/Group3.png"),)
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}