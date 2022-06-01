import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/custom_search_bar.dart';
import 'package:workcake/models/models.dart';

class AddFriendUsername extends StatefulWidget {
  @override
  _AddFriendUsernameState createState() => _AddFriendUsernameState();
}

class _AddFriendUsernameState extends State<AddFriendUsername> {
  final TextEditingController _searchQuery = new TextEditingController();
  var usernameTag;

  @override
  void dispose() {
    _searchQuery.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User>(context, listen: false).currentUser;
    final token = Provider.of<Auth>(context).token;
    return Container(
      alignment: Alignment.center,
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 50),
          Text(
            "Add your friend on Pancake Chat",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold
            ),
          ),
          SizedBox(height: 20),
          Text(
            "You will need both their username and a tag. Keep in mind that username is case sensitive.",
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          Container(
            alignment: Alignment.topLeft,
            margin: EdgeInsets.only(left: 15, right: 15),
            child: Text(
              "USERNAME",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600
              ),
            ),
          ),
          SizedBox(height: 10),
          Container(
            margin: EdgeInsets.only(left: 15, right: 15),
            child: CustomSearchBar(
              autoFocus: true,
              prefix: false,
              controller: _searchQuery,
              placeholder: "Username#0000",
              onChanged: (value) {
                // RegExp(r'^[0-9]+$').hasMatch(value);
                setState(() {
                  usernameTag = value;
                });
                // if (_debounce?.isActive ?? false) _debounce.cancel();
                // _debounce = Timer(const Duration(milliseconds: 500), () {
                  
                // });
              },
            ),
          ),
          SizedBox(height: 10),
          Container(
            alignment: Alignment.topLeft,
            margin: EdgeInsets.only(left: 15, right: 15),
            child: Text("Your username and tag is ${currentUser["full_name"]}#${currentUser["custom_id"]}")
          ),
          SizedBox(height: 20),
          Container(
            margin: EdgeInsets.only(left: 15, right: 15),
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              onPressed: () {
                Provider.of<User>(context, listen: false).sendFriendRequestTag(usernameTag, token).then((data) {
                  final snackBar = SnackBar(
                    duration: Duration(seconds: 2),
                    content: Text(
                      data["message"],
                      style: TextStyle(
                        color: Utils.checkedTypeEmpty(data["success"]) ? Colors.white : Colors.red
                      ),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  // Scaffold.of(context).showSnackBar(snackBar);
                  if(data["success"]) _searchQuery.clear();
                });
              },
              child: Text("Send Friend Request"),
            ),
            // child: FlatButton(
            //   onPressed: () {
            //   },
            //   color: Utils.getPrimaryColor(),
            //   child: Text("Send Friend Request", style: TextStyle(color: Colors.white))
            // ),
          ),
        ],
      )
    );
  }
}