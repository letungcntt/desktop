import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/emoji/emoji.dart';

class ListIcons extends StatefulWidget {
  const ListIcons({
    Key? key,
    this.surroundTextSelection,
    this.isDark
  }) : super(key: key);

  final surroundTextSelection;
  final isDark;

  @override
  _ListIconsState createState() => _ListIconsState();
}

class _ListIconsState extends State<ListIcons> {
  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Container(
      height: 40,
      width: 320,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          HoverItem(
            colorHover: Palette.hoverColorDefault,
            child: InkWell(
              focusNode: FocusNode()..skipTraversal = true,
              onTap: () {
                widget.surroundTextSelection("### ", "", "header");
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.5, vertical: 10),
                child: Text(
                  "H",
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white70 : Color.fromRGBO(0, 0, 0, 0.65)
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          HoverItem(
            colorHover: Palette.hoverColorDefault,
            child: Container(
              width: 35,
              child: IconButton(
                color: isDark ? Colors.white70 : Color.fromRGBO(0, 0, 0, 0.60),
                icon: Icon(CupertinoIcons.bold, size: 21),
                onPressed: () {
                  widget.surroundTextSelection("**", "**", "bold");
                },
              ),
            ),
          ),
          HoverItem(
            colorHover: Palette.hoverColorDefault,
            child: Container(
              width: 35,
              child: IconButton(
                color: isDark ? Colors.white70 : Color.fromRGBO(0, 0, 0, 0.65),
                icon: Icon(CupertinoIcons.italic, size: 20),
                onPressed: () {
                  widget.surroundTextSelection("_", "_", "italic");
                },
              ),
            ),
          ),
          HoverItem(
            colorHover: Palette.hoverColorDefault,
            child: Container(
              margin: EdgeInsets.only(top: 2.5),
              width: 35,
              child: IconButton(
                color: isDark ? Colors.white70 : Color.fromRGBO(0, 0, 0, 0.65),
                icon: Icon(Icons.code, size: 19),
                onPressed: () {
                  widget.surroundTextSelection("`", "`", "code");
                },
              ),
            ),
          ),
          HoverItem(
            colorHover: Palette.hoverColorDefault,
            child: Container(
              width: 35,
              child: IconButton(
                color: isDark ? Colors.white70 : Color.fromRGBO(0, 0, 0, 0.65),
                icon: Icon(CupertinoIcons.link, size: 16),
                onPressed: () {
                  widget.surroundTextSelection("[", "](url)", "link");
                },
              ),
            ),
          ),
          HoverItem(
            colorHover: Palette.hoverColorDefault,
            child: Container(
              width: 35,
              child: IconButton(
                color: isDark ? Colors.white70 : Color.fromRGBO(0, 0, 0, 0.65),
                icon: Icon(CupertinoIcons.list_bullet, size: 21),
                onPressed: () {
                  widget.surroundTextSelection("- ", "", "listDash");
                },
              ),
            ),
          ),
          HoverItem(
            colorHover: Palette.hoverColorDefault,
            child: Container(
              width: 35,
              child: IconButton(
                color: isDark ? Colors.white70 : Color.fromRGBO(0, 0, 0, 0.65),
                icon: Icon(CupertinoIcons.list_number, size: 21),
                onPressed: () {
                  widget.surroundTextSelection("1. ", "", "listNumber");
                },
              ),
            ),
          ),
          HoverItem(
            colorHover: Palette.hoverColorDefault,
            child: Container(
              width: 35,
              child: IconButton(
                color: isDark ? Colors.white70 : Color.fromRGBO(0, 0, 0, 0.65),
                icon: Icon(CupertinoIcons.checkmark_square, size: 21),
                onPressed: () {
                  widget.surroundTextSelection("- [ ] ", "", "check");
                },
              ),
            ),
          ),
          HoverItem(
            colorHover: Palette.hoverColorDefault,
            child: Container(
              width: 35,
              child: IconButton(
                color: isDark ? Colors.white70 : Color.fromRGBO(0, 0, 0, 0.65),
                icon: Icon(Icons.panorama_outlined, size: 24),
                onPressed: () {
                  widget.surroundTextSelection("![ ](url)", "", "img");
                },
              ),
            ),
          )
        ]
      ),
    );
  }
}