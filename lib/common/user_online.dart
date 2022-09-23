import 'package:flutter/material.dart';
import 'package:workcake/common/cache_avatar.dart';

class UserOnline extends StatelessWidget {
  final avatarUrl;
  final name;
  final isOnline;
  const UserOnline({ Key? key, this.avatarUrl, required this.name, this.isOnline = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CachedAvatar(
          avatarUrl ?? "", 
          name: name, 
          width: 28, 
          height: 28
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0),
              color: isOnline ? Colors.green : Colors.transparent
            ),
          ),
        )
      ],
    );
  }
}