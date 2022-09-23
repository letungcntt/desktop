import 'package:flutter/material.dart';
import '../components/call_center/p2p_manager.dart';

class P2PModel extends ChangeNotifier {

  late VoidCallback callback;

  void onMediaEvent(message) {
    p2pManager.handleMediaEvent(message);
  }
}
