import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:workcake/common/utils.dart';

/// Build the Scroll Thumb and label using the current configuration
typedef Widget ScrollThumbBuilder(
  Color backgroundColor,
  Animation<double> thumbAnimation,
  double height
);

/// Build a Text widget using the current scroll offset
typedef Text LabelTextBuilder(double offsetY);

/// A widget that will display a BoxScrollView with a ScrollThumb that can be dragged
/// for quick navigation of the BoxScrollView.
class DraggableScrollbar extends StatefulWidget {
  /// The view that will be scrolled with the scroll thumb
  final Widget? child;

  /// The id
  final id;

  /// A function that builds a thumb using the current configuration
  final ScrollThumbBuilder? scrollThumbBuilder;

  /// The height of the scroll thumb
  final double? heightScrollThumb;

  /// The background color of the label and thumb
  final Color? backgroundColor;

  /// The amount of padding that should surround the thumb
  final EdgeInsetsGeometry? padding;

  /// Determines how quickly the scrollbar will animate in and out
  final Duration? scrollbarAnimationDuration;

  /// How long should the thumb be visible before fading out
  final Duration? scrollbarTimeToFade;

  /// The ScrollController for the BoxScrollView
  final ScrollController? controller;

  /// Determines scrollThumb displaying. If you draw own ScrollThumb and it is true you just don't need to use animation parameters in [scrollThumbBuilder]
  final bool? alwaysVisibleScrollThumb;

  final bool? isSendMessage;

  final Function? onChangeIsSendMessage;

  final int? itemCount;

  final ValueChanged<bool> onChanged;

  DraggableScrollbar({
    Key? key,
    this.alwaysVisibleScrollThumb = false,
    this.id,
    @required this.heightScrollThumb,
    @required this.backgroundColor,
    @required this.scrollThumbBuilder,
    @required this.child,
    @required this.controller,
    this.onChangeIsSendMessage,
    this.isSendMessage,
    this.itemCount,
    this.padding,
    this.scrollbarAnimationDuration = const Duration(milliseconds: 300),
    this.scrollbarTimeToFade = const Duration(seconds: 1),
    required this.onChanged
  })  : assert(controller != null),
        assert(scrollThumbBuilder != null),
        super(key: key);

  DraggableScrollbar.rrect({
    Key? key,
    Key? scrollThumbKey,
    this.alwaysVisibleScrollThumb = false,
    @required this.child,
    @required this.controller,
    this.isSendMessage,
    this.id,
    this.onChangeIsSendMessage,
    this.heightScrollThumb = 48.0,
    this.backgroundColor = Colors.white,
    this.padding,
    this.itemCount,
    this.scrollbarAnimationDuration = const Duration(milliseconds: 200),
    this.scrollbarTimeToFade = const Duration(seconds: 1),
    required this.onChanged
  })  : 
        scrollThumbBuilder = _thumbRRectBuilder(scrollThumbKey ?? Key(id.toString()), alwaysVisibleScrollThumb!),
        super(key: key);

  @override
  DraggableScrollbarState createState() => DraggableScrollbarState();

  static buildScrollThumbAndLabel({
      @required Widget? scrollThumb,
      @required Color? backgroundColor,
      @required Animation<double>? thumbAnimation,
      @required BoxConstraints? labelConstraints,
      @required bool? alwaysVisibleScrollThumb
    }) {

    if (alwaysVisibleScrollThumb!) {
      return scrollThumb;
    }

    return AnimatedBuilder(
      animation: thumbAnimation!,
      builder: (context, child) => thumbAnimation.value == 0.0 ? Container() : child ?? Container(),
      child: SlideTransition(
        position: Tween(
          begin: Offset(0.3, 0.0),
          end: Offset(0.0, 0.0),
        ).animate(thumbAnimation),
        child: FadeTransition(
          opacity: thumbAnimation,
          child: scrollThumb,
        ),
      ),
    );
  }

  static ScrollThumbBuilder _thumbRRectBuilder(
      Key scrollThumbKey, bool alwaysVisibleScrollThumb) {
    return (
      Color backgroundColor,
      Animation<double> thumbAnimation,
      double height, {
      Text? labelText,
      BoxConstraints? labelConstraints,
    }) {
      final scrollThumb = Material(
        elevation: 4.0,
        child: Container(
          constraints: BoxConstraints.tight(
            Size(10.0, height),
          ),
        ),
        color: backgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(7.0)),
      );

      return buildScrollThumbAndLabel(
        scrollThumb: scrollThumb,
        backgroundColor: backgroundColor,
        thumbAnimation: thumbAnimation,
        labelConstraints: labelConstraints,
        alwaysVisibleScrollThumb: alwaysVisibleScrollThumb,
      );
    };
  }
}

