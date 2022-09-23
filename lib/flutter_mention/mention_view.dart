part of flutter_mentions;

class FlutterMentions extends StatefulWidget {
  FlutterMentions({
    required this.mentions,
    Key? key,
    this.suggestionPosition = SuggestionPosition.Bottom,
    this.onMarkupChanged,
    this.onMentionAdd,
    this.onSearchChanged,
    this.leading = const [],
    this.trailing = const [],
    this.suggestionListDecoration,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.readOnly = false,
    this.showCursor,
    this.maxLength,
    this.maxLengthEnforcement = MaxLengthEnforcement.none,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.enabled,
    this.cursorWidth = 1.0,
    this.cursorHeight = 15,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableInteractiveSelection = true,
    this.onTap,
    this.buildCounter,
    this.scrollPhysics,
    this.scrollController,
    this.autofillHints,
    this.appendSpaceOnAdd = true,
    this.hideSuggestionList = false,
    this.onSuggestionVisibleChanged,
    this.controller,
    this.id,
    this.islastEdited = false,
    this.sendMessages,
    this.onEdittingText,
    this.isIssues,
    this.handleEnterEvent,
    this.handleUpdateIssues,
    this.isCodeBlock,
    this.handleCodeBlock,
    this.isUpdate,
    this.setUpdateMessage,
    this.setShareMessage,
    this.isShowCommand,
    this.selectArrowCommand,
    this.isDark,
    this.isThread = false,
    this.parseMention,
    this.onFocusChange,
    this.afterFirstFrame,
    this.isViewThread = false,
    this.handleMessageToAttachments,
    this.isKanbanMode = false
  }) : super(key: key);

  final handleMessageToAttachments;

  final bool isThread;

  final bool isViewThread;

  final bool? isIssues;

  final Function? handleEnterEvent;

  final Function? handleUpdateIssues;

  final bool? isShowCommand;

  final Function? selectArrowCommand;

  final Function? setUpdateMessage;

  final Function? setShareMessage;

  final bool? isUpdate;

  final bool? isCodeBlock;

  final Function? handleCodeBlock;

  final Function? onEdittingText;

  final Function? sendMessages;

  final bool islastEdited;

  final TextEditingController? controller;

  final bool? isDark;

  final String? id;

  final bool hideSuggestionList;

  final Function(bool)? onSuggestionVisibleChanged;

  final List<Mention> mentions;

  final List<Widget> leading;

  final List<Widget> trailing;

  final SuggestionPosition suggestionPosition;

  final Function(Map<String, dynamic>)? onMentionAdd;

  final ValueChanged<String>? onMarkupChanged;

  final void Function(String trigger, String value)? onSearchChanged;

  final BoxDecoration? suggestionListDecoration;

  final FocusNode? focusNode;

  final bool appendSpaceOnAdd;

  final InputDecoration decoration;

  final TextInputType? keyboardType;

  final TextInputAction? textInputAction;

  final TextCapitalization textCapitalization;

  final TextStyle? style;

  final StrutStyle? strutStyle;

  final TextAlign textAlign;

  final TextDirection? textDirection;

  final bool autofocus;

  final bool autocorrect;

  final bool enableSuggestions;

  final int maxLines;

  final int? minLines;

  final bool expands;

  final bool readOnly;

  final bool? showCursor;

  static const int noMaxLength = -1;

  final int? maxLength;

  final MaxLengthEnforcement maxLengthEnforcement;

  final ValueChanged<String>? onChanged;

  final VoidCallback? onEditingComplete;

  final ValueChanged<String>? onSubmitted;

  final bool? enabled;

  final double cursorWidth;

  final double cursorHeight;

  final Radius? cursorRadius;

  final Color? cursorColor;

  final Brightness? keyboardAppearance;

  final EdgeInsets scrollPadding;

  final bool enableInteractiveSelection;

  bool get selectionEnabled => enableInteractiveSelection;

  final GestureTapCallback? onTap;

  final InputCounterWidgetBuilder? buildCounter;

  final ScrollPhysics? scrollPhysics;

  final ScrollController? scrollController;

  final Iterable<String>? autofillHints;

  final Function? parseMention;

  final Function? onFocusChange;

  final Function? afterFirstFrame;

  final bool isKanbanMode;

  @override
  FlutterMentionsState createState() => FlutterMentionsState();
}

class FlutterMentionsState extends State<FlutterMentions> {
  GlobalKey<CustomTextFieldState> key = GlobalKey<CustomTextFieldState> ();
  AnnotationEditingController? controller;
  ScrollController scrollController = ScrollController();
  ValueNotifier<bool> showSuggestions = ValueNotifier(false);
  LengthMap? _selectedMention;
  String _pattern = '';
  FocusNode focusNode = FocusNode();
  Map<String, dynamic>? currentMention;
  int indexSelectedMention = 0;
  bool isShow = false;
  final ItemScrollController _controller = ItemScrollController();
  bool triggerMention = false;
  bool isFocus = false;
  int lastCursorPosition = 0;
  bool oldFocusApp = true;
  var _textMarkUp = "";
  Alignment? alignment;

