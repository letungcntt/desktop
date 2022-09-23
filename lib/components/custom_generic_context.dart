import 'dart:async';

import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';

class CustomGenericContextMenu extends StatefulWidget {
  const CustomGenericContextMenu({
    Key? key,
    required this.buttonConfigs,
    this.injectDividers = false,
    this.autoClose = true,
    required this.otherWidget,
  }) : super(key: key);
  final bool injectDividers;
  final bool autoClose;
  final List<ContextMenuButtonConfig?> buttonConfigs;
  final List<Widget> otherWidget;
  @override
  _GenericContextMenuState createState() => _GenericContextMenuState();
}

class _GenericContextMenuState extends State<CustomGenericContextMenu> with ContextMenuStateMixin {
  @override
  Widget build(BuildContext context) {
    if ((widget.buttonConfigs.isEmpty)) {
      scheduleMicrotask(() => context.contextMenuOverlay.close());
      return Container();
    }
    if (widget.injectDividers) {
      for (var i = widget.buttonConfigs.length - 2; i-- > 1; i++) {
        widget.buttonConfigs.add(null);
      }
    }
    return cardBuilder.call(
      context,
      widget.otherWidget + widget.buttonConfigs.map(
        (config) {
          if (config == null) return buildDivider();
          VoidCallback? action = config.onPressed;
          if (widget.autoClose && action != null) {
            action = () => handlePressed(context, config.onPressed!);
          }
          return buttonBuilder.call(
              context,
              ContextMenuButtonConfig(
                config.label,
                icon: config.icon,
                iconHover: config.iconHover,
                shortcutLabel: config.shortcutLabel,
                onPressed: action,
              ));
        },
      ).toList(),
    );
  }
}
