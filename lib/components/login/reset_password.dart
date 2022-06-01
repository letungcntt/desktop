import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/components/login/input_field.dart';
import 'package:workcake/components/login/submit_button.dart';
import 'package:workcake/models/models.dart';

import '../../login_macOS.dart';

class ResetPassword extends StatefulWidget {
  final dataUser;
  const ResetPassword({Key? key, required this.dataUser}) : super(key: key);

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  bool loading = false;
  String message = "";
  bool invalidCredential = false;

  void resetPassword(dataUser) async {
    try {
      if(_passwordController.text != _passwordConfirmController.text) {
        setState(() {
          message = "Confirm password didn't match";
          invalidCredential = true;
        });
        return;
      }
      setState(() {
        loading = true;
      });
      var res = await Provider.of<Auth>(context, listen: false).resetPassword(dataUser);

      if(res["success"]) {
        await Provider.of<Auth>(context, listen: false).loginUserPassword(dataUser["phone_number"], _passwordController.text, context);
        Navigator.pushNamed(context, 'main_screen_macOS');
      } else {
        setState(() {
          loading = false;
          message = res["message"];
          invalidCredential = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }
  setInvalidCredential(value) {
    setState(() {
      invalidCredential = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
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
                      Text("Create new password", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xff1F2933)),),
                      SizedBox(height: height * 0.02,),
                      Text("A strong password will help you better protect your account.", style: TextStyle(fontSize: 16, color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xff616E7C)),),
                      SizedBox(height: height * 0.04,),
                      InputPassword(
                        controller: _passwordController,
                        // focusNode: focusNode,
                        invalidCredential: invalidCredential,
                        setInvalidCredential: setInvalidCredential,
                        hintText: "New password",
                        prefix: Container(
                          child: isDark ? SvgPicture.asset("assets/icons/LockDark.svg") : SvgPicture.asset("assets/icons/LockLight.svg")
                        )
                      ),
                      SizedBox(height: height * 0.015,),
                      InputPassword(
                        controller: _passwordConfirmController,
                        // focusNode: focusNode,
                        invalidCredential: invalidCredential,
                        setInvalidCredential: setInvalidCredential,
                        hintText: "Confirm new password",
                        prefix: Container(
                          child: isDark ? SvgPicture.asset("assets/icons/LockDark.svg") : SvgPicture.asset("assets/icons/LockLight.svg")
                        )
                      ),
                      SizedBox(height: height * 0.03,),
                      SubmitButton(
                        onTap: () {
                          resetPassword({...widget.dataUser, "new_password": _passwordController.text });
                        }, 
                        text: "Submit", isLoading: false,
                      ),
                      SizedBox(height: height * 0.03,),
                      Container(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: invalidCredential ? Text(message, style: const TextStyle(fontWeight: FontWeight.w400, color:  Color(0xffEB5757))) : const SizedBox()
                      )
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