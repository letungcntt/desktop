import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/http_exception.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_search_bar.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/models/models.dart';

class SearchUser extends StatefulWidget {
  SearchUser({Key? key}) : super(key: key);

  @override
  _SearchUser createState() => _SearchUser();
}

class _SearchUser extends State<SearchUser>
    with SingleTickerProviderStateMixin {
  final _controller = ScrollController();
  var resultSearch = [];
  var seaching = false;
  var handleUser;
  var _debounce;

  @override
  void initState() {
    _controller.addListener(_scrollListener);
    super.initState();
  }

  _scrollListener() {
    FocusScope.of(context).unfocus();
  }

  search(value, token) async {
    String url =
        "${Utils.apiUrl}users/search_user_in_workspace?token=$token&keyword=$value";
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

  invite(userId, token, idDM) async {
    LazyBox box = Hive.lazyBox("pairKey");
    String url = "${Utils.apiUrl}direct_messages/$idDM/invite?token=$token&device_id=${await box.get("deviceId")}";
    setState(() {
      handleUser = userId;
    });
    try {
      var response = await Dio().post(url, data: {
        "data": await Utils.encryptServer({"invite_id": userId})
      });
      var dataRes = response.data;
      if (dataRes["success"]) {
        var currentDM = Provider.of<DirectMessage>(context, listen: false).getModelConversation(idDM);
        if (currentDM == null) return;
        currentDM.user = dataRes["data"]["user"];
        var boxDirect = Hive.box('direct');
        boxDirect.put(currentDM.id, currentDM);

        Provider.of<DirectMessage>(context, listen: false).setSelectedDM(currentDM, token);
      }
      setState(() {
        handleUser = null;
      });
    } catch (e) {
      setState(() {
        handleUser = null;
      });
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<Auth>(context, listen: false).token;
    final userId = Provider.of<Auth>(context, listen: false).userId;
    double deviceHeight = MediaQuery.of(context).size.height;
    DirectModel dm = Provider.of<DirectMessage>(context, listen: true).directMessageSelected;
    resultSearch.removeWhere((element) {
      return element["id"] == userId;
    });

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        height: deviceHeight * .85,
        child: Column(children: <Widget>[
          Container(
            height: 40,
            margin: EdgeInsets.only(right: 18, left: 18, top: 14),
            child: CustomSearchBar(
               onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  search(value, token);
                });
              },
            )
          ),
          Stack(
            children: [
              Container(
                alignment: Alignment.center,
                height: seaching ? 100 : 0,
                child: Lottie.network("https://assets6.lottiefiles.com/datafiles/tvGrhGYaLS0VjreZ1oqQpeFYPn4xPO625FsUAsp8/simple loading/simple.json")
              ),
              Container(
                height: deviceHeight * .85 - 160,
                padding: EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom:
                      BorderSide(color: Colors.black12, width: 0.5)
                    )
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: ListView.builder(
                      // scrollDirection: Axis.horizontal,
                      itemCount: resultSearch.length,
                      itemBuilder: (context, index) {
                        var selected = dm.user.where((e) {return e["user_id"] == resultSearch[index]["id"]; }).length > 0;

                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 5),
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
                                      child: Text(
                                        resultSearch[index]["full_name"],
                                        style: TextStyle(fontSize: 16)
                                      )
                                    )
                                  ]
                                ),
                                GestureDetector(
                                  onTap: () {
                                    invite(resultSearch[index]["id"], token, dm.id);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(Radius.circular(10)),
                                      color: selected ? Colors.redAccent : Colors.blueAccent,
                                    ),
                                    child: Row(
                                      children: [
                                        handleUser == resultSearch[index]["id"] ? Container(
                                          height: 20,
                                          alignment: Alignment.center,
                                          child: Lottie.network("https://assets4.lottiefiles.com/datafiles/riuf5c21sUZ05w6/data.json")
                                        ) : Text(selected ? "Remove" : "Add")
                                      ],
                                    )
                                  ),
                                )
                              ]
                            ),
                          );
                      }
                    )
                  )
                )
              ]
            )
          ]
        )
      )
    );
  }
}

class AnimationProcessing extends StatefulWidget {
  final active;
  AnimationProcessing({Key? key, @required this.active}) : super(key: key);
  @override
  _AnimationProcessing createState() => _AnimationProcessing();
}

class _AnimationProcessing extends State<AnimationProcessing> {
  double _width = 0;

  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: _width,
      height: 10,
      duration: Duration(seconds: 1),
      child: Container(
        height: widget.active ? 20 : 0,
        child: Lottie.network("https://assets6.lottiefiles.com/datafiles/riuf5c21sUZ05w6/data.json"),
      ),
    );
  }
}
