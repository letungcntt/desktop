import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:popover/popover.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';

import '../../providers/providers.dart';

class BoardFilter extends StatefulWidget {
  const BoardFilter({
    Key? key,
    required this.filters,
    required this.filterType,
    required this.onChangeFilterType,
    this.onChangeFilter
  }) : super(key: key);

  final Map filters;
  final onChangeFilter;
  final filterType;
  final onChangeFilterType;

  @override
  State<BoardFilter> createState() => _BoardFilterState();
}

class _BoardFilterState extends State<BoardFilter> {
  bool onFocus = false;
  bool noMember = false;
  List members = [];
  int? priority;
  List labels = [];
  Timer? debounce;
  DateTime? afterDate;
  TextEditingController textSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.filters["text"].trim() != "") {
      textSearchController.text = widget.filters["text"].trim();
    }
  }

  onChangeFilter(key, value) {
    switch (key) {
      case "text":
        widget.filters["text"] = value.toLowerCase();
        break;

      case "noMember":
        noMember = !noMember;
        widget.filters["noMember"] = noMember;
        break;

      case "member":
        final index = members.indexWhere((e) => e == value);
        if (index == -1) {
          members.add(value);
        } else {
          members.removeAt(index);
        }
        widget.filters["members"] = members;
        break;

      case "label":
        final index = labels.indexWhere((e) => e == value);
        if (index == -1) {
          labels.add(value);
        } else {
          labels.removeAt(index);
        }
        widget.filters["labels"] = labels;
        break;

      case "priority":
        priority = priority == value ? null : value;
        widget.filters["priority"] = priority;
        break;

      case "dueDate":
        widget.filters["dueDate"] = value;
        break;

      default:
        break;
      }
    widget.onChangeFilter(widget.filters);
  }

  onChangefilterType(value) {
    widget.onChangeFilterType(value);
    Navigator.pop(context);
  }

  checkIsSearching() {
    Map filters = widget.filters;
    if (filters["noMember"] == false && filters["members"].isEmpty 
        && filters["labels"].isEmpty && filters["priority"] == null 
        && filters["text"].trim() == "" && filters["dueDate"].isEmpty
    ) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;
    final currentUser = Provider.of<User>(context, listen: true).currentUser;
    double popoverHeight = MediaQuery.of(context).size.height - 100 > 1040 ? 1040 :  MediaQuery.of(context).size.height - 100;

    return InkWell(
      onTap: () {
        this.setState(() {
          onFocus = true;
        });
        showPopover(
          backgroundColor: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
          context: context,
          transitionDuration: const Duration(milliseconds: 50),
          direction: PopoverDirection.bottom,
          barrierColor: Colors.transparent,
          arrowHeight: 0,
          arrowWidth: 0,
          radius: 4,
          height: popoverHeight,
          width: 360,
          bodyBuilder: (context) => StatefulBuilder(
            builder: (context, setState) {
              return Container(
                width: 360,
                decoration: BoxDecoration(
                  color: isDark ? Color(0xff4c4c4) : Color(0xffF8F8F8),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isDark ? Color(0xff828282) : Color(0xffDBDBDB))
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        color: isDark ? Color(0xff4c4c4) : Color(0xffF8F8F8),
                        padding: EdgeInsets.symmetric(horizontal: 18),
                        height: 48,
                        child: Row(
                          children: [
                            Expanded(child: Center(child: Text("Search card", style: TextStyle(color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E), fontSize: 16, fontWeight: FontWeight.w500)))),
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Icon(PhosphorIcons.x, size: 18, color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E))
                            )
                          ]
                        )
                      ),
                      Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1, thickness: 1),
                      Container(
                        color: isDark ? null : Color(0xffF8F8F8),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                        child: Container(
                          height: 44,
                          child: CupertinoTextField(
                            controller: textSearchController,
                            onChanged: (value) {
                              if (debounce?.isActive ?? false) debounce?.cancel();
                              debounce = Timer(const Duration(milliseconds: 300), () {
                                onChangeFilter("text", value);
                              });
                            },
                            prefix: Container(margin: EdgeInsets.only(left: 8), child: Icon(PhosphorIcons.magnifyingGlass, color: Color(0xffA6A6A6), size: 17)),
                            padding: EdgeInsets.only(left: 8, bottom: 2, right: 10),
                            decoration: BoxDecoration(
                              color: isDark ? Color(0xff444444) : Color(0xffF8F8F8),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isDark ? Color(0xff828282) : Color(0xffDBDBDB))
                            ),
                            style: TextStyle(fontSize: 14, color: Color(0xffA6A6A6)),
                            placeholder: "Search by card title or description",
                            placeholderStyle: TextStyle(fontSize: 14, color: Color(0xffA6A6A6))
                          )
                        )
                      ),
                      Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1, thickness: 1),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              alignment: Alignment.centerLeft,
                              height: 44,
                              child: Text("Members:", style: TextStyle(color: isDark ? null : Color(0xff5E5E5E)))
                            ),
                            // Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1, thickness: 1),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  onChangeFilter("noMember", false);
                                });
                              },
                              child: Container(
                                height: 44,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                                            borderRadius: BorderRadius.circular(24)
                                          ),
                                          child: Icon(PhosphorIcons.user, size: 16, color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E))
                                        ),
                                        SizedBox(width: 10),
                                        Text("No member", style: TextStyle(color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E)))
                                      ]
                                    ),
                                    if(noMember) Icon(PhosphorIcons.checkCircleThin, size: 18, color: Color(0xffFAAD14))
                                  ]
                                ),
                              )
                            ),
                            // Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1, thickness: 1),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  onChangeFilter("member", currentUser["id"]);
                                });
                              },
                              child: Container(
                                height: 44,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        CachedAvatar(currentUser["avatar_url"], name: currentUser["full_name"], width: 24, height: 24, radius: 24),
                                        SizedBox(width: 10),
                                        Text(currentUser["full_name"], style: TextStyle(color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E)))
                                      ]
                                    ),
                                    if(members.contains(currentUser["id"])) Icon(PhosphorIcons.checkCircleThin, size: 18, color: Color(0xffFAAD14))
                                  ]
                                )
                              )
                            ),
                            // Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1, thickness: 1),
                            FilterMember(onChangeFilter: onChangeFilter, members: members),
                            SizedBox(height: 4)
                          ]
                        )
                      ),
                      Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1, thickness: 1),
                      SizedBox(height: 12),
                      FilterPriority(
                        priority: priority,
                        onChangeFilter: (key, value) {
                          setState(() {
                            onChangeFilter(key, value);
                          });
                        }
                      ),
                      Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1, thickness: 1),
                      FilterDueDate(
                        onChangeFilter: (key, value) {
                          setState(() {
                            onChangeFilter(key, value);
                          });
                        },
                        filters: widget.filters
                      ),
                      Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1, thickness: 1),
                      SizedBox(height: 12),
                      FilterLabel(
                        onChangeFilter: (key, value) {
                          setState(() {
                            onChangeFilter(key, value);
                          });
                        },
                        labels: labels
                      ),
                      Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1, thickness: 1),
                      SelectfilterType(filterType: widget.filterType, onChangefilterType: onChangefilterType),
                      SizedBox(height: 10),
                    ]
                  )
                )
              );
            }
          )
        ).then((value) {
          this.setState(() {
            onFocus = false;
          });
        });
      },
      child:  Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
          borderRadius: BorderRadius.circular(4)
        ),
        child: Center(child: Icon(PhosphorIcons.magnifyingGlass, size: 17, color:  checkIsSearching() ? isDark ? Palette.calendulaGold : Color(0xff69C0FF) : null ))
      )
    );
  }
}

