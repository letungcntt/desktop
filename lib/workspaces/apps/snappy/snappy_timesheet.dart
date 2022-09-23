import 'dart:convert';
import 'dart:ui';
import 'dart:math';

import 'package:calendar_view/calendar_view.dart' hide FilledCell;
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Border, Row, Stack;
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/themes.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/dropdown_overlay.dart';
import 'package:workcake/components/transitions/modal.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/workspaces/apps/snappy/service.dart';
import 'package:workcake/workspaces/apps/snappy/wifi_scanner.dart';

import 'file_save_helper.dart';

extension TimeOfDayConverter on TimeOfDay {
  String to24hours() {
    final hour = this.hour.toString().padLeft(2, "0");
    final min = this.minute.toString().padLeft(2, "0");
    return "$hour:$min";
  }
}

class SnappyTimeSheet extends StatefulWidget {
  final changeView;
  final workspaceId;
  const SnappyTimeSheet({Key? key, this.changeView, this.workspaceId}) : super(key: key);

  @override
  State<SnappyTimeSheet> createState() => _SnappyTimeSheetState();
}

class _SnappyTimeSheetState extends State<SnappyTimeSheet> {
  final _controller = EventController<Event>();

  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId) {
      final currentWs = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
      final auth = Provider.of<Auth>(context, listen: false);
      Provider.of<User>(context, listen: false).selectTab("app");
      auth.channel.push(
        event: "join_channel",
        payload: {"channel_id": 0, "workspace_id": currentWs["id"]}
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<Auth>();
    final currentWs = context.read<Workspaces>().currentWorkspace;

    return CalendarControllerProvider<Event>(
      controller: _controller,
      child: MaterialApp(

        debugShowCheckedModeBanner: false,
        scrollBehavior: ScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.trackpad,
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
          },
        ),
        theme: (auth.theme == ThemeType.DARK
          ? Themes.darkTheme
          : Themes.lightTheme).copyWith(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
              },
            )),
        home: Scaffold(
          body: currentWs["timesheets_config"] != null
            ? CalendarViews(changeView: widget.changeView,)
            : TimeSheetsConfig(changeView: widget.changeView),
        ),
      ),
    );
  }
}

class CalendarViews extends StatefulWidget {
  final Function(DateTime)? onSelectMonth;
  final Function? changeView;

  const CalendarViews({Key? key, this.onSelectMonth, this.changeView}) : super(key: key);
  @override
  State<CalendarViews> createState() => _CalendarViewsState();
}

