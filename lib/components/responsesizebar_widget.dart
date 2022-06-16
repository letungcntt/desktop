import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ResponseSidebarBox extends StatefulWidget {
  final Widget child;

  const ResponseSidebarBox({key, required this.child});
  @override
  State<ResponseSidebarBox> createState() => _ResponseSidebarBoxState();
}

class _ResponseSidebarBoxState extends State<ResponseSidebarBox> {
  final Map<String, ResponseSidebarController> _controllersMap = {};
  BoxConstraints? _boxConstraints;
  Function(ResponseSidebarController)? onCreateItem;
  
  double defaultConversationWidth = 500;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _ensureRenderBetweenItems(_boxConstraints, currentController: null);
    });
  }
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder:(context, constraints) {
        _ensureRenderBetweenItems(constraints, currentController: null);
        return widget.child;
      },
    );
  }
  ResponseSidebarController _createControllerForChild(ResponseSidebarItemInfo info) {
    ResponseSidebarController controller;
    if (_controllersMap.containsKey(info.itemKey)) {
      _controllersMap[info.itemKey]!.isAttached = true;
      // _controllersMap[info.itemKey]!.updateInfo(info);
      controller = _controllersMap[info.itemKey]!;
    } else {
      controller = ResponseSidebarController(info);
      controller.eventStream.stream.listen((ResponseSidebarController event) {
        _ensureRenderBetweenItems(_boxConstraints, currentController: event);
      });
      _controllersMap[info.itemKey] = controller;
    }

    _ensureRenderBetweenItems(_boxConstraints, currentController: controller, self: true);
    onCreateItem?.call(controller);
    return controller;
  }

  void _ensureRenderBetweenItems(BoxConstraints? constraints, {ResponseSidebarController? currentController, bool self = false}) {
    _boxConstraints = constraints;
    assert(_boxConstraints != null);

    List<ResponseSidebarController> controllers = _controllersMap.values.where((element) => element.isAttached).toList();

    if (currentController == null) {
      // print("Box update constraints");
      controllers.sort((a, b) {
        return - a.info.elevation + b.info.elevation;
      });

      var previousWidth = _boxConstraints!.maxWidth - defaultConversationWidth;
      for (var ctl in controllers) {
        ctl.updateConstraints(withBoxConstraints: ctl.info.constraints.copyWith(maxWidth: previousWidth));
        previousWidth = previousWidth - min(ctl.info.constraints.maxWidth, ctl.info.size);
      }
      return;
    }
    
    if (self) {
      double validMaxWidth = 0;
      for (var ctl in controllers) {
        if (ctl.info.elevation > currentController.info.elevation) {
          validMaxWidth = validMaxWidth + min(ctl.info.size, ctl.info.constraints.maxWidth);
        }
      }
      validMaxWidth = _boxConstraints!.maxWidth - defaultConversationWidth - validMaxWidth;
      currentController.updateConstraints(withBoxConstraints: currentController.info.constraints.copyWith(maxWidth: validMaxWidth));

      for (var ctl in controllers) {
        if (ctl != currentController) {
          BoxConstraints newConstraints = ctl.info.constraints.copyWith(maxWidth: _boxConstraints!.maxWidth - defaultConversationWidth - _currentSize(currentController));
          ctl.updateConstraints(withBoxConstraints: newConstraints);
        }
      }
      // print("Item update constraints when create");
    } else {
      // print("Item update constraints when resize ${currentController.info.direction}");
      for (var ctl in controllers) {
        if (ctl.info.elevation < currentController.info.elevation) {
          double validMaxWidth = _boxConstraints!.maxWidth - defaultConversationWidth - (currentController.isAttached ? _currentSize(currentController) : 0);
          ctl.updateConstraints(withBoxConstraints: ctl.info.constraints.copyWith(maxWidth: validMaxWidth));
        }
      }
    }
  }
  double _currentSize(ResponseSidebarController controller) {
    return max(min(controller.info.size, controller.info.constraints.maxWidth), controller.info.constraints.minWidth);
  }

  forceShowForElementWithKey(String itemKey) {
    ResponseSidebarController controller;
    if (_controllersMap.containsKey(itemKey)) {
      controller = _controllersMap[itemKey]!;
    } else {
      return;
    }

    double forceWidthToShow = 300 + controller.info.zeroSize;
    List<ResponseSidebarController> controllers = _controllersMap.values.where((element) => element.isAttached).toList();
    for (var ctl in controllers) {
      if (ctl.info.elevation > controller.info.elevation) {
        final sizeFit = _boxConstraints!.maxWidth - defaultConversationWidth;
        final sizeRemain = sizeFit - forceWidthToShow;
        if (sizeRemain <= ctl.info.constraints.minWidth) {
          ctl.callOnRemove();
        } else if (sizeRemain <= _currentSize(ctl)) {
          ctl.setSize(sizeRemain);
        }
      }
    }

    controller.setSize(forceWidthToShow);
    controller.saveSizeToLocal();
  }
  ResponseSidebarController? controllerForKey(String key) {
    if (!_controllersMap.containsKey(key)) return null;
    return _controllersMap[key]!;
  }
}