class FilterDueDate extends StatefulWidget {
  const FilterDueDate({
    Key? key,
    this.onChangeFilter,
    this.filters
  }) : super(key: key);

  final onChangeFilter;
  final filters;

  @override
  State<FilterDueDate> createState() => _FilterDueDateState();
}

class _FilterDueDateState extends State<FilterDueDate> {

  onChangeFilter(type) async {
    if (type == "noDueDate" || type == "overdue") {
      if (widget.filters["dueDate"]["type"] == type) {
        widget.filters["dueDate"].remove("type");
      } else {
        this.setState(() {
          widget.filters["dueDate"]["type"] = type;
        });
      }
    } else if (type == "before") {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: widget.filters["dueDate"]["after"] != null ? 
            DateTime.parse(widget.filters["dueDate"]["after"]).add(const Duration(days: 1)) : 
            widget.filters["dueDate"]["before"] ?? DateTime.now(),
        firstDate: widget.filters["dueDate"]["after"] != null ? 
            DateTime.parse(widget.filters["dueDate"]["after"]) : DateTime(2022),
        lastDate: DateTime(2049),
      );

      if (picked != null) {
        widget.filters["dueDate"]["before"] = DateFormat('yyyy-MM-dd').format(picked);
      }
    } else if (type == "after") {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: widget.filters["dueDate"]["before"] != null ? 
            DateTime.parse(widget.filters["dueDate"]["before"]).add(const Duration(days: -1))
            : widget.filters["dueDate"]["after"] != null 
            ? DateTime.parse(widget.filters["dueDate"]["after"]) 
            : DateTime.now(),
        firstDate: DateTime(2022),
        lastDate: widget.filters["dueDate"]["before"] != null ? 
            DateTime.parse(widget.filters["dueDate"]["before"]) : DateTime(2049),
      );