  Map dataFiltered = {
    "data": [],
    "str": ""
  };
  Map<String, Annotation> mapToAnotation() {
    final data = <String, Annotation>{};

    // Loop over all the mention items and generate a suggestions matching list
    widget.mentions.forEach((element) {
      // if matchAll is set to true add a general regex patteren to match with
      if (element.matchAll) {
        data['${element.trigger}([A-Za-z0-9])*'] = Annotation(
          style: element.style,
          id: null,
          display: null,
          trigger: element.trigger,
          disableMarkup: element.disableMarkup,
          markupBuilder: element.markupBuilder,
        );
      }
      element.data.forEach(
        (e) => data["${element.trigger}${e['display']}"] = e['style'] != null
            ? Annotation(
                style: e['style'],
                id: e['id'],
                display: e['display'],
                trigger: element.trigger,
                disableMarkup: element.disableMarkup,
                markupBuilder: element.markupBuilder,
              )
            : Annotation(
                style: element.style,
                id: e['id'],
                display: e['display'],
                trigger: element.trigger,
                disableMarkup: element.disableMarkup,
                markupBuilder: element.markupBuilder,
              ),
      );
    });

    return data;
  }

  void setMarkUpText(String markUp){
    var parse  = checkMentions(markUp);
    _textMarkUp = markUp;
    controller!.text =  parse["success"] ? Utils.getStringFromParse(parse["data"]) : markUp;
    controller!.selection = TextSelection.fromPosition(TextPosition(offset: (controller!.text.length)));
  }

  String getStringFromParse(List parses){
    return Utils.getStringFromParse(parses);
  }

  String getMarkUpFromParse(List parses){
    return parses.map((e) {
      if (e["type"] == "text") return e["value"];
      var trigger = e["trigger"];
      final _list = widget.mentions.firstWhere((element) => trigger.contains(element.trigger));
      return _list.markupBuilder(_list.trigger, e["value"], e["name"], e["type"]);
    }).toList().join("");
  }

  // tra ve so phan tu giong nhau tu ben trai
  int getLeftIndex(String left, String right){
    int count = -1;
    int leftLength = left.length;
    int rightLength = right.length;
    // uu tien lay chuoi ngan hon
    String sourceToStart = leftLength < rightLength ? left: right;
    // uu tien lay chuoi daI hon
    String target  = leftLength < rightLength ? right: left;

    for(int i = 0; i < sourceToStart.length; i++){
      if (sourceToStart[i] == target[i]) count = i;
      else break;
    }
    return count + 1;
  }

  //  tra ve so phan tu giong nhau ke tu ben phai
  int getRightIndex(String left, String right){
    int leftCount = getLeftIndex(left, right);
    String newLeft = left.replaceRange(0, leftCount, "");
    String newRight = right.replaceRange(0, leftCount, "");
    return getLeftIndex(newLeft.split("").reversed.join(""), newRight.split("").reversed.join(""));
  }

  String leftNewString(List dataParse, int count){
    var index = 0;
    var results = [];
    for (int i = 0; i < dataParse.length; i++ ){
      String strDataParse = dataParse[i]["type"] == "text" ? dataParse[i]["value"] : "${dataParse[i]["trigger"]}${dataParse[i]["name"]}";
      if ((index + (strDataParse.length)) <= count){
        results += [dataParse[i]];
        index = index + (strDataParse.length);
      } else {
        results += [{
          "type": "text",
          "value": strDataParse.substring(0, count - index)
        }];
        break;
      }
    }
    return getMarkUpFromParse(results);
  }

  String rightNewString(List dataParse, int count){
    if (count == 0) return "";
    var results = [];
    var initCount = 0;
    for (var i = dataParse.length -1; i >= 0; i --){
      String strDataParse = dataParse[i]["type"] == "text" ? dataParse[i]["value"] : "${dataParse[i]["trigger"]}${dataParse[i]["name"]}";
      if (initCount == count) break;
      if ((initCount + strDataParse.length) <= count){
        results = [] + [dataParse[i]] + results;
        initCount = initCount + strDataParse.length;
      } else {
        results = [] + [{
          "type": "text",
          "value": strDataParse.substring(strDataParse.length - count + initCount, strDataParse.length)
        }] + results;
        break;
      }
    }
    return getMarkUpFromParse(results);
  }

  checkMentions(String markUpText){
    // if (widget.parseMention == null) return checkMentions(markUpText);
    return widget.parseMention!(markUpText, trim: false);
  }

  int checkIsInOldMention(List dataParse, int count){
    if (count < 0) return -1;
    var offset = 0;
    for(int i =0 ; i < dataParse.length ; i++){
      String strDataParse = dataParse[i]["type"] == "text" ? dataParse[i]["value"] : "${dataParse[i]["trigger"]}${dataParse[i]["name"]}";
      if (offset <= count && count <= (offset + (strDataParse.length)) && dataParse[i]["type"] != "text") return i;
      else offset += strDataParse.length;
    }
    return -1;
  }