class _CalendarViewsState extends State<CalendarViews> {
  List<DateTime> date = [DateTime.now(), DateTime.now().subtract(Duration(days: 1))];
  DateTime? _selectedDate;
  Map? selectedUser;
  int successDay = 0;
  int overTime = 0;
  int failureDay = 0;
  int outTime = 0;


  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getEventsForMonth(DateTime.now());
    });
    super.initState();
  }

  _getEventsForMonth(DateTime month) async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];

    final url = Utils.apiUrl + 'workspaces/$workspaceId/index_timesheets?token=$token';
    final body = {
      'user_id': selectedUser?["id"],
      'start_date': DateFormat('yyyy-MM-dd').format(DateTime(month.year, month.month, 1)),
      'end_date': DateFormat('yyyy-MM-dd').format(DateTime(month.year, month.month + 1, 0)),
    };
    try {
      final response = await Dio().post(url, data: json.encode(body));
      var dataRes = response.data;
      if (dataRes["success"]) {
        List _responseData = dataRes['data'].map((data) {
          return {
            'user_id': data['user_id'],
            'check_in': data["start_time"],
            'check_out': data["end_time"],
            'date': data["date"],
            'reason': data["reason"],
            'success': data["success"],
            'form': data['form']
          };
        }).toList();

        print(_responseData);

        _parseEventData(_responseData);
        _calculateStatsMonth(month);
        // setState(() => isLoading = false);
      }
    } catch (e, trace) {
      print("$e: $trace");
      // setState(() => isLoading = false);
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  _parseEventData(listData) {
    for (var data in listData) {
      final event = _defaultEvent(Event(
        userId: data['user_id'],
        date: DateTime.parse(data["date"]),
        checkIn: DateTime.tryParse(data["check_in"] ?? ""),
        checkOut: DateTime.tryParse(data["check_out"] ?? ""),
        reason: data["reason"],
        success: data["success"],
        form: data['form'] != null ? Form.fromData(data['form']) : null
      ));
      if (!CalendarControllerProvider.of<Event>(context).controller.events.contains(event)) {
        CalendarControllerProvider.of<Event>(context).controller.add(event);
      }
    }
  }

  _clearEventOnMonth(DateTime month) {
    final controller = CalendarControllerProvider.of<Event>(context).controller;
    month.datesOfMonths().forEach((day) {
      final events = controller.getEventsOnDay(day);
      for (var event in events) {
        controller.remove(event);
      }
    });
  }

  _clearEventOnDay(DateTime day) {
    final controller = CalendarControllerProvider.of<Event>(context).controller;
    final events = controller.getEventsOnDay(day);
    for (var event in events) {
      controller.remove(event);
    }
  }

  _clearFormOnDay(DateTime day) {
    final controller = CalendarControllerProvider.of<Event>(context).controller;
    final events = controller.getEventsOnDay(day);
    for (var event in events) {
      event.event!.form = null;
      if (day.compareTo(DateTime.now()) > 0) {
        controller.remove(event);
      }
    }
  }

  _calculateStatsMonth(month) {
    successDay = 0; overTime = 0; failureDay = 0; outTime = 0;
    final calendarEventController = CalendarControllerProvider.of<Event>(context).controller;
    for (var i = DateTime(month.year, month.month, 1); i.month == month.month; i = i.add(Duration(days: 1))) {
      final eventOnDay = calendarEventController.getEventsOnDay(i);
      if (eventOnDay.isNotEmpty) {
        final event = eventOnDay[0].event;
        if (event!.success) successDay++;
        else failureDay++;
        if (event.checkIn == null && event.checkOut == null) outTime ++;
      } else outTime ++;
    }
    setState(() {});
  }

  CalendarEventData<Event> _defaultEvent(Event event) {
    final _current = event.date;
    final _startTime = DateTime(_current.year, _current.month, _current.day);
    final _endTime = _startTime.add(Duration(days: 0, hours: 23, minutes: 59));
    return CalendarEventData(
      title: "",
      date: _startTime,
      startTime: _startTime,
      endTime: _endTime,
      event: event
    );
  }

  _onSelectMonth(DateTime month) {
    _getEventsForMonth(month);
  }

  _generateExcel(DateTime month) async {
    final Workbook workbook = Workbook(0);
    final Worksheet sheets = workbook.worksheets.addWithName('timesheets${DateFormat('M-y').format(month)}');
    final lastRow = CalendarControllerProvider.of<Event>(context).controller.events.length + 2;

    sheets.getRangeByName('A1:I$lastRow').cellStyle.fontSize = 14;
    sheets.getRangeByName('A1:I1').cellStyle.bold = true;

    sheets.getRangeByName('A1').setText('Họ tên');
    sheets.getRangeByName('B1').setText('Ngày tháng');
    sheets.getRangeByName('C1').setText('Giờ check in');
    sheets.getRangeByName('D1').setText('Giờ check out');
    sheets.getRangeByName('E1').setText('Thời gian làm việc');
    sheets.getRangeByName('F1').setText('Thời gian tăng ca');
    sheets.getRangeByName('G1').setText('Người duyệt tăng ca');
    sheets.getRangeByName('H1').setText('Lý do');
    sheets.getRangeByName('I1').setText('Người phê duyệt');



    for (var i = 0; i < CalendarControllerProvider.of<Event>(context).controller.events.length; i++) {
      final event = CalendarControllerProvider.of<Event>(context).controller.events[i].event!;
      if (event.userId != null) {
        final rowIndex = i + 2;

        final userId = event.userId;
        final timeRange = event.checkOut != null && event.checkIn != null ?  event.checkOut!.difference(event.checkIn!) : "";
        final overtimeRange = event.form != null && event.form!.overtime != null ? DateTime.parse(event.form!.overtime!['start_time']).difference(DateTime.parse(event.form!.overtime!['end_time'])).toString() : "";
        final overtimeApprover = event.form != null && event.form!.overtime != null ? event.form!.approver : "";
        final formApprover = event.form != null && event.form!.overtime == null ? event.form!.approver : "";
        sheets.getRangeByName('A$rowIndex').setText(_getUserById(userId)['full_name']);
        sheets.getRangeByName('B$rowIndex').setText(event.date.toString());
        sheets.getRangeByName('C$rowIndex').setText(event.checkIn.toString());
        sheets.getRangeByName('D$rowIndex').setText(event.checkOut.toString());
        sheets.getRangeByName('E$rowIndex').setText(timeRange.toString());
        sheets.getRangeByName('F$rowIndex').setText(overtimeRange);
        sheets.getRangeByName('G$rowIndex').setText(_getUserById(overtimeApprover)['full_name']);
        sheets.getRangeByName('H$rowIndex').setText(event.reason);
        sheets.getRangeByName('I$rowIndex').setText(_getUserById(formApprover)['full_name']);
      }
    }

    final List<int> bytes = workbook.saveAsStream();
    await FileSaveHelper.saveAndLaunchFile(bytes, 'timesheets${DateFormat('M-y').format(month)}.xlsx');
  }

  _removeForm(date) async {
    final getFormData = () {
      final event = CalendarControllerProvider.of<Event>(context).controller.getEventsOnDay(date);
      return event[0].event!.form!;
    }.call();
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWs = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final workspaceId = currentWs["id"];
    final url = Utils.apiUrl + 'workspaces/$workspaceId/delete_form_timesheets?token=$token';
    try {
      await Dio().post(url, data: json.encode({
        "id": getFormData.id,
        "user_id": getFormData.userId,
        "workspace_id": getFormData.workspaceId,
      }));
      setState(() {
        _clearFormOnDay(date);
      });
    } catch (e, trace) {
      print("$e\n$trace");
    }
  }

  _showModalCheckIn(context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final currentWs = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final startTime = currentWs["timesheets_config"]["start_time"];
    String _st = startTime;
    if (_st.contains("AM") || _st.contains("PM")) _st = DateFormat("HH:mm").format(DateFormat.jm().parse(startTime));
    bool isLate = false;
    TimeOfDay _startTime = TimeOfDay(hour:int.parse(_st.split(":")[0]), minute: int.parse(_st.split(":")[1]));

    isLate = Utils.compareTime(_startTime);

    showModal(
      context: context,
      builder: (_) => SimpleDialog(
      children: <Widget>[
        Center(
          child: Container(
            child: Column(
              children: [
                Icon(CupertinoIcons.exclamationmark_shield_fill, color: Colors.red),
                SizedBox(height: 10),
                Text(
                  isLate
                    ? "Bạn đang checkin sau giờ quy định. Vẫn muốn checkin?"
                    : "Xác nhận checkin?"
                ),
                SizedBox(height: 10),
                Container(
                  margin: EdgeInsets.only(right: 12),
                  child: OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                    ),
                    onPressed: () => _onHandleCheckIn(),
                    child: Text(
                      isLate
                        ? 'Vẫn checkin'
                        : 'Checkin',
                      style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                  ),
                ),
              ],
            )
          )
        )
      ])
    );
  }


  _onHandleCheckIn() async {
    final hasForm = () {
      final event = CalendarControllerProvider.of<Event>(context).controller.getEventsOnDay(DateTime.now());
      if (event.isNotEmpty && event[0].event != null && event[0].event!.form != null && (event[0].event!.form!.overtime == null)) return true;
      return false;
    }.call();

    _showRemoveFormQuestion() async {
      final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
      bool? accept;
      accept = await showModal<bool>(
        context: context,
        builder: (context) => SimpleDialog(
        children: <Widget>[
          Center(
            child: Container(
              child: Column(
                children: [
                  Icon(CupertinoIcons.exclamationmark_shield_fill, color: Colors.red),
                  SizedBox(height: 10),
                  Text(
                    'Đang có form xin nghỉ, bạn có muốn huỷ form'
                  ),
                  SizedBox(height: 10),
                  Container(
                    margin: EdgeInsets.only(right: 12),
                    child: OutlinedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                      ),
                      onPressed: () async {
                        await _removeForm(DateTime.now());
                        Navigator.pop(context, true);
                      },
                      child: Text(
                        'Huỷ form',
                        style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                    ),
                  ),
                ],
              )
            )
          )
        ])
      );
      return accept != null && accept ? true : false;
    }

    Navigator.of(context, rootNavigator: true).pop("Discard");
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWs = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final workspaceId = currentWs["id"];

    if (hasForm){
      bool accept = await _showRemoveFormQuestion();
      if (!accept) {
        // Navigator.pop(context);
        return;
      }
    }

    final url = Utils.apiUrl + 'workspaces/$workspaceId/checkin?token=$token';
    try {
      final response = await Dio().post(url,
        data: {
          "bssid": await ServiceSnappy.getCurrentBSSIDFromProcess()
        }
      );
      var dataRes = response.data;
      if (dataRes["success"]) {
        _getEventsForMonth(DateTime.now());
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
            Center(
              child: Container(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.green),
                    SizedBox(height: 10),
                    Text("Checkin thành công"),
                  ],
                )
              )
            )
          ])
        );
      } else {
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
            Center(
              child: Container(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.xmark_circle_fill, color: Colors.red),
                    SizedBox(height: 10),
                    Text(dataRes["message"]),
                  ],
                )
              )
            )
          ])
        );
      }
    } catch (e, trace) {
      print("Error Channel: $trace");
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  _showModalCheckOut(context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final currentWs = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final endTime = currentWs["timesheets_config"]["end_time"];
    String _et = endTime;
    if (_et.contains("AM") || _et.contains("PM")) _et = DateFormat("HH:mm").format(DateFormat.jm().parse(endTime));
    bool isLate = false;
    TimeOfDay _endTime = TimeOfDay(hour:int.parse(_et.split(":")[0]),minute: int.parse(_et.split(":")[1]));

    isLate = Utils.compareTime(_endTime);

    showModal(
      context: context,
      builder: (_) => SimpleDialog(
      children: <Widget>[
        Center(
          child: Container(
            child: Column(
              children: [
                Icon(CupertinoIcons.exclamationmark_shield_fill, color: Colors.red),
                SizedBox(height: 10),
                Text(
                  !isLate
                    ? "Bạn đang checkout trước giờ quy định. Vẫn muốn checkout?"
                    : "Xác nhận checkout?"
                ),
                SizedBox(height: 10),
                Container(
                  margin: EdgeInsets.only(right: 12),
                  child: OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                    ),
                    onPressed: () => _onHandleCheckOut(),
                    child: Text(
                      !isLate
                        ? 'Vẫn checkout'
                        : 'Checkout',
                      style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                  ),
                ),
              ],
            )
          )
        )
      ])
    );
  }

  _showModalCheckinOffset(context) async {
    await showModal(
      context: context,
      builder: (BuildContext context) {
        return FormBreakWorkDay();
      }
    );
    _getEventsForMonth(DateTime.now());
  }

  _onHandleCheckOut() async {
    Navigator.of(context, rootNavigator: true).pop("Discard");
    final token = Provider.of<Auth>(context, listen: false).token;
    final currentWs = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final workspaceId = currentWs["id"];

    final url = Utils.apiUrl + 'workspaces/$workspaceId/checkout?token=$token';
    try {
      final response = await Dio().post(url,
        data: {
          "bssid": await ServiceSnappy.getCurrentBSSIDFromProcess()
        }
      );
      var dataRes = response.data;
      if (dataRes["success"]) {
        _clearEventOnDay(DateTime.parse(dataRes["data"]["date"]));
        _getEventsForMonth(DateTime.now());
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
            Center(
              child: Container(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.green),
                    SizedBox(height: 10),
                    Text("Checkout thành công"),
                  ],
                )
              )
            )
          ])
        );
      } else {
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
            Center(
              child: Container(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.xmark_circle_fill, color: Colors.red),
                    SizedBox(height: 10),
                    Text(dataRes["message"]),
                  ],
                )
              )
            )
          ])
        );
      }
    } catch (e, trace) {
      print("Error Channel: $trace");
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  reviewCheckinOffset() {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;

    showModal(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0)),
          title: Container(
            decoration: BoxDecoration(
              color: isDark ? Color(0xff5E5E5E).withOpacity(0.5) : Color(0xffF3F3F3),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(4.0),
                topLeft: Radius.circular(4.0)
              )
            ),
            child: Container(
              padding: const EdgeInsets.only(top: 9, bottom: 9, left: 16),
              child: Text("Review", style: TextStyle(fontSize: 16))
            ),
          ),
          titlePadding: const EdgeInsets.all(0),
          backgroundColor: isDark ? Palette.backgroundTheardDark : Colors.white,
          contentPadding: EdgeInsets.zero,
          content: ReviewFormTimesheets(),
        );
      }
    );
  }

  Widget logCheckInOut() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showModalCheckIn(context),
          child: Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xff5E5E5E), width: 0.5)
              )
            ),
            child: Text("Checkin"),
          ),
        ),
        InkWell(
          onTap:() => _showModalCheckOut(context),
          child: Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xff5E5E5E), width: 0.5)
              )
            ),
            child: Text("Checkout"),
          ),
        ),
        InkWell(
          onTap:() => _showModalCheckinOffset(context),
          child: Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xff5E5E5E), width: 0.5)
              )
            ),
            child: Text("Xin nghỉ/Tăng ca"),
          ),
        )
      ],
    );
  }

  Widget _statsWidget(DateTime date) {
    final eventDate = CalendarControllerProvider.of<Event>(context).controller.getEventsOnDay(date);
    var checkIn;
    var checkOut;
    var reason;
    var success;
    if (eventDate.isNotEmpty) {
      checkIn = eventDate[0].event!.checkIn;
      checkOut = eventDate[0].event!.checkOut;
      reason = eventDate[0].event!.reason;
      success = eventDate[0].event!.success;
    }

    if (eventDate.isNotEmpty && (checkIn != null || checkOut != null)) return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(checkIn != null) Text("Đã checkin lúc ${DateFormatter().renderTime(checkIn)}")
        else Text("Chưa checkin"),
        SizedBox(height: 8),
        if (checkOut != null) Text("Đã checkout lúc ${DateFormatter().renderTime(checkOut)}")
        else Text("Chưa checkout"),
        SizedBox(height: 8),
        if (Utils.checkedTypeEmpty(reason)) Text("Lý do: $reason")
        else Text("Không có log reason"),
        SizedBox(height: 8),
        if (success) Text("Trạng thái thành công", style: TextStyle(color: Colors.green))
        else Text("Trạng thái không thành công", style: TextStyle(color: Colors.red))
      ],
    );
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final currentWs = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final currentMember = Provider.of<Workspaces>(context, listen: false).currentMember;
    final wsMembers = Provider.of<Workspaces>(context, listen: true).members;
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    final members = wsMembers.where((ele) => ele["account_type"] == 'user' && ele["id"] != currentUser['id']).toList();

    return Container(
      padding: EdgeInsets.all(24),
      color: auth.theme == ThemeType.DARK ? Palette.backgroundRightSiderDark : Palette.backgroundRightSiderLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () => widget.changeView!(1),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          child: Icon(PhosphorIcons.arrowLeft, size: 20,),
                        ),
                      ),
                    ),
                    Text("Chấm công", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                height: 32,
                margin: EdgeInsets.only(right: 12),
                child: OutlinedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                  ),
                  onPressed: () => _generateExcel(DateTime.now()),
                  child: Text(
                    'Export To Excel',
                    style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                )
              ),
              if (currentMember['role_id'] <= 2) Container(
                width: 30,
                height: 30,
                margin: EdgeInsets.only(right: 12),
                child: TextButton(
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                    overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : const Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0))),
                  ),
                  child: Icon(CupertinoIcons.settings, size: 18, color: Palette.calendulaGold),
                  onPressed: () => onConfigTimesheets(context, currentWs["timesheets_config"]),
                )
              ),
            ],
          ),
          SizedBox(height: 10),
          if (currentMember['role_id'] == 1) Container(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Text("Xem lịch công của nhân viên", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                SizedBox(width: 8),
                Container(
                  margin: EdgeInsets.only(left: 10),
                  child: DropdownOverlay(
                    width: 200,
                    isAnimated: true,
                    menuDirection: MenuDirection.start,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: HoverItem(
                        colorHover: Palette.hoverColorDefault,
                        child: Container(
                          height: 36,
                          constraints: new BoxConstraints(
                            minWidth: 200,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              width: 1,
                              color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment:  MainAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                child: selectedUser != null
                                  ? Row(
                                    children: [
                                      CachedAvatar(
                                        selectedUser!["avatar_url"] ?? "",
                                        name: selectedUser!["full_name"],
                                        width: 28,
                                        height: 28
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        selectedUser!["full_name"],
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  )
                                : Text(
                                    "Chọn nhân viên",
                                    style: TextStyle(
                                      color: isDark ? Color(0xffF0F4F8) : Colors.black45,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ),
                              SizedBox(width: 8),
                              Icon(CupertinoIcons.arrowtriangle_down_fill, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65), size: 12),
                            ]
                          ),
                        ),
                      ),
                    ),
                    dropdownWindow: StatefulBuilder(
                      builder: ((context, setState) {
                        return Container(
                          constraints: new BoxConstraints(
                            maxHeight: 300.0,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Palette.backgroundTheardDark : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: members.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final item = members[index];

                                    return TextButton(
                                      style: ButtonStyle(
                                        overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                                        padding: MaterialStateProperty.all(EdgeInsets.zero)
                                      ),
                                      onPressed: () {
                                        if (selectedUser != null && selectedUser!["id"] == item["id"]) setState(() => selectedUser = null);
                                        else setState(() => selectedUser = {"id": item["id"], "full_name": item["full_name"], "avatar_url": item["avatar_url"]});
                                        _clearEventOnMonth(DateTime.now());
                                        _getEventsForMonth(DateTime.now());
                                        this.setState(() {});
                                        Navigator.of(context).pop();
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: index != members.length -1 ? Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)) : null,
                                        ),
                                        padding: EdgeInsets.all(4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                CachedAvatar(
                                                  item["avatar_url"] ?? "",
                                                  name: item["full_name"],
                                                  width: 28,
                                                  height: 28
                                                ),
                                                SizedBox(width: 10),
                                                Text(
                                                  item["full_name"],
                                                  style: TextStyle(
                                                    color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                            Flexible(
                                              child: Container(
                                                margin: EdgeInsets.only(right: 5),
                                                child: selectedUser != null && selectedUser!["id"] == item["id"]
                                                  ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                                  : Container(width: 16, height: 16)
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                ),
                              ],
                            ),
                          )
                        );
                      }),
                    )
                  )
                )
              ],
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Số ngày công: $successDay"),
                    SizedBox(height: 8),
                    // Text("Tăng ca: $overTime"),
                    // SizedBox(height: 8),
                    Text("Công chưa duyệt: $failureDay"),
                    SizedBox(height: 8),
                    Text("Số ngày nghỉ: $outTime")
                  ],
                ),
                if (_selectedDate != null) _statsWidget(_selectedDate!),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraint) {
                  return MonthView<Event>(
                    showBorder: true,
                    width: constraint.maxWidth * 0.7,
                    cellAspectRatio: 1.7,
                    onCellTap: (events, date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    onPageChange: (date, page) {
                      _onSelectMonth(date);
                    },
                    weekDayBuilder: (day) {
                      return Center(
                        child: Container(
                          padding: EdgeInsets.all(5),
                          child: Text(Constants.weekTitles[day])
                        )
                      );
                    },
                    cellBuilder: (date, event, isToday, isInMonth) {
                      bool _eventSuccess = event.isNotEmpty && event[0].event != null && event[0].event!.success;
                      bool _eventNotSuccess =  event.isNotEmpty && event[0].event != null && !event[0].event!.success;
                      bool _isBreakFormInFuture = event.isNotEmpty && event[0].event != null && event[0].event!.checkIn == null && event[0].event!.checkOut == null && event[0].event!.form != null && event[0].event!.date.compareTo(DateTime.now()) > 0;
                      Form? _eventForm = event.isNotEmpty && event[0].event != null ? event[0].event!.form : null;
                      return GestureDetector(
                        onDoubleTap: () {
                          bool admin = currentMember['role_id'] == 1;

                          final hasForm = () {
                            final event = CalendarControllerProvider.of<Event>(context).controller.getEventsOnDay(date);
                            if (event.isNotEmpty && event[0].event != null && event[0].event!.form != null && (event[0].event!.form!.overtime == null)) return true;
                            return false;
                          }.call();

                          if(_eventSuccess) {
                            _showInfo(date);
                            return;
                          }
                          if (!admin && _eventNotSuccess && _eventForm == null) {
                            _showCreateForm(date);
                            return;
                          }
                          if(!admin && _eventForm != null) {
                            showFormInfo(date);
                            return;
                          }

                          if (admin && hasForm) {
                            showApproveForm(date);
                            return;
                          } else {
                            _showInfo(date);
                            return;
                          }
                        },
                        child: FilledCell<Event>(
                          isInMonth: isInMonth,
                          titleColor: Colors.white,
                          date: date,
                          events: event,
                          shouldHighlight: isToday && isInMonth,
                          shouldRounded: _selectedDate?.compareTo(date) == 0,
                          backgroundColor: event.length == 0 || !isInMonth
                                          ? Colors.grey : event[0].event!.success
                                    ? Color(0xff1E643B) : _isBreakFormInFuture ? Colors.grey : Color(0xff9B1414),
                        ),
                      );
                    },
                  );
                }
              ),
            ),
          ),
          currentMember['role_id'] > 1
            ? logCheckInOut()
            : InkWell(
                onTap:() => reviewCheckinOffset(),
                child: Container(
                  padding: EdgeInsets.all(15),
                  child: Text("Duyệt đơn xin nghỉ/Tăng ca"),
                ),
              )
        ],
      ),
    );
  }

  void _showInfo(DateTime date) {
    showModal(
      context: context,
      builder: (context) {
        return SimpleDialog(
          children: <Widget>[
            Center(
              child: Container(
                child: Column(
                  children: [
                    Text("Log checkin/out"),
                    SizedBox(height: 10),
                    _statsWidget(date),
                  ],
                )
              )
            )
          ]
        );
      }
    );
  }

  void _showCreateForm(DateTime date) async {
    final success = await showModal<bool>(
      context: context,
      builder: (context) {
        return ReasonForm(selectedDate: date);
      }
    );
    if (success != null && success) {
      _clearEventOnDay(date);
      _getEventsForMonth(date);
    }
  }

  void showApproveForm(date) async {
    await showModal(
      context: context,
      builder: (_) {
        return ReasonAdminViewer(
          selectedUser: selectedUser,
          selectedDate: date,
          data: CalendarControllerProvider.of<Event>(context).controller.getEventsOnDay(date)
        );
      }
    );
    _clearEventOnDay(date);
    _getEventsForMonth(date);
  }

  void showFormInfo(date) {
    final eventDate = CalendarControllerProvider.of<Event>(context).controller.getEventsOnDay(date);
    final form = eventDate[0].event!.form!;
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    showModal(
      context: context,
      builder: (context) {
        return SimpleDialog(
          contentPadding: EdgeInsets.all(10),
          children: [
            Text("Người tạo đơn: ${_getUserById(form.userId)["full_name"]}"),
            SizedBox(height: 10),
            Text("Lý do"),
            TextField(controller: TextEditingController(text: form.reason), readOnly: true, maxLines: 3, decoration: InputDecoration(border: OutlineInputBorder())),
            SizedBox(height: 10.0),
            Text("Người duyệt: ${_getUserById(form.approver)["full_name"]}"),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: EdgeInsets.only(right: 12),
                child: OutlinedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                  ),
                  onPressed: () async {
                    await showModal(
                      context: context,
                      builder: (context) => SimpleDialog(
                      children: <Widget>[
                        Center(
                          child: Container(
                            child: Column(
                              children: [
                                Icon(CupertinoIcons.exclamationmark_shield_fill, color: Colors.red),
                                SizedBox(height: 10),
                                Text(
                                  'bạn có muốn huỷ form này'
                                ),
                                SizedBox(height: 10),
                                Container(
                                  margin: EdgeInsets.only(right: 12),
                                  child: OutlinedButton(
                                    style: ButtonStyle(
                                      backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                                    ),
                                    onPressed: () async {
                                      await _removeForm(date);
                                      Navigator.pop(context, true);
                                      Navigator.pop(context, true);
                                    },
                                    child: Text(
                                      'Huỷ',
                                      style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                                  ),
                                ),
                              ],
                            )
                          )
                        )
                      ])
                    );
                  },
                  child: Text(
                    'Huỷ form',
                    style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                ),
              ),
            ),
          ],
        );
      }
    );
  }
  _getUserById(userId) {
    final wsMembers = Provider.of<Workspaces>(context, listen: false).members;
    final index = wsMembers.indexWhere((element) => element["account_type"] == "user" && element["id"] == userId);
    if (index != -1) return wsMembers[index];
    else return {};
  }
}

