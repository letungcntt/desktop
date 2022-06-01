part of flutter_mentions;

class OptionList extends StatelessWidget {
  OptionList({
    required this.data,
    required this.onTap,
    required this.suggestionListHeight,
    required this.selectMention,
    this.suggestionListDecoration,
    this.isDark,
    this.isShow,
    this.scrollController,
    this.isMentionIssue = false,
    this.isExpand = false
  });


  final isDark;

  final scrollController;

  final List<dynamic> data;

  final Function(Map<String, dynamic>) onTap;

  final double suggestionListHeight;

  final BoxDecoration? suggestionListDecoration;

  final Map<String, dynamic>? selectMention;

  final bool? isShow;

  final bool isMentionIssue;

  final bool isExpand;

  @override
  Widget build(BuildContext context) {
    return data.isNotEmpty && isShow!
      ? Container(
        margin: EdgeInsets.only(bottom: 4),
        width: !isExpand && isMentionIssue ? 980 : 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(8)),
            color: isDark ? Color(0xff2f3136) : Color(0xFFf0f0f0),
          ),
        constraints: BoxConstraints(
          maxHeight: suggestionListHeight is int ? suggestionListHeight : 200,
          minHeight: 0,
        ),
        child: ListView.builder(
          controller: scrollController,
          itemCount: data.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                onTap(data[index]);
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: index == data.length - 1 ? Colors.transparent : Colors.grey[500]!, width: 0.2),
                    top: BorderSide(color: index == 0 ? Colors.transparent : Colors.grey[500]!, width: 0.2)
                  )
                ),
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    data[index]['photo'] == "all" ? Icon(Icons.campaign, color: Colors.grey[600], size: 24) :
                    isMentionIssue ? Icon(
                      Icons.info_outline,
                      color: !data[index]["is_closed"] ? Colors.green : Colors.redAccent, size: 18
                    ) : CachedImage(
                      data[index]['photo'],
                      width: 24,
                      height: 24,
                      radius: 5,
                      isAvatar: true,
                      name: data[index]["full_name"]
                    ),
                    Container(width: 8),
                    Container(
                      width: isMentionIssue ? (!isExpand ? 930 : 274) : null,
                      child: isMentionIssue ? Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "#${data[index]['display']} ",
                              style: TextStyle(
                                color: !(selectMention != null && selectMention!["id"] != data[index]["id"]) ? isDark ? Palette.calendulaGold : Palette.dayBlue : isDark ? Colors.grey[400] : Colors.grey[800],
                                fontWeight: selectMention != null && selectMention!["id"] != data[index]["id"] ? FontWeight.w300 : FontWeight.w600
                              )
                            ),
                            TextSpan(
                              text: "${data[index]["channel_name"]} ",
                              style: TextStyle(
                                color: !(selectMention != null && selectMention!["id"] != data[index]["id"]) ? isDark ? Palette.calendulaGold : Palette.dayBlue :  isDark ? Colors.grey[400] : Colors.grey[800],
                                fontWeight: selectMention != null && selectMention!["id"] != data[index]["id"] ? FontWeight.w500 : FontWeight.w600
                              )
                            ),
                            TextSpan(
                              text: "${data[index]['title']}",
                              style: TextStyle(
                                color: !(selectMention != null && selectMention!["id"] != data[index]["id"]) ? isDark ? Palette.calendulaGold : Palette.dayBlue : isDark ? Colors.grey[400] : Colors.grey[800],
                                fontWeight: selectMention != null && selectMention!["id"] != data[index]["id"] ? FontWeight.w300 : FontWeight.w600
                              )
                            ),
                          ]
                        ),
                        overflow: TextOverflow.ellipsis
                      ) : Text(
                        ("@" + data[index]['full_name']),
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[800],
                          fontWeight: selectMention != null && selectMention!["id"] != data[index]["id"] ? FontWeight.w300 : FontWeight.w600
                        ),
                        overflow: TextOverflow.ellipsis
                      ),
                    )
                  ],
                ),
              )
            );
          },
        ),
      )
    : Container();
  }
}