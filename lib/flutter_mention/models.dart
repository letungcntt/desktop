part of flutter_mentions;

enum SuggestionPosition { Top, Bottom }

class LengthMap {
  LengthMap({this.start, this.end, this.str});

  String? str;
  int? start;
  int? end;
}

class Mention {
  Mention({
    this.data = const [],
    this.style,
    this.trigger,
    this.matchAll = false,
    this.suggestionBuilder,
    this.disableMarkup = false,
    this.markupBuilder,
  });

  /// A single character that will be used to trigger the suggestions.
  final trigger;

  /// List of Map to represent the suggestions shown to the user
  ///
  /// You need to provide two properties `id` & `display` both are [String]
  /// You can also have any custom properties as you like to build custom suggestion
  /// widget.
  final data;

  /// Style for the mention item in Input.
  final style;

  /// Should every non-suggestion with the trigger character be matched
  final matchAll;

  /// Should the markup generation be disabled for this Mention Item.
  final disableMarkup;

  /// Build Custom suggestion widget using this builder.
  final suggestionBuilder;

  /// Allows to set custom markup for the mentioned item.
  final markupBuilder;
}

class Annotation {
  Annotation({
    this.style,
    this.id,
    this.display,
    this.trigger,
    this.disableMarkup,
    this.markupBuilder,
  });

  var style;
  var id;
  var display;
  var trigger;
  var disableMarkup;
  var markupBuilder;
}
