import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/components/login/input_field.dart';
import 'package:workcake/components/login/reset_password.dart';
import 'package:workcake/components/login/submit_button.dart';
import 'package:workcake/login_macOS.dart';
import 'package:workcake/providers/providers.dart';

class ForgotPassword extends StatefulWidget {
  ForgotPassword({Key? key}) : super(key: key);

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _inputController = TextEditingController(text: "");
  FocusNode? focusNode;
  String message = '';
  bool invalidCredential = false;
  bool? sentSucess;
  bool loading = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  resetPassword() async {
    try {
      if(_inputController.text.isEmpty) {
        setState(() {
          invalidCredential = true;
          sentSucess = false;
          message = "input can't empty";
        });
        return;
      }
      setState(() {
        loading = true;
      });

      String type = _inputController.text.contains("@") ? "email" : "phone_number";

      var res = await Provider.of<Auth>(context, listen: false).forgotPassword(_inputController.text, type);
      if(type == "email" || !res["success"]) {
        setState(() {
          loading = false;
          invalidCredential = true;
          message = res["message"];
          sentSucess = res["success"];
        });
      } else {
        setState(() {
          loading = false;
        });

        Navigator.push(context, MaterialPageRoute(builder: (context) => ResetPassword(dataUser: res["data"])));
      }
    } catch (e) {
      print(e);
    }
  }

  setInvalidCredential(value) {
    setState(() {
      invalidCredential = value;
    });
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
                            Text("Back", style: TextStyle(color: isDark ? Colors.white.withOpacity(0.9) : Color(0xff1F2933), fontSize: 16, fontWeight: FontWeight.w500),)
                          ],
                        ),
                      ),
                      SizedBox(height: height * 0.063,),
                      Text("Reset password", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withOpacity(0.9) : Color(0xff1F2933)),),
                      SizedBox(height: height * 0.02,),
                      Text("Enter the email associated with your account and we will send a verification code to your registered email.", style: TextStyle(fontSize: 16, color: isDark ? Colors.white.withOpacity(0.9) : Color(0xff616E7C)),),
                      SizedBox(height: height * 0.04,),
                      InputField(
                        controller: _inputController,
                        focusNode: focusNode,
                        invalidCredential: invalidCredential,
                        setInvalidCredential: setInvalidCredential,
                        hintText: "Your email or phone number",
                        prefix: Container(
                          child: isDark ? SvgPicture.asset("assets/icons/@Dark.svg") : SvgPicture.asset("assets/icons/@Light.svg")
                        )
                      ),
                      SizedBox(height: height * 0.0267,),
                      SubmitButton(
                        onTap: () {
                          invalidCredential = false;
                          resetPassword();
                        },
                        text: "Send", isLoading: loading,
                      ),
                      SizedBox(height: height * 0.04,),
                      invalidCredential ? Container(
                        padding: EdgeInsets.only(top: 4, bottom: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: Column(
                          children: [
                            Text(message, style: TextStyle(fontWeight: FontWeight.w400, color: sentSucess != null && sentSucess == true ? Color(0xff5ac45a) : Color(0xffEB5757))),
                          ],
                        )
                      ) : const SizedBox()
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