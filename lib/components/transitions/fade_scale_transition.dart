import 'package:flutter/material.dart';

import 'modal.dart';

class FadeScaleTransitionConfiguration extends ModalConfiguration {
  const FadeScaleTransitionConfiguration({
    Color barrierColor = Colors.black54,
    bool barrierDismissible = true,
    Duration transitionDuration = const Duration(milliseconds: 150),
    Duration reverseTransitionDuration = const Duration(milliseconds: 75),
    String barrierLabel = 'Dismiss',
  }) : super(
          barrierColor: barrierColor,
          barrierDismissible: barrierDismissible,
          barrierLabel: barrierLabel,
          transitionDuration: transitionDuration,
          reverseTransitionDuration: reverseTransitionDuration,
        );

  @override
  Widget transitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeScaleTransition(
      animation: animation,
      child: child,
    );
  }
}

class FadeScaleOutTransitionConfiguration extends ModalConfiguration {
  const FadeScaleOutTransitionConfiguration({
    Color barrierColor = Colors.black54,
    bool barrierDismissible = true,
    Duration transitionDuration = const Duration(milliseconds: 150),
    Duration reverseTransitionDuration = const Duration(milliseconds: 75),
    String barrierLabel = 'Dismiss',
  }) : super(
          barrierColor: barrierColor,
          barrierDismissible: barrierDismissible,
          barrierLabel: barrierLabel,
          transitionDuration: transitionDuration,
          reverseTransitionDuration: reverseTransitionDuration,
        );

  @override
  Widget transitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeScaleOutTransition(
      animation: animation,
      child: child,
    );
  }
}
class FadeScaleTransition extends StatelessWidget {
  const FadeScaleTransition({
    Key? key,
    required this.animation,
    this.child,
  }) : super(key: key);
  final Animation<double> animation;
  final Widget? child;

  static final Animatable<double> _fadeInTransition = CurveTween(
    curve: const Interval(0.0, 0.3),
  );
  static final Animatable<double> _scaleInTransition = Tween<double>(
    begin: 0.80,
    end: 1.00,
  ).chain(CurveTween(curve: decelerateEasing));
  static final Animatable<double> _fadeOutTransition = Tween<double>(
    begin: 1.0,
    end: 0.0,
  );

  @override
  Widget build(BuildContext context) {
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder: (
        BuildContext context,
        Animation<double> animation,
        Widget? child,
      ) {
        return FadeTransition(
          opacity: _fadeInTransition.animate(animation),
          child: ScaleTransition(
            scale: _scaleInTransition.animate(animation),
            child: child,
          ),
        );
      },
      reverseBuilder: (
        BuildContext context,
        Animation<double> animation,
        Widget? child,
      ) {
        return FadeTransition(
          opacity: _fadeOutTransition.animate(animation),
          child: child,
        );
      },
      child: child,
    );
  }
}

class FadeScaleOutTransition extends StatelessWidget {
  const FadeScaleOutTransition({
    Key? key,
    required this.animation,
    this.child,
  }) : super(key: key);
  final Animation<double> animation;
  final Widget? child;

  static final Animatable<double> _fadeInTransition = CurveTween(
    curve: const Interval(0.0, 0.3),
  );
  static final Animatable<double> _scaleInTransition = Tween<double>(
    begin: 0.80,
    end: 1.00,
  ).chain(CurveTween(curve: decelerateEasing));
  static final Animatable<double> _scaleOutTransition = Tween<double>(
    begin: 1.00,
    end: 0.80
  ).chain(CurveTween(curve: decelerateEasing));
  static final Animatable<double> _fadeOutTransition = Tween<double>(
    begin: 1.0,
    end: 0.0,
  );

  @override
  Widget build(BuildContext context) {
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder: (
        BuildContext context,
        Animation<double> animation,
        Widget? child,
      ) {
        return FadeTransition(
          opacity: _fadeInTransition.animate(animation),
          child: ScaleTransition(
            scale: _scaleInTransition.animate(animation),
            child: child,
          ),
        );
      },
      reverseBuilder: (
        BuildContext context,
        Animation<double> animation,
        Widget? child,
      ) {
        return FadeTransition(
          opacity: _fadeOutTransition.animate(animation),
          child: ScaleTransition(
            scale: _scaleOutTransition.animate(animation),
            child: child
          ),
        );
      },
      child: child,
    );
  }
}
