import 'package:flutter/material.dart';
import 'package:workcake/components/widget_text.dart';

class Collapse extends StatefulWidget {
  const Collapse({
    Key? key,
    required this.name,
    required this.child
  }) : super(key: key);

  final name;
  final child;

  @override
  State<Collapse> createState() => _CollapseState();
}

class _CollapseState extends State<Collapse> {
  bool collapse = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            this.setState(() {
              collapse = !collapse;
            });
          },
          child: Container(
            margin: EdgeInsets.only(top: 4),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextWidget(
                  widget.name,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1)
                ),
                Icon(collapse ? Icons.arrow_right : Icons.arrow_drop_down, color: Colors.grey[500])
              ]
            )
          )
        ),
        if (!collapse) widget.child
      ]
    );
  }
}
