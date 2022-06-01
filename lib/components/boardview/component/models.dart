import 'package:flutter/material.dart';

class CardMember {
  String name;
  String avatarUrl;
  String id;

  CardMember({required this.name, required this.avatarUrl, required this.id});
}

class CardDetailButton{
  IconData icon;
  String title;
  Function callback;

  CardDetailButton({required this.title, required this.icon, required this.callback});
}

class Label{
  String colorHex;
  String title;
  String id;

  Label({required this.colorHex, required this.title, required this.id});
}