  void addMention(Map<String, dynamic> value, [Mention? list]) {
    final selectedMention = _selectedMention!;
    var t = _selectedMention;
    setState(() {
      _selectedMention = null;
      currentMention = null;
    });

    final _list = widget.mentions.firstWhere((element) => selectedMention.str!.contains(element.trigger));
    if (t == null) return;
    var text = controller!.value.text;
    var parse = checkMentions(_textMarkUp);
    if (parse["success"] == false){
      // neu tin do chua co mention, thi tu them vao vi tri con tro
      _textMarkUp = text.replaceRange(
        selectedMention.start!,
        selectedMention.end,
        _list.markupBuilder(_list.trigger, value["id"], value["display"], value["type"] ) + (widget.appendSpaceOnAdd ? " " : "")
      );
      controller!.text = controller!.value.text.replaceRange(
        selectedMention.start!,
        selectedMention.end,
        "${_list.trigger}${value['display']}${widget.appendSpaceOnAdd ? ' ' : ''}",
      );

      if (widget.onMentionAdd != null) widget.onMentionAdd!(value);

      // Move the cursor to next position after the new mentioned item.
      var nextCursorPosition = selectedMention.start! + 1 + value['display']?.length as int? ?? 0;
      if (widget.appendSpaceOnAdd) nextCursorPosition++;
      controller!.selection = TextSelection.fromPosition(TextPosition(offset: nextCursorPosition));
    } else {
      var dataParses = parse["data"];

      // thay the mention hien tai = mention moi (neu da o mention)

      var indexMentionOld = checkIsInOldMention(dataParses, selectedMention.start ?? -1);
      if (indexMentionOld  == -1){
        // khoi tao lai chuoi trai
        var leftStr = leftNewString(dataParses, selectedMention.start!);

        //  khoi tao chuoi phai
        var rightStr = rightNewString(dataParses, text.length - selectedMention.end!);

        // khoi tao chuoi giua
        var innerStr = getMarkUpFromParse([{
          "type": value["type"],
          "value": value["id"],
          "trigger": _list.trigger,
          "name": value["display"]
        }]);

        _textMarkUp = (leftStr + innerStr + (widget.appendSpaceOnAdd ? " " : "") + rightStr);
        autoDetectMention();

        controller!.text = controller!.value.text.replaceRange(
          selectedMention.start!,
          selectedMention.end,
          "${_list.trigger}${value['display']}${widget.appendSpaceOnAdd ? ' ' : ''}",
        );

        if (widget.onMentionAdd != null) widget.onMentionAdd!(value);

        // Move the cursor to next position after the new mentioned item.
        var nextCursorPosition = selectedMention.start! + 1 + value['display']?.length as int? ?? 0;
        if (widget.appendSpaceOnAdd) nextCursorPosition++;
        controller!.selection = TextSelection.fromPosition(TextPosition(offset: nextCursorPosition));
      } else {
        dataParses[indexMentionOld] = {
          "type": value["type"],
          "trigger": _list.trigger,
          "value": value["id"],
          "name": value["display"]
        };
        if (indexMentionOld == (dataParses.length - 2)) dataParses += [{"type": "text", "value": " "}];
        _textMarkUp = getMarkUpFromParse(dataParses);
        controller!.text = getStringFromParse(dataParses);
        var nextCursorPosition = selectedMention.start! + 1 + value['display']?.length as int? ?? 0;
        controller!.selection = TextSelection.fromPosition(TextPosition(offset: nextCursorPosition + 1 > controller!.text.length ? nextCursorPosition : nextCursorPosition + 1));
      }
    }
  }

  checkReMarkUpText(String newString){
    var parse = checkMentions(_textMarkUp);
    if (parse["success"] == false){
      _textMarkUp = newString;
    } else {
      var dataParses  = parse["data"];
      // lay lai text cu
      var oldStr = getStringFromParse(dataParses);
      var newStr = controller!.text;
      // print("\n oldStr: ,${oldStr},${oldStr.length} \n newStr: ,$newStr,${newStr.length} \n parse: $parse");
      if (oldStr == newStr) {}
      else {
        // tim phan tu dau dien tu trai qua phai khac nhau cua oldStr va newStr
        var leftCount = getLeftIndex(oldStr, newStr);
        var rightCount = getRightIndex(oldStr, newStr);

        // khoi tao lai chuoi trai
        var leftStr = leftNewString(dataParses, leftCount);

        //  khoi tao chuoi phai
        var rightStr = rightNewString(dataParses, rightCount);

        // khoi tao chuoi giua
        var innerStr = newStr.substring(leftCount, newStr.length - rightCount);

        _textMarkUp = leftStr + innerStr + rightStr;
      }
    }
    autoDetectMention();
  }

