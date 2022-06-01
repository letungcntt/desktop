import 'dart:async';
import 'package:flutter/material.dart';

class StreamStatusConnection extends ValueNotifier<bool>{
  static final instance = StreamStatusConnection();
  final _statusConnectionController = StreamController<bool>.broadcast(sync: false);

  StreamStatusConnection(): super(false);
  Stream<bool> get status => _statusConnectionController.stream;

  setConnectionStatus(bool value) {
    _statusConnectionController.add(value);
  }
}

class StatusConnectionView extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder(
        initialData: true,
        stream: StreamStatusConnection.instance.status,
        builder: (context, snappshort){
          
          return Container(
            child: (snappshort.data as bool)? Container(): Container(
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.red[100]!.withOpacity(0.8),
              ),
              child: Center(child: Text("You don't connect to Internet", style: TextStyle(color: Colors.red[600]),)),
            ),
          );
        },
      ),
    );
  }
}