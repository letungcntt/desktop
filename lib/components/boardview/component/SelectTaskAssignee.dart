import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:popover/popover.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/providers/providers.dart';

import 'ListMember.dart';

class SelectTaskAssignee extends StatefulWidget {
  final members;
  final addOrRemoveTaskMember;

  const SelectTaskAssignee({
    Key? key,
    this.members,
    this.addOrRemoveTaskMember
  }) : super(key: key);

  @override
  State<SelectTaskAssignee> createState() => _SelectTaskAssigneeState();
}

class _SelectTaskAssigneeState extends State<SelectTaskAssignee> {
  findUser(id) {
    final members = Provider.of<Workspaces>(context, listen: false).members;
    final indexMember = members.indexWhere((e) => e["id"] == id);

    if (indexMember != -1) {
      return members[indexMember];
    } else {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        showPopover(
          context: context,
          backgroundColor: isDark ? Color(0xff2E2E2E) : Colors.white,
          transitionDuration: const Duration(milliseconds: 50),
          direction: PopoverDirection.bottom,
          barrierColor: Colors.transparent,
          width: 300,
          height: 400,
          arrowHeight: 0,
          arrowWidth: 0,
          bodyBuilder: (context) => ListMember(members: widget.members, addOrRemoveMember: widget.addOrRemoveTaskMember)
        );
      },
      child: Container(
        height: 40,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(PhosphorIcons.userPlus, size: 17, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
            SizedBox(width: 14),
            Text("Assignee", style: TextStyle(fontSize: 14, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight))
          ]
        )
      )
    );
  }
}
