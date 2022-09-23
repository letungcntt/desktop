// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html_core.dart';
import 'package:html/parser.dart' as HTMLParse;
import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/draggable_scrollbar.dart';
import 'package:workcake/components/widget_text.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/flutter_mention/custom_selection.dart';
import 'package:workcake/providers/providers.dart';
import 'package:workcake/workspaces/apps/zimbra/config.dart';
import 'package:workcake/workspaces/apps/zimbra/forward.dart';
import 'package:workcake/workspaces/apps/zimbra/reply.dart';
import 'package:workcake/workspaces/apps/zimbra/service.dart';
import 'package:xml/xml.dart';


class ConvDetailZimbra extends StatefulWidget {
final MailZimbra conv;
final int workspaceId;
const ConvDetailZimbra({Key? key, required this.conv, required this.workspaceId}) : super(key: key);

@override
State<ConvDetailZimbra> createState() => ConvDetailZimbraState();
}

class ConvDetailZimbraState extends State<ConvDetailZimbra> {
  MailZimbra? current;
  ScrollController scrollController = ScrollController();
  @override
  void initState(){
    super.initState();
    getConv();
  }

  getConv() async {
    try {
      current = await ServiceZimbra.getDetailConv(widget.conv, widget.workspaceId);
      setState(() {

      });
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    if (current == null) return Container();
    bool isDark = false && Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return CustomSelectionArea(
      child: Container(
        // subject
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // render message
            Expanded(
              child: DraggableScrollbar.rrect(
                controller: scrollController,
                onChanged: (bool value) {  },
                heightScrollThumb: 56,
                backgroundColor: Colors.grey[600],
                scrollbarTimeToFade: const Duration(seconds: 1),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
                  child: SingleChildScrollView(
                    reverse: true,
                    controller: scrollController,
                    child: Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width - 100,
                          margin: EdgeInsets.symmetric(vertical: 12),
                          child: RichTextWidget(
                            TextSpan(
                              text: current!.subject != "" ? current!.subject : "<No subject>",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 20,
                                color: isDark ? Color(0xFFffffff): Color(0xFF5e5e5e)
                              )
                            )
                          ),
                        ),
                        Column(
                          children: (widget.conv.m.reversed).map<Widget>((m) {
                            return RenderMessageConv(messConv: m, workspaceId: widget.workspaceId, conv: widget.conv);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}


class RenderMessageConv extends StatefulWidget {
  final MessageConvZimbra messConv;
  final int workspaceId;
  final MailZimbra? conv;
  const RenderMessageConv({Key? key, required this.messConv, required this.workspaceId, this.conv}) : super(key: key);

  @override
  State<RenderMessageConv> createState() => _RenderMessageConvState();
}

class _RenderMessageConvState extends State<RenderMessageConv> {
  bool showQuote = false;
  bool viewDefault = false;

  Widget renderMP(List<MessagePartConvZimbra> mps, MessageConvZimbra m){
    try {

      Widget renderFiles(MessagePartConvZimbra mp){
        // get all files
        var mpFiles = (mp.mps ?? []).where((mpe) => Utils.checkedTypeEmpty(mpe.filename)).toList();
        return Container(
          child: Wrap(
            children: mpFiles.map<Widget>((mpe) => Container(
              margin: EdgeInsets.all(4),
              child: GestureDetector(
                onTap: (){
                  Provider.of<Work>(context, listen: false).addTaskDownload({
                    "name": mpe.filename,
                    "content_url": "https://mail.pancake.vn/service/home/~/?loc=en_US&id=${m.id}&part=${mpe.part}&auth=qp&zauthtoken=${ConfigZimbra.instance.currentAccountZimbra!.authToken}"
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(top:  8),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    border: Border.all(width: 1, color: Color(0xFF5e5e5e))
                  ),
                  child: Text(mpe.filename ?? "", style: TextStyle(fontSize: 11, color: Color(0xFFa6a6a6))),
                ),
              ),
            ),).toList(),
          ),
        );
      }

      Widget renderText(String content, String type){

        if (content == "") return Container();
        if (type.contains("plain")) {
          String contentText = content.split(RegExp(r'----- Original Message -----|----- Forward Message -----')).first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(contentText, style: TextStyle(fontSize: 14, color: Color(0xFF000000))),
              !showQuote ? TextWidget(contentText, style: TextStyle(fontSize: 14, color: Color(0xFF000000))) : TextWidget(content, style: TextStyle(fontSize: 14, color: Color(0xFF000000)))
            ],
          );
        }

        bool isDark = false && Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
        if (!showQuote){
          // trong truong hop co nhieu html, thi chi lay html dau tien
          bool hasMany = content.contains("</html><html>");
          if (hasMany) content =  content.split("</html><html>")[0] + "</html>";
          var document = HTMLParse.parse(content);
          // xoa cac nodes bi qouted
          if (document.body!.nodes.length > 1) {
            var index  = document.body!.nodes.indexWhere((ele) => ["appendonsend"].contains((ele).attributes["id"]) || ["gmail_quote"].contains((ele).attributes["class"]));
            if (index != -1){
              document.body!.nodes.removeRange(index,  document.body!.nodes.length);
            }
          }

          // xoa cac nodes bi qouted trong nodes[0]
          if (document.body!.nodes.length > 0) {
            // remove aall id = "marker || zwchr"(default zimbra)
            int index = document.body!.nodes[0].nodes.indexWhere((ele) => ["marker", "zwchr", "zwchr\\"].contains((ele).attributes["id"]));
            if (index != -1){
              document.body!.nodes[0].nodes.removeRange(index,  document.body!.nodes[0].nodes.length);
            }
          }
          content = document.body!.outerHtml;
        }

        // tam fix voi height la pt
        RegExp heightByP = RegExp(r'height\:[0-9\.\s]{0,}p[t]');
        content = content.replaceAllMapped(heightByP, (match){
          return  (match.group(0) ?? "").split("p").first;
        });
        return HtmlWidget(content,
            // render a custom widget
            onTapUrl: (String url) {
              launch(url);
              return true;
            },
            renderTextCustom: viewDefault ? null : (InlineSpan text) {
              if (text.toPlainText().trim() == "") return Text("");
              if(text is TextSpan) {
                text.children?.removeWhere((element) => !(element is TextSpan));
                for(int i = 0; i < (text.children ?? []).length; i++){
                  text.children![i].style?.apply(color: Color(0xFFffffff));
                }
                text.style?.apply(backgroundColor: null, color: Color(0xFFffffff));
                return RichTextWidget(
                  text,
                );
              }
              return Text.rich(text);
            },
            buildAsync: true,
            textStyle: TextStyle(
              fontSize: 14,
              height: showQuote
                ? viewDefault ? 1.000001 : 1.000002
                : viewDefault ? 1.000003 : 1.000003,
                color: isDark ? Color(0xFFffffff) : Color(0xFF5e5e5e)),
            customStylesBuilder: (element) {
              if (element.classes.contains('gmail_quote') || element.classes.contains('gmail_attr')) {
                return {'margin-left': '20px', 'padding-left': '10px'};
              }
              if ((element.localName ?? "").contains('')) {
                return {"font-size": "14", "color": "#000000"};
              }
              return null;
            },
            customWidgetBuilder: (element) {
              if (element.localName == "div" && element.children.length == 0){
                if (element.text.trim() == "") return Container();
              }
              if (element.localName == "img" && element.attributes.keys.contains("dfsrc")){
                return  ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 100, maxWidth: 100
                  ),
                  child: Container(
                    // color: Colors.green,s
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Image(
                      image: NetworkImage(element.attributes["dfsrc"] ?? ""),
                    )
                  ),
                );
              }
              if (element.attributes["src"] != null){
                try {
                  String cid = (element.attributes["src"] ?? "").split(":").last;
                  var u = XmlDocument.parse(m.rawData);
                  var mmm =  u.findAllElements("mp").where((e) {
                    return (e.getAttribute("ci") ?? "").contains(cid);
                  }).first;

                  if ((mmm.getAttribute("ct") ?? "").contains("image")){
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 500, maxWidth: 500
                      ),
                      child: Container(
                        // color: Colors.green,s
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Image(
                          image: NetworkImage("https://mail.pancake.vn/service/home/~/?loc=en_US&id=${m.id}&part=${mmm.getAttribute("part")}&auth=qp&zauthtoken=${ConfigZimbra.instance.currentAccountZimbra!.authToken}"),
                        )
                      ),
                    );
                  }

                  return Text("errr");
                } catch (e) {
                  return Text("Error");
                }
              }
              // if (
              //   // gmail
              //   element.classes.contains('gmail_quote')
              //   || (element.localName ?? "").contains('blockquote')
              //   // zimbra
              //   || (element.id.contains("marker"))
              //   || (element.id.contains("zwchr"))
              // ) {
              //   if (showQuote) return null;
              //   return Container();
              // }
              return null;
            },
        );
      }

      return Container(
        margin: EdgeInsets.only(top: 12),
        child: Wrap(
          children: mps.map((mp) {
            return Container(
              padding: EdgeInsets.all(0),
              margin: EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  renderText(mp.content ?? "", mp.contentType),
                  renderFiles(mp),
                  renderMP(mp.mps ?? [], m)
                ],
              ),
            );
          }).toList(),
        ),
      );
    } catch (e) {
      return Text("fail to display");
    }
  }

  Widget renderFullData(){
    MessageConvZimbra m = widget.messConv;
    bool isDark = false && Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom:  BorderSide(
            color: isDark ? Color(0xFF5e5e5e) : Color(0xFFdbdbdb),
            width: 1
          )
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CachedAvatar(null, name: m.from?.displayName ?? "", width: 30, height: 30),
              Container(width: 8,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichTextWidget(
                    TextSpan(
                      text: "${m.from!.partName ?? m.from!.displayName ?? m.from!.address.split("@").first} (${m.from!.address})",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: isDark ? Color(0xFFffffff): Color(0xFF5e5e5e)
                      )
                    )
                  ),
                  Container(height: 4),
                  RichTextWidget(
                    TextSpan(
                      text: "to: ${m.to.map((e) => "${e.partName ?? e.displayName ?? e.address.split("@").first} (${e.address})").join(", ")}.",
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        fontSize: 10,
                        color: isDark ? Color(0xFFbfbfbf) : Color(0xFF5e5e5e)
                      )
                    )
                  ),
                  // render CC
                  m.cc.length > 0
                  ? Container(
                    child: RichTextWidget(
                      TextSpan(
                        text: "cc: ${m.cc.map((e) => "${e.partName ?? e.displayName ?? e.address.split("@").first} (${e.address})").join(", ")}.",
                        style: TextStyle(
                          overflow: TextOverflow.ellipsis,
                          fontSize: 10,
                          color: isDark ? Color(0xFFbfbfbf) : Color(0xFF5e5e5e)
                        )
                      )
                    )
                  )
                  : Container()
                ],
              )
            ],
          ),
          renderMP(m.mps ?? [], m),
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showQuote = !showQuote;
                    });
                  },
                  child: HoverItem(
                    child: Text(showQuote ? "Hide quote" : "Open quote", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 10, color:  isDark ? Color(0xFFbfbfbf) : Color(0xFF5e5e5e)),),
                  ),
                ),
                Container(width: 8,),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext c) {
                        return Dialog(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              color: Colors.white
                            ),
                            height: MediaQuery.of(context).size.height* 0.9,
                            width: MediaQuery.of(context).size.width* 0.85,
                            child: ReplyMessageMailZimbra(messageMail: m, workspaceId: widget.workspaceId, type: "reply"),
                          ),
                        );
                      }
                    );
                  },
                  child: HoverItem(
                    child: Text("Reply", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 10, color: isDark ? Color(0xFFbfbfbf) : Color(0xFF5e5e5e)),),
                  ),
                ),
                Container(width: 8,),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext c) {
                        List<String> fromString = [m.from!.address];
                        List<Map> cc = (Map.fromIterable(
                          widget.conv!.m.map((e){
                            return e.to + e.cc;
                          }).reduce((a,b) => a + b).toList().where((ele) => !fromString.contains(ele.address))
                          .map((e) => e.toJson())
                          .toList(),
                          key: (e) => e["address"],
                          value: (e) => e as Map)
                        ).values.toList();
                        return Dialog(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              color: Colors.white
                            ),
                            height: MediaQuery.of(context).size.height* 0.9,
                            width: MediaQuery.of(context).size.width* 0.85,
                            child: ReplyMessageMailZimbra(messageMail: m, workspaceId: widget.workspaceId, type: "reply to all", cc: cc,),
                          ),
                        );
                      }
                    );
                  },
                  child: HoverItem(
                    child: Text("Reply to All", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 10, color: isDark ? Color(0xFFbfbfbf) : Color(0xFF5e5e5e)),),
                  ),
                ),
                Container(width: 8,),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext c) {
                        return Dialog(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              color: Colors.white
                            ),
                            height: MediaQuery.of(context).size.height* 0.9,
                            width: MediaQuery.of(context).size.width* 0.85,
                            child: ForwardMessageMailZimbra(messageMail: m, workspaceId: widget.workspaceId,),
                          ),
                        );
                      }
                    );
                  },
                  child: HoverItem(
                    child: Text("Forward", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 10, color: isDark ? Color(0xFFbfbfbf) : Color(0xFF5e5e5e)),),
                  ),
                ),
                Container(width: 8,),
                GestureDetector(
                  onTap: () {
                    setState((){
                      viewDefault = !viewDefault;
                    });
                  },
                  child: HoverItem(
                    child: Text(viewDefault ? "View styled" : "View default", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 10, color: isDark ? Color(0xFFbfbfbf) : Color(0xFF5e5e5e)),),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Future loadwMessageItem() async {
    var res = await ServiceZimbra.getMessageOfConv(widget.messConv.id ?? "", widget.workspaceId);
    if (res == null) return;
    widget.messConv.bcc = res.bcc;
    widget.messConv.cc = res.cc;
    widget.messConv.convId = res.convId;
    widget.messConv.currentTime = res.currentTime;
    widget.messConv.from = res.from;
    widget.messConv.id = res.id;
    widget.messConv.idHeader = res.idHeader;
    widget.messConv.mps = res.mps;
    widget.messConv.rawData = res.rawData;
    widget.messConv.size = res.size;
    widget.messConv.subject = res.subject;
    widget.messConv.to = res.to;

    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    MessageConvZimbra m = widget.messConv;
    bool isDark = false && Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    return GestureDetector(
      onTap: () {
        loadwMessageItem();
      },
      child: HoverItem(
        child: (widget.messConv.idHeader != null) ? renderFullData() : Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom:  BorderSide(
                color: isDark ? Color(0xFF5e5e5e) : Color(0xFFdbdbdb),
                width: 1
              )
            )
          ),
          child: Row(
            children: [
              CachedAvatar(null, name: m.from?.displayName ?? "", width: 30, height: 30),
              Container(width: 8,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${m.from!.partName ?? m.from!.displayName ?? m.from!.address.split("@").first}", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14,  color: isDark ? Color(0xFFbfbfbf) : Color(0xFF5e5e5e))),
                  Container(height: 4),
                  Container(
                    width: 500,
                    alignment: Alignment.centerLeft,
                    child: Text(m.snippet, maxLines: 1, style: TextStyle(overflow: TextOverflow.ellipsis, fontSize: 10, color: isDark ? Color(0xFFbfbfbf) : Color(0xFF828282)))
                  )
                ],
              )
            ],
          )
        )
      )
    );
  }
}