import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/apps/create_app_view.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/models/models.dart';

class ListAppCreate extends StatefulWidget {
  final Function? onSuccessCreateApp;
  const ListAppCreate({ Key? key, @required this.onSuccessCreateApp }) : super(key: key);

  @override
  State<ListAppCreate> createState() => _ListAppCreateState();
}

class _ListAppCreateState extends State<ListAppCreate> {
  FocusNode focusNode = FocusNode();
  List shops = [];
  String? message;
  bool isActive = true;
  bool isLoading = true;
  bool highLight = false;
  bool highLightcustomapp = false;
  bool highLightbankapp = false;
  

  @override
  void initState() {
    super.initState();
    Timer.run(() async {
      loadListShops();
    });
  }

  loadListShops() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final url = Utils.apiUrl + 'users/list_shops?token=$token';

    try {
      final response = await Dio().get(url);
      if (response.data["success"]) {
        setState(() {
          shops = response.data["shops"];
          isLoading = false;
        });
      } else {
        setState(() {
          message = response.data["message"];
          isLoading = false;
          isActive = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  onSave() async {
    final token  =  Provider.of<Auth>(context, listen: false).token;
    final url = "${Utils.apiUrl}app?token=$token";
    try {
      var response  = await Dio().post(url, data: {
        "name": "POS",
        "is_workspace": false,
        "type": "pos_app"
      });

      var resData = response.data;
      if (resData["success"]){
        widget.onSuccessCreateApp!(resData["data"]);
        Navigator.of(context, rootNavigator: true).pop("Discard");
      } else {
        setState(() {
          message = resData["message"];
          isActive = false;
        });
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Container(
      height: 652,
      width: 800,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0)),
        title: Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xff323F4B) : Palette.defaultBackgroundLight,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(4.0),
              topLeft: Radius.circular(4.0)
            )
          ),
          child: Container(
            padding: const EdgeInsets.only(top: 9, bottom: 9, left: 16),
            decoration: BoxDecoration(
              color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(4.0),
                topLeft: Radius.circular(4.0)
              )
            ),
            child: Text('Create custom app', style: TextStyle(fontSize: 16))
          ),
        ),
        titlePadding: const EdgeInsets.all(0),
        backgroundColor: isDark ? Color(0xff3D3D3D): Color(0xffFFFFFF),
        contentPadding: EdgeInsets.zero,
        content: Container(
          // width: 1000,
          padding: EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Container(
                      width: 224,
                      height: 226,
                      margin: EdgeInsets.only(right: 15),
                      child: MouseRegion(
                        onEnter: (_) => setState(() => highLight = true),
                        onExit: (_) => setState(() => highLight = false),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: highLight ? isDark ?Color(0xffFAAD14) :Utils.getPrimaryColor()  : isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                              width: 1,
                            ),
                          ),
                          color: isDark ? Color(0xff4C4C4C) : Color(0xffEDEDED),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.only(left: 16, top: 16, right: 16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8.0),
                                            child: Image.asset(
                                              "assets/images/pos_app.png",
                                              width: 40,
                                              height: 40,
                                            ),
                                          ),
                                          // child: SvgPicture.asset('assets/icons/pos_color.svg', color: Colors.blue, width: 40,)
                                        ),
                                        SizedBox(width: 10,),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("POS", style: TextStyle(fontWeight: FontWeight.w600),),
                                            SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Image.asset(
                                                  "assets/images/logoPanchat.png",
                                                  width: 16,
                                                  height: 16,
                                                ),
                                                SizedBox(width: 5,),
                                                Text("Panchat", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),)
                                              ],
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 6),
                                      height: 1,
                                      color: isDark ? Color(0xff5E5E5E): Color(0xffDBDBDB),
                                    ),
                                    SizedBox(height: 10),
                                    Text("Đồng bộ tin nhắn từ những trạng thái cấu hình POS"),
                                    if (!isActive) SizedBox(height: 10),
                                    if (!isActive) Text(message ?? "Lỗi hệ thống", style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic))
                                  ],
                                ),
                              ),
                              Container(
                                height: 32,
                                width: 176,
                                color: isDark ? Color(0xff3D3D3D) : Color(0xffF8F8F8),
                                child: TextButton(
                                  style: ButtonStyle(
                                    shape: MaterialStateProperty.all(
                                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.0))
                                    ),
                                    padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 20, vertical: 8))
                                  ),
                                  child: isLoading
                                    ? SpinKitFadingCircle(
                                      color: isDark ? Color(0xffC9C9C9) : Color(0xffA6A6A6),
                                      size: 19)
                                    : Text(
                                      "Cài đặt",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        color: isDark ? Color(0xffffffff) : Color(0xff3D3D3D),
                                      )
                                    ),
                                  onPressed: !isActive || isLoading ? null : () {
                                    onSave();
                                    // showListAppCreate(context, shops);
                                  },
                                ),
                              ),
                              SizedBox(height: 8,)
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 224,
                      height: 226,
                      margin: EdgeInsets.only(right: 10, left: 10),
                      child: MouseRegion(
                        onEnter: (_) => setState(() => highLightbankapp = true),
                        onExit: (_) => setState(() => highLightbankapp = false),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: highLightbankapp ? isDark ?Color(0xffFAAD14) :Utils.getPrimaryColor() : isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                              width: 1,
                            ),
                          ),
                          color: isDark ? Color(0xff4C4C4C) : Color(0xffEDEDED),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.only(left: 16, top: 16, right: 16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8.0),
                                            child: Image.asset(
                                              "assets/images/bank_app.png",
                                              width: 40,
                                              height: 40,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10,),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("BizBanking", style: TextStyle(fontWeight: FontWeight.w600),),
                                            SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Image.asset(
                                                  "assets/images/logoPanchat.png",
                                                  width: 16,
                                                  height: 16,
                                                ),
                                                SizedBox(width: 5,),
                                                Text("Panchat", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),)
                                              ],
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 6),
                                      height: 1,
                                      color: isDark ? Color(0xff5E5E5E): Color(0xffDBDBDB),
                                    ),
                                    SizedBox(height: 10),
                                    Text("Thông báo biến động tài khoản ngân hàng")
                                  ],
                                ),
                              ),
                              Container(
                                height: 32,
                                width: 176,
                                margin: EdgeInsets.only(bottom: 27),
                                color: isDark ? Color(0xff3D3D3D) : Color(0xffF8F8F8),
                                child: HoverItem(
                                  colorHover: isDark ? Color(0xffFAAD14) :Utils.getPrimaryColor(),
                                  child: TextButton(
                                    style: ButtonStyle(
                                      shape: MaterialStateProperty.all(
                                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.0))
                                      ),
                                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 20, vertical: 8))
                                    ),
                                    child: Text(
                                      "Cài đặt",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        color: isDark ? Color(0xffffffff) : Color(0xff3D3D3D),
                                      )
                                    ),
                                    onPressed: () {},
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(left: 15),
                      width: 224,
                      height: 226,
                      child: MouseRegion(
                         onEnter: (_) => setState(() => highLightcustomapp = true),
                         onExit: (_) => setState(() => highLightcustomapp = false),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: highLightcustomapp ? isDark ?Color(0xffFAAD14) :Utils.getPrimaryColor() : isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                              width: 1,
                            ),
                          ),
                          color: isDark ? Color(0xff4C4C4C) : Color(0xffEDEDED),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.only(left: 16, top: 16, right: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8.0),
                                          child: Image.asset(
                                            "assets/images/custom_app.png",
                                            width: 40,
                                            height: 40,
                                          ),
                                        ),
                                        SizedBox(width: 10,),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Custom app", style: TextStyle(fontWeight: FontWeight.w600),),
                                            SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Image.asset(
                                                  "assets/images/logoPanchat.png",
                                                  width: 16,
                                                  height: 16,
                                                ),
                                                SizedBox(width: 5,),
                                                Text("Panchat", style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),)
                                              ],
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(top: 6),
                                      height: 1,
                                      color: isDark ? Color(0xff5E5E5E): Color(0xffDBDBDB),
                                    ),
                                    SizedBox(height: 10),
                                    Text("Tạo app tuỳ biến")
                                  ],
                                ),
                              ),
                              Container(
                                height: 32,
                                width: 176,
                                margin: EdgeInsets.only(bottom: 27),
                                color: isDark ? Color(0xff3D3D3D) : Color(0xffF8F8F8),
                                child: HoverItem(
                                  colorHover: isDark ? Color(0xffFAAD14) :Utils.getPrimaryColor(),
                                  child: TextButton(
                                    style: ButtonStyle(
                                      shape: MaterialStateProperty.all(
                                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.0))
                                      ),
                                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 20, vertical: 8))
                                    ),
                                    child: Text(
                                      "Cài đặt",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        color: isDark ? Color(0xffffffff) : Color(0xff3D3D3D),
                                      )
                                    ),
                                    onPressed: () {
                                      showCreateApps(context, widget.onSuccessCreateApp);
                                    },
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        )
      ),
    );
  }
}

showCreateApps(context, onSuccessCreateApp) {
  showDialog(
    context: context,
    builder:(context) {
      return AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5))
        ),
        content: CreateAppView(onSuccessCreateApp: onSuccessCreateApp)
      );
    }
  );
}
