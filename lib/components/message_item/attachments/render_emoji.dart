// import 'package:workcake/common/cached_image.dart';
// import 'package:workcake/components/main_menu/emoji.dart';
import 'package:workcake/models/models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

  class RenderEmoji extends StatefulWidget {
    RenderEmoji({
      Key? key,
      this.reactions,
      this.workspaceEmojiData,
      this.isChannel,
      this.id
    }) : super(key: key);

    final reactions;
    final workspaceEmojiData;
    final isChannel;
    final id;

    @override
    _RenderEmojiState createState() => _RenderEmojiState();
  }

class _RenderEmojiState extends State<RenderEmoji>{

  renderOtherReaction(List users){
    List channelMembers = Provider.of<Channels>(context, listen: false).channelMember;
    bool isMe = users.indexWhere((element) => element == Provider.of<Auth>(context, listen: false).userId) != -1;
    String name  = isMe ? "You, " :  "";
    for(var i = 0; i< users.length ; i++){
      if (users[i] != Provider.of<Auth>(context, listen: false).userId){
        var index  =  channelMembers.indexWhere((element) => element["id"] == users[i]);
        if (index != -1)
          name += channelMembers[index]["full_name"] + ", ";
      }
    }
    return name.length > 1 ? name.substring(0, name.length - 2) : '';
  }

  @override
  Widget build(BuildContext context) {
    final reactions = widget.reactions;
    final workspaceEmojiData = widget.workspaceEmojiData;
    // final auth = Provider.of<Auth>(context);
    // final isDark = auth.theme == ThemeType.DARK;
    List result = [];
    for(int i = 0; i < reactions.length; i++){
      int indexR = result.indexWhere((element) => element["emoji_id"] == reactions[i]["emoji_id"]);
      if (indexR == -1){
        result = result + [{
          "emoji_id": reactions[i]["emoji_id"],
          "users": [reactions[i]["user_id"]],
          "count": 1
        }];
      }
      else {
        result[indexR] = {
          "users": result[indexR]["users"] + [reactions[i]["user_id"]],
          "count": result[indexR]["count"] + 1,
          "emoji_id": result[indexR]["emoji_id"],
        };
      }
    }
    var dataEmoji  = Provider.of<Workspaces>(context, listen: false).emojis;

    return Container(
      child: Wrap(
        alignment: WrapAlignment.start,
        children: result.map<Widget>((e){
          // check
          var indexDefaultEmoji =  (dataEmoji.indexWhere((element) => element.contains(e["emoji_id"] ?? "_")) );
          var indexWorkspaceEmoji = (workspaceEmojiData.indexWhere((element) => element["name"] == e["emoji_id"] || element["emoji_id"] ==  e["emoji_id"]));
          if ((indexDefaultEmoji == -1 )  && (indexWorkspaceEmoji == -1 )) return Container();
          // bool isMe = e["users"].indexWhere((element) => element == Provider.of<Auth>(context, listen: false).userId) != -1;
          return Container();
          // HoverItem(
          //   showTooltip: true,
          //   tooltip: Container(
          //     child: Column(
          //       children: [
          //         Container(
          //             height: 25, width: 25,
          //             margin: EdgeInsets.only(bottom: 8),
          //             child: indexWorkspaceEmoji != -1 ? CachedImage(workspaceEmojiData[indexWorkspaceEmoji]["url"],width: 25, height: 25, )
          //             :  Image(image: AssetImage(dataEmoji[indexDefaultEmoji]) ) 
          //           ),
          //         Text("${renderOtherReaction(e["users"])} reacted with :${e["emoji_id"]}",style: TextStyle(fontSize: 10,  color: isDark ? Colors.white : Colors.black, decoration: TextDecoration.none, fontWeight: FontWeight.w500), )
          //       ],
          //     ),
          //   ), 
          //   colorHover: null,
          //   child: GestureDetector(
          //     onTap: (){
          //       final channelId = widget.isChannel ? Provider.of<Channels>(context, listen: false).currentChannel["id"] : null;
          //       final workspaceId = widget.isChannel ? Provider.of<Workspaces>(context, listen: false).currentWorkspace["id"] : null;
          //       Provider.of<Messages>(context, listen: false).handleReactionMessage({
          //         "emoji_id": e["emoji_id"],
          //         "message_id": widget.id,
          //         "channel_id": channelId,
          //         "workspace_id": workspaceId,
          //         "user_id": Provider.of<Auth>(context, listen: false).userId,
          //         "token": Provider.of<Auth>(context, listen: false).token,
          //       });
          //     },
          //     child: Container(
          //       padding: EdgeInsets.all(4),
          //       margin: EdgeInsets.only(right: 4, top: 4),
          //       decoration: BoxDecoration(
          //         borderRadius: BorderRadius.circular(12),
          //         boxShadow: isMe && !isDark ? [BoxShadow(
          //           color: Colors.grey.withOpacity(0.3),
          //           spreadRadius: 1,
          //           blurRadius: 1,
          //           offset: Offset(0, 1),
          //         )] : [],
          //         color: !isDark ?  Colors.white : isMe ? Color(0xFF323F4B) : null
          //       ),
          //       child: Wrap(
          //         crossAxisAlignment: WrapCrossAlignment.center,
          //         children: [
          //           Container(
          //             height: 16, width: 16,
          //             child: indexWorkspaceEmoji != -1 ? 
          //               CachedImage(workspaceEmojiData[indexWorkspaceEmoji]["url"], fit: BoxFit.cover) : 
          //               Image(image: AssetImage(dataEmoji[indexDefaultEmoji]))
          //           ),
          //           e["count"] > 0 ? Text("  ${e["count"]}", style: TextStyle(fontSize: 12, color: Color(0xFF19DFCB)) ): Text("")
          //         ],
          //       )
          //     ),
          //   ),
          // );
        
        }).toList(),
      ),
    );
  }
}