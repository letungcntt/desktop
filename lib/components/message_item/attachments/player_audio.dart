import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:workcake/common/palette.dart';

import '../../../providers/providers.dart';

class PlayerWidget extends StatefulWidget {
  final AudioPlayer player;
  final att;
  final bool isChannel;

  const PlayerWidget({
    Key? key,
    required this.player,
    this.isChannel = true,
    this.att
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PlayerWidgetState();
  }
}

class _PlayerWidgetState extends State<PlayerWidget> {
  Duration? _duration;
  Duration? _position;

  PlayerState _playerState = PlayerState.stopped;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  bool get _isPlaying => _playerState == PlayerState.playing;
  bool get _isPaused => _playerState == PlayerState.paused;

  AudioPlayer get player => widget.player;
  get att => widget.att;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }



  String _parseDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes);
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    String _durationText = _parseDuration(_duration ?? Duration());
    String _positionText = _parseDuration(_position ?? Duration());

    SliderThemeData themeSlider = SliderTheme.of(context).copyWith(
      thumbColor: Palette.dayBlue,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9),
    );

    return LayoutBuilder(
      builder: (context, cts) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight,
            borderRadius: BorderRadius.all(Radius.circular(4))
          ),
          margin: EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Container(
                    padding:EdgeInsets.only(left: 16),
                    child: Text(
                      _position != null
                          ? '$_positionText / $_durationText'
                          : _duration != null
                              ? _durationText
                              : '',
                      style: const TextStyle(fontSize: 14.0),
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: themeSlider,
                      child: Slider(
                        onChanged: (v) {
                          final duration = _duration;
                          if (duration == null) {
                            return;
                          }
                          final position = v * duration.inMilliseconds;
                          player.seek(Duration(milliseconds: position.round()));
                        },
                        value: (_position != null &&
                                _duration != null &&
                                _position!.inMilliseconds > 0 &&
                                _position!.inMilliseconds < _duration!.inMilliseconds)
                            ? _position!.inMilliseconds / _duration!.inMilliseconds
                            : 0.0,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 132,
                    child: Row(
                      children: [
                        IconButton(
                          key: const Key('play_button'),
                          onPressed: _isPlaying ? null : _play,
                          iconSize: 28.0,
                          padding: EdgeInsets.zero,
                          icon: const Icon(PhosphorIcons.playFill),
                          color: Palette.dayBlue,
                        ),
                        IconButton(
                          key: const Key('pause_button'),
                          onPressed: _isPlaying ? _pause : null,
                          iconSize: 28.0,
                          padding: EdgeInsets.zero,
                          icon: const Icon(PhosphorIcons.pauseFill),
                          color: Palette.dayBlue,
                        ),
                        IconButton(
                          key: const Key('stop_button'),
                          onPressed: _isPlaying || _isPaused ? _stop : null,
                          iconSize: 28.0,
                          padding: EdgeInsets.zero,
                          icon: const Icon(PhosphorIcons.stopFill),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                  if(widget.att != null) widget.isChannel ? Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            att['name'] ?? '',
                            style: const TextStyle(fontSize: 14.0),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(width: 4),
                        IconButton(
                          key: const Key('download_button'),
                          onPressed: () {
                            final url = att['content_url'];
                            Provider.of<Work>(context, listen: false).addTaskDownload({'content_url': url, 'name': att['name'],  "key_encrypt": att["key_encrypt"], "version": att["version"]});
                          },
                          iconSize: 24.0,
                          padding: EdgeInsets.zero,
                          icon: const Icon(PhosphorIcons.downloadSimple),
                          color: Palette.dayBlue,
                        ),
                        SizedBox(width: 16)
                      ],
                    )
                  ) : Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: 24),
                      child: Text(
                        att['name'] ?? '',
                        style: const TextStyle(fontSize: 14.0),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  void _initStreams() {
    _durationSubscription = player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = player.onPositionChanged.listen(
      (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {
      setState(() { });
    });
  }

  Future<void> _play() async {
    final position = _position;
    if (position != null && position.inMilliseconds > 0) {
      await player.seek(position);
    }
    await player.resume();
    setState(() => _playerState = PlayerState.playing);
  }

  Future<void> _pause() async {
    await player.pause();
    setState(() => _playerState = PlayerState.paused);
  }

  Future<void> _stop() async {
    await player.stop();
    setState(() {
      _playerState = PlayerState.stopped;
      _position = Duration.zero;
    });
  }
}
