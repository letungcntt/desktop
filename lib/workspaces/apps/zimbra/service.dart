import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/components/notification_macOS.dart';
import 'package:workcake/services/queue.dart';
import 'package:workcake/workspaces/apps/zimbra/config.dart';
import 'package:workcake/workspaces/apps/zimbra/conv.dart';
import 'package:workcake/workspaces/apps/zimbra/import_provider.dart';
import 'package:xml/xml.dart';

import 'dashboard.dart';

class ServiceZimbra {
  static GlobalKey<DashBoardZimbraState> dashboardZimbra = GlobalKey();
  static GlobalKey<ConvDetailZimbraState> convDetailZimbra = GlobalKey();
  static Scheduler oneSchedule = Scheduler();
  static StreamController<List<Map<dynamic, dynamic>>> autoCompleteController = StreamController<List<Map>>.broadcast(sync: false);
  static final streamAccounts = StreamController<List<AccountZimbra>>.broadcast(sync: false);

  static Future<Map> getFolderData() async {
    try {
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element("soap:Envelope", nest: (){
        builder.attribute("xmlns:soap", "http://www.w3.org/2003/05/soap-envelope");
        builder.element("soap:Body", nest: (){
          builder.element("GetFolderRequest", nest: (){
            builder.attribute("xmlns", "urn:zimbraMail");
          });
        });
      });
      var t = await Dio().post(ConfigZimbra.instance.currentAccountZimbra!.getSoapServiceEndpoint, data: builder.buildDocument(), options: Options(
        validateStatus: (status) => true,
        contentType: "application/soap+xml",
        headers: {
          "content_type": "application/soap+xml",
          'cookie': 'ZM_AUTH_TOKEN=${ConfigZimbra.instance.currentAccountZimbra!.authToken}',
        },
      ));
      var u = XmlDocument.parse(t.data);
      var searchResponse = u.findAllElements("GetFolderResponse").first;
      return Map.fromIterable(
        searchResponse.findAllElements("folder").toList().map((e) {
          return {
            "id": (e.getAttribute("name") ?? "").toLowerCase(),
            "unread_count": int.parse(e.getAttribute("u") ?? "0")
          };
          }).toList(),
        key: (v) => v["id"],
        value: (v) => v
      );
    } catch (e, t) {
      print("getFolderData, $e, $t");
      return {};
    }
  }

  static Future<Map?> getTokenLoginZimbra(String email, String password, int workspaceId, String domain, {String? sessionId}) async {
    try {
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element("soap:Envelope", nest: () {
        builder.attribute("xmlns:soap", "http://www.w3.org/2003/05/soap-envelope");
        builder.element("soap:Header", nest: () {
          builder.element("context", nest: () {
            builder.attribute("xmlns", "urn:zimbra");
            builder.element("session", nest: () {
              builder.attribute("id", sessionId ?? "12");
            });
          });
        });
        builder.element("soap:Body", nest: () {
          builder.element("AuthRequest", nest: () {
            builder.attribute("xmlns", "urn:zimbraAccount");
            builder.element("account", nest: () {
              builder.attribute("by", "name");
              builder.text(email);
            });
            builder.element("password", nest: password);
          });
        });

      });

      final document = builder.buildDocument();
      var t = await Dio().post(domain + "/service/soap", data: document, options: Options(
        validateStatus: (status) => true,
        contentType: "application/soap+xml"
      ));
      if (t.statusCode == 500)  {
        checkResponse(t, workspaceId);
        return null;
      }
      var u = XmlDocument.parse(t.data);
      return {
        "auth_token":  u.findAllElements("authToken").first.text,
        "session_id":  u.findAllElements("session").first.text
      };
    } catch (e) {
      return null;
    }
  }