class FilledCell<T extends Object?> extends StatelessWidget {
  final DateTime date;
  final List<CalendarEventData<Event>> events;
  final bool shouldHighlight;
  final Color backgroundColor;
  final Color highlightColor;
  final Color tileColor;
  final TileTapCallback<T>? onTileTap;
  final bool isInMonth;
  final double highlightRadius;
  final Color titleColor;
  final Color highlightedTitleColor;
  final bool shouldRounded;
  const FilledCell({
    Key? key,
    required this.date,
    required this.events,
    this.isInMonth = false,
    this.shouldHighlight = false,
    this.backgroundColor = Colors.blue,
    this.highlightColor = Colors.blue,
    this.onTileTap,
    this.tileColor = Colors.blue,
    this.highlightRadius = 11,
    this.titleColor = Constants.black,
    this.highlightedTitleColor = Constants.white,
    this.shouldRounded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: shouldRounded ? Border.all(color: Colors.black) : null
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (events.isNotEmpty
            && events[0].event != null
            && events[0].event!.form != null
            && events[0].event!.form!.success == false
          ) Positioned(
            top: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: Colors.yellow,
              radius: 4,
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: 5.0,
              ),
              CircleAvatar(
                radius: highlightRadius,
                backgroundColor:
                    shouldHighlight ? highlightColor : Colors.transparent,
                child: Text(
                  "${date.day}",
                  style: TextStyle(
                    color: shouldHighlight
                        ? highlightedTitleColor
                        : isInMonth
                            ? titleColor
                            : titleColor.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Event {
  final DateTime date;
  final String? userId;
  DateTime? checkIn;
  DateTime? checkOut;
  String? reason;
  final bool success;
  Form? form;

  Event({this.userId, required this.date, this.checkIn, this.checkOut, this.reason, required this.success, this.form});

  @override
  bool operator == (Object other) => other is Event && date == other.date && checkIn == other.checkIn && checkOut == other.checkOut && reason == other.reason;

  @override
  int get hashCode => super.hashCode;

  @override
  String toString() {
    return "date:$date\ncheck_in:$checkIn\ncheck_out:$checkOut\nreason:$reason\nsuccess:$success\nform:$form";
  }
}

class Form {
  final int id;
  final String approver;
  final bool success;
  final String? reason;
  final workspaceId;
  final userId;
  Map? overtime;

  Form({required this.id, required this.userId, required this.workspaceId, required this.approver, required this.success, required this.reason, this.overtime});
  Form.fromData(data) :
                    id = data["id"],
                    approver = data["approver_id"],
                    userId = data["user_id"],
                    workspaceId = data["workspace_id"],
                    success = data["success"],
                    reason = data["reason"],
                    overtime = data["overtime"];
  @override
  String toString() {
    return "{id:$id\napprover:$approver\nsuccess:$success\nreason:$reason\nworkspaceId:$workspaceId\nuserId:$userId}";
  }
}

enum CalendarView {
  month,
  day,
  week,
}
class Constants {
  Constants._();

  static final Random _random = Random();
  static final int _maxColor = 256;

  static const int hoursADay = 24;

  static final List<String> weekTitles = ["Mon", "Tue", "Wed", "Thus", "Fri", "Sat", "Sun"];

  static const Color defaultLiveTimeIndicatorColor = Color(0xff444444);
  static const Color defaultBorderColor = Color(0xffdddddd);
  static const Color black = Color(0xff000000);
  static const Color white = Color(0xffffffff);
  static const Color offWhite = Color(0xfff0f0f0);
  static const Color headerBackground = Color(0xFFDCF0FF);
  static Color get randomColor {
    return Color.fromRGBO(_random.nextInt(_maxColor),
        _random.nextInt(_maxColor), _random.nextInt(_maxColor), 1);
  }
}

class TimeSheetsConfig extends StatefulWidget {
  final Function? changeView;
  TimeSheetsConfig({Key? key, this.changeView}) : super(key: key);

  @override
  State<TimeSheetsConfig> createState() => _TimeSheetsConfigState();
}

class _TimeSheetsConfigState extends State<TimeSheetsConfig> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final currentMember = Provider.of<Workspaces>(context, listen: false).currentMember;

    return Container(
      padding: EdgeInsets.all(24),
      color: auth.theme == ThemeType.DARK ? Palette.backgroundRightSiderDark : Palette.backgroundRightSiderLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                margin: EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => widget.changeView!(1),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Icon(PhosphorIcons.arrowLeft, size: 20,),
                  ),
                ),
              ),
              Text("Chấm công", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
          Expanded(
            child: Center(
              child: currentMember["role_id"] > 1
                ? Text("Owner cần phải cấu hình chấm công cho workspace này trước.")
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Bạn chưa cấu hình chấm công cho workspace này."),
                    SizedBox(height: 10),
                    Container(
                      margin: EdgeInsets.only(right: 12),
                      child: OutlinedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                        ),
                        onPressed: () => onConfigTimesheets(context, null),
                        child: Text(
                          'Cấu hình',
                          style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                      ),
                    ),
                  ],
                )
            )
          )
        ],
      )
    );
  }
}

