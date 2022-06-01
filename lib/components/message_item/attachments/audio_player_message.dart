import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerMessage extends StatefulWidget {
  const AudioPlayerMessage({
    Key? key,
    required this.source,
  }) : super(key: key);

  final AudioSource source;

  @override
  State<AudioPlayerMessage> createState() => _AudioPlayerMessageState();
}

class _AudioPlayerMessageState extends State<AudioPlayerMessage> {
  final _audioPlayer = AudioPlayer();
  late StreamSubscription<PlayerState> _playerStateChangedSubscription;

  Duration? duration;
  late Future<Duration?> futureDuration;

  @override
  void initState() {
    super.initState();

    _playerStateChangedSubscription =
        _audioPlayer.playerStateStream.listen(playerStateListener);

    futureDuration = _audioPlayer.setAudioSource(widget.source).then((value) {
      setState(() => duration = value);
      return;
    });
  }

  void playerStateListener(PlayerState state) async {
    if (state.processingState == ProcessingState.completed) {
      await reset();
    }
  }

  @override
  void dispose() {
    _playerStateChangedSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Duration?>(
      future: futureDuration,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.all(Radius.circular(4))
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _controlButtons(),
                _slider(snapshot.data),
              ],
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.all(Radius.circular(4))
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _controlButtons(),
              _slider(duration),
            ],
          ),
        );
      }
    );
  }

  Widget _controlButtons() {
    return StreamBuilder<bool>(
      stream: _audioPlayer.playingStream,
      builder: (context, _) {
        final color =
            _audioPlayer.playerState.playing ? Colors.red : Colors.blue;
        final icon =
            _audioPlayer.playerState.playing ? Icons.pause : Icons.play_arrow;
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: GestureDetector(
            onTap: () {
              if (_audioPlayer.playerState.playing) {
                pause();
              } else {
                play();
              }
            },
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, color: color, size: 30),
            ),
          ),
        );
      },
    );
  }

  Widget _slider(Duration? duration) {
    return StreamBuilder<Duration>(
      stream: _audioPlayer.positionStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && duration != null) {
          return CupertinoSlider(
            value: snapshot.data!.inMicroseconds / duration.inMicroseconds,
            onChanged: (val) {
              _audioPlayer.seek(duration * val);
            },
          );
        } else {
          return CupertinoSlider(
            value: 0,
            onChanged: (val) {},
          );
        }
      },
    );
  }

  Future<void> play() {
    return _audioPlayer.play();
  }

  Future<void> pause() {
    return _audioPlayer.pause();
  }

  Future<void> reset() async {
    await _audioPlayer.stop();
    return _audioPlayer.seek(const Duration(milliseconds: 0));
  }
}

class AudioPlayerMessageDirect extends StatefulWidget {
  const AudioPlayerMessageDirect({
    Key? key,
    this.path,
  }) : super(key: key);

  final String? path;

  @override
  State<AudioPlayerMessageDirect> createState() => _AudioPlayerMessageDirectState();
}

class _AudioPlayerMessageDirectState extends State<AudioPlayerMessageDirect> {
  final _audioPlayer = AudioPlayer();
  late StreamSubscription<PlayerState> _playerStateChangedSubscription;

  late Future<Duration?> futureDuration;
  Duration? duration;

  @override
  void initState() {
    super.initState();

    _playerStateChangedSubscription =
        _audioPlayer.playerStateStream.listen(playerStateListener);

    futureDuration = _audioPlayer.setFilePath(widget.path!).then((value) {
      setState(() => duration = value);
      return;
    });
  }

  void playerStateListener(PlayerState state) async {
    if (state.processingState == ProcessingState.completed) {
      await reset();
    }
  }

  @override
  void dispose() {
    _playerStateChangedSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Duration?>(
      future: futureDuration,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.all(Radius.circular(4))
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _controlButtons(),
                _slider(snapshot.data),
              ],
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.all(Radius.circular(4))
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _controlButtons(),
              _slider(duration),
            ],
          ),
        );
      },
    );
  }

  Widget _controlButtons() {
    return StreamBuilder<bool>(
      stream: _audioPlayer.playingStream,
      builder: (context, _) {
        final color =
            _audioPlayer.playerState.playing ? Colors.red : Colors.blue;
        final icon =
            _audioPlayer.playerState.playing ? Icons.pause : Icons.play_arrow;
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: GestureDetector(
            onTap: () {
              if (_audioPlayer.playerState.playing) {
                pause();
              } else {
                play();
              }
            },
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, color: color, size: 30),
            ),
          ),
        );
      },
    );
  }

  Widget _slider(Duration? duration) {
    return StreamBuilder<Duration>(
      stream: _audioPlayer.positionStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && duration != null) {
          return CupertinoSlider(
            value: snapshot.data!.inMicroseconds / duration.inMicroseconds,
            onChanged: (val) {
              _audioPlayer.seek(duration * val);
            },
          );
        } else {
          return CupertinoSlider(
            value: 0,
            onChanged: (val) {},
          );
        }
      },
    );
  }

  Future<void> play() {
    return _audioPlayer.play();
  }

  Future<void> pause() {
    return _audioPlayer.pause();
  }

  Future<void> reset() async {
    await _audioPlayer.stop();
    return _audioPlayer.seek(const Duration(milliseconds: 0));
  }
}