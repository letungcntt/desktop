import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/components/login/forgot_password.dart';
import 'package:workcake/components/login/input_field.dart';
import 'package:workcake/components/login/login_qr_code_buutton.dart';
import 'package:workcake/components/login/logo.dart';
import 'package:workcake/components/login/signup.dart';
import 'package:workcake/components/login/submit_button.dart';
import 'package:workcake/data_channel_webrtc/device_socket.dart';
import 'package:workcake/providers/providers.dart';
import 'common/utils.dart';

class LoginMacOS extends StatefulWidget {
  final title;

  LoginMacOS({Key? key, this.title}) : super(key: key);

  @override
  _LoginMacOSState createState() => _LoginMacOSState();
}

class _LoginMacOSState extends State<LoginMacOS> {
  final _formKey = GlobalKey<FormState>();
  // String _status = '';
  FocusNode? focusNode1;
  FocusNode? focusNode2;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool loginProcess = false;
  String loginType = 'password';

  @override
  void initState() {
    super.initState();
    Utils.loginContext = context;
    focusNode1 = FocusNode(onKey: (node, RawKeyEvent keyEvent) {
      if(keyEvent is RawKeyDownEvent) {
        if (keyEvent.isKeyPressed(LogicalKeyboardKey.enter)) {
          loginUser();
          return KeyEventResult.handled;
        } else if (keyEvent.isKeyPressed(LogicalKeyboardKey.tab)) {
          FocusScope.of(context).requestFocus(focusNode2);
          return KeyEventResult.handled;
        }
      }

      return KeyEventResult.ignored;
    });

    focusNode2 = FocusNode(onKey: (node, RawKeyEvent keyEvent) {
      if (keyEvent is RawKeyDownEvent) {
        if (keyEvent.isKeyPressed(LogicalKeyboardKey.enter)) {
          loginUser();
          return KeyEventResult.handled;
        } else if (keyEvent.isKeyPressed(LogicalKeyboardKey.tab)) {
          FocusScope.of(context).requestFocus(focusNode1);
          return KeyEventResult.handled;
        }
      }

      return KeyEventResult.ignored;
    });
  }

  @override
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
    focusNode1!.dispose();
    focusNode2!.dispose();
    super.dispose();
  }

  void loginUser() async {
    try {
      setState(() {
        loginProcess = true;
      });
      final form = _formKey.currentState;
      form!.save();

      if (form.validate()) {
        await Provider.of<Auth>(context, listen: false).loginUserPassword(_emailController.text, _passwordController.text, context);
      }
      setState(() {
        loginProcess = false;
      });
    } catch (e) {
      setState(() {
        loginProcess = false;
      });
    }

  }

  void saveToken(token) {
    Provider.of<Auth>(context, listen: false).loginPancakeId(token, context);
  }

  Widget formLoginUser() {
    double height = MediaQuery.of(context).size.height;
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return Container(
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            InputFieldMacOs(
              controller: _emailController,
              autoFocus: true,
              focusNode: focusNode1,
              hintText: "Email or Phone number",
              prefix: Container(
                child: isDark ? SvgPicture.asset("assets/icons/@Dark.svg") : SvgPicture.asset("assets/icons/@Light.svg")
              )
            ),
            SizedBox(height: height * 0.005),
            InputPassword(
              controller: _passwordController,
              focusNode: focusNode2,
              hintText: "Your password",
              prefix: Container(
                child: isDark ? SvgPicture.asset("assets/icons/LockDark.svg") : SvgPicture.asset("assets/icons/LockLight.svg")
              )
            ),
            SizedBox(height: height * 0.01,),
            const RememberMe(),
          ],
        ),
      )
    );
  }

  Widget signUpButton() {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => SignUpMacOS()));
      },
      child: Container(
        // width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.only(top: 12, bottom: 12, left: 4, right: 12),
        alignment: Alignment.center,
        child: Text(
          'Create an Account',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xffFAAD14) :const Color(0xff2A5298),
          ),
        ),
      ),
    );
  }

  Widget _noAccount() {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return InkWell(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        child: Text(
          'Not registered yet / ',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white : const Color(0xff1F2933),
          )
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double height =  MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Scaffold(
      backgroundColor: isDark ? Palette.backgroundRightSiderDark : Palette.backgroundRightSiderLight ,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
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
              width: width,
              height:  Platform.isWindows ? height - 38 : height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: width * 0.41
                    ),
                    padding: EdgeInsets.only(left: width * 0.0695),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        loginType == "qr_code" ? LoginQrCode(
                          onBack: (){
                            setState((){
                              loginType = "password";
                          });
                        })
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(height: height * 0.1422),
                            Container(
                              child: const Logo(),
                            ),
                            SizedBox(height: height * 0.1,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Welcome!", style: TextStyle(color: isDark ? Colors.white :  const Color(0xff1F2933), fontSize: 30, fontWeight: FontWeight.w500),),
                                SizedBox(height: height * 0.022,),
                                Text("We're so excited to see you", style: TextStyle(color: isDark ? Colors.white : const Color(0xff616E7C), fontSize: 16),)
                              ],
                            ),
                            SizedBox(height: height * 0.0356,),
                            formLoginUser(),
                            SizedBox(height: height * 0.026),
                            constraints.maxHeight >= 650 ?
                              Column(
                                children: [
                                  SubmitButton(
                                    onTap: loginUser,
                                    text: "Sign In",
                                    isLoading: loginProcess,
                                  ),
                                  SizedBox(height: height * 0.015,),
                                  LoginQrCodeButton(onTap: (){
                                    DeviceSocket.instance.sendRequestQrCode();
                                    setState((){
                                      loginType = "qr_code";
                                    });
                                  }, text: "Login with QR Code")
                                ],
                              ) :
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 44,
                                      child: SubmitButton(
                                        onTap: loginUser,
                                        text: "Sign In",
                                        isLoading: loginProcess,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8,),
                                  Expanded(
                                    child: Container(
                                      height: 44,
                                      child: LoginQrCodeButton(onTap: (){
                                        DeviceSocket.instance.sendRequestQrCode();
                                        setState((){
                                          loginType = "qr_code";
                                        });
                                      }, text: "Login QR"),
                                    ),
                                  )
                                ],
                              )
                            // SizedBox(height: 600),
                          ],
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                _noAccount(),
                                signUpButton(),
                              ],
                            ),
                            SizedBox(height: height * 0.05,)
                          ],
                        )
                      ],
                    ),

                  ),
                  SizedBox(width: width * 0.2,),
                  Container(
                    padding: EdgeInsets.only(top: height * 0.0445, bottom: height * 0.0245, right: 14),
                    child: const Image(image: AssetImage("assets/images/Group3.png"),)
                  )
                ],
              ),
              ),
            ],
          );
        }
      )
    );
  }
}