  static Future<AccountZimbra?> newLogin(String email, String password, int workspaceId, String domain, {String? sessionId, bool hasSave = true}) async {
    try {
      Map? dataLogin = await getTokenLoginZimbra(email, password, workspaceId, domain);
      int index = ConfigZimbra.instance.accounts.indexWhere((element) => element.workspaceId == workspaceId && element.email == email);
      List<int> convIdUnread = index == -1 ? [] : ConfigZimbra.instance.accounts[index].convIdUnread;
      AccountZimbra current = AccountZimbra(email, password, "status", dataLogin!["auth_token"], "", domain, dataLogin["session_id"], convIdUnread, workspaceId);
      noOpRequest(current);
      if (hasSave){
        ConfigZimbra.instance.accounts = Map.fromIterable(ConfigZimbra.instance.accounts + [current], key: (v) => "${v.workspaceId}_${v.email}", value: (v) => v as AccountZimbra).values.toList();
        LazyBox box = Hive.lazyBox("pairKey");
        await box.put("zimbra_$workspaceId",  {
          ...(await box.get("zimbra_$workspaceId") ?? {}),
          "current_account_zimbra": current.toJson(),
          "accounts": ConfigZimbra.instance.accounts.where((element) => element.workspaceId == workspaceId).map((e) => e.toJson()).toList()
        });
      }
      return current;
    } catch (e, t) {
      print("login zimbra $e, $t");
      return null;
    }
  }

// config = {
//   "auth_token": "",
//   "limit": "",
//   "query": "in:inbox"
// }
  static Future<Map> getMail(Map config) async {
    try {
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element("soap:Envelope", nest: (){
        builder.attribute("xmlns:soap", "http://www.w3.org/2003/05/soap-envelope");
        builder.element("soap:Body", nest: (){
          builder.element("SearchRequest", nest: (){
            builder.attribute("xmlns", "urn:zimbraMail");
            builder.attribute("limit", config["limit"]);
            builder.attribute("offset", config["offset"]);
            builder.attribute("recip", config["recip"]);
            builder.element("query", nest: config["query"]);
          });
        });
      });

      var document = builder.buildDocument();

      var t = await Dio().post(ConfigZimbra.instance.currentAccountZimbra!.getSoapServiceEndpoint, data: document.toString(), options: Options(
        validateStatus: (status) => true,
        headers: {
          "content_type": "application/soap+xml",
          'cookie': 'ZM_AUTH_TOKEN=${ConfigZimbra.instance.currentAccountZimbra!.authToken}',
        },
      ));
      if (t.statusCode == 500) {
        checkResponse(t, config["workspace_id"]);
        return {
          "success": false,
          "convs": <MailZimbra>[]
        };
      }
      var u = XmlDocument.parse(t.data);
      var searchResponse = u.findAllElements("SearchResponse").first;
      List<MailZimbra> convs = (searchResponse.findAllElements("c").toList()).map((conv) {
        return MailZimbra(
          int.parse("${conv.getAttribute("id")}"),
          int.parse("${conv.getAttribute("d")}"),
          int.parse("${conv.getAttribute("n")}"),
          int.parse("${conv.getAttribute("u")}"),
          conv.findAllElements("su").first.text,
          conv.findAllElements("fr").first.text,
          (conv.findAllElements("e")).map((e) {
            return EmailAdd(
              "${e.getAttribute("t")}",
              e.getAttribute("d"),
              "${e.getAttribute("a")}",
              e.getAttribute("p")
            );
          }).toList(),
          (conv.findAllElements("m").first.getAttribute("f") ?? "").contains("a"),
          []
        );
      }).toList();
      if (config["query"].toString().contains("inbox")) ConfigZimbra.instance.currentAccountZimbra!.convIdUnread = [];
      return {
        "convs": convs,
        "success": true,
        "load_more": searchResponse.getAttribute("more") != "0"
      };
    } catch (e, t) {
      print("getMail__$e   $t");
      return {
        "success": false,
        "convs": <MailZimbra>[]
      };

    }
  }

// tin nhan dau tien cuoi cung vaf bi miss luon dc hien thi day du
// config = {
//   "cid":
// }