onConfigTimesheets(context, setting) {
  final auth = Provider.of<Auth>(context, listen: false);
  final isDark = auth.theme == ThemeType.DARK;

  showModal(
    context: context,
    builder: (BuildContext context) {
      int tab = 1;
      TimeOfDay? startTime = setting != null ? TimeOfDay(hour: int.parse(setting["start_time"].split(":")[0]),minute: int.parse(setting["start_time"].split(":")[1])) : null;
      TimeOfDay? endTime = setting != null ? TimeOfDay(hour: int.parse(setting["end_time"].split(":")[0]),minute: int.parse(setting["end_time"].split(":")[1])) : null;
      Map wifiConfig = {
        "selected": Map.fromIterable(((setting ?? {})["wifi"] ?? []), key: (v) => v["bssid"], value: (v) => v),
        "total": (((setting ?? {})["wifi"] ?? []).map((e) => e as Map).toList())
      };
      return StatefulBuilder(
        builder: (context, setState) {
          _selectStartTime(BuildContext context) async {
            final picked = await showTimePicker(
              context: context,
              initialTime: startTime ?? TimeOfDay.now(),
              builder: (BuildContext context, Widget? child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                );
              },
            );

            if (picked != null && picked != startTime) {
              setState(() => startTime = picked);
            }
          }

          _selectEndTime(BuildContext context) async {
            final picked = await showTimePicker(
              context: context,
              initialTime: endTime ?? TimeOfDay.now(),
              builder: (BuildContext context, Widget? child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                );
              },
            );

            if (picked != null && picked != endTime) {
              setState(() => endTime = picked);
            }
          }

          onHandleSaveConfig() async {
            final currentWs = Provider.of<Workspaces>(context, listen: false).currentWorkspace;

            Map workspace = new Map.from(currentWs);
            if (startTime != null && endTime != null) {
              workspace["timesheets_config"] = {
                "start_time": "${startTime?.to24hours()}",
                "end_time": "${endTime?.to24hours()}",
                "wifi": (wifiConfig["selected"] as Map).values.toList()
              };
              await Provider.of<Workspaces>(context, listen: false).changeWorkspaceInfo(auth.token, currentWs["id"], workspace);
              Navigator.of(context, rootNavigator: true).pop("Discard");
            } else {
              showModal(
                context: context,
                builder: (_) => SimpleDialog(
                children: <Widget>[
                  Center(
                    child: Container(
                      child: Column(
                        children: [
                          Icon(CupertinoIcons.xmark_circle_fill, color: Colors.red),
                          SizedBox(height: 10),
                          Text('Yêu cầu chọn thời gian bắt đầu và kết thúc phiên làm việc trong ngày.'),
                        ],
                      )
                    )
                  )
                ])
              );
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0)),
            title: Container(
              decoration: BoxDecoration(
                color: isDark ? Color(0xff5E5E5E).withOpacity(0.5) : Color(0xffF3F3F3),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4.0),
                  topLeft: Radius.circular(4.0)
                )
              ),
              child: Container(
                padding: const EdgeInsets.only(top: 9, bottom: 9, left: 16),
                child: Text("Cấu hình chấm công", style: TextStyle(fontSize: 16))
              ),
            ),
            titlePadding: const EdgeInsets.all(0),
            backgroundColor: isDark ? Palette.backgroundTheardDark : Colors.white,
            contentPadding: EdgeInsets.zero,
            content: Container(
              padding: EdgeInsets.all(10),
              width: 500,
              child: Column(
                children: [
                  Stack(
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () => setState(() => tab = 1),
                            child: Ink(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                decoration: BoxDecoration(
                                  border: tab == 1 ? Border(bottom: BorderSide(width: 2.0, color: isDark ? Palette.calendulaGold : Palette.dayBlue)) : null
                                ),
                                alignment: Alignment.center,
                                height: 30,
                                child: Text("Thời gian làm việc", style: TextStyle(fontSize: 13))
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() => tab = 2),
                            child: Ink(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                decoration: BoxDecoration(
                                  border: tab == 2 ? Border(bottom: BorderSide(width: 2.0, color: isDark ? Palette.calendulaGold : Palette.dayBlue)) : null
                                ),
                                alignment: Alignment.center,
                                height: 30,
                                child: Text("Cấu hình wifi", style: TextStyle(fontSize: 13))
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Divider(height: 2, thickness: 2,),
                      )
                    ],
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      child: tab == 1
                        ? Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 150,
                                  child: Text("Thời gian checkin", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14))
                                ),
                                Container(
                                  height: 36,
                                  padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: isDark ? Color(0xff1E1E1E) : Colors.white,
                                    border: Border.all(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      _selectStartTime(context);
                                    },
                                    child: Container(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          startTime != null
                                            ? Text(
                                                "${startTime?.hour}:${startTime?.minute}",
                                                style: TextStyle(color: isDark ? Colors.white.withOpacity(0.85) : Color(0xff1F2933), fontSize: 13.0, fontWeight: FontWeight.w300)
                                              )
                                            : Center(
                                                child: Text('Select start time', style: TextStyle(fontSize: 13, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65),)),
                                              ),
                                          SizedBox(width: 5,),
                                          Icon(Icons.calendar_today_outlined, size: 16.0, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65))
                                        ],
                                      ),
                                    )
                                  ),
                                )
                              ],
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  width: 150,
                                  child: Text("Thời gian checkout", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14))
                                ),
                                Container(
                                  height: 36,
                                  padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: isDark ? Color(0xff1E1E1E) : Colors.white,
                                    border: Border.all(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      _selectEndTime(context);
                                    },
                                    child: Container(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          endTime != null
                                            ? Text(
                                                "${endTime?.hour}:${endTime?.minute}",
                                                style: TextStyle(color: isDark ? Colors.white.withOpacity(0.85) : Color(0xff1F2933), fontSize: 13.0, fontWeight: FontWeight.w300)
                                              )
                                            : Center(
                                                child: Text('Select end time', style: TextStyle(fontSize: 13, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65),)),
                                              ),
                                          SizedBox(width: 5,),
                                          Icon(Icons.calendar_today_outlined, size: 16.0, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65))
                                        ],
                                      ),
                                    )
                                  ),
                                )
                              ],
                            )
                          ],
                        )
                        : WifiScanner(wifiConfig: wifiConfig, onChangeSelected: (wifi) => wifiConfig = wifi,)
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(border: Border(top: BorderSide(width: 0.2, color: Colors.grey))),
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 120, height: 32,
                          margin: EdgeInsets.only(right: 12),
                          child: OutlinedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                            ),
                            onPressed: () => onHandleSaveConfig(),
                            child: Text(
                              'Lưu cấu hình',
                              style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  );
}