      if (picked != null) {
        widget.filters["dueDate"]["after"] =  DateFormat('yyyy-MM-dd').format(picked);
      }
    } else if (type == "removeAfter") {
      widget.filters["dueDate"].remove("after");
    } else if(type == "removeBefore") {
      widget.filters["dueDate"].remove("before");
    }

    widget.onChangeFilter("dueDate", widget.filters["dueDate"]);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.centerLeft,
          height: 44,
          child: Text("Due Date:", style: TextStyle(color: isDark ? null : Color(0xff5E5E5E)))
        ),
        InkWell(
          onTap: () {
            onChangeFilter("noDueDate");
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.centerLeft,
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIcons.calendarBlank, size: 18, color: isDark ? null : Color(0xff5E5E5E)),
                    SizedBox(width: 10),
                    Text("No due date", style: TextStyle(color: isDark ? null : Color(0xff5E5E5E)))
                  ]
                ),
                if(widget.filters["dueDate"]["type"] == "noDueDate") Icon(PhosphorIcons.checkCircleThin, size: 18, color: Color(0xffFAAD14))
              ]
            )
          )
        ),
        InkWell(
          onTap: () {
            onChangeFilter("overdue");
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.centerLeft,
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Color(0xffFF7875)
                      ),
                      height: 22,
                      width: 22,
                      child: Center(child: Icon(PhosphorIcons.clock, size: 17))
                    ),
                    SizedBox(width: 10),
                    Text("Overdue", style: TextStyle(color: isDark ? null : Color(0xff5E5E5E)))
                  ]
                ),
                if(widget.filters["dueDate"]["type"] == "overdue") Icon(PhosphorIcons.checkCircleThin, size: 18, color: Color(0xffFAAD14))
              ]
            )
          )
        ),
        InkWell(
          onTap: () {
            onChangeFilter("after");
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.centerLeft,
                height: 44,
                child: Row(
                  children: [
                    Icon(PhosphorIcons.calendar, size: 18, color: isDark ? null : Color(0xff5E5E5E)),
                    SizedBox(width: 10),
                    widget.filters["dueDate"]["after"] != null ? Row(
                      children: [
                        Text("After "),
                        Text(
                          "${DateFormatter().renderTime(DateTime.parse("${widget.filters['dueDate']['after']}"), type: 'yMMMd')}",
                          style: TextStyle(color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E), fontSize: 14)
                        ),
                      ],
                    ) : Text("After", style: TextStyle(color: isDark ? null : Color(0xff5E5E5E)))
                  ]
                )
              ),
              if(widget.filters["dueDate"]["after"] != null) InkWell(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                onTap: () {
                  onChangeFilter("removeAfter");
                },
                child: Container(
                  height: 30,
                  width: 30,
                  margin: EdgeInsets.only(right: 10),
                  child: Icon(PhosphorIcons.x, size: 18)
                )
              )
            ]
          )
        ),
        InkWell(
          onTap: () async {
           onChangeFilter("before");
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.centerLeft,
                height: 44,
                child: Row(
                  children: [
                    Icon(PhosphorIcons.calendar, size: 18, color: isDark ? null : Color(0xff5E5E5E)),
                    SizedBox(width: 10),
                    widget.filters["dueDate"]["before"] != null ? Row(
                      children: [
                        Text("Before "),
                        Text(
                          "${DateFormatter().renderTime(DateTime.parse("${widget.filters['dueDate']['before']}"), type: 'yMMMd')}",
                          style: TextStyle(color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E), fontSize: 14)
                        )
                      ]
                    ) : Text("Before", style: TextStyle(color: isDark ? null : Color(0xff5E5E5E)))
                  ]
                )
              ),
              if(widget.filters["dueDate"]["before"] != null) InkWell(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                onTap: () {
                  onChangeFilter("removeBefore");
                },
                child: Container(
                  height: 30,
                  width: 30,
                  margin: EdgeInsets.only(right: 10),
                  child: Icon(PhosphorIcons.x, size: 18)
                )
              )
            ]
          )
        ),
        SizedBox(height: 4)
      ]
    );
  }
}

