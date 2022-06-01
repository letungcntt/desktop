import 'dart:async';
import 'package:flutter/material.dart';

class StreamUploadStatus extends ValueNotifier<bool>{
  static final instance = StreamUploadStatus();
  static Map dataStatus = {};
  final _statusUploadController = StreamController<Map>.broadcast(sync: false);

  StreamUploadStatus(): super(false);
  Stream<Map> get status => _statusUploadController.stream;

  setUploadStatus(key, value){
    dataStatus[key] = value;
    _statusUploadController.add(dataStatus);
  }
}