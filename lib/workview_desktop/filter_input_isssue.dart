import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workcake/models/models.dart';

import 'issue_table.dart';

class FilterInput extends StatefulWidget {
  FilterInput({Key? key}) : super(key: key);

  @override
  _FilterInputState createState() => _FilterInputState();
}

class _FilterInputState extends State<FilterInput> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    
    return  Container(
      margin: EdgeInsets.only(top: 12),
      width: (MediaQuery.of(context).size.width - 348),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Color(0xff323F4B) : Colors.grey[300]!
        ),
        borderRadius: BorderRadius.circular(3)
      ),
      child: Row(
        children: [
          OutlinedButton(
            style: ButtonStyle(
              padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 12, horizontal: 18)),
              // borderSide: BorderSide(color: Colors.grey[600]!, width: 0.5),
            ),
            child: Row(
              children: [
                Text("Filters", style: TextStyle(fontSize: 15, color: isDark ? Colors.grey[300] : Colors.grey[700])),
                Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white54 : Colors.grey[700], size: 18)
              ],
            ),
            onPressed: () {  }
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(4),
              height: 28.5,
              child: TextField(
                focusNode: AlwaysDisabledFocusNode(),
                cursorHeight: 16,
                cursorColor: Colors.grey[700],
                onChanged: (value) {},
                decoration: InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 15, height: 1, color: Colors.grey[700]),
                  contentPadding: EdgeInsets.only(bottom: 19, left: 6),
                  // hintText: filters.length > 0 ? parseFilterToString() : ""
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}