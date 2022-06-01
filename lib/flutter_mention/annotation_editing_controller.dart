part of flutter_mentions;

/// A custom implementation of [TextEditingController] to support @ mention or other
/// trigger based mentions.
class AnnotationEditingController extends TextEditingController {
  Map<String, Annotation> _mapping;
  BuildContext context;
  Function parseMention;
  List mentions;
  var _markText = "";

  // Generate the Regex pattern for matching all the suggestions in one.
  AnnotationEditingController(this._mapping, this.context, this.parseMention, this.mentions);

  /// Can be used to get the markup from the controller directly.
  String get markupText {
    return _markText;
  }

  Map<String, Annotation> get mapping {
    return _mapping;
  }

  set mapping(Map<String, Annotation> _mapping) {
    this._mapping = _mapping;

  }

  setMarkText(String markText){
    _markText = markText;
  }

  @override
  TextSpan buildTextSpan({required context, TextStyle? style, bool? withComposing}) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    var children = <InlineSpan>[];
    var parse = parseMention(_markText);
    if (parse["success"] == false) children.add(TextSpan(text: _markText, style: style));
    else {
      for (var i = 0; i < parse["data"].length; i++) {
        var indexMention = mentions.indexWhere((element) => element.trigger == parse["data"][i]["trigger"]);
        var styleMention  = indexMention == -1 ? null : mentions[indexMention].style;
        children.add(
          TextSpan(
            text: parse["data"][i]["type"] == "text" ? parse["data"][i]["value"] : "${parse["data"][i]["trigger"]}${parse["data"][i]["name"]}",
            style: parse["data"][i]["type"] == "text" ? style : style!.merge(styleMention).merge(TextStyle(color: isDark ? Palette.calendulaGold : Palette.dayBlue)),
          )
        );
      }
    }

    return TextSpan(style: style, children: children);
  }
}