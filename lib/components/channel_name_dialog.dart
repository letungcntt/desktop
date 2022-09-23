import 'package:flutter/material.dart';
import 'package:workcake/generated/l10n.dart';

import 'package:workcake/providers/providers.dart';

class ChannelNameDialog extends StatefulWidget {
  final title;
  final displayText;
  final onSaveString;

  ChannelNameDialog({key, this.title, this.displayText, this.onSaveString}) : super(key: key);

  @override
  _ChannelNameDialogState createState() => _ChannelNameDialogState();
}

class _ChannelNameDialogState extends State<ChannelNameDialog> {
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.displayText;
    _controller.addListener(inputListeners);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void inputListeners() {
    if (_controller.text.contains(' ')) {
      List _splitCurrentSpace = _controller.text.split(" ");
      int _currentCaretPosition = _splitCurrentSpace[0].length +1;
      final formatName = _controller.text.replaceAll(' ', '-');
      _controller.value = TextEditingValue(
        text: formatName,
        selection: TextSelection.fromPosition(
          TextPosition(offset: _currentCaretPosition),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: true);
    final isDark = auth.theme == ThemeType.DARK;

    return Container(
      child: AlertDialog(
        insetPadding: EdgeInsets.all(20),
        contentPadding: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        backgroundColor: isDark ? Color(0xFF1F2933) : Colors.white,
        content: Container(
          height: 190,
          width: 300,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(top: 10, bottom: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14, color: isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[700]))
                        ]
                      ),
                      decoration:  BoxDecoration(border: Border(bottom: BorderSide(width: 0.2, color: Colors.grey))),
                    ),
                  ]
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(2),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(10),
                width: MediaQuery.of(context).size.width,
                child: TextButton(
                  // color: Utils.getPrimaryColor(),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(isDark ? Color(0XFF19DFCB) : Color(0XFF2A5298))
                  ),
                  onPressed: () {
                    widget.onSaveString(_controller.text);
                  },
                  child: Text(S.current.save, style: TextStyle(fontSize: 12, color: isDark ? Colors.black.withOpacity(0.65) : Colors.white))
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                width: MediaQuery.of(context).size.width,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop("Discard");
                  },
                  child: Text(S.current.cancel, style: TextStyle(fontSize: 12))
                ),
              )
            ]
          ),
        ),
      ),
    );
  }
}