import 'package:flutter/material.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/providers/providers.dart';

class ResponseSideBar extends StatefulWidget{
  ResponseSideBar({
    required this.child,
    this.onResize,
    this.minWidth = 250,
    this.maxWidth = 630,
    required this.dragAtLeft
  });
  final child;
  final onResize;
  final double minWidth;
  final double maxWidth;
  final bool dragAtLeft;
  @override
  State<StatefulWidget> createState() {
    return _ResponseSideBarState();
  }
}
class _ResponseSideBarState extends State<ResponseSideBar>{
  var wrapperSize;
  var objectSize;
  bool _onHover = false;
  bool _onPan = false;
  var globalPosition;
  double? widthFromHive;
  GlobalKey wrapperKey = GlobalKey();
  final double conversationWidth = 610;
  @override
  void initState() {
    widthFromHive = widget.dragAtLeft
      ? Provider.of<Windows>(context, listen: false).threadWidth
      : Provider.of<Windows>(context, listen: false).channelWidth;
    WidgetsBinding.instance.addPostFrameCallback((_) => findWidgetPosition());
    super.initState();
  }
  void findWidgetPosition(){
    final renderObject = wrapperKey.currentContext?.findRenderObject();
    var translation = renderObject?.getTransformTo(null).getTranslation();
    if(translation != null){
      setState(() {
        objectSize = Size(renderObject!.paintBounds.width, renderObject.paintBounds.height);
        wrapperSize = objectSize;
        globalPosition = Offset(renderObject.paintBounds.width + translation.x, renderObject.paintBounds.height + translation.y);
      });
    }
  }

  @override
  Widget build(BuildContext context){
    final isDark = Provider.of<Auth>(context).theme == ThemeType.DARK;
    return objectSize == null
      ? SizedBox(
        width: widthFromHive,
        child: LayoutBuilder(
          key: wrapperKey,
          builder: (context, constraints) {
            return Container(
              color: isDark ? Palette.backgroundTheardDark : Palette.backgroundTheardLight,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Palette.backgroundTheardDark,
                      border: Border(
                        bottom: BorderSide(
                          color: Palette.borderSideColorDark
                        )
                      ),
                    ),
                    height: 56,
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Reply in thread", style: TextStyle(color: Color(0xffF0F4F8), fontSize: 16, fontWeight: FontWeight.w500)),
                        Container(margin: EdgeInsets.only(right: 12) ,child: Icon(Icons.close, size: 18, color: Color(0xffF0F4F8)))
                      ],
                    ),
                  ),
                  Expanded(child: Container())
                ],
              ),
            );
          }
        )
      )
      : Stack(
        children: [
          Consumer<Windows>(
            builder: (context, windows, _) {
              return Consumer<Messages>(
                builder: (context, message, _) {
                  var _maxWidth = maxWidth(windows, message.openThread);
                  return AnimatedContainer(
                    duration: Duration(milliseconds: _onPan ? 0 : !widget.dragAtLeft ? 70 : 0),
                    width: wrapperSize.width > _maxWidth ? _maxWidth < widget.minWidth ? (!widget.dragAtLeft && _maxWidth < 150) ? 70 : widget.minWidth : _maxWidth : wrapperSize.width,
                    child: widget.child,
                  );
                }
              );
            }
          ),
          if (!widget.dragAtLeft) Positioned(
            top: 0,
            right: 0,
            child: dragEdge()
          ) else Positioned(
            top: 0,
            left: 0,
            child: dragEdge(),
          )
        ],
      );
  }
  //Tính maxwidth của thanh list channel có thể có, duy trì kích thước conversation luôn lớn hơn hoặc bằng 630
  double maxWidth(windows, isShowThread) {
    bool showChannelSetting = Provider.of<Channels>(context, listen: true).showChannelSetting;
    bool showDirectSetting = Provider.of<DirectMessage>(context, listen: true).showDirectSetting;
    bool showChannelMember = Provider.of<Channels>(context, listen: true).showChannelMember;
    bool showChannelPinned = Provider.of<Channels>(context, listen: true).showChannelPinned;
    var threadWidth = windows.threadWidth;
    var max = MediaQuery.of(context).size.width - (isShowThread || showChannelSetting || showDirectSetting || showChannelMember || showChannelPinned ? threadWidth : 0) - conversationWidth;
    if (widget.dragAtLeft) {
      return MediaQuery.of(context).size.width - widget.maxWidth <= conversationWidth ? MediaQuery.of(context).size.width - conversationWidth : widget.maxWidth;
    }
    return max > widget.maxWidth ? widget.maxWidth : max;
  }
  Widget dragEdge(){
    void _onEnter(PointerEvent event){
      setState(() {
        _onHover = true;
      });
    }
    void _onExit(PointerEvent event){
      setState(() {
        _onHover = false;
      });
    }
    return GestureDetector(
      onPanStart: (details){
        setState(() {
          _onPan = true;
        });
      },
      onPanUpdate: (details) {
        var newWidth = widget.dragAtLeft
          ? MediaQuery.of(context).size.width - details.globalPosition.dx
          : details.globalPosition.dx - (globalPosition.dx - objectSize!.width);
        setState(() {
          wrapperSize = Size((newWidth < widget.minWidth) ? !widget.dragAtLeft && newWidth < 150 ? 70 : widget.minWidth : (newWidth > widget.maxWidth) ? widget.maxWidth : newWidth, wrapperSize.height);
        });

        if(widget.onResize != null && wrapperSize != null ) {
          widget.onResize(wrapperSize);
        }
        if (widget.dragAtLeft) {
          Provider.of<Windows>(context, listen: false).threadWidth = wrapperSize.width;
        } else {
          Provider.of<Windows>(context,listen: false).channelWidth = wrapperSize.width;
        }

      },
      onPanEnd: (details){
        setState(() {
          _onPan = false;
        });
        Provider.of<Windows>(context, listen: false).saveResponsiveBarToHive(widget.dragAtLeft ? "thread" : "channel");
      },
      child: MouseRegion(
        onEnter: _onEnter,
        onExit: _onExit,
        cursor: SystemMouseCursors.resizeLeftRight,
        child: Container(
          width: 4.5,
          height: MediaQuery.of(context).size.height,
          color: _onHover || _onPan ? Colors.blue : Colors.transparent,
        ),
      ),
    );
  }
}