  static markReadConv(MailZimbra m) async {
    try {
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element("soap:Envelope", nest: (){
        builder.attribute("xmlns:soap", "http://www.w3.org/2003/05/soap-envelope");
        builder.element("soap:Body", nest: (){
          builder.element("ConvActionRequest", nest: (){
            builder.attribute("xmlns", "urn:zimbraMail");
            builder.element("action", nest: (){
              builder.attribute("id", m.id);
              builder.attribute("op", "read");
            });
          });
        });
      });

      var document = builder.buildDocument();
      await Dio().post(ConfigZimbra.instance.currentAccountZimbra!.getSoapServiceEndpoint, data: document.toString(), options: Options(
        validateStatus: (status) => true,
        headers: {
          "content_type": "application/soap+xml",
          'Cookie': 'ZM_AUTH_TOKEN=${ConfigZimbra.instance.currentAccountZimbra!.authToken}',
        },
      ));
      m.unreadMessagesChild = 0;
      dashboardZimbra.currentState?.getMail({});

    } catch (e) {

    }
  }
  static Future<MailZimbra?> getDetailConv(MailZimbra config, int workspaceId) async {
    try {
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element("soap:Envelope", nest: (){
        builder.attribute("xmlns:soap", "http://www.w3.org/2003/05/soap-envelope");
        builder.element("soap:Body", nest: (){
          builder.element("SearchConvRequest", nest: (){
            builder.attribute("xmlns", "urn:zimbraMail");
            builder.attribute("cid", config.id);
            builder.attribute("fetch", "u!");
            builder.attribute("html", 1);
            builder.attribute("limit", 1000000);
            builder.attribute("recip", "2");
          });
        });
      });

      var document = builder.buildDocument();
      var t = await Dio().post(ConfigZimbra.instance.currentAccountZimbra!.getSoapServiceEndpoint, data: document.toString(), options: Options(
        validateStatus: (status) => true,
        headers: {
          "content_type": "application/soap+xml",
          'Cookie': 'ZM_AUTH_TOKEN=${ConfigZimbra.instance.currentAccountZimbra!.authToken}',
        },
      ));

      if (t.statusCode == 500) {
        checkResponse(t, workspaceId);
        return null;
      }
      var u = XmlDocument.parse(t.data);
      var searchConvResponse = u.findAllElements("SearchConvResponse").first;
      List<XmlElement> messages = searchConvResponse.findAllElements("m").toList();
      config.m = messages.map<MessageConvZimbra>((e) {
        return MessageConvZimbra(
          "${e.getAttribute("id")}",
          e.findElements("mid").toList().firstElement?.text,
          int.parse("${e.getAttribute("s")}"),
          int.parse("${e.getAttribute("d")}"),
          int.parse("${e.getAttribute("cid")}"),
          getEmailAddsByType(e, "f").firstElement,
          getEmailAddsByType(e, "t"),
          getEmailAddsByType(e, "c"),
          getEmailAddsByType(e, "bcc"),
          "${e.findAllElements("su").toList().firstElement?.text ?? ""}",
          "${e.findAllElements("fr").toList().firstElement?.text ?? ""}",
          getMessagePart([e]),
          t.data
        );
      }).toList();
      config.subject = config.m.length > 0 ? config.m.first.subject : "";
      int index = ConfigZimbra.instance.accounts.indexWhere((element) => element.isEqual(ConfigZimbra.instance.currentAccountZimbra!));
      if (index != -1){
        ConfigZimbra.instance.accounts[index].convIdUnread = ConfigZimbra.instance.accounts[index].convIdUnread.where((element) => element != config.id).toList();
        streamAccounts.add(ConfigZimbra.instance.accounts);
      }
      markReadConv(config);
      return config;
    } catch (e, t) {
      print("get detasil conv:$e, $t");
      return null;
    }
  }

  static List<EmailAdd> getEmailAddsByType(XmlElement data, String type){
    return data.findElements("e").where((element) => element.getAttribute("t") == type).toList().map((e) => EmailAdd(
      "${e.getAttribute("t")}",
      e.getAttribute("d"),
      "${e.getAttribute("a")}",
      e.getAttribute("p")
    )).toList();
  }

  static List<MessagePartConvZimbra>? getMessagePart(List<XmlElement> dataSource){
      if (dataSource == []) return null;
      return dataSource.map<MessagePartConvZimbra>((mp) {
        return MessagePartConvZimbra(
          "${mp.getAttribute("part")}",
          "${mp.getAttribute("ct")}",
          mp.findElements("content").toList().firstElement?.text,
          mp.getAttribute("ci"),
          mp.getAttribute("s") != null ? int.parse("${mp.getAttribute("s")}") : null,
          mp.getAttribute("filename"),
          getMessagePart(mp.findElements("mp").toList()),
        );
        // return data.findElements("mp").map((mp) => MessagePartConvZimbra(
        //   "${mp.getAttribute("part")}",
        //   "${mp.getAttribute("ct")}",
        //   mp.findElements("content").toList().firstElement?.text,
        //   mp.getAttribute("ci"),
        //   mp.getAttribute("s") != null ? int.parse("${mp.getAttribute("s")}") : null,
        //   (mp.findElements("filename").toList()).firstElement?.text,
        //   getMessagePart(data.findElements("mp").toList().firstElement),

        // )).toList();
      }).toList();

    }

  static Future<MessageConvZimbra?> getMessageOfConv(String messageId, int workspaceId) async {
    try {
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element("soap:Envelope", nest: (){
        builder.attribute("xmlns:soap", "http://www.w3.org/2003/05/soap-envelope");
          builder.element("soap:Body", nest: (){
            builder.element("GetMsgRequest", nest: (){
              builder.attribute("xmlns", "urn:zimbraMail");
              builder.element("m", nest: (){
                builder.attribute("id", messageId);
                builder.attribute("html", 1);
              });
          });
        });
      });

      var document = builder.buildDocument();
      var t = await Dio().post(ConfigZimbra.instance.currentAccountZimbra!.getSoapServiceEndpoint, data: document.toString(), options: Options(
        validateStatus: (status) => true,
        headers: {
          "content_type": "application/soap+xml",
          'Cookie': 'ZM_AUTH_TOKEN=${ConfigZimbra.instance.currentAccountZimbra!.authToken}',
        },
      ));
      var u = XmlDocument.parse(t.data);
      var e = u.findAllElements("m").first;
      return MessageConvZimbra(
        "${e.getAttribute("id")}",
        e.findElements("mid").toList().firstElement?.text,
        int.parse("${e.getAttribute("s")}"),
        int.parse("${e.getAttribute("d")}"),
        int.parse("${e.getAttribute("cid")}"),
        getEmailAddsByType(e, "f").firstElement,
        getEmailAddsByType(e, "t"),
        getEmailAddsByType(e, "cc"),
        getEmailAddsByType(e, "bcc"),
        "${e.findAllElements("su").toList().firstElement?.text ?? ""}",
        "${e.findAllElements("fr").toList().firstElement?.text ?? ""}",
        getMessagePart([e]),
        t.data
      );
    } catch (e) {
      checkResponse(e, workspaceId);
      return null;
    }

  }