class SelectfilterType extends StatefulWidget {
  const SelectfilterType({
    Key? key,
    required this.filterType,
    this.onChangefilterType
  }) : super(key: key);

  final String filterType;
  final onChangefilterType;

  @override
  State<SelectfilterType> createState() => _SelectfilterTypeState();
}

class _SelectfilterTypeState extends State<SelectfilterType> {
  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return InkWell(
      onTap: () {
        showPopover(
          backgroundColor: Colors.transparent,
          context: context,
          shadow: [BoxShadow(color: Colors.transparent, blurRadius: 0)],
          transitionDuration: const Duration(milliseconds: 50),
          direction: PopoverDirection.top,
          barrierColor: Colors.transparent,
          radius: 4,
          height: 105,
          width: 336,
          bodyBuilder: (context) => StatefulBuilder(
            builder: (context, setState) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? Color(0xff353535) : Color(0xffF8F8F8),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9),
                    width: 1
                  )
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        widget.onChangefilterType("any");
                      },
                      child: Container(
                        color: isDark ? Color(0xff353535) : Color(0xffF8F8F8),
                        width: 336,
                        height: 50,
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Any match"),
                            Text("Match any label and any member.", style: TextStyle(fontSize: 11, color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E)))
                          ]
                        )
                      )
                    ),
                    Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1, thickness: 1),
                    InkWell(
                      onTap: () {
                        widget.onChangefilterType("exact");
                      },
                      child: Container(
                        width: 336,
                        height: 50,
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Exact match"),
                            Text("Match any label and any member.", style: TextStyle(fontSize: 11, color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E)))
                          ]
                        )
                      )
                    )
                  ]
                )
              );
            }
          )
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18),
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.filterType == "exact" ? "Exact match" : "Any match", style: TextStyle(color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E))),
            Icon(PhosphorIcons.caretDown, color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E), size: 20)
          ]
        )
      ),
    );
  }
}

class FilterLabel extends StatefulWidget {
  const FilterLabel({
    Key? key,
    this.onChangeFilter,
    required this.labels
  }) : super(key: key);

  final onChangeFilter;
  final List labels;

  @override
  State<FilterLabel> createState() => _FilterLabelState();
}

