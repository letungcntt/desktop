import 'dart:convert';
import 'dart:io';
import 'package:better_selection/better_selection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/common/validators.dart';
import 'package:workcake/components/check_verify_phone_number.dart';
import 'package:workcake/components/crop_image_dialog.dart';
import 'package:workcake/components/widget_text.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/login_macOS.dart';
import 'package:workcake/models/models.dart';

class EditProfileDialog extends StatefulWidget {
  EditProfileDialog({Key? key}) : super(key: key);

  @override
  _EditProfileDialogState createState() => _EditProfileDialogState();
}

enum Themes { Auto, Light, Dark }

class _EditProfileDialogState extends State<EditProfileDialog> {
  Color nameColor = Color.fromARGB(255, 0, 0, 0);
  double sliderPosition = 0.0;
  List images = [];
  var dateTime;
  var body;
  var _themesType;
  var customIdError ="";
  var fullNameError ="";
  var phoneError = "";
  String tagNameInput = "";

  
  @override
  void initState() {
    super.initState();
    final auth = Provider.of<Auth>(context, listen: false);
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    sliderPosition = currentUser['position'];
    final isDark = auth.theme == ThemeType.DARK;
    body = new Map.from(currentUser);
    nameColor = body["custom_color"] == "default" 
    ? isDark 
      ? Color(0xffF5F7FA)
      : Color(0xff243B53)
    : Color(int.parse("0xff${body["custom_color"]}"));

    dateTime = Utils.checkedTypeEmpty(currentUser["date_of_birth"]) ? DateFormatter().renderTime(DateTime.parse(currentUser["date_of_birth"]), type: "yMMMd") : "--/--/--";
    var theme = Provider.of<Auth>(context, listen: false).theme;
    bool isAutoTheme = Provider.of<Auth>(context, listen: false).isAutoTheme;
  
    if(isAutoTheme == true) {
      _themesType = Themes.Auto;
    } else {
      if(theme == ThemeType.DARK) {
        _themesType = Themes.Dark;
      } else {
        _themesType = Themes.Light;
      }
    }
  }

  onChangeColor(color) {
    setState(() {
      body["custom_color"] = color;
    });
  }

  _selectDate(BuildContext context, date) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: Utils.checkedTypeEmpty(date)
          ? DateTime.parse(date)
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if(picked == null) {
      return;
    }

