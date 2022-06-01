import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:workcake/E2EE/GroupKey.dart';
import 'package:workcake/E2EE/e2ee.dart';
import 'package:encrypt/encrypt.dart' as En;
import 'package:workcake/common/utils.dart';

class ConversationKey {
  var conversationKey;
  var conversationId;
  var nextConversationKey;
  var listThreadKeys;
  var nextPublicKey;
  var defaultConversationKey;
  var currentTime;
  var box;
  var dataHive;

  ConversationKey(
    this.conversationKey, 
    this.conversationId, 
    this.listThreadKeys, 
    this.defaultConversationKey,
    this.dataHive
  );

  String getMessageKey(){
    return this.conversationKey;
  }

  String getPublicKeySender(String userId){
    return "";
  }

  static Future<Map> getConversationKey(String conversationId, String currentUserId, List users) async {
    try {
      var box =  await Hive.openLazyBox("pairKey");
      var idDefaultPrivateKey = await box.get("id_default_private_key");
      Map signedKey = await box.get("signedKey");
      // check Hive da co data ve hoi thoai hay chua.
      var dataConv =  await box.get(conversationId);
      // get PublicKey
      var publicKey;
      var idDefaultPublicKey;
      if (users.length  == 1) {
        idDefaultPublicKey = users[0]["id_default_public_key"];
        publicKey = users[0]["public_key"];}
      else {
        List secondUser = users.where((ele) {return ele["user_id"] != currentUserId;}).toList();
        publicKey = secondUser[0]["public_key"];
        idDefaultPublicKey = secondUser[0]["id_default_public_key"];
      }
      // get listThreadKey
      List<MemberKey> sharedkeys = [];
      for (var i = 0; i< users.length; i++){
        var currentUserPublicKey =  users[i]["public_key"];
        var currentUserDefualtPublicKey = users[i]["id_default_public_key"];
        if (currentUserPublicKey == null && currentUserDefualtPublicKey == null) continue;
        // su dung key nay khi ko co public key co giai ma va ma hoa tin nhan
        // key nay se dc dung de giai ma tin nhan sau khi dung skey that bai va ko cos trong Hive
        var defaultSharedkeyKey =  await X25519().calculateSharedSecret(
          KeyP.fromBase64(signedKey["privKey"], false),
          KeyP.fromBase64(currentUserDefualtPublicKey, true)
        );
        var keyDe;
        try {
          var skey =  await X25519().calculateSharedSecret(
          KeyP.fromBase64(signedKey["privKey"], false),
          KeyP.fromBase64(currentUserPublicKey, true)
        );
          // sharedkeys dung de ma hoa tin nhan thread
          keyDe = Utils.decrypt(users[i]["message_shared_key"], skey.toBase64());
        } catch (e) {
        }
        sharedkeys += [MemberKey(users[i]["user_id"], conversationId, keyDe, defaultSharedkeyKey.toBase64(), users[i]["public_key"], "")];
      }
      if ( dataConv == null || (dataConv != null && dataConv["public_key"] != publicKey) || (dataConv != null &&  dataConv["default_key"] == null)){
        Map signedKey = await box.get("signedKey");
        var masterKey;
        var defaultMasterKey;
        try {
          masterKey = await X25519().calculateSharedSecret(KeyP.fromBase64(signedKey["privKey"], false), KeyP.fromBase64(publicKey, true));
        } catch (e) {
        }
        try {
          defaultMasterKey = await X25519().calculateSharedSecret(KeyP.fromBase64(idDefaultPrivateKey, false), KeyP.fromBase64(idDefaultPublicKey, true));
        } catch (e) {
        }
        var dataHive  = Utils.mergeMaps([
          dataConv == null ? {} : dataConv,
          {
            "key": masterKey == null ? null : masterKey.toBase64(), 
            "default_key": defaultMasterKey == null ? null : defaultMasterKey.toBase64(),
            "public_key": publicKey,
          }
        ]);
        // save Hive
        await box.put(conversationId, dataHive);

        return {
          "conversationKey": masterKey == null ? null : masterKey.toBase64(), 
          "defaultConversationKey": defaultMasterKey == null ? null : defaultMasterKey.toBase64(),
          "sharedkeys": sharedkeys,
          "dataHive": dataHive
        };
      }
      else {
        return {
          "conversationKey": dataConv["key"],
          "defaultConversationKey":  dataConv["default_key"],
          "sharedkeys": sharedkeys,
          "dataHive": dataConv
        };
      }
    } catch (e) {
      print("SDFSdfdsFSDFSDfsdfsfdsfsdfdnsflsndfje  $e");

      return {};
    }
  }

