import 'package:flutter/material.dart';
import 'package:workcake/common/palette.dart';

class MarkdownCheckbox extends StatefulWidget {
  const MarkdownCheckbox({
    Key? key,
    @required this.value,
    @required this.variable,
    @required this.onChangeCheckBox, 
    this.commentId,
    required this.isDark
  }) : super(key: key);

  final value;
  final variable;
  final onChangeCheckBox;
  final commentId;
  final bool isDark;

  @override
  _MarkdownCheckboxState createState() => _MarkdownCheckboxState();
}

class _MarkdownCheckboxState extends State<MarkdownCheckbox> {
  var value;

  @override
  void initState() {
    super.initState();
    this.setState(() {
      value = widget.value;
    });
  }

  @override
  void didUpdateWidget (oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      value = widget.value;
    } 
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 6),
      child: Transform.scale(
        scale: 1,
        child: SizedBox(
          height: 15.0,
          width: 24.0,
          child: Checkbox(
            onChanged: (newValue) {
              this.setState(() { value = newValue; });
              widget.onChangeCheckBox(newValue, widget.variable, widget.commentId);
            },
            value: value,
            activeColor: widget.isDark ? Palette.calendulaGold : Palette.dayBlue,
            checkColor: widget.isDark ? Colors.black : Colors.white,
          )
        ),
      ),
    );
  }
}