    final dateFormatted = DateFormatter().renderTime(DateTime.parse("$picked"), type: "yMMMd");
    if (dateFormatted != "" && dateFormatted != dateTime) {
      setState(() {
        dateTime = dateFormatted;
        body["date_of_birth"] = DateFormatter().renderTime(DateTime.parse("$picked"), type: "yyyy-MM-dd");
      });
    }
  }

  uploadAvatar(token, workspaceId) async {
    List list = images;

    this.setState(() { images = []; });

    for (var item in list) {
      String imageData = base64.encode(item["file"]);

      if (item["file"].lengthInBytes > 10000000) {
        final uploadFile = {
          "filename": item["name"],
          "path": imageData,
          "length": imageData.length,
        };
        await Provider.of<User>(context, listen: false).uploadAvatar(token, workspaceId, uploadFile, "image");
      } else {
        final uploadFile = {
          "filename": item["name"],
          "path": imageData,
          "length": imageData.length,
        };
        await Provider.of<User>(context, listen: false).uploadAvatar(token, workspaceId, uploadFile, "image");
      }
    }
  }

  openFileSelector(workspaceId) async {
    List resultList = [];
    final auth = Provider.of<Auth>(context, listen: false);
    
    try {

      var myMultipleFiles =  await Utils.openFilePicker([
        XTypeGroup(
          extensions: ['jpg', 'jpeg', 'png'],
        )
      ]);
      for (var e in myMultipleFiles) {
        Map newFile = {
          "name": e["name"],
          "file": e["file"],
          "path": e["path"]
        };
        resultList.add(newFile);
      }

      if(resultList.length > 0) {
        final image = resultList[0];
        String imageData = base64.encode(image["file"]);

        if (image["file"].lengthInBytes > 10000000) {
          final uploadFile = {
            "filename": image["name"],
            "path": imageData,
            "length": imageData.length,
          };
          await Provider.of<User>(context, listen: false).uploadAvatar(auth.token, workspaceId, uploadFile, "image");
        } else {
          final uploadFile = {
            "filename": image["name"],
            "path": imageData,
            "length": imageData.length,
          };
          await Provider.of<User>(context, listen: false).uploadAvatar(auth.token, workspaceId, uploadFile, "image");
        }
      }
    } on Exception catch (e) {
      print("$e Cancel");
    }
  }

  _updateUserInfo() async {
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    if (customIdError == "" && tagNameInput != "") {
        body["custom_id"] = tagNameInput;
    }
    
    if (body["custom_id"].runtimeType == String) {
      body["custom_id"] = int.parse(body["custom_id"]);
    }

    if (body["avatar_url"] != currentUser["avatar_url"]) {
      body["avatar_url"] = currentUser["avatar_url"];
    }

    final keyColor = nameColor.toString().substring(10,16);
    if (keyColor != currentUser["custom_color"]) {
      body["custom_color"] = keyColor;
    }

    final auth = Provider.of<Auth>(context, listen: false);
    var response = await Provider.of<User>(context, listen: false).changeProfileInfo(auth.token, body);
    if (response == null) return;
    if (response["success"] && mounted) {
      Provider.of<User>(context, listen: false).onChangeSliderPosition(sliderPosition);
      S.load(Locale(body["locale"]));
      Provider.of<Auth>(context, listen: false).locale = body['locale'];
      Navigator.pop(context);
    } else {
      setState(() => {customIdError = response["message"]});
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentWorkspace = Provider.of<Workspaces>(context).currentWorkspace;
    final data = Provider.of<Workspaces>(context).data;
    final workspaceId = currentWorkspace["id"] ?? (data.length > 0 ? data[0]["id"] : "");
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    TextStyle labelStyle = TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 14, fontWeight: FontWeight.w500);
    final currentUser = Provider.of<User>(context, listen: true).currentUser;
    final isVerifiedEmail = currentUser["is_verified_email"] is bool ? currentUser["is_verified_email"] : currentUser["is_verified_email"] == 'true';
    final isVerifiedPhoneNumber = currentUser["is_verified_phone_number"] is bool ? currentUser["is_verified_phone_number"] : currentUser["is_verified_phone_number"] == 'true';

    final bool isInfoValidated = fullNameError.length == 0 && customIdError.length == 0 && phoneError.length == 0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isDark ? Palette.backgroundRightSiderDark :  Palette.backgroundRightSiderLight,
      ),
      width: 798,
      height: 570,
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0)
              ),
              color: isDark ? Palette.borderSideColorDark : Palette.defaultTextDark,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(S.current.userProfile, style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight, fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                Container(
                  padding: EdgeInsets.only(right: 12),
                  alignment: Alignment.centerRight,
                  child: HoverItem(
                    colorHover: isDark ? Color(0xff828282) : Color(0xffDBDBDB),
                    child: IconButton(
                      onPressed: (){
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        PhosphorIcons.xCircle,
                        size: 20.0,
                      ),
                    )
                  )
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight))),
            padding: EdgeInsets.only(left: 32),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 19),
                      child: Stack(
                        children: [
                          Container(
                            child: CachedAvatar(
                              currentUser["avatar_url"],
                              height: 136,
                              width: 136,
                              radius: 3,
                              fontSize: 48,
                              name: currentUser["full_name"]
                            ),
                          ),
                          Positioned(
                            left: 100,
                            bottom: 98,
                            child: UploadIcon(isDark: isDark, onPressed: (){
                              openFileSelector(workspaceId);
                            })
                          )
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                          child: Text("Color Picker", style: labelStyle),
                        ),
                        Container(
                          height: 40,
                          width: 351,
                          child: Column(
                            children: [
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: nameColor,
                                      border: Border.all(width: 0.5, color: isDark ? const Color(0x00000000) : Color(0xffC9C9C9)),
                                      borderRadius: BorderRadius.circular(4),
                                    )
                                  ),
                                  SizedBox(width: 8),
                                  ColorPicker(
                                    initValue: nameColor,
                                    position: sliderPosition,
                                    width: 303, height: 24, 
                                    onChanged: (Map data) {
                                      setState(() {
                                        nameColor = data["currentColor"];
                                        sliderPosition = data["colorSliderPosition"];
                                      });
                                    }
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                          child: Text("Theme", style: labelStyle),
                        ),
                        Row(
                          children: [
                            Container(
                              height: 40,
                              width: 111,
                              decoration: BoxDecoration(
                                color: isDark ? Color(0xFF353535) : Color(0xffFAFAFA),
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                                border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9)),
                              ),
                              child: HoverItem(
                                colorHover: isDark ?Color(0xff5E5E5E) : Color(0xffEDEDED),
                                child: InkWell(
                                  onTap:(){
                                    setState(() {
                                      _themesType = Themes.Auto;
                                      Provider.of<Auth>(context, listen: false).setIsAutoTheme(true);
                                    });
                                    var currentTheme = MediaQuery.of(context).platformBrightness == Brightness.dark ? "NSAppearanceNameDarkAqua" : "NSAppearanceNameAqua" ;
                                    Provider.of<Auth>(context, listen: false).onChangeCurrentTheme(currentTheme, true);
                                    Provider.of<User>(context, listen: false).updateTheme(auth.token, "auto");
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                        child: Text("Auto", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 16)),
                                      ),
                                      Transform.scale(
                                        scale: 0.8,
                                        child: Radio(
                                          overlayColor: MaterialStateProperty.all(Colors.transparent),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          value: Themes.Auto,
                                          activeColor: isDark ? Color(0xffFAAD14) : Colors.blue,
                                          groupValue: _themesType,
                                          onChanged: (value) {
                                            setState(() {
                                              _themesType = value;
                                              Provider.of<Auth>(context, listen: false).setIsAutoTheme(true);
                                            });
                                            var currentTheme = MediaQuery.of(context).platformBrightness == Brightness.dark ? "NSAppearanceNameDarkAqua" : "NSAppearanceNameAqua" ;
                                            Provider.of<Auth>(context, listen: false).onChangeCurrentTheme(currentTheme, true);
                                            Provider.of<User>(context, listen: false).updateTheme(auth.token, "auto");
                                          },
                                        ),
                                      ),
                                    ]
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 9),
                            Container(
                              height: 40,
                              width: 111,
                              decoration: BoxDecoration(
                                color: isDark ? Color(0xFF353535) : Color(0xffFAFAFA),
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                                border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9)),
                              ),
                              child: HoverItem(
                                colorHover: isDark ?Color(0xff5E5E5E) : Color(0xffEDEDED),
                                child: InkWell( // bọc InkWell. 
                                  onTap: (){
                                    setState(() {
                                      _themesType = Themes.Light;
                                    });
                                    Provider.of<Auth>(context, listen: false).isAutoTheme = false;
                                    Provider.of<Auth>(context, listen: false).theme = ThemeType.LIGHT;
                                    Provider.of<User>(context, listen: false).updateTheme(auth.token, "light");
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                        child: Text("Light", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 16)),
                                      ),
                                      Transform.scale(
                                        scale: 0.8,
                                        child: Radio(
                                          overlayColor: MaterialStateProperty.all(Colors.transparent),
                                          materialTapTargetSize: MaterialTapTargetSize.padded,
                                          value: Themes.Light,
                                          activeColor: isDark ? Color(0xffFAAD14) : Colors.blue,
                                          groupValue: _themesType,
                                          onChanged: (value) {
                                            setState(() {
                                              _themesType = value;
                                            });
                                            Provider.of<Auth>(context, listen: false).isAutoTheme = false;
                                            Provider.of<Auth>(context, listen: false).theme = ThemeType.LIGHT;
                                            Provider.of<User>(context, listen: false).updateTheme(auth.token, "light");
                                          },
                                        ),
                                      ),
                                    ]
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 9),
                            Container(
                              height: 40,
                              width: 111,
                              decoration: BoxDecoration(
                                color: isDark ? Color(0xFF353535) : Color(0xffFAFAFA),
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                                border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9)),
                              ),
                              child: HoverItem(
                                colorHover: isDark ?Color(0xff5E5E5E) : Color(0xffEDEDED),
                                child: InkWell(
                                  onTap: (){
                                    setState(() {
                                      Provider.of<Auth>(context, listen: false).isAutoTheme = false;
                                      Provider.of<Auth>(context, listen: false).theme = ThemeType.DARK;
                                      _themesType = Themes.Dark;
                                    });
                                    Provider.of<Auth>(context, listen: false).isAutoTheme = false;
                                    Provider.of<Auth>(context, listen: false).theme = ThemeType.DARK;
                                    Provider.of<User>(context, listen: false).updateTheme(auth.token, "dark");
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                        child: Text("Dark", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 16)),
                                      ),
                                      Transform.scale(
                                        scale: 0.8,
                                        child: Radio(
                                          overlayColor: MaterialStateProperty.all(Colors.transparent),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          value: Themes.Dark,
                                          activeColor: isDark ? Color(0xffFAAD14) : Colors.blue,
                                          groupValue: _themesType,
                                          onChanged: (value) {
                                            setState(() {
                                              Provider.of<Auth>(context, listen: false).isAutoTheme = false;
                                              Provider.of<Auth>(context, listen: false).theme = ThemeType.DARK;
                                              _themesType = value;
                                            });
                                            Provider.of<Auth>(context, listen: false).isAutoTheme = false;
                                            Provider.of<Auth>(context, listen: false).theme = ThemeType.DARK;
                                            Provider.of<User>(context, listen: false).updateTheme(auth.token, "dark");
                                          },
                                        ),
                                      ),
                                    ]
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                          child: Text("Languages", style: labelStyle),
                        ),
                        Row(
                          children: [
                            Container(
                              height: 40,
                              width: 171,
                              decoration: BoxDecoration(
                                color: isDark ? Color(0xFF353535) : Color(0xffFAFAFA),
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                                border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9)),
                              ),
                              child: HoverItem(
                                colorHover: isDark ?Color(0xff5E5E5E) : Color(0xffEDEDED),
                                child: InkWell(
                                  onTap:(){
                                    setState((){
                                      body["locale"] = "vi";
                                    });
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                        child: Text("Vietnamese", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 16)),
                                      ),
                                      Transform.scale(
                                        scale: 0.8,
                                        child: Radio(
                                          overlayColor: MaterialStateProperty.all(Colors.transparent),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          activeColor: isDark ? Color(0xffFAAD14) : Colors.blue,
                                          value: "vi",
                                          groupValue: body["locale"],
                                          onChanged: (value) {
                                            setState((){
                                              body["locale"] = "vi";
                                            });
                                          },
                                        ),
                                      ),
                                    ]
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 9),
                            Container(
                              height: 40,
                              width: 171,
                              decoration: BoxDecoration(
                                color: isDark ? Color(0xFF353535) : Color(0xffFAFAFA),
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                                border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9)),
                              ),
                              child: HoverItem(
                                colorHover: isDark ?Color(0xff5E5E5E) : Color(0xffEDEDED),
                                child: InkWell(
                                  onTap: (){
                                    setState((){
                                      body["locale"] = "en";
                                    });
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                        child: Text("English", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 16)),
                                      ),
                                      Transform.scale(
                                        scale: 0.8,
                                        child: Radio(
                                          overlayColor: MaterialStateProperty.all(Colors.transparent),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          activeColor: isDark ? Color(0xffFAAD14) : Colors.blue,
                                          value: "en",
                                          groupValue: body["locale"],
                                          onChanged: (value) {
                                            setState((){
                                              body["locale"] = "en";
                                            });
                                          },
                                        ),
                                      ),
                                    ]
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ]
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 28, horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                                child: Text("Your name", style: labelStyle),
                              ),
                              Container(
                                height: 40,
                                width: 275,
                                child: TextFormField(
                                  style: TextStyle(
                                    color: nameColor,
                                    fontSize: 14 
                                    ),
                                  initialValue: currentUser["full_name"],
                                  onChanged: (value) {
                                    body["full_name"] = value;
                                    bool isError = value.length < 2 || value.length > 32 ? true : false;
                                    if(isError) {
                                      setState(() {
                                        fullNameError = "Full name is not valid";
                                      });
                                    } else {
                                      setState(() {
                                        fullNameError = "";
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hoverColor: isDark ?Color(0xff5E5E5E) : Color(0xffEDEDED),
                                    contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                    filled: true,
                                    fillColor: isDark ? Color(0xFF353535) : Color(0xffFAFAFA),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9)),
                                      borderRadius: BorderRadius.all(Radius.circular(4))),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9)),
                                      borderRadius: BorderRadius.all(Radius.circular(4)))
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 9),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                                child: Text("Tag name", style: labelStyle),
                              ),
                              Container(
                                height: 40,
                                width: 68,
                                child: TextFormField(
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  onChanged: (value) {
                                    tagNameInput = value;
                                    if(value.length > 0 && value[0] == "0") {
                                      setState(() {
                                        customIdError = "Tag id can't begin with 0";
                                      });
                                    } else if(!RegExp(r'^[0-9]+$').hasMatch("$value") && value.length > 0) {
                                      setState(() {
                                        customIdError = "Tag id must be integer";
                                      });
                                    } else if(value.length != 4) {
                                      setState(() {
                                        customIdError = "Tag id must be 4 characters";
                                      });
                                    } else {
                                      setState(() {
                                        customIdError = "";
                                      });
                                    }
                                  },
                                  initialValue: "${currentUser["custom_id"]}",
                                  style: TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hoverColor: isDark ?Color(0xff5E5E5E) : Color(0xffEDEDED),
                                    prefix: Text("#", style: TextStyle(fontSize: 14)),
                                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    filled: true,
                                    fillColor: isDark ? Color(0xFF353535) : Color(0xffFAFAFA),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9)),
                                      borderRadius: BorderRadius.all(Radius.circular(4))),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9)),
                                      borderRadius: BorderRadius.all(Radius.circular(4)))
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 2),
                        height: 15, 
                        child: Text(customIdError, style: TextStyle(fontSize: 11, color: Colors.red))
                      ),
                      FormInput(
                        labelStyle: labelStyle,
                        isDark: isDark,
                        verifyType: "email",
                        isVerified: isVerifiedEmail,
                        labelContent: "Email",
                        initialValue: currentUser["email"],
                        readOnly: isVerifiedEmail
                      ),
                      FormInput(
                        labelStyle: labelStyle,
                        isDark: isDark,
                        readOnly: isVerifiedPhoneNumber,
                        verifyType: "phoneNumber",
                        isVerified: isVerifiedPhoneNumber,
                        labelContent: "Phone number",
                        isError: phoneError != "" ? true : false,
                        initialValue: currentUser["phone_number"],
                        errorMessage: phoneError,
                        onChanged: (value) {
                          body["phone_number"] = value;
                          if((body["phone_number"]).length > 0 && !Validators.validatePhoneNumber(body["phone_number"])) {
                            setState(() {
                              phoneError = "Phone number is not valid";
                            });
                          } else {
                            setState(() {
                              phoneError = "";
                            });
                          }
                        }
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                            child: Text("Date of birth", style: labelStyle),
                          ),
                          Container(
                            height: 40,
                            width: 351,
                            child: TextButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(isDark ? Color(0xFF353535) : Color(0xffFAFAFA)),
                                overlayColor: MaterialStateProperty.all(isDark ?Color(0xff5E5E5E) : Color(0xffEDEDED),),
                                // padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 16)),
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    side: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9))
                                  ),
                                )
                              ),
                              onPressed: () {
                                _selectDate(context, currentUser["date_of_birth"]);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: SelectableScope(
                                      child: TextWidget(
                                        dateTime, style: TextStyle(color: isDark ? Color(0xffF5F7FA) : Color(0xff243B53), fontSize: 14, fontWeight: FontWeight.w400)
                                      ),
                                    )
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: SvgPicture.asset('assets/icons/calendar_icon.svg', color: isDark ? Color(0xffF5F7FA) : Color(0xff243B53) ),
                                  ),
                                ],
                              )
                            )
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                            child: Text("Gender", style: labelStyle),
                          ),
                          Row(
                            children: [
                              Container(
                                height: 40,
                                width: 171,
                                decoration: BoxDecoration(
                                  color: isDark ? Color(0xFF353535) : Color(0xffFAFAFA),
                                  borderRadius: BorderRadius.all(Radius.circular(4)),
                                  border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9)),
                                ),
                                child: HoverItem(
                                  colorHover: isDark ?Color(0xff5E5E5E) : Color(0xffEDEDED),
                                  child: InkWell(
                                    onTap: (){
                                      setState(() {
                                        body["gender"] = "Male";
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Padding(
                                          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                          child: Text("Male", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 16)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(3),
                                          child: Transform.scale(
                                            scale: 0.8,
                                            child: Radio(
                                              overlayColor: MaterialStateProperty.all(Colors.transparent),
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              activeColor: isDark ? Color(0xffFAAD14) : Colors.blue,
                                              value: "Male",
                                              groupValue: body["gender"],
                                              onChanged: (value) {
                                                setState(() {
                                                  body["gender"] = "Male";
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ]
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 9),
                              Container(
                                height: 40,
                                width: 171,
                                decoration: BoxDecoration(
                                  color: isDark ? Color(0xFF353535) : Color(0xffFAFAFA),
                                  borderRadius: BorderRadius.all(Radius.circular(4)),
                                  border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9)),
                                ),
                                child: HoverItem(
                                  colorHover: isDark ?Color(0xff5E5E5E) : Color(0xffEDEDED),
                                  child: InkWell(
                                    onTap: (){
                                      setState(() {
                                        body["gender"] = "Female";
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                          child: Text("Female", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 16)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(3),
                                          child: Transform.scale(
                                            scale: 0.8,
                                            child: Radio(
                                              overlayColor: MaterialStateProperty.all(Colors.transparent),
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              activeColor: isDark ? Color(0xffFAAD14) : Colors.blue,
                                              value: "Female",
                                              groupValue: body["gender"],
                                              onChanged: (value) {
                                                setState(() {
                                                  body["gender"] = "Female";
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ]
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 18),
            padding: EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Platform.isWindows ? SystemToTray() : SizedBox(),
                SizedBox(width: 393),
                HoverItem(
                  colorHover: Color(0xffFF7875).withOpacity(0.2),
                  child: TextButton(
                    style: ButtonStyle(
                      // overlayColor: MaterialStateProperty.all(Colors.red[100]),
                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(width: 1, color: Colors.red, style: BorderStyle.solid)
                        ),
                      ),
                    ),
                    onPressed: () async {
                      // try {
                        await Provider.of<Auth>(context, listen: false).logout();
                        await Provider.of<Workspaces>(context, listen: false).resetData();
                        await Provider.of<DirectMessage>(context, listen: false).resetData();
                        await Provider.of<Channels>(context, listen: false).openChannelSetting(false);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginMacOS()
                          ));
                      // } catch (e) {
                      //   print(e);
                      // }
                    },
                    child:Text("Logout", style: TextStyle(color: Colors.red))
                  ),
                ),
                SizedBox(width: 7),
                HoverItem(
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(isInfoValidated ? Colors.blue : Colors.grey),
                      overlayColor: MaterialStateProperty.all(Colors.blue[400]),
                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(width: 1, color: isInfoValidated ? Colors.blue : Colors.grey, style: BorderStyle.solid)
                        ),
                      ),
                    ),
                    // onPressed: fullNameError.length > 0 || customIdError.length > 0 || phoneError.length > 0 ? null : _updateUserInfo,
                    onPressed: isInfoValidated ? _updateUserInfo : null,
                    child: Text("Save", style: TextStyle(color: Colors.white))
                  ),
                ),
              ],
            )
          ),
        ]
      )
    );
  }
}

class UploadIcon extends StatefulWidget {
  const UploadIcon({
    this.onPressed,
    Key? key,
    required this.isDark,
  }) : super(key: key);

  final bool isDark;
  final Function? onPressed;

  @override
  State<UploadIcon> createState() => _UploadIconState();
}

class _UploadIconState extends State<UploadIcon> {
  bool isHovered = false;

  openFileSelector(workspaceId) async {
    List resultList = [];
    final auth = Provider.of<Auth>(context, listen: false);
    
    try {

      var myMultipleFiles =  await Utils.openFilePicker([
        XTypeGroup(
          extensions: ['jpg', 'jpeg', 'png'],
        )
      ]);
      for (var e in myMultipleFiles) {
        Map newFile = {
          "name": e["name"],
          "file": e["file"],
          "path": e["path"]
        };
        resultList.add(newFile);
      }

      if(resultList.length > 0) {
        final image = resultList[0];
        if (image["file"].lengthInBytes > 10000000) {
          showDialog(
            context: context, 
            builder: (BuildContext context){
              return Dialog(
                child: CropImageDialog(image: image, token: auth.token, workspaceId: workspaceId),
              );
            }
          );
        } else {
          showDialog(
            context: context, 
            builder: (BuildContext context){
              return Dialog(
                child: CropImageDialog(image: image, token: auth.token, workspaceId: workspaceId),
              );
            }
          );
        }
      }
    } on Exception catch (e) {
      print("$e Cancel");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWorkspace = Provider.of<Workspaces>(context).currentWorkspace;
    final data = Provider.of<Workspaces>(context).data;
    final workspaceId = currentWorkspace["id"] ?? (data.length > 0 ? data[0]["id"] : "");
    
    return MouseRegion(
      onEnter: (event) => setState(() => isHovered = true),
      onExit: (event) => setState(() => isHovered = false),
      child: Container(
        width: 36,
        decoration: BoxDecoration(
          color: widget.isDark 
            ? isHovered ? Color(0xff828282) : Palette.borderSideColorDark  
            : isHovered ? Color(0xffDBDBDB) : Color(0xffEDEDED),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: (){
            openFileSelector(workspaceId);
          },
          icon: SvgPicture.asset('assets/icons/camera_icon.svg', color: widget.isDark ? Palette.defaultTextDark : Palette.fillerText)
        )
      ),
    );
  }
}

class FormInput extends StatefulWidget {
  const FormInput({
    Key? key,
    required this.labelStyle,
    required this.isDark,
    this.verifyType,
    this.isVerified,
    this.labelContent,
    this.initialValue,
    this.onChanged,
    this.readOnly = false,
    this.isError = false,
    this.errorMessage = ""
    
  }) : super(key: key);

  final TextStyle labelStyle;
  final bool isDark;
  final String? verifyType;
  final bool? isVerified;
  final labelContent;
  final initialValue;
  final onChanged;
  final bool readOnly;
  final isError;
  final errorMessage;

  @override
  State<FormInput> createState() => _FormInputState();
}

class _FormInputState extends State<FormInput> {

  @override
  Widget build(BuildContext context) {
  final isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;

  TextStyle textInputStyle = TextStyle(
    color: isDark ? Color(0xffF5F7FA) : Color(0xff243B53),
    fontSize: 14,
  );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
          child: Text(widget.labelContent, style: widget.labelStyle),
        ),
        Container(
          height: 40,
          width: 351,
          child: !widget.readOnly ? TextFormField(
            onChanged: this.widget.onChanged,
            readOnly: widget.readOnly,
            style: textInputStyle,
            initialValue: widget.initialValue,
            decoration: InputDecoration(
              hoverColor: widget.isDark ?Color(0xff5E5E5E) : Color(0xffEDEDED),
              contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              suffixIcon: Utils.checkedTypeEmpty(widget.isVerified)
                ? Transform.scale(scale: 0.35, child: SvgPicture.asset('assets/icons/verified_icon.svg'))
                : InkWell(
                  onTap: () {
                    _showAlert(context);
                  }, 
                  child: Transform.scale(scale: 0.35, child: SvgPicture.asset('assets/icons/verified_icon.svg', color: Colors.grey))
                ),
              filled: true,
              fillColor: widget.isDark ? Color(0xFF353535) : Color(0xffFAFAFA),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: widget.isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9)),
                borderRadius: BorderRadius.all(Radius.circular(4))),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: widget.isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9)),
                borderRadius: BorderRadius.all(Radius.circular(4)))
            ),
          ) : Container(
            decoration: BoxDecoration(
              border: Border.all(color: widget.isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9)),
              borderRadius: BorderRadius.all(Radius.circular(4)),
              color: widget.isDark ? Color(0xFF353535) : Color(0xffFAFAFA),
            ),
            child: HoverItem(
              colorHover: isDark ?Color(0xff5E5E5E) : Color(0xffEDEDED),
              child: SelectableScope(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(widget.initialValue, style: textInputStyle),
                      SvgPicture.asset('assets/icons/verified_icon.svg')
                    ],
                  ),
                ),
              ),
            )
          )
        ),
        (widget.verifyType == "email" && !Utils.checkedTypeEmpty(widget.isVerified))
        ? Container(
          padding: EdgeInsets.only(top: 2),
          child: Text(
            "Email chưa được xác thực",
            style: TextStyle(
              fontSize: 11,
              color: Colors.red
            )
          ),
        )
        : (widget.verifyType == "phoneNumber" && !Utils.checkedTypeEmpty(widget.isVerified))
          ? Container(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              widget.isError ? widget.errorMessage : 
              "Số điện thoại chưa được xác thực",
              style: TextStyle(
                fontSize: 11,
                color: Colors.red
              )
            )
          )
          : Container(child: Text("", style: TextStyle(fontSize: 12))),      
      ],
    );
  }
  void _showAlert(BuildContext context) {
    final currentUser = Provider.of<User>(context, listen: false).currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Enter verification code."),
        content: CheckVerifyPhoneNumber(
          verificationType: widget.verifyType,
          type: widget.verifyType == "email"
              ? currentUser["email"]
              : currentUser["phone_number"]
        )
      )
    );
  }
}