  void getNextkey()async{

  }

  Future<Map> encryptMessage(String text, String userId, bool isThread)async {
  // cac tin nhan 1-1 deu phai co public_key_sender`
    try {
      if (isThread){
        var index = listThreadKeys.indexWhere((element) => element.userId == userId);
        if (index == -1){
          return {};
        }
        else {
          MemberKey memberKey = listThreadKeys[index];
          return memberKey.encryptByMember(text);
        }

      }
      else {
        if (this.conversationKey != null){
          var pairKey = await X25519().generateKeyPair();
          var nextKey  = await X25519().calculateSharedSecret(KeyP.fromBase64(this.conversationKey, false) , pairKey.publicKey);
          this.nextPublicKey =  pairKey.publicKey.toBase64();
          this.nextConversationKey = nextKey.toBase64();
          // init encrypted

          final key = En.Key.fromBase64(this.nextConversationKey);
          final iv  =  En.IV.fromLength(16);
          final encrypter = En.Encrypter(En.AES(key, mode: En.AESMode.cbc));
          // return data
          return  {
            "success": true,
            "publicKey": this.nextPublicKey,
            "message": encrypter.encrypt(text, iv: iv).base64
          };
        } else {
          final key = En.Key.fromBase64(this.defaultConversationKey);
          final iv  =  En.IV.fromLength(16);
          final encrypter = En.Encrypter(En.AES(key, mode: En.AESMode.cbc));
          // return data
          return  {
            "success": true,
            "message": encrypter.encrypt(text, iv: iv).base64
          };
        }
      }
    } catch (e) {
      print("err $e");
      return {
        "success": false,
        "message": null
      };
    }
    
  }

  Future<Map> decryptMessage(Map message) async {
    try {
      if (Utils.checkedTypeEmpty(message["parent_id"])){
        var index = listThreadKeys.indexWhere((element) => element.userId == message["user_id"]);
        if (index == -1){
          return {
            "success": false
          };
        }
        else {
          MemberKey memberKey = listThreadKeys[index];
          return memberKey.decryptMessageByMember(message);
        }
      }else {
        // // /thu giai bang conversation Key
        // neu ko giai dc   giai banbg default key
          var messageEncrypted =  message["message"];
          var publicKey =  message["public_key_sender"];
        try {
          // get next Message Key
          var nextMessageKey = await X25519().calculateSharedSecret(KeyP.fromBase64(this.conversationKey, false), KeyP.fromBase64(publicKey, true));
          // init encrypted
          final key = En.Key.fromBase64(nextMessageKey.toBase64());
          final iv  =  En.IV.fromLength(16);
          final encrypter = En.Encrypter(En.AES(key, mode: En.AESMode.cbc));
          var encrypted =  En.Key.fromBase64(messageEncrypted);
          var dataDecrypt =  encrypter.decrypt(encrypted, iv: iv);
          // parse String to json
          dataDecrypt = dataDecrypt;
          Map resultDataDecrypted = jsonDecode(dataDecrypt);
          // return data
          var dataFinalMessage  = Map.from(message);
          dataFinalMessage["message"] =  resultDataDecrypted["message"];
          dataFinalMessage["attachments"] = resultDataDecrypted["attachments"];
          this.conversationKey = nextMessageKey.toBase64();
          // save new key to Hive
          this.dataHive = Utils.mergeMaps([this.dataHive ?? {}, {"key": nextMessageKey.toBase64()}]);
          var box = Hive.lazyBox("pairKey");
          await box.put(this.conversationId, this.dataHive);
          return {
            "success": true,
            "message": dataFinalMessage
          };
        } catch (e) {
          final key = En.Key.fromBase64(this.defaultConversationKey);
          final iv  =  En.IV.fromLength(16);
          final encrypter = En.Encrypter(En.AES(key, mode: En.AESMode.cbc));
          var encrypted =  En.Key.fromBase64(messageEncrypted);
          var dataDecrypt =  encrypter.decrypt(encrypted, iv: iv);
          // parse String to json
          dataDecrypt = dataDecrypt;
          Map resultDataDecrypted = jsonDecode(dataDecrypt);
          // return data
          var dataFinalMessage  = Map.from(message);
          dataFinalMessage["message"] =  resultDataDecrypted["message"];
          dataFinalMessage["attachments"] = resultDataDecrypted["attachments"];
          return {
            "success": true,
            "message": dataFinalMessage
          };
        }
      }  
    } catch (e) {
      // print("___E__: $e  ${this.conversationId}  ${this.conversationKey} ${this.defaultConversationKey}");
      return {
        "success": false,
        "message": null
      };
    }
  }
}