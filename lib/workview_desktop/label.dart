import 'package:flutter/material.dart';

class LabelDesktop extends StatefulWidget {
  final labelName;
  final color;

  LabelDesktop({
    Key? key,
    @required this.labelName, 
    @required this.color,
  }) : super(key: key);

  @override
  _LabelDesktopState createState() => _LabelDesktopState();
}

class _LabelDesktopState extends State<LabelDesktop> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 4, top: 1, bottom: 1),
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: Color(widget.color),
        borderRadius: BorderRadius.circular(20)
      ),
      child: Text("${widget.labelName}", style: TextStyle(color: Colors.white, fontSize: 12.5)),
    );
  }
}