class SystemToTray extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _SystemToTrayState();
  }
}
class _SystemToTrayState extends State<SystemToTray>{
  late bool _check = true;
  MethodChannel systemChannel = MethodChannel("system");
  late Box box;
  @override
  void initState() {
    super.initState();
    Hive.openBox("system").then((value){
      box = value;
    });
    _check = Provider.of<Work>(context, listen: false).isSystemTray;
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(3)),
      ),
      width: 208.0,
      child: Row(
        children: [
          Expanded(child: Text("Close button to system tray", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400))),
          Checkbox(
            onChanged: (value) {
              setState(() {
                _check = value!;
                systemChannel.invokeMethod("system_to_tray", [_check]);
                box.put("is_tray", _check);
                Provider.of<Work>(context, listen: false).isSystemTray = _check;
              });
            },
            value: _check,
            activeColor: Colors.grey[300],
            checkColor: Colors.black,
          ),
        ],
      )
    );
  }
}

class ColorPicker extends StatefulWidget {
  final double width;
  final double height;
  final ValueChanged<Map> onChanged;
  final Color initValue;
  final double position;

  ColorPicker({
    Key? key,
    required this.width,
    required this.height,
    required this.onChanged,
    required this.initValue,
    required this.position
  }) : super(key: key);
  @override
  ColorPickerState createState() => ColorPickerState();
}
class ColorPickerState extends State<ColorPicker> {
  final List<Color> _colors = [
    const Color.fromARGB(255, 0, 0, 0),
    const Color.fromARGB(255, 255, 0, 0),
    const Color.fromARGB(255, 255, 128, 0),
    const Color.fromARGB(255, 255, 255, 0),
    const Color.fromARGB(255, 128, 255, 0),
    const Color.fromARGB(255, 0, 255, 0),
    const Color.fromARGB(255, 0, 255, 128),
    const Color.fromARGB(255, 0, 255, 255),
    const Color.fromARGB(255, 0, 128, 255),
    const Color.fromARGB(255, 0, 0, 255),
    const Color.fromARGB(255, 127, 0, 255),
    const Color.fromARGB(255, 255, 0, 255),
    const Color.fromARGB(255, 255, 0, 127),
    const Color.fromARGB(255, 128, 128, 128),
    const Color.fromARGB(255, 255, 255, 255),
  ];
  double colorSliderPosition = 0;
  Color currentColor = Colors.white;

