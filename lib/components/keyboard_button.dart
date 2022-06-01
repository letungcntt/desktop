import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class KeyBoardButton extends StatefulWidget {
  final onChanged;

  KeyBoardButton({
    Key? key,
    @required this.onChanged
  }) : super(key: key,);

  @override
  _KeyBoardButtonState createState() => _KeyBoardButtonState();
}

class _KeyBoardButtonState extends State<KeyBoardButton> {

  List listButton = [
    {{"key": "1", "value": 1}, {"key": "2", "value": 2}, {"key": "3", "value": 3}},
    {{"key": "4", "value": 4}, {"key": "5", "value": 5}, {"key": "6", "value": 6}},
    {{"key": "7", "value": 7}, {"key": "8", "value": 8}, {"key": "9", "value": 9}},
    {{"key": "Cancel", "value": "Cancel"}, {"key": "0", "value": 0}, {"key": "delete", "value": "del"}},
  ];

  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: listButton.map<Widget>((e) {
          return Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: e.map<Widget>((k) {
                return Container(
                  width: 72,
                  height: 56,
                  margin: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF323F4B),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Color(0xFF7B8794)),
                      foregroundColor: MaterialStateProperty.all(Color(0xFF7B8794)),
                      overlayColor: MaterialStateProperty.all(Color(0xFF7B8794)),
                    ),
                    onPressed: () {
                      widget.onChanged(k["value"]);
                    },
                    child: k["key"] == "delete"
                    ? Container(
                      child: Icon(
                        CupertinoIcons.delete_left,
                        size: 24,
                        color: Colors.white,
                      )
                    )
                    : Text(
                      k["key"],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: k["key"] == "Cancel" ? FontWeight.w400 : FontWeight.w500,
                        color: Colors.white,
                        fontSize: k["key"] == "Cancel" ? 13 : 24
                      )
                    )
                  )
                );
              }).toList(),
            )
          );
        }).toList(),
      )
    );
  }
}
