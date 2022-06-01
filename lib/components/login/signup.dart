// import 'dart:convert';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/components/login/input_field.dart';
import 'package:workcake/components/login/logo.dart';
import 'package:workcake/components/login/submit_button.dart';
import 'package:workcake/components/login/verify_otp.dart';
import 'package:workcake/login_macOS.dart';
import 'package:workcake/models/models.dart';

class SignUpMacOS extends StatefulWidget {
  final title;

  SignUpMacOS({Key? key, this.title}) : super(key: key);

  @override
  _SignUpMacOSState createState() => _SignUpMacOSState();
}

class _SignUpMacOSState extends State<SignUpMacOS> {
  final _formKey = GlobalKey<FormState>();
  // String _status = '';
  FocusNode _fistNameNode = FocusNode();
  FocusNode _lastNameNode = FocusNode();
  FocusNode _emailNode = FocusNode();
  FocusNode _passwordNode = FocusNode();
  FocusNode _confirmPasswordNode = FocusNode();

  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  bool loading = false;
  String errorMessage = "";                                                                                            

  @override
  void initState() {
    super.initState();
    _fistNameNode = handleFocusNode(context, _lastNameNode);
    _lastNameNode = handleFocusNode(context, _emailNode);
    _emailNode = handleFocusNode(context,_passwordNode);
    _passwordNode = handleFocusNode(context,_confirmPasswordNode);
    _confirmPasswordNode = handleFocusNode(context,_fistNameNode, isLastNode: true);
  }

  handleFocusNode(context, nextNode,{isLastNode = false}) {
    return FocusNode(onKey: (node, RawKeyEvent keyEvent) {

      if(keyEvent is RawKeyDownEvent) {
        if (keyEvent.isKeyPressed(LogicalKeyboardKey.enter)) {
          signUp();
        } else if (keyEvent.isKeyPressed(LogicalKeyboardKey.tab)) {
          if(!isLastNode) {
            FocusScope.of(context).nextFocus();
          } else {
            FocusScope.of(context).requestFocus(nextNode);
          }
          return KeyEventResult.handled;
        }
      }

      return KeyEventResult.ignored;
    });
  }

  @override
  void dispose(){
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _fistNameNode.dispose();
    _lastNameNode.dispose();
    _emailNode.dispose();
    _passwordNode.dispose();
    _confirmPasswordNode.dispose();
    super.dispose();
  }
  
  void signUp() async {
    try {
      if(_firstNameController.text.trim() == '' || _lastNameController.text.trim() == '' || _emailController.text.trim() == '' || _passwordController.text.trim() == '' || _confirmPasswordController.text.trim() == '') {
        setState(() {
          errorMessage = "All fields must be entered";
          // invalidCredential = true;
          // FocusScope.of(context).unfocus();
        });
        Provider.of<Auth>(context, listen: false).showAlertDialog(context, errorMessage);
      }
      else if(_passwordController.text != _confirmPasswordController.text){
        setState(() {
          errorMessage = "Password didn't match ";
          
          // invalidCredential = true;
          // FocusScope.of(context).unfocus();
        });
        Provider.of<Auth>(context, listen: false).showAlertDialog(context, errorMessage);
      } else if(_passwordController.text.length < 6 || _confirmPasswordController.text.length < 6){
        setState(() {
          errorMessage = "Password must contain at least 6 characters ";
          // invalidCredential = true;
          // FocusScope.of(context).unfocus();
        });
      } else {
        setState(() => loading = true);

        final response = await Provider.of<Auth>(context, listen: false).signUp(_firstNameController.text, _lastNameController.text, _emailController.text, _passwordController.text, _confirmPasswordController.text, context);
        if(response["success"]) {

          setState(() => loading = false);

          Navigator.push(context, MaterialPageRoute(builder: (context) => VerifyOtp(dataUser: {...response["data"], "password": _passwordController.text},)));
        } else {
          setState(() {
            errorMessage = response["message"];
            loading = false;
          });
          Provider.of<Auth>(context, listen: false).showAlertDialog(context, errorMessage);
        }
      }
    } catch (e) {
      setState(() => loading = false );
    }

  }

  void saveToken(token) {
    Provider.of<Auth>(context, listen: false).loginPancakeId(token, context);
  }

