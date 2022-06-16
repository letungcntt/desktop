import 'package:flutter/material.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:flutter_highlighter/themes/atom-one-light.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:simple_tooltip/simple_tooltip.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_highlight_view.dart';
import 'package:workcake/components/widget_text.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/models/models.dart';

class TextFile extends StatefulWidget {
  TextFile({
    Key? key,
    required this.att,
  }) : super(key: key);

  final att;

  @override
  _TextFileState createState() => _TextFileState();
}

class _TextFileState extends State<TextFile> {
  String previewText = '';
  String renderText = '';
  bool isExpanded = false;
  String language = '';
  String fullText = '';

  @override
  void initState() {
    final att = widget.att;

    language = Utils.getLanguageFile(att['mime_type'].toLowerCase());

    final List<String> splitSnippet = att['preview'] != null ? att['preview'].split('\n') : [];

    previewText =  splitSnippet.length > 5 ? splitSnippet.sublist(0, 5).join('\n').trimRight() : att['preview'].trimRight();
    renderText = previewText;

    Utils.onRenderSnippet(att['content_url'], keyEncrypt: att["key_encrypt"]).then((value) {
      fullText = value;
    });

    super.initState();
  }

  @override
  void didUpdateWidget(covariant TextFile oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  onShowFile(att) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    showDialog(
      context: context,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              backgroundColor: isDark ? Color(0xff1E1E1E) : Color(0xffDBDBDB),
              content: Container(
                height: constraints.maxHeight*0.85,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Theme.of(context).dividerColor)
                        )
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              att['name'],
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.grey[800]
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ListAction(
                                action: 'Download file',
                                isDark: isDark,
                                child: IconButton(
                                  hoverColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onPressed: () {
                                    final url = att['content_url'];
                                    Provider.of<Work>(context, listen: false).addTaskDownload({'content_url': url, 'name': att['name'],  "key_encrypt": att["key_encrypt"],});
                                    Navigator.pop(context);
                                  },
                                  icon: Icon(
                                    PhosphorIcons.downloadSimple,
                                    size: 20.0,
                                    color: isDark ? Colors.white70 : Colors.grey[800],
                                  )
                                ),
                              ),
                              SizedBox(width: 4),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  PhosphorIcons.xCircle, size: 24,
                                  color: isDark ? Colors.white70 : Colors.grey[800],
                                ),
                              )
                            ],
                          )
                        ],
                      )
                    ),
                    SingleChildScrollView(
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight*0.85 - 60,
                          minHeight: 300
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: CustomHighlightView(
                          fullText,
                          language: language,
                          backgroundColor: isDark ? Color(0xff1E1E1E) : Color(0xffDBDBDB),
                          theme: MediaQueryData.fromWindow(WidgetsBinding.instance.window)
                            .platformBrightness == Brightness.dark
                            ? atomOneLightTheme
                            : atomOneDarkTheme,
                          padding: const EdgeInsets.all(8),
                          textStyle: GoogleFonts.robotoMono(
                            color: isDark ? Colors.white70 : Colors.grey[800],
                            fontSize: 14
                          ),
                          isIssue: false,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final att = widget.att;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isDark ? Color(0xff1E1E1E) : Color(0xffDBDBDB)
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: language != 'txt' ? CustomHighlightView(
              renderText,
              language: language,
              backgroundColor: isDark ? Color(0xff1E1E1E) : Color(0xffDBDBDB),
              theme: MediaQueryData.fromWindow(WidgetsBinding.instance.window)
                  .platformBrightness == Brightness.dark
                  ? atomOneLightTheme
                  : atomOneDarkTheme,
              padding: const EdgeInsets.all(8),
              textStyle: GoogleFonts.robotoMono(color: isDark ? Colors.white70 : Colors.grey[800]),
            ) : RichTextWidget(
            TextSpan(
              text: renderText,
              style: TextStyle(
                  fontWeight: FontWeight.w400, fontSize: 14,height: 1.57,
                  fontFamily: 'Menlo',
                  color: isDark ? Color(0xffEAE8E8) : Color(0xff3D3D3D)
                )
              ),
              isDark: isDark,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor)
              )
            ),
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                ListAction(
                  action: '',
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        isExpanded = !isExpanded;
                        renderText = isExpanded ? att['preview'] : previewText;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      width: 88,
                      child: Row(
                        children: [
                          Icon(
                            isExpanded ? PhosphorIcons.caretUp : PhosphorIcons.caretRight,
                            color: isDark ? Colors.white70 : Colors.grey[800],
                            size: 18,
                          ),
                          Text(
                            isExpanded ? ' Collapse' : ' Expand',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.grey[800],
                              fontSize: 14
                            )
                          )
                        ],
                      ),
                    ),
                  ),
                  isDark: isDark,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListAction(
                    action: 'View whole file',
                    isDark: isDark,
                    child: IconButton(
                      onPressed: () => fullText.length <= 50000 ? onShowFile(att) : launch(att['content_url']),
                      padding: const EdgeInsets.all(4),
                      icon: Icon(
                        PhosphorIcons.arrowsOutSimple,
                        color: isDark ? Colors.white70 : Colors.grey[800],
                        size: 18,
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListAction(
                    action: 'Download file',
                    isDark: isDark,
                    child: IconButton(
                      onPressed: () {
                        final url = att['content_url'];
                        Provider.of<Work>(context, listen: false).addTaskDownload({'content_url': url, 'name': att['name'],  "key_encrypt": att["key_encrypt"],});
                      },
                      padding: const EdgeInsets.all(4),
                      icon: Icon(
                        PhosphorIcons.downloadSimple,
                        size: 18.0,
                        color: isDark ? Colors.white70 : Colors.grey[800],
                      )
                    ),
                  ),
                ),
                // const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text.rich(
                      TextSpan(
                        text: att['name'],
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[800],
                          fontSize: 13
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ListAction extends StatefulWidget {
  ListAction({
    Key? key,
    required this.action,
    required this.child,
    required this.isDark,
    this.colorHover,
    this.arrowTipDistance,
    this.tooltipDirection,
    this.isRound = false,
    this.radius = 2.0
  }) : super(key: key);

  final Widget child;
  final String action;
  final bool isDark;
  final Color? colorHover;
  final double? arrowTipDistance;
  final TooltipDirection? tooltipDirection;
  final bool isRound;
  final double radius;

  @override
  _ListActionState createState() => _ListActionState();
}

class _ListActionState extends State<ListAction> {
  bool isShow = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return SimpleTooltip(
      arrowTipDistance: widget.arrowTipDistance ?? -2.5,
      tooltipDirection: widget.tooltipDirection ?? TooltipDirection.down,
      animationDuration: Duration(milliseconds: 100),
      borderColor: isDark ? Color(0xFF262626) :Color(0xFFb5b5b5),
      borderWidth: 0.5,
      borderRadius: 5,
      backgroundColor: isDark ? Palette.backgroundTheardDark  : Palette.backgroundTheardLight,
      arrowLength:  6,
      arrowBaseWidth: 6.0,
      ballonPadding: EdgeInsets.zero,
      child: HoverItem(
        colorHover: widget.colorHover ?? Palette.hoverColorDefault,
        child: widget.child,
        isRound: widget.isRound, radius: widget.radius,
        onHover: () => setState(() => isShow = true),
        onExit: () => setState(() => isShow = false),
      ),
      content: Material(
        child: Text(widget.action)
      ),
      show: (widget.action != '') ? isShow : false
    );
  }
}
