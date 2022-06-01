import 'dart:async';

import 'package:flutter/material.dart';

class FocusInputBoxManager extends StatefulWidget {
  FocusInputBoxManager({required this.isThread, required this.focusNode, required this.child});
  final isThread;
  final focusNode;
  final child;
  @override
  State<StatefulWidget> createState() {
    return _FocusInputBoxManagerState();
  }
}
class _FocusInputBoxManagerState extends State<FocusInputBoxManager> {
  late FocusNode focusNode;
  late bool isThread;
  FocusTarget focusTarget = FocusTarget.NONE;
  @override
  void initState() {
    super.initState();
    focusNode = widget.focusNode ?? FocusNode();
    isThread = widget.isThread;
    if (isThread) focusTarget = FocusTarget.THREADBOX;
    else focusTarget = FocusTarget.MESSAGEBOX;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FocusTarget>(
      stream: FocusInputStream.instance.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != FocusTarget.NONE) {
          final focusTargetData = snapshot.data;
          bool canPop = Navigator.of(context).canPop();
          if(focusTargetData == focusTarget && !canPop) {
            focusNode.requestFocus();
          }
          FocusInputStream.instance.dropStream();
        }
        
        return widget.child;
      }
    );
  }
}

class FocusInputStream extends ValueNotifier<FocusTarget> {
  FocusInputStream() : super(FocusTarget.NONE);
  static final instance = FocusInputStream();

  final _streamController = StreamController<FocusTarget>.broadcast(sync: false);
  Stream<FocusTarget> get stream => _streamController.stream;
  FocusTarget focusTarget = FocusTarget.NONE;

  initObject() {
    _streamController.add(FocusTarget.NONE);
  }
  focusToThread() {
    _streamController.add(FocusTarget.THREADBOX);
    focusTarget = FocusTarget.THREADBOX;
  }
  focusToMessage() {
    _streamController.add(FocusTarget.MESSAGEBOX);
    focusTarget = FocusTarget.MESSAGEBOX;
  }

  dropStream () {
    _streamController.sink.add(FocusTarget.NONE);
  }
}

class StreamApp extends ValueNotifier<FocusTarget> {
  StreamApp() : super(FocusTarget.NONE);
  static final instance = StreamApp();
  bool isIssues = false;
  final _streamAppController = StreamController<bool>.broadcast(sync: false);

  initObject() {
    _streamAppController.add(false);
  }

  changeDataStream() {
    isIssues = !isIssues;
    _streamAppController.add(isIssues);
  }

  Stream<bool> get streamApp => _streamAppController.stream;
}

enum FocusTarget {
  NONE,
  THREADBOX,
  MESSAGEBOX
}