
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/http_exception.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/models/models.dart';

class TransferIssue extends StatefulWidget {
  const TransferIssue({
    Key? key,
    this.issue,
  }) : super(key: key);

  final issue;

  @override
  State<TransferIssue> createState() => _TransferIssueState();
}

class _TransferIssueState extends State<TransferIssue> {
  var selectedItem;

  onTransferIssue(selectedItem) async {
    final issueClosedTab = Provider.of<Work>(context, listen: false).issueClosedTab;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace; 
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final token = Provider.of<Auth>(context, listen: false).token;
    final workspaceId = currentWorkspace["id"];
    final channelId = widget.issue["channel_id"];
    final url = Utils.apiUrl + 'workspaces/$workspaceId/channels/$channelId/issues/transfer_issue?token=$token';

    try {
      var response = await Dio().post(url, data: {
        "selected_channel": selectedItem,
        "issue_id": widget.issue["id"]
      });

      var resData  =  response.data;

      if (resData["success"]) {
        this.setState(() {
          widget.issue["channel_id"] = selectedItem;
          selectedItem = null;
        });

        Provider.of<Channels>(context, listen: false).getListIssue(token, currentWorkspace["id"], currentChannel['id'], 1, issueClosedTab, [], "newest", "", false);
        Navigator.pop(context);
      } else {
        throw HttpException(resData["message"]);
      }
      
    } on HttpException catch (error) {
      print("This is http exception on transfer issue $error");
    } catch (e) {
      print(e.toString());
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    final data = Provider.of<Channels>(context, listen: true).data;
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    final channels = data.where((e) => e["workspace_id"] == currentWorkspace["id"] && (widget.issue["id"] != null && e["id"] != widget.issue["channel_id"])).toList();

    return HoverItem(
      colorHover: isDark ? Colors.white.withOpacity(0.15): Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) {
                return StatefulBuilder(
                  builder: (context, setState) {
                    return Dialog(
                      elevation: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xff3D3D3D) : Color(0xfffffffff),
                          borderRadius: BorderRadius.circular(5)
                        ),
                        width: 460,
                        height: 215,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(5),
                                  topLeft: Radius.circular(5),
                                ),
                              ),
                              padding: EdgeInsets.only(
                                left: 20.0
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Transfer this issue", 
                                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: isDark ? Colors.white.withOpacity(0.85) : Color(0xff3D3D3D))
                                  ),
                                  HoverItem(
                                    colorHover: isDark ? Color(0xff828282) : Color(0xffDBDBDB),
                                    child: IconButton(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      icon: Icon(Icons.close, size: 16, color: isDark ? Colors.white : Color(0xff3D3D3D),)
                                    ),
                                  )
                                ],
                              )
                            ),
                            Container(
                              height: 1,
                              color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  margin: EdgeInsets.only(top: 39, left: 18, right: 18, bottom: 39),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: isDark ? Color(0xff9E9696) : Color(0xffA6A6A6), width: 1),
                                    borderRadius: BorderRadius.circular(4)
                                  ),
                                  width: 225,
                                  child: DropdownButton<String>(
                                    hint: Text("Choose a channel"),
                                    dropdownColor: isDark ? Color(0xff3D3D3D) : Color(0xffF5F7FA),
                                    borderRadius: BorderRadius.circular(5),
                                    isDense: true,
                                    underline: Container(),
                                    // alignment: AlignmentDirectional.centerStart,
                                    value: selectedItem,
                                    onChanged: (String? string) => setState(() => selectedItem = string!),
                                    selectedItemBuilder: (BuildContext context) {
                                      return channels.map<Widget>((var channel) {
                                        return HoverItem(
                                          colorHover: null,
                                          child: Container(
                                            width: 185,
                                            child: Text(
                                              "${channel["name"]}",
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 14),
                                            )
                                          ),
                                        );
                                      }).toList();
                                    },
                                    items: channels.map((var channel) {
                                      return DropdownMenuItem<String>(
                                        // alignment: AlignmentDirectional.centerStart,
                                        child: Text("${channel["name"]}"),
                                        value: channel["id"].toString(),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              margin: EdgeInsets.only( left: 18, right: 18, ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3)
                              ),
                              width: 460,
                              height: 36,
                              child: TextButton(
                                onPressed: selectedItem != null ? () async {
                                  await onTransferIssue(selectedItem);
                                  Provider.of<Channels>(context, listen: false).onChangeOpenIssue(null);
                                } : null,
                                child: Text(
                                  "Transfer issue",
                                  style: TextStyle(fontSize: 15, color: selectedItem == null ? Color(0xff9AA5B1) : Colors.white),
                                ),
                                style: ButtonStyle(
                                  backgroundColor: selectedItem == null ? isDark ? MaterialStateProperty.all(Color(0xff5E5E5E)) : MaterialStateProperty.all(Color.fromARGB(255, 203, 206, 209)) : MaterialStateProperty.all(Color(0xff1888C7))
                                ),
                              )
                            )
                          ]
                        )
                      )
                    );
                  }
                );
              }
            );
          },
          child: Container(
            width: (MediaQuery.of(context).size.width *1/4),
            constraints: BoxConstraints(
              maxWidth: 300
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 3),
                Icon(Icons.arrow_forward, size: 18),
                SizedBox(width: 5),
                Text("Transfer issue")
              ],
            )
          ),
        ),
      ),
    );
  }
}