class FormBreakWorkDay extends StatefulWidget {
  const FormBreakWorkDay({Key? key}) : super(key: key);

  @override
  State<FormBreakWorkDay> createState() => _FormBreakWorkDayState();
}

class _FormBreakWorkDayState extends State<FormBreakWorkDay> {
  String type = "off";

  @override
  Widget build(BuildContext context) {
    final auth = context.read<Auth>();
    final isDark = auth.theme == ThemeType.DARK;
    final wsMembers = context.read<Workspaces>().members;
    final currentUser = context.read<User>().currentUser;
    final members = wsMembers.where((ele) => ele["account_type"] == 'user' && ele["role_id"] <= 2 && ele["id"] != currentUser['id']).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0)),
      title: Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xff5E5E5E).withOpacity(0.5) : Color(0xffF3F3F3),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(4.0),
            topLeft: Radius.circular(4.0)
          )
        ),
        child: Container(
          padding: const EdgeInsets.only(top: 9, bottom: 9, left: 16),
          child: Text("Tạo yêu cầu")
        ),
      ),
      titlePadding: const EdgeInsets.all(0),
      backgroundColor: isDark ? Palette.backgroundTheardDark : Colors.white,
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 600,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: EdgeInsets.only(left: 10, right: 10, top: 10),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => setState(() => type = 'off'),
                        child: Ink(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              border: type == 'off' ? Border(bottom: BorderSide(width: 2.0, color: isDark ? Palette.calendulaGold : Palette.dayBlue)) : null
                            ),
                            alignment: Alignment.center,
                            height: 30,
                            child: Text("Xin nghỉ", style: TextStyle(color: type == 'off' ? isDark ? Colors.white : Colors.black : Colors.grey, fontSize: 14))
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => type = 'overtime'),
                        child: Ink(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              border: type == 'overtime' ? Border(bottom: BorderSide(width: 2.0, color: isDark ? Palette.calendulaGold : Palette.dayBlue)) : null
                            ),
                            alignment: Alignment.center,
                            height: 30,
                            child: Text("Tăng ca", style: TextStyle(color: type == 'overtime' ? isDark ? Colors.white : Colors.black : Colors.grey, fontSize: 14))
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Divider(height: 2, thickness: 2,),
                )
              ],
            ),
            Expanded(
              child: Center(
                child: type == 'off'
                  ? FormBreak(auth: auth, members: members, type: type)
                  : FormOvertime(auth: auth, members: members, type: type),
              ),
            )
          ],
        ),
      )
    );
  }
}

class ReviewFormTimesheets extends StatefulWidget {
  const ReviewFormTimesheets({Key? key}) : super(key: key);

  @override
  State<ReviewFormTimesheets> createState() => _ReviewFormTimesheetsState();
}

