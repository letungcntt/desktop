import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/models/models.dart';

class FilterMentions extends StatefulWidget {
  FilterMentions({Key? key}) : super(key: key);

  @override
  _FilterMentionsState createState() => _FilterMentionsState();
}

class _FilterMentionsState extends State<FilterMentions> {
  
  bool _channelFilter = false;
  bool _reactFilter = false;
  bool _userFilter = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;

    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: Palette.backgroundTheardDark,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.15),
            blurRadius: 8.0,
            offset: Offset(0, 3)
          )
        ]
      ),
      child: Column(
        children: [
          Row(
            children: [
              Transform.scale(
                scale: 0.8,
                child: Checkbox(
                  value: _channelFilter,
                  onChanged: (value) {
                    setState(() {
                      _channelFilter = value!;
                    });
                  },
                  // side: BorderSide(color: isDark ? Color(0XFF19DFCB) : Color(0XFF2A5298)),
                ),
              ),
              Text("Channel Mentions", style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.85)),),
            ],
          ),
          Row(
            children: [
              Transform.scale(
                scale: 0.8,
                child: Checkbox(
                  value: _reactFilter,
                  onChanged: (value) {
                    setState(() {
                      _reactFilter = value!;
                    });
                  },
                  // side: BorderSide(color: isDark ? Color(0XFF19DFCB) : Color(0XFF2A5298)),
                ),
              ),
              Text("Reactions", style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.85)),),
            ],
          ),
          Row(
            children: [
              Transform.scale(
                scale: 0.8,
                child: Checkbox(
                  value: _userFilter,
                  onChanged: (value) {
                    setState(() {
                      _userFilter = value!;
                    });
                  },
                  // side: BorderSide(color: isDark ? Color(0XFF19DFCB) : Color(0XFF2A5298)),
                ),
              ),
              Text("Users Groups", style: TextStyle(color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 0.85)),),
            ],
          ),
          Container(
            margin: EdgeInsets.only(left: 10, top: 4),
            child: Text("( User Groups are collections of individual members )", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 10)),
          )
        ],
      )
    );
  }
}
