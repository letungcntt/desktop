// ignore_for_file: body_might_complete_normally_nullable

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:html/parser.dart' show parse;
import 'package:workcake/providers/providers.dart';
import 'package:http/http.dart' as http;

abstract class InfoBase {
  late DateTime _timeout;
}

/// Web Information
class WebInfo extends InfoBase {
  var title;
  var icon;
  var description;
  var image;
  var redirectUrl;

  WebInfo({
    this.title,
    this.icon,
    this.description,
    this.image,
    this.redirectUrl,
  });
}

/// Image Information
class WebImageInfo extends InfoBase {
  var image;

  WebImageInfo({this.image});
}

/// Video Information
class WebVideoInfo extends WebImageInfo {
  WebVideoInfo({var image}) : super(image: image);
}

/// Web analyzer
class WebAnalyzer {
  static final Map<String, InfoBase> _map = {};
  static final RegExp _bodyReg = RegExp(r"<body[^>]*>([\s\S]*?)<\/body>", caseSensitive: false);
  static final RegExp _htmlReg = RegExp(r"(<head[^>]*>([\s\S]*?)<\/head>)|(<script[^>]*>([\s\S]*?)<\/script>)|(<style[^>]*>([\s\S]*?)<\/style>)|(<[^>]+>)|(<link[^>]*>([\s\S]*?)<\/link>)|(<[^>]+>)", caseSensitive: false);
  static final RegExp _metaReg = RegExp(r"<(meta|link)(.*?)\/?>|<title(.*?)</title>", caseSensitive: false, dotAll: true);
  static final RegExp _titleReg = RegExp("(title|icon|description|image)", caseSensitive: false);
  static final RegExp _lineReg = RegExp(r"[\n\r]|&nbsp;|&gt;");
  static final RegExp _spaceReg = RegExp(r"\s+");

  /// Is it an empty string
  static bool isNotEmpty(String? str) {
    return str != null && str.isNotEmpty;
  }

  /// Get web information
  /// return [InfoBase]
  static InfoBase? getInfoFromCache(String url) {
    try {
      var info;
      info = _map[url]!;
      if (info != null) {
        if (!info._timeout.isAfter(DateTime.now())) {
          _map.remove(url);
        }
      }
      return info;
    } catch (e) {
      return null;
    }
  }

  /// Get web information
  /// return [InfoBase]
  static Future<InfoBase?> getInfo(String url,
      {Duration cache = const Duration(hours: 24),
      bool multimedia = true,
      bool useMultithread = false}) async {
    // final start = DateTime.now();

    var info = getInfoFromCache(url);
    if (info != null) {
      return info;
    }
    try {
      if (useMultithread)
        info = await _getInfoByIsolate(url, multimedia);
      else
        info = (await _getInfo(url, multimedia))!;

      info._timeout = DateTime.now().add(cache);
      _map[url] = info;
    } catch (e) {
      info = WebInfo();
      info._timeout = DateTime.now().add(cache);
      _map[url] = info;
    }
    return info;
  }

  static Future<InfoBase?> _getInfo(String url, bool multimedia) async {
    var response = await _requestUrl(url);

    if (response != null) {
      return _getWebInfo(response, url, multimedia);
    } else
      return null;
  }

  static Future<InfoBase> _getInfoByIsolate(String url, bool multimedia) async {
    final sender = ReceivePort();
    final Isolate isolate = await Isolate.spawn(_isolate, sender.sendPort);
    final sendPort = await sender.first as SendPort;
    final answer = ReceivePort();

    sendPort.send([answer.sendPort, url, multimedia]);
    final List<String> res = await answer.first;

    var info;
    if (res[0] == "0") {
      info = WebInfo(
          title: res[1], description: res[2], icon: res[3], image: res[4]);
    } else if (res[0] == "1") {
      info = WebVideoInfo(image: res[1]);
    } else if (res[0] == "2") {
      info = WebImageInfo(image: res[1]);
    }

    sender.close();
    answer.close();
    isolate.kill(priority: Isolate.immediate);

    return info;
  }

  static void _isolate(SendPort sendPort) {
    final port = ReceivePort();
    sendPort.send(port.sendPort);
    port.listen((message) async {
      final SendPort sender = message[0];
      var url = message[1];
      final bool multimedia = message[2];
      final info = await _getInfo(url, multimedia);
      if (info is WebInfo) {
        sender.send(["0", info.title, info.description, info.icon, info.image]);
      } else if (info is WebVideoInfo) {
        sender.send(["1", info.image]);
      } else if (info is WebImageInfo) {
        sender.send(["2", info.image]);
      } else {
        sender.send(null);
      }
      port.close();
    });
  }