class _ReviewFormTimesheetsState extends State<ReviewFormTimesheets> {
  bool isLoading = false;
  List formReview = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getReviewFormTimesheets();
    });
  }

  _getReviewFormTimesheets() async {
    setState(() => isLoading = true);
    final token = Provider.of<Auth>(context, listen: false).token;
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];

    final url = Utils.apiUrl + 'workspaces/$workspaceId/index_timesheets_form?token=$token';
    try {
      final response = await Dio().get(url);
      var dataRes = response.data;
      if (dataRes["success"]) {
        setState(() {
          formReview = dataRes["data"];
          isLoading = false;
        });
      }
    } catch (e, trace) {
      print("Error Channel: $trace");
      setState(() => isLoading = false);
    }
  }

  _reviewFormTimesheets(formId, status, date, senderId, reason, overtime, token) async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];

    final url = Utils.apiUrl + 'workspaces/$workspaceId/checkin_offset?token=$token';
    try {
      final response = await Dio().post(url, data: json.encode({
        "success": status,
        "is_approved": true,
        "date": date,
        "sender_id": senderId,
        'form_id': formId,
        'overtime': overtime,
        'reason': reason,
      }));
      var dataRes = response.data;
      if (dataRes["success"]) {
        Navigator.of(context, rootNavigator: true).pop("Discard");
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
            Center(
              child: Container(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.xmark_circle_fill, color: Colors.red),
                    SizedBox(height: 10),
                    Text(dataRes["message"] ?? ""),
                  ],
                )
              )
            )
          ])
        );
      } else {
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
            Center(
              child: Container(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.xmark_circle_fill, color: Colors.red),
                    SizedBox(height: 10),
                    Text(dataRes["message"]),
                  ],
                )
              )
            )
          ])
        );
      }
    } catch (e, trace) {
      print("Error Channel: $trace");
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;

    return Container(
      width: 600,
      padding: EdgeInsets.all(10),
      child: isLoading
        ? Center(
          child: SpinKitFadingCircle(
            color: isDark ? Colors.white60 : Color(0xff096DD9),
            size: 15,
          ))
        : Container(
            child: formReview.length > 0
              ? SingleChildScrollView(
                child: Column(
                  children: [
                    ...formReview.map((ele) {
                      return Card(
                        color: isDark ? null : Colors.grey[200],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 0.2, color: Colors.grey))),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                              margin: EdgeInsets.only(bottom: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Đơn ${Utils.checkedTypeEmpty(ele['overtime']) ? 'tăng ca' : 'xin nghỉ'} của ${ele['full_name']}", style: TextStyle(fontSize: 15)),
                                ],
                              )
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  Text("Ngày: ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                                  Text("${ele["date"]}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14))
                                ],
                              )
                            ),
                            SizedBox(height: 10),
                            Utils.checkedTypeEmpty(ele['overtime'])
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Row(
                                    children: [
                                      Text("Thời gian: ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                                      Text("${ele["overtime"]['start_time']} - ${ele["overtime"]['end_time']}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14))
                                    ],
                                  )
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Row(
                                    children: [
                                      Text("Lý do: ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                                      Text("${ele["reason"]}", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14))
                                    ],
                                  )
                                ),
                            Container(
                              decoration: BoxDecoration(border: Border(top: BorderSide(width: 0.2, color: Colors.grey))),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                              margin: EdgeInsets.only(top: 16),
                              child: Row(
                                // mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 100, height: 32,
                                    margin: EdgeInsets.only(right: 12),
                                    child: OutlinedButton(
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                                      ),
                                      onPressed: () => _reviewFormTimesheets(ele["id"], true, ele["date"], ele["user_id"], ele["reason"], ele["overtime"], auth.token),
                                      child: Text(
                                            'Duyệt',
                                            style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                                    ),
                                  ),
                                  Container(
                                    width: 100, height: 32,
                                    margin: EdgeInsets.only(right: 12),
                                    child: OutlinedButton(
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all(Colors.red),
                                      ),
                                      onPressed: () => _reviewFormTimesheets(ele["id"], false, ele["date"], ele["user_id"], ele["reason"], ele["overtime"], auth.token),
                                      child: Text(
                                            'Từ chối',
                                            style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ]
                ),
              )
              : Center(
                child: Text("Không có yêu cầu duyệt."),
              ),
          ),
    );
  }
}

class FormBreak extends StatefulWidget {
  final auth;
  final members;
  final type;
  const FormBreak({Key? key, this.auth, this.members, this.type}) : super(key: key);

  @override
  State<FormBreak> createState() => _FormBreakState();
}

class _FormBreakState extends State<FormBreak> {
  final TextEditingController _controller = TextEditingController();
  DateTime? dateTime;
  Map? selectedUser;

  void dispose(){
    _controller.dispose();
    super.dispose();
  }

