import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/http_exception.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';

class CreateChannelDesktop extends StatefulWidget {
  @override
  _CreateChannelDesktopState createState() => _CreateChannelDesktopState();
}

class _CreateChannelDesktopState extends State<CreateChannelDesktop> {
  TextEditingController _controller = TextEditingController();
  bool isValuePrivate = false;
  var _debounce;
  List resultSearch = [];
  List listUserChannel = [];

  @override
  void initState(){
    super.initState();
    Timer.run(()async {
      final auth = Provider.of<Auth>(context, listen: false);
      final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      var result   = await Provider.of<Workspaces>(context, listen: false).searchMember("", auth.token, currentWorkspace["id"]);
      result.removeWhere((element) => element["id"] == auth.userId);
      setState(() {
        resultSearch = result;
      }); 
    });

    _controller.addListener(inputListeners);
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void inputListeners() {
    if (_controller.text.contains(' ')) {
      List _splitCurrentSpace = _controller.text.split(" ");
      int _currentCaretPosition = _splitCurrentSpace[0].length +1;  
      final formatName = _controller.text.replaceAll(' ', '-');
      _controller.value = TextEditingValue(
        text: formatName,
        selection: TextSelection.collapsed(offset: _currentCaretPosition),
      );
    }
  }

  handleUserToChannel(user, selected) {
    setState(() {
      var index  = listUserChannel.indexWhere((element) => element["id"] == user["id"]);
      if (index != -1){
        listUserChannel.removeAt(index);
      }
      else listUserChannel.add(user);
    });
  }

  _submitCreateChannel(token, workspaceId, String value) {
    final auth = Provider.of<Auth>(context, listen: false);
    final providerMessage = Provider.of<Messages>(context, listen: false);
    try {
      var userIds = listUserChannel.map((e) => e["id"]).toList();
      Provider.of<Channels>(context, listen: false).createChannel(token, workspaceId, value, isValuePrivate, userIds, auth, providerMessage);
      Navigator.pop(context);
    } on HttpException catch (error) {
      print("this is http exception $error");
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final token = auth.token;
    final currentWorkspace = Provider.of<Workspaces>(context).currentWorkspace;
    final isDark = auth.theme == ThemeType.DARK;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xff3D3D3D) : Color(0xffF8F8F8),
        borderRadius: BorderRadius.all(Radius.circular(5))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(left: 16,right: 13,top:13,bottom: 13 ),
            decoration: BoxDecoration(
              color: isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5.0),
                  topRight: Radius.circular(5.0)
                )
              ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.of(context).createChannel.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Color(0xffFFFFFF): Color(0xff3D3D3D))),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(PhosphorIcons.xCircle,size: 18))
              ],
            )
          ),
          Container(
            color: isDark? Color(0xFF4C4C4C): Color(0xFFDBDBDB),
            height: 1,),
          Container(
            margin: EdgeInsets.only(top: 16, bottom: 10, left: 16),
            child: Text("CHANNEL TYPE", style: TextStyle(fontWeight: FontWeight.w400, color: isDark ? Color(0xffC9C9C9) : Color(0xff828282), fontSize: 12))
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                      color: isDark ? Color(0xff353535) : Color(0xffEDEDED),
                      border: Border.all(color: isDark ? Color(0xff828282) : Color(0xffA6A6A6), width: 0.5),
                    ),
                    child: Row(children: <Widget>[
                      Radio(
                        activeColor: Color(0xff096DD9),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: false,
                        groupValue: isValuePrivate,
                        onChanged: (_) {
                          if (isValuePrivate) {
                            this.setState(() {
                              isValuePrivate = false;
                            });
                          }
                        },
                      ),
                      Container(margin: EdgeInsets.symmetric(horizontal: 5), child: SvgPicture.asset('assets/icons/iconNumber.svg',  color: isDark ?Color(0xffFAFAFA) :Color(0xff3D3D3D) )),
                      Text("Regular Channel", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 14))
                    ]),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                      color: isDark ? Color(0xff353535) : Color(0xffEDEDED),
                      border: Border.all(color: isDark ? Color(0xff828282) : Color(0xffA6A6A6), width: 0.5),
                    ),
                    child: Row(children: <Widget>[
                      Radio(
                        activeColor: Color(0xff096DD9),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        value: true,
                        groupValue: isValuePrivate,
                        onChanged: (_) {
                          if (!isValuePrivate) {
                            this.setState(() {
                              isValuePrivate = true;
                            });
                          }
                        },
                      ),
                      Container(margin: EdgeInsets.symmetric(horizontal: 5), child: SvgPicture.asset('assets/icons/Locked.svg' ,  color: isDark ?Color(0xffFAFAFA) :Color(0xff3D3D3D))),
                      Text("Private Channel", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 14))
                    ]),
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text("CHANNEL NAME", style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12))
          ),
          SizedBox(height: 8),
          Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(left: 16, right: 16),
            decoration: BoxDecoration(
              border: Border.all(color: isDark? Color(0xff828282): Color(0xffC9C9C9),width: 0.5),
              color: isDark ? Color(0xff353535) : Color(0xffEDEDED),
              borderRadius: BorderRadius.circular(2)),
              child: TextField(
                cursorWidth: 1.0,
                cursorHeight: 14,
                controller: _controller,
                cursorColor: Color(0xffA6A6A6),
                decoration: InputDecoration(
                  hintText: 'Enter new channel name',
                  hintStyle: TextStyle(color:  Color(0xffA6A6A6),fontWeight: FontWeight.w400,fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  border: InputBorder.none,
                ),
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                onSubmitted: (value) {
                  if (value != "newsroom") {
                    _submitCreateChannel(token, currentWorkspace["id"], value);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            
          ),
          SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text("MEMBERS (${listUserChannel.length})", style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12))
          ),
          SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: isDark? Color(0xff828282): Color(0xffC9C9C9),width: 0.5),
              color: isDark ? Color(0xff353535) : Color(0xffEDEDED),
              borderRadius: BorderRadius.circular(2)),
            child: TextFormField(
              decoration: InputDecoration(
              hintText: 'Search members...',
              hintStyle: TextStyle(color:  Color(0xffA6A6A6),fontWeight: FontWeight.w400,fontSize: 14),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              border: InputBorder.none,
            ),
              style: TextStyle(color:  Color(0xffA6A6A6) ),
              onChanged: (value){
                if (_debounce?.isActive ?? false) _debounce.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), ()async {
                  List result = await Provider.of<Workspaces>(context, listen: false).searchMember(value, token, currentWorkspace["id"]);
                  result.removeWhere((element) => element["id"] == auth.userId);
                  setState(() {
                    resultSearch = result;
                  });
                });
              },
            ),
          ),
          listUserChannel.length == 0 ?SizedBox(height: 10,) : Container(
            margin: EdgeInsets.only(left: 18,right: 18,top: 0),
            width: MediaQuery.of(context).size.width,
            height: 50,
            child: ScrollConfiguration(
              behavior: MyCustomScrollBehavior(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                child: Row(
                  children: listUserChannel.map((u) => Container(
                    margin: EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {handleUserToChannel(u, true);},
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xff2E2E2E) : Color(0xffEAE8E8),
                          borderRadius: BorderRadius.circular(20)),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Row(
                            children: [
                              CachedAvatar(
                                u["avatar_url"],
                                radius: 16,
                                height: 20,
                                width: 20,
                                name: u["full_name"]
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Container(
                                child: Text(u["full_name"],
                                style: TextStyle(fontSize: 12,fontWeight: FontWeight.w400, color: isDark ? Color(0xffEDEDED) : Color(0xff3D3D3D), height: 1.5)),
                              ),
                              SizedBox(width: 8,),
                              Icon(PhosphorIcons.xCircle,size: 12,),
                            ],
                          )
                        ),
                      ),
                    ),
                  )).toList(),
                ) 
              ),
            )),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide( 
                      color:isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9),
                      width: 1.0,
                    ),
                ),
              ),
              child: ListView.builder(
                itemCount: resultSearch.length,
                itemBuilder: (context, index) {
                  // var selected = listUserChannel.where((e) {return e["id"] == resultSearch[index]["id"];}).length > 0;
                  var selected = listUserChannel.where((e) {return e["id"] == resultSearch[index]["id"];}).length >0;
                  return InkWell(
                    onTap: (){
                      handleUserToChannel(resultSearch[index], selected);
                    },
                    child: HoverItem(
                      colorHover: Palette.hoverColorDefault,
                      child: Container(
                        height: 45,
                        padding: EdgeInsets.symmetric(vertical: 10,horizontal: 11),
                        decoration: BoxDecoration(
                          border: Border( 
                            left: BorderSide( 
                              width: 1.0,
                              color:isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9),
                            ),
                            right: BorderSide( 
                              color:isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9),
                              width: 1.0,
                            ),
                            bottom: BorderSide( 
                              color:isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9),
                              width: 0.5,
                            ),
                          ), 
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              children: [
                                CachedImage(
                                  resultSearch[index]["avatar_url"],
                                  radius: 24,
                                  isRound: true,
                                  name: resultSearch[index]["full_name"]
                                ),
                                Container(
                                  width: 10,
                                ),
                                Container(
                                  child: Text( Utils.getUserNickName(resultSearch[index]["id"]) ?? resultSearch[index]["full_name"],
                                      style: TextStyle(fontSize: 14)),
                                ),
                              ],
                            ),
                            selected ? Container(
                             child: Icon(PhosphorIcons.checkCircleFill, size: 19, color:isDark ? Color(0xffFAAD14) : Utils.getPrimaryColor(),)
                             ) : SizedBox()
                          ]
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16,vertical: 9),
            width: double.infinity,
            height: 36,
            child: TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Utils.getPrimaryColor()),
              ),
              onPressed: () {
                if (_controller.text != "newsroom") {
                  _submitCreateChannel(token, currentWorkspace["id"], _controller.text);
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text(S.of(context).createChannel, style: TextStyle(color: Colors.white))
            )
          )
        ],
      ),
    );
  }
}
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => { 
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    // etc.
  };
}