  static checkResponse(t, int workspaceId) async {
    var u = XmlDocument.parse(t.data);
    if (u.findAllElements("Code").first.text == "service.AUTH_REQUIRED"){
      logout(workspaceId);
    }
  }

  static logout(int workspaceId, {String type = "logout"}) async {
    if (type == "logout") {
      AccountZimbra account = ConfigZimbra.instance.currentAccountZimbra!;
      ConfigZimbra.instance.accounts = ConfigZimbra.instance.accounts.where((element) => element.email == account.email && element.workspaceId == workspaceId).toList();
    }
    ConfigZimbra.instance.currentAccountZimbra = null;
    LazyBox box = Hive.lazyBox("pairKey");
    await box.put("zimbra_$workspaceId", {
      "current_account_zimbra": null,
      "accounts": ConfigZimbra.instance.accounts.where((element) => element.workspaceId == workspaceId).map((e) => e.toJson()).toList()
    });
    dashboardZimbra.currentState?.initAccount();
  }

  static switchAccount(AccountZimbra account, int workspaceId) async {
    int index  = ConfigZimbra.instance.accounts.indexWhere((element) => element.email == account.email && element.workspaceId == workspaceId);
    if (index != -1){
      LazyBox box = Hive.lazyBox("pairKey");
      await box.put("zimbra_$workspaceId",  {
        ...(await box.get("zimbra_$workspaceId") ?? {}),
        "current_account_zimbra": account.toJson(),
        "accounts": ConfigZimbra.instance.accounts.where((element) => element.workspaceId == workspaceId).map((e) => e.toJson()).toList()
      });
      dashboardZimbra.currentState?.initAccount();
    }
  }

  static Map<String, String> addOriginMessage(MessageConvZimbra m, String content, {String type = "reply"}) {
    var xml = XmlDocument.parse(m.rawData);
    XmlElement? first  = xml.findAllElements("content").where((element) => Utils.checkedTypeEmpty(element.text) ).toList().firstElement;
    String? typeContent = first?.parent?.getAttribute("ct");
    if ((typeContent ?? "").contains("plain"))
      return {
        "type": "text/plain",
        "data": "$content\r\n\r\n----- ${type == "reply" ? "Original" : "Forwarded"} Message -----\r\nFrom: ${m.from?.displayName} <${m.from?.address}>\r\nTo: ${m.to.map((e) => "${e.displayName} <${e.address}>").join(", ")}\r\nSent: ${DateFormatter().renderTime(DateTime.fromMicrosecondsSinceEpoch(m.currentTime * 1000), type: "yMMMMd")}\r\n\r\n${first?.text}"
      };
    String html = first?.text ?? "";
    try {
      var t = XmlDocument.parse(first?.text ?? "");
      html = t.findAllElements("body").toList()[0].children[1].toString();
    } catch (e){
      html = first?.text ?? "";

    }

    if ((typeContent ?? "").contains("html"))
      return {
        "type": "text/html",
        "data": '<html><body><div style=\"font-family: arial, helvetica, sans-serif; font-size: 12pt; color: #000000\">${content.replaceAll("\n", "<br />")}<br/><br/><hr id=\"zwchr\" data-marker=\"\"/><div id="marker" data-marker=\"\"><b>From: </b> \"${m.from?.displayName}\" &lt;${m.from?.address}&gt;<br/><b>To: </b> ${m.to.map((e) => "\"${e.displayName}\" &lt;${e.address}&gt;").join(", ")}<br/><b>Send: </b> ${DateFormatter().renderTime(DateTime.fromMicrosecondsSinceEpoch(m.currentTime * 1000), type: "yMMMMd")}<br/></div><br/><div data-marker=\"\" id =\"marker\"><style style="display: none;">/*<![CDATA[*/P {margin-top: 0;margin-bottom: 0;}/*]]>*/</style>$html<br/></div></div></body></html>'
      };
    return {
      "type": "text/plain",
      "data": content
    };
  }