  static final Map<String, String> _cookies = {
    "weibo.com":
        "YF-Page-G0=02467fca7cf40a590c28b8459d93fb95|1596707497|1596707497; SUB=_2AkMod12Af8NxqwJRmf8WxGjna49_ygnEieKeK6xbJRMxHRl-yT9kqlcftRB6A_dzb7xq29tqJiOUtDsy806R_ZoEGgwS; SUBP=0033WrSXqPxfM72-Ws9jqgMF55529P9D9W59fYdi4BXCzHNAH7GabuIJ"
  };

  static bool _certificateCheck(X509Certificate cert, String host, int port) =>
      true;

  static Future<Response?> _requestUrl(String url,
      {int count = 0, var cookie, useDesktopAgent = true}) async {
    if (url.contains("m.toutiaoimg.cn")) useDesktopAgent = false;
    var res;
    final uri = Uri.parse(url);
    final ioClient = HttpClient()..badCertificateCallback = _certificateCheck;
    final client = IOClient(ioClient);
    final request = Request('GET', uri)
      ..followRedirects = false
      ..headers["User-Agent"] = useDesktopAgent
          ? "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.125 Safari/537.36"
          : "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1"
      ..headers["cache-control"] = "no-cache"
      ..headers["Cookie"] = cookie ?? _cookies[uri.host] ?? ""
      ..headers["accept"] = "*/*";
    // print(request.headers);
    final stream = await client.send(request);

    if (stream.statusCode == HttpStatus.movedTemporarily || stream.statusCode == HttpStatus.movedPermanently) {
      if (stream.isRedirect && count < 6) {
        var location = stream.headers['location'];
        if (location != null) {
          url = location;
          if (location.startsWith("/")) {
            url = uri.origin + location;
          }
        }
        if (stream.headers['set-cookie'] != null) {
          cookie = stream.headers['set-cookie'];
        }
        count++;
        client.close();
        // print("Redirect ====> $url");
        return _requestUrl(url, count: count, cookie: cookie);
      }
    } else if (stream.statusCode == HttpStatus.ok) {
      res = await Response.fromStream(stream);
      if (uri.host == "m.tb.cn") {
        final match = RegExp(r"var url = \'(.*)\'").firstMatch(res.body);
        if (match != null) {
          final newUrl = match.group(1);
          if (newUrl != null) {
            return _requestUrl(newUrl, count: count, cookie: cookie);
          }
        }
      }
    }
    client.close();
    return res;
  }

  static Future<InfoBase?> _getWebInfo(var response, String url, bool multimedia) async {
    if (response != null) {
      if (response.statusCode == HttpStatus.ok) {
        String? html;
        try {
          html = const Utf8Decoder().convert(response.bodyBytes);
        } catch (e) {
          try {
            html = response.bodyBytes;
          } catch (e) {
            print("Web page resolution failure from:$url Error:$e");
          }
        }

        if (html == null) {
          print("Web page resolution failure from:$url");
          return null;
        }

        // Improved performance
        // final start = DateTime.now();
        final headHtml = _getHeadHtml(html);
        final document = parse(headHtml);
        // print("dom cost ${DateTime.now().difference(start).inMilliseconds}");
        final uri = Uri.parse(url);

        // get image or video
        if (multimedia) {
          final gif = _analyzeGif(document, uri);
          if (gif != null) return gif;

          final video = _analyzeVideo(document, uri);
          if (video != null) return video;
        }

        String? title = _analyzeTitle(document);
        String? description =
            _analyzeDescription(document, html)?.replaceAll(r"\x0a", " ");
        if (!isNotEmpty(title)) {
          title = description;
          description = null;
        }

        final info = WebInfo(
          title: title,
          icon: _analyzeIcon(document, uri),
          description: description,
          image: _analyzeImage(document, uri),
          redirectUrl: response.request.url.toString(),
        );
        return info;
      }
    }

    return null;
  }

  static String _getHeadHtml(String html) {
    html = html.replaceFirst(_bodyReg, "<body></body>");
    final matchs = _metaReg.allMatches(html);
    var head = StringBuffer("<html><head>");
    matchs.forEach((element) {
      var str = element.group(0);
      if (str!.contains(_titleReg)) head.writeln(str);
    });
    head.writeln("</head></html>");
    return head.toString();
  }

