import 'package:flutter/material.dart';
import 'package:workcake/providers/providers.dart';

class Logo extends StatelessWidget {
  const Logo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Row(
      children: [
        Container(
          child: Image.asset(
            "assets/images/logo_app/logoPanchat.png",
            width: 48,
            height: 48,
          ),
        ),
        SizedBox(width: 8,),
        Text("PancakeChat", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Color(0xff1F2933)))
      ],
    );
  }
}
