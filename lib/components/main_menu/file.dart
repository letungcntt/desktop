import 'package:flutter/material.dart';
import 'package:workcake/components/main_menu/task_download.dart';
import 'package:workcake/data_channel_webrtc/list_device.dart';

class File extends StatefulWidget{

  @override
  _File  createState() => _File();
}

class _File extends State<File>{
  // List fileItems = [];

  // @override
  // void initState(){
  //   super.initState();
  //   Timer.run(() async {
  //     var appDocDirectory;

  //     if (Platform.isMacOS) appDocDirectory = await getDownloadsDirectory();
  //     var path = appDocDirectory.path;
  //     await processFiles(Directory(path).listSync()).then((value) {
  //       if(this.mounted) setState(() {
  //         fileItems = value;
  //       });
  //     });
  //   });
  // }
  

  //  processFiles(uriFiles) async{
  //   List result  = [];
  //   for(var i = 0; i < uriFiles.length; i++){
  //     var name  =  uriFiles[i].path.split("/").last;
  //     var type =  name.split(".").last;
  //     if (type  == null || type == "") continue;
  //     if (type  == "png" || type == "jpg" || type == "jpeg") type = "image";
  //     // check the path has existed
  //     var existed  =  fileItems.indexWhere((element) => element["path"] == uriFiles[i].path);
  //     if (existed != -1) continue;
  //     // image = "png, jpg, jpeg"
  //      result  += [{
  //       "name": name,
  //       "mime_type": type,
  //       "path": uriFiles[i].path,
  //     }];
  //   }
  //   return result;
  // }

  @override
  Widget build(BuildContext context){
    return Container(
      // width: 300,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Color(0xff3D3D3D)
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            ListDevices(),
            Container(
              padding: EdgeInsets.only(right: 16, left: 16),
              child: Column(
                children: [
                  Container(height: 30,),
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("File downloading", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  TaskDownload(showDownload:  true,),
                ]
              )
            )

            // Container(
            //   margin: EdgeInsets.all(8),
            //   child: Align(
            //     alignment: Alignment.centerLeft,
            //       child: Text("File downloaded", style: TextStyle(),
            //     ),
            //   ),
            // ),
            // Column(
            //   children: fileItems.map((e){
            //     return GestureDetector(
            //       onTap: () {
            //         if (Platform.isMacOS) Process.runSync('open', ['-R', e["path"]]);
            //         // else if (Platform.isWindows) Process.runSync('')
            //       },
            //       child: Container(
            //         margin: EdgeInsets.only(bottom: 8),
            //         padding:  EdgeInsets.all(8),
            //         decoration: BoxDecoration(
            //           color: Color(0xFF8c8c8c),
            //           borderRadius: BorderRadius.circular(8)
            //         ),
            //         width: 260,
            //         child:  Text(e["name"], style: TextStyle(color: Color(0xFFffffff)),
            //       )),
            //     );
            //   }).toList(),
            // )
          ],
        ),
      )
    );
  }
}




