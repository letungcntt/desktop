import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:workcake/channels/create_channel_desktop.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/http_exception.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/icon_online.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/providers/providers.dart';

class CreateDirectMessage extends StatefulWidget {
  final defaultList;
    CreateDirectMessage({
    Key? key,
    this.defaultList,
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
        Provider.of<DirectMessage>(context, listen: false).getNameDM(listUserId, userId, nameFM),
        null
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
             Container(
               padding: EdgeInsets.symmetric(horizontal: 24,vertical: 12),
               child: Text(S.current.createGroup, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: isDark ? Color(0xffF1F1F1) : Colors.grey[700])),
            ),
            Container(
               height: 1,
               color: isDark ? Color(0xff1E1F20) : Color(0xffA6A6A6),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(24, 8, 8, 0),
              alignment: Alignment.centerLeft,
              child: Text("Group name" , style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Color(0xffB9B9B9) : Color(0xff5E5E5E)),)
            ),
            Container(
              height: 40,
              margin: EdgeInsets.only(right: 24, left: 24, top: 8, bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isDark ? Color(0xff1E1F20) : Color(0xffDBDBDB)
              ),
              child: TextFormField(
                style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87),
                decoration: InputDecoration(
                  labelText: "Enter group name",
                  labelStyle: TextStyle(color: Color(0xffBCBCBC),fontSize: 14),
                  contentPadding: EdgeInsets.all(8),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                    borderRadius: BorderRadius.all(Radius.circular(4))
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                    borderRadius: BorderRadius.all(Radius.circular(4))
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.never
                ),
                onChanged: (value) {
                 if (_debounce?.isActive ?? false) _debounce.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    nameFM = value;
                  });
                },
              )
            ),
            Container(
              margin: EdgeInsets.fromLTRB(24, 4, 0, 0),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 500,
                    child: ScrollConfiguration(
                      behavior: MyCustomScrollBehavior(),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: BouncingScrollPhysics(),
                        child: Row(
                          children: listUserDM.map((u) => GestureDetector(
                            onTap: () {handleUserToDM(u, true);},
                            child: Container(
                              width: 60,
                              height: 65,
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  Stack(
                                    children: [
                                      CachedImage(
                                        u["avatar_url"],
                                        radius: 40,
                                        isRound: true,
                                        name: u["full_name"]
                                      ),
                                      Positioned(
                                        right: 4,
                                        top: -1,
                                        child: InkWell(
                                          onTap: () {handleUserToDM(u, true);},
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            child: Icon(Icons.cancel_rounded,
                                              size: 15, color: isDark ? Palette.defaultTextDark : Palette.fillerText
                                            ),
                                          ),
                                        )
                                      ),
                                      Positioned(
                                        right: 0, bottom: -12,
                                        child: u["is_online"] ? IconOnline() : Container()
                                      )
                                    ],
                                  ),
                                  Text(" " + u["full_name"] + " ", textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5 ),),
                                ],
                              )
                            ),
                          )).toList(),
                        ),
                      ),
                    )
                  )
                ],
              )
            ),
            Container(
              margin: EdgeInsets.fromLTRB(24, 8, 8, 0),
              alignment: Alignment.centerLeft,
              child: Text("Your Friends",style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500 , color: isDark ? Color(0xffB9B9B9) : Color(0xff5E5E5E)),),
            ),
            Container(
              height: 40,
              margin: EdgeInsets.only(right: 24, left: 24, top: 8, bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isDark ? Color(0xff1E1F20) : Color(0xffDBDBDB)
              ),
              child: TextFormField(
                style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Search",
                  labelStyle: TextStyle(color: Color(0xffBCBCBC),fontSize: 14),
                  contentPadding: EdgeInsets.all(8),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                    borderRadius: BorderRadius.all(Radius.circular(4))
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                    borderRadius: BorderRadius.all(Radius.circular(4))
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.never
                ),
                onChanged: (value) {
                 if (_debounce?.isActive ?? false) _debounce.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    search(Utils.unSignVietnamese(value.toLowerCase()), token);
                  });
                },
              )
            ),
            Expanded(
              child: ListView.builder(
                // scrollDirection: Axis.horizontal,
                itemCount: resultSearch.length,
                itemBuilder: (context, index) {
                  var selected = listUserDM.where((e) {
                    return e["id"] == resultSearch[index]["id"];
                  }).length >0;
                  return HoverItem(
                    colorHover: Palette.hoverColorDefault,
                    child: Container(
                      margin: EdgeInsets.fromLTRB(24, 8, 24, 8),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    CachedImage(
                                      resultSearch[index]["avatar_url"],
                                      radius: 35,
                                      isRound: true,
                                      name: resultSearch[index]["full_name"]
                                    ),
                                    Positioned(
                                      right: 0, bottom: -13,
                                      child: resultSearch[index]["is_online"] ? IconOnline() : Container()
                                    )
                                  ],
                                ),
                                Container(
                                  width: 10,
                                ),
                                Container(
                                  child: Text(resultSearch[index]["full_name"],
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,color: isDark ? Color(0xffB9B9B9) : Color(0xff5E5E5E))),
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
                                      BorderRadius.all(Radius.circular(4)),
                                    color: selected
                                      ? Colors.redAccent
                                      : theme == ThemeType.DARK ? Color(0xFF1481FF) : Color(0xFF1481FF),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        selected ? "Remove" : "Add",
                                        style: TextStyle(
                                          color: Color(0xFFFFFFFF),
                                          fontSize: 14
                                        ),
                                      ),
                                    ],
                                  )),
                            )
                          ]),
                    ),
                  );
                },
              ),
            ),
            // CREATE DIRECT MESSAGE
            Container(
              padding: EdgeInsets.only(top: 10,bottom: 10),
              decoration: BoxDecoration(
                border: Border (
                  top: BorderSide(
                    color:isDark ? Color(0xff1E1F20) : Color(0xffA6A6A6),
                    width: 1.0,
                  ),
                )
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Color(0xFFFF7875),
                          width: 1,
                        )
                      ),
                      height: 34,
                      width: 80,
                      child: TextButton(
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))) ,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        S.current.cancel,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFFF7875)
                        ),
                      )
                    )
                  ),
                  SizedBox(width: 8,),
                  Container(
                    // padding: EdgeInsets.symmetric(horizontal: 16),
                    margin: EdgeInsets.only(right: 20),
                    height: 34,
                    width: 106,
                    child: TextButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                           Color(0xff1481FF)
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
                ],
              ),
            )
          ]),
        ),
      ],
    );
  }
}
