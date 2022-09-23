import 'package:flutter/widgets.dart';
import 'package:workcake/data_channel_webrtc/device_socket.dart';

class DeviceProvider extends ChangeNotifier{
  List<Device> _devices = [];


  List<Device> get devices => _devices;


  setDevices(List<Device> data){
    _devices = data;
    notifyListeners();
  }

  
}