  @override
  void initState(){
    colorSliderPosition = widget.position;
    currentColor = _calculateSelectedColor(colorSliderPosition);
    super.initState();
  }

  Color _calculateSelectedColor(double position) {
    //determine color
    double positionInColorArray = (position / widget.width * (_colors.length - 1));
    int index = positionInColorArray.truncate();
    double remainder = positionInColorArray - index;
    if (remainder == 0.0) {
      currentColor = _colors[index];
    } else {
      //calculate new color
      int redValue = _colors[index].red == _colors[index + 1].red
        ? _colors[index].red
        : (_colors[index].red + (_colors[index + 1].red - _colors[index].red) * remainder).round();
      int greenValue = _colors[index].green == _colors[index + 1].green
        ? _colors[index].green
        : (_colors[index].green + (_colors[index + 1].green - _colors[index].green) * remainder).round();
      int blueValue = _colors[index].blue == _colors[index + 1].blue
        ? _colors[index].blue
        : (_colors[index].blue + (_colors[index + 1].blue - _colors[index].blue) * remainder).round();
      currentColor = Color.fromARGB(255, redValue, greenValue, blueValue);
    }
    return currentColor;
  }

  _colorChangeHandler(double position) {
    //handle out of bounds positions
    if (position > widget.width) {
      position = widget.width;
    }
    if (position < 0) {
      position = 0;
    }
    
    setState(() {
      colorSliderPosition = position;
      currentColor = _calculateSelectedColor(colorSliderPosition);
    });

    try {
      widget.onChanged.call({
        "currentColor": currentColor,
        "colorSliderPosition": colorSliderPosition 
      });
    } catch (err) {
      print(err);
    }
  }
  
