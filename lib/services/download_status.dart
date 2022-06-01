import 'dart:async';
import 'package:flutter/material.dart';

class StreamDownloadStatus extends ValueNotifier<bool>{
  static final instance = StreamDownloadStatus();
  static Map dataStatus = {};
  final _statusDownloadController = StreamController<Map>.broadcast(sync: false);

  StreamDownloadStatus(): super(false);
  Stream<Map> get status => _statusDownloadController.stream;

  setUploadStatus(key, value){
    dataStatus[key] = value;
    _statusDownloadController.add(dataStatus);
  }
}