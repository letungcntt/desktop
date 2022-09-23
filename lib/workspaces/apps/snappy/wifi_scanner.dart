import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/workspaces/apps/snappy/service.dart';

class WifiScanner extends StatefulWidget {
  const WifiScanner({Key? key, required this.wifiConfig, required this.onChangeSelected}) : super(key: key);
  final Function onChangeSelected;
  final Map wifiConfig;

  @override
  State<WifiScanner> createState() => _WifiScannerState();
}

class _WifiScannerState extends State<WifiScanner> {

  bool isFetching = false;
  @override
  void initState(){
    super.initState();
    initData();
  }

  Future initData() async { 
    try {
      setState(() {
        isFetching = true;
      });
      List<Map> wifi = (Map.fromIterable(widget.wifiConfig["total"] + (await ServiceSnappy.getListAP()), key: (v) => v["bssid"], value: (v) => v as Map).values.toList());
      wifi.sort((a,b) => a["ssid"].compareTo(b["ssid"]));
      widget.wifiConfig["total"] = wifi;
      if (this.mounted) setState(() {
        isFetching = false;
      });

      await Future.delayed(Duration(seconds: 10));
      if (this.mounted) initData();
    } catch (e, t) {
      print("initData: $e, $t");
    }
    
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 20,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Select all access points of your workspace", style: TextStyle(fontSize: 12)),
              isFetching ?
               SpinKitFadingCircle(
                  color: Colors.white,
                  size: 16,
                )
              : Container()
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: widget.wifiConfig["total"].map<Widget>((e) => InkWell(
                onTap: (){
                  if (widget.wifiConfig["selected"][e["bssid"]] == null){
                    widget.wifiConfig["selected"][e["bssid"]] = e;
                  } else {
                    (widget.wifiConfig["selected"] as Map).remove(e["bssid"]);
                  }
                  setState(() { 
                  });
                },
                child: Container(
            
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFbfbfbf),)
                    )
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e["ssid"]),
                          Container(height: 4),
                          Text(e["bssid"], style: TextStyle(fontSize: 10,))
                        ],
                      ),
                      widget.wifiConfig["selected"][e["bssid"]] == null ? Container() : Icon(PhosphorIcons.check, size: 12,)
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }
}