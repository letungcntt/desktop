import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/dropdown_overlay.dart';
import 'package:workcake/models/models.dart';

class PosAppConfig extends StatefulWidget {
  const PosAppConfig({ Key? key, required this.app }) : super(key: key);

  final app;

  @override
  State<PosAppConfig> createState() => _PosAppConfigState();
}

class _PosAppConfigState extends State<PosAppConfig> {
  List selectedShops = [];
  List statusOrderIds = [];
  bool isSendMessageWhenChangeStatusOrder = false;
  bool outForDelivery = false;
  bool undeliverable = false;
  bool canceled = false;
  bool loading = false;
  Map? settings;
  List status = [{
    "id": 0,
    "name": "Mới"
  }, {
    "id": 1,
    "name": "Đã xác nhận"
  }, {
    "id": 2,
    "name": "Đã gửi hàng"
  }, {
    "id": 3,
    "name": "Đã nhận"
  }, {
    "id": 4,
    "name": "Đang hoàn"
  }, {
    "id": 5,
    "name": "Đã hoàn"
  }, {
    "id": 6,
    "name": "Đã huỷ"
  }, {
    "id": 7,
    "name": "Đã xoá"
  }, {
    "id": 8,
    "name": "Đang đóng hàng"
  }, {
    "id": 9,
    "name": "Chờ chuyển hàng"
  }, {
    "id": 11,
    "name": "Chờ hàng"
  }, {
    "id": 12,
    "name": "Chờ in"
  }, {
    "id": 13,
    "name": "Đã in"
  }, {
    "id": 15,
    "name": "Hoàn một phần"
  }, {
    "id": 16,
    "name": "Đã thu tiền"
  }, {
    "id": 17,
    "name": "Chờ xác nhận"
  }, {
    "id": 20,
    "name": "Đã đặt hàng"
  }];
  bool? noShops;
  bool? noSelectOrderStatus;
  String? errorMessage;
  List shops = [];