  Widget _formSignUpUser() {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return Container(
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            SizedBox(
              width: width * 0.395,
              child: Row(
                children: [
                  Expanded(
                    child: InputFieldMacOs(
                      controller: _firstNameController,
                      focusNode: _fistNameNode,
                      hintText: "First name",
                      prefix: Container(
                        child: isDark ? SvgPicture.asset("assets/icons/userDark.svg") : SvgPicture.asset("assets/icons/userLight.svg")
                      )
                    ),
                  ),
                  const SizedBox(width: 12,),
                  Expanded(
                    child: InputFieldMacOs(
                      controller: _lastNameController,
                      focusNode: _lastNameNode,
                      hintText: "Last name",
                      prefix: Container(
                        child: isDark ? SvgPicture.asset("assets/icons/userDark.svg") : SvgPicture.asset("assets/icons/userLight.svg")
                      )
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: height * 0.005),
            InputFieldMacOs(
              controller: _emailController,
              focusNode: _emailNode,
              hintText: "Email or phone number",
              prefix: Container(
                child: isDark ? SvgPicture.asset("assets/icons/@Dark.svg") : SvgPicture.asset("assets/icons/@Light.svg")
              )
            ),
            SizedBox(height: height * 0.005),
            InputPassword(
              controller: _passwordController,
              focusNode: _passwordNode,
              hintText: "Password",
              prefix: Container(
                child: isDark ? SvgPicture.asset("assets/icons/LockDark.svg") : SvgPicture.asset("assets/icons/LockLight.svg")
              )
            ),
            SizedBox(height: height * 0.005,),
            InputPassword(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordNode,
              hintText: "Confirm password",
              prefix: Container(
                child: isDark ? SvgPicture.asset("assets/icons/LockDark.svg") : SvgPicture.asset("assets/icons/LockLight.svg")
              )
            ),
            SizedBox(height: height * 0.01),
            const AcceptPolicy(),
            SizedBox(height: height * 0.014),
            SubmitButton(
              onTap: signUp,
              text: "Sign Up",
              isLoading: loading,
            )
          ],
        ),
      )
    );
  }

  Widget _signInButton() {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return InkWell(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginMacOS()
        )),
      child: Container(
        // width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.only(top: 12, bottom: 12, left: 4, right: 12 ),
        alignment: Alignment.center,
        child: Text(
          'Sign In',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xffFAAD14) :const Color(0xff2A5298),
          ),
        ),
      ),
    );
  }

  Widget _alreadyAccount() {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return InkWell(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        child: Text(
          'Already have an account / ',
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
              SingleChildScrollView(
                child: SizedBox(
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(height: height * 0.126),
                              const Logo(),
                              constraints.maxHeight >= 600 ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: height * 0.064,),
                                  Text("Create Account", style: TextStyle(color: isDark ? Colors.white :  const Color(0xff1F2933), fontSize: 30, fontWeight: FontWeight.w500),),
                                  SizedBox(height: height * 0.009,),
                                  Text("Enter your information below", style: TextStyle(color: isDark ? Colors.white : const Color(0xff616E7C), fontSize: 16),)
                                ],
                              ) : const SizedBox(),
                              SizedBox(height: height * 0.0356,),
                              _formSignUpUser(),
                              // SizedBox(height: 600),
                            ],
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  _alreadyAccount(),
                                  _signInButton(),
                                ],
                              ),
                              SizedBox(height: height * 0.08,)
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
                )
              ),
            ],
          );
        }
      )
    );
  }
}

class WindowButtons extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 30,child: MinimizeWindowButton( colors: WindowButtonColors(iconNormal: Colors.green[300], mouseOver: Colors.grey[400]))),
        SizedBox(width: 30,child: MaximizeWindowButton(colors: WindowButtonColors(iconNormal: Colors.green[300], mouseOver: Colors.grey[400]))),
        SizedBox(width: 30,child: CloseWindowButton(colors: WindowButtonColors(iconNormal: Colors.green[300], mouseOver: Colors.grey[400])))
      ],
    );
  }
}

class AcceptPolicy extends StatefulWidget {
  const AcceptPolicy({
    Key? key,
  }) : super(key: key);

  @override
  _AcceptPolicyState createState() => _AcceptPolicyState();
}

// ignore: camel_case_types
class _AcceptPolicyState extends State<AcceptPolicy> {
  bool checked = true;
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Row(
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
        Text("I agree to the Terms of service and Privacy policy", style: TextStyle(color: isDark ? Colors.white : const Color(0xff1F2933), fontSize:  13),)
      ],
    );
  }
}
