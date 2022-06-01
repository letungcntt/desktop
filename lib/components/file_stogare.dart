import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileStorage {
  String type = 'txt';
  setType(String value) { type = value; }

  Future<String> get localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get localFile async {
    final path = await localPath;
    return File('$path/message_attachments.$type');
  }

  Future<String> readFile() async {
    try {
      final file = await localFile;
      String contents = await file.readAsString();

      return contents;
    } catch (e) {
      return '';
    }
  }

  Future<File> writeCounter(String message) async {
    final file = await localFile;
    return file.writeAsString(message);
  }
}