  static Future<bool> replyMessage(MessageConvZimbra m, String type, String content, List<Map> files, List<Map>? cc) async {
    try {
      files = files.where((element) => element["id_uploaded"] != -1 && element["id_uploaded"] != null).toList();
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element("soap:Envelope", nest: (){
        builder.attribute("xmlns:soap", "http://www.w3.org/2003/05/soap-envelope");
          builder.element("soap:Body", nest: (){
            builder.element("SendMsgRequest", nest: (){
              builder.attribute("xmlns", "urn:zimbraMail");
              builder.element("m", nest: (){
                builder.attribute("origid", "${m.id}");
                builder.attribute("rt", type);
                builder.attribute("irt", "${m.idHeader}");
                builder.attribute("su", m.subject.startsWith("Re:") ? m.subject : "Re: ${m.subject}");
                if (files.length > 0) {
                  builder.element("attach", nest: (){
                    builder.attribute("aid", files.map((e) => e["id_uploaded"]).toList().join(",") );
                  });
                }
                builder.element("e", nest: (){
                  builder.attribute("a", "${ConfigZimbra.instance.currentAccountZimbra?.email}");
                  builder.attribute("t", "f");
                  builder.attribute("p", "${ConfigZimbra.instance.currentAccountZimbra?.email.split("@").first}");
                });

                builder.element("e", nest: (){
                  builder.attribute("a", "${m.from!.address}");
                  builder.attribute("t", "t");
                  builder.attribute("p", "${m.from!.address.split("@").first}");
                });
                if (cc != null)
                  for (var i = 0; i < cc.length; i++) {
                    builder.element("e", nest: (){
                      builder.attribute("a", "${cc[i]["address"]}");
                      builder.attribute("t", "c");
                      builder.attribute("p", "${cc[i]["address"].split("@").first}");
                    });
                  }

                builder.element("mp", nest: (){
                  Map u = addOriginMessage(m, content);
                  builder.attribute("ct", u["type"]);
                  builder.element("content", nest: u["data"]);
                });
              });
          });
        });
      });

      var document = builder.buildDocument();
      var t = await Dio().post(ConfigZimbra.instance.currentAccountZimbra!.getSoapServiceEndpoint, data: document.toString(), options: Options(
        validateStatus: (status) => true,
        headers: {
          "content_type": "application/soap+xml",
          'Cookie': 'ZM_AUTH_TOKEN=${ConfigZimbra.instance.currentAccountZimbra!.authToken}',
        },
      ));
      var u = XmlDocument.parse(t.data);
      u.findAllElements("SendMsgResponse").first;
      convDetailZimbra.currentState!.getConv();
      dashboardZimbra.currentState?.getMail({});
      return true;
    } catch (e) {
      return false;

    }
  }


  static Future<bool> forwardMessage(MessageConvZimbra m, String type, String content, List<Map> selectedEmailToSend, List<Map> files) async {
    try {
      files = files.where((element) => element["id_uploaded"] != -1 && element["id_uploaded"] != null).toList();
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element("soap:Envelope", nest: (){
        builder.attribute("xmlns:soap", "http://www.w3.org/2003/05/soap-envelope");
          builder.element("soap:Body", nest: (){
            builder.element("SendMsgRequest", nest: (){
              builder.attribute("xmlns", "urn:zimbraMail");
              builder.element("m", nest: (){
                builder.attribute("su", m.subject.startsWith("Fw") ? m.subject : "Fw: ${m.subject}");
                if (files.length >0) {
                  builder.element("attach", nest: (){
                    builder.attribute("aid", files.map((e) => e["id_uploaded"]).toList().join(",") );
                  });
                }
                builder.attribute("origid", "${m.id}");
                builder.attribute("rt", type);
                builder.attribute("irt", "${m.idHeader}");
                for (var i in selectedEmailToSend){
                  builder.element("e", nest: (){
                    builder.attribute("a", "${i["email"]}");
                    builder.attribute("t", "t");
                    builder.attribute("p", "${i["name"]}");
                  });
                }

                builder.element("e", nest: (){
                  builder.attribute("a", "${ConfigZimbra.instance.currentAccountZimbra?.email}");
                  builder.attribute("t", "f");
                  builder.attribute("p", "${ConfigZimbra.instance.currentAccountZimbra?.email.split("@").first}");
                });


                builder.element("mp", nest: (){
                  Map u = addOriginMessage(m, content, type: "forward");
                  builder.attribute("ct", u["type"]);
                  builder.element("content", nest: u["data"]);
                });
              });
          });
        });
      });

      var document = builder.buildDocument();

      var t = await Dio().post(ConfigZimbra.instance.currentAccountZimbra!.getSoapServiceEndpoint, data: document.toString(), options: Options(
        validateStatus: (status) => true,
        headers: {
          "content_type": "application/soap+xml",
          'Cookie': 'ZM_AUTH_TOKEN=${ConfigZimbra.instance.currentAccountZimbra!.authToken}',
        },
      ));
      var u = XmlDocument.parse(t.data);
      u.findAllElements("SendMsgResponse").first;
      convDetailZimbra.currentState!.getConv();
      dashboardZimbra.currentState?.getMail({});
      return true;
    } catch (e) {
      return false;

    }
  }