  autoDetectMention(){
    controller!.setMarkText(_textMarkUp);

    // return;
    // if (_textMarkUp.length <= 500){
    //   var parse = checkMentions(_textMarkUp);
    //   List totalMentions = widget.mentions.map((ele) {
    //     return ele.data.map((d) {
    //       return Utils.mergeMaps([
    //         d,
    //         {
    //           "trigger": ele.trigger,
    //           "strMath": Utils.unSignVietnamese("${ele.trigger}${d["display"]}")
    //         }
    //       ]);
    //     });
    //   }).toList().reduce((value, element) => value = value + element).toList();
    //   totalMentions.sort((a, b) =>  a["strMath"].length <= b["strMath"].length ? 1 :  -1);

    //   var parses = [];
    //   if (parse["success"] == false){
    //     parses = [{
    //       "type": "text",
    //       "value": _textMarkUp,
    //     }];
    //   } else {
    //     parses = parse["data"];
    //   }
    //   var results = [];
    //   for (int i = 0; i < parses.length; i++){
    //     if (parses[i]["type"] != "text") {
    //       results  = [] + results + [parses[i]];
    //     } else {
    //       // detect
    //       // lay tat ca cac mentions lai, uu tien mention co ten dai nhat

    //       String text = parses[i]["value"];
    //       String cloneText = text;
    //       // lap den khi cloneText = ""
    //       RegExp exp = new RegExp(r"[@|#]{1}");
    //       while (cloneText != "") {
    //         if (exp.hasMatch(cloneText[0])){
    //           // tim mention dai nhat
    //           try {
    //             var first = totalMentions.firstWhere((element) {
    //               try {
    //                 int length = element["strMath"].length;
    //                 if (element["strMath"] == Utils.unSignVietnamese(cloneText.substring(0, length))) return true;
    //                 return false;
    //               } catch (e) {
    //                 return false;
    //               }
    //             });
    //             if (first == null){
    //               results += [{
    //                 "type": "text",
    //                 "value": cloneText[0]
    //               }];
    //               cloneText = cloneText.replaceRange(0, 1, "");
    //             } else {
    //               results += [{
    //                 "type": first["type"],
    //                 "name": first["display"],
    //                 "trigger": first["trigger"],
    //                 "value": first["id"]
    //               }];
    //               cloneText = cloneText.replaceRange(0, first["strMath"].length, "");
    //             }
    //           } catch (e) {
    //             results += [{
    //               "type": "text",
    //               "value": cloneText[0]
    //             }];
    //             cloneText = cloneText.replaceRange(0, 1, "");
    //           }
    //         }
    //         else {
    //           results += [{
    //             "type": "text",
    //             "value": cloneText[0]
    //           }];
    //           cloneText = cloneText.replaceRange(0, 1, "");
    //         }
    //       }
    //     }
    //   }
    //   _textMarkUp = getMarkUpFromParse(results);
    //   // an dong nay de giu lai text cu
    //   // if (getStringFromParse(results) != controller!.text)
    //   //   controller!.text = getStringFromParse(results);
    // }
    // controller!.setMarkText(_textMarkUp);
  }

  checkCanShowInElement(text, cursorPos){
    // check @@@
    try {
      String newText = "  " + text + "  ";
      int newCursorPos = (cursorPos ?? 0) + 2;
      var left = newText.substring(newCursorPos - 1, newCursorPos);
      var right = newText.substring(newCursorPos, newCursorPos + 1);
      RegExp reg = RegExp(r'(?=[@|#])');
      var nearRegexLeftIndex = newText.substring(0, newCursorPos).lastIndexOf(reg);
      return !(
        (reg.hasMatch(right) && reg.hasMatch(left))
        || (nearRegexLeftIndex == -1 ? false : reg.hasMatch(newText.substring(nearRegexLeftIndex - 1, nearRegexLeftIndex)))
      );
    } catch (e) {
      return false;
    }
  }

  void suggestionListerner() {
    final cursorPos = controller!.selection.baseOffset;

    if (cursorPos >= 0) {
      var _pos = 0;

      final lengthMap = <LengthMap>[];
      // final String text = convertStringRegex(controller!.value.text);
      final String text = controller!.value.text.replaceAllMapped(RegExp(r'(?=[@|#]{2,})'), (map) {
        return  (map.group(0) ?? "").split("").map((e) => "_").join();
      });
      // split on each word and generate a list with start & end position of each word.
      text.split(RegExp(r'(?=[@|#])')).forEach((element) {
        lengthMap.add(LengthMap(str: element, start: _pos, end: _pos + element.length));
        _pos = _pos + element.length;
      });

      var val = lengthMap.indexWhere((element) {
        String? content;
        _pattern = widget.mentions.map((e) => e.trigger).join('|');

        try {
          if (element.start! <= cursorPos && cursorPos <= (element.end ?? 0)) content = controller!.value.text.substring(element.start!, cursorPos);
        } catch (e) { }

        return content == null  ? false : content.toLowerCase().contains(RegExp(_pattern));
      });
      if (!checkCanShowInElement(text, cursorPos)){
         val = -1;
      }
      showSuggestions.value = val != -1;

      if (widget.onSuggestionVisibleChanged != null) {
        widget.onSuggestionVisibleChanged!(val != -1);
      }

      LengthMap? t;
      bool hasShow = true;
      checkReMarkUpText(controller!.value.text);
      try {
        // end là vị trí con trỏ hiện tại
        t = LengthMap(end: cursorPos, start: lengthMap[val].start, str: controller!.value.text.substring(lengthMap[val].start!, cursorPos));
        if (checkIsInOldMention(checkMentions(_textMarkUp)["data"], lengthMap[val].start ?? -1) != -1) hasShow = false;
      } catch (e) { }

      setState(() {
        _selectedMention = hasShow ? t : null;
      });
    }
  }

