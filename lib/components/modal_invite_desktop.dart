import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/http_exception.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/models/models.dart';

class InviteModalDesktop extends StatefulWidget {
  InviteModalDesktop({
    Key? key,
    required this.directMessage
  }) : super(key: key);

  final DirectModel directMessage;

  @override
  _InviteModalDesktop createState() => _InviteModalDesktop();
}

class _InviteModalDesktop extends State<InviteModalDesktop>
    with SingleTickerProviderStateMixin {
  final _controller = ScrollController();
  var resultSearch = [];
  var seaching = false;
  var handleUser;
  var _debounce;
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    _controller.addListener(_scrollListener);
    super.initState();
    search("", Provider.of<Auth>(context, listen: false).token);
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

  invite(userSelected, token, idDM) async {
    String url = "${Utils.apiUrl}direct_messages/$idDM/invite?token=$token&device_id=${await Utils.getDeviceId()}";
    setState(() {
      handleUser = userSelected["id"];
    });
    try {
      // ktra xem idDM co 
      var dataConversation = Provider.of<DirectMessage>(context, listen: false).getCurrentDataDMMessage(idDM);
      if (dataConversation == null) return;
      var status = dataConversation["statusConversation"];
      if (status == "creating" ) return;
      if (status == "init"){
        Provider.of<DirectMessage>(context, listen: false).inviteMemberWhenConversationInDummy(userSelected, idDM);
        return setState(() {
          handleUser = null;
        });
      }
      var response = await Dio().post(url, data: {
        "data": await Utils.encryptServer({"invite_id": userSelected["id"]})
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
      else throw HttpException(dataRes["error_code"]);
      await Future.delayed(Duration(milliseconds: 500));
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

  // đối với hội thoại 1-1, thì nút thêm sẽ là "Tạo nhom với ..."
  // đổi với group thì sẽ la thêm thành viên.
  // hội thoai 1-1 có user là 2 người,
  // hội thoại group sẽ có user > 2 ngươi
  // hôi thoai 1, ko có nút này



  @override
  Widget build(BuildContext context) {
    final token = Provider.of<Auth>(context, listen: false).token;
    final userId = Provider.of<Auth>(context, listen: false).userId;
    final dm = widget.directMessage;
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;

    resultSearch.removeWhere((element) {
      return element["id"] == userId;
    });

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
        Container(
          padding: EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(4.5), topRight: Radius.circular(4.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dm.user.length > 2 ? "Invite people" : "Create a group with ", style: TextStyle(color: isDark ? Color(0xffB9B9B9) : Color(0xff5E5E5E) , fontSize: 16 ,fontWeight: FontWeight.w600)),
              Container(
                padding: EdgeInsets.only(right: 2),
                alignment: Alignment.centerRight,
                child: HoverItem(
                  colorHover: isDark ? Color(0xff828282) : Color(0xffDBDBDB),
                  child: IconButton(
                    onPressed: (){
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      PhosphorIcons.xCircle,
                      size: 20.0,
                      color: isDark ? Color(0xffB9B9B9) : Color(0xff5E5E5E)
                    ),
                  )
                )
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          color:isDark ? Color(0xff1E1F20) : Color(0xffA6A6A6),
        ),
        Container(
          height: 50,
          padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            prefix:Container(
              child: Icon(Icons.search, color: Colors.grey[500], size: 18),
              padding: EdgeInsets.only(left: 15)
            ),
            placeholder: "Search user",
            style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Color(0xff1E1F20)),
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: isDark ? Color(0xff1E1F20) : Color(0xffDBDBDB)
            ),
            onChanged: (value) {
              if (_debounce?.isActive ?? false) _debounce.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                  search(value, token);
              });
            },
          )
        ),
        Container(
          padding: EdgeInsets.only(left: 18,top: 4),
          child: Text("Your Friends",
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w500,
              color: isDark ? Color(0xffB9B9B9) : Color(0xff5E5E5E)
            ),
          )
        ),
        Container(
          height: 464,
          child: resultSearch.length == 0 
          ? Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/icons/searchIcon.svg', width: 120,),
                  SizedBox(height: 30),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: "No result found\n", style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic, fontSize: 40)), 
                   ]
                  ), 
                  textAlign: TextAlign.center),
                  SizedBox(height: 120)
                ],
              ),
            ):ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 18),
            itemCount: resultSearch.length,
            itemBuilder: (context, index) {
              var selected = dm.user.where((e) {return e["user_id"] == resultSearch[index]["id"]  && e["user_id"] == "in_conversation"; }).length > 0;
              return Container(
                padding: EdgeInsets.symmetric(vertical: 8),
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
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          resultSearch[index]["full_name"],
                          style: TextStyle(fontSize: 16, color: isDark ? Color(0xffB9B9B9) : Color(0xff5E5E5E))
                        )
                      ]
                    ),
                    GestureDetector(
                      onTap: () {
                        if(!selected) invite(resultSearch[index], token, dm.id);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                          color: handleUser != null ? Colors.blueAccent : selected ? Color(0xff575757) : Colors.blueAccent,
                        ),
                        child: Row(
                          children: [
                            handleUser == resultSearch[index]["id"] ? Container(
                              height: 20,
                              alignment: Alignment.center,
                              child: Lottie.network("https://assets4.lottiefiles.com/datafiles/riuf5c21sUZ05w6/data.json")
                            ) : Text(
                              selected ? "Invited" : "Invite",
                              style: TextStyle(fontSize: 13, color: Color(0xffffffff))
                            )
                          ]
                        )
                      ),
                    )
                  ]
                ),
              );
             }
            )
          ),
        SizedBox(height: 16)
      ])
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
