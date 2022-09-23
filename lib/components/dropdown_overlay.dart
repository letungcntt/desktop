import 'package:flutter/material.dart';

class FunkyOverlay extends StatefulWidget {
  final Widget child;
  FunkyOverlay({required this.child});
  @override
  State<StatefulWidget> createState() => FunkyOverlayState();
}

class FunkyOverlayState extends State<FunkyOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scaleAnimation;
  late Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();

    controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 140));
    scaleAnimation =
        Tween(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: controller, curve: decelerateEasing));
    fadeAnimation = 
        CurveTween(curve: const Interval(0.0, 0.3)).animate(CurvedAnimation(parent: controller, curve: Curves.decelerate));

    controller.addListener(() {
      setState(() {});
    });

    controller.forward();
  }
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {  
    return ScaleTransition(
      alignment: Alignment.topRight,
      scale: scaleAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Material(
          elevation: 18,
          color: Colors.transparent,
          child: Container(
            decoration: ShapeDecoration(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0.0))),
            child: widget.child
          ),
        ),
      ),
    );
  }
}


class DropdownOverlay extends StatefulWidget{
  DropdownOverlay({
    Key? key,
    @required this.dropdownWindow,
    @required this.child,
    this.childOnTap,
    this.onTap,
    this.menuOffset = 8.8,
    this.menuDirection = MenuDirection.mid,
    this.width = 200,
    this.duration = 400,
    this.curve,
    this.isSizeTransition = false,
    this.isFadeTransition = false,
    this.isAnimated = false,
    this.decoration,
    this.onPop
  }) : super(key: key) ;
  DropdownOverlayState createState() => DropdownOverlayState();

  final dropdownWindow;
  final child;
  final childOnTap;
  final onTap;
  final double menuOffset;
  final MenuDirection menuDirection;
  final double width;
  final duration;
  final curve;
  final isSizeTransition;
  final isFadeTransition;
  final isAnimated;
  final decoration;
  final VoidCallback? onPop;
}

class DropdownOverlayState extends State<DropdownOverlay> {
  var dropdownRoute;
  var isTap = false;
  void removeDropdownRoute(){
    dropdownRoute?.dismiss();
    dropdownRoute = null;
    if (widget.onPop != null){
      widget.onPop!();
    }
  }
  void handleOnTap(){
    final ancestor = context.findAncestorStateOfType<State<MaterialApp>>();
    if (ancestor == null) return;
    final ancestorObject = ancestor.context.findRenderObject();
    final RenderBox itemBox = context.findRenderObject() as RenderBox;
    final Rect buttonRect = itemBox.localToGlobal(Offset.zero, ancestor: ancestorObject) & itemBox.size;
    if(widget.onTap != null){
      widget.onTap();
    }
    this.setState(() {
      isTap = true;
    });
    dropdownRoute = DropdownRoute(
      child: widget.dropdownWindow,
      buttonRect: buttonRect,
      menuOffset: widget.menuOffset,
      menuDirection: widget.menuDirection,
      width: widget.width,
      duration: widget.duration,
      curve: widget.curve,
      isSizeTransition: widget.isSizeTransition,
      isFadeTransition: widget.isFadeTransition,
      isAnimated: widget.isAnimated,
      decoration: widget.decoration,
    );
    Navigator.push(context, dropdownRoute).then((value){
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        removeDropdownRoute();
        if (mounted) {
          setState(() {
            isTap = false;
          });
        }
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: isTap && widget.childOnTap != null ? widget.childOnTap : widget.child,
      onTap: handleOnTap,
    );
  }
}

class DropdownRoute extends PopupRoute{
  DropdownRoute({
    @required this.child,
    this.buttonRect,
    this.menuOffset,
    this.menuDirection,
    this.width,
    this.duration,
    this.curve,
    this.isSizeTransition,
    this.isFadeTransition,
    this.isAnimated,
    this.decoration
  });
  final child;
  final buttonRect;
  final menuOffset;
  final menuDirection;
  final width;
  final duration;
  final curve;
  final isSizeTransition;
  final isFadeTransition;
  final isAnimated;
  final decoration;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return DropdownRoutePage(
      child: this.child,
      buttonRect: this.buttonRect,
      menuDirection: this.menuDirection,
      menuOffset: this.menuOffset,
      width: this.width,
      duration: this.duration,
      curve: this.curve,
      isSizeTransition: this.isSizeTransition,
      isFadeTransition: this.isFadeTransition,
      isAnimated: this.isAnimated,
      decoration: this.decoration
    );
  }
  void dismiss() {
     navigator?.removeRoute(this);
  }

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => Duration(milliseconds: 30);
}

class DropdownRoutePage extends StatefulWidget{
  DropdownRoutePage({
    @required this.child,
    this.buttonRect,
    this.menuDirection,
    this.menuOffset,
    this.width,
    this.duration,
    this.curve,
    this.isSizeTransition ,
    this.isFadeTransition ,
    this.isAnimated,
    this.decoration
  });
  final child;
  final buttonRect;
  final menuDirection;
  final menuOffset;
  final width;
  final duration;
  final curve;
  final isSizeTransition;
  final isFadeTransition;
  final isAnimated;
  final decoration;

  _DropdownRoutePageState createState() => _DropdownRoutePageState();
}

class _DropdownRoutePageState extends State<DropdownRoutePage> with TickerProviderStateMixin{
  var _controller;
  var _animation;
  @override
  initState(){
    super.initState();
    _controller = AnimationController(
      animationBehavior: AnimationBehavior.normal,
      duration: Duration(milliseconds: 200),
      vsync: this,
      value: 0,
      lowerBound: 0,
      upperBound: 1
    );
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve ?? Curves.fastOutSlowIn);
    _controller.forward();
  }

  @override
  dispose(){
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return CustomSingleChildLayout(
      delegate: DropdownMenuRouteLayout(
        buttonRect: widget.buttonRect,
        width: widget.width,
        menuOffset: widget.menuOffset,
        menuDirection: widget.menuDirection
      ),
      child: widget.isAnimated ? FunkyOverlay(child: widget.child,)
      : Material(
        type: MaterialType.transparency,
        elevation: 18,
        child: Container(
          decoration: widget.decoration ?? BoxDecoration(),
          child: widget.isSizeTransition ? 
            SizeTransition(
              sizeFactor: _animation,
              axisAlignment: 1.0,
              child: widget.child,
            ): FadeTransition(
              opacity: _animation,
              child: widget.child
            ),
        )
        )
    );
  }
}
class DropdownMenuRouteLayout extends SingleChildLayoutDelegate{
  DropdownMenuRouteLayout({
    @required this.buttonRect,
    this.width,
    this.menuDirection,
    this.menuOffset
  });
  final buttonRect;
  final width;
  final menuOffset;
  final menuDirection;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final double width = this.width;
    // final double maxHeight = 350;
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      minHeight: 0.0,
      // maxHeight: maxHeight
    );
  }
  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var left;
    
    switch(menuDirection){
      case MenuDirection.start:
        left = buttonRect.left;
        break;
      case MenuDirection.mid:
        left = (buttonRect.right + buttonRect.left)/2 - childSize.width/2;
        break;
      case MenuDirection.end:
        left = buttonRect.right - childSize.width;
        break;
    }

    double top = buttonRect.bottom + menuOffset;
    return Offset(left, top);

  }
  @override
  bool shouldRelayout(DropdownMenuRouteLayout oldDelegate) {
    return buttonRect != oldDelegate.buttonRect;
  }
}

enum MenuDirection{
  start,
  mid,
  end
}