  convertStringRegex(String l) {
    var s = "";
    var length = l.length + 2;
    for(var i =0; i< length; i++){
      if (i == 0 || i == length -1) continue;
      var index  = i-1;
      if (l[index] != "@" || l[index] != "#"){
        s+=l[index];
        continue;
      } else {
        if ((index - 1 >= 0 ? (l[index -1] == " " || l[index -1] == "\n") : true) && (index +1 < l.length ? (l[index +1] != "@" || l[index +1] != "#") : true))
          s+=l[index];
        else s+= "_";
      }
    }

    return s;
  }

  onSelectedMentions(data, int index) {
    currentMention = data;
    indexSelectedMention = index;
  }

  void inputListeners() {
    if (widget.onChanged != null) {
      widget.onChanged!(controller!.text);
      if (controller!.text == "```" && !widget.isIssues!) {
        if(widget.handleCodeBlock != null) widget.handleCodeBlock!(true);
        controller!.clear();
        controller!.selection = TextSelection.fromPosition(TextPosition(offset: controller!.text.length));
      }
    }

    if (widget.onMarkupChanged != null) {
      widget.onMarkupChanged!(controller!.markupText);
    }

    if (widget.onSearchChanged != null && _selectedMention?.str != null) {
      final str = _selectedMention!.str!.toLowerCase();

      widget.onSearchChanged!(str[0], str.substring(1));
      final valueSearch = _selectedMention?.str?.toLowerCase().substring(1);
      var result = checkMention(valueSearch);

      final data = filterOption();
      // bool isMentionIssue = checkMentionIssue(data);

      // final RenderBox box = context.findRenderObject() as RenderBox;
      // double heightOptionList = 0.0;
      // double widthOptionList = !widget.isThread && isMentionIssue ? 980 : 320;

      // if(data.length >= 5) heightOptionList = 200.0;
      // else {
      //   if(data.length == 1) heightOptionList = 47.5;
      //   else heightOptionList = (data.length * 45).toDouble();
      // }

      // if(heightOptionList > 0) {
      //   Offset offsetCaret = box.globalToLocal(key.currentState!.editableText!.renderEditable.getOffsetForPosition(
      //     TextPosition(offset: controller!.selection.baseOffset - 1, affinity: controller!.selection.extent.affinity)
      //   ));

      //   double dx = offsetCaret.dx + widthOptionList >= context.size!.width
      //                 ? (context.size!.width/2 - (context.size!.width - widthOptionList))/widthOptionList*2 - (isMentionIssue ? 1 : 0.9)
      //                 : (context.size!.width/2 - offsetCaret.dx)/widthOptionList*2 - (isMentionIssue ? 1 : 0.9);
      //   double dy = 1.1 - offsetCaret.dy/(heightOptionList/2);
      //   alignment = Alignment(dx, dy);
      // }

      setState(() {
        onSelectedMentions(data.length > 0 ? data[0] : {'id': "${widget.id}", 'display': 'all', 'full_name': 'all', 'photo': 'all'}, 0);
        triggerMention = result;
      });
    } else if(triggerMention) {
      setState(() {
        triggerMention = false;
      });
    }
    if (mounted) Provider.of<Auth>(context, listen: false).onChangeIsShowMention(triggerMention);
  }

  //Listen keyevent to autofocus main reply

  checkMention(value) {
    var text = !Utils.checkedTypeEmpty(value) ? "" : value;
    RegExp exp = new RegExp(r"@");
    var matchs = exp.allMatches(text).toList();
    if (matchs.length == 0 ) return true;
    else return false;
  }