class ResponseSidebarItem extends StatefulWidget {
  final String separateSide;
  final BoxConstraints constraints;
  final Widget child;
  final int elevation;
  final String itemKey;
  final bool canZero;
  final double zeroSize;
  final double defaultWidth;
  final Function? callOnRemove;
  final bool deAttackable;

  const ResponseSidebarItem({required this.separateSide, 
                            required this.child, 
                            this.constraints = const BoxConstraints(), 
                            this.elevation = 0, 
                            required this.itemKey, 
                            this.canZero = true, 
                            this.defaultWidth = 400, 
                            this.callOnRemove, 
                            this.zeroSize = 0, 
                            this.deAttackable = true
                            });
  @override
  State<ResponseSidebarItem> createState() => _ResponseSidebarItemState();
}

class _ResponseSidebarItemState extends State<ResponseSidebarItem> {

  bool _onHoverSeparateSide = false;
  bool _onPanSeparateSide = false;
  late ResponseSidebarController _controller;
  @override
  void initState() {
    super.initState();
    final parent = context.findAncestorStateOfType<_ResponseSidebarBoxState>();
    assert(parent is _ResponseSidebarBoxState, "Cannot find any parent ResponseSidebarBox");

    ResponseSidebarItemInfo info = ResponseSidebarItemInfo(widget);
    _controller = parent!._createControllerForChild(info);
    _controller.loadSizeFromLocal();
  }

  @override
  void dispose() {
    if (widget.deAttackable) _controller.dispose();
    super.dispose();
  }

  // @override
  // void didUpdateWidget(covariant ResponseSidebarItem oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (widget.child != oldWidget.child) {
  //     print("update info");
  //     _controller.updateInfo(ResponseSidebarItemInfo(widget));
  //   }
  // }

  
  @override
  Widget build(BuildContext context) {
    
    return Stack(
      children: [
        StreamBuilder(
          stream: _controller.eventStream.stream,
          builder: (context, snapshot) {
            return Container(
              constraints: _controller.info.constraints,
              width: _controller.info.size,
              child: widget.child,
            );
          },
        ),
        _buildSeparatorWidget()
      ],
    );
  }

