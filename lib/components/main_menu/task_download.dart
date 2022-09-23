import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:workcake/components/main_menu/task_download_item.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/services/download_status.dart';

class TaskDownload extends StatefulWidget{
  final showDownload;

  TaskDownload({
    Key? key,
    this.showDownload,
  }): super(key: key);
  @override
  _TaskDownload createState() => _TaskDownload();
}

class _TaskDownload extends State<TaskDownload>{

  @override
  Widget build(BuildContext context) {
    List tasks = Provider.of<Work>(context, listen: true).taskDownload;

  return StreamBuilder(
    stream: StreamDownloadStatus.instance.status,
    initialData: {},
    builder: (context, data){

    return Container(
        // height: MediaQuery.of(context).size.height - 200,
        child: SingleChildScrollView(
          child: Column(
            children: tasks.map((e) {
              var id = e["id"];
              var progress = 0.0;
              if (data.data != null){
                progress = (data.data as Map?)![id] ?? 0.0;
              }
              return TaskDownloadItem(att: {...e, "progress": progress}, showDownload: widget.showDownload == null ? false : widget.showDownload);
            }).toList(),
          ),
        )
      );
    });
  }
}