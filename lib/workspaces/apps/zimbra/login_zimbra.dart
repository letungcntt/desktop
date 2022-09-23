import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:workcake/channels/create_channel_desktop.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/workspaces/apps/zimbra/service.dart';

import 'config.dart';

class LoginZimbra extends StatefulWidget {
  final int workspaceId;
  final Function onLoginSuccess;
  const LoginZimbra({Key? key, required this.workspaceId, required this.onLoginSuccess}) : super(key: key);

  @override
  State<LoginZimbra> createState() => _LoginZimbraState();
}

class _LoginZimbraState extends State<LoginZimbra> {

  String email = "";
  String password = "";
  String domain = "";
  String error = "";
  List<AccountZimbra> accountLogined = <AccountZimbra>[];

  final focusPass = FocusNode();
  final focusDomain = FocusNode();

  @override
  void initState() {
    super.initState();
    Timer.run(() async {
      try {
        var box = Hive.lazyBox('pairKey');
        var data = await box.get("zimbra_${widget.workspaceId}");
        if (this.mounted) setState((){
          accountLogined = (data!["accounts"].map<AccountZimbra?>((e) => AccountZimbra.initAccountZimbra(e)).toList() as List<AccountZimbra?>).whereType<AccountZimbra>().toList();
        });
      } catch (e) {
        print("...............: $e");
      }
    });
  }

  Future login() async {
    if (error != "") setState(((){
      error = "";
    }));
    AccountZimbra? acc = await ServiceZimbra.newLogin(email, password, widget.workspaceId, domain == "" ? "https://mail.pancake.vn" : domain, hasSave:  true);
    if (acc != null) {
      widget.onLoginSuccess();
    }
    else setState((){
      error =  "Opps!!!. Please check your info again";
    });
  }

  @override
  Widget build(BuildContext context) {
    var isDark = Provider.of<Auth>(context, listen: false).theme ==ThemeType.DARK;
    return Center(
      child: Wrap(
        children: [
          Container(
            padding: EdgeInsets.all(48),
            width: 460,
            // height: 500,
            color: isDark ? Color(0xFF2e2e2e) : Color(0xFFffffff),
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    child: Text("LOG IN", style: TextStyle(fontSize: 30)),
                  ),
                  Container(height: 48,),
                  accountLogined.length > 0 ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ScrollConfiguration(
                        behavior: MyCustomScrollBehavior(),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,

                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: accountLogined.map((e) => Container(
                              margin: EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  ServiceZimbra.switchAccount(e, widget.workspaceId);
                                },
                                child: HoverItem(
                                  colorHover: isDark ? Color.fromARGB(255, 75, 75, 75) : Color(0xFFffffff),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? Color.fromARGB(255, 75, 75, 75) : Color(0xffffffff),
                                      borderRadius: BorderRadius.all(Radius.circular(4)),
                                      boxShadow: isDark ? [] : [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.2),
                                          spreadRadius: 3,
                                          blurRadius: 5,
                                          offset: Offset(0, 2), // changes position of shadow
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.all(8),
                                    child: Row(
                                      children: [
                                        CachedAvatar("", name: e.email, height: 40, width: 40,),
                                        Container(width: 8,),
                                        Container(width: 100, child: Text(e.email, maxLines: 1, style: TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis)))
                                      ],
                                    ),
                                  ))
                              ),
                            )).toList(),
                          ),
                        ),
                      ),
                      Container(height: 24,),
                    ],
                  ) : Container(),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: Text("Email address *", style: TextStyle(color: isDark ? Color(0xFFa6a6a6): Color(0xFF828282) , fontSize: 12),),
                      ),
                      Container(height: 12,),
                      Container(
                        color: isDark ?Color(0xFF4c4c4c) : Color(0xFFfafafa),
                        height: 36,
                        child: TextFormField(
                          onFieldSubmitted: (v){
                            FocusScope.of(context).requestFocus(focusPass);
                          },
                          autofocus: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFdbdbdb))),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Color(0xfffaad14) : Color(0xFF1890ff))),
                            hintText: "Email"),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ?Colors.white : Color(0xFF5e5e5e),
                            fontWeight: FontWeight.w500
                          ),
                          onChanged: (String t) => email = t,
                        ),
                      ),
                    ],
                  ),
                  Container(height: 24,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: Text("Password", style: TextStyle(color: isDark ? Color(0xFFa6a6a6): Color(0xFF828282) , fontSize: 12),),
                      ),
                      Container(height: 12,),
                      Container(
                        color: isDark ?Color(0xFF4c4c4c) : Color(0xFFfafafa),
                        height: 36,
                        child: TextFormField(
                          // autofocus: true,
                          focusNode: focusPass,
                          onFieldSubmitted: (v){
                            FocusScope.of(context).requestFocus(focusDomain);
                          },
                          obscureText: true,
                          decoration: InputDecoration(

                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFdbdbdb))),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Color(0xfffaad14) : Color(0xFF1890ff))),
                            hintText: "Password"),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ?Colors.white : Color(0xFF5e5e5e),
                            fontWeight: FontWeight.w500
                          ),
                          onChanged: (String t) => password = t,
                        ),
                      ),
                    ],
                  ),
                                Container(height: 24,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: Text("Domain", style: TextStyle(color: isDark ? Color(0xFFa6a6a6): Color(0xFF828282) , fontSize: 12),),
                      ),
                      Container(height: 12,),
                      Container(
                        color: isDark ?Color(0xFF4c4c4c) : Color(0xFFfafafa),
                        height: 36,
                        child: TextFormField(
                          // autofocus: true,
                          focusNode: focusDomain,
                          onFieldSubmitted:  (v) => login(),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFdbdbdb))),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Color(0xfffaad14) : Color(0xFF1890ff))),
                            hintText: "https://mail.pancake.vn"),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ?Colors.white : Color(0xFF5e5e5e),
                            fontWeight: FontWeight.w500
                          ),
                          onChanged: (String t) => domain = t,
                        ),
                      ),
                    ],
                  ),

                  Container(height: 48,),
                  GestureDetector(
                    onTap: () => login(),
                    child: HoverItem(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF1890ff),
                          borderRadius: BorderRadius.all(Radius.circular(4))
                        ),

                        width: 460,
                        height: 40,
                        child: Center(child: Text("Login", style: TextStyle(color:Color(0xFFf5f5f5)),))
                      ),
                    ),
                  ),
                  error != "" ? Container(
                    height: 32,
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      color: Color(0xFF4c4c4c),
                    ),
                    margin: EdgeInsets.only(top: 33),
                    child: Expanded(child: Text(error, style: const TextStyle(color: Color(0xFFFF7875)))),
                  ) : Container()
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
