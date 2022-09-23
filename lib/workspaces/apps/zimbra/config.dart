class ConfigZimbra {

  static ConfigZimbra instance = ConfigZimbra();
  late List<AccountZimbra> accounts;
  AccountZimbra? currentAccountZimbra;

  static ConfigZimbra? initConfigZimbra(Map config){
    try {
      return ConfigZimbra();
    } catch (e, t) {
      print("ConfigZimbra: $e,,,,,, $t");
      return null;
    }
  }

  Map toJson(){
    return {
      "accounts": this.accounts.map((e) => e.toJson()).toList(),
      "current_account_zimbra": this.currentAccountZimbra?.toJson()
    };
  }

  static bool parseFromJson(Map data){
    try {
      ConfigZimbra.instance.currentAccountZimbra = AccountZimbra.initAccountZimbra(data["current_account_zimbra"]);
      ConfigZimbra.instance.accounts = (data["accounts"].map((e) => AccountZimbra.initAccountZimbra(e)).toList() as List).whereType<AccountZimbra>().toList();
      return true;
    } catch (e) {
      return false;
    }
  }

  ConfigZimbra();
}

class AccountZimbra {
  late String email;
  late String password;
  late String status;
  late String authToken;
  late String csrfToken;
  late String domain;
  late String sessionId;
  late List<int> convIdUnread;
  late int workspaceId;

  String get getSoapServiceEndpoint => this.domain + "/service/soap";

  static AccountZimbra? initAccountZimbra(Map init){
    try {
      return AccountZimbra(init["email"], init["password"], init["status"], init["auth_token"] ??init["token"], init["csrf_token"], init["domain"], init["session_id"] ?? "0", <int>[], init["workspace_id"] ?? 0);
    } catch (e, t) {
      print(")))))):${init["conv_id_unread"]}");
      print("AccountZimbra: $e,,,,,,, $t");
      return null;
    }
  }

  Map toJson() {
    return {
      "email": this.email,
      "password": this.password,
      "status": this.status,
      "auth_token": this.authToken,
      "csrf_token": this.csrfToken,
      "domain": this.domain,
      "session_id": this.sessionId,
      "conv_id_unread": <int>[],
      "workspace_id": this.workspaceId
    };
  }

  bool isEqual(AccountZimbra other){
    return (other.email == this.email) && other.workspaceId == this.workspaceId && other.password == this.password;
  }

  AccountZimbra(String email, String password, String status, String authToken, String csrfToken, String domain, String sessionId, List<int> convIdUnread, int workspaceId){
    this.email = email;
    this.password = password;
    this.status = status;
    this.authToken = authToken;
    this.csrfToken = csrfToken;
    this.domain = domain;
    this.sessionId = sessionId;
    this.convIdUnread = convIdUnread;
    this.workspaceId = workspaceId;
  }
}

class EmailAdd {
  late String type;
  late String? displayName;
  late String address;
  late String? partName;

  EmailAdd(String type, String? displayName, String address, String? partName){
    this.type = type;
    this.displayName = displayName;
    this.address = address;
    this. partName = partName;
  }

  Map toJson() {
    return {
      "type": this.type,
      "address": this.address,
      "display_name": this.displayName,
      "part_name": this.partName
    };
  }
}

// conversation mail
class MailZimbra{
  late int id;
  late int currentTime;
  late int countMessagesChild;
  late int unreadMessagesChild;
  late String subject;
  late String snippet;
  late List<EmailAdd> emailAdds;
  late bool hasAtts;
  late List<MessageConvZimbra> m;


  MailZimbra(int id, int currentTime, int countMessagesChild, int unreadMessagesChild, String subject, String snippet, List<EmailAdd> emailAdds, bool hasAtts, List<MessageConvZimbra> m){
    this.id = id;
    this.currentTime = currentTime;
    this.countMessagesChild = countMessagesChild;
    this.unreadMessagesChild = unreadMessagesChild;
    this.subject = subject;
    this.snippet = snippet;
    this.emailAdds = emailAdds;
    this.hasAtts= hasAtts;
    this.m = m;
  }
}

class MessageConvZimbra {
  late String? id;
  late String? idHeader;//id cua tin nhan se bi null khi tin nhan lad dummy
  late int size;
  late int currentTime; //  from the date header in the message
  late int convId;
  late EmailAdd? from;
  late List<EmailAdd> to;
  late List<EmailAdd> cc;
  late List<EmailAdd> bcc;
  late String subject;
  late String snippet;
  late List<MessagePartConvZimbra>? mps;
  late String rawData;

  MessageConvZimbra(String id, String? idHeader, int size, int currentTime, int convId, EmailAdd? from, List<EmailAdd> to,  List<EmailAdd> cc,  List<EmailAdd> bcc, String subject, String snippet, List<MessagePartConvZimbra>? mps, String rawData){
    this.id = id;
    this.idHeader = idHeader;
    this.size = size;
    this.currentTime = currentTime;
    this.convId = convId;
    this.from = from;
    this.to = to;
    this.cc = cc;
    this.bcc = bcc;
    this.subject = subject;
    this.snippet = snippet;
    this.mps = mps;
    this.rawData = rawData;
  }

  Map toJson(){
    return {
      "mp": (mps ?? []).map((e) => e.toJson()).toList(),
    };
  }
}

class MessagePartConvZimbra {
  late String part;
  late String contentType; //  from the date header in the message
  late String?  content;
  late String? contentId;
  late int? size;
  late String? filename;
  late List<MessagePartConvZimbra>? mps;

  MessagePartConvZimbra(String part, String contentType, String? content, String? contentId, int? size, String? filename,  List<MessagePartConvZimbra>? mps){
    this.part = part;
    this.contentType = contentType;
    this.content = content;
    this.contentId = contentId;
    this.size = size;
    this.filename = filename;
    this.mps = mps;
  }

  Map toJson(){
    return {
      "mp": (mps ?? []).map((e) => e.toJson()).toList(),
      "filename": filename,
      "content": (content ?? ""),
    };
  }
}