class _FilterLabelState extends State<FilterLabel> {
  @override
  Widget build(BuildContext context) {
    final selectedBoard = Provider.of<Boards>(context, listen: true).selectedBoard;
    final firstThreeLabels = selectedBoard["labels"].length >= 3 ? selectedBoard["labels"].sublist(0, 3) : selectedBoard["labels"];
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Labels:", style: TextStyle(color: isDark ? Palette.defaultTextDark : Color(0xff5E5E5E))),
          SizedBox(height: 12),
          // Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1, thickness: 1),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: firstThreeLabels.map<Widget>((e) {
              return Wrap(
                children: [
                  InkWell(
                    onTap: () {
                      widget.onChangeFilter("label", e["id"]);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          height: 20,
                          decoration: BoxDecoration(
                            color: Color(int.parse("0xFF${e["color_hex"]}")),
                            borderRadius: BorderRadius.circular(16)
                          ),
                          margin: EdgeInsets.symmetric(vertical: 12),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                            child: Text(e["name"], style: TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis, color: isDark ? Palette.defaultTextDark : Colors.white))
                          )
                        ),
                        if(widget.labels.contains(e["id"])) Icon(PhosphorIcons.checkCircleThin, size: 18, color: Color(0xffFAAD14))
                      ]
                    ),
                  ),
                  // Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1, thickness: 1)
                ]
              );
            }).toList()
          ),
          LabelFilterSelection(onChangeFilter: widget.onChangeFilter, labels: widget.labels),
          SizedBox(height: 4),
        ]
      )
    );
  }
}

class LabelFilterSelection extends StatefulWidget {
  const LabelFilterSelection({
    Key? key,
    this.onChangeFilter,
    required this.labels
  }) : super(key: key);

  final onChangeFilter;
  final List labels;

  @override
  State<LabelFilterSelection> createState() => _LabelFilterSelectionState();
}

class _LabelFilterSelectionState extends State<LabelFilterSelection> {
  String text = '';

  @override
  Widget build(BuildContext context) {
    final selectedBoard = Provider.of<Boards>(context, listen: true).selectedBoard;
    final lastLabels = selectedBoard["labels"].length >= 3 ? selectedBoard["labels"].sublist(3) : [];
    final selectedLabels = lastLabels.where((e) => widget.labels.contains(e["id"])).toList();
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Container(
      height: 42,
      child: InkWell(
        onTap: () {
          showPopover(
            backgroundColor: Colors.transparent,
            context: context,
            shadow: [BoxShadow(color: Colors.transparent, blurRadius: 0)],
            transitionDuration: const Duration(milliseconds: 50),
            direction: PopoverDirection.top,
            barrierColor: Colors.transparent,
            arrowHeight: 23,
            arrowWidth: 23,
            contentDyOffset: -18,
            radius: 2,
            height: 331,
            width: 312,
            bodyBuilder: (context) => StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xff353535) : Color(0xffffffff),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark ? Color(0xff5E5E5E) : Color(0xffC9C9C9),
                      width: 0.5
                    )
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 12),
                      Container(
                        color: isDark ? null : Color(0xffF8F8F8),
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          height: 36,
                          child: CupertinoTextField(
                            autofocus: true,
                            onChanged: (value) {
                              setState(() {
                                text = Utils.unSignVietnamese(value);
                              });
                            },
                            padding: EdgeInsets.only(left: 8, bottom: 2, right: 10),
                            decoration: BoxDecoration(
                              color: isDark ? Color(0xff444444) : Color(0xffF8F8F8),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isDark ? Color(0xff828282) : Color(0xffDBDBDB))
                            ),
                            style: TextStyle(fontSize: 14, color: Color(0xffA6A6A6)),
                            placeholder: "Search label",
                            placeholderStyle: TextStyle(fontSize: 14, color: Color(0xffA6A6A6))
                          )
                        )
                      ),
                      SizedBox(height: 12),
                      Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1, thickness: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: lastLabels.map<Widget>((e) {
                              return text.trim() != "" && !Utils.unSignVietnamese(e["name"]).toLowerCase().contains(text.trim().toLowerCase()) ? Container() : Wrap(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        widget.onChangeFilter("label", e["id"]);
                                      });
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8),
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Color(int.parse("0xFF${e["color_hex"]}")),
                                            borderRadius: BorderRadius.circular(16)
                                          ),
                                          margin: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                                            child: Text(e["name"], style: TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis, color: isDark ? null : Colors.white))
                                          )
                                        ),
                                        if(widget.labels.contains(e["id"])) Icon(PhosphorIcons.checkCircleThin, size: 18, color: Color(0xffFAAD14))
                                      ]
                                    )
                                  ),
                                  Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1, thickness: 1)
                                ]
                              );
                            }).toList()
                          ),
                        ),
                      ),
                    ],
                  )
                );
              }
            )
          ).then((value) {
            this.setState(() {
              text = "";
            });
          });
        },
        child: selectedLabels.length > 0 ? Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${selectedLabels.length} label selected", style: TextStyle(color: Color(0xffFAAD14))),
            Icon(PhosphorIcons.caretDown, color: Color(0xffFAAD14), size: 20)
          ]
        ) : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Choose a label", style: TextStyle(color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E))),
            Icon(PhosphorIcons.caretDown, color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E), size: 20)
          ]
        )
      ),
    );
  }
}

