import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:workcake/common/utils.dart';

class SubmitButton extends StatefulWidget {
  const SubmitButton({Key? key, required this.onTap, required this.text, this.isLoading = false, this.isDisable = false}) : super(key: key);
  final onTap;
  final String text;
  final bool isLoading;
  final bool isDisable;

  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton> {
  bool isHover = false;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onHover: (value) {
        if(isHover != value) {
          setState(() {
            isHover = value;
          });
        }
      },
      onTap: widget.isLoading ? null : widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(4.0)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(0, 3),
              blurRadius: 8,
            )
          ],
          color: widget.isDisable ? Colors.grey[500] : isHover ? const Color(0xff40A9FF) : Utils.getPrimaryColor()
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.isLoading ? (
              const SpinKitFadingCircle(
                color: Colors.white,
                size: 19,
              )
            ) : Text(
              widget.text,
              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
