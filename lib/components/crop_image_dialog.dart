import 'dart:convert';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';

class CropImageDialog extends StatefulWidget {
  final image;
  final onCropped;
  final bool isDirect;

  const CropImageDialog({
    Key? key,
    required this.image,
    required this.onCropped,
    this.isDirect = false
  }) : super(key: key);

  @override
  _CropImageDialogState createState() => _CropImageDialogState();
}

class _CropImageDialogState extends State<CropImageDialog> {
final _cropController = CropController();
  // var _loadingImage = false;
  var _isCropping = false;

  Uint8List? _croppedData;

  @override
  void initState() {
    super.initState();
  }

  uint8ListTob64(Uint8List? uint8list) {
    String base64String = base64.encode(uint8list!);
    return base64String; 
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return Container(
      width: 798,
      height: 569,
      child: Center(
        child: Column(
          children: [
            Container(
                height: 40,
                padding: EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  color:isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(5),
                    topLeft: Radius.circular(5), 
                  )
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     (_croppedData == null) ? Text(S.current.editImage) : Text(S.current.userProfile),
                    HoverItem(
                    colorHover: isDark ? Color(0xff828282) : Color(0xffDBDBDB),
                    child: IconButton(
                      onPressed: (){
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        PhosphorIcons.xCircle,
                        size: 20.0,
                      ),
                    )
                  )
                ]),
              ),
            Expanded(
              child: Crop(
                image: widget.image["file"].buffer.asUint8List(),
                onCropped: (croppedData) {
                  if (mounted) {
                    setState(() {
                      _croppedData = croppedData;
                      _isCropping = false;
                    });
                  }
                  Navigator.pop(context);
                  if(_croppedData != null) {
                    final uploadFile = {
                      "filename": widget.image["name"],
                      "path": uint8ListTob64(_croppedData!),
                      "length": uint8ListTob64(_croppedData!).length,
                    };
                    widget.onCropped(uploadFile);
                  }
                },
                controller: _cropController,
                initialSize: 1,
                aspectRatio: 1,
              ),
            ),
            Container(
              height: 0.75,
              color: Color(0xffC9C9C9),
            ),
            Container(
              height: 56,
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
              color:isDark ? Color(0xff5E5E5E) : Color(0xffF3F3F3),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(5), 
                )
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(width: 1, color: Color(0xffEB5757), style: BorderStyle.solid)
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    }, 
                    child: Text(S.current.cancel, style: TextStyle(color: Colors.red))
                  ),
                  SizedBox(width: 10,),
                  Container(
                    width: 142,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: _isCropping ? null : () async {
                        setState(() {
                          _isCropping = true;
                        });
                        _cropController.crop();
                      },
                      child: Container(
                        child: _isCropping 
                        ? SpinKitFadingCircle(
                            color: isDark ? Colors.white60 : Color(0xff096DD9),
                            size: 19,
                          ) 
                        : Text(S.of(context).changeAvatar),
                      )
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}