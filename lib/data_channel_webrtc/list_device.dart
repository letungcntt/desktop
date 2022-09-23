import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/E2EE/e2ee.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/providers/providers.dart';
import '../common/utils.dart';
import 'device_socket.dart';

class ListDevices extends StatefulWidget {
  const ListDevices({ Key? key }) : super(key: key);

  @override
  State<ListDevices> createState() => _ListDevicesState();
}

class _ListDevicesState extends State<ListDevices> {

  @override
  void initState(){
    super.initState();
    Timer.run((){
      DeviceSocket.instance.channel!.push(event: "get_list_device");
    });
  }

  logoutDevice(String token, String targetDeviceId)async{
    // if (!await Utils.localAuth()) return;
    String url  = "${Utils.apiUrl}users/logout_device?token=$token";
    LazyBox box = Hive.lazyBox('pairkey');
    try{
      var res = await Dio().post(url, data: {
        "current_device": await box.get("deviceId"),
        "data": await Utils.encryptServer({"device_id": targetDeviceId})
      });
      if(res.data["success"]){
        DeviceSocket.instance.channel!.push(event: "get_list_device");
      }
    } catch(e){
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }
  @override
  Widget build(BuildContext context) {
    List<Device> devices = Provider.of<DeviceProvider>(context, listen: true).devices;
    Device? currentDevice;
    try {
      currentDevice = devices.firstWhere((element) => element.deviceId == Utils.deviceId);
    } catch (e) {
    }
    return Container(
      child: Container(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 62,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xffDBDBDB))) ,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: (){
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Icon(PhosphorIcons.arrowLeft, size: 20, color: Color(0xffEDEDED)),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            // await Navigator.push(context, MaterialPageRoute(builder: (context) => DMInfo(id: widget.id)));
                          },
                          child: Container(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  "Devices",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xffEDEDED)),
                                ),
                              ],
                          ),
                        ),
                      )),
                      InkWell(
                        onTap: () async {

                          },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Icon(PhosphorIcons.dotsThreeVerticalBold, color: Color(0xffEDEDED))
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Container(
                child: SingleChildScrollView(
                  child: Column(
                    children: (devices).map<Widget>((device){
                      return Container(
                        margin: EdgeInsets.all(8),
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Color(0xFF212121),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(device.name, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.white)),
                                  Row(
                                    children: [
                                      Text(device.platform, style: TextStyle(overflow: TextOverflow.ellipsis, fontSize: 10, color: Colors.white)),
                                      SizedBox(width: 3),
                                      Expanded(child: Text(device.deviceId, style: TextStyle(overflow: TextOverflow.ellipsis, fontSize: 10, color: Colors.white))),
                                    ],
                                  )
                                ],
                              ),
                            ),

                            Utils.deviceId == device.deviceId || currentDevice == null || !currentDevice.readyToUse ? Container() : StreamBuilder(
                              stream: DeviceSocket.instance.syncDataWebrtcStreamController.stream,
                              initialData: DataWebrtcStreamStatus("Connecting", DeviceSocket.instance.deviceId ?? "", DeviceSocket.instance.targetDevice ?? "", DeviceSocket.instance.sharedKeyCurrentVSTarget ?? ""),
                              builder: (context, snapshot){
                                DataWebrtcStreamStatus status = (snapshot.data as DataWebrtcStreamStatus?) ??  DataWebrtcStreamStatus("Connecting", DeviceSocket.instance.deviceId ?? "", DeviceSocket.instance.targetDevice ?? "", DeviceSocket.instance.sharedKeyCurrentVSTarget ?? "");
                                if (status.targetDeviceId != device.deviceId) {
                                  return InkWell(
                                    onTap: () async {
                                      LazyBox box  = Hive.lazyBox('pairKey');
                                      var idKey =  await box.get("identityKey");
                                      String sharedKey = (await X25519().calculateSharedSecret(KeyP.fromBase64(idKey["privKey"], false), KeyP.fromBase64(device.pubIdentityKey, true))).toBase64();
                                      DeviceSocket.instance.setPairDeviceId(device.deviceId, await Utils.getDeviceId(), sharedKey);
                                      DeviceSocket.instance.createOffer(
                                        () => MessageConversationServices.syncData(DeviceSocket.instance.localChannel!, sharedKey)
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 4, horizontal:8),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF1890ff),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      margin: EdgeInsets.only(left: 8),
                                      child: Text("Sync", style: TextStyle(fontSize: 12, color: Colors.white),)
                                    ),
                                  );
                                }
                                return Expanded(
                                  child: Container(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(status.status.toString().split("RTCDataChannel").last, style: TextStyle(overflow: TextOverflow.ellipsis, color: Colors.white))
                                    )
                                  )
                                );
                              }
                            ),
                            Utils.deviceId == device.deviceId || currentDevice == null || !currentDevice.readyToUse ? Container() : InkWell(
                              onTap: (){
                                logoutDevice(
                                  Provider.of<Auth>(context, listen: false).token,
                                  device.deviceId
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 4, horizontal:8),
                                decoration: BoxDecoration(
                                  color: Color(0xFFf5222d),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                margin: EdgeInsets.only(left: 8),
                                child: Text("Logout", style: TextStyle(fontSize: 12, color: Colors.white),),
                              ),
                            )
                          ],
                        ),
                      );
                    }).toList()
                    ,
                  ),
                ),
              ),
            ],
          )
        ),
      ),
    );
  }
}