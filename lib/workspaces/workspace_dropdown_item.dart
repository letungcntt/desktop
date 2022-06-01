import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/models/models.dart';

class MenuItem extends StatefulWidget {
  MenuItem({
    Key? key,
    @required this.icon,
    @required this.title,
    @required this.onClick
  }) : super(key: key);

  final icon;
  final title;
  final onClick;

  @override
  _MenuItemState createState() => _MenuItemState();
}

class _MenuItemState extends State<MenuItem> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;

    return TextButton(
      style: ButtonStyle(
        padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 22)),
        foregroundColor: MaterialStateProperty.all(Colors.transparent),
        backgroundColor: MaterialStateProperty.all(Colors.transparent),
        overlayColor: MaterialStateProperty.all(Colors.transparent),
      ),
      onPressed: () {
        Navigator.pop(context);
        widget.onClick(context);
      },
      child: Container(width: 190, child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.title, style: TextStyle(fontSize: 14, color: widget.title == "Delete workspace" ? Colors.red : isDark ? Color(0xffF5F7FA) : Colors.grey[600])),
          Icon(widget.icon, size: 16, color: widget.title == "Delete workspace" ? Colors.transparent : isDark ? Color(0xffF5F7FA) : Colors.grey[600])
        ],
      )),
    );
  }
}