import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:workcake/components/message_item/attachments/player_audio.dart';

class AudioPlayerMessage extends StatefulWidget {
  const AudioPlayerMessage({
    Key? key,
    required this.source,
    required this.att
  }) : super(key: key);

  final UrlSource source;
  final att;

  @override
  State<AudioPlayerMessage> createState() => _AudioPlayerMessageState();
}

class _AudioPlayerMessageState extends State<AudioPlayerMessage> {
  AudioPlayer player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  @override
  void initState() {
    super.initState();
    player.setSource(widget.source).then(
      (value) => player.pause()
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return PlayerWidget(
      player: player,
      att: widget.att
    );
  }
}

class AudioPlayerMessageDirect extends StatefulWidget {
  const AudioPlayerMessageDirect({
    Key? key,
    this.path,
    this.att
  }) : super(key: key);

  final String? path;
  final Map? att;

  @override
  State<AudioPlayerMessageDirect> createState() => _AudioPlayerMessageDirectState();
}

class _AudioPlayerMessageDirectState extends State<AudioPlayerMessageDirect> {
  final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  @override
  void initState() {
    super.initState();
    player.setSourceDeviceFile(widget.path ?? '').then(
      (value) => player.pause()
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return PlayerWidget(
      player: player,
      att: widget.att,
      isChannel: false
    );
  }
}