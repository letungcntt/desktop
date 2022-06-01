import 'dart:async';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as gdrive;
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
import 'package:http/http.dart' as http;

import 'package:http/http.dart';

import 'model.dart';

class DriveService {
  static gdrive.DriveApi? instance;


  static login() async {
    // GoogleSignInArgs arg = GoogleSignInArgs(
    //   clientId: '592269086567-n7q8u3mde17eo7cn2dloj5kbmkniejbo.apps.googleusercontent.com',
    //   redirectUri: 'https://chat.pancake.vn/api/google_auth',
    //   scope: 'https://www.googleapis.com/auth/drive.appdata'
    // );

    // final result = await DesktopWebviewAuth.signIn(arg);
    // if (result == null) return;
    // final gapis.AccessCredentials credentials = gapis.AccessCredentials(
    //   gapis.AccessToken(
    //     'Bearer',
    //     result.accessToken ?? "",
    //     DateTime.now().toUtc().add(const Duration(days: 365)),
    //   ),
    //   null, // We don't have a refreshToken
    //   ['https://www.googleapis.com/auth/drive.appdata'],
    // );
    // var r = gapis.authenticatedClient(http.Client(), credentials);

    // DriveService.instance = gdrive.DriveApi(r);
    // new Timer(new Duration(hours: 1), () {
    //   DriveService.instance = null;
    // });
    return  null;
  }

  static setDataLogin(String accessToken){
     final gapis.AccessCredentials credentials = gapis.AccessCredentials(
      gapis.AccessToken(
        'Bearer',
        accessToken,
        DateTime.now().toUtc().add(const Duration(days: 365)),
      ),
      null, // We don't have a refreshToken
      ['https://www.googleapis.com/auth/drive.appdata'],
    );
    var r = gapis.authenticatedClient(http.Client(), credentials);

    DriveService.instance = gdrive.DriveApi(r);
    new Timer(new Duration(hours: 1), () {
      DriveService.instance = null;
    });
  }

  static uploadFile(Media file) async {
    if (DriveService.instance == null) await DriveService.login();
    if (DriveService.instance == null) return;

    gdrive.File f = gdrive.File();
    f.name = file.name;
    f.parents = ["appDataFolder"];

    final fileList = await DriveService.instance!.files.list(spaces: 'appDataFolder', q: "name='${file.name}'", $fields: 'files(id, name, modifiedTime)');
    List existedFileWithName = fileList.files ?? [];
    await Future.wait(existedFileWithName.map((e) => DriveService.instance!.files.delete( (e as gdrive.File).id ?? "")));
    await DriveService.instance!.files.create(
      f,
      uploadMedia: gdrive.Media(File(file.pathInDevice ?? "").openRead(), file.size),
    );
  }

  static Future<gdrive.File?> getFileBackUpMessage({String backupName = "backup_message_v1_encrypted.text"}) async {
    if (DriveService.instance == null) await DriveService.login();
    if (DriveService.instance == null) return null;
    final fileList = await DriveService.instance!.files.list(spaces: 'appDataFolder', q: "name='$backupName'", $fields: 'files(id, name, modifiedTime)');
    List existedFileWithName = fileList.files ?? [];
    if (existedFileWithName.length == 0) return null;
    return existedFileWithName[0];
  }

  static Future<List<int>?> getContentFile(String fileId) async {
    try {
      if (DriveService.instance == null) await DriveService.login();
      if (DriveService.instance == null) return null;
      gdrive.Media i = await DriveService.instance!.files.get(fileId, downloadOptions: gdrive.DownloadOptions.fullMedia) as gdrive.Media; 
      return (await (i.stream as ByteStream).toBytes());      
    } catch (e) {
      return null;
    }
  }

}