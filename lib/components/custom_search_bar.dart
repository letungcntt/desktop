import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/models/models.dart';

class CustomSearchBar extends StatefulWidget {
  final placeholder;
  final onChanged;
  final double radius;
  final prefix;
  final controller;
  final autoFocus;

  CustomSearchBar({
    Key? key,
    this.placeholder = "",
    this.onChanged,
    this.controller,
    this.radius = 5,
    this.prefix = true,
    this.autoFocus = false
  }) : super(key: key);

  @override
  _CustomSearchBarState createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;

    return CupertinoTextField(
      autofocus: widget.autoFocus,
      prefix: widget.prefix ? Container(
        child: Icon(Icons.search, color: isDark ? Colors.grey[300] : Colors.black54),
        padding: EdgeInsets.only(left: 15)
      ) : Container(),
      style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87),
      placeholder: widget.placeholder,
      padding: EdgeInsets.all(8),
      clearButtonMode: OverlayVisibilityMode.always,
      controller: widget.controller,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        color: isDark ? Colors.black38 : Color(0xffe2e5e8)
      ),
      onChanged: (value) {
        widget.onChanged(value);
      },
    );
  }
}
