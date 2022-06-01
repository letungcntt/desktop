import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/models/models.dart';
import 'package:workcake/service_locator.dart';
import 'package:workcake/services/sharedprefsutil.dart';

class AddAppMacOS extends StatefulWidget {
  AddAppMacOS({Key? key}) : super(key: key);

  @override
  _AddAppMacOSState createState() => _AddAppMacOSState();
}

class _AddAppMacOSState extends State<AddAppMacOS> {
  List apps = [];
  String techAcc = '';

  @override
  void initState() {
    // _controller.addListener(_scrollListener);
    super.initState();
    String token = Provider.of<Auth>(context, listen: false).token;
    getListApps(token);
    getAcc().then((vl) {
      techAcc = vl;
    });
  }
  
  getListApps(token)async {
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

  Future<String> getAcc() async {
    final accTech = sl.get<SharedPrefsUtil>().getTechcomAccount();
    return accTech;
  }

  @override
  Widget build(BuildContext context) {
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    final appInChannels = Provider.of<Channels>(context, listen: true).appInChannels;
    final lengthA = techAcc.length > 4 ? techAcc.length - 4 : 0;
    final newString = techAcc.substring(lengthA);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF3D3D3D) : Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(5.0))
      ),
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
          apps.length > 0 ? Container(
            child: Expanded(
              child: ListView.builder(
                itemCount: apps.length,
                itemBuilder: (context, index) {
                  var installed  = appInChannels.where((element) {return element["app_id"] == apps[index]["id"];}).toList().length > 0;
                  return HoverItem(
                    colorHover: Palette.hoverColorDefault,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          CachedImage(
                            apps[index]["avatar"],
                            width: 36,
                            height: 36,
                            radius: 18,
                            name: apps[index]["name"].substring(0,1),
                            fontSize: 20
                          ),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(apps[index]["name"]),
                                  Text(
                                    apps[index]['name'] == 'BizBanking'
                                      ? techAcc != ''
                                        ? '***$newString' : 'Not logged in.'
                                      : apps[index]['type'] == 'pos_app'
                                        ? 'Kết nối ứng dụng POS đến kênh này'
                                        : '',
                                    style: TextStyle(fontSize: 13),
                                  )
                                ],
                              ),
                            )
                          ),
                          Container(
                            child: TextButton(
                              style: ButtonStyle(
                                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  side: BorderSide(color:isDark ? !installed ? Color(0xffEAE8E8) : Color(0xff828282) : installed ? Color(0xffB7B7B7):Color(0xff5E5E5E)),
                                ))
                              ),
                              onPressed: (apps[index]['name'] == 'BizBanking' && techAcc == '')
                                ? null
                                : () {
                                  handelApp(installed, apps[index]["id"], auth.token, currentChannel["id"], currentWorkspace["id"], apps[index]['type']);
                                },
                              child: Text(
                                installed ? "Uninstall" : "Install",
                                style: TextStyle(
                                  color: isDark ? installed ? Color(0xff828282):Color(0xffEAE8E8): installed ? Color(0xffB7B7B7):Color(0xff5E5E5E)
                                )
                              ),
                            )
                          )
                        ],
                      ),
                    ),
                  );
                }
              )
            )
          ) : Container(
            child: Text("Can't find App Commands")
          ),
                    Container(
          margin: EdgeInsets.only(bottom: 10),
          height: 1,
          color: isDark? Color(0xFF5E5E5E): Color(0xFFDBDBDB)
        ),
        Container(
          margin: EdgeInsets.only(bottom: 10,left: 10,right: 10),
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
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFFF7875)
                  ),
                )
              )
            ),
            ]
          ),
        ),
        ]
      ),
    );
  }
}