    static Future<bool> sendMessage(String content, String subject, List<Map> selectedEmailToSend, List<Map> files) async {
    try {
      files = files.where((element) => element["id_uploaded"] != -1 && element["id_uploaded"] != null).toList();
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element("soap:Envelope", nest: (){
        builder.attribute("xmlns:soap", "http://www.w3.org/2003/05/soap-envelope");
          builder.element("soap:Body", nest: (){
            builder.element("SendMsgRequest", nest: (){
              builder.attribute("xmlns", "urn:zimbraMail");
              builder.element("m", nest: (){
                builder.attribute("su", subject);
                if (files.length > 0) {
                  builder.element("attach", nest: (){
                    builder.attribute("aid", files.map((e) => e["id_uploaded"]).toList().join(",") );
                  });
                }
                for (var i in selectedEmailToSend){
                  builder.element("e", nest: (){
                    builder.attribute("a", "${i["email"]}");
                    builder.attribute("t", "t");
                    builder.attribute("p", "${i["name"]}");
                  });
                }

                builder.element("e", nest: (){
                  builder.attribute("a", "${ConfigZimbra.instance.currentAccountZimbra?.email}");
                  builder.attribute("t", "f");
                  builder.attribute("p", "${ConfigZimbra.instance.currentAccountZimbra?.email.split("@").first} ");
                });
                builder.element("mp", nest: (){
                  builder.element("content", nest: content);
                });
              });
          });
        });
      });

      var document = builder.buildDocument();
      var t = await Dio().post(ConfigZimbra.instance.currentAccountZimbra!.getSoapServiceEndpoint, data: document.toString(), options: Options(
        validateStatus: (status) => true,
        headers: {
          "content_type": "application/soap+xml",
          'Cookie': 'ZM_AUTH_TOKEN=${ConfigZimbra.instance.currentAccountZimbra!.authToken}',
        },
      ));
      var u = XmlDocument.parse(t.data);
      u.findAllElements("SendMsgResponse").first;
      convDetailZimbra.currentState?.getConv();
      dashboardZimbra.currentState?.getMail({});
      return true;
    } catch (e, t) {
      print("sendmsg. $e, $t");
      return false;

    }
  }

  static autoComplete(String text) async {
    oneSchedule.scheduleOne(() async {
      try {
        final builder = XmlBuilder();
          builder.processing('xml', 'version="1.0"');
          builder.element("soap:Envelope", nest: (){
            builder.attribute("xmlns:soap", "http://www.w3.org/2003/05/soap-envelope");
              builder.element("soap:Body", nest: (){
                builder.element("AutoCompleteRequest", nest: (){
                  builder.attribute("xmlns", "urn:zimbraMail");
                  builder.attribute("name", text);
              });
            });
          });
          var document = builder.buildDocument();
          var t = await Dio().post(ConfigZimbra.instance.currentAccountZimbra!.getSoapServiceEndpoint, data: document.toString(), options: Options(
            validateStatus: (status) => true,
            headers: {
              "content_type": "application/soap+xml",
              'Cookie': 'ZM_AUTH_TOKEN=${ConfigZimbra.instance.currentAccountZimbra!.authToken}',
            },
          ));
          var u = XmlDocument.parse(t.data);
          var e = u.findAllElements("AutoCompleteResponse").first;
          List<Map> emailAuto = e.findElements("match").map((e) {
            return {
              "name": e.getAttribute("full") ?? e.getAttribute("first"),
              "email": e.getAttribute("email").toString().split(" ").last.replaceAll(RegExp(r'[<>]'), "")
            };
          }).toList();
          autoCompleteController.add(emailAuto);

      } catch (e, t) {
        print("autoComplete: $e, \n $t");
        autoCompleteController.add(<Map>[]);
      }

    }, timeDelay: 1);
  }

