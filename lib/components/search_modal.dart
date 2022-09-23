import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/pagination.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/user_online.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/dropdown_overlay.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/providers/providers.dart';

extension _Unique<E, Id> on List<E> {
  List<E> _unique([Id Function(E element)? id, bool inplace = true]) {
    final ids = Set();
    var list = inplace ? this : List<E>.from(this);
    list.retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
    return list;
  }
}
class SearchModal extends StatefulWidget {
  SearchModal({ Key? key, this.contacts = const [], this.totalMessage = 0, this.channels = const [], this.messages = const [], required this.textSearch, required this.onSelect, this.onReloadSearch}) : super(key: key);
  // final List dataSearch;
  final List contacts;
  final List channels;
  final List messages;
  final String textSearch;
  final Function onSelect;
  final Function? onReloadSearch;
  final int totalMessage;

  @override
  State<SearchModal> createState() => SearchModalState();
}

class SearchModalState extends State<SearchModal> {
  int _searchType = 3;
  List _allContact = [];
  int totalMessage = 0;
  List _listChannel = [];
  List _contacts = [];
  List _channels = [];
  List messages = [];
  List userIds = [];
  List channelIds = [];
  Map? date;

  bool loading = false;
  DateTime? dateTime;
  DateTimeRange? dateRange;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _contacts = widget.contacts;
    _channels = widget.channels;
    messages = widget.messages;
    totalMessage = widget.totalMessage;