  Widget _buildSeparatorWidget() {
    return Positioned(
      top: 0,
      left: widget.separateSide == "left" ? 0 : null,
      right: widget.separateSide == "right" ? 0 : null,
      bottom: 0,
      child: GestureDetector(
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          onEnter: (_) => setState(() => _onHoverSeparateSide = true),
          onExit: (_) => setState(() => _onHoverSeparateSide = false),
          child: SizedBox(
            width: 4.5,
            height: double.infinity,
            child: Container(color: _onPanSeparateSide || _onHoverSeparateSide ? Colors.blue : Colors.transparent),
          ),
        ),
        onPanUpdate: (details) => _controller.resize(details.delta),
        onPanStart: (details) {
          setState(() {
            _onPanSeparateSide = true;
          });
          _controller.startResize();
        },
        onPanEnd: (details) {
          setState(() {
            _onPanSeparateSide = false;
          });
          _controller.endResize();
        },
        onDoubleTap: () => _controller.toggleZeroAndSize(),
      ),
    );
  }
}

class ResponseSidebarController {
  final eventStream = StreamController<ResponseSidebarController>.broadcast();
  
  final ResponSidebarModel _model;
  bool isAttached = true;
  ResponseSidebarItemInfo get info => _model.info;
  Function? func;

  ResponseSidebarController(ResponseSidebarItemInfo info) : _model = ResponSidebarModel(info);

  void resize(Offset details) {
    _model.resize(details);
    eventStream.add(this);
  }
  void setSize(double size) {
    _model.setSize(size);
    eventStream.add(this);
  }
  void tryShow() {
    _model.tryShow();
    eventStream.add(this);
  }

  void updateConstraints({BoxConstraints? withBoxConstraints}) {
    _model.updateConstraints(withBoxConstraints!);
    eventStream.add(this);
  }

  void dispose() {
    isAttached = false;
    eventStream.add(this);
  }
  
  void loadSizeFromLocal() {
    _model.loadSizeFromLocal();
    eventStream.add(this);
  }

  void saveSizeToLocal() {
    _model.saveSizeToLocal();
  }

  void toggleZeroAndSize() {
    _model.toggleZeroAndSize();
    eventStream.add(this);
  }
  
  startResize() {
    _model.startResize();
  }
  
  endResize() {
    _model.endResize();
  }
  
  void callOnRemove() {
    info.callOnRemove?.call();
  }
  
  void didActiveChild(bool active) {
    isAttached = active;
    eventStream.add(this);
  }
  
  void updateInfo(ResponseSidebarItemInfo info) {
    _model.updateInfo(info);
    eventStream.add(this);
  }
  void onCreate(Function func) {
    func.call();
  }
}

class ResponSidebarModel {
  ResponseSidebarItemInfo info;
  late BoxConstraints constraints;
  double _tempWidth = 0;
  

  ResponSidebarModel(this.info) {
    constraints = info.constraints;
    if (info.canZero) info.constraints = info.constraints.copyWith(minWidth: 0);
  }
  void resize(Offset details) {
    final size = _resizeImpl(details * info.direction.toDouble());
    final deltaWithoutZero = 50;

    _tempWidth = _tempWidth + details.dx * info.direction;
    if (_tempWidth >= constraints.minWidth - deltaWithoutZero && _tempWidth <= constraints.minWidth && info.canZero) {
      _resizeImpl(-details * info.direction.toDouble());
    }
    else if (_tempWidth <= constraints.minWidth - deltaWithoutZero && info.canZero) {
      _resizeImpl(Offset(-size + info.zeroSize, 0));
    } else {
      _resizeImpl(Offset(_tempWidth - size, 0));
    }
    
  }

  void startResize() {
    _tempWidth = max(min(info.constraints.maxWidth, info.size), info.constraints.minWidth);
  }
  
  void endResize() {
    saveSizeToLocal();
  }

  void updateConstraints(BoxConstraints constraints) {
    if (constraints.maxWidth < this.constraints.minWidth) {
      if (info.canZero) {
        info.constraints = info.constraints.copyWith(maxWidth: info.zeroSize, minWidth: info.zeroSize);
      }
      
      return;
    }
    if (constraints.maxWidth >= this.constraints.maxWidth) {
      info.constraints = info.constraints.copyWith(maxWidth: this.constraints.maxWidth);
      return;
    }
    info.constraints = constraints;
  }