  static InfoBase? _analyzeGif( document, Uri uri) {
    try {
       if (_getMetaContent(document, "property", "og:image:type") ==  null)
    if (_getMetaContent(document, "property", "og:image:type") == "image/gif") {
      final gif = _getMetaContent(document, "property", "og:image");
      if (gif != null) return WebImageInfo(image: _handleUrl(uri, gif));
    }
    return null;
    } catch (e) {
      return null;
    }

  }

  static InfoBase? _analyzeVideo(document, Uri uri) {
    final video = _getMetaContent(document, "property", "og:video");
    if (video != null) return WebVideoInfo(image: _handleUrl(uri, video));
    return null;
  }

  static String? _getMetaContent(
    var document, String property, String propertyValue) {
    final meta = document.head.getElementsByTagName("meta");
    final index  =  meta.indexWhere((e) => e.attributes[property] == propertyValue);
    final ele = index == -1 ?  null : meta[index];
    if (ele != null) return ele.attributes["content"]?.trim();
    return null;
  }

  static String _analyzeTitle(document) {
    final title = _getMetaContent(document, "property", "og:title");
    if (title != null) return title;
    final list = document.head.getElementsByTagName("title");

    if (list.isNotEmpty) {
      final tagTitle = list.first.text;
      if (tagTitle != null) return tagTitle.trim();
    }
    return "";
  }

  static String? _analyzeDescription(document, String html) {
    final desc = _getMetaContent(document, "property", "og:description");
    if (desc != null) return desc;

    final description = _getMetaContent(document, "name", "description") ??
        _getMetaContent(document, "name", "Description");
    if (description == null) return null;

    if (!isNotEmpty(description)) {
      // final DateTime start = DateTime.now();
      String body = html.replaceAll(_htmlReg, "");
      body = body.trim().replaceAll(_lineReg, " ").replaceAll(_spaceReg, " ");
      if (body.length > 300) {
        body = body.substring(0, 300);
      }
      // print("html cost ${DateTime.now().difference(start).inMilliseconds}");
      return body;
    }
    return description;
  }

  static String? _analyzeIcon(document, Uri uri) {
    final meta = document.head.getElementsByTagName("link");
    String icon = "";
    var metaIcon;
    // get icon first
    var indexMetaIcon = meta.indexWhere((e) {
      final rel = (e.attributes["rel"] ?? "").toLowerCase();
      if (rel == "icon") {
        icon = e.attributes["href"];
        if (!icon.toLowerCase().contains(".svg")) {
          return true;
        }
      }
      return false;
    });

    if (indexMetaIcon != -1) metaIcon =  meta[indexMetaIcon];
    else {
      indexMetaIcon =  meta.indexWhere((e) {
      final rel = (e.attributes["rel"] ?? "").toLowerCase();
        if (rel == "shortcut icon") {
          icon = e.attributes["href"];
          if (!icon.toLowerCase().contains(".svg")) {
            return true;
          }
        }
        return false;
      });
       if (indexMetaIcon != -1) metaIcon =  meta[indexMetaIcon];
    }

    if (metaIcon != null) {
      icon = metaIcon.attributes["href"];
    } else {
      return null;
    }

    return _handleUrl(uri, icon);
  }

  static String? _analyzeImage(document, Uri uri) {
    final image = _getMetaContent(document, "property", "og:image");
    if (image == null) return null;
    return _handleUrl(uri, image);
  }

  static String _handleUrl(Uri uri, String source) {
    if (isNotEmpty(source) && !source.startsWith("http")) {
      if (source.startsWith("//")) {
        source = "${uri.scheme}:$source";
      } else {
        if (source.startsWith("/")) {
          source = "${uri.origin}$source";
        } else {
          source = "${uri.origin}/$source";
        }
      }
    }
    return source;
  }
}

class LinkPreview extends StatefulWidget {
  const LinkPreview({
    Key? key,
    @required this.url,
  }) : super(key: key);

  /// Web address, HTTP and HTTPS support
  final url;

  @override
  _LinkPreviewState createState() => _LinkPreviewState();
}

class _LinkPreviewState extends State<LinkPreview> {

  var _info;
  bool isExpanded = false;
  bool validImage = false;

   @override
   void initState() {
    _getInfo();
    super.initState();
  }