    _allContact = _getAllContact();
    _listChannel = _getListChannel();
  }

  _getAllContact() {
    final directmodels = Provider.of<DirectMessage>(context, listen: false).data;
    final currentUserId = Provider.of<User>(context, listen: false).currentUser["id"];
    return directmodels.map((e) {
      var users = e.user.length > 1
          ? e.user.where((item) => item["user_id"] != currentUserId).toList()
          : e.user;

      return {
        "user_id": users[0]["user_id"],
        "conversation_id": users[0]["conversation_id"],
        "name": e.displayName,
        "avatar_url": users[0]["avatar_url"] ?? "",
        "is_online": users[0]["is_online"],
        "members": users.length
      };
    }).toList();
  }
  _getListChannel() {
    return Provider.of<Channels>(context, listen: false).data;
  }

  _onSearchMessages() {
    setState(() {
      _searchType = 3;
    });
  }
  _onSearchChannels() {
    setState(() {
      _searchType = 2;
    });
  }
  _onSearchContacts() {
    setState(() {
      _searchType = 1;
    });
  }

  _usersInMessage() {
    if (_searchType != 3) return [];
    return widget.messages.map((e) {
      if (_isDirectMessage(e)) {
        var indexContact = _allContact.indexWhere((i) {
          return i["conversation_id"] == e["conversation_id"];
        });
        if (indexContact == -1) return null;
        return _allContact[indexContact];
      }
      else if (_isChannelMessage(e)) {
        return {
          "user_id": e["_source"]["user_id"],
          "avatar_url": e["_source"]["avatar_url"],
          "name": e["_source"]["full_name"]
        };
      }
      return null;
    }).where((element) => element != null).toList()._unique((x) => x["user_id"]);
  }

  _channelsInMessage() {
    if (_searchType != 3) return [];
    return widget.messages.map((e) {
      if (e["_source"] == null) return null;
      final indexChannel = _listChannel.indexWhere((element) => element["id"] == e["_source"]["channel_id"]);
      if (indexChannel == -1) return null;
      return _listChannel[indexChannel];
    })
    .where((element) => element != null).toList()._unique((x) => x["id"]);
  }

  bool _isDirectMessage(message) => message["time_create"] != null;
  bool _isChannelMessage(message) => message["_source"] != null;

  _selectDate(BuildContext context, type, title) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final label = DateFormatter().renderTime(picked, type: "MMMd", timeZone: 0);
      this.setState(() {
        date = {
          "type": type,
          "label": "$title $label",
          "day": picked.toIso8601String()
        };
      });
    }

    Navigator.of(context, rootNavigator: true).pop("Discard");
  }

  _selectDateRange(BuildContext context, locale) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022, 1, 1),
      lastDate: DateTime(2030, 1, 31),
      currentDate: DateTime.now(),
      builder: (context, child) {
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: Container(
                height: 450,
                width: 700,
                child: child,
              ),
            ),
          ],
        );
      },
    );

    if (picked != null && picked != dateRange) {
      final labelStart = DateFormatter().renderTime(picked.start, type: "MMMd", timeZone: 0);
      final labelEnd = DateFormatter().renderTime(picked.end, type: "MMMd", timeZone: 0);
      this.setState(() {
        date = {
          "type": "range",
          "label": "$labelStart - $labelEnd",
          "start_date": picked.start.toIso8601String(),
          "end_date": picked.end.toIso8601String()
        };
      });
    }

    Navigator.of(context, rootNavigator: true).pop("Discard");
  }

  selectFilter(key, title) {
    DateTime time = new DateTime.now();
    DateTime fromTime;
    switch (key) {
      case "today":
        fromTime = new DateTime(time.year, time.month, time.day);
        break;
      case "yesterday":
        fromTime = new DateTime(time.year, time.month, time.day - 1);
        break;
      case "last_7_days":
        fromTime = new DateTime(time.year, time.month, time.day - 7);
        break;
      case "last_30_days":
        fromTime = new DateTime(time.year, time.month, time.day - 30);
        break;
      case "last_3_months":
        fromTime = new DateTime(time.year, time.month - 3, time.day);
        break;
      case "last_12_months":
        fromTime = new DateTime(time.year, time.month - 12, time.day);
        break;
      default:
        fromTime = time;
        break;
    }

    this.setState(() {
      date = {"type": key, "label": title, "day": fromTime.toIso8601String()};
    });
  }

  TextButton renderDate(isDark, title, key) {
    return TextButton(
      style: ButtonStyle(
        overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
        padding: MaterialStateProperty.all(EdgeInsets.zero)
      ),
      onPressed: () {
        selectFilter(key, title);
        Navigator.of(context, rootNavigator: true).pop("Discard");
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)),
        ),
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Container(
              margin: EdgeInsets.only(right: 5),
              child: (date != null && date!["type"] == key)
                  ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                  : Container(width: 16, height: 16)
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List _dataSearchForType = this._dataSearchForType(_searchType);
    final isDark = Provider.of<Auth>(context).theme == ThemeType.DARK;
    final locale = Provider.of<Auth>(context, listen: false).locale;
    final tab = Provider.of<Workspaces>(context).tab;

    Widget _searchHeader = Stack(
      children: [
        Row(
          children: [
            _searchTypeButton(3,
              onTap: _onSearchMessages,
              text: "Message",
            ),
            SizedBox(width: 10),
            _searchTypeButton(1,
              onTap: _onSearchContacts,
              text: "Contacts",
            ),
            SizedBox(width: 10),
            _searchTypeButton(2,
              onTap: _onSearchChannels,
              text: "Channels",
            )
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Divider(height: 2, thickness: 2,),
        )
      ],
    );

    Widget _searchFilter = Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 12.0),
      child: Row(
        children: [
          DropdownOverlay(
            isAnimated: true,
            menuDirection: MenuDirection.end,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: !isDark ? Color(0xff2E2E2E) : Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(4),
                color: userIds.length >= 1
                  ? Palette.buttonColor
                  : isDark ? Color(0xff2E2E2E) : Colors.white.withOpacity(0.2)
              ),
              margin: EdgeInsets.symmetric(horizontal: 3),
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: MouseRegion(
                child: Row(children: [
                  Text(userIds.length > 1 ? "From ${userIds.length} teammates" : userIds.length == 1 ? "From ${userIds.length} teammate" : "From", style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black)),
                  Icon(Icons.arrow_drop_down)]),
                cursor: SystemMouseCursors.click
              ),
            ),
            onPop: () async {
              widget.onReloadSearch?.call(this, false, /*_currentOffset*/ 0, userIds, channelIds, date);
            },
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
                        TextButton(
                          style: ButtonStyle(
                            overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                            padding: MaterialStateProperty.all(EdgeInsets.zero)
                          ),
                          onPressed: () {
                            List uIds = List.from(userIds);
                            if (uIds.length > 0) uIds = [];
                            // else _usersInMessage().forEach((element) => uIds.add(element["id"]));
                            setState(() => userIds = uIds);
                            this.setState(() => userIds);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)),
                            ),
                            padding: EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Remove selected",
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  margin: EdgeInsets.only(right: 5),
                                  child: Container(width: 16, height: 16)
                                  // child: Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                ),
                              ],
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _usersInMessage().length,
                          itemBuilder: (BuildContext context, int index) {
                            final item = _usersInMessage()[index];
                            final isGroup = item["members"] != null && item["members"] > 2;

                            return TextButton(
                              style: ButtonStyle(
                                overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                                padding: MaterialStateProperty.all(EdgeInsets.zero)
                              ),
                              onPressed: () {
                                final idx = userIds.indexWhere((e) => e == item["user_id"]);
                                List approverIds = List.from(userIds);
                                if (idx != -1) approverIds.removeAt(idx);
                                else approverIds.add(item["user_id"]);
                                setState(() => userIds = approverIds);
                                this.setState(() => userIds);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: index != _usersInMessage().length -1 ? Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)) : null,
                                ),
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        isGroup
                                          ? Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: Color(((index + 1) * pi * 0.1 * 0xFFFFFF).toInt()).withOpacity(1.0),
                                                borderRadius: BorderRadius.circular(16)
                                              ),
                                              child: Icon(
                                                Icons.group,
                                                size: 16,
                                                color: Colors.white
                                              ),
                                            )
                                          : CachedAvatar(
                                              item["avatar_url"] ?? "",
                                              name: item["name"],
                                              width: 28,
                                              height: 28
                                            ),
                                        SizedBox(width: 10),
                                        Text(
                                          item["name"],
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
                                        child: userIds.contains(item["user_id"])
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
            ),
          ),
          if (tab != 0) DropdownOverlay(
            isAnimated: true,
            menuDirection: MenuDirection.end,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: !isDark ? Color(0xff2E2E2E) : Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(4),
                color: channelIds.length >= 1
                  ? Palette.buttonColor
                  : isDark ? Color(0xff2E2E2E) : Colors.white.withOpacity(0.2)
              ),
              margin: EdgeInsets.symmetric(horizontal: 3),
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: MouseRegion(
                child: Row(children: [
                  Text(channelIds.length > 1 ? "In ${channelIds.length} places" : channelIds.length == 1 ? "In ${channelIds.length} place" : "In", style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black)),
                  Icon(Icons.arrow_drop_down)]),
                cursor: SystemMouseCursors.click
              ),
            ),
            onPop: () async {
              widget.onReloadSearch?.call(this, false, /*_currentOffset*/ 0, userIds, channelIds, date);
            },
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
                        TextButton(
                          style: ButtonStyle(
                            overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                            padding: MaterialStateProperty.all(EdgeInsets.zero)
                          ),
                          onPressed: () {
                            List cIds = List.from(channelIds);
                            if (cIds.length > 0) cIds = [];
                            // else _channelsInMessage().forEach((element) => cIds.add(element["id"]));
                            setState(() => channelIds = cIds);
                            this.setState(() => channelIds);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)),
                            ),
                            padding: EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Remove selected",
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  margin: EdgeInsets.only(right: 5),
                                  child: Container(width: 16, height: 16)
                                  // child: Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                ),
                              ],
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _channelsInMessage().length,
                          itemBuilder: (BuildContext context, int index) {
                            final item = _channelsInMessage()[index];

                            return TextButton(
                              style: ButtonStyle(
                                overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                                padding: MaterialStateProperty.all(EdgeInsets.zero)
                              ),
                              onPressed: () {
                                final idx = channelIds.indexWhere((e) => e == item["id"]);
                                List cIds = List.from(channelIds);
                                if (idx != -1) cIds.removeAt(idx);
                                else cIds.add(item["id"]);
                                setState(() => channelIds = cIds);
                                this.setState(() => channelIds);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: index != _channelsInMessage().length -1 ? Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)) : null,
                                ),
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        item["is_private"]
                                          ? SvgPicture.asset('assets/icons/Locked.svg',
                                              color: isDark
                                                  ? Palette.defaultTextDark
                                                  : Palette.defaultTextLight)
                                          : SvgPicture.asset('assets/icons/iconNumber.svg',
                                              width: 13,
                                              color: isDark
                                                  ? Palette.defaultTextDark
                                                  : Palette.defaultTextLight),
                                        SizedBox(width: 10),
                                        Text(
                                          item["name"],
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
                                        child: channelIds.contains(item["id"])
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
            ),
          ),
          if (tab != 0) DropdownOverlay(
            isAnimated: true,
            menuDirection: MenuDirection.end,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: !isDark ? Color(0xff2E2E2E) : Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(4),
                color: date != null
                    ? Palette.buttonColor
                    : isDark ? Color(0xff2E2E2E) : Colors.white.withOpacity(0.2)
              ),
              margin: EdgeInsets.symmetric(horizontal: 3),
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: MouseRegion(
                child: Row(children: [
                  Text(
                    date?["label"] ?? "Date", style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black)),
                  Icon(Icons.arrow_drop_down)]),
                cursor: SystemMouseCursors.click
              ),
            ),
            onPop: () async {
              widget.onReloadSearch?.call(this, false, /*_currentOffset*/ 0, userIds, channelIds, date);
            },
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
                        TextButton(
                          style: ButtonStyle(
                            overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                            padding: MaterialStateProperty.all(EdgeInsets.zero)
                          ),
                          onPressed: () {
                            setState(() => date = null);
                            Navigator.of(context, rootNavigator: true).pop("Discard");
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)),
                            ),
                            padding: EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Any day",
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  margin: EdgeInsets.only(right: 5),
                                  child: Container(width: 16, height: 16)
                                  // child: Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                ),
                              ],
                            ),
                          ),
                        ),
                        renderDate(isDark, "Today", "today"),
                        renderDate(isDark, "Yesterday", "yesterday"),
                        renderDate(isDark, "Last 7 days", "last_7_days"),
                        renderDate(isDark, "Last 30 days", "last_30_days"),
                        renderDate(isDark, "Last 3 months", "last_3_months"),
                        renderDate(isDark, "Last 12 months", "last_12_months"),
                        TextButton(
                          style: ButtonStyle(
                            overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                            padding: MaterialStateProperty.all(EdgeInsets.zero)
                          ),
                          onPressed: () {
                            _selectDate(context, "on", "On");
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)),
                            ),
                            padding: EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "On...",
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  margin: EdgeInsets.only(right: 5),
                                  child: (date != null && date!["type"] == "on")
                                      ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                      : Container(width: 16, height: 16)
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          style: ButtonStyle(
                            overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                            padding: MaterialStateProperty.all(EdgeInsets.zero)
                          ),
                          onPressed: () {
                            _selectDate(context, "before", "Before");
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)),
                            ),
                            padding: EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Before...",
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  margin: EdgeInsets.only(right: 5),
                                  child: (date != null && date!["type"] == "before")
                                      ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                      : Container(width: 16, height: 16)
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          style: ButtonStyle(
                            overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                            padding: MaterialStateProperty.all(EdgeInsets.zero)
                          ),
                          onPressed: () {
                            _selectDate(context, "after", "After");
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)),
                            ),
                            padding: EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "After...",
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  margin: EdgeInsets.only(right: 5),
                                  child: (date != null && date!["type"] == "after")
                                      ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                      : Container(width: 16, height: 16)
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          style: ButtonStyle(
                            overlayColor: MaterialStateProperty.all(isDark ? Palette.selectChannelColor : Color(0xffF3F3F3)),
                            padding: MaterialStateProperty.all(EdgeInsets.zero)
                          ),
                          onPressed: () {
                            _selectDateRange(context, locale);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: isDark ? Palette.borderSideColorDark : Palette.borderSideColorLight)),
                            ),
                            padding: EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Range...",
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Color.fromRGBO(0, 0, 0, 065)
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  margin: EdgeInsets.only(right: 5),
                                  child: (date != null && date!["type"] == "range")
                                      ? Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 16, color: Palette.buttonColor)
                                      : Container(width: 16, height: 16)
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                );
              }),
            ),
          ),
        ],
      ),
    );

    Widget _searchResult = ListView.builder(
      // controller: _controller,
      itemCount: _dataSearchForType.length,
      itemBuilder: (context, index) {
        Widget _renderContact = _searchType == 1 ? SearchContactItem(
          showAction: true,
          contact: _dataSearchForType[index],
          onSelectContact: (contact) {
            widget.onSelect(1, contact);
          },
        ) : Container();
        Widget _renderMessage = _searchType == 3 ? SearchMessageItem(
          isDirectMessage: _dataSearchForType[index]["time_create"] != null,
          isChannelMessage: _dataSearchForType[index]["_source"] != null,
          message: _dataSearchForType[index],
          allContact: _allContact,
          listChannel: _listChannel,
          onSelectMessage: (message, isDirectMessage, isChannelMessage) {
            widget.onSelect(3, {
              "message": message,
              "isDirectMessage": isDirectMessage,
              "isChannelMessage": isChannelMessage
            });
          }
        ) : Container();
        Widget _renderChannel = _searchType == 2 ? SearchChannelItem(
          channel: _dataSearchForType[index],
          onSelectChannel: (channelId, workspaceId) {
            widget.onSelect(2, {
              "channelId": channelId,
              "workspaceId": workspaceId
            });
          },
        ) : Container();

        return Padding(
          padding: EdgeInsets.all(2),
          child: _searchType == 1 ? _renderContact
          : _searchType == 2 ? _renderChannel
          : _searchType == 3 ? _renderMessage
          : Container(),
        );
      }
    );

    return AlertDialog(
      content: SizedBox(
        width: 3 / 4 * MediaQuery.of(context).size.width,
        child: Column(
          children: [
            _searchHeader,
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 12.0),
                    child: Text("Search results for \"${widget.textSearch}\""),
                  )
                ),
                if (_searchType == 3) _searchFilter
              ],
            ),
            Expanded(child: _searchResult),
            SizedBox(height: 10),
            if (_searchType == 3 && totalMessage > 50) NumberPagination(
              onPageChanged: (int pageNumber) {
                setState(() {
                  currentPage = pageNumber;
                });
                widget.onReloadSearch?.call(this, false, 50 * (pageNumber - 1), userIds, channelIds, date);
              },
              threshold: (totalMessage/50).ceil() >= 5 ? 5 : (totalMessage/50).ceil(),
              pageTotal: totalMessage,
              pageInit: currentPage,
              colorPrimary: isDark ? Palette.calendulaGold : Palette.dayBlue,
              colorSub: Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchTypeButton(type, {onTap, text}) {
    final lengthData = this._dataSearchForType(type).length;
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return InkWell(
      onTap: onTap,
      child: Ink(
        child: Container(
          decoration: BoxDecoration(
            border: type == _searchType ? Border(bottom: BorderSide(width: 2.0, color: isDark ? Palette.calendulaGold : Palette.dayBlue)) : null
          ),
          alignment: Alignment.center,
          height: 30,
          width: 100,
          child: Text("$text ${Utils.formatNumber(type != 3 ? lengthData : totalMessage)}", style: TextStyle(color: _searchType == type ? isDark ? Colors.white : Colors.black : Colors.grey, fontSize: 14)),
        ),
      ),
    );
  }

  // _currentMessageOffsetWithId(userIds, channelIds) async {
  //   final token = Provider.of<Auth>(context, listen: false).token;
  //   final result = await widget.searchApi!(token, widget.textSearch, false, 0, userIds, channelIds);
  //   if (mounted) setState(() => messages = result);
  //   return messages.length;
  // }

  _dataSearchForType(type) {
    return type == 1 ? _contacts : type == 2 ? _channels : type == 3 ? messages : [];
  }
}