class FilterPriority extends StatefulWidget {
  const FilterPriority({
    Key? key,
    this.onChangeFilter,
    this.priority
  }) : super(key: key);

  final onChangeFilter;
  final priority;

  @override
  State<FilterPriority> createState() => _FilterPriorityState();
}

class _FilterPriorityState extends State<FilterPriority> {
  List priorities = [1,2,3,4,5];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Priority:", style: TextStyle(color: isDark ? null : Color(0xff5E5E5E))),
          SizedBox(height: 12),
          // Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1, thickness: 1),
          SizedBox(height: 2),
          Wrap(
            direction: Axis.vertical,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: priorities.map<Widget>((e) {
              return InkWell(
                onTap: () {
                  widget.onChangeFilter("priority", e);
                },
                child: Container(
                  width: 322,
                  // decoration: BoxDecoration(
                  //   border: Border(
                  //     bottom: BorderSide(
                  //       color: e == 5 ? Colors.transparent : isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)
                  //     )
                  //   )
                  // ),
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      getPriority(e, isDark),
                      if(widget.priority == e) Icon(PhosphorIcons.checkCircleThin, size: 18, color: Color(0xffFAAD14))
                    ]
                  )
                )
              );
            }).toList()
          )
        ]
      ),
    );
  }
}

class FilterMember extends StatefulWidget {
  const FilterMember({
    Key? key,
    this.onChangeFilter,
    required this.members
  }) : super(key: key);

  final onChangeFilter;
  final List members;

  @override
  State<FilterMember> createState() => _FilterMemberState();
}

class _FilterMemberState extends State<FilterMember> {
  String text = '';

