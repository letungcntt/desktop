import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/providers/providers.dart';

enum RadioOptionApp { Workspace, Channel }

class CreateAppView extends StatefulWidget {
  final onSuccessCreateApp;

  CreateAppView({Key? key, @required this.onSuccessCreateApp});
  @override
  _CreateAppViewState createState() => _CreateAppViewState();
}

class _CreateAppViewState extends State<CreateAppView> {
  var _nameChannel;
  RadioOptionApp _radioOptionApp = RadioOptionApp.Channel;

  onSave(appName, option) async {
    final token  =  Provider.of<Auth>(context, listen: false).token;
    final url = "${Utils.apiUrl}app?token=$token";
    try {
      var response  = await Dio().post(url, data: {
        "type": "custom",
        "name": appName,
        "is_workspace": option == RadioOptionApp.Channel ? false : true
      });

      var resData = response.data;
      if (resData["success"]){
        widget.onSuccessCreateApp(resData["data"]);
        Navigator.of(context, rootNavigator: true).pop("Discard");
      }
    } catch (e) {
      print(e);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  Widget _myRadioButton({var title, var value, var onChanged}) {
    return RadioListTile(
      value: value,
      groupValue: _radioOptionApp,
      onChanged: onChanged,
      title: Text(title, style: TextStyle(fontFamily: "Roboto", fontSize: 14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Container(
      height: 330,
      width: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: Offset(0, 3),
            blurRadius: 8
          )
        ]
      ),
      child: Column(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              )
            ),
            height: 40,
            width: MediaQuery.of(context).size.width,

            child: Center(child: Text(S.current.createCustomApp.toUpperCase(), style: TextStyle(fontFamily: "Roboto", fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white))),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Color(0xff3D3D3D) : Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                )
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 24,top:8),
                          child: Text(S.current.appName, style: TextStyle(fontFamily: "Roboto", fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                        SizedBox(height: 8),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 24,vertical: 8),
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: isDark ? Color(0xff323F4B) : Color(0xffCBD2D9)),
                            borderRadius: BorderRadius.circular(2),
                            color: isDark ? Color(0xff353535) : Color(0xffF5F7FA)
                          ),
                          child: TextFormField(
                            autofocus: true,
                            onChanged: (value) {
                              setState(() {
                                _nameChannel = value;
                              });
                            },
                            style: TextStyle(color: isDark ? Color(0xffF5F7FA) : Color(0xff243B53), fontSize: 14, fontWeight: FontWeight.w400),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(2), bottomLeft: Radius.circular(2)), borderSide: BorderSide(color: isDark ? Color(0xffCBD2D9) : Color(0xffF5F7FA), style: BorderStyle.solid, width: 0.5)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(2), bottomLeft: Radius.circular(2)), borderSide: BorderSide(color: isDark ? Color(0xffCBD2D9) : Color(0xffF5F7FA), style: BorderStyle.solid, width: 0.5)),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.only(left: 24),
                          child: Text(S.current.option, style: TextStyle(fontFamily: "Roboto", fontWeight: FontWeight.w600, fontSize: 14))),
                        SizedBox(height: 8),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 24,vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? Color(0xff353535) : Color(0xffF5F7FA),
                                    border: Border.all(
                                      color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: _myRadioButton(
                                  title: S.current.workspace,
                                  value: RadioOptionApp.Workspace,
                                  onChanged: (newValue) {
                                    setState(() => _radioOptionApp = newValue);
                                  },
                                  ),

                                ),
                              ),
                              SizedBox(width: 10,),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? Color(0xff353535) : Color(0xffF5F7FA),
                                    border: Border.all(
                                      color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: _myRadioButton(
                                    title: S.current.channel,
                                    value: RadioOptionApp.Channel,
                                    onChanged: (newValue) {
                                      print(newValue);
                                      setState(() => _radioOptionApp = newValue);
                                    },
                                  ),

                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 32),
                        Container(
                          color: isDark ? Color(0xff5E5E5E): Color(0xffDBDBDB),
                          height: 1,),
                          SizedBox(height: 22),
                        Container(
                          padding: EdgeInsets.only(right: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    child: TextButton(
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
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(S.current.cancel, style: TextStyle(color: Color(0xffFF7875), fontSize: 14, fontWeight: FontWeight.w400)),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 16),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color:  Utils.getPrimaryColor(),
                                ),
                                child: TextButton(
                                  onPressed: () {
                                    onSave(_nameChannel, _radioOptionApp);
                                  },
                                  style: ButtonStyle(
                                    padding: MaterialStateProperty.all(
                                      EdgeInsets.symmetric(vertical: 16, horizontal: 22)
                                    ),
                                  ),
                                  child: Text(S.current.createApp, style: TextStyle(color: isDark ? Color(0xff1F2933) : Colors.white)),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}