class SearchMessageItem extends StatelessWidget {
  SearchMessageItem({ Key? key, this.isDirectMessage = false, this.isChannelMessage = false, required this.message, required this.onSelectMessage, this.allContact, this.listChannel}) : super(key: key);
  final bool isDirectMessage;
  final bool isChannelMessage;
  final Map message;
  final allContact;
  final listChannel;
  final Function onSelectMessage;

  List<TextSpan> buildTextSpanWidgets(text, isDark) {
    const String _ALLCHARACTERS =
    r"[\s\wÀÂÆÇÉÈÊËÎÏÔŒÙÛÜŸÿüûùœôïîëêèéçæâà«»€$£¥@&()\-=~#{}\[\]|`\\^°+/²,;:!?§.¨¤*µ%']*";
    List<TextSpan> spans = [];
    int previous = 0;

    int count = 0;

    RegExp regex = RegExp("<em>" + _ALLCHARACTERS + "</em>");

    String regText = Utils.unSignVietnamese(text);

    Iterable matches = regex.allMatches(regText);
    int numberOfMatches = matches.length;

    matches.forEach((dynamic match) {
      String normalText = text.substring(previous, match.start);
      String toHighlight = text.substring(match.start, match.end);
      previous = match.end;

      spans.add(TextSpan(
        text: normalText
            .replaceAll("<em>", "")
            .replaceAll("</em>", ""),
        style: TextStyle(
          color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight
        ),
      ));

      spans.add(TextSpan(
        text: toHighlight
            .replaceAll("<em>", "")
            .replaceAll("</em>", ""),
        style: TextStyle(
          color: isDark ? Palette.calendulaGold : Palette.dayBlue,
        ),
      ));

      count++;

      if (count == numberOfMatches) {
        spans.add(TextSpan(
          text: text.substring(match.end),
          style: TextStyle(
            color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight
          ),
        ));
      }
    });

    return spans;
  }

