import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/generated/l10n.dart';
import 'package:workcake/providers/providers.dart';

class Pagination extends StatefulWidget {
  Pagination({Key? key, this.channelId, this.issueClosedTab, this.filters, this.sortBy, this.text, this.handleCurrentPage, this.issuePerPage, this.currentPage, this.unreadOnly = false}) : super(key: key);

  final channelId;
  final issueClosedTab;
  final filters;
  final sortBy;
  final text;
  final handleCurrentPage;
  final issuePerPage;
  final currentPage;
  final unreadOnly;

  @override
  _PaginationState createState() => _PaginationState();
}

class _PaginationState extends State<Pagination> {
  @override
  void didUpdateWidget (oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(oldWidget.channelId != widget.channelId || oldWidget.issueClosedTab != widget.issueClosedTab) {
      widget.handleCurrentPage(1);
    }
  }

  _previous(isClosedTab) {
    widget.handleCurrentPage(widget.currentPage - 1);
    goToPage(widget.currentPage - 1, isClosedTab);
  }

  _next(isClosedTab) {
    widget.handleCurrentPage(widget.currentPage + 1);
    goToPage(widget.currentPage + 1, isClosedTab);
  }


  goToPage(int page, isClosedTab) async{
    final token = Provider.of<Auth>(context, listen: false).token;
    final workspaceId = Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"];
    final channelId = Provider.of<Channels>(context, listen: false).currentChannel["id"];
    final issueClosedTab = Provider.of<Work>(context, listen: false).issueClosedTab;
    widget.handleCurrentPage(page);

    await Provider.of<Channels>(context, listen: false).getListIssue(token, workspaceId, channelId, page, issueClosedTab, widget.filters, widget.sortBy, widget.text, widget.unreadOnly);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false );
    final isDark = auth.theme == ThemeType.DARK;
    final currentChannel = Provider.of<Channels>(context, listen: true).currentChannel;
    List channels = Provider.of<Channels>(context, listen: true).data;
    final indexChannel = channels.indexWhere((e) => e["id"] == currentChannel["id"]);
    final issueClosedTab = Provider.of<Work>(context, listen: true).issueClosedTab;
    var totalPage;
    if (indexChannel != -1) totalPage = channels[indexChannel]["totalPage"];
    var pagingLength = totalPage == null ? 1 : totalPage >= 9 ? 9 : totalPage;
    var currentPage = widget.currentPage;

    return  totalPage == null || totalPage <= 1 ? Container() :  Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HoverItem(
            colorHover: currentPage <= 1 ? Colors.transparent : Palette.hoverColorDefault,
            child: InkWell(
              onTap: currentPage <= 1 ? null : () {
                _previous(issueClosedTab);
              },
              child: Row(
                children: [
                  Icon(CupertinoIcons.chevron_back, size: 22,color: currentPage > 1 ? Palette.buttonColor : (isDark ? Color(0xffD9D9D9) : Colors.black45)),
                  SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(S.current.previous, style: TextStyle(color: currentPage > 1 ? Palette.buttonColor : (isDark ? Color(0xffD9D9D9) : Colors.black45), fontSize: 14)),
                  ),
                ],
              )
            ),
          ),
          SizedBox(width: 12),
          Container(
            height: 30,
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              physics: NeverScrollableScrollPhysics(),
              itemCount: pagingLength,
              itemBuilder: (context, index) {
                var text = 0;
                if (index == 0) text = index + 1;
                if (index == pagingLength - 1) text = totalPage;
                if (index == 1) {
                  if (currentPage - 2 <= index + 1 || totalPage <= pagingLength) text = index + 1;
                  else text = -1;
                }
                if (index == pagingLength - 2) {
                  if (currentPage + 2 >= totalPage - 1  || totalPage <= pagingLength) text = totalPage - 1;
                  else text = -1;
                }
                if (2 <= index && index <= pagingLength - 3) {
                  if (currentPage >= 5 && currentPage < totalPage - 3) {
                    text = currentPage + (index - 4);
                  }
                  else if (currentPage >= totalPage - 3) {
                    text = totalPage - (pagingLength - index - 1);
                  }
                  else {
                    text = index + 1;
                  }
                }
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: text == -1 ? Colors.transparent : currentPage == text ? Palette.buttonColor : Colors.white,
                  ),
                  child: HoverItem(
                    colorHover: currentPage == text ? Colors.transparent : Colors.grey.withOpacity(0.075),
                    child: InkWell(
                      child: Container(
                        width: 36,
                        alignment: Alignment.center,

                        padding: EdgeInsets.symmetric(vertical:6, horizontal: 10),
                        child: Text(text <= -1 ? "..." : text.toString(), style: TextStyle(color: currentPage == text ? Colors.white : isDark && text <= -1 ? Colors.white : Color.fromRGBO(0, 0, 0, 0.65), fontSize: 14))
                      ),
                      onTap: text == -1 ? null : () {
                        setState(() {
                          currentPage = text;
                        });
                        goToPage(text, issueClosedTab);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 12),
          HoverItem(
            colorHover: currentPage >= totalPage ? Colors.transparent : Palette.hoverColorDefault,
            child: InkWell(
              onTap: currentPage >= totalPage ? null : () {
                _next(issueClosedTab);
              },
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(S.current.next, style: TextStyle(color: currentPage < totalPage ? Palette.buttonColor : (isDark ? Color(0xffD9D9D9) : Colors.black45), fontSize: 14)),
                  ),
                  SizedBox(width: 8),
                  Icon(CupertinoIcons.chevron_forward, size: 22, color: currentPage < totalPage ? Palette.buttonColor : (isDark ? Color(0xffD9D9D9) : Colors.black45))
                ]
              )
            ),
          )
        ]
      )
    );
  }
}