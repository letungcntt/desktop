import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/providers/providers.dart';

class SnappyReviewRequest extends StatefulWidget {
  final requests;
  final isDark;
  final isRequestSent;
  final onChangeListRequest;
  const SnappyReviewRequest({Key? key, this.requests, this.isDark, this.isRequestSent, this.onChangeListRequest}) : super(key: key);

  @override
  State<SnappyReviewRequest> createState() => _SnappyReviewRequestState();
}

class _SnappyReviewRequestState extends State<SnappyReviewRequest> {
  bool isLoading1 = false;
  bool isLoading2 = false;

  handleRequest(request, status) async {
    if (status == "APPROVED") {
      setState(() => isLoading1 = true);
    } else {
      setState(() => isLoading2 = true);
    }
    final token = Provider.of<Auth>(context, listen: false).token;
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];

    final body = {
      'request_id': request['id'],
      'sender_id': request['sender_id'],
      'status': status
    };
    final url = Utils.apiUrl + 'workspaces/$workspaceId/handle_request?token=$token';
    try {
      final response = await Dio().post(url, data: body);
      var dataRes = response.data;
      if (dataRes["success"]) {
        widget.onChangeListRequest("minus", "pending", dataRes['data']);
        if (status == "APPROVED") {
          widget.onChangeListRequest("add", "approved", dataRes['data']);
        } else {
          widget.onChangeListRequest("add", "canceled", dataRes['data']);
        }
        setState(() {
          isLoading1 = false;
          isLoading2 = false;
        });
        Navigator.of(context, rootNavigator: true).pop("Discard");
      }
    } catch (e) {
      setState(() {
        isLoading1 = false;
        isLoading2 = false;
      });
      print("Error Channel: $e");
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = widget.requests;
    final isDark = widget.isDark;
    return Container(
      width: 600,
      padding: EdgeInsets.all(10),
      child: requests.length > 0
        ? SingleChildScrollView(
          child: Column(
            children: [
              ...requests.map((ele) {
                Map sender = {};
                final senderId = ele["sender_id"];
                final members = Provider.of<Workspaces>(context, listen: false).members;
                final index = members.indexWhere((element) => element["id"] == senderId);
                if (index != -1) {
                  sender = members[index];
                }
                return Card(
                  color: isDark ? null : Colors.grey[200],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 0.2, color: Colors.grey))),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("${ele['form_title']} của ${sender['full_name']}", style: TextStyle(fontSize: 15)),
                          ],
                        )
                      ),
                      ...ele["form_submit"].map((e) {
                        return Container(
                          padding: EdgeInsets.all(10),
                          child: Utils.renderElementForm(context, e, isDark)
                        );
                      }).toList(),
                      if (ele['status'] == "PENDING" && !widget.isRequestSent) Container(
                        decoration: BoxDecoration(border: Border(top: BorderSide(width: 0.2, color: Colors.grey))),
                        padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 11),
                        child: Row(
                          // mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              width: 100, height: 32,
                              margin: EdgeInsets.only(right: 12),
                              child: OutlinedButton(
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                                ),
                                onPressed: () => handleRequest(ele, "APPROVED"),
                                child: isLoading1
                                  ? Center(
                                      child: SpinKitFadingCircle(
                                        color: widget.isDark ? Colors.white60 : Color(0xff096DD9),
                                        size: 15,
                                      ))
                                  : Text(
                                      'Duyệt',
                                      style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                              ),
                            ),
                            Container(
                              width: 100, height: 32,
                              margin: EdgeInsets.only(right: 12),
                              child: OutlinedButton(
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(Colors.red),
                                ),
                                onPressed: () => handleRequest(ele, "CANCELED"),
                                child: isLoading2
                                  ? Center(
                                      child: SpinKitFadingCircle(
                                        color: widget.isDark ? Colors.white60 : Color(0xff096DD9),
                                        size: 15,
                                      ))
                                  : Text(
                                      'Từ chối',
                                      style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ]
          ),
        )
        : Center(
          child: Text("Không có yêu cầu duyệt."),
        ),
    );
  }
}