  @override
  void initState() {
    super.initState();
    Timer.run(() async {
      loadListShops();
      loadSettingAppChannel();
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
        });
      }
    } catch (e) {
      print(e);
    }
  }

  loadSettingAppChannel() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;

    final url = Utils.apiUrl + 'workspaces/${currentWorkspace["id"]}/channels/${currentChannel["id"]}/app/${widget.app["app_id"]}/get_config?token=$token';

    try {
      final response = await Dio().get(url);
      if (response.data["success"]) {
        setState(() {
          settings = response.data["app"]["config"];
          selectedShops = response.data["app"]["config"] != null ? response.data["app"]["config"]["shop_ids"] ?? [] : [];
          statusOrderIds = response.data["app"]["config"] != null ? response.data["app"]["config"]["status_ids"] ?? [] : [];
          isSendMessageWhenChangeStatusOrder = response.data["app"]["config"] != null ? response.data["app"]["config"]["is_send_message_when_change_status"] ?? false : false;
          undeliverable = response.data["app"]["config"] != null ? response.data["app"]["config"]["undeliverable"] ?? false : false;
          outForDelivery = response.data["app"]["config"] != null ? response.data["app"]["config"]["out_for_delivery"] ?? false : false;
          canceled = response.data["app"]["config"] != null ? response.data["app"]["config"]["canceled"] ?? false : false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  onSaveSettingsPosApp(context, workspaceId, channelId) async {
    final token = Provider.of<Auth>(context, listen: false).token;

    if (selectedShops.length == 0) {
      setState(() => noShops = true);
    } else {
      List disabled = [];
      if (widget.app["config"] != null) {
        for (var shop in widget.app["config"]["shop_ids"]) {
          if (!selectedShops.contains(shop)) disabled.add(shop);
        }
      }
      try {
        String url = Utils.apiUrl + 'app/${widget.app["app_id"]}/update_settings?token=$token';
        final body = {
          "shop_ids": selectedShops,
          "disabled_shop_ids": disabled,
          "workspace_id": workspaceId,
          "channel_id": channelId,
          "settings": {
            "workspace_id": workspaceId,
            "channel_id": channelId,
            "shop_ids": selectedShops,
            "is_send_message_when_change_status": isSendMessageWhenChangeStatusOrder,
            "out_for_delivery": outForDelivery,
            "undeliverable": undeliverable,
            "canceled": canceled,
            "status_ids": statusOrderIds
          }
        };

        final response = await Dio().post(url, data: body);
        setState(() => loading = false);
        if (!response.data["success"]) {
          setState(() => errorMessage = response.data["message"]);
        } else {
          Navigator.pop(context);
        }
      } catch (e) {
        print("update setting $e");
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;

    return Container(
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0)),
        title: Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(4.0),
              topLeft: Radius.circular(4.0)
            )
          ),
          child: Container(
            padding: const EdgeInsets.only(top: 9, bottom: 9, left: 16),
            child: Text('App settings', style: TextStyle(fontSize: 16))
          ),
        ),
        titlePadding: const EdgeInsets.all(0),
        backgroundColor: isDark ? Color(0xff3D3D3D):Color(0xffffffff),
        contentPadding: EdgeInsets.zero,
        content: Container(
          // width: 1000,
          padding: EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 12),
          child: Container(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, top: 20),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Container(
                            width: 300,
                            child: Text("Authentication", style: TextStyle(fontSize: 18),),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(40.0),
                          child: Container(
                            padding: EdgeInsets.only(left: 12, right: 12, top: 5, bottom: 5),
                            color: Colors.blue,
                            child: Text("Authenticated to POS as: ${currentUser["full_name"]}", style: TextStyle(fontSize: 14.4, fontWeight: FontWeight.w300),),
                          ),
                        )
                      ],
                    ),
                  ),
                  Divider(color: isDark ? Color(0xff707070) : Color(0xFFB7B7B7)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, top: 20),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Container(
                            width: 300,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Choose pages or shops", style: TextStyle(fontSize: 18),),
                                SizedBox(height: 5),
                                Text("Choose pages or shops from POS to send messages.", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),)
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            DropdownOverlay(
                              width: 250,
                              isAnimated: true,
                              menuDirection: MenuDirection.start,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  constraints: new BoxConstraints(
                                    minWidth: 360,
                                  ),
                                  padding: EdgeInsets.only(left: 0, right: 0),
                                  decoration: BoxDecoration(
                                    color: isDark ? Color(0xff3D3D3D) : Color(0xffF3F3F3),
                                    borderRadius: BorderRadius.all(Radius.circular(5)),
                                    border: Border.all(
                                      color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                                      width: 1,
                                    ), 
                                  ),
                                  height: 40,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Container(
                                        child: Text(
                                          selectedShops.length > 0 ? "Selected shops (${selectedShops.length})" : "Choose shops or pages",
                                          style: TextStyle(fontSize: 14.5, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 100),
                                      Icon(Icons.arrow_drop_down, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, size: 20)
                                    ]
                                  )
                                ),
                              ),
                              dropdownWindow: StatefulBuilder(
                                builder: (context, setState) {

                                  return Container(
                                    constraints: new BoxConstraints(
                                      maxHeight: 300.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark ? Palette.backgroundTheardDark : Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
                                    ),
                                    child: shops.length > 0 ? SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          TextButton(
                                            style: ButtonStyle(
                                              overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                                              padding: MaterialStateProperty.all(EdgeInsets.zero)
                                            ),
                                            onPressed: () {
                                              List list = List.from(selectedShops);
                                              if (list.length > 0) list = [];
                                              else shops.forEach((element) => list.add(element["id"]));
                                              setState(() => selectedShops = list);
                                              this.setState(() => noShops = false);
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)),
                                              ),
                                              padding: EdgeInsets.all(12),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    selectedShops.length > 0 ? "Remove all shops" : "Select all shops",
                                                    style: TextStyle(
                                                      color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Container(
                                                    margin: EdgeInsets.only(right: 5),
                                                    child: Container(width: 16, height: 16)
                                                    // child: Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: shops.length,
                                            itemBuilder: (BuildContext context, int index) {
                                              var item = shops[index];
                                
                                              return TextButton(
                                                style: ButtonStyle(
                                                  overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                                                  padding: MaterialStateProperty.all(EdgeInsets.zero)
                                                ),
                                                onPressed: () {
                                                  final idx = selectedShops.indexWhere((e) => e == item["id"]);
                                                  List list = List.from(selectedShops);
                                                  if (idx != -1) list.removeAt(idx);
                                                  else list.add(item["id"]);
                                                  setState(() => selectedShops = list);
                                                  this.setState(() => noShops = false);
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border: index != shops.length - 1 ? Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)) : null,
                                                  ),
                                                  padding: EdgeInsets.all(12),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              child: ClipRRect(
                                                                borderRadius: BorderRadius.circular(100.0),
                                                                child: !Utils.checkedTypeEmpty(item["avatar_url"]) ? Image.asset(
                                                                  "assets/images/pos_app.png",
                                                                  width: 32,
                                                                  height: 32,
                                                                ) : CachedAvatar(
                                                                  item["avatar_url"],
                                                                  radius: 16,
                                                                  height: 32,
                                                                  width: 32,
                                                                  name: item["name"]
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(width: 10),
                                                            Flexible(
                                                              child: Text(
                                                                item["name"] ?? "No name",
                                                                style: TextStyle(
                                                                  color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Container(
                                                        margin: EdgeInsets.only(right: 15),
                                                        child: selectedShops.contains(item["id"])
                                                        ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                                        : Container(width: 16, height: 16)
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }
                                          ),
                                        ],
                                      ),
                                    ) : Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text("Tài khoản hiện tại chưa có shops."),
                                    )
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 10,),
                            if (Utils.checkedTypeEmpty(noShops)) Text("Chưa chọn shops", style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic, fontSize: 13))
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(color: isDark ? Color(0xff707070) : Color(0xFFB7B7B7)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, top: 20),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Container(
                            width: 300,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Option-post Pos in Panchat", style: TextStyle(fontSize: 18),),
                                SizedBox(height: 5),
                                Text("Automatically display full changes sent to/from this account.", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),)
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Theme(
                                          data: ThemeData(
                                            primarySwatch: Colors.blue,
                                            unselectedWidgetColor: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65) // Your color
                                          ),
                                          child: Transform.scale(
                                            scale: 0.9,
                                            child: Checkbox(
                                              value: isSendMessageWhenChangeStatusOrder,
                                              onChanged: (value) {setState(() => isSendMessageWhenChangeStatusOrder = !isSendMessageWhenChangeStatusOrder);},
                                            )
                                          )
                                        ),
                                        Expanded(
                                          child: Text(
                                            "Gửi tin nhắn khi thay đổi trạng thái đơn hàng",
                                            style: TextStyle(fontSize: 14.5, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, overflow: TextOverflow.ellipsis)
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 20,),
                                  Expanded(
                                    child: DropdownOverlay(
                                      width: 200,
                                      isAnimated: true,
                                      menuDirection: MenuDirection.start,
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isDark ? Palette.backgroundTheardDark : Colors.grey[200],
                                            borderRadius: BorderRadius.all(Radius.circular(8))
                                          ),
                                          constraints: new BoxConstraints(
                                            minWidth: 200,
                                          ),
                                          padding: EdgeInsets.only(left: 10, right: 10),
                                          height: 32,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              Icon(Icons.arrow_drop_down, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, size: 20),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Container(
                                                  child: Text(
                                                    statusOrderIds.length > 0 ? "Selected ${statusOrderIds.length} status" : "Choose a status...",
                                                    style: TextStyle(fontSize: 14.5, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ]
                                          )
                                        ),
                                      ),
                                      dropdownWindow: StatefulBuilder(
                                        builder: ((context, setState) {
                                          return Container(
                                            constraints: new BoxConstraints(
                                              maxHeight: 300.0,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark ? Palette.backgroundTheardDark : Colors.white,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
                                            ),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                children: [
                                                  TextButton(
                                                    style: ButtonStyle(
                                                      overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                                                      padding: MaterialStateProperty.all(EdgeInsets.zero)
                                                    ),
                                                    onPressed: () {
                                                      List statusIds = List.from(statusOrderIds);
                                                      if (statusIds.length > 0) statusIds = [];
                                                      else status.forEach((element) => statusIds.add(element["id"]));
                                                      setState(() => statusOrderIds = statusIds);
                                                      this.setState(() {noSelectOrderStatus = false;});
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        border: Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)),
                                                      ),
                                                      padding: EdgeInsets.all(12),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            statusOrderIds.length > 0 ? "Remove all status" : "Select all status",
                                                            style: TextStyle(
                                                              color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          Container(
                                                            margin: EdgeInsets.only(right: 5),
                                                            child: Container(width: 16, height: 16)
                                                            // child: Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  ListView.builder(
                                                    shrinkWrap: true,
                                                    itemCount: status.length, 
                                                    itemBuilder: (BuildContext context, int index) {
                                                      var item = status[index];

                                                      return TextButton(
                                                        style: ButtonStyle(
                                                          overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                                                          padding: MaterialStateProperty.all(EdgeInsets.zero)
                                                        ),
                                                        onPressed: () {
                                                          final idx = statusOrderIds.indexWhere((e) => e == item["id"]);
                                                          List statusIds = List.from(statusOrderIds);
                                                          if (idx != -1) statusIds.removeAt(idx);
                                                          else statusIds.add(item["id"]);
                                                          setState(() => statusOrderIds = statusIds);
                                                          this.setState(() {noSelectOrderStatus = false;});
                                                        },
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            border: index != status.length -1 ? Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)) : null,
                                                          ),
                                                          padding: EdgeInsets.all(12),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Text(
                                                                item["name"],
                                                                style: TextStyle(
                                                                  color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                              Container(
                                                                margin: EdgeInsets.only(right: 5),
                                                                child: statusOrderIds.contains(item["id"])
                                                                ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                                                : Container(width: 16, height: 16)
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  ),
                                                ],
                                              ),
                                            )
                                          );
                                        }),
                                      )
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Theme(
                                    data: ThemeData(
                                      primarySwatch: Colors.blue,
                                      unselectedWidgetColor: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65) // Your color
                                    ),
                                    child: Transform.scale(
                                      scale: 0.9,
                                      child: Checkbox(
                                        value: outForDelivery,
                                        onChanged: (value) => setState(() => outForDelivery = !outForDelivery),
                                      )
                                    )
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Gửi tin nhắn khi hàng tới kho đích.",
                                      style: TextStyle(fontSize: 14.5, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, overflow: TextOverflow.ellipsis)
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Theme(
                                    data: ThemeData(
                                      primarySwatch: Colors.blue,
                                      unselectedWidgetColor: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65) // Your color
                                    ),
                                    child: Transform.scale(
                                      scale: 0.9,
                                      child: Checkbox(
                                        value: undeliverable,
                                        onChanged: (value) => setState(() => undeliverable = !undeliverable),
                                      )
                                    )
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Gửi tin nhắn khi đơn giao không thành công.",
                                      style: TextStyle(fontSize: 14.5, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, overflow: TextOverflow.ellipsis)
                                    ),
                                  )
                                ],
                              ),
                              // SizedBox(height: 10),
                              // Row(
                              //   children: [
                              //     Theme(
                              //       data: ThemeData(
                              //         primarySwatch: Colors.blue,
                              //         unselectedWidgetColor: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65) // Your color
                              //       ),
                              //       child: Transform.scale(
                              //         scale: 0.9,
                              //         child: Checkbox(
                              //           value: isSendMessageWhenChangeStatusOrder,
                              //           onChanged: (value) {setState(() => isSendMessageWhenChangeStatusOrder = !isSendMessageWhenChangeStatusOrder);},
                              //         )
                              //       )
                              //     ),
                              //     Expanded(
                              //       child: Text(
                              //         "Gửi tin nhắn khi đơn không liên lạc được với khách hàng.",
                              //         style: TextStyle(fontSize: 14.5, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, overflow: TextOverflow.ellipsis)
                              //       ),
                              //     )
                              //   ],
                              // ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Theme(
                                    data: ThemeData(
                                      primarySwatch: Colors.blue,
                                      unselectedWidgetColor: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65) // Your color
                                    ),
                                    child: Transform.scale(
                                      scale: 0.9,
                                      child: Checkbox(
                                        value: canceled,
                                        onChanged: (value) => setState(() => canceled = !canceled),
                                      )
                                    )
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Gửi tin nhắn khi đơn báo khách huỷ không nhận hàng.",
                                      style: TextStyle(fontSize: 14.5, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, overflow: TextOverflow.ellipsis)
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Divider(color: isDark ? Color(0xff707070) : Color(0xFFB7B7B7)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, top: 20),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Container(
                            width: 300,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Preview Message", style: TextStyle(fontSize: 18),),
                                SizedBox(height: 5),
                                Text("Here's what messages from this integration will look like in Panchat.", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),)
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.only(top: 12, bottom: 12, left: 24, right: 24),
                            decoration: BoxDecoration(
                              color: isDark ? Palette.backgroundTheardDark : Colors.grey[200],
                              borderRadius: BorderRadius.all(Radius.circular(8))
                            ),
                            child: Row(
                              children: [
                                Container(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(100.0),
                                    child: Image.asset(
                                      "assets/images/pos_app.png",
                                      width: 36,
                                      height: 36,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text("POS", style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontWeight: FontWeight.w700, fontSize: 14),),
                                          SizedBox(width: 3,),
                                          Container(
                                            width: 42,
                                            height: 20,
                                            padding: EdgeInsets.only(left: 3, right: 3, top: 1, bottom: 1),
                                            decoration: BoxDecoration(
                                              color: isDark ? Color(0xff5E5E5E): Color(0xff828282),
                                              borderRadius: BorderRadius.all(Radius.circular(2))
                                            ),
                                            child: Center(child: Text("APPS", style: TextStyle(fontSize: 9),))
                                          ),
                                          SizedBox(width: 3,),
                                          Text("4:47 PM", style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Color(0xFF323F4B)),)
                                        ],
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        "This is what messages from this service will look like in Panchat. Good luck!!!",
                                        style: TextStyle(fontSize: 14.5, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, overflow: TextOverflow.ellipsis)
                                      )
                                    ],
                                  ),
                                )
                              ]
                            )
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(height: 30, child: Text(Utils.checkedTypeEmpty(noSelectOrderStatus) ? "Chưa chọn trạng thái gửi tin nhắn" : errorMessage ?? "", style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic, fontSize: 14))),
                  Container(
                    margin: EdgeInsets.only(bottom: 10),
                    height: 1,
                    color: isDark? Color(0xFF5E5E5E): Color(0xFFDBDBDB)
                  ),
                  Row(
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
                    SizedBox(width: 10,),
                      Container(
                        height: 34,
                        width: 117,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                             Color(0xff1890FF) 
                            ),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.0))
                            ),
                            padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 10, vertical: 8))
                          ),
                          child: loading
                            ? SpinKitFadingCircle(
                              color: isDark ? Colors.white60 : Color(0xff096DD9),
                              size: 19)
                            : Text(
                              "Save Settings",
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                color: !isDark ? Color.fromRGBO(0, 0, 0, 0.65) : Colors.white
                              )
                            ),
                          onPressed: loading ? null : () => onSaveSettingsPosApp(context, currentWorkspace["id"], currentChannel["id"]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ),
        )
      ),
    );
  }
}