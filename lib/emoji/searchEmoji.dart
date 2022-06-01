import 'package:flutter/cupertino.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/emoji/itemEmoji.dart';
import 'package:workcake/models/models.dart';

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
      margin: EdgeInsets.only(top: 55),
      // top: 50,

      child: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            height: 30,
            child: CupertinoTextField(
              placeholder: 'Search Emoji',
              prefix: Container(margin: EdgeInsets.symmetric(horizontal: 5), child: Icon(PhosphorIcons.magnifyingGlass,
               color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E), size: 15,)),
              autofocus: false,
              style: TextStyle(fontSize: 13),
              onChanged: (value) => search(value),
               decoration: BoxDecoration(

                borderRadius: BorderRadius.circular(10),
                color:isDark ? Color(0xff2E2E2E) : Color(0xffEDEDED)
              ),
            ),
          ), 
          text == ""
            ? Container()
            : Container(
              height: 262,
              // color: isDark ? Color(0xFF1F2933) : Colors.white,
              child: SingleChildScrollView(
                child: Container(
                  width: 350,
                  margin: EdgeInsets.only(top: 10),
                  child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: listResults.map<Widget>((emo) {
                    return Container(
                      key: Key("_search_${emo.id}"),
                      child: emo.render(),
                    );
                  }).toList(),
              ),
                ),
              ),
            )
        ],
      ),
    );
  }
} 
