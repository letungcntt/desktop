import 'package:path_provider/path_provider.dart';
import '../objectbox.g.dart';

class ServiceBox {
  static var box;
  static Future<Store> getObjectBox() async {
    if (box == null){
      var newDir = await getApplicationSupportDirectory();
      var newPath = newDir.path + "/pancake_chat_data";
      box =  await openStore(directory: newPath);
    }
    return box;
  }
}