  _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != dateTime) {
      setState(() {
        dateTime = picked;
      });
    }
  }

  _onSendFormTimesheets(BuildContext context) async {
    final token = widget.auth.token;
    final currentWs = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final workspaceId = currentWs["id"];

    final url = Utils.apiUrl + 'workspaces/$workspaceId/send_form_timesheet?token=$token';
    if (selectedUser != null && dateTime != null && _controller.text != "") {
      try {
        final body = {
          "approver_id": selectedUser!["id"],
          "date": dateTime.toString(),
          "reason": _controller.text
        };
        final response = await Dio().post(url, data: json.encode(body));
        var dataRes = response.data;
        if (dataRes["success"]) {
          Navigator.pop(context, true);
          showModal(
            context: context,
            builder: (_) => SimpleDialog(
            children: <Widget>[
              Center(
                child: Container(
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.green),
                      SizedBox(height: 10),
                      Text(dataRes["message"] ?? "Tạo form thành công"),
                    ],
                  )
                )
              )
            ])
          );
        } else {
          showModal(
            context: context,
            builder: (_) => SimpleDialog(
            children: <Widget>[
              Center(
                child: Container(
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.xmark_circle_fill, color: Colors.red),
                      SizedBox(height: 10),
                      Text(dataRes["message"]),
                    ],
                  )
                )
              )
            ])
          );
        }
      } catch (e, trace) {
        print("Error Channel: $trace");
        // sl.get<Auth>().showErrorDialog(e.toString());
      }
    } else {
      showModal(
        context: context,
        builder: (_) => SimpleDialog(
        children: <Widget>[
          Center(
            child: Container(
              child: Column(
                children: [
                  Icon(CupertinoIcons.xmark_circle_fill, color: Colors.red),
                  SizedBox(height: 10),
                  Text("Nhập đủ thông tin mới có thể gửi form."),
                ],
              )
            )
          )
        ])
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.auth.theme == ThemeType.DARK;
    final members = widget.members;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(10),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Chọn ngày nghỉ", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                        SizedBox(height: 8),
                        Container(
                          margin: EdgeInsets.only(left: 10),
                          child: Container(
                            height: 36,
                            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: isDark ? Color(0xff1E1E1E) : Colors.white,
                              border: Border.all(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))
                            ),
                            child: InkWell(
                              onTap: () {
                                _selectDate(context);
                              },
                              child: Container(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    dateTime != null
                                      ? Text(
                                          DateFormatter().renderTime(dateTime!, type: "dd/MM/yyyy"),
                                          style: TextStyle(color: isDark ? Colors.white.withOpacity(0.85) : Color(0xff1F2933), fontSize: 13.0, fontWeight: FontWeight.w300)
                                        )
                                      : Center(
                                          child: Text('Chọn ngày nghỉ', style: TextStyle(fontSize: 13, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65),)),
                                        ),
                                    Icon(Icons.calendar_today_outlined, size: 16.0, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65))
                                  ],
                                ),
                              )
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Chọn người duyệt", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                        SizedBox(height: 8),
                        Container(
                          margin: EdgeInsets.only(left: 10),
                          child: DropdownOverlay(
                            width: 200,
                            isAnimated: true,
                            menuDirection: MenuDirection.start,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: HoverItem(
                                colorHover: Palette.hoverColorDefault,
                                child: Container(
                                  height: 36,
                                  constraints: new BoxConstraints(
                                    minWidth: 200,
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      width: 1,
                                      color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:  MainAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                        child: selectedUser != null
                                          ? Row(
                                            children: [
                                              CachedAvatar(
                                                selectedUser!["avatar_url"] ?? "",
                                                name: selectedUser!["full_name"],
                                                width: 28,
                                                height: 28
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                selectedUser!["full_name"],
                                                style: TextStyle(
                                                  color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          )
                                        : Text(
                                            "Chọn người kiểm duyệt",
                                            style: TextStyle(
                                              color: isDark ? Color(0xffF0F4F8) : Colors.black45,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(CupertinoIcons.arrowtriangle_down_fill, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65), size: 12),
                                    ]
                                  ),
                                ),
                              ),
                            ),
                            dropdownWindow: StatefulBuilder(
                              builder: ((context, setState) {
                                return Container(
                                  constraints: new BoxConstraints(
                                    maxHeight: 300.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark ? Palette.backgroundTheardDark : Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: members.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            final item = members[index];

                                            return TextButton(
                                              style: ButtonStyle(
                                                overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                                                padding: MaterialStateProperty.all(EdgeInsets.zero)
                                              ),
                                              onPressed: () {
                                                if (selectedUser != null && selectedUser!["id"] == item["id"]) setState(() => selectedUser = null);
                                                else setState(() => selectedUser = {"id": item["id"], "full_name": item["full_name"], "avatar_url": item["avatar_url"]});
                                                this.setState(() {});
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: index != members.length -1 ? Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)) : null,
                                                ),
                                                padding: EdgeInsets.all(12),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        CachedAvatar(
                                                          item["avatar_url"] ?? "",
                                                          name: item["name"],
                                                          width: 28,
                                                          height: 28
                                                        ),
                                                        SizedBox(width: 10),
                                                        Text(
                                                          item["full_name"],
                                                          style: TextStyle(
                                                            color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                    Flexible(
                                                      child: Container(
                                                        margin: EdgeInsets.only(right: 5),
                                                        child: selectedUser != null && selectedUser!["id"] == item["id"]
                                                          ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                                          : Container(width: 16, height: 16)
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }
                                        ),
                                      ],
                                    ),
                                  )
                                );
                              }),
                            )
                          )
                        )
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Lý do", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                        SizedBox(height: 8),
                        Container(
                          height: 100,
                          color: isDark ? Palette.backgroundTheardDark : Colors.white,
                          child: TextFormField(
                            // focusNode: _titleNode,
                            autofocus: true,
                            maxLines: 4,
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: "Nhập lý do",
                              hintStyle: TextStyle(
                                color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65),
                                fontSize: 13,
                                fontWeight: FontWeight.w300),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight),
                                borderRadius: const BorderRadius.all(Radius.circular(2))
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight),
                                borderRadius: const BorderRadius.all(Radius.circular(2))
                              ),
                            ),
                            style: TextStyle(color: isDark ? Colors.white : const Color.fromRGBO( 0, 0, 0, 0.65), fontSize: 15, fontWeight: FontWeight.normal),
                            onChanged: (value) => {},
                          ),
                        )
                      ],
                    ),
                  )
                ]
              ),
            ),
          ),
        ),
        Container(
          decoration:  BoxDecoration(border: Border(top: BorderSide(width: 0.2, color: Colors.grey))),
          padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 120, height: 32,
                margin: EdgeInsets.only(right: 12),
                child: OutlinedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                  ),
                  onPressed: () => _onSendFormTimesheets(context),
                  child: Text(
                    'Tạo yêu cầu',
                    style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FormOvertime extends StatefulWidget {
  final auth;
  final members;
  final type;
  FormOvertime({Key? key, this.auth, this.members, this.type}) : super(key: key);

  @override
  State<FormOvertime> createState() => _FormOvertimeState();
}

class _FormOvertimeState extends State<FormOvertime> {
  Map? selectedUser;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  _onSendFormTimesheets(context) async {
    final token = widget.auth.token;
    final currentWs = Provider.of<Workspaces>(context, listen: false).currentWorkspace;
    final workspaceId = currentWs["id"];

    final url = Utils.apiUrl + 'workspaces/$workspaceId/send_form_overtime?token=$token';
    if (selectedUser != null && startTime != null && endTime != null) {
      try {
        final body = {
          "approver_id": selectedUser!["id"],
          "overtime": {
            "start_time": "${startTime?.to24hours()}",
            "end_time": "${endTime?.to24hours()}"
          }
        };
        final response = await Dio().post(url, data: json.encode(body));
        var dataRes = response.data;
        if (dataRes["success"]) {
          Navigator.of(context, rootNavigator: true).pop("Discard");
        } else {
          showModal(
            context: context,
            builder: (_) => SimpleDialog(
            children: <Widget>[
              Center(
                child: Container(
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.xmark_circle_fill, color: Colors.red),
                      SizedBox(height: 10),
                      Text(dataRes["message"]),
                    ],
                  )
                )
              )
            ])
          );
        }
      } catch (e, trace) {
        print("Error Channel: $trace");
        // sl.get<Auth>().showErrorDialog(e.toString());
      }
    } else {
      showModal(
        context: context,
        builder: (_) => SimpleDialog(
        children: <Widget>[
          Center(
            child: Container(
              child: Column(
                children: [
                  Icon(CupertinoIcons.xmark_circle_fill, color: Colors.red),
                  SizedBox(height: 10),
                  Text("Nhập đủ thông tin mới có thể gửi form."),
                ],
              )
            )
          )
        ])
      );
    }
  }

  _selectStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: startTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && picked != startTime) {
      setState(() => startTime = picked);
    }
  }

  _selectEndTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: endTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && picked != endTime) {
      setState(() => endTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.auth.theme == ThemeType.DARK;
    final members = widget.members;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(10),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Container(
                          width: 150,
                          child: Text("Thời gian bắt đầu tăng ca", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14))
                        ),
                        Container(
                          height: 36,
                          padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isDark ? Color(0xff1E1E1E) : Colors.white,
                            border: Border.all(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))
                          ),
                          child: InkWell(
                            onTap: () {
                              _selectStartTime(context);
                            },
                            child: Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  startTime != null
                                    ? Text(
                                        "${startTime?.hour}:${startTime?.minute}",
                                        style: TextStyle(color: isDark ? Colors.white.withOpacity(0.85) : Color(0xff1F2933), fontSize: 13.0, fontWeight: FontWeight.w300)
                                      )
                                    : Center(
                                        child: Text('Select start time', style: TextStyle(fontSize: 13, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65),)),
                                      ),
                                  SizedBox(width: 5,),
                                  Icon(Icons.calendar_today_outlined, size: 16.0, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65))
                                ],
                              ),
                            )
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Container(
                          width: 150,
                          child: Text("Thời gian kết thúc tăng ca", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14))
                        ),
                        Container(
                          height: 36,
                          padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isDark ? Color(0xff1E1E1E) : Colors.white,
                            border: Border.all(color: isDark ? Color(0xff52606D) : Color(0xffCBD2D9))
                          ),
                          child: InkWell(
                            onTap: () {
                              _selectEndTime(context);
                            },
                            child: Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  endTime != null
                                    ? Text(
                                        "${endTime?.hour}:${endTime?.minute}",
                                        style: TextStyle(color: isDark ? Colors.white.withOpacity(0.85) : Color(0xff1F2933), fontSize: 13.0, fontWeight: FontWeight.w300)
                                      )
                                    : Center(
                                        child: Text('Select end time', style: TextStyle(fontSize: 13, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65),)),
                                      ),
                                  SizedBox(width: 5,),
                                  Icon(Icons.calendar_today_outlined, size: 16.0, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65))
                                ],
                              ),
                            )
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Chọn người duyệt", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                        SizedBox(height: 8),
                        Container(
                          margin: EdgeInsets.only(left: 10),
                          child: DropdownOverlay(
                            width: 200,
                            isAnimated: true,
                            menuDirection: MenuDirection.start,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: HoverItem(
                                colorHover: Palette.hoverColorDefault,
                                child: Container(
                                  height: 36,
                                  constraints: new BoxConstraints(
                                    minWidth: 200,
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      width: 1,
                                      color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:  MainAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                        child: selectedUser != null
                                          ? Row(
                                            children: [
                                              CachedAvatar(
                                                selectedUser!["avatar_url"] ?? "",
                                                name: selectedUser!["full_name"],
                                                width: 28,
                                                height: 28
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                selectedUser!["full_name"],
                                                style: TextStyle(
                                                  color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          )
                                        : Text(
                                            "Chọn người kiểm duyệt",
                                            style: TextStyle(
                                              color: isDark ? Color(0xffF0F4F8) : Colors.black45,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(CupertinoIcons.arrowtriangle_down_fill, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65), size: 12),
                                    ]
                                  ),
                                ),
                              ),
                            ),
                            dropdownWindow: StatefulBuilder(
                              builder: ((context, setState) {
                                return Container(
                                  constraints: new BoxConstraints(
                                    maxHeight: 300.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark ? Palette.backgroundTheardDark : Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: members.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            final item = members[index];

                                            return TextButton(
                                              style: ButtonStyle(
                                                overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                                                padding: MaterialStateProperty.all(EdgeInsets.zero)
                                              ),
                                              onPressed: () {
                                                if (selectedUser != null && selectedUser!["id"] == item["id"]) setState(() => selectedUser = null);
                                                else setState(() => selectedUser = {"id": item["id"], "full_name": item["full_name"], "avatar_url": item["avatar_url"]});
                                                this.setState(() {});
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: index != members.length -1 ? Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)) : null,
                                                ),
                                                padding: EdgeInsets.all(12),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        CachedAvatar(
                                                          item["avatar_url"] ?? "",
                                                          name: item["name"],
                                                          width: 28,
                                                          height: 28
                                                        ),
                                                        SizedBox(width: 10),
                                                        Text(
                                                          item["full_name"],
                                                          style: TextStyle(
                                                            color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                    Flexible(
                                                      child: Container(
                                                        margin: EdgeInsets.only(right: 5),
                                                        child: selectedUser != null && selectedUser!["id"] == item["id"]
                                                          ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                                          : Container(width: 16, height: 16)
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }
                                        ),
                                      ],
                                    ),
                                  )
                                );
                              }),
                            )
                          )
                        )
                      ],
                    ),
                  ),
                ]
              ),
            ),
          ),
        ),
        Container(
          decoration:  BoxDecoration(border: Border(top: BorderSide(width: 0.2, color: Colors.grey))),
          padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 120, height: 32,
                margin: EdgeInsets.only(right: 12),
                child: OutlinedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
                  ),
                  onPressed: () => _onSendFormTimesheets(context),
                  child: Text(
                    'Tạo yêu cầu',
                    style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ReasonForm extends StatefulWidget {
  final selectedDate;
  const ReasonForm({Key? key, this.selectedDate}) : super(key: key);

  @override
  State<ReasonForm> createState() => _ReasonFormState();
}

class _ReasonFormState extends State<ReasonForm> {
  Map? _selectedUser;
  String? _reason;

  _onSendFormTimesheets(token) async {
    final currentWs = context.read<Workspaces>().currentWorkspace;
    final workspaceId = currentWs["id"];

    final url = Utils.apiUrl + 'workspaces/$workspaceId/send_form_timesheet?token=$token';
    if (widget.selectedDate != null && _selectedUser != null && _reason != null) {
      final body = {
        "approver_id": _selectedUser!["id"],
        "date": widget.selectedDate.toString(),
        "reason": _reason!
      };
      final response = await Dio().post(url, data: json.encode(body));
      var dataRes = response.data;
      if (dataRes["success"]) {
        Navigator.pop(context, true);
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
            Center(
              child: Container(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.green),
                    SizedBox(height: 10),
                    Text(dataRes["message"] ?? "Tạo form thành công"),
                  ],
                )
              )
            )
          ])
        );
      }
    } else {
      showModal(
        context: context,
        builder: (context) {
          return SimpleDialog(
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.exclamationmark_shield_fill, color: Colors.red),
                    SizedBox(height: 10),
                    Text("Vui lòng nhập đủ thông tin để tạo form")
                  ],
                ),
              )
            ],
          );
        }
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final auth = context.read<Auth>();
    final isDark = auth.theme == ThemeType.DARK;
    final currentUser = context.read<User>().currentUser;
    final wsMembers = context.read<Workspaces>().members;
    final members = wsMembers.where((ele) => ele["account_type"] == 'user' && ele["role_id"] <= 2 && ele["id"] != currentUser['id']).toList();

    final approver = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Chọn người duyệt"),
        SizedBox(height: 8),
        DropdownOverlay(
          isAnimated: true,
          width: 200,
          menuDirection: MenuDirection.mid,
          dropdownWindow: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                color: Colors.red,
                width: 1000,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...members.map((item) {
                        return TextButton(
                          style: ButtonStyle(
                            overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                            padding: MaterialStateProperty.all(EdgeInsets.zero)
                          ),
                          onPressed: () {
                            if (_selectedUser != null && _selectedUser!["id"] == item["id"]) setState(() => _selectedUser = null);
                            else setState(() => _selectedUser = {"id": item["id"], "full_name": item["full_name"], "avatar_url": item["avatar_url"]});
                            this.setState(() {});
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: item != members.last ? Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)) : null,
                            ),
                            padding: EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CachedAvatar(
                                      item["avatar_url"] ?? "",
                                      name: item["name"],
                                      width: 28,
                                      height: 28
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      item["full_name"],
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                Flexible(
                                  child: Container(
                                    margin: EdgeInsets.only(right: 5),
                                    child: _selectedUser != null && _selectedUser!["id"] == item["id"]
                                      ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                      : Container(width: 16, height: 16)
                                  ),
                                ),
                              ],
                            ),
                          )
                        );
                      }).toList()
                    ],
                  ),
                ),
              );
            },
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: HoverItem(
              colorHover: Palette.hoverColorDefault,
              child: Container(
                height: 36,
                constraints: new BoxConstraints(
                  minWidth: 200,
                ),
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    width: 1,
                    color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight
                  ),
                ),
                child: Row(
                  children: [
                    _selectedUser != null ?
                    Row(
                      children: [
                        CachedAvatar(
                          _selectedUser!["avatar_url"] ?? "",
                          name: _selectedUser!["full_name"],
                          width: 28, height: 28
                        ),
                        SizedBox(width: 10),
                        Text(
                          _selectedUser!["full_name"],
                          style: TextStyle(
                            color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ) :
                    Text("Chọn người duyệt", style: TextStyle(
                      color: isDark ? Color(0xffF0F4F8) : Colors.black45,
                      overflow: TextOverflow.ellipsis,
                    )),
                    SizedBox(width: 8),
                    Icon(CupertinoIcons.arrowtriangle_down_fill, color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65), size: 12),
                  ],
                ),
              ),
            ),
          )
        )
      ],
    );

    final reasonBox = Container(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Lý do", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
          SizedBox(height: 8),
          Container(
            height: 100,
            color: isDark ? Palette.backgroundTheardDark : Colors.white,
            child: TextFormField(
              // focusNode: _titleNode,
              autofocus: true,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Nhập lý do",
                hintStyle: TextStyle(
                  color: isDark ? Color(0xff9AA5B1) : Color.fromRGBO(0, 0, 0, 0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w300),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight),
                  borderRadius: const BorderRadius.all(Radius.circular(2))
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight),
                  borderRadius: const BorderRadius.all(Radius.circular(2))
                ),
              ),
              style: TextStyle(color: isDark ? Colors.white : const Color.fromRGBO( 0, 0, 0, 0.65), fontSize: 15, fontWeight: FontWeight.normal),
              onChanged: (value) {
                _reason = value;
              },
            ),
          )
        ],
      ),
    );
    final submitButton = Container(
      decoration:  BoxDecoration(border: Border(top: BorderSide(width: 0.2, color: Colors.grey))),
      padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 120, height: 32,
            margin: EdgeInsets.only(right: 12),
            child: OutlinedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
              ),
              onPressed: () => _onSendFormTimesheets(auth.token),
              child: Text(
                'Tạo yêu cầu',
                style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
            ),
          ),
        ],
      ),
    );
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0)
      ),
      title: Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xff5E5E5E).withOpacity(0.5) : Color(0xffF3F3F3),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(4.0),
            topLeft: Radius.circular(4.0)
          )
        ),
        child: Container(
          padding: const EdgeInsets.only(top: 9, bottom: 9, left: 16),
          child: Text("Lý do")
        ),
      ),
      titlePadding: const EdgeInsets.all(0),
      backgroundColor: isDark ? Palette.backgroundTheardDark : Colors.white,
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    approver,
                    reasonBox
                  ],
                ),
              ),
            ),
            submitButton
          ],
        ),
      ),
    );
  }
}

