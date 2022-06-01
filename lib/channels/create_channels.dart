import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/http_exception.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';

class CreateChannel extends StatefulWidget {
  @override
  _CreateChannelState createState() => _CreateChannelState();
}

class _CreateChannelState extends State<CreateChannel> {
  var _channelName;
  var _radioValue;
  var _debounce;
  List resultSearch = [];
  List listUserChannel = [];
  FocusNode node = new FocusNode();


  @override
  void initState(){
    super.initState();
    Timer.run(()async {
      final auth = Provider.of<Auth>(context, listen: false);
      final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      List result   = await Provider.of<Workspaces>(context, listen: false).searchMember("", auth.token, currentWorkspace["id"]);
      result.removeWhere((element) => element["id"] == auth.userId);
      setState(() {
        resultSearch = result;
      }); 
    });
  }

  _submitCreateChannel(token, workspaceId) {
    final auth = Provider.of<Auth>(context, listen: false);
    final providerMessage = Provider.of<Messages>(context, listen: false);
    try {
      var userIds  = listUserChannel.map((e) => e["id"]).toList();
      Provider.of<Channels>(context, listen: false).createChannel(token, workspaceId, _channelName, _radioValue == 0 ? false : true, userIds, auth, providerMessage);
      Navigator.pushNamed(context, 'main_screen_macOS');
    } on HttpException catch (error) {
      print("this is http exception $error");
    } catch (e) {
      print(e);
    }
  }


  handleUserToChannel(user, selected) {
    setState(() {
      var index  = listUserChannel.indexWhere((element) => element["id"] == user["id"]);
      if (index != -1){
        listUserChannel.removeAt(index);
      }
      else listUserChannel.add(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final token = auth.token;
    final currentWorkspace = Provider.of<Workspaces>(context).currentWorkspace;
    final height = MediaQuery.of(context).size.height *.85;
    final width = MediaQuery.of(context).size.width;
    final isDark = auth.theme == ThemeType.DARK;
    final deviceWidth = MediaQuery.of(context).size.width;
    final theme = auth.theme;

    return GestureDetector(
      onTap: () { FocusScope.of(context).unfocus(); },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF353a3e) : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10.0),
            topRight: Radius.circular(10.0)
          )
        ),
        height: height,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
              color: isDark ? Color(0xFF353a3e) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0)
                )
              ),
              width: deviceWidth,
              padding: EdgeInsets.all(25),
              child: Center(child: Text(S.of(context).createChannel, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: isDark ? Colors.grey[400] : Colors.grey[700])))
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              height: node.hasFocus ? 0 : 260,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 30, left: 15, bottom: 5),
                    child: Row(children: [Text("CHANNEL NAME", style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[700]))])
                  ),
                  Container(
                    child: CupertinoTextField(
                      decoration: BoxDecoration(
                        color: isDark ? Color(0XFF2e3235) : Colors.white,
                      ),
                      autofocus: true,
                      placeholder: "Channel's name ...",
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                      padding: EdgeInsets.all(15),
                      clearButtonMode: OverlayVisibilityMode.always,
                      onChanged: (value){
                        _channelName = value;
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 30, left: 15, bottom: 5),
                    child: Row(children: [Text("CHANNEL TYPE", style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[700]))])
                  ),
                  Container(
                    child: Column(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Color(0XFF2e3235) : Colors.white,
                            border: Border(bottom: BorderSide(color: theme == ThemeType.DARK ? Color(0xFF6a6e74) : Color(0xff9FB3C8), width: 1)),
                          ),
                          child: Row(children: <Widget>[
                            Radio(
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              value: 0,
                              groupValue: _radioValue != null ? _radioValue : 0,
                              onChanged: (value) {
                                this.setState(() {
                                  _radioValue = value;
                                });
                              },
                            ),
                            Container(margin: EdgeInsets.symmetric(horizontal: 5), child: Icon(CupertinoIcons.number, size: 16)),
                            Text("Regular Channel", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 16))
                          ]),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Color(0XFF2e3235) : Colors.white,
                          ),
                          child: Row(children: <Widget>[
                            Radio(
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              value: 1,
                              groupValue: _radioValue,
                              onChanged: (value) {
                                this.setState(() {
                                  _radioValue = value;
                                });
                              },
                            ),
                            Container(margin: EdgeInsets.symmetric(horizontal: 5), child: Icon(Icons.lock, size: 17)),
                            Text("Private Channel", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 16))
                          ]),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            
            ),
            Container(
              padding: EdgeInsets.only(top: 30, left: 15, bottom: 5),
              child: Row(children: [
                Text("MEMBERS" + ((listUserChannel.length > 0 )? "  (${listUserChannel.length })": "") , style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[700])),
              ])
            ),
            CupertinoTextField(
              decoration: BoxDecoration(color: isDark ? Color(0XFF2e3235) : Colors.white,),
              placeholder: "Search members ...",
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
              padding: EdgeInsets.all(15),
              clearButtonMode: OverlayVisibilityMode.always,
              focusNode: node,
              onChanged: (value){
                if (_debounce?.isActive ?? false) _debounce.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), ()async {
                  List result = await Provider.of<Workspaces>(context, listen: false).searchMember(value, token, currentWorkspace["id"]);
                  result.removeWhere((element) => element["id"] == auth.userId);
                  setState(() {
                    resultSearch = result;
                  });
                });
              },
            ),

            Expanded(
              child: ListView.builder(
                // scrollDirection: Axis.horizontal,
                itemCount: resultSearch.length,
                itemBuilder: (context, index) {
                  var selected = listUserChannel.where((e) {return e["id"] == resultSearch[index]["id"]; }).length > 0;
                  return Container(
                    margin: EdgeInsets.fromLTRB(18, 8, 18, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: [
                            CachedImage(
                              resultSearch[index]["avatar_url"],
                              radius: 35,
                              isRound: true,
                              name: resultSearch[index]["full_name"]
                            ),
                            Container(
                              width: 10,
                            ),
                            Container(
                              child: Text(resultSearch[index]["full_name"],
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            // print(resultSearch[index]["id"]);
                            handleUserToChannel(resultSearch[index], selected);
                          },
                          child: Container(
                            padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              color: selected ? Colors.redAccent : theme == ThemeType.DARK ? Color(0xFF1890FF) : Utils.getPrimaryColor(),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  selected ? "Remove" : "Add",
                                  style: TextStyle(color: Color(0xFFFFFFFF)),
                                ),
                              ],
                            )
                          ),
                        )
                      ]
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              width: width,
              child: TextButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.lightBlue),
                ),
                onPressed: () {
                  _submitCreateChannel(token, currentWorkspace["id"]);
                },
                child: Text(S.of(context).createChannel, style: TextStyle(color: Colors.white))
              )
            )
          ],
        ),
      ),
    );
  }
}