  static Future<String?>? uploadFile(String path) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(ConfigZimbra.instance.currentAccountZimbra!.domain + "/service/upload"));
      request.headers["Cookie"] = 'ZM_AUTH_TOKEN=${ConfigZimbra.instance.currentAccountZimbra!.authToken}';
      request.files.add(await http.MultipartFile.fromPath('file', path));
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String data  = await response.stream.bytesToString();
        var r = RegExp(r'[a-z0-9\-]{1,}:[a-z0-9\-]{1,}');
        return r.allMatches(data).toList()[0].group(0);
      }
      return null;
    } catch (e, t) {
      print("uploadFile, $e,\n\n\n\n\ $t");
    }
    return null;
  }

  static Future saveDraft(List<Map> fileSelected, List<Map> selectedEmailToSend, String to, String content, String topic, String type, MessageConvZimbra? messageSelected, int workspaceId) async {
    try {
      LazyBox box = Hive.lazyBox("pairKey");
      String key = getKeyDraft(type, parentMessageId: messageSelected?.id);
      await box.put("zimbra_$workspaceId", {
        ...(await box.get("zimbra_$workspaceId") ?? {}),
        "$key": {
          "file_selected": fileSelected,
          "selected_email_to_send": selectedEmailToSend,
          "content": content,
          "topic": topic,
          "to": to,
          "message_selected": messageSelected == null ? {} : messageSelected.toJson(),
        }
      });
    } catch (e, t) {
      print("saveDraft, $e, $t");
    }
  }

  static String getKeyDraft(String type, {String? parentMessageId}){
    switch (type) {
      case "new":
        return "new_${ConfigZimbra.instance.currentAccountZimbra!.email}";
      case "reply":
        return "reply_${ConfigZimbra.instance.currentAccountZimbra?.email}_$parentMessageId";
      case "forward":
        return "forward_${ConfigZimbra.instance.currentAccountZimbra?.email}_$parentMessageId";
      default: return "";
    }
  }

  static deleteDraft(int workspaceId, String type, {String? parentMessageId}) async {
    LazyBox box = Hive.lazyBox("pairKey");
    Map oldData = await box.get("zimbra_$workspaceId") ?? {};
    oldData.removeWhere((key, value) => key == getKeyDraft(type, parentMessageId: parentMessageId));
    await box.put("zimbra_$workspaceId", oldData);
  }

  static Future<void> noOpRequest(AccountZimbra current, {int loop = 50}) async {
    try {
      if (loop == 0) return;
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element("soap:Envelope", nest: (){
        builder.attribute("xmlns:soap", "http://www.w3.org/2003/05/soap-envelope");
        builder.element("soap:Header", nest: () {
          builder.element("context", nest: () {
            builder.attribute("xmlns", "urn:zimbra");
            builder.element("session", nest: () {
              builder.attribute("id", current.sessionId);
            });
          });
        });
        builder.element("soap:Body", nest: (){
          builder.element("NoOpRequest", nest: (){
          builder.attribute("xmlns", "urn:zimbraMail");
          builder.attribute("wait", 1);
          builder.attribute("limitToOneBlocked", 1);
        });
        });
      });
      var document = builder.buildDocument();
      var t = await Dio().post(current.getSoapServiceEndpoint, data: document.toString(), options: Options(
        validateStatus: (status) => true,
        headers: {
          "content_type": "application/soap+xml",
          'Cookie': 'ZM_AUTH_TOKEN=${current.authToken}',
        },
      ));
      //check account has existed
      int index = ConfigZimbra.instance.accounts.indexWhere((element) => element.isEqual(current));
      if (index == -1) return;
      var u = XmlDocument.parse(t.data.toString().replaceAll('''<meta http-equiv="Refresh" content="0;url=public/noscript.jsp" >''', '''<meta http-equiv="Refresh" content="0;url=public/noscript.jsp" />'''));
      XmlElement noOpResponse = u.findAllElements("NoOpResponse").toList()[0];
      bool waitDisallowed = (noOpResponse.getAttribute("waitDisallowed") ?? "") == "1";
      if (waitDisallowed){
        return;
      }
      List<XmlElement> i = u.findAllElements("m").toList();
      if (i.length > 0) {
        if (getEmailAddsByType(i[0], "f").firstElement != null && (getEmailAddsByType(i[0], "f").firstElement as EmailAdd).address == current.email) return;
        if (i[0].getAttribute("cid") == null) return noOpRequest(current, loop: loop -1);
        int convId = int.parse("${i[0].getAttribute("cid")}");
        MacOSInitializationSettings initializationSettingsMacOS = MacOSInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true
        );
        final InitializationSettings initializationSettings =
          InitializationSettings(
            macOS: initializationSettingsMacOS
        );
        flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onSelectNotification: (payload) async {
            try {
              Map p = (jsonDecode(payload ?? ""));
              Map account = p["account"] ?? {};
              int workspaceId = account["workspace_id"];
              var index = ConfigZimbra.instance.accounts.indexWhere((element) => element.workspaceId == account["workspace_id"] && element.email == account["email"]);
              if (index == -1) return;
              ConfigZimbra.instance.currentAccountZimbra = ConfigZimbra.instance.accounts[index];
              LazyBox box = Hive.lazyBox("pairKey");
              await box.put("zimbra_$workspaceId}",  {
                ...(await box.get("zimbra_$workspaceId") ?? {}),
                "current_account_zimbra": account,
                "accounts": ConfigZimbra.instance.accounts.where((element) => element.workspaceId == workspaceId).map((e) => e.toJson()).toList()
              });
              if (dashboardZimbra.currentState != null) dashboardZimbra.currentState!.initAccount();
              showDialog(
                context: Utils.globalMaterialContext!,
                builder: (BuildContext c) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    content: Container(
                      height: MediaQuery.of(Utils.globalMaterialContext!).size.height* 0.8,
                      width: MediaQuery.of(Utils.globalMaterialContext!).size.width* 0.8,
                      child: ConvDetailZimbra(key: ServiceZimbra.convDetailZimbra, conv: MailZimbra(
                        convId,
                        0,
                        0,
                        0,
                        "",
                        "",
                        [],
                        false,
                        []
                      ), workspaceId: workspaceId,),
                    ),
                  );
                }
              );
            } catch (e, t) {
              print("onclick noti email, $e, $t $payload");
            }
          }
        );
        String subBody = "";
        String subTitle = "New mail to: ${current.email}";
        try {
          subBody = i[0].findAllElements("fr").toList()[0].text;
        } catch (e, t) {
          print("get frffrfrr $e, $t");
        }

        if (Platform.isWindows){
          MethodChannel notifyChannel = MethodChannel("notify");
          notifyChannel.invokeMethod("push_notify",[subTitle, subBody]);
        }
        if (Platform.isMacOS){
          var macOSPlatformChannelSpecifics = new MacOSNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

          flutterLocalNotificationsPlugin.show(
            convId + current.workspaceId,
            subTitle,
            subBody,
            NotificationDetails(macOS: macOSPlatformChannelSpecifics),
            payload: jsonEncode( {
              "conv_id":  i[0].getAttribute("cid") ?? "",
              "account": current.toJson()
            })
          );
        }
        if (dashboardZimbra.currentState != null && (dashboardZimbra.currentState?.selectedHeader).toString().contains("inbox") && dashboardZimbra.currentState?.widget.workspaceId == current.workspaceId) {
          dashboardZimbra..currentState?.dataMails = [];
          dashboardZimbra.currentState?.getMail({});
        }
        current.convIdUnread = Map.fromIterable(current.convIdUnread + [convId], key: (v) => v, value: (v) => v as int).values.toList();
        ConfigZimbra.instance.accounts[index].convIdUnread = current.convIdUnread;
        streamAccounts.add(ConfigZimbra.instance.accounts);
        noOpRequest(current, loop: 50);
      } else {
        u.findAllElements("NoOpResponse");
        return noOpRequest(current, loop: loop -1);
      }
    } catch (e) {
      await Future.delayed(Duration(seconds: 10));
      // print("########################################################################:$e, $t");
      noOpRequest(current, loop: loop -1);
    }

  }

  static endSessionZimbra(AccountZimbra acc) async {
    try {
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0"');
      builder.element("soap:Envelope", nest: (){
        builder.attribute("xmlns:soap", "http://www.w3.org/2003/05/soap-envelope");
        builder.element("soap:Body", nest: (){
          builder.element("EndSessionRequest", nest: (){
            builder.attribute("xmlns", "urn:zimbraAccount");
            builder.attribute("sessionId", acc.sessionId);

          });
        });
      });
      var document = builder.buildDocument();
      await Dio().post(acc.getSoapServiceEndpoint, data: document.toString(), options: Options(
        validateStatus: (status) => true,
        headers: {
          "content_type": "application/soap+xml",
          'Cookie': 'ZM_AUTH_TOKEN=${acc.authToken}',
        },
      ));
    } catch (e) {
    }
  }

  static initAllAccount(List workspacesIds) async {
    LazyBox box = Hive.lazyBox("pairKey");
    ConfigZimbra.instance.accounts =(
      await Future.wait(
        workspacesIds.map(
          (workspaceId) async {
            Map data = (await box.get("zimbra_$workspaceId")) ?? {};
            List accounts = Map.fromIterable(data["accounts"] ?? [], key: (v) => v["email"], value: (v) => v as Map).values.toList();
            return (
              await Future.wait(
                accounts.map(
                  (acc) async {
                    await endSessionZimbra(AccountZimbra.initAccountZimbra(acc)!);
                    return newLogin(acc["email"], acc["password"], workspaceId, acc["domain"]);
                  }
                )
              )
            ).whereType<AccountZimbra>().toList();
          }
        )
      )
    )
    .reduce((value, element) => value + element);
  }

  static int getNewMessageCount(int workspaceId){
    try {
      return ConfigZimbra.instance.accounts.where((element) => element.workspaceId == workspaceId).toList().map((e) => e.convIdUnread.length).reduce((value, element) => value + element);
    } catch (e) {
      return 0;
    }
  }
}

 extension UtilListExtension on List{
  get firstElement => this.length > 0 ? this.first : null;
}