  @override
  void initState() {
    final data = mapToAnotation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.afterFirstFrame != null) widget.afterFirstFrame!();
    });
    controller = AnnotationEditingController(data, context, checkMentions, widget.mentions);

    // setup a listener to figure out which suggestions to show based on the trigger
    controller!.addListener(suggestionListerner);

    controller!.addListener(inputListeners);


    super.initState();

    focusNode = FocusNode(onKey: (node, RawKeyEvent keyEvent) {

      if(keyEvent is RawKeyDownEvent) {
        final primaryKeyPressed = Utils.isWinOrLinux() ? keyEvent.isControlPressed : keyEvent.isMetaPressed;
        final isEnterPressed = keyEvent.isKeyPressed(LogicalKeyboardKey.enter) || keyEvent.isKeyPressed(LogicalKeyboardKey.numpadEnter);

        if(Utils.isWinOrLinux()) {
          if(keyEvent.isMetaPressed) return KeyEventResult.handled;
          else if(primaryKeyPressed) {
            if (keyEvent.isKeyPressed(LogicalKeyboardKey.enter) && widget.isIssues!) {
              if (widget.handleUpdateIssues != null) widget.handleUpdateIssues!();
              return KeyEventResult.handled;
            }
          }
        }

        if (!keyEvent.isKeyPressed(LogicalKeyboardKey.arrowDown) && !keyEvent.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
          if (widget.onEdittingText != null) widget.onEdittingText!(false);
        }

        if ((keyEvent.isShiftPressed || keyEvent.isAltPressed)) {
          if(isEnterPressed) {
            if (widget.handleEnterEvent != null) widget.handleEnterEvent!();
          }
        } else if (primaryKeyPressed) {
        if (isEnterPressed && widget.isIssues! && !Utils.isWinOrLinux()) {
            if (widget.handleUpdateIssues != null) widget.handleUpdateIssues!();
          } else if (keyEvent.isKeyPressed(LogicalKeyboardKey.keyV)) {
            handlePasteText();
            return KeyEventResult.handled;
          }
        } else if (isEnterPressed) {
          return handleEnter();
        } else if (keyEvent.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
          if (widget.isShowCommand!) {
            widget.selectArrowCommand!("up");
            return KeyEventResult.handled;
          } else if (isShow && !widget.islastEdited) {
            handleSelectItem('up');
            return KeyEventResult.handled;
          }
        } else if (keyEvent.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
          if (widget.isShowCommand!) {
            widget.selectArrowCommand!("down");
            return KeyEventResult.handled;
          } else if (isShow && !widget.islastEdited) {
            handleSelectItem('down');
            return KeyEventResult.handled;
          }
        } else if (keyEvent.isKeyPressed(LogicalKeyboardKey.backspace)) {
          if (widget.isCodeBlock! && !Utils.checkedTypeEmpty(controller!.text)) {
            if(widget.handleCodeBlock != null) widget.handleCodeBlock!(false);
          }
        } else if (keyEvent.isKeyPressed(LogicalKeyboardKey.escape)) {
          if (widget.setShareMessage != null) {
            widget.setShareMessage!(false);
          }

          if (widget.isUpdate!) {
            widget.setUpdateMessage!(null, false);
            controller!.clear();
          }

          if (Utils.checkedTypeEmpty(widget.isCodeBlock)) {
            if(widget.handleCodeBlock != null) widget.handleCodeBlock!(false);
          }

          if (triggerMention) {
            this.setState(() {
              triggerMention = false;
              _selectedMention = null;
            });
            Provider.of<Auth>(context, listen: false).onChangeIsShowMention(false);

            return widget.isIssues! ? KeyEventResult.handled : KeyEventResult.ignored;
          } else {
            return KeyEventResult.ignored;
          }
        } else if (keyEvent.isKeyPressed(LogicalKeyboardKey.tab)) {
          if (isShow && triggerMention) {
            addMention(currentMention!);
            return KeyEventResult.handled;
          }
        }
      }

      return KeyEventResult.ignored;
    });

    if (widget.controller != null) {
      controller!.text = widget.controller!.text;
    }
  }

  handlePasteText() async{
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    String text = data?.text ?? '';

    final splitSnippet = text.split("\n");
    int lengthString = splitSnippet.length > 12 ? 12 : splitSnippet.length;

    if((text.length > 7500 || lengthString > 12) && widget.handleMessageToAttachments != null) {
      widget.handleMessageToAttachments(text);
    } else {
      key.currentState?.editableText?.pasteText(SelectionChangedCause.keyboard);
    }
  }

  handleEnter() {
    final list = _selectedMention != null
      ? widget.mentions.firstWhere((element) => _selectedMention!.str!.contains(element.trigger))
      : widget.mentions[0];

    if (isShow && list.data.length > 0 && triggerMention) {
      addMention(currentMention!);
      return KeyEventResult.handled;
    } else {
      if (widget.sendMessages != null) {
        widget.sendMessages!();
        return KeyEventResult.handled;
      } else {
        if (widget.handleEnterEvent != null) {
          return widget.handleEnterEvent!();
        }

        return KeyEventResult.ignored;
      }
    }
  }

  void handleSelectItem(key) {
    final data = filterOption();

    if (data.length > 0) {
      if (key == 'up' && data.isNotEmpty) {
        setState(() {
          onSelectedMentions(indexSelectedMention <= 0 ? data[0] : data[indexSelectedMention - 1], indexSelectedMention);
          indexSelectedMention = indexSelectedMention <= 0 ? 0 : indexSelectedMention - 1;
          if (indexSelectedMention >= 0 && indexSelectedMention <= data.length - 5) _controller.jumpTo(index: indexSelectedMention);
        });
      } else if (key == 'down' && data.isNotEmpty) {
        setState(() {
          onSelectedMentions(indexSelectedMention >= data.length - 1 ? data[data.length - 1] : data[indexSelectedMention + 1], indexSelectedMention);
          indexSelectedMention = indexSelectedMention >= data.length - 1 ? data.length - 1 : indexSelectedMention + 1;
          if (indexSelectedMention >= 5 && indexSelectedMention <= data.length - 4) _controller.jumpTo(index: indexSelectedMention);
        });
      }
    }
  }

  @override
  void dispose() {
    controller!.removeListener(suggestionListerner);
    controller!.removeListener(inputListeners);
    controller!.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

    final data = filterOption(filterRequire: true);
    if(oldWidget.id != widget.id) {
      // focusNode!.requestFocus();
      setState(() {
        onSelectedMentions(data.length > 0 ? data[0] : {'id': "${widget.id}", 'display': 'all', 'full_name': 'all', 'photo': 'all'}, 0);
      });
    }

    controller!.mapping = mapToAnotation();
  }

  checkMentionIssue(data) {
    if (data.length > 0 && data[0]["full_name"] != null) {
      return false;
    } else {
      return true;
    }
  }

  int levelMentionRegex(String text) {
    final _vietnamese = 'aâăAÂĂeêEÊoôơOÔƠuưUƯyY';
    final _vietnameseRegex = <RegExp>[
      RegExp(r'à|á|ạ|ả|ã'),
      RegExp(r'ầ|ấ|ậ|ẩ|ẫ'),
      RegExp(r'ằ|ắ|ặ|ẳ|ẵ'),
      RegExp(r'À|Á|Ạ|Ả|Ã'),
      RegExp(r'Ẫ|Ầ|Ấ|Ậ|Ẩ'),
      RegExp(r'Ằ|Ắ|Ặ|Ẳ|Ẵ'),
      RegExp(r'è|é|ẹ|ẻ|ẽ'),
      RegExp(r'ề|ế|ệ|ể|ễ'),
      RegExp(r'È|É|Ẹ|Ẻ|Ẽ'),
      RegExp(r'Ề|Ế|Ệ|Ể|Ễ'),
      RegExp(r'ò|ó|ọ|ỏ|õ'),
      RegExp(r'ồ|ố|ộ|ổ|ỗ'),
      RegExp(r'ờ|ớ|ợ|ở|ỡ'),
      RegExp(r'Ò|Ó|Ọ|Ỏ|Õ'),
      RegExp(r'Ồ|Ố|Ộ|Ổ|Ỗ'),
      RegExp(r'Ờ|Ớ|Ợ|Ở|Ỡ'),
      RegExp(r'ù|ú|ụ|ủ|ũ'),
      RegExp(r'ừ|ứ|ự|ử|ữ'),
      RegExp(r'Ù|Ú|Ụ|Ủ|Ũ'),
      RegExp(r'Ừ|Ứ|Ự|Ử|Ữ'),
      RegExp(r'ỳ|ý|ỵ|ỷ|ỹ'),
      RegExp(r'Ỳ|Ý|Ỵ|Ỷ|Ỹ')
    ];

    var result = text;
    for (var i = 0; i < _vietnamese.length; ++i) {
      result = result.replaceAll(_vietnameseRegex[i], _vietnamese[i]);
    }

    int level = 0;

    if (Utils.unSignVietnamese(text) == text ) {
      level = 1;
    } else {
      if(text == result ) {
        level = 2;
      } else {
        level = 3;
      }
    }

    return level;
  }

  List filterOption ({bool filterRequire = false}) {
    try {
      if (!filterRequire){
        if (_selectedMention == null) return [];
        if (dataFiltered["str"] == _selectedMention!.str) return dataFiltered["data"];
      }

      final list = _selectedMention != null
          ? widget.mentions.firstWhere((element) => _selectedMention!.str!.contains(element.trigger))
          : widget.mentions[0];

      final data = _selectedMention != null ? list.data.where((e) {
        final ele =  Utils.unSignVietnamese(e["full_name"] ?? e["display"] ?? "");
        final str = _selectedMention!.str!
          .replaceAll(RegExp(_pattern), '');

        bool check = ele.contains(Utils.unSignVietnamese(str));
        return check;
      }).toList() : [];

      if (_selectedMention == null  || _selectedMention!.str!.length == 1) return data;
      var fuse = Fuzzy(data, options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: "display",
            getter: (item){
              if (item == null) return "";
              return (Utils.unSignVietnamese((item as Map)["display"]));
            },
            weight: 1
          )
        ]
      ));
      dataFiltered = {
        "str": _selectedMention!.str,
        "data":  fuse.search(_selectedMention == null ? "" : Utils.unSignVietnamese(_selectedMention!.str ?? "")).map((ele) => ele.item).toList()
      };

      String text = _selectedMention!.str != null ? _selectedMention!.str!.substring(1) : '';
      int level = levelMentionRegex(text);

      dataFiltered["data"] = searchMention(data, text, level);

      return dataFiltered["data"];
    } catch (e) {
      return [];
    }
  }

  List searchMention(List data, String text, int level) {
    List dataSearch = [];

    if (level == 1) {
      dataSearch = data;
    } else if (level == 2) {
      dataSearch = data.where((ele) {
        final bool check =  Utils.convertCharacter(ele["display"]).contains(Utils.convertCharacter(text));

        return check;
      }).toList();
    } else if (level == 3) {
      dataSearch = data.where((ele) {
        final bool check =  ele["display"].toLowerCase().contains(text.toLowerCase());

        return check;
      }).toList();
    }

    if(dataSearch.length == 0 && level > 0) {
      dataSearch = searchMention(data, text, level - 1);
    }

    if(dataSearch.length > 1) {
      dataSearch.sort((a, b) {
        return a['display'].length.compareTo(b['display'].length);
      });
    }

    return dataSearch;
  }

  @override
  Widget build(BuildContext context) {
    // Filter the list based on the selection
    final data = filterOption();

    isShow = data.length > 0;

    bool isMentionIssue = checkMentionIssue(data);
    return Container(
      decoration: BoxDecoration(
        color: widget.isCodeBlock! ? widget.isDark! ? Color(0xFF1D2C3B) : Colors.grey[200]! : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: widget.isThread || widget.isKanbanMode ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: 6),
      child: PortalTarget(
        anchor: Aligned(
          follower: alignment ?? Alignment.bottomCenter,
          target: Alignment.topCenter
        ),
        portalFollower: ValueListenableBuilder(
          valueListenable: showSuggestions,
          builder: (BuildContext context, bool show, Widget? child) {
            return show && !widget.hideSuggestionList && isFocus
            ? OptionList(
              isMentionIssue: isMentionIssue,
              isDark: widget.isDark,
              isShow: triggerMention,
              selectMention: currentMention,
              suggestionListDecoration: widget.suggestionListDecoration,
              data: data,
              isExpand: widget.isThread,
              onTap: (value) {
                addMention(value);
                showSuggestions.value = false;
              },
              scrollController: _controller,
            ) : Container();
          },
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if(!widget.isCodeBlock!) ...widget.leading,
            Expanded(
              child: Focus(
                onFocusChange: (value) {
                 this.setState(() {
                    isFocus = value;
                    final selectedTab = Provider.of<User>(context, listen: false).selectedTab;
                    if (value && selectedTab == "channel" && !widget.isIssues!) {
                      if (widget.isThread) FocusInputStream.instance.focusToThread();
                      else FocusInputStream.instance.focusToMessage();
                    }
                  });
                  var isFocusApp = Provider.of<Auth>(context, listen: false).onFocusApp;
                  if (oldFocusApp != isFocusApp) {
                    if (isFocusApp) {
                      controller!.value = controller!.value.copyWith(
                        selection: TextSelection.collapsed(
                          offset: lastCursorPosition,
                        )
                      );
                    } else {
                      final selection = controller!.selection;
                      int offset = selection.baseOffset;
                      lastCursorPosition = offset;
                    }
                    oldFocusApp = isFocusApp;
                  }
                  if (widget.onFocusChange != null ) widget.onFocusChange!(value);
                },
                child: FocusInputBoxManager(
                  focusNode: focusNode,
                  isThread: widget.isThread,
                  child: CustomTextField(
                    key: key,
                    // cursorHeight: widget.cursorHeight,
                    focusNode: focusNode,
                    textAlignVertical: TextAlignVertical.center,
                    maxLines: 22,
                    minLines: widget.minLines ?? (widget.isIssues! && !widget.isViewThread && !widget.isKanbanMode ? 22 : 1),
                    maxLength: widget.maxLength,
                    keyboardType: TextInputType.multiline,
                    keyboardAppearance: widget.keyboardAppearance,
                    textInputAction: widget.textInputAction,
                    textCapitalization: widget.textCapitalization,
                    style: widget.style,
                    textAlign: widget.textAlign,
                    textDirection: widget.textDirection,
                    readOnly: widget.readOnly,
                    showCursor: widget.showCursor,
                    autofocus: widget.autofocus,
                    autocorrect: widget.autocorrect,
                    cursorColor: widget.cursorColor,
                    cursorRadius: widget.cursorRadius,
                    cursorWidth: widget.cursorWidth,
                    buildCounter: widget.buildCounter,
                    autofillHints: widget.autofillHints,
                    decoration: widget.decoration,
                    expands: widget.expands,
                    onEditingComplete: widget.onEditingComplete,
                    onTap: widget.onTap,
                    enabled: widget.enabled,
                    enableInteractiveSelection: widget.enableInteractiveSelection,
                    enableSuggestions: widget.enableSuggestions,
                    scrollPadding: widget.scrollPadding,
                    scrollPhysics: widget.scrollPhysics,
                    controller: controller,
                    scrollController: scrollController,
                  ),
                )
              ),
            ),
            ...widget.trailing,
          ],
        ),
      ),
    );
  }
}