  renderAttachmentsMessage(attachments, isDark) {
    return RichText(
        text: TextSpan(
            children: attachments[0]["data"].map<TextSpan>((item) {
              if (item["type"] == "text" &&
                  Utils.checkedTypeEmpty(item["value"])) {
                return _renderText(item["value"], isDark);
              } else if (item["type"] == "text") {
                return TextSpan(text: item["value"]);
              } else if (item["name"] == "all" || item["type"] == "all") {
                return TextSpan(
                    text: "@all ",
                    style: TextStyle(
                        color:
                            isDark ? Palette.calendulaGold : Palette.dayBlue));
              } else if (item["type"] == "user") {
                return TextSpan(
                      text: "@${item["name"]} ",
                      style: TextStyle(
                          color: isDark
                              ? Palette.calendulaGold
                              : Palette.dayBlue));
              } else {
                return const TextSpan();
              }
            }).toList(),
            style: const TextStyle(fontSize: 13)));
  }
  TextSpan _renderText(string, isDark) {
    RegExp exp = RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
    List list = string.trim().split(" ");

    return TextSpan(
        children: list.map<TextSpan>((e) {
      Iterable<RegExpMatch> matches = exp.allMatches(e);
      if (matches.isNotEmpty) {
        return TextSpan(
            text: "$e ",
            style: const TextStyle(
                color: Colors.blue, decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                if (await canLaunch(e)) {
                  await launch(e);
                } else {
                  throw 'Could not launch $e';
                }
              });
      } else {
        return TextSpan(
            text: "$e ",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87));
      }
    }).toList());
  }

  renderTime(time) {
    final messageTime = DateFormat('kk:mm').format(DateTime.parse(time).add(const Duration(hours: 7)));
    final checked = DateTime.parse(time).year == DateTime.now().year;

    final messageLastTime = "${DateFormatter().renderTime(DateTime.parse(time), type: checked ? "MMMd" : "yMMMd")}";

    return {
      "messageTime": messageTime,
      "messageLastTime": messageLastTime
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final currentUser = Provider.of<User>(context).currentUser;
    Widget _userOrGroupIcon(isGroup, name, avatarUrl, isOnline) {
      return isGroup
        ? Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Color(((0 + 1) * pi * 0.1 * 0xFFFFFF).toInt()).withOpacity(1.0),
              borderRadius: BorderRadius.circular(16)
            ),
            child: Icon(
              Icons.group,
              size: 16,
              color: Colors.white
            ),
          )
        : UserOnline(
            name: name,
            avatarUrl: avatarUrl,
            isOnline: isOnline,
          );
    }
    if (isDirectMessage) {
      var indexContact = allContact.indexWhere((i) {
        return i["conversation_id"] == message["conversation_id"];
      });

      if (indexContact == -1) return Container();
      final isUser = allContact[indexContact]["members"] < 2;
      final isMention = (message["attachments"].length > 0 &&
          message["attachments"][0]["type"] == "mention");

      Widget _message = Row(
        children: [
          message["user_id"] == currentUser["id"]
              ? Icon(Icons.subdirectory_arrow_right,
                  size: 14,
                  color: isDark
                      ? Colors.white.withOpacity(0.85)
                      : Colors.black.withOpacity(0.85))
              : Container(),
          Expanded(child: isMention
              ? renderAttachmentsMessage(message["attachments"], isDark)
              : Text(message["message"],
                  style: TextStyle(
                    color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
                  ),
                  overflow: TextOverflow.ellipsis))
        ],
      );

      return TextButton(
        style: ButtonStyle(
          overlayColor: MaterialStateProperty.all(Colors.transparent),
        ),
        onPressed: () => onSelectMessage(message, isDirectMessage, isChannelMessage),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
            borderRadius: BorderRadius.all(Radius.circular(8))
          ),
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.only(bottom: 5),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(left: 5),
                child: Row(children: [
                  Text(allContact[indexContact]["name"],
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Palette.defaultTextDark.withOpacity(0.65)
                            : Palette.defaultTextLight.withOpacity(0.65),
                        fontWeight: FontWeight.w500)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(renderTime(message["time_create"])["messageLastTime"],
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? Palette.defaultTextDark.withOpacity(0.65)
                                : Palette.defaultTextLight.withOpacity(0.65)))),
                ])
              ),
              SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _userOrGroupIcon(
                    !isUser,
                    allContact[indexContact]["name"],
                    allContact[indexContact]["avatar_url"],
                    allContact[indexContact]["is_online"]),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              allContact[indexContact]["name"],
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white : const Color(0xFF1F2933),
                                fontWeight: FontWeight.w500
                              )
                            ),
                            SizedBox(width: 6,),
                            Text(renderTime(message["time_create"])["messageTime"],
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w400,
                                color: isDark
                                    ? Palette.defaultTextDark.withOpacity(0.65)
                                    : Palette.defaultTextLight.withOpacity(0.65)))
                          ]
                        ),
                        SizedBox(height: 1),
                        _message
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    if (isChannelMessage) {
      final lastReply = message["_source"]['inserted_at'];
      final channel = listChannel
          .where((element) =>
              element["id"] == message["_source"]["channel_id"])
          .toList()
          .first;
      final stringMessage = message["highlight"]["message_parse"].first;

      Widget _channelName = Row(children: [
        channel["is_private"]
            ? SvgPicture.asset('assets/icons/Locked.svg',
                width: 10,
                color: isDark
                    ? Palette.defaultTextDark
                    : Palette.defaultTextLight)
            : SvgPicture.asset('assets/icons/iconNumber.svg',
                width: 10,
                color: isDark
                    ? Palette.defaultTextDark.withOpacity(0.65)
                    : Palette.defaultTextLight.withOpacity(0.65)),
        SizedBox(width: 4,),
        Text(channel["name"],
            style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Palette.defaultTextDark.withOpacity(0.65)
                    : Palette.defaultTextLight.withOpacity(0.65),
                fontWeight: FontWeight.w500))
      ]);

      List<TextSpan> spans = buildTextSpanWidgets(stringMessage, isDark);
      Widget _message = RichText(
        // textAlign: widget.textAlign,
        text: TextSpan(
          children: spans,
        ),
      );

      Widget _lastTime = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(renderTime(lastReply)["messageLastTime"],
            style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? Palette.defaultTextDark.withOpacity(0.65)
                    : Palette.defaultTextLight.withOpacity(0.65))),
      );

      Widget _inThread = message["_source"]['channel_thread_id'] != null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(S.current.inThread,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w300, color:Color.fromARGB(255, 160, 158, 158)
                    )
                  )
                )
              : Container();

      return TextButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
          overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
        ),
        onPressed: () => onSelectMessage(message, isDirectMessage, isChannelMessage),
        child: Container(
          decoration: BoxDecoration(
            // color: isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
            borderRadius: BorderRadius.all(Radius.circular(8))
          ),
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.only(bottom: 5),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(left: 5),
                child: Row(children: [_channelName, _lastTime])
              ),
              SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserOnline(
                    name: message["_source"]["full_name"],
                    avatarUrl: message["_source"]["avatar_url"],
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              message["_source"]["full_name"],
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white : const Color(0xFF1F2933),
                                fontWeight: FontWeight.w500
                              )
                            ),
                            SizedBox(width: 6,),
                            Text(renderTime(lastReply)["messageTime"],
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w400,
                                color: isDark
                                    ? Palette.defaultTextDark.withOpacity(0.65)
                                    : Palette.defaultTextLight.withOpacity(0.65)))
                          ]
                        ),
                        SizedBox(height: 1),
                        _message
                      ],
                    ),
                  ),
                  _inThread
                ],
              ),
            ],
          ),
        ),
      );
    }
    return Container();
  }
}

