import 'dart:async';
import 'dart:collection';

class Scheduler {
  bool _scheduled = false;

  Queue<Future Function()> _queue = Queue<Future Function()>();


  void schedule(Future Function() task) {
    _queue.add(task);
    if (!_scheduled) {
      _scheduled = true;
      Timer(Duration(seconds: 0), _execute);
    }
  }

  int getLength(){
    return _queue.length;
  }

  Future _execute() async {
    while (true) {
      if (_queue.isEmpty) {
        _scheduled = false;
        return;
      }

      var first = _queue.removeFirst();
      _queue.addFirst((){ throw {}; });
      await first();
      _queue.removeFirst();
    }
  }


  void scheduleOne(Future Function() task) {
    _queue.add(task);
    if (!_scheduled) {
      _scheduled = true;
      Timer(Duration(seconds: 10), _executeOne);
    }
  }

  Future _executeOne() async {
    _scheduled = false;
    var first = _queue.removeFirst();
    _queue = Queue<Future Function()>();
    await first();
  }
}