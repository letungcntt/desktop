import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/providers/providers.dart';

class RecordAudio extends StatefulWidget {
  const RecordAudio({Key? key, required this.onExit, this.isDMs}) : super(key: key);

  final onExit;
  final bool? isDMs;

  @override
  State<RecordAudio> createState() => _RecordAudioState();
}

class _RecordAudioState extends State<RecordAudio> {
  int _recordDuration = 0;
  bool _isRecording = false;
  Timer? _timer;
  final _audioRecorder = Record();
  Path? path;
  bool _isPaused = false;

  @override
  void initState() {
    _start();
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start();

        bool isRecording = await _audioRecorder.isRecording();
        setState(() {
          _isRecording = isRecording;
          _recordDuration = 0;
        });

        _startTimer();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _pause() async {
    _timer?.cancel();
    await _audioRecorder.pause();

    setState(() {
      _isPaused = true;
      _isRecording = false;
    });
  }

  Future<void> _resume() async {
    _startTimer();
    await _audioRecorder.resume();

    setState(() {
      _isPaused = false;
      _isRecording = true;
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();

    setState(() {
      _isPaused = true;
      _isRecording = false;
      _recordDuration = 0;
    });
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }

  Widget _buildRecordPausePlayControl(isDark) {
    return ClipOval(
      child: Material(
        color: isDark ? Colors.white : Colors.black12,
        child: InkWell(
          child: SizedBox(width: 20, height: 20, child: _isPaused
            ? Icon(Icons.play_arrow, color: Colors.red, size: 15)
            : Icon(Icons.pause, color: Colors.red, size: 15)),
          onTap: () {
            _isRecording ? _pause() : _resume();
          },
        ),
      ),
    );
  }

  Widget _buildRecordStopControl(isDark) {
    return ClipOval(
      child: Material(
        color: isDark ? Colors.white : Colors.black12,
        child: InkWell(
          child: SizedBox(width: 20, height: 20, child: Icon(Icons.stop, color: Colors.red, size: 15)),
          onTap: () {
            _stop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          margin: EdgeInsets.only(right: 5),
          child: HoverItem(
            colorHover: isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
            child: TextButton(
              style: ButtonStyle(
                padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
              ),
              child: const Icon(Icons.close, color: Color(0xffFAAD14), size: 20),
              onPressed: () {
                widget.onExit(false);
              }
            ),
          )
        ),
        Expanded(
          child: Container(
            child: Stack(
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? Palette.backgroundTheardDark : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: isDark ? const Border() : Border.all(
                      color: const Color(0xffA6A6A6), width: 0.5
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.only(top: 3, bottom: 3, right: 5, left: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      border: Border(
                        top: BorderSide(width: 1.0, color: isDark ? Colors.transparent : Colors.black12),
                        left: BorderSide(width: 1.0, color: isDark ? Colors.transparent : Colors.black12),
                        right: BorderSide(width: 1.0, color: isDark ? Colors.transparent : Colors.black12),
                        bottom: BorderSide(width: 1.0, color: isDark ? Colors.transparent : Colors.black12),
                      ),
                    ),
                    child: _buildTimer(),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 10,
                  child: Row(
                    children: [
                      _buildRecordStopControl(isDark),
                      const SizedBox(width: 5),
                      _buildRecordPausePlayControl(isDark)
                    ],
                  )
                )
              ],
            ),
          ),
        ),
        Container(
          width: 30,
          height: 30,
          margin: EdgeInsets.only(left: 5),
          child: HoverItem(
            colorHover: isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
            child: TextButton(
              style: ButtonStyle(
                padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
              ),
              child: const Icon(Icons.send, color: Color(0xffFAAD14), size: 20),
              onPressed: Utils.checkedTypeEmpty(widget.isDMs)
                ? () => _sendRecordToDMs()
                : () => _sendRecordToChannel()
            ),
          )
        ),
      ],
    );
  }

  _sendRecordToChannel() async {
    final auth = Provider.of<Auth>(context, listen: false);
    final currentWorkspace = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentChannel = Provider.of<Channels>(context, listen: false).currentChannel;
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    final path = await _audioRecorder.stop();
    File file = File(path!);
    String fileName = file.path.split('/').last;
    final bytes = await File.fromUri(Uri.parse(file.path)).readAsBytes();

    final attachments = {
      "name": fileName,
      "file": bytes,
      "upload": {
        "filename": fileName,
        "file": bytes
      },
      "type": "record",
      "mime_type": fileName.split('.').last,
    };

    var dataMessage = {
      "channel_thread_id": null,
      "key": Utils.getRandomString(20),
      "count_child": 0,
      "message": "",
      "attachments": [],
      "workspace_id": currentWorkspace["id"],
      "channel_id":  currentChannel["id"],
      "user_id": auth.userId,
      "is_system_message": false,
      "full_name": currentUser["full_name"] ?? "",
      "avatar_url": currentUser["avatar_url"] ?? "",
      "inserted_at": DateTime.now().add(const Duration(hours: -7)).toIso8601String(),
      "isDesktop": true
    };

    Provider.of<Messages>(context, listen: false).sendMessageWithImage([attachments], dataMessage, auth.token);
    widget.onExit(false);
  }

  _sendRecordToDMs() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final directMessageSelected = Provider.of<DirectMessage>(context, listen: false).directMessageSelected;
    final userId = Provider.of<Auth>(context, listen: false).userId;
    final currentUser = Provider.of<User>(context, listen: false).currentUser;

    final fakeId = Utils.getRandomString(20);
    final idDirectmessage = directMessageSelected.id;
    final path = await _audioRecorder.stop();
    File file = File(path!);
    String fileName = file.path.split('/').last;
    final bytes = await File.fromUri(Uri.parse(file.path)).readAsBytes();
    final attachments = {
      "name": fileName,
      "file": bytes,
      "upload": {
        "filename": fileName,
        "file": bytes
      },
      "type": "record",
      "mime_type": fileName.split('.').last,
    };
    final dataMessage = {
      "message": "",
      "attachments": [],
      "title": "",
      "conversation_id": idDirectmessage,
      "show": true,
      "id": "",
      "user_id": userId,
      "time_create": DateTime.now().add(const Duration(hours: -7)).toIso8601String(),
      "count": 0,
      "isSend": true,
      "sending": true,
      "success": true,
      "fake_id": fakeId,
      "current_time": DateTime.now().millisecondsSinceEpoch * 1000,
      "isDesktop": true,
      "avatar_url": currentUser["avatar_url"],
      "full_name": currentUser["full_name"],
    };

    Provider.of<DirectMessage>(context, listen: false).sendMessageWithImage([attachments], dataMessage, token);
    widget.onExit(false);
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDuration ~/ 60);
    final String seconds = _formatNumber(_recordDuration % 60);

    return Text(
      '$minutes : $seconds',
      style: const TextStyle(color: Colors.red),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0' + numberStr;
    }

    return numberStr;
  }
}