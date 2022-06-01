import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:workcake/models/models.dart';

Container circularProgress() {
  return Container(
    color: Colors.transparent,
    padding: EdgeInsets.only(top: 10.0),
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.cyan[200]),
      ));
}

Container circularProgressForChatScreen() {
  return Container(
    color: Color(0xff0d1a26),
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.purple),
      ));
}

Widget spinkit(){ 
  return SpinKitCircle(
  color: Colors.white,
  size: 20.0,
);}

getRandomInt(range) {
  Random random = new Random();

  return random.nextInt(range).toDouble();
}

getRandomBool() {
  final randomNumberGenerator = Random();
  final randomBoolean = randomNumberGenerator.nextBool();
  
  return randomBoolean;
}

Container shimmerEffect(context, {int number = 20}) {
  final auth = Provider.of<Auth>(context);
  final isDark = auth.theme == ThemeType.DARK;

  return Container(
    height: number * 70,
    width: double.infinity,
    padding: EdgeInsets.only(top: 12.0, left: 12.0, right: 12),
    child: SingleChildScrollView(
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.black12 : Color(0xffe2e5e8),
        highlightColor: isDark ? Colors.black26 : Colors.grey[100]!,
        enabled: true,
        child: Column(
          children: List.generate(number, (i) => i).map((_) => Padding(
            padding: EdgeInsets.only(bottom: 14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42.0,
                  height: 42.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  
                ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 6),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15)
                        ),
                        width: getRandomInt(100) + 50,
                        height: 14,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 2.0)
                      ),
                      Container(
                        width: getRandomInt(100) + 150,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15)
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 2.0)
                      ),
                      // getRandomBool() ? Container() :
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15)
                        )
                      ) ,
                    ],
                  ),
                )
              ],
            )
          )).toList(),
        ),
      ),
    ),
  );
}

Scaffold specialCircularProgress(){
  return Scaffold(
    body: SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 40, horizontal: 30),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text('Initializing...',
                textAlign: TextAlign.center,
                style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 23,
                color: Colors.blue,
              ),),
              SizedBox(
                height: 7,
              ),
              Text('Please wait a moment',textAlign:TextAlign.center, style: TextStyle(fontSize: 18,fontWeight:FontWeight.w600 ,color: Colors.blueGrey),),
              SizedBox(
                height: 70,
              ),
              Image.asset('images/chat-features-crop_1x.png'),
              SizedBox(
                height: 70,
              ),
              CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.blue),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Container linearProgress() {
  return Container(
    padding: EdgeInsets.only(bottom: 10.0),
    child: LinearProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Colors.purple),
    ),
  );
}