class WindowButtons extends StatefulWidget{
  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 38, child: MinimizeWindowButton(colors: WindowButtonColors(iconNormal: Colors.white))),
        SizedBox(width: 38, child: appWindow.isMaximized ?
          RestoreWindowButton(colors: WindowButtonColors(iconNormal: Colors.white),
           onPressed: () => setState((){
             appWindow.maximizeOrRestore();
           }),
          )
          : MaximizeWindowButton(colors: WindowButtonColors(iconNormal: Colors.green[300], mouseOver: Colors.grey[400]),
            onPressed: () => setState(() {
              appWindow.maximizeOrRestore();
            }))
          ),
        SizedBox(width: 38, child: CloseWindowButton(colors: WindowButtonColors(iconNormal: Colors.white, mouseOver: Colors.red)))
      ],
    );
  }
}

class RememberMe extends StatefulWidget {
  const RememberMe({
    Key? key,
  }) : super(key: key);

  @override
  _RememberMeState createState() => _RememberMeState();
}

class _RememberMeState extends State<RememberMe> {
  bool checked = true;
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Transform.scale(
                scale: 0.9,
                child: Checkbox(
                  activeColor: isDark ? const Color(0xffFAAD14) : Colors.blue,
                  side: BorderSide(color: isDark ? Colors.white : const Color(0xff1F2933)),
                  splashRadius: 1.0,
                  value: checked,
                  onChanged: (value) {
                    setState(() {
                      checked = !checked;
                    });
                  }
                ),
              ),
            ),
            const SizedBox(width: 8.0,),
            Text("Remember me", style: TextStyle(color: isDark ? Colors.white : const Color(0xff1F2933), fontSize:  13),)
          ],
        ),
        InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPassword()));
          },
          child: Text("Forgot password?", style: TextStyle(fontSize: 13, color: isDark ? const Color(0xffFAAD14) : const Color(0xff2A5298)),),
        )
      ],
    );
  }
}


class LoginQrCode extends StatefulWidget {
  final Function onBack;
  const LoginQrCode({ Key? key, required this.onBack }) : super(key: key);

  @override
  State<LoginQrCode> createState() => _LoginQrCodeState();
}

class _LoginQrCodeState extends State<LoginQrCode> {

  @override
  void initState(){
    super.initState();
    loop();
  }

  Future<void> loop() async {
    await Future.delayed(Duration(seconds: 50));
    if (this.mounted) {
      DeviceSocket.instance.sendRequestQrCode();
      loop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark =  auth.theme == ThemeType.DARK;
    double height =  MediaQuery.of(context).size.height;
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: height * 0.13),
          InkWell(
            onTap:() => widget.onBack(),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4)
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.arrowLeft,
                    size: 16,
                    color: isDark ? const Color(0xFFEDEDED) : const Color(0xFF5E5E5E),
                  ),
                  Container(width: 12),
                  Text("Login with password",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                       color: isDark ? const Color(0xFFEDEDED) : const Color(0xFF5E5E5E),
                    ),
                  ),

                ],
              ),
            ),
          ),
          SizedBox(height: height * 0.13),
          Text("Login with QR Code",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 30,
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFFBDBDB)
            ),
          ),
          Container(height: 12,),
          Text("Scan QR Code on Panchat",
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFFBDBDB)
            ),
          ),
          SizedBox(height: height * 0.1),
          DeviceSocket.instance.renderQRCode(),
          SizedBox(height: height * 0.05),
          Row(
            children: const [
              Text("Note: ",
                style: TextStyle(
                  fontWeight: FontWeight.w700,

                )
              ),
              Text("Tap "),
              Icon(PhosphorIcons.qrCode, size:16),
              Text(" on Panchat app tp scan")
            ],
          ),
          Container(height: 12),
          Stack(
            children: [
              const Image(image: AssetImage("assets/images/scan_light.png")),
              Positioned(
                right: 61, top: 13,
                child: Container(
                  width: 30, height: 30,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    border: Border(
                      top: BorderSide(width: 1.0, color: Colors.red),
                      left: BorderSide(width: 1.0, color: Colors.red),
                      right: BorderSide(width: 1.0, color: Colors.red),
                      bottom: BorderSide(width: 1.0, color: Colors.red),
                    ),
                  )
                ),
              )
            ],
          )

          // AssetImage("assets/images/scan.svg")
          // SvgPicture.asset("assets/images/scan.svg")
        ],
      ),
    );
  }
}