import 'package:flutter/services.dart';

class WindowManager {
  WindowManager._() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }
  static final WindowManager instance = WindowManager._();
  final MethodChannel _channel = const MethodChannel('window_manager');

  Future<void> _methodCallHandler(MethodCall call) async {

  }

  Future<void> wakeUp() async {
    bool isMinimized = await this.isMinimized();
    if (isMinimized) {
      await this.restore();
    }
    await _channel.invokeMethod('wakeUp');
  }
  Future<bool> isMinimized() async {
    return await _channel.invokeMethod('isMinimized');
  }
  Future<bool> isMaximized() async {
    return await _channel.invokeMethod('isMaximized');
  }
  Future<void> restore() async {
    await _channel.invokeMethod('restore');
  }
}

final windowManager = WindowManager.instance;