  double _resizeImpl(Offset offset) {
    final size = info.size;
    info.size = size + offset.dx;
    return info.size;
  }

  void setSize(double size) {
    if (size <= constraints.minWidth) {}
    info.size = size;
  }
  
  void tryShow() {}

  void forceShow() {}

  void tempFunc() {}
  
  void updateInfo(ResponseSidebarItemInfo info) {
    this.info = info;
  }
  
  void loadSizeFromLocal() async {
    var box = Hive.box("windows");
    double size = box.get("RESWIDTH_${info.itemKey}") ?? info.size;
    setSize(size);
  }
  
  void saveSizeToLocal() async {
    var box = await Hive.openBox("windows");
     box.put("RESWIDTH_${info.itemKey}", _currentSize());
  }

  void toggleZeroAndSize() {
    if (info.size <= info.zeroSize || info.size <= info.constraints.minWidth) {
      setSize(max(_tempWidth, info.zeroSize));
    }
    else {
      _tempWidth = info.size;
      setSize(info.zeroSize);
    }
    saveSizeToLocal();
  }

  double _currentSize() {
    return max(min(info.size, info.constraints.maxWidth), info.constraints.minWidth);
  }

}

class ForceShowButtonForItemResponseSidebar extends StatefulWidget {
  final String itemKey;
  const ForceShowButtonForItemResponseSidebar({Key? key, required this.itemKey}) : super(key: key);

  @override
  State<ForceShowButtonForItemResponseSidebar> createState() => _ForceShowButtonForItemResponseSidebarState();
}

class _ForceShowButtonForItemResponseSidebarState extends State<ForceShowButtonForItemResponseSidebar> {
  _ResponseSidebarBoxState? responseSidebarBoxInstance;
  ResponseSidebarController? _controller;
  bool show = false;
  @override
  void initState() {
    super.initState();
    responseSidebarBoxInstance = context.findAncestorStateOfType<_ResponseSidebarBoxState>();
    assert(responseSidebarBoxInstance is _ResponseSidebarBoxState, "Cannot find any parent ResponseSidebarBox");
    responseSidebarBoxInstance!.onCreateItem = (controller) {
      if (controller.info.itemKey == widget.itemKey) {
        _controller = controller;
        _controller!.eventStream.stream.listen((_) {
          _handleEvent();
        });
        _handleEvent();
      }
    };

    _controller = responseSidebarBoxInstance!.controllerForKey(widget.itemKey);
    if (_controller != null) {
      _controller!.eventStream.stream.listen((_) {
        _handleEvent();
      });
      _handleEvent();
    }
  }
  @override
  Widget build(BuildContext context) {
    return show ?
      Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: InkWell(
          child: Icon(PhosphorIcons.list),
          onTap: () {
            responseSidebarBoxInstance!.forceShowForElementWithKey(widget.itemKey);
          },
        ),
      ) : Container();
  }
  _handleEvent() {
    if (_controller!.info.constraints.maxWidth <= _controller!.info.zeroSize || _controller!.info.size <= _controller!.info.zeroSize) {
      if (mounted) setState(() => show = true );
    }
    else {
      if (mounted) setState(() => show = false );
    }
  }
}

class ResponseSidebarItemInfo {
  Widget child;
  BoxConstraints constraints = const BoxConstraints();
  double size;
  int direction = -1;
  int elevation;
  bool canZero;
  double zeroSize;
  String itemKey;
  Function? callOnRemove;

  ResponseSidebarItemInfo(ResponseSidebarItem widget) 
    : child = widget.child,
      itemKey = widget.itemKey,
      canZero = widget.canZero,
      zeroSize = widget.zeroSize,
      callOnRemove = widget.callOnRemove,
      constraints = widget.constraints,
      size = widget.defaultWidth,
      direction = widget.separateSide == "right" ? 1 : -1,
      elevation = widget.elevation;
}
