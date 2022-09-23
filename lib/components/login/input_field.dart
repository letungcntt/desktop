import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:workcake/providers/providers.dart';

class InputPassword extends StatefulWidget {
  const InputPassword({Key? key, required this.controller, this.hintText, required this.prefix, this.invalidCredential = false, this.setInvalidCredential, this.isLogin = false, this.focusNode}) : super(key: key);
  final TextEditingController controller;
  final String? hintText;
  final Widget? prefix;
  final bool invalidCredential;
  final bool isLogin;
  final Function(bool)? setInvalidCredential;
  final focusNode;

  @override
  _InputPasswordState createState() => _InputPasswordState();
}

class _InputPasswordState extends State<InputPassword> {

  bool obscureText = true;
  FocusNode _focus = new FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose(){
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChange(){
    if(widget.invalidCredential && _focus.hasFocus) {
      widget.setInvalidCredential!(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Container(
      height: 42,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        focusNode: widget.focusNode,
        keyboardType: TextInputType.visiblePassword,
        controller: widget.controller,
        obscureText: obscureText,
        style: TextStyle(color: isDark ? Colors.white : Color(0xff1F2933)),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white : Color(0xff323F48)),
          prefixIcon: widget.prefix,
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                obscureText = !obscureText;
              });
            },
            child: obscureText ? isDark ? SvgPicture.asset("assets/icons/EyeDark.svg") : SvgPicture.asset("assets/icons/EyeLight.svg") : isDark ? SvgPicture.asset("assets/icons/EyeInvisibleDark.svg") : SvgPicture.asset("assets/icons/EyeInvisibleLight.svg"),
          ),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.invalidCredential && widget.isLogin ? Color(0xffEB5757) : isDark ? Colors.white : Color(0xff616E7C))),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.invalidCredential && widget.isLogin ? Color(0xffEB5757) :isDark ? Colors.white : Color(0xff2A5298))),
          contentPadding: EdgeInsets.only( top: 12.0, bottom: 12),
        ),
      ),
    );
  }
}


class InputFieldMacOs extends StatefulWidget {
  InputFieldMacOs({Key? key, required this.controller, required this.hintText, required this.prefix, this.invalidCredential = false, this.autoFocus = false, this.setInvalidCredential, this.keyboardType = TextInputType.text, this.isLogin = false, this.focusNode}) : super(key: key);
  final TextEditingController controller;
  final String? hintText;
  final Widget? prefix;
  final bool invalidCredential;
  final bool isLogin;
  final bool autoFocus;
  final keyboardType;
  final Function(bool)? setInvalidCredential;
  final focusNode;

  @override
  _InputFieldMacOsState createState() => _InputFieldMacOsState();
}

class _InputFieldMacOsState extends State<InputFieldMacOs> {
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Container(
      height: 42,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        keyboardType: widget.keyboardType,
        focusNode: widget.focusNode,
        autofocus: widget.autoFocus,
        controller: widget.controller,
        style: TextStyle(color: isDark ? Colors.white : Color(0xff1F2933)),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white : Color(0xff323F48)),
          prefixIcon: widget.prefix,
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.invalidCredential && widget.isLogin ? Color(0xffEB5757) : isDark ? Colors.white : Color(0xff616E7C))),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.invalidCredential && widget.isLogin ? Color(0xffEB5757) : isDark ? Colors.white : Color(0xff616E7C))),
          contentPadding: EdgeInsets.only( top: 12.0, bottom: 12, right: 6),
          // fillColor: Color(0xfff3f3f4),
          // filled: true
        ),
      ),
    );
  }
}

class InputField extends StatefulWidget {
  InputField({Key? key, required this.controller, required this.hintText, required this.prefix, this.invalidCredential = false, this.autoFocus = false, this.setInvalidCredential, this.keyboardType = TextInputType.text, this.isLogin = false, this.focusNode}) : super(key: key);
  final TextEditingController controller;
  final String? hintText;
  final Widget? prefix;
  final bool invalidCredential;
  final bool isLogin;
  final bool autoFocus;
  final keyboardType;
  final Function(bool)? setInvalidCredential;
  final focusNode;

  @override
  _InputFieldState createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  FocusNode _focus = new FocusNode();
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose(){
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChange(){
    if(widget.invalidCredential && _focus.hasFocus) {
      widget.setInvalidCredential!(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return Container(
      height: 42,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        keyboardType: widget.keyboardType,
        focusNode: _focus,
        autofocus: widget.autoFocus,
        controller: widget.controller,
        style: TextStyle(color: isDark ? Colors.white : Color(0xff1F2933)),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white : Color(0xff323F48)),
          prefixIcon: widget.prefix,
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.invalidCredential && widget.isLogin ? Color(0xffEB5757) : isDark ? Colors.white : Color(0xff616E7C))),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.invalidCredential && widget.isLogin ? Color(0xffEB5757) : isDark ? Colors.white : Color(0xff616E7C))),
          contentPadding: EdgeInsets.only( top: 12.0, bottom: 12, right: 6),
          // fillColor: Color(0xfff3f3f4),
          // filled: true
        ),
      ),
    );
  }
}

