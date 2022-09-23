import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/responsive_grid.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/providers/providers.dart';

class ListApp extends StatefulWidget {
  final workspaceId;
  const ListApp({Key? key, required this.workspaceId}) : super(key: key);

  @override
  State<ListApp> createState() => _ListAppState();
}

class _ListAppState extends State<ListApp> {
  bool isHover = false;
  List listApp = [];

  @override
  void initState() {
    super.initState();
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    this.setState(() {
      listApp = currentWorkspace["app_ids"] ?? [];
    });
  }

  @override
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId) {
      final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      setState(() => listApp = currentWorkspace["app_ids"]);
    }
  }

  handleAddApp(token, app, currentWs) async {
    final currentMember = Provider.of<Workspaces>(context, listen: false).currentMember;
    if (currentMember["role_id"] <= 2) {
      if (!(currentWs['app_ids'] ?? []).contains(app['id'])) {
        List list = currentWs["app_ids"] ?? [];
        Map workspace = new Map.from(currentWs);
        if (!list.contains(app["id"])) {
          workspace["app_ids"] = list + [app["id"]];
        }
        setState(() => listApp = workspace["app_ids"]);
        await Provider.of<Workspaces>(context, listen: false).changeWorkspaceInfo(token, currentWs["id"], workspace);
      } else {
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
              new Center(child: new Container(child: new Text('App đã được thêm vào workspace này.')))
          ])
        );
      }
    } else {
      showModal(
        context: context,
        builder: (_) => SimpleDialog(
        children: <Widget>[
            new Center(child: new Container(child: new Text('Bạn không có đủ quyền để thực hiện thao tác')))
        ])
      );
    }
  }

  handleRemoveApp(token, app, currentWs) async {
    final currentMember = Provider.of<Workspaces>(context, listen: false).currentMember;
    if (currentMember["role_id"] <= 2) {
      if (currentWs['app_ids'].contains(app['id'])) {
        List list = currentWs["app_ids"] ?? [];
        Map workspace = new Map.from(currentWs);
        if (list.contains(app["id"])) {
          workspace["app_ids"].remove(app["id"]);
        }
        setState(() => listApp = workspace["app_ids"]);
        await Provider.of<Workspaces>(context, listen: false).changeWorkspaceInfo(token, currentWs["id"], workspace);
      } else {
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
              new Center(child: new Container(child: new Text('App đã bị xoá khỏi workspace này')))
          ])
        );
      }
    } else {
      showModal(
        context: context,
        builder: (_) => SimpleDialog(
        children: <Widget>[
            new Center(child: new Container(child: new Text('Bạn không có đủ quyền để thực hiện thao tác')))
        ])
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWorkspace = Provider.of<Workspaces>(context, listen: true).currentWorkspace;
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final listActive = listAllApp.where((e) => listApp.contains(e["id"])).toList();
    final listDeactive = listAllApp.where((e) => !listApp.contains(e["id"])).toList();

    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xffe6f7ff),
              borderRadius: BorderRadius.all(Radius.circular(4)),
              // border: Border.all(color: Color(0xff91d5ff))
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.exclamationmark_circle, color: Colors.black87, size: 16),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "Hiện tại các ứng dụng đang được phát triển. Nếu bạn có nhu cầu kết nối và sử dụng các ứng dụng, hãy liên hệ với đội ngũ admin.",
                    style: TextStyle(color: Colors.black87)
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          if (listApp.length > 0) Container(
            margin: EdgeInsets.only(bottom: 16, left: 10, right: 10),
            child: Text(
              "${listApp.length} apps in ${currentWorkspace['name']}",
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87
              )
            )
          ),
          if (listApp.length > 0) Expanded(
            child: ResponsiveGridList(
              desiredItemWidth: 300,
              minSpacing: 10,
              children: listActive.map((i) {
                return Container(
                  // height: 130,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9))
                  ),
                  alignment: Alignment(0, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.asset(
                                i["avatar_app"].toString(),
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ),
                          SizedBox(width: 16,),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  i["name"].toString(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight
                                  )
                                ),
                                SizedBox(height: 2),
                                Text(
                                  i["description"].toString(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white70 : Colors.black87
                                  )
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            handleRemoveApp(auth.token, i, currentWorkspace);
                          },
                          child: Text(
                            'Remove',
                            style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                          ),)
                      ),
                    ],
                  ),
                );
              }).toList()
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            child: Text(
              "Recommend apps",
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87
              )
            )
          ),
          Expanded(
            child: ResponsiveGridList(
              desiredItemWidth: 300,
              minSpacing: 10,
              children: listDeactive.map((i) {
                return Container(
                  // height: 130,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9))
                  ),
                  alignment: Alignment(0, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.asset(
                                i["avatar_app"].toString(),
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ),
                          SizedBox(width: 16,),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  i["name"].toString(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight
                                  )
                                ),
                                SizedBox(height: 2),
                                Text(
                                  i["description"].toString(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white70 : Colors.black87
                                  )
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: i["id"] == 1 || i["id"] == 3 || i["id"] == 4 ? () {
                            handleAddApp(auth.token, i, currentWorkspace);
                          } : null,
                          child: Text(
                            'Add',
                            style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                          ),)
                      ),
                    ],
                  ),
                );
              }).toList()
            ),
          ),
        ],
      )
    );
  }
}