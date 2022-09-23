// import 'BoardItemObject.dart';

class BoardListObject{
  var id;
  String? title;
  List? cards;
  int? workspaceId;
  int? channelId;
  int? boardId;
  bool? isArchived;

  BoardListObject({this.title,this.cards, this.workspaceId, this.channelId, this.boardId, this.id, this.isArchived}){
    if (this.title == null){
      this.title = "";
    }
    if (this.cards == null){
      this.cards = [];
    }
  }
}