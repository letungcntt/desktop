import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/emoji/itemEmoji.dart';
import 'package:workcake/providers/providers.dart';

class SearchEmoji extends StatefulWidget {
  final onTap;
  final onHover;
  final onSearch;
  const SearchEmoji({ Key? key, @required this.onTap, @required this.onHover, @required this.onSearch}) : super(key: key);

  @override
  _SearchEmojiState createState() => _SearchEmojiState();
}

class _SearchEmojiState extends State<SearchEmoji> {
  var text = "";
  List<ItemEmoji> listResults = [];

  search(value){
    if (value == ""){
      setState(() {
        text = "";
        listResults = [];
      });
    } else {
      setState(() {
        text = value;
        listResults = uniq(widget.onSearch(value));
      });
    }
  }

  List<ItemEmoji> uniq(List dataSource){
    Map index  = {};
    List<ItemEmoji> results = [];
    for (var i in dataSource){
      if (index[i.id] == null) {
        index[i.id] = true;
        results += [i];
      }
    }
    return results;
  }


  @override
  Widget build(BuildContext context) {
    var isDark  = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;
    return Container(
      color:isDark ? Color(0xFF3D3D3D) : Color(0xFFFFFFFF),
      margin: EdgeInsets.only(top: 8),
      // top: 50,

      child: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              color: isDark ? Color(0xff2E2E2E) : Color(0xffEDEDED),
            ),
            height: 36,
            child: Focus(
              onFocusChange: (value) {
                Provider.of<Windows>(context, listen: false).isOtherFocus = value;
              },
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: 'Search emojis',
                  prefixIcon: Icon(
                    PhosphorIcons.magnifyingGlass,
                    color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E), size: 16
                  ),
                  contentPadding: EdgeInsets.only(top: 8),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)),
                    borderRadius: BorderRadius.all(Radius.circular(4))
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDark ? Palette.calendulaGold : Palette.dayBlue),
                    borderRadius: BorderRadius.all(Radius.circular(4))
                  )
                ),
                autofocus: false,
                style: TextStyle(fontSize: 14, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                onChanged: (value) => search(value),
              ),
            ),
          ),
          text == ""
            ? Container()
            : Container(
              height: listResults.length != 0 ? (listResults.length/8 >= 3 ? 150 : (listResults.length < 9 ? 50 : 100)) : 0,
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 50,
                  childAspectRatio: 1,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: listResults.length,
                itemBuilder: (context, index) {
                  final emo = listResults[index];
                  return Container(
                    key: Key("_search_${emo.id}"),
                    child: emo.render(size: 28),
                  );
                }
              ),
            )
        ],
      ),
    );
  }
}
