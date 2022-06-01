import 'package:flutter/cupertino.dart';

class Friend with ChangeNotifier{
  var _tab = "Addfriend";
  String get tab => _tab; 
  // ignore: unnecessary_getters_setters
  void setTab(String tab){
    _tab = tab; 
    notifyListeners(); 
  }
}