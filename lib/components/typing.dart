import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/models/models.dart';

class TypingDesktop extends StatefulWidget {
  final id;

  TypingDesktop({
    Key? key,
    this.id
  }) : super(key: key);

  @override
  _TypingDesktopState createState() => _TypingDesktopState();
}

class _TypingDesktopState extends State<TypingDesktop> {  
  List typing = [];
  var channel;

  @override
  void initState() {
    channel = Provider.of<Auth>(context, listen: false).channel;
    super.initState();

    if (this.mounted) {
      setupTyping();
    }
  }

  @override
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.id != widget.id) { 
      setState(() {
        typing = [];
      });
    }
  }

  setupTyping() async {
    final duration = const Duration(seconds: 1);

    channel.on("on_typing", (data, _ref, _joinRef) {
      onTyping(data);
    });

    while(true && this.mounted) {
      await Future.delayed(duration);
      await resetTypingCountdown();
    } 
  }

  resetTypingCountdown() {
    List list = [];

    if (typing.length > 0) {
      for (var i = 0; i < typing.length; i++) {
        if (typing[i]["typing_countdown"] > 0) {
          typing[i]["typing_countdown"] = typing[i]["typing_countdown"] - 1;

          list.add(typing[i]);
        }
      }

      if (this.mounted) {
        this.setState(() {
          typing = list;
        });
      }
    }
  }

  onTyping(data) {
    if (this.mounted) {
      if (widget.id == data["id"]) {
        int index = typing.indexWhere((e) => e["user_id"] == data["user_id"]);
        List list = List.from(typing);

        if (index == -1) {
          list.add(data);
        } else {
          list[index]["typing_countdown"] = 3;
        }

        this.setState(() {
          typing = list;
        });
      }
    }
  }

  @override
  void dispose() { 
    channel.off("on_typing");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: 
      (typing.length > 0) ? Container(
        padding: EdgeInsets.only(left: 52, top: 3, bottom: 1),
        child: Row(
          children: [
            Text(typing.length > 1 ? "Several " : "${typing[0]["user_name"]} ", style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
            Text(typing.length > 1 ? "are typing..." : "is typing....", style: TextStyle(color: Colors.grey[700], fontSize: 12.5, fontWeight: FontWeight.w300)),
          ],
        ),
      ) : Container(height: 19)
    ); 
  }
}