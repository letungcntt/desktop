import 'dart:async';

// import 'package:dio/dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/http_exception.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';

class AppDetail extends StatefulWidget {
  final appId;

AppDetail({
    Key? key,
    @required this.appId
  });
  @override
  _AppDetailState createState() => _AppDetailState();
}

class _AppDetailState extends State<AppDetail>{
  Map dataApp = {
    "channels": [],
    "commands": [],
    "app": {}
  };

  double heightClientKey = 0;
  double heightCommands = 0;

  String _shortcut = "";
  String _requestUrl = "";
  String _description = "";

  bool _isChecked = false;
  List _commandParams = [
    {
      "key": ""
    }
  ];

  @override
  void initState() {
    super.initState();

    Timer.run(() async {
      final token = Provider.of<Auth>(context, listen: false).token;
      // get list Apps of user
      getDetailApp(token);
    });
  }

  getDetailApp(token)async {
    String url = "${Utils.apiUrl}app/${widget.appId}?token=$token";
    try {
      var response  =  await Dio().get(url);
      var resData  =  response.data;
      setState(() {
        dataApp =  resData["data"];
      });
      if(resData["success"] == false) throw HttpException(resData["message"]);
    } catch (e) {
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    return Container(
      color: isDark ? Color(0xFF353a3e) : Colors.white,
      child: Stack(
        children: [
          Container(
            color: isDark ? Color(0xFF353a3e) : Colors.white,
            margin: EdgeInsets.all(8),
            height: MediaQuery.of(context).size.height *3 /4,
            padding: EdgeInsets.only(top: 30, left: 5, right: 5, bottom: 0),
            child: ListView(
              children: [
                Column(
                  children: [
                    Text( 
                      dataApp["app"]["name"] ?? "",
                      style: TextStyle(fontSize: 30,fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[700])),
                    // 
                    Container(
                      margin: EdgeInsets.only(top: 10, bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {},
                              child:  Column(
                                children: [
                                  Text("${dataApp["channels"].length}", style: TextStyle(fontSize: 30, color: !isDark ? Color(0xFF242424) :  Colors.white),),
                                  Text(S.current.channelInstalled)
                                ],
                              ),
                            )
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  heightCommands  = heightCommands != 0 
                                      ? 0
                                      : dataApp["commands"].length.toDouble() * 50 + 20;
                                });
                              },
                              child: Column(
                                children: [
                                  Text("${dataApp["commands"].length}", style: TextStyle(fontSize: 30,  color: !isDark ? Color(0xFF242424) :  Colors.white),),
                                  Text(S.current.commands)
                                ],
                              ),
                            ) ,
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      padding: EdgeInsets.only(top: 10, bottom: 10, left: 8, right: 8),
                      height: heightCommands.toDouble(),
                      width: MediaQuery.of(context).size.width,
                      curve: Curves.fastOutSlowIn,
                      child: SingleChildScrollView(
                        child: Column(
                          children: dataApp["commands"].map<Widget>((command) {
                            var string = command["command_params"] != null ? command["command_params"].map((e) {
                              return "[${e["key"]}]";
                            }) : [];
                            return Container(
                              width: MediaQuery.of(context).size.width,
                              height: 50,
                              child: TextButton(
                                onPressed: (){},
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        children: [
                                          Container(
                                            constraints: BoxConstraints(maxWidth: 240),
                                            child: Text(
                                              "/${command["short_cut"] ?? ""}  (${command["request_url"]})",
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          ),
                                          Text(
                                            "${string.join(" ")}",
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Color(0xFF8C8C8C),
                                              fontWeight: FontWeight.w300,
                                              fontSize: 12
                                            )
                                          )
                                        ]
                                      ),
                                    ),
                                    Text(
                                      command["description"] ?? "",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Color(0xFF8C8C8C),
                                        fontWeight: FontWeight.w300,
                                        fontSize: 12
                                      )
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: (){},
                      child: Row(
                        children: [
                          Expanded(child: Text("Id"),),
                          Expanded(child: Text(dataApp["app"]["id"] ?? "", overflow:  TextOverflow.ellipsis, textAlign: TextAlign.right,) )
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: (){},
                      child: Row(
                        children: [
                        Expanded(child: Text(S.current.timeCreated),),
                        Expanded(child: Text(
                          Utils.checkedTypeEmpty(dataApp["app"]["create_time"])
                              ? DateFormatter().renderTime(DateTime.parse(dataApp["app"]["create_time"]), type: "dd-MM-yyyy")
                              : "Not set",
                          textAlign: TextAlign.right
                        ))
                        ],
                      ),
                    ),

                    TextButton(
                      onPressed: (){
                        setState(() {
                          if (heightClientKey == 0) heightClientKey  =  300;
                          else heightClientKey  = 0;
                        });
                      },
                      child: Row(
                        children: [
                          Expanded(child: Text("Client_key"),),
                          Expanded(child:  Text((dataApp["app"]["public_key"] ?? ""), overflow: TextOverflow.ellipsis, textAlign: TextAlign.right) )
                        ],
                      ),
                    ),
            
                    // time create
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      padding: EdgeInsets.only(top: 30, right: 10, left: 10),
                      height: heightClientKey,
                      curve: Curves.fastOutSlowIn,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.blueGrey.withOpacity(heightClientKey != 0 ? 1 : 0.5)
                      ),
                      child: Text((dataApp["app"]["public_key"] ?? ""))
                    )
                  ],
                ),
              ],
            )
          ),
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: Center(
              child: TextButton(
                onPressed: (){
                  showCreateApps(context, onSuccessCreateCommands);
                },
                child: Text(S.current.addCommands),
              ),
            )
          )
        ]
      ),
    );
    
  }