  @override
  Widget build(BuildContext context) { 
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (DragStartDetails details) {
        _colorChangeHandler(details.localPosition.dx);
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        _colorChangeHandler(details.localPosition.dx);
      },
      onTapDown: (TapDownDetails details) {
        _colorChangeHandler(details.localPosition.dx);
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(colors: _colors),
        ),
        child: CustomPaint(
          painter: _SliderIndicatorPainter(colorSliderPosition, widget.height),
        ),
      ),
    );
  }
}

class _SliderIndicatorPainter extends CustomPainter {
  final double position;
  final double height;
  _SliderIndicatorPainter(this.position, this.height);

  @override
  void paint(Canvas canvas, Size size) {
    var topTrianglePath = Path();
    var bottomTrianglePath = Path();
 
    topTrianglePath.moveTo(position, 0);
    topTrianglePath.lineTo(position - 5, -8);
    topTrianglePath.lineTo(position + 5, -8);
    topTrianglePath.close();

    bottomTrianglePath.moveTo(position, height);
    bottomTrianglePath.lineTo(position - 5, height + 8);
    bottomTrianglePath.lineTo(position + 5, height + 8);
    bottomTrianglePath.close();
 
    canvas.drawPath(topTrianglePath, Paint()..color = const Color(0xFFC9C9C9));
    canvas.drawPath(bottomTrianglePath, Paint()..color = const Color(0xFFC9C9C9));
  }
  @override
  bool shouldRepaint(_SliderIndicatorPainter old) {
    return true;
  }
}
