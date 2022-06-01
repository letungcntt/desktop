import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/apps/add_app_macOS.dart';
import 'package:workcake/components/apps/app_detail.dart';
import 'package:workcake/components/apps/pos_app_config.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/models/models.dart';

class ChannelAppMacOS extends StatefulWidget {
  final type;

  ChannelAppMacOS({Key? key, this.type}) : super(key: key);

  @override
  _ChannelAppMacOSState createState() => _ChannelAppMacOSState();
}

class _ChannelAppMacOSState extends State<ChannelAppMacOS> {
  List apps = [];
  String itemHover = "";
  bool rebuild = false;

  @override
  void initState() {
    super.initState();
    getListApps();
  }

  handelApp(installed, appId, token, channelId, workspaceId, type)async{
    try {
      String url  = "";
      if (!installed) url = "${Utils.apiUrl}app/$appId/install_channel?token=$token";
      else url = "${Utils.apiUrl}app/$appId/remove_channel?token=$token";
      await Dio().post(url, data: {
        "workspace_id": workspaceId,
        "channel_id": channelId,
        "type": type
      });
      Provider.of<Channels>(context, listen: false).loadCommandChannel(token, workspaceId, channelId);
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  getListApps()async {
    final token = Provider.of<Auth>(context, listen: false).token;

    String url = "${Utils.apiUrl}app?token=$token";
    try {
      var response = await Dio().get(url);
      var resData = response.data;
      setState(() {
        apps = resData["data"];
      });
      // print(resData);
    } catch (e) {
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  onChangeIsHover(String value) {
    setState(() {
      itemHover = value;
      rebuild = false;
    });

    Future.delayed(Duration.zero, () {
      if(this.mounted) {
        setState(() => rebuild = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appInChannels = Provider.of<Channels>(context, listen: true).appInChannels;
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    return Container(
      child: Column(
        children: [
          Container(
            width: 470.0,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(5.0),
                  topLeft: Radius.circular(5.0)),
              color:isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left:8.0),
                  child: Text(
                    "Channel apps",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    )
                  ),
                ),
                Container(
                  child: HoverItem(
                    colorHover: isDark ? Color(0xff828282) : Color(0xffDBDBDB),
                    child: IconButton(
                      onPressed: (){
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        PhosphorIcons.xCircle,
                        size: 18.0,
                      ),
                    )
                  )
                ),
              ],
            ),
          ),
          // SizedBox(height: 8,),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: appInChannels.length,
              itemBuilder: (context, index) {
                final app = appInChannels[index];
                final installed  = appInChannels.where((element) {return element["app_id"] == app["app_id"];}).toList().length > 0;

                return HoverItem(
                  colorHover: isDark ? Color(0xff4C4C4C) : Color(0xffEDEDED),
                  onHover: () => onChangeIsHover(app["id"] ?? app["app_id"]),
                  onExit: () => onChangeIsHover(""),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CachedImage(
                              app['avatar'] ?? '',
                              width: 36,
                              height: 36,
                              radius: 18,
                              name: app['name'] ?? appInChannels[index]["app_name"],
                              fontSize: 20
                            ),
                            SizedBox(width: 12),
                            Text(
                              app['name'] ?? appInChannels[index]["app_name"],
                              style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w400, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight
                              ),
                            ),
                          ],
                        ),
                        (itemHover == (app["id"] ?? app["app_id"])) ? Row(
                          children: [
                            if (app["app_type"] == "pos_app") InkWell(
                              onTap: app["app_type"] != "default" ? () => showPOSAppConfig(context, app) : null,
                              child: Container(
                                height: 30,
                                width: 30,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDark ? Color(0xffEDEDED) : Color(0xff5E5E5E),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                                child:Icon(PhosphorIcons.gear,size: 16,
                                  color: isDark ? Color(0xffEDEDED) : Color(0xff5E5E5E),),
                              ),
                            ),
                            SizedBox(width: 8,),
                            InkWell(
                              onTap: (){
                                 handelApp(installed, app["app_id"], auth.token, currentChannel["id"], currentWorkspace["id"], app['app_type']);
                              },
                              child: Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Color(0xffEB5757) ,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Icon(
                                  PhosphorIcons.trashSimple,
                                  color: Color(0xffEB5757) ,
                                  size: 16.0,
                                ),
                               ),
                            ),
                            SizedBox(width: 8,),
                          ],
                        ):SizedBox(),
                      ],
                    ),
                  ),
                );
              }
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 10),
            height: 1,
            color: isDark? Color(0xFF5E5E5E): Color(0xFFDBDBDB)
          ),
          Container(
            margin: EdgeInsets.only(bottom: 10,left: 10,right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => showAddAppChannel(context),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                      color: isDark ? Color(0xffFAAD14): Color(0xff1890FF),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.plus,
                          size: 13,
                          color: isDark ? Color(0xffFAAD14): Color(0xff1890FF)
                        ),
                        SizedBox(width: 8,),
                        Text(
                          "New Apps",
                          style: TextStyle(
                            color: isDark ? Color(0xffFAAD14): Color(0xff1890FF),
                            fontSize: 13
                          )
                        ),
                      ],
                    ),
                  )
                ),
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Color(0xFFFF7875),
                        width: 1,
                      )
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFFF7875)
                      ),
                    ),
                  ),
                ),
              ]
            ),
          ),
        ]
      )
    );
  }
}

showPOSAppConfig(context, app) {
  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: Duration(milliseconds: 80),
    transitionBuilder: (context, a1, a2, widget){
      var begin = 0.5;
      var end = 1.0;
      var curve = Curves.fastOutSlowIn;
      var curveTween = CurveTween(curve: curve);
      var tween = Tween(begin: begin, end: end).chain(curveTween);
      var offsetAnimation = a1.drive(tween);
      return ScaleTransition(
        scale: offsetAnimation,
        child: FadeTransition(
          opacity: a1,
          child: widget,
        ),
      );
    },
    pageBuilder: (BuildContext context, a1, a2) {
      return  Container(
        child: Center(
          child: PosAppConfig(app: app),
        )
      );
    }
  );
}

onShowAppsSetting(context, id) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Container(
        child: AlertDialog(
          content: Container(
              height: 110.0,
              width: 480.0,
              child: Center(
                child: AppDetail(appId: id)
              )
          ),
        ),
      );
    }
  );
}

showAddAppChannel(context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Container(
        child: AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Container(
            height: 470.0,
            width: 470.0,
            child: Center(
              child: AddAppMacOS(),
            )
          ),
        ),
      );
    }
  );
}