class ReasonAdminViewer extends StatefulWidget {
  final selectedUser;
  final selectedDate;
  final data;
  const ReasonAdminViewer({Key? key, this.selectedUser, this.selectedDate, this.data}) : super(key: key);

  @override
  State<ReasonAdminViewer> createState() => _ReasonAdminViewerState();
}

class _ReasonAdminViewerState extends State<ReasonAdminViewer> {
  Event? data;

  @override
  void initState() {
    super.initState();
    final event = widget.data;
    data = event[0].event!;
  }
  // _getUserById(userId) {
  //   final wsMembers = Provider.of<Workspaces>(context, listen: false).members;
  //   final index = wsMembers.indexWhere((element) => element["account_type"] == "user" && element["id"] == userId);
  //   if (index != -1) return wsMembers[index];
  //   else return {};
  // }
  _onApprovedRequest() async {
    final token = Provider.of<Auth>(context, listen: false).token;
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];

    final url = Utils.apiUrl + 'workspaces/$workspaceId/checkin_offset?token=$token';
    try {
      final response = await Dio().post(url, data: json.encode({"is_approved": true, "date": DateFormat('yyyy-MM-dd').format(data!.date), "sender_id": widget.selectedUser["id"], 'form_id': data!.form!.id, 'overtime': false, 'reason': data!.reason}));
      var dataRes = response.data;
      if (dataRes["success"]) {
        Navigator.of(context, rootNavigator: true).pop("Discard");
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
            Center(
              child: Container(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.xmark_circle_fill, color: Colors.red),
                    SizedBox(height: 10),
                    Text(dataRes["message"] ?? "Duyệt thành công"),
                  ],
                )
              )
            )
          ])
        );
      } else {
        showModal(
          context: context,
          builder: (_) => SimpleDialog(
          children: <Widget>[
            Center(
              child: Container(
                child: Column(
                  children: [
                    Icon(CupertinoIcons.xmark_circle_fill, color: Colors.red),
                    SizedBox(height: 10),
                    Text(dataRes["message"] ?? "Duyệt không thành công"),
                  ],
                )
              )
            )
          ])
        );
      }
    } catch (e, trace) {
      print("Error Channel: $trace");
    }
  }
  @override
  Widget build(BuildContext context) {
    final auth = context.read<Auth>();
    final isDark = auth.theme == ThemeType.DARK;
    // final currentUser = context.read<User>().currentUser;
    // final wsMembers = context.read<Workspaces>().members;

    final submitButton = Container(
      decoration:  BoxDecoration(border: Border(top: BorderSide(width: 0.2, color: Colors.grey))),
      padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 120, height: 32,
            margin: EdgeInsets.only(right: 12),
            child: OutlinedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Palette.calendulaGold),
              ),
              onPressed: () => _onApprovedRequest(),
              child: Text(
                'Duyệt',
                style: TextStyle(color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),),
            ),
          ),
        ],
      ),
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0)
      ),
      title: Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xff5E5E5E).withOpacity(0.5) : Color(0xffF3F3F3),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(4.0),
            topLeft: Radius.circular(4.0)
          )
        ),
        child: Container(
          padding: const EdgeInsets.only(top: 9, bottom: 9, left: 16),
          child: Text("Duyệt công")
        ),
      ),
      titlePadding: const EdgeInsets.all(0),
      backgroundColor: isDark ? Palette.backgroundTheardDark : Colors.white,
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 600,
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nhân viên: ${widget.selectedUser["full_name"]}"),
                  SizedBox(height: 8),
                  Text("Ngày: ${widget.selectedDate.year}-${widget.selectedDate.month}-${widget.selectedDate.day}"),
                  SizedBox(height: 8),
                  Text("Lý do"),
                  SizedBox(height: 8),
                  TextFormField(
                    initialValue: data!.form!.reason,
                    readOnly: true,
                    maxLines: 4,
                    decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight),
                          borderRadius: const BorderRadius.all(Radius.circular(2))
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight),
                          borderRadius: const BorderRadius.all(Radius.circular(2))
                        ),
                      ),
                  ),
                ],
              ),
            ),
            submitButton
          ],
        ),
      ),
    );
  }
}