class SearchChannelItem extends StatelessWidget {
  SearchChannelItem({ Key? key, this.channel, this.onSelectChannel }) : super(key: key);
  final channel;
  final onSelectChannel;


  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;

    return TextButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.transparent),
        overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
      ),
      onPressed: () => onSelectChannel(channel["id"], channel["workspace_id"]),
      child: Container(
        decoration: BoxDecoration(
          // color: isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
          borderRadius: BorderRadius.all(Radius.circular(8))
        ),
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            channel["is_private"]
                ? SvgPicture.asset('assets/icons/Locked.svg',
                    color: isDark
                        ? Palette.defaultTextDark
                        : Palette.defaultTextLight)
                : SvgPicture.asset('assets/icons/iconNumber.svg',
                    width: 13,
                    color: isDark
                        ? Palette.defaultTextDark
                        : Palette.defaultTextLight),
            SizedBox(width: 10),
            Text(
                "${channel["name"]} ${channel["is_archived"] == true ? "(archived)" : ""}",
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1F2933),
                  fontWeight: FontWeight.w500
                ),
                overflow: TextOverflow.ellipsis
              )
          ],
        ),
      ),
    );
  }
}

class SearchContactItem extends StatefulWidget {
  const SearchContactItem({ Key? key, this.contact, this.onSelectContact, this.showAction = false }) : super(key: key);
  final contact;
  final onSelectContact;
  final showAction;