  onSuccessCreateCommands(app){
    setState(() {
      dataApp["commands"]  = [app] + dataApp["commands"];
    });
  }

  onAddParams() {
    _commandParams.add(
      {
        "key": ""
      }
    );
  }

  onRemoveParams() {
    int index = _commandParams.length;

    if (index > 1) {
      _commandParams.remove(
        _commandParams[index-1]
      );
    } 
  }

  showCreateApps(context, onSuccessCreateApp){
    onSave(shortcut, requestUrl, description) async {
      final token  =  Provider.of<Auth>(context, listen: false).token;

      _commandParams.removeWhere((e) => e["key"] == "");
      final paramsCommand = _isChecked ? (_commandParams.length > 0 ? _commandParams : null) : null;

      String url = "${Utils.apiUrl}app/${widget.appId}/commands?token=$token";
      try {
        var response  = await Dio().post(url, data: {
          "request_url": requestUrl?.trim() ?? "",
          "short_cut": shortcut?.trim() ?? "",
          "description": description?.trim() ?? "",
          "command_params": paramsCommand
        });

        var resData = response.data;
        if (resData["success"]){
          onSuccessCreateApp(resData["data"]);
          Navigator.of(context, rootNavigator: true).pop();
        }
        else{
          throw HttpException(resData["message"]);
        }

      } catch (e) {
        print(e);
        // sl.get<Auth>().showErrorDialog(e.toString());
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        final auth = Provider.of<Auth>(context, listen: true);
        final isDark = auth.theme == ThemeType.DARK;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              insetPadding: EdgeInsets.all(20),
              contentPadding: EdgeInsets.all(10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              backgroundColor: isDark ? Palette.defaultBackgroundDark : Palette.defaultBackgroundLight,
              content: Container(
                height: 500,
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.only(top: 10, bottom: 15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    S.current.createCommands.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? Colors.grey[300] : Colors.grey[700]
                                    )
                                  )
                                ]
                              ),
                              decoration:  BoxDecoration(border: Border(bottom: BorderSide(width: 0.2, color: Colors.grey))),
                            ),
                          ]
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _shortcut = value;
                            });
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(0),
                            labelText: S.current.shortcut
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _requestUrl = value;
                            });
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(0),
                            labelText: S.current.requestUrl
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _description = value;
                            });
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(0),
                            labelText: S.current.description
                          ),
                        ),
                      ),
                      Container(
                        child: CheckboxListTile(
                          title: Text(S.current.paramsCommand),
                          value: _isChecked,
                          onChanged: (value) {
                            setState(() {
                              _isChecked = value ?? _isChecked;
                            });
                          },
                        )
                      ),
                      _isChecked ? Container(
                        child: Column(
                          children: [
                            DataTable(
                              columns: [
                                DataColumn(label: Text(S.current.index)),
                                DataColumn(label: Text(S.current.params)),
                              ],
                              rows:
                                _commandParams.map(
                                  ((element) {
                                    var index = _commandParams.indexOf(element);
                                    return DataRow(
                                      cells: <DataCell>[
                                        DataCell(
                                          Container(
                                            padding: EdgeInsets.only(left: 2),
                                            child: Text("${index + 1}")
                                          )
                                        ),
                                        DataCell(
                                          Container(
                                            width: 320,
                                            child: CupertinoTextField(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.grey[400]!, width: 1)
                                              ),
                                              autofocus: true,
                                              onChanged: (value){
                                                element["key"] = value.trim();
                                              },
                                            )
                                          )
                                        ),
                                      ],
                                    );
                                  }),
                                ).toList(),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    onAddParams();
                                    setState(() {});  
                                  },
                                  child: Icon(Icons.add, color: isDark ? Colors.grey[300] : Colors.black54)
                                ),

                                TextButton(
                                  onPressed: () {
                                    onRemoveParams();
                                    setState(() {});  
                                  },
                                  child: Icon(Icons.remove, color: isDark ? Colors.grey[300] : Colors.black54)
                                ),
                              ],
                            )
                          ]
                        )
                      ) : Container(),
                      Container(
                        padding: EdgeInsets.only(left: 10, right: 10, top: 10),
                        width: MediaQuery.of(context).size.width,
                        child: TextButton(
                          style: ButtonStyle(
                            backgroundColor: Utils.getPrimaryColor(),
                          ),
                          onPressed: () {
                            if (Utils.checkedTypeEmpty(_shortcut) && Utils.checkedTypeEmpty(_requestUrl)) {
                              onSave(_shortcut, _requestUrl, _description);
                              setState(() {
                                _commandParams = [{
                                  "key": ""
                                }];
                                _isChecked = false;
                              });
                            }
                          },
                          child: Text(S.current.create, style: TextStyle(fontSize: 12, color: Colors.white))
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(10),
                        width: MediaQuery.of(context).size.width,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).pop();
                            setState(() {
                              _commandParams = [{
                                "key": ""
                              }];
                              _isChecked = false;
                            });
                          },
                          child: Text(S.current.cancel, style: TextStyle(fontSize: 12))
                        ),
                      )
                    ]
                  ),
                )
              ),
            );
          },
        );
      }
    );
  }
}


