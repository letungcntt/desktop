import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/models/models.dart';

class ChannelMemberBottom extends StatefulWidget {
  final isDelete;
  final checkboxs;

  ChannelMemberBottom({
    Key? key,
    this.isDelete, 
    this.checkboxs
  }) : super(key: key);

  @override
  _ChannelMemberBottomState createState() => _ChannelMemberBottomState();
}

class _ChannelMemberBottomState extends State<ChannelMemberBottom> {
  onChangeChannelInfo() async {
    List list = [];
    final auth = Provider.of<Auth>(context, listen: false);
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final channelMember = Provider.of<Channels>(context, listen: false).channelMember;
    final selectedMember = Provider.of<Channels>(context, listen: false).selectedMember;

    selectedMember.forEach((e) {
      list.add(channelMember[e]["id"]);
    });

    await Provider.of<Workspaces>(context, listen: false).deleteChannelMember(auth.token, currentWorkspace["id"], currentChannel["id"], list);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    List checkboxs = Provider.of<Channels>(context, listen: true).selectedMember;

    return widget.isDelete ? BottomAppBar(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        height: 60,
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  this.setState(() { checkboxs = []; });
                },
                child: Text(
                  S.current.cancel,
                  style: TextStyle(color: Colors.blueAccent, fontSize: 15))
                ),
              TextButton(
                // disabledColor: Colors.lightBlue[200],
                // shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(20.0) ),
                // color: Colors.blue[500],
                onPressed: checkboxs.length > 0 ? () => onChangeChannelInfo() : null,
                child: Text(
                  S.current.confirm,
                  style: TextStyle(color: Colors.white, fontSize: 14)
                )
              )
            ]
          )]
        )
      )
    ) : Container(height: 0);
  }
}
