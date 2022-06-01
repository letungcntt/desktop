import 'package:flutter/material.dart';

class IconOnline extends StatefulWidget {

  final icon;
  final size;
  final color;

  IconOnline({Key? key, this.icon, this.size, this.color})
      : super(key: key);

  @override
  _IconOnlineState createState() => _IconOnlineState();
}

class _IconOnlineState extends State<IconOnline> {

  int counter = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Icon(
          widget.icon,
          size: widget.size,
          color: widget.color
        ),
        Positioned(
          right: 0,
          child: Container(
            padding: EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(6),
            ),
            constraints: BoxConstraints(
              minWidth: 11,
              minHeight: 11,
            ),
            child: Padding(
              padding: EdgeInsets.only(top: 1),
              child: counter == 0 ? Container() : Text(
                '$counter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}