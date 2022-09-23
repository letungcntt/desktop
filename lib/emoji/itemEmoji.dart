import 'package:flutter/material.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/emoji/emoji.dart';

class ItemEmoji {
  var name;
  var id;
  var value;
  var skin;
  var custom;
  var type;
  var url;
  var onTap;
  var onHover;

  ItemEmoji(this.id, this.name, this.value, this.skin, this.custom, this.type, this.url, this.onTap, this.onHover);

  getItemEmoji(){
    return;
  }

  static ItemEmoji castObjectToClass(Map obj){
    return ItemEmoji(
      obj["id"] ?? obj["emoji_id"] ?? "",
      obj["name"] ??  "",  
      obj["value"] ??  "",
      obj["skin"] ??  "",
      obj["custom"] ??  "",
      obj["type"],
      obj["url"] ??  "",
      obj["opTap"],
      obj["onHover"],
    );
  }

  toJson(){
    return {
      "id": id,
      "name": name,
      "value": value,
      "skin": skin,
      "custom": custom,
      "type": type,
      "url": url,
    };
  }

  render({double size = 22, var padding = 5.0, bool isEnableHover = true, double heightLine = 0.0}){
    
    if (isEnableHover) {
      return HoverItem(
        onHover: (){
          if (onHover != null) {
            onHover(this);
          }
        },
        onExit: (){
          if (onHover != null) {
            onHover(null);
          }
        },
        colorHover: Palette.hoverColorDefault,
        child: InkWell(
          onTap: () {
            if (onTap != null) onTap(this);
          },
          child: Container(
            padding: EdgeInsets.all(padding),
            height: type == "default" ? 48 : size *2,
            width: type == "default" ? 48 : size *2,
            child: Center(
              child: type == "default"
                ? RichText(
                  text: TextSpan(
                    text: value, style: TextStyle(fontSize: size, fontFamilyFallback: ['Roboto', 'Apple Color Emoji'])
                  ),
                )
                : CachedImage(url, height: size* 2, width:  size* 2,)
            )
          ),
        ),
      );
    }
    return type == "default"
      ? RichText(
        text: TextSpan(
          text: value, style: TextStyle(fontSize: size,  height: heightLine, fontFamilyFallback: ['Roboto', 'Apple Color Emoji'])
        ),
      )
      : CachedImage(url, height: size* 2, width:  size* 2,);
  }
}