class ScrollLabel extends StatelessWidget {
  final Animation<double>? animation;
  final Color? backgroundColor;
  final Text? child;

  final BoxConstraints constraints;
  static const BoxConstraints _defaultConstraints = BoxConstraints.tightFor(width: 72.0);

  const ScrollLabel({
    Key? key,
    @required this.child,
    @required this.animation,
    @required this.backgroundColor,
    this.constraints = _defaultConstraints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation!,
      child: Container(
        margin: EdgeInsets.only(right: 6.0),
        child: Material(
          elevation: 4.0,
          color: backgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
          child: Container(
            constraints: constraints,
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

class DraggableScrollbarState extends State<DraggableScrollbar> with TickerProviderStateMixin {
  double _barOffset = 0.0;
  double _viewOffset = 0.0;
  bool? _isDragInProcess;
  bool? isLoadding = false;

  AnimationController? _thumbAnimationController;
  Animation<double>? _thumbAnimation;
  Timer? _fadeoutTimer;

  ScrollNotification? _notification;

  @override
  void initState() {
    super.initState();
    _barOffset = 0.0;
    _viewOffset = 0.0;
    _isDragInProcess = false;

    _thumbAnimationController = AnimationController(
      vsync: this,
      duration: widget.scrollbarAnimationDuration,
    );

    _thumbAnimation = CurvedAnimation(
      parent: _thumbAnimationController!,
      curve: Curves.fastOutSlowIn,
    );
  }

  void _onVerticalDragStart(DragStartDetails details) {
    setState(() {
      _isDragInProcess = true;
      _thumbAnimationController!.reverse();
      _fadeoutTimer?.cancel();
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      if (_thumbAnimationController!.status != AnimationStatus.forward) {
        _thumbAnimationController!.forward();
      }
      if (_isDragInProcess!) {
        _barOffset -= details.delta.dy;

        if (_barOffset < barMinScrollExtent) {
          _barOffset = barMinScrollExtent;
        }
        if (_barOffset > barMaxScrollExtent) {
          _barOffset = barMaxScrollExtent;
        }

        double viewDelta = getScrollViewDelta(details.delta.dy, barMaxScrollExtent, viewMaxScrollExtent);

        _viewOffset = widget.controller!.position.pixels - viewDelta;

        if (_viewOffset < widget.controller!.position.minScrollExtent) {
          _viewOffset = widget.controller!.position.minScrollExtent;
        }
        if (_viewOffset > viewMaxScrollExtent) {
          _viewOffset = viewMaxScrollExtent;
        }
        widget.controller!.jumpTo(_viewOffset);
      }
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _fadeoutTimer = Timer(widget.scrollbarTimeToFade ?? Duration(), () {
      _fadeoutTimer = null;
    });
    setState(() {
      _isDragInProcess = false;
    });
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSendMessage != widget.isSendMessage && (widget.isSendMessage ?? false)) {
      widget.controller!.jumpTo(widget.controller!.initialScrollOffset);
      _barOffset = 0;
      this.setState(() {});
      widget.onChangeIsSendMessage!(false);
    }

    if (oldWidget.itemCount != widget.itemCount) {
      this.setState(() {
        isLoadding = true;
      });
    }

    if (oldWidget.id != widget.id) {
      widget.controller!.jumpTo(widget.controller!.initialScrollOffset);
      _barOffset = 0.0;
      setState(() {});
    }
  }

  double _getScrollToTrack(ScrollMetrics metrics, double thumbExtent, double scrollDelta) {
    final double scrollableExtent = metrics.maxScrollExtent - metrics.minScrollExtent + scrollDelta;
    this.setState(() {
        isLoadding = false;
      });

    final double fractionPast = (scrollableExtent > 0)
      ? ((metrics.pixels - metrics.minScrollExtent) / scrollableExtent).clamp(0.0, 1.0)
      : 0;

    return (fractionPast) * (metrics.viewportDimension - thumbExtent);
  }

  @override
  void dispose() {
    _thumbAnimationController!.dispose();
    _fadeoutTimer?.cancel();
    super.dispose();
  }

  double get barMaxScrollExtent => (MediaQuery.of(context).size.height - 150) - (widget.heightScrollThumb ?? 0.0);

  double get barMinScrollExtent => 0.0;

  double get viewMaxScrollExtent => widget.controller!.position.maxScrollExtent;

  double get viewMinScrollExtent => widget.controller!.position.minScrollExtent;

  bool get isVisibleWidget => _isVisibleWidget;

  bool _isVisibleWidget = false;

  onIsVisibleWidget() {
    bool value = true;
    BuildContext? currentContext = Utils.getHoverMessageContext();
    if (currentContext == null || _notification == null) return false;

    try {
      var renderObject = currentContext.findRenderObject() as RenderObject;
      RenderAbstractViewport? viewport = RenderAbstractViewport.of(renderObject);
      var offsetToRevealBottom = viewport!.getOffsetToReveal(renderObject, 1.0);
      var offsetToRevealTop = viewport.getOffsetToReveal(renderObject, 0.0);

      if (offsetToRevealBottom.offset + 25.0 > _notification!.metrics.pixels) {
        value = false;
      } else if(_notification!.metrics.pixels > offsetToRevealTop.offset) {

      } else {
        value = true;
      }

      _isVisibleWidget = value;
      widget.onChanged(_isVisibleWidget);
    } catch (err) {
      // print(err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {

      return NotificationListener<ScrollNotification>(
        // ignore: missing_return
        onNotification: (ScrollNotification notification) {
          _notification = notification;
          onIsVisibleWidget();
          return changePosition(notification) ?? false;
        },
        child: Stack(
          children: <Widget>[
            RepaintBoundary(
              child: widget.child,
            ),
            RepaintBoundary(
              child: GestureDetector(
                onVerticalDragStart: _onVerticalDragStart,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                child: Container(
                  alignment: Alignment.bottomRight,
                  margin: EdgeInsets.only(bottom: _barOffset, right: 1.4),
                  padding: widget.padding,
                  child: widget.scrollThumbBuilder!(
                    widget.backgroundColor ?? Colors.grey[600]!,
                    _thumbAnimation ?? CurvedAnimation(parent: _thumbAnimationController!, curve: Curves.fastOutSlowIn),
                    widget.heightScrollThumb ?? 0.0
                  ),
                ),
              )
            ),
          ],
        ),
      );
    });
  }

  changePosition(ScrollNotification notification) {
    if (_isDragInProcess!) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      if (!this.mounted) return;
      setState(() {
        if (notification is ScrollUpdateNotification) {
          if (!isLoadding!) {
            _barOffset += getBarDelta(
              notification.scrollDelta!,
              barMaxScrollExtent,
              viewMaxScrollExtent,
            );
          } else _barOffset = _getScrollToTrack(notification.metrics, 48, notification.scrollDelta!);

          _viewOffset += notification.scrollDelta!;
          if (_barOffset < barMinScrollExtent) {
            _barOffset = barMinScrollExtent;
          }
          if (_barOffset > barMaxScrollExtent) {
            _barOffset = barMaxScrollExtent;
          }
          if (_viewOffset < widget.controller!.position.minScrollExtent) {
            _viewOffset = widget.controller!.position.minScrollExtent;
          }
          if (_viewOffset > viewMaxScrollExtent) {
            _viewOffset = viewMaxScrollExtent;
          }
        }

        if (viewMaxScrollExtent <= notification.metrics.pixels) {
          _barOffset = barMaxScrollExtent;
        }

        if (notification.metrics.pixels == 0) {
          _barOffset = 0;
        }
        if (notification is ScrollUpdateNotification || notification is OverscrollNotification) {
          if (_thumbAnimationController!.status != AnimationStatus.forward) {
            _thumbAnimationController!.forward();
          }
          _fadeoutTimer?.cancel();
          _fadeoutTimer = Timer(widget.scrollbarTimeToFade!, () {
            _thumbAnimationController!.reverse();
            _fadeoutTimer = null;
          });
        }
      });
    });
  }

  double getBarDelta(
    double scrollViewDelta,
    double barMaxScrollExtent,
    double viewMaxScrollExtent,
  ) {
    return scrollViewDelta * barMaxScrollExtent / viewMaxScrollExtent;
  }

  double getScrollViewDelta(
    double barDelta,
    double barMaxScrollExtent,
    double viewMaxScrollExtent,
  ) {
    return barDelta * viewMaxScrollExtent / barMaxScrollExtent;
  }
}