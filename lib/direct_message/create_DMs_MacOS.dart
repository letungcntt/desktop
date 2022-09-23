import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:workcake/common/http_exception.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/providers/providers.dart';

class CreateDMsMacOS extends StatefulWidget {
  @override
  _CreateDMsMacOSState createState() => _CreateDMsMacOSState();
}

class _CreateDMsMacOSState extends State<CreateDMsMacOS> {
  var resultSearch = [];
  var seaching = false;
  var listUserDM = [];
  var creating = false;
  var nameFM = "";
  var listFirend = [];
  var _debounce;

  @override
  void initState(){
    super.initState();
    listFirend =  Provider.of<User>(context, listen: false).friendList;
    resultSearch =  listFirend;
  }

  search(value, token) async {
    if (!Utils.checkedTypeEmpty(value)) return setState(() {
      resultSearch = listFirend;
    });
    String url = "${Utils.apiUrl}users/search_user_in_workspace?token=$token&keyword=$value";
    setState(() {
      seaching = true;
    });

    try {
      var response = await Dio().get(url);
      var dataRes = response.data;
      if (dataRes["success"]) {
        setState(() {
          resultSearch = dataRes["users"];
          seaching = false;
        });
      } else {
        setState(() {
          seaching = false;
        });
        throw HttpException(dataRes["message"]);
      }
    } catch (e) {
      setState(() {
        seaching = false;
      });
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  handleUserToDM(user, seleted) {
    setState(() {
      if (seleted){
        listUserDM.removeWhere((item) => item["id"] == user["id"]);
      }
      else {
        listUserDM += [user];
      }
    });
  }

  createDirectMessage(String token) async {
    final userId = Provider.of<Auth>(context, listen: false).userId;
     var listUserId = listUserDM.map((e) {
      return {
        "user_id": e["id"],
        "full_name": e["full_name"],
        "avatar_url": e["avatar_url"]
      };
    }).toList();
    Map data  = {"users": listUserId, "name": nameFM, "isDesktop": true};

    setState(() {
      creating = true;
    });
    await Provider.of<DirectMessage>(context, listen: false).createDirectMessage(token, data, context, userId);
    if (this.mounted){
      Navigator.pop(context);
      setState(() {
        creating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final token = auth.token;
    final userId = Provider.of<Auth>(context, listen: false).userId;
    final theme = Provider.of<Auth>(context, listen: true).theme;
    final isDark = auth.theme == ThemeType.DARK;

    // double deviceHeight = MediaQuery.of(context).size.height;
    resultSearch.removeWhere((element){return element["id"] == userId;});

    return Container(
      child: GestureDetector(
        onTap: () { FocusScope.of(context).unfocus(); },
        child: Stack(
          children: [
            // AnimatedPositioned(
            //   duration: Duration(milliseconds: 0),
            //   top: 250,
            //   child: Container(
            //     width: MediaQuery.of(context).size.width,
            //     alignment: Alignment.center,
            //     height: seaching ? 100 : 0,
            //     child: Lottie.network("https://assets6.lottiefiles.com/datafiles/tvGrhGYaLS0VjreZ1oqQpeFYPn4xPO625FsUAsp8/simple loading/simple.json")
            //   ),
            // ),
            Container(
              child: Column(children: <Widget>[
                Container(
                  margin: EdgeInsets.only(bottom: 24, top: 8),
                  alignment: Alignment.center,
                  child: Text(
                    "New Direct Message",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 12),
                  alignment: Alignment.centerLeft,
                  child: Text("Name direct message:")
                ),
                Container(
                  height: 40,
                  margin: EdgeInsets.only(bottom: 16),
                  child: CupertinoTextField(
                    autofocus: true,
                    style: TextStyle(color: Colors.grey),
                    padding: EdgeInsets.only(left: 16),
                    clearButtonMode: OverlayVisibilityMode.always,
                    placeholder: "Enter name of DMs",
                    onChanged: (value) {
                      nameFM = value;
                    },
                  ),
                ),
                Container(
                  height: 40,
                  child: Row(
                    children: <Widget>[
                      Container(margin: EdgeInsets.only(bottom: 5), child: Text("To: ")),
                      Container(
                        width: 460,
                        child: Scrollbar(
                          child: ListView.builder(
                            padding: EdgeInsets.only(bottom: 8),
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: listUserDM.length,
                            itemBuilder: (context, index) {
                              return Container(
                                padding: EdgeInsets.fromLTRB(7, 0, 7, 0),
                                margin: EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[600] : Color(0xFFE0E0E0),
                                  borderRadius: BorderRadius.circular(10)
                                ),
                                child: Row(
                                  children: [
                                    Text(listUserDM[index]["full_name"] + " "),
                                    Container(
                                      width: 18,
                                      height: 18,
                                      child: TextButton(
                                        style: ButtonStyle(
                                          padding: MaterialStateProperty.all(EdgeInsets.all(0)),
                                          backgroundColor: MaterialStateProperty.all(isDark ? Colors.grey[700] : Colors.grey[500]),
                                          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
                                        ),
                                        onPressed: () {
                                          handleUserToDM(listUserDM[index], true);
                                        },
                                        child: Icon(Icons.close, size: 16, color: Colors.grey[300])
                                      ),
                                    )
                                  ],
                                ),
                              );
                            }
                          ),
                        ),
                      )
                    ],
                  )
                ),
                Container(
                  height: 40,
                  margin: EdgeInsets.only(bottom: 6),
                  child: CupertinoTextField(
                    autofocus: true,
                    prefix: Container(
                      child: Icon(Icons.search, color: Colors.grey),
                      padding: EdgeInsets.only(left: 10)
                    ),
                    style: TextStyle(color: Colors.grey),
                    padding: EdgeInsets.only(left: 10),
                    clearButtonMode: OverlayVisibilityMode.always,
                    placeholder: "Enter pancake user,...",
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        search(value, token);
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: resultSearch.length,
                    itemBuilder: (context, index) {
                      var selected = listUserDM.where((e) { return e["id"] == resultSearch[index]["id"]; }).length > 0;

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  child: Text(
                                    resultSearch[index]["full_name"]
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.0,
                                        color: Colors.white),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Container(
                                  child: Text(resultSearch[index]["full_name"], style: TextStyle(fontSize: 16)),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                handleUserToDM(resultSearch[index], selected);
                              },
                              child: Container(
                                  padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                    color: selected
                                        ? Color(0xffEF5350)
                                        : theme == ThemeType.DARK ? Color(0xFF1890FF) : Utils.getPrimaryColor(),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        selected ? "Remove" : "Add",
                                        style: TextStyle(
                                          color: Color(0xFFFFFFFF)
                                        ),
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
                  margin: EdgeInsets.only(top: 16),
                  height: 42,
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: Utils.getPrimaryColor(),
                    ),
                    onPressed: () {
                      if (!creating){
                        createDirectMessage(token);
                      }
                    },
                    child:  Row(
                      children: [
                        Expanded( child: Container(),),
                        creating ? Container(
                              width: 50,
                              alignment: Alignment.center,
                              child: Lottie.network("https://assets4.lottiefiles.com/datafiles/riuf5c21sUZ05w6/data.json"),
                            )
                          : Container(),
                        Text("CREATE", style: TextStyle(color: Colors.white)),
                        Expanded( child: Container() ),
                      ],
                    )
                  )
                )
              ]),
            ),
          ],
        ),
      ),
    );
  }
}