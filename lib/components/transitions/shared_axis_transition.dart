import 'package:flutter/material.dart';

enum SharedAxisTransitionType {
  vertical,
  horizontal,
  scaled,
}

class SharedAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  const SharedAxisPageTransitionsBuilder({
    required this.transitionType,
    this.fillColor,
  });

  final SharedAxisTransitionType transitionType;
  final Color? fillColor;

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: transitionType,
      fillColor: fillColor,
      child: child,
    );
  }
}

class SharedAxisTransition extends StatelessWidget {
  const SharedAxisTransition({
    Key? key,
    required this.animation,
    required this.secondaryAnimation,
    required this.transitionType,
    this.fillColor,
    this.child,
  }) : super(key: key);

  final Animation<double> animation;

  final Animation<double> secondaryAnimation;

  final SharedAxisTransitionType transitionType;

  final Color? fillColor;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final Color color = fillColor ?? Theme.of(context).canvasColor;
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder: (
        BuildContext context,
        Animation<double> animation,
        Widget? child,
      ) {
        return _EnterTransition(
          animation: animation,
          transitionType: transitionType,
          child: child,
        );
      },
      reverseBuilder: (
        BuildContext context,
        Animation<double> animation,
        Widget? child,
      ) {
        return _ExitTransition(
          animation: animation,
          transitionType: transitionType,
          reverse: true,
          fillColor: color,
          child: child,
        );
      },
      child: DualTransitionBuilder(
        animation: ReverseAnimation(secondaryAnimation),
        forwardBuilder: (
          BuildContext context,
          Animation<double> animation,
          Widget? child,
        ) {
          return _EnterTransition(
            animation: animation,
            transitionType: transitionType,
            reverse: true,
            child: child,
          );
        },
        reverseBuilder: (
          BuildContext context,
          Animation<double> animation,
          Widget? child,
        ) {
          return _ExitTransition(
            animation: animation,
            transitionType: transitionType,
            fillColor: color,
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}

class _EnterTransition extends StatelessWidget {
  const _EnterTransition({
    required this.animation,
    required this.transitionType,
    this.reverse = false,
    this.child,
  });

  final Animation<double> animation;
  final SharedAxisTransitionType transitionType;
  final Widget? child;
  final bool reverse;

  static final Animatable<double> _fadeInTransition = CurveTween(
    curve: decelerateEasing,
  ).chain(CurveTween(curve: const Interval(0.3, 1.0)));

  static final Animatable<double> _scaleDownTransition = Tween<double>(
    begin: 1.10,
    end: 1.00,
  ).chain(CurveTween(curve: standardEasing));

  static final Animatable<double> _scaleUpTransition = Tween<double>(
    begin: 0.80,
    end: 1.00,
  ).chain(CurveTween(curve: standardEasing));

  @override
  Widget build(BuildContext context) {
    switch (transitionType) {
      case SharedAxisTransitionType.horizontal:
        final Animatable<Offset> slideInTransition = Tween<Offset>(
          begin: Offset(!reverse ? 30.0 : -30.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: standardEasing));

        return FadeTransition(
          opacity: _fadeInTransition.animate(animation),
          child: AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              return Transform.translate(
                offset: slideInTransition.evaluate(animation),
                child: child,
              );
            },
            child: child,
          ),
        );
      case SharedAxisTransitionType.vertical:
        final Animatable<Offset> slideInTransition = Tween<Offset>(
          begin: Offset(0.0, !reverse ? 30.0 : -30.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: standardEasing));

        return FadeTransition(
          opacity: _fadeInTransition.animate(animation),
          child: AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              return Transform.translate(
                offset: slideInTransition.evaluate(animation),
                child: child,
              );
            },
            child: child,
          ),
        );
      case SharedAxisTransitionType.scaled:
        return FadeTransition(
          opacity: _fadeInTransition.animate(animation),
          child: ScaleTransition(
            scale: (!reverse ? _scaleUpTransition : _scaleDownTransition)
                .animate(animation),
            child: child,
          ),
        );
    }
  }
}

class _ExitTransition extends StatelessWidget {
  const _ExitTransition({
    required this.animation,
    required this.transitionType,
    this.reverse = false,
    required this.fillColor,
    this.child,
  });

  final Animation<double> animation;
  final SharedAxisTransitionType transitionType;
  final bool reverse;
  final Color fillColor;
  final Widget? child;

  static final Animatable<double> _fadeOutTransition = _FlippedCurveTween(
    curve: accelerateEasing,
  ).chain(CurveTween(curve: const Interval(0.0, 0.3)));

  static final Animatable<double> _scaleUpTransition = Tween<double>(
    begin: 1.00,
    end: 1.10,
  ).chain(CurveTween(curve: standardEasing));

  static final Animatable<double> _scaleDownTransition = Tween<double>(
    begin: 1.00,
    end: 0.80,
  ).chain(CurveTween(curve: standardEasing));

  @override
  Widget build(BuildContext context) {
    switch (transitionType) {
      case SharedAxisTransitionType.horizontal:
        final Animatable<Offset> slideOutTransition = Tween<Offset>(
          begin: Offset.zero,
          end: Offset(!reverse ? -30.0 : 30.0, 0.0),
        ).chain(CurveTween(curve: standardEasing));

        return FadeTransition(
          opacity: _fadeOutTransition.animate(animation),
          child: Container(
            color: fillColor,
            child: AnimatedBuilder(
              animation: animation,
              builder: (BuildContext context, Widget? child) {
                return Transform.translate(
                  offset: slideOutTransition.evaluate(animation),
                  child: child,
                );
              },
              child: child,
            ),
          ),
        );
      case SharedAxisTransitionType.vertical:
        final Animatable<Offset> slideOutTransition = Tween<Offset>(
          begin: Offset.zero,
          end: Offset(0.0, !reverse ? -30.0 : 30.0),
        ).chain(CurveTween(curve: standardEasing));

        return FadeTransition(
          opacity: _fadeOutTransition.animate(animation),
          child: Container(
            color: fillColor,
            child: AnimatedBuilder(
              animation: animation,
              builder: (BuildContext context, Widget? child) {
                return Transform.translate(
                  offset: slideOutTransition.evaluate(animation),
                  child: child,
                );
              },
              child: child,
            ),
          ),
        );
      case SharedAxisTransitionType.scaled:
        return FadeTransition(
          opacity: _fadeOutTransition.animate(animation),
          child: Container(
            color: fillColor,
            child: ScaleTransition(
              scale: (!reverse ? _scaleUpTransition : _scaleDownTransition)
                  .animate(animation),
              child: child,
            ),
          ),
        );
    }
  }
}

class _FlippedCurveTween extends CurveTween {
  _FlippedCurveTween({
    required Curve curve,
  }) : super(curve: curve);

  @override
  double transform(double t) => 1.0 - super.transform(t);
}
