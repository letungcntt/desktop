import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:workcake/common/http_exception.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/providers/providers.dart';

class CreateCommandView extends StatefulWidget {
  final createOrUpdateCommand;
  final appId;
  final command;

  CreateCommandView({
    Key? key,
    @required this.createOrUpdateCommand,
    @required this.appId,
    this.command
  });
  @override
  _CreateCommandViewState createState() => _CreateCommandViewState();
}

class _CreateCommandViewState extends State<CreateCommandView> {
  var _shortcut;
  var _requestUrl;
  var _description;
  String message = "";
  bool _isChecked = false;
  List _commandParams = [
    {
      "key": ""
    }
  ];
  List<String> methods = [
    'GET', 'POST', 'PUT', 'DELETE'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.command != null) {
      this.setState(() {
        _isChecked = (widget.command["command_params"] != null && widget.command["command_params"].length > 0);
        _commandParams = (widget.command["command_params"] != null && widget.command["command_params"].length > 0) ? widget.command["command_params"] : _commandParams;
        _description = widget.command["description"];
        _requestUrl = widget.command["request_url"];
        _shortcut = widget.command["short_cut"];
      });
    }
  }

  onAddParams() {
    _commandParams.add({
      "key": ""
    });
  }

  onRemoveParams() {
    int index = _commandParams.length;

    if (index > 1) {
      _commandParams.remove(
        _commandParams[index-1]
      );
    }
  }

  onSave(shortcut, requestUrl, description) async {
    final token  =  Provider.of<Auth>(context, listen: false).token;
    if (widget.command == null) _commandParams.removeWhere((e) => e["key"] == "");
    final paramsCommand = _isChecked ? (_commandParams.length > 0 ? _commandParams : null) : null;
    String url = "${Utils.apiUrl}app/${widget.appId}/${widget.command != null ? "update" : "commands"}?token=$token";

    try {
      var body = {
        "id": widget.command?["id"] ?? "",
        "request_url": requestUrl?.trim() ?? "",
        "short_cut": shortcut?.trim() ?? "",
        "description": description?.trim() ?? "",
        "command_params": paramsCommand,
        "app_id": widget.appId
      };
      var response  = await Dio().post(url, data: body);
      var resData = response.data;

      if (resData["success"]) {
        setState(() { message = ""; });
        widget.command != null ? widget.createOrUpdateCommand(body, true) : widget.createOrUpdateCommand(resData["data"], false);
        Navigator.of(context, rootNavigator: true).pop();
      } else{
        setState(() {
          message = resData["message"] ?? "";
        });
        throw HttpException(resData["message"]);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Container(
      width: 600,
      height: 628,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: 16,vertical: 10),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: isDark ? Color(0xff5E5E5E): Color(0xffF3F3F3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5.0),
                topRight: Radius.circular(5.0),
              ),
            ),

            child: Text(S.current.createCommands.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: "Roboto", fontWeight: FontWeight.w600)),
          ),
          Container(
            height: 588,
            color: isDark ? Color(0xff3D3D3D) : Color(0xffFFFFFF),
            // constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height - 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.current.shortcut, style: TextStyle(fontSize: 12, fontFamily: "Roboto", fontWeight: FontWeight.w400)),
                      SizedBox(height: 8),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? Color(0xff323F4B) : Color(0xffCBD2D9)),
                          borderRadius: BorderRadius.circular(2),
                          color: isDark ? Color(0xff2E2E2E) : Color(0xffEDEDED),
                        ),
                        child: TextFormField(
                          initialValue: _shortcut,
                          autofocus: true,
                          onChanged: (value) {
                            setState(() {
                              _shortcut = value;
                            });
                          },
                          style: TextStyle(color: isDark ? Color(0xffF5F7FA) : Color(0xff243B53), fontSize: 14, fontWeight: FontWeight.w400),
                          decoration: InputDecoration(
                            hintText: S.current.addShortcut,
                            hintStyle: TextStyle(color: Color(0xff828282)),
                            contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(2), bottomLeft: Radius.circular(2)), borderSide: BorderSide(color: isDark ? Color(0xff1F2933) : Color.fromRGBO(228, 231, 235, 0.4), style: BorderStyle.solid, width: 0.5)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(2), bottomLeft: Radius.circular(2)), borderSide: BorderSide(color: isDark ? Color(0xff1F2933) : Color.fromRGBO(228, 231, 235, 0.4), style: BorderStyle.solid, width: 0.5)),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(S.current.requestUrl, style: TextStyle(fontSize: 12, fontFamily: "Roboto", fontWeight: FontWeight.w400)),
                      SizedBox(height: 8),
                      Container(
                        height: 40,
                        child: Row(
                          children: [
                            Container(
                              child: DropdownButton<String>(
                                value: 'GET',
                                icon: Icon(Icons.arrow_drop_down, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, size: 20),
                                elevation: 16,
                                style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 13.5),
                                underline: Container(),
                                onChanged: (String? newValue) { },
                                items: methods.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              )
                            ),
                            SizedBox(width: 8,),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: isDark ? Color(0xff323F4B) : Color(0xffCBD2D9)),
                                  borderRadius: BorderRadius.circular(2),
                                  color: isDark ? Color(0xff2E2E2E) : Color(0xffEDEDED),
                                ),
                                child: TextFormField(
                                  initialValue: _requestUrl,
                                  onChanged: (value) {
                                    setState(() {
                                      _requestUrl = value;
                                    });
                                  },
                                  style: TextStyle(color: isDark ? Color(0xffF5F7FA) : Color(0xff243B53), fontSize: 14, fontWeight: FontWeight.w400),
                                  decoration: InputDecoration(
                                    hintText: S.current.addUrl,
                                    hintStyle: TextStyle(color: Color(0xff828282)),
                                    contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(2), bottomLeft: Radius.circular(2)), borderSide: BorderSide(color: isDark ? Color(0xff1F2933) : Color.fromRGBO(228, 231, 235, 0.4), style: BorderStyle.solid, width: 0.5)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(2), bottomLeft: Radius.circular(2)), borderSide: BorderSide(color: isDark ? Color(0xff1F2933) : Color.fromRGBO(228, 231, 235, 0.4), style: BorderStyle.solid, width: 0.5)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(S.current.description, style: TextStyle(fontSize: 12, fontFamily: "Roboto", fontWeight: FontWeight.w400)),
                      SizedBox(height: 8),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? Color(0xff323F4B) : Color(0xffCBD2D9)),
                          borderRadius: BorderRadius.circular(2),
                          color: isDark ? Color(0xff2E2E2E) : Color(0xffEDEDED),
                        ),
                        child: TextFormField(
                          initialValue: _description,
                          onChanged: (value) {
                            setState(() {
                              _description = value;
                            });
                          },
                          style: TextStyle(color: isDark ? Color(0xffF5F7FA) : Color(0xff243B53), fontSize: 14, fontWeight: FontWeight.w400),
                          decoration: InputDecoration(
                            hintText: S.current.addText,
                            hintStyle: TextStyle(color: Color(0xff828282)),
                            contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(2), bottomLeft: Radius.circular(2)), borderSide: BorderSide(color: isDark ? Color(0xff1F2933) : Color.fromRGBO(228, 231, 235, 0.4), style: BorderStyle.solid, width: 0.5)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(2), bottomLeft: Radius.circular(2)), borderSide: BorderSide(color: isDark ? Color(0xff1F2933) : Color.fromRGBO(228, 231, 235, 0.4), style: BorderStyle.solid, width: 0.5)),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Text(S.current.paramsCommand, style: TextStyle(fontSize: 12, fontFamily: "Roboto", fontWeight: FontWeight.w400)),
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              tristate: true,
                              onChanged: (newValue) {
                                this.setState(() { _isChecked = newValue ?? false; });
                              },
                              value: _isChecked
                            )
                          )
                        ]
                      ),
                      SizedBox(height: 6,),
                      _isChecked ? Container(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(S.current.index,  style: TextStyle(fontSize: 14, fontFamily: "Roboto", fontWeight: FontWeight.w600)),
                                  SizedBox(width: 22,),
                                  Text(S.current.params,  style: TextStyle(fontSize: 14, fontFamily: "Roboto", fontWeight: FontWeight.w600))
                                ],
                              ),
                            ),
                            SizedBox(height: 6,),
                            Container(
                              height: 118,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(top: 8),
                                shrinkWrap: true,
                                itemCount: _commandParams.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        index < 9 ? Center(
                                          child: Container(
                                            height: 40,
                                            width: 48,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: isDark ? Color(0xff323F4B) : Color(0xffCBD2D9)),
                                              borderRadius: BorderRadius.circular(2),
                                              color: isDark ? Color(0xff2E2E2E) : Color(0xffEDEDED),
                                            ),
                                            child: Center(child: Text("0${index + 1}", style: TextStyle(fontSize: 14, fontFamily: "Roboto")))),
                                        )
                                          : Center(child: Text("${index + 1}",  style: TextStyle(fontSize: 14, fontFamily: "Roboto", fontWeight: FontWeight.w600))),
                                        SizedBox(width: 12,),
                                        Container(
                                          height: 40,
                                          width: 488,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: isDark ? Color(0xff323F4B) : Color(0xffCBD2D9)),
                                            borderRadius: BorderRadius.circular(5),
                                            color: isDark ? Color(0xff2E2E2E) : Color(0xffEDEDED),
                                          ),
                                          child: TextFormField(
                                            cursorColor: Color(0xffA6A6A6),
                                            controller: TextEditingController(text: _commandParams[index]["key"] ?? ""),
                                            decoration: InputDecoration(
                                              hintStyle: TextStyle(color:  Color(0xffA6A6A6),fontWeight: FontWeight.w400,fontSize: 14),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              border: InputBorder.none,
                                              suffixIcon: InkWell(
                                                onTap: () {
                                                  onRemoveParams();
                                                  setState(() {});
                                                },
                                              child: Padding(
                                                padding: const EdgeInsets.only(right: 10),
                                                child: Icon(CupertinoIcons.xmark_circle,size: 16,),
                                              )),
                                            ),
                                            onChanged: (value) {
                                              _commandParams[index]["key"] = value.trim();
                                            }
                                          )
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              ),
                            ),
                            InkWell(
                              onTap: (){
                                onAddParams();
                                setState(() {});
                              },
                              child: Container(
                                height: 40,
                                width: 552,
                                margin: EdgeInsets.only(top: 24),

                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: isDark ? Color(0xffFAAD14) : Utils.getPrimaryColor(),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, color: isDark ? Color(0xffFAAD14) : Utils.getPrimaryColor(),size: 16,),
                                    Text(S.current.addParamsCommands,style: TextStyle(color: isDark ? Color(0xffFAAD14) : Utils.getPrimaryColor(),fontSize: 13),)
                                  ],
                                ),
                              ),
                            ),
                          ]
                        )
                      ) : Container(height: 204,),
                  ]),
                ),
                if (Utils.checkedTypeEmpty(message)) Text(message, style: TextStyle(color: Colors.red)),
                // Expanded(child: Container()),

                Expanded(
                  child: Container(
                    child: Column(
                      children: [
                        Container(
                          height: 1,
                          color: isDark ? Color(0xff5E5E5E): Color(0xffDBDBDB),
                        ),
                        SizedBox(height: 15,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(

                              child: TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _commandParams = [{
                                      "key": ""
                                    }];
                                    _isChecked = false;
                                  });
                                },
                                style: ButtonStyle(
                                  shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                      side: BorderSide(color: Color(0xffFF7875), width: 1),
                                      borderRadius: BorderRadius.circular(2)
                                    ),
                                  ),
                                  padding: MaterialStateProperty.all(
                                    EdgeInsets.symmetric(vertical: 16, horizontal: 24)
                                  )
                                ),
                                child: Text(S.current.cancel, style: TextStyle(color: Color(0xffFF7875), fontSize: 14, fontWeight: FontWeight.w400)),
                              ),
                            ),
                            SizedBox(width: 16),
                            Container(
                              margin: EdgeInsets.only(right: 24),
                              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 16),
                              decoration: BoxDecoration(
                                color:  Utils.getPrimaryColor(),
                                borderRadius: BorderRadius.circular(3)
                              ),
                              child: TextButton(
                                onPressed: () {
                                  if (Utils.checkedTypeEmpty(_shortcut) && Utils.checkedTypeEmpty(_requestUrl)) {
                                    onSave(_shortcut, _requestUrl, _description);
                                  }
                                },
                                child: Text(widget.command != null ? S.current.updateCommand  : S.current.createCommand, style: TextStyle(color: isDark ? Color(0xffFFFFFF) : Colors.white)),
                              )
                            )
                          ]
                        ),
                      ]
                    )
                  ),
                )
              ]
            )
          )
        ]
      )
    );
  }
}