  Future<void> _getInfo() async {
    if (widget.url.trim().startsWith("http")) {
      _info = await WebAnalyzer.getInfo(
        widget.url.trim(),
      );
      if (_info.image != null) validateImageUrl(_info.image);
      if (mounted) setState(() {});
    } else {
      print("Links don't start with http or https from : ${widget.url.trim()}");
    }
  }

  @override
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() {
        _info = null;
      });
      _getInfo();}
  }

  bool loadedImage = false;

  validateImageUrl(url) async {
    final response = await http.get(Uri.parse(url));
    String type = Work.checkTypeFile(response.bodyBytes.sublist(0, 10));
    if (!mounted) return;
    this.setState(() {
      validImage = type.contains("png") || type.contains("jpg");
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context);
    final isDark = auth.theme == ThemeType.DARK;
    var webInfo = _info;
    return Container(
      margin: EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            width: 3,
            color: isDark ? Color(0xFF61616) : Color(0xFFe0e0e0)
          )
        )
      ),
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        children: [
          Container(
            constraints: BoxConstraints(minHeight: 100),
            width: 100,
            child: loadedImage ? ExtendedImage.network(
              "https://statics.pancake.vn/panchat-prod/2021/9/14/904ef09383d868b77e6304953370e52b256f1937.png",
              cacheHeight: 200,
            ) : ExtendedImage.network(
              (_info is WebInfo && webInfo.image != null && WebAnalyzer.isNotEmpty(webInfo.image) && validImage)
                ? webInfo.image
                : "https://statics.pancake.vn/panchat-prod/2021/9/14/904ef09383d868b77e6304953370e52b256f1937.png",
              fit: BoxFit.cover,
              cacheHeight: 200,
              repeat: ImageRepeat.repeat,
              cache: true,
              filterQuality: FilterQuality.medium,
              retries: 0,
              isAntiAlias: true,
              cacheMaxAge: Duration(days: 10),
              loadStateChanged: (ExtendedImageState state) {
                if (state.extendedImageLoadState == LoadState.loading) {
                  return Container(
                    height: 100,
                    child: ExtendedImage.network(
                      "https://statics.pancake.vn/panchat-prod/2021/9/14/904ef09383d868b77e6304953370e52b256f1937.png",
                      cacheHeight: 100,
                      repeat: ImageRepeat.repeat,
                      cache: true,
                      filterQuality: FilterQuality.medium,
                      retries: 0,
                      cacheMaxAge: Duration(days: 10),
                      isAntiAlias: true
                    ),
                  );
                }
                if (state.extendedImageLoadState == LoadState.failed) {
                  loadedImage = true;
                  return ExtendedImage.network(
                    "https://statics.pancake.vn/panchat-prod/2021/9/14/904ef09383d868b77e6304953370e52b256f1937.png",
                    cacheHeight: 100,
                    repeat: ImageRepeat.repeat,
                    cache: true,
                    filterQuality: FilterQuality.medium,
                    retries: 0,
                    cacheMaxAge: Duration(days: 10),
                    isAntiAlias: true
                  );
                }
              }
            )
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 18,
                      child: ExtendedImage.network(
                        _info is WebInfo && webInfo.icon != "" && webInfo.icon != null
                            ? webInfo.icon
                            : "",
                        fit: BoxFit.cover,
                        cacheWidth: 30,
                        repeat: ImageRepeat.repeat,
                        cache: true,
                        filterQuality: FilterQuality.low,
                        retries: 0,
                        isAntiAlias: true,
                        cacheMaxAge: Duration(days: 10),
                        loadStateChanged: (ExtendedImageState state) {
                          if (state.extendedImageLoadState == LoadState.loading) {
                            return Container(
                              width: 18,
                            );
                          } else if (state.extendedImageLoadState == LoadState.failed) {
                            return Container(width: 18);
                          }
                        }
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        child: Text(
                          (_info is WebInfo && WebAnalyzer.isNotEmpty(webInfo.title)) ? webInfo.title : "No title",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Container(
                  margin: EdgeInsets.only(left: 23),
                  height: 50,
                  constraints: BoxConstraints(
                    maxWidth: 600,
                  ),
                  child: Text(
                    (_info is WebInfo && webInfo.description != null && WebAnalyzer.isNotEmpty(webInfo.description))
                      ? webInfo.description
                      : "No description",
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]
            ),
          ),
        ],
      )
    );
  }
}