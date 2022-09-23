import 'package:flutter/material.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/providers/providers.dart';

class SnappyApps extends StatefulWidget {
  final Function changeView;
  final int workspaceId;
  const SnappyApps({Key? key, required this.changeView, required this.workspaceId}) : super(key: key);

  @override
  State<SnappyApps> createState() => _SnappyAppsState();
}

class _SnappyAppsState extends State<SnappyApps> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;

    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 28),
            child: Text("Quản lý chấm công",
            style: TextStyle(fontSize: 16),),
          ),
          Row(
            children: [
              Container(
                width: 213, height: 58,
                margin: EdgeInsets.only(right: 34),
                child: OutlinedButton(
                  onPressed: () => widget.changeView(4),
                  child: Text(
                    'Chấm công',
                    style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                  ),),
              ),
              Container(
                width: 213, height: 58,
                child: OutlinedButton(
                  onPressed: () => widget.changeView(2),
                  child: Text(
                    'Yêu cầu phê duyệt',
                    style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                  ),),
              )
            ],
          ),
          Container(
            margin: EdgeInsets.only(bottom: 28, top: 36),
            child: Text("Quản lý tài liệu",
            style: TextStyle(fontSize: 16),),
          ),
          Row(
            children: [
              Container(
                width: 213, height: 58,
                margin: EdgeInsets.only(right: 34),
                child: OutlinedButton(
                  onPressed: () {
                  },
                  child: Text(
                    'Tài liệu của bạn',
                    style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                  ),),
              ),
              Container(
                width: 213, height: 58,
                child: OutlinedButton(
                  onPressed: () {
                    widget.changeView(3);
                  },
                  child: Text(
                    'Quản lý tài liệu',
                    style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                  ),),
              )
            ],
          )
        ],
      )
    );
  }
}