  @override
  State<SearchContactItem> createState() => _SearchContactItemState();
}

class _SearchContactItemState extends State<SearchContactItem> {

  bool _hover = false;

  Widget _userOrGroupIcon(isGroup, name, avatarUrl, isOnline) {
    Random random = new Random();
    int randomNumber = random.nextInt(10);
    return isGroup
        ? Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Color(((randomNumber + 1) * pi * 0.1 * 0xFFFFFF).toInt()).withOpacity(1.0),
              borderRadius: BorderRadius.circular(16)
            ),
            child: Icon(
              Icons.group,
              size: 16,
              color: Colors.white
            ),
          )
        : UserOnline(
            name: name,
            avatarUrl: avatarUrl,
            isOnline: isOnline);
  }

  _inFriendList() {
    final friendList = Provider.of<User>(context, listen: true).friendList;
    final index = friendList.indexWhere((friend) => friend["id"] == (widget.contact["user_id"] ?? widget.contact["id"]));

    if (index != -1){
      return true;
    }
    return false;
  }

  _inPendingList() {
    final pendingList = Provider.of<User>(context, listen: true).pendingList;
    final index = pendingList.indexWhere((friend) => friend["id"] == (widget.contact["user_id"] ?? widget.contact["id"]));

    if (index != -1){
      return true;
    }
    return false;
  }

  _inSendingList() {
    final sendingList = Provider.of<User>(context, listen: true).sendingList;
    final index = sendingList.indexWhere((friend) => friend["id"] == (widget.contact["user_id"] ?? widget.contact["id"]));

    if (index != -1){
      return true;
    }
    return false;
  }

  Widget get _unFriendButton => Container();
  Widget get _cancelFriendButton => OutlinedButton(
    onPressed: () async {
      final token = Provider.of<Auth>(context, listen: false).token;
      await Provider.of<User>(context, listen: false).removeRequest(token, widget.contact["user_id"] ?? widget.contact["id"]);
    },
    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.grey)),
    child: SizedBox(
      width: 80,
      child: Row(
        children: [
          Icon(
            CupertinoIcons.arrow_counterclockwise_circle_fill,
            color: Colors.white,
          ),
          Text("   Cancel", style: TextStyle(color: Colors.white))
        ],
      ),
    ),
  );
  Widget get _acceptFriendButton => OutlinedButton(
    onPressed: () async {
      final token = Provider.of<Auth>(context, listen: false).token;
      await Provider.of<User>(context, listen: false).acceptRequest(token, widget.contact["user_id"] ?? widget.contact["id"]);
    },
    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.grey)),
    child: SizedBox(
      width: 80,
      child: Row(
        children: [
          Icon(
            CupertinoIcons.check_mark_circled_solid,
            color: Colors.white,
            size: 17,
          ),
          Text("   Accept", style: TextStyle(color: Colors.white))
        ],
      ),
    ),
  );
  Widget get _sendFriendRequestButton => OutlinedButton(
    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.grey)),
    onPressed: () async {
      final token = Provider.of<Auth>(context, listen: false).token;
      await Provider.of<User>(context, listen: false).addFriendRequest( widget.contact["user_id"] ?? widget.contact["id"], token);
    },
    child: SizedBox(
      width: 100,
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/AddMember.svg',width: 15, height: 15, color: Colors.white,),
          Text("  Add Friend", style: TextStyle(color: Colors.white))
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final name = widget.contact["name"] ?? widget.contact["full_name"] ?? "Error name";
    final avatarUrl = widget.contact["avatar_url"];
    final isOnline = widget.contact["is_online"] ?? false;
    final isGroup = !((widget.contact["members"] ?? 1) < 2);

    return TextButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.transparent),
        overlayColor: MaterialStateProperty.all(isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15)),
      ),
      onPressed: () => widget.onSelectContact(widget.contact),
      onHover: (value) => setState(() => _hover = value),
      child: Container(
        decoration: BoxDecoration(
          // color: isDark ? Palette.hoverColorDefault : Color.fromARGB(255, 166, 164, 164).withOpacity(0.15),
          borderRadius: BorderRadius.all(Radius.circular(8))
        ),
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            _userOrGroupIcon(isGroup, name, avatarUrl, isOnline),
            SizedBox(width: 10),
            Text(
              name,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1F2933),
                fontWeight: FontWeight.w500
              ),
              overflow: TextOverflow.ellipsis
            ),
            Expanded(
              child: widget.showAction && _hover ? Align(
                alignment: Alignment.centerRight,
                child: _inFriendList() ? _unFriendButton
                      : _inSendingList() ? _cancelFriendButton
                      : _inPendingList() ? _acceptFriendButton 
                      : _sendFriendRequestButton,
              ) : Container(),
            )
          ],
        ),
      ),
    );
  }
}