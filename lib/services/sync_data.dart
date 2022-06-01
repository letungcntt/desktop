import 'dart:async';
import 'package:flutter/material.dart';
class StreamSyncData extends ValueNotifier<Map>{

  static final instance = StreamSyncData();
  Map dataStatus = {};
  final _statusSyncController = StreamController<Map>.broadcast(sync: false);

  StreamSyncData(): super({});
  Stream<Map> get status => _statusSyncController.stream;

  initValue(){
    dataStatus = {};
    _statusSyncController.add(dataStatus);
  }

  setSyncStatus(int value){
    // print("value: $value, ${dataStatus.toString()}");
    dataStatus["receive"] = (dataStatus["receive"] ?? 0) + value;
    _statusSyncController.add(dataStatus);
  }

  setTotalMessage(int value){
    dataStatus["total"] = value;
    _statusSyncController.add(dataStatus);
  }


  Widget render(BuildContext context){
    return StreamBuilder(
      stream: StreamSyncData.instance.status,
      initialData: {
        "total": 0,
        "receive": 0
      },
      builder: (context, status){
        if (status.data ==  null) return Container();
        int total  = (((status.data ?? {}) as Map)["total"] ?? 0) as int;
        int receive  = (((status.data ?? {}) as Map)["receive"] ?? 0) as int;
        if (total == 0 && receive == 0) return Container();
        if (total <= receive) return Container();
        return Container(
          padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          color: Colors.white54.withOpacity(0.5),
          child: Text('Getting data $receive / $total messages', style: TextStyle(color: Colors.black54, fontSize: 9)),
        );
      }
    );
  }
}