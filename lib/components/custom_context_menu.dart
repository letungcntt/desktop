import 'package:context_menus/context_menus.dart';
import 'package:flutter/widgets.dart';

class ContextMenu extends StatelessWidget {
  const ContextMenu({
    Key? key,
    required this.child,
    required this.contextMenu,
    this.isEnabled = true,
    this.onTap
  }) : super(key: key);

  final Widget child;
  final Widget contextMenu;
  final bool isEnabled;
  final Function? onTap;

  @override
  Widget build(BuildContext context) {
    void showMenu() {
      if(onTap != null) {
        onTap!();
      }
      context.contextMenuOverlay.show(contextMenu);
    }

    if (isEnabled == false) return child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: showMenu,
      child: child,
    );
  }
}
