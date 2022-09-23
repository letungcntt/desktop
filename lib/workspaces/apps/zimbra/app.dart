import 'package:flutter/material.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/workspaces/apps/zimbra/dashboard.dart';
import 'package:workcake/workspaces/apps/zimbra/service.dart';

class AppZimbra extends StatefulWidget {
  const AppZimbra({Key? key}) : super(key: key);

  @override
  State<AppZimbra> createState() => _AppZimbraState();
}

class _AppZimbraState extends State<AppZimbra> {
  bool loginned = false;
  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return Container(
      color: isDark ? Palette.backgroundRightSiderDark : Color(0xFFf5f5f5),
      child: DashBoardZimbra(
        key: ServiceZimbra.dashboardZimbra,
        workspaceId: Provider.of<Workspaces>(context, listen: true).currentWorkspace["id"],
      ),
    );
  }
}