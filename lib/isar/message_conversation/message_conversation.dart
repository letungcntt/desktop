import 'package:isar/isar.dart';
part 'message_conversation.g.dart';

@Collection()
class MessageConversation {
  @Id()
  @Name("localId")
  int? localId;

  @Name("message")
  String? message;

  // tat ca att can parse sang string de search
  // messageParse = message + parse(att)
  @Index(type: IndexType.value) // Search index
  @Name("messageParse")
  String? messageParse;

  @Index()
  @Name("conversationId")
  String? conversationId;

  @Name("currentTime")
  int? currentTime;

  @Name("attachments")
  List<String>? attachments;

  @Name("dataRead")
  List<String>? dataRead;

  // id cua tin nhan tren server (do id trong isar mac dinh la int)
  @Index()
  @Name("id")
  String? id;

  @Name("count")
  int? count;


  @Name("success")
  bool? success;

  @Name("sending")
  bool? sending;

  @Name("isBlur")
  bool? isBlur;

  @Index(composite: [CompositeIndex('conversationId')])
  @Name("parentId")
  String? parentId;

  @Name("insertedAt")
  String? insertedAt;

  @Name("userId")
  String? userId;

  @Name("fakeId")
  String? fakeId;

  @Name("publicKeySender")
  String? publicKeySender;

  @Name("infoThread")
  List<String>? infoThread;

  @Name("isSystemMessage")
  bool? isSystemMessage;

  @Name("lastEditedAt")
  String? lastEditedAt;

  @Name("action")
  String? action;
}