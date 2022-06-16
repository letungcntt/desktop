import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class Windows extends ChangeNotifier{
  Size _deviceInfo = new Size(0, 0);
  double _channelWidth = 230.0;
  double _threadWidth= 300.0;
  bool _openSearchbar = false;
  bool _isOtherFocus = false ;
  bool _isBlockEscape = false;

  Size get deviceInfo => _deviceInfo;

  double get channelWidth => _channelWidth;
  double get threadWidth => _threadWidth;

  bool get openSearchbar => _openSearchbar;
  bool get isOtherFocus => _isOtherFocus;
  bool get isBlockEscape => _isBlockEscape;

  set isBlockEscape(bool value) {
    _isBlockEscape = value;
    notifyListeners();
  }

  set channelWidth(width) {
    _channelWidth = width;
    notifyListeners();
  }

  set threadWidth(width) {
    _threadWidth = width;
    notifyListeners();
  }

  set deviceInfo(Size size){
    _deviceInfo = size;
    notifyListeners();
  }

  set openSearchbar(bool value) {
    _openSearchbar = value;
    notifyListeners();
  }

  set isOtherFocus(bool value) {
    _isOtherFocus = value;
    notifyListeners();
  }



  saveResponsiveBarToHive(String key) async {
     var box = await Hive.openBox("windows");
     box.put("RESWIDTH_$key", key == "thread" ? _threadWidth : _channelWidth);
     notifyListeners();
  }
  loadResponsiveBarFromHive(){
    var box = Hive.box("windows");
    var _widthThread = box.get("RESWIDTH_thread");
    var _widthChannel = box.get("RESWIDTH_channel");
    _channelWidth = _widthChannel ?? _channelWidth;
    _threadWidth = _widthThread ?? _threadWidth;
  }
}