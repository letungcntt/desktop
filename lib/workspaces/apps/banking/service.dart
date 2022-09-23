import 'package:dio/dio.dart';
import 'package:workcake/common/utils.dart';

class BankingService {
  static Future<List> getTransactions(int workspaceId, String token) async {
    try {
      String url = "${Utils.apiUrl}/workspaces/$workspaceId/get_transactions?token=$token";
      var res = await Dio().get(url);
      return res.data["data"];
    } catch (e, t) {
      print("getTransactions:$e, $t");
      return [];
    }

  }
}