  findUser(id) {
    final members = Provider.of<Workspaces>(context, listen: false).members;
    final indexMember = members.indexWhere((e) => e["id"] == id);

    if (indexMember != -1) {
      return members[indexMember];
    } else {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<Auth>(context, listen: true).userId;
    final channelMember = Provider.of<Channels>(context, listen: true).channelMember.where((e) => e["id"] != userId && e["account_type"] == "user").toList();
    final bool isDark = Provider.of<Auth>(context, listen: true).theme == ThemeType.DARK;

    return Container(
      width: 322,
      height: 42,
      child: InkWell(
        onTap: () {
          showPopover(
            backgroundColor: Colors.transparent,
            context: context,
            shadow: [BoxShadow(color: Colors.transparent, blurRadius: 0)],
            transitionDuration: const Duration(milliseconds: 50),
            direction: PopoverDirection.bottom,
            barrierColor: Colors.transparent,
            arrowHeight: 23,
            arrowWidth: 23,
            contentDyOffset: -18,
            radius: 2,
            width: 312,
            bodyBuilder: (context) => StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xff353535) : Color(0xffF8F8F8),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB),
                      width: 0.5
                    )
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 12),
                      Container(
                        color: isDark ? null : Color(0xffF8F8F8),
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          height: 36,
                          child: CupertinoTextField(
                            autofocus: true,
                            onChanged: (value) {
                              setState(() {
                                text = Utils.unSignVietnamese(value);
                              });
                            },
                            padding: EdgeInsets.only(left: 8, bottom: 2, right: 10),
                            decoration: BoxDecoration(
                              color: isDark ? Color(0xff444444) : Color(0xffF8F8F8),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isDark ? Color(0xff828282) : Color(0xffDBDBDB))
                            ),
                            style: TextStyle(fontSize: 14, color: Color(0xffA6A6A6)),
                            placeholder: "Search member",
                            placeholderStyle: TextStyle(fontSize: 14, color: Color(0xffA6A6A6))
                          )
                        )
                      ),
                      SizedBox(height: 12),
                      Divider(color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB), height: 1, thickness: 1),
                      Column(
                        children: channelMember.map((e) {
                          return text.trim() != "" && !Utils.unSignVietnamese(e["full_name"]).toLowerCase().contains(text.trim().toLowerCase()) ? Container() : InkWell(
                            onTap: () {
                              setState(() {
                                widget.onChangeFilter("member", e["id"]);
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isDark ? Color(0xff5E5E5E) : Color(0xffDBDBDB)
                                  )
                                )
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      CachedAvatar(e["avatar_url"], name: e["full_name"], width: 24, height: 24, radius: 24),
                                      SizedBox(width: 12),
                                      Text(e["full_name"], style: TextStyle(color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E)))
                                    ]
                                  ),
                                  if(widget.members.contains(e["id"])) Icon(PhosphorIcons.checkCircleThin, size: 18, color: Color(0xffFAAD14))
                                ],
                              )
                            ),
                          );
                        }).toList()
                      )
                    ]
                  )
                );
              }
            )
          ).then((value) {
            this.setState(() {
              text = "";
            });
          });
        },
        child: widget.members.length > 0 ? Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Selected: ", style: TextStyle(color: Color(0xffA6A6A6))),
                Container(
                  width: 240,
                  child: Wrap(
                    children: widget.members.map((e) {
                      var member = findUser(e);
                      var index = widget.members.indexOf(e);

                      return Text(index == widget.members.length - 1 ? "${member["full_name"]}": "${member["full_name"]}, ", style: TextStyle(color: Color(0xffDBDBDB)));
                    }).toList(),
                  ),
                )
              ]
            ),
            Icon(PhosphorIcons.caretDown, color: Color(0xffDBDBDB), size: 20)
          ],
        ) : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Choose a member", style: TextStyle(color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E))),
            Icon(PhosphorIcons.caretDown, color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E), size: 20)
          ]
        )
      )
    );
  }
}

getPriority(priority, isDark) {
  Widget icon = priority == 1 ? Icon(PhosphorIcons.fire, color: Color(0xffFF7875), size: 19)
    : priority == 2 ?
      Container(
        height: 28,
        child: Stack(children: [
          Positioned(child: Icon(PhosphorIcons.caretUpThin, size: 18.5, color: Color(0xffFAAD14))),
          Positioned(top: 4, child: Icon(PhosphorIcons.caretUpThin, size: 18.5, color: Color(0xffFAAD14))),
          Positioned(top: 8, child: Icon(PhosphorIcons.caretUpThin, size: 18.5, color: Color(0xffFAAD14)))
        ]),
      )
    : priority == 3 ?
      Container(
        height: 22,
        child: Stack(children: [
          Positioned(child: Icon(PhosphorIcons.caretUpThin, size: 18.5, color: Color(0xff27AE60))),
          Positioned(top: 4, child: Icon(PhosphorIcons.caretUpThin, size: 18.5, color: Color(0xff27AE60)))
        ]),
      )
    : priority == 4 ?
      Icon(PhosphorIcons.caretUpThin, size: 18.5, color: Color(0xff69C0FF))
    : Icon(PhosphorIcons.minus, size: 19, color: isDark ? null : Color(0xff5E5E5E));

  Widget text = Text(
    priority == 1 ? "Urgent" : priority == 2 ? 'High' : priority == 3 ? 'Medium' : priority == 4 ? 'Low' : 'None',
    style: TextStyle(
      color: priority == 1
      ? Color(0xffFF7875)
      : priority == 2
        ? Palette.calendulaGold
        : priority == 3
          ? Color(0xff27AE60)
          : priority == 4
            ? Color(0xff69C0FF)
            : (isDark ? Palette.defaultTextDark : Color(0xff5E5E5E))
    )
  );

  return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
    icon,
    SizedBox(width: 8),
    text
  ]);
}