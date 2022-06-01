import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/http_exception.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_search_bar.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/models/models.dart';

class CreateDirectMessage extends StatefulWidget {

  final defaultList;
    CreateDirectMessage({
    Key? key,
    this.defaultList
  }): super(key: key);

  @override
  _CreateDirectMessageState createState() => _CreateDirectMessageState();
}

class _CreateDirectMessageState extends State<CreateDirectMessage> {
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
    if (widget.defaultList != null){
      listUserDM = [] + widget.defaultList;
    }
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
        "avatar_url": e["avatar_url"],
        "is_online": e["is_online"],
      };
    }).toList();

    setState(() {
      creating = true;
    });
    try {
      Provider.of<DirectMessage>(context, listen: false).setSelectedDM(DirectModel(
        "", 
        listUserId, 
        nameFM, 
        false, 
        0, 
        {}, 
        false,
        0,
        {},
        Provider.of<DirectMessage>(context, listen: false).getNameDM(listUserId, userId, nameFM)
      ), "", isCreate: true);
      Navigator.pop(context);
    } catch (e) {
    }
    if (this.mounted){
      setState(() {
        creating = false;
      });
    }
  }

  getNameOfDm(){
    if (nameFM != "") return nameFM;
    final userId = Provider.of<Auth>(context, listen: false).userId;
    return listUserDM.where((element) => element["user_id"] != userId).map((ele) =>ele["full_name"]).toList().join(", ");
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final token = auth.token;
    final userId = Provider.of<Auth>(context, listen: false).userId;
    final theme = Provider.of<Auth>(context, listen: true).theme;
    final isDark = auth.theme == ThemeType.DARK;
    resultSearch.removeWhere((element){return element["id"] == userId;});

    return Stack(
      children: [
        Container(
          child: Column(children: <Widget>[
            Container(
              margin: EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Text("New Direct Message", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: isDark ? Colors.grey[400] : Colors.grey[700])),
            ),
            Container(
              height: 30,
              margin: EdgeInsets.fromLTRB(8, 0, 8, 0),
              alignment: Alignment.centerLeft,
              child: Text("Conversation Name:")
            ),
            Container(
              height: 40,
              margin: EdgeInsets.only(right: 0, left: 0, top: 14, bottom: 10),
              child: CustomSearchBar(
                placeholder: listUserDM.length > 0 ? listUserDM.map((e) => e["full_name"]).join(", ") : "Enter conversation name",
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    nameFM = value;
                  });
                },
              )
            ),
            Container(
              margin: EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: Row(
                children: <Widget>[
                  Text("To: ", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  Container(
                    width: 430,
                    child: Wrap(
                      children: listUserDM.map((u) => GestureDetector(
                        onTap: () {handleUserToDM(u, true);},
                        child: Container(
                          padding: EdgeInsets.fromLTRB(7, 0, 7, 0),
                          margin: EdgeInsets.only(right: 10, top: 5),
                          decoration: BoxDecoration(
                              color: isDark ? Colors.grey[600] : Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(16)),
                          child: Container(
                            // width: 100,
                            padding: EdgeInsets.all(4),
                            child: Wrap(
                              children: [
                                  CachedImage(
                                    u["avatar_url"],
                                    radius: 16,
                                    isRound: true,
                                    name: u["full_name"]
                                  ),
                                  Text(" " + u["full_name"] + " "),
                              ],
                            )
                          ),
                        ),
                      )).toList(),
                    ) 
                  )
                ],
              )),
            Container(
              height: 40,
              margin: EdgeInsets.only(right: 0, left: 0, top: 14, bottom: 10),
              child: CustomSearchBar(
                autoFocus: true,
                placeholder: "Enter pancake user...",
                onChanged: (String value) {
                  if (_debounce?.isActive ?? false) _debounce.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    search(Utils.unSignVietnamese(value.toLowerCase()), token);
                  });
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                // scrollDirection: Axis.horizontal,
                itemCount: resultSearch.length,
                itemBuilder: (context, index) {
                  var selected = listUserDM.where((e) {
                        return e["id"] == resultSearch[index]["id"];
                      }).length >
                      0;
                  return Container(
                    margin: EdgeInsets.fromLTRB(8, 8, 8, 8),
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
                              handleUserToDM(resultSearch[index], selected);
                            },
                            child: Container(
                                padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                  color: selected
                                      ? Colors.redAccent
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
                                )),
                          )
                        ]),
                  );
                },
              ),
            ),
            // CREATE DIRECT MESSAGE
            Center(
              child: Container(
                // padding: EdgeInsets.symmetric(horizontal: 16),
                margin: EdgeInsets.only(top: 12),
                width: MediaQuery.of(context).size.width,
                height: 40,
                child: TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      isDark ? Color(0xff19DFCB) : Color(0xff2A5298)
                    )
                  ),
                  onPressed: () {
                    if (!creating){
                      createDirectMessage(token);
                    }
                  },
                  // color: Utils.getPrimaryColor(),
                  child:  Row(
                    children: [
                      Expanded( child: Container(),),
                      creating
                          ? Container(
                              width: 50,
                              alignment: Alignment.center,
                              child: Lottie.network("https://assets4.lottiefiles.com/datafiles/riuf5c21sUZ05w6/data.json"),
                            )
                          : Container(),
                      Text("Create", style: TextStyle(color: Colors.white)),
                      Expanded( child: Container(),),
                    ],
                  )
                )
              ),
            )
          ]),
        ),
      ],
    );
  }
}
