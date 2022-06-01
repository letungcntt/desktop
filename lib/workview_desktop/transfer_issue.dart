
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
      colorHover: isDark ? Color(0xff323F4B): Colors.grey[100],
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
                          color: isDark ? Color(0xff1F2933) : Colors.white,
                        ),
                        width: 460,
                        height: 400,
                        child: Column(
                          children: [
                            Container(
                                color: Color(0xff52606D),
                              padding: EdgeInsets.only(
                                top: 8.0,
                                bottom: 8.0,
                                left: 20.0
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Transfer this issue", 
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white.withOpacity(0.85))
                                  ),
                                  IconButton(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    icon: Icon(Icons.close, size: 16, color: Colors.white,)
                                  )
                                ],
                              )
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  margin: EdgeInsets.symmetric(vertical: 20, horizontal: 18),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!, width: 1),
                                    borderRadius: BorderRadius.circular(3)
                                  ),
                                  width: 178,
                                  child: DropdownButton<String>(
                                    hint: Text("Choose a channel"),
                                    dropdownColor: isDark ? Color(0xff1F2933) : Color(0xffF5F7FA),
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
                                            width: 140,
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
                                        child: Container(
                                          child: Text("${channel["name"]}")
                                        ),
                                        value: channel["id"].toString(),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 16, horizontal: 18),
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
                                  backgroundColor: selectedItem == null ? isDark ? MaterialStateProperty.all(Color(0xff616E7C)) : MaterialStateProperty.all(Color(0xffE4E7EB)) : MaterialStateProperty.all(Color(0xff2A5298))
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
