import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/models/models.dart';

import '../../common/palette.dart';

class LoginQrCodeButton extends StatefulWidget {
  const LoginQrCodeButton({Key? key, required this.onTap, required this.text, this.isLoading = false}) : super(key: key);
  final onTap;
  final String text;
  final bool isLoading;

  @override
  State<LoginQrCodeButton> createState() => _LoginQrCodeButtonState();
}

class _LoginQrCodeButtonState extends State<LoginQrCodeButton> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    
    return InkWell(
      onHover: (value) {
        if(isHover != value) {
          setState(() {
            isHover = value;
          });
        }
      },
      onTap: widget.isLoading ? null : widget.onTap ,
      child: Container(
        // margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(4.0)),
          border: Border.all(color: isHover ?  Utils.getPrimaryColor() : const Color(0xFF5E5E5E)),
          // boxShadow: <BoxShadow>[
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.15),
          //     offset: const Offset(0, 3),
          //     blurRadius: 8,
          //   )
          // ],
          color:  isDark ? Palette.backgroundRightSiderDark : Palette.backgroundRightSiderLight ,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.qrCodeThin,
              color: isHover ? Utils.getPrimaryColor() :  isDark ? const Color(0xffDBDBDB) : Colors.black.withOpacity(0.85,)
            ),
            Container(width: 12,),
            Text(
              widget.text,
              style: TextStyle(fontSize: 16, color: isHover ? Utils.getPrimaryColor() : isDark ? const Color(0xffDBDBDB) : const Color(0xff3D3D3D)),
            ),
          ],
        ),
      ),
    );
  }
}
