import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'fade_scale_transition.dart';
typedef _ModalTransitionBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
);

Future<T?> showModal<T>({
  required BuildContext context,
  ModalConfiguration configuration = const FadeScaleTransitionConfiguration(),
  bool useRootNavigator = true,
  required WidgetBuilder builder,
  RouteSettings? routeSettings,
  ui.ImageFilter? filter,
}) {
  String? barrierLabel = configuration.barrierLabel;
  if (configuration.barrierDismissible && configuration.barrierLabel == null) {
    barrierLabel = MaterialLocalizations.of(context).modalBarrierDismissLabel;
  }
  assert(!configuration.barrierDismissible || barrierLabel != null);
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    _ModalRoute<T>(
      barrierColor: configuration.barrierColor,
      barrierDismissible: configuration.barrierDismissible,
      barrierLabel: barrierLabel,
      transitionBuilder: configuration.transitionBuilder,
      transitionDuration: configuration.transitionDuration,
      reverseTransitionDuration: configuration.reverseTransitionDuration,
      builder: builder,
      routeSettings: routeSettings,
      filter: filter,
    ),
  );
}

class _ModalRoute<T> extends PopupRoute<T> {
  _ModalRoute({
    this.barrierColor,
    this.barrierDismissible = true,
    this.barrierLabel,
    required this.transitionDuration,
    required this.reverseTransitionDuration,
    required _ModalTransitionBuilder transitionBuilder,
    required this.builder,
    RouteSettings? routeSettings,
    ui.ImageFilter? filter,
  })  : assert(!barrierDismissible || barrierLabel != null),
        _transitionBuilder = transitionBuilder,
        super(filter: filter, settings: routeSettings);

  @override
  final Color? barrierColor;

  @override
  final bool barrierDismissible;

  @override
  final String? barrierLabel;

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;
  final WidgetBuilder builder;

  final _ModalTransitionBuilder _transitionBuilder;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      child: SafeArea(
        child: Builder(
          builder: (BuildContext context) {
            final Widget child = Builder(builder: builder);
            return Theme(data: theme, child: child);
          },
        ),
      ),
      scopesRoute: true,
      explicitChildNodes: true,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _transitionBuilder(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

abstract class ModalConfiguration {
  const ModalConfiguration({
    required this.barrierColor,
    required this.barrierDismissible,
    this.barrierLabel,
    required this.transitionDuration,
    required this.reverseTransitionDuration,
  }) : assert(!barrierDismissible || barrierLabel != null);

  final Color barrierColor;

  final bool barrierDismissible;

  final String? barrierLabel;

  final Duration transitionDuration;

  final Duration reverseTransitionDuration;


  Widget transitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  );
}
