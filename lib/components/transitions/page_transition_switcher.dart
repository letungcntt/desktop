import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
class _ChildEntry {
  _ChildEntry({
    required this.primaryController,
    required this.secondaryController,
    required this.transition,
    required this.widgetChild,
  });

  final AnimationController primaryController;

  final AnimationController secondaryController;

  Widget transition;

  Widget widgetChild;

  void dispose() {
    primaryController.dispose();
    secondaryController.dispose();
  }

  @override
  String toString() {
    return 'PageTransitionSwitcherEntry#${shortHash(this)}($widgetChild)';
  }
}

typedef PageTransitionSwitcherLayoutBuilder = Widget Function(
  List<Widget> entries,
);

typedef PageTransitionSwitcherTransitionBuilder = Widget Function(
  Widget child,
  Animation<double> primaryAnimation,
  Animation<double> secondaryAnimation,
);

class PageTransitionSwitcher extends StatefulWidget {
  const PageTransitionSwitcher({
    Key? key,
    this.duration = const Duration(milliseconds: 300),
    this.reverse = false,
    required this.transitionBuilder,
    this.layoutBuilder = defaultLayoutBuilder,
    this.child,
  }) : super(key: key);

  final Widget? child;
  final Duration duration;
  final bool reverse;
  final PageTransitionSwitcherTransitionBuilder transitionBuilder;
  final PageTransitionSwitcherLayoutBuilder layoutBuilder;

  static Widget defaultLayoutBuilder(List<Widget> entries) {
    return Stack(
      children: entries,
      alignment: Alignment.center,
    );
  }

  @override
  _PageTransitionSwitcherState createState() => _PageTransitionSwitcherState();
}

class _PageTransitionSwitcherState extends State<PageTransitionSwitcher>
    with TickerProviderStateMixin {
  final List<_ChildEntry> _activeEntries = <_ChildEntry>[];
  _ChildEntry? _currentEntry;
  int _childNumber = 0;

  @override
  void initState() {
    super.initState();
    _addEntryForNewChild(shouldAnimate: false);
  }

  @override
  void didUpdateWidget(PageTransitionSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.transitionBuilder != oldWidget.transitionBuilder) {
      _activeEntries.forEach(_updateTransitionForEntry);
    }

    final bool hasNewChild = widget.child != null;
    final bool hasOldChild = _currentEntry != null;
    if (hasNewChild != hasOldChild ||
        hasNewChild &&
            !Widget.canUpdate(widget.child!, _currentEntry!.widgetChild)) {
      _childNumber += 1;
      _addEntryForNewChild(shouldAnimate: true);
    } else if (_currentEntry != null) {
      assert(hasOldChild && hasNewChild);
      assert(Widget.canUpdate(widget.child!, _currentEntry!.widgetChild));
      _currentEntry!.widgetChild = widget.child!;
      _updateTransitionForEntry(_currentEntry!);
    }
  }

  void _addEntryForNewChild({required bool shouldAnimate}) {
    assert(shouldAnimate || _currentEntry == null);
    if (_currentEntry != null) {
      assert(shouldAnimate);
      if (widget.reverse) {
        _currentEntry!.primaryController.reverse();
      } else {
        _currentEntry!.secondaryController.forward();
      }
      _currentEntry = null;
    }
    if (widget.child == null) {
      return;
    }
    final AnimationController primaryController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    final AnimationController secondaryController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    if (shouldAnimate) {
      if (widget.reverse) {
        primaryController.value = 1.0;
        secondaryController.value = 1.0;
        secondaryController.reverse();
      } else {
        primaryController.forward();
      }
    } else {
      assert(_activeEntries.isEmpty);
      primaryController.value = 1.0;
    }
    _currentEntry = _newEntry(
      child: widget.child!,
      primaryController: primaryController,
      secondaryController: secondaryController,
      builder: widget.transitionBuilder,
    );
    if (widget.reverse && _activeEntries.isNotEmpty) {
      _activeEntries.insert(_activeEntries.length - 1, _currentEntry!);
    } else {
      _activeEntries.add(_currentEntry!);
    }
  }

  _ChildEntry _newEntry({
    required Widget child,
    required PageTransitionSwitcherTransitionBuilder builder,
    required AnimationController primaryController,
    required AnimationController secondaryController,
  }) {
    final Widget transition = builder(
      child,
      primaryController,
      secondaryController,
    );
    final _ChildEntry entry = _ChildEntry(
      widgetChild: child,
      transition: KeyedSubtree.wrap(
        transition,
        _childNumber,
      ),
      primaryController: primaryController,
      secondaryController: secondaryController,
    );
    secondaryController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        assert(mounted);
        assert(_activeEntries.contains(entry));
        setState(() {
          _activeEntries.remove(entry);
          entry.dispose();
        });
      }
    });
    primaryController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        assert(mounted);
        assert(_activeEntries.contains(entry));
        setState(() {
          _activeEntries.remove(entry);
          entry.dispose();
        });
      }
    });
    return entry;
  }

  void _updateTransitionForEntry(_ChildEntry entry) {
    final Widget transition = widget.transitionBuilder(
      entry.widgetChild,
      entry.primaryController,
      entry.secondaryController,
    );
    entry.transition = KeyedSubtree(
      key: entry.transition.key,
      child: transition,
    );
  }

  @override
  void dispose() {
    for (final _ChildEntry entry in _activeEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.layoutBuilder(_activeEntries
        .map<Widget>((_ChildEntry entry) => entry.transition)
        .toList());
  }
}
