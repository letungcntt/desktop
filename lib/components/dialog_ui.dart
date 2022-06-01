import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:workcake/service_locator.dart';

enum DialogType{error, complete}


void setupDialogUI(){
  final dialogService = sl<DialogService>();
  final builders = {
    DialogType.error: (context, sheetRequest, completer) => _AlertDialog(request: sheetRequest, completer: completer, isError: true),
    DialogType.complete: (context, sheetRequest, completer) => _AlertDialog(request: sheetRequest, completer: completer, isError: false)
  };

  dialogService.registerCustomDialogBuilders(builders);
}
class _AlertDialog extends StatelessWidget {
  final request;
  final completer;
  final bool isError;
  const _AlertDialog({
    Key? key,
    this.request, this.completer,
    required this.isError
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      animationDuration: Duration(milliseconds: 500),
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned(
            top: 80,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.transparent, blurRadius: 10.0, offset: Offset(1,2))],
                borderRadius: BorderRadius.all(Radius.circular(5)),
                color: isError ? Color(0xffEE3B3B) : Colors.green[400]!
              ),
              width: 400,
              height: 70,
              padding: EdgeInsets.all(20),
              child: Center(child: Text(
                request.customData,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14
                ),
              ))
            ),
          ),
        ],
      ),
    );
  }
}
