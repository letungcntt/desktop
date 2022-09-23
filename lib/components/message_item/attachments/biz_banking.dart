import 'package:flutter/material.dart';
import 'package:workcake/flutter_mention/custom_selection.dart';
import 'package:workcake/providers/providers.dart';

class BizBankingAttachments extends StatefulWidget {
  final att;
  const BizBankingAttachments({Key? key, this.att}) : super(key: key);

  @override
  State<BizBankingAttachments> createState() => _BizBankingAttachmentsState();
}

class _BizBankingAttachmentsState extends State<BizBankingAttachments> {
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;
    final att = widget.att;

    return CustomSelectionArea(
      child: Container(
        margin: EdgeInsets.only(bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container(
            //   child: ClipRRect(
            //     borderRadius: BorderRadius.circular(8.0),
            //     child: Image.asset(
            //       "assets/images/logo_app/bank_app.png",
            //       width: 30,
            //       height: 30,
            //       color: isDark ? Color(0xFFd8dcde) : Colors.grey[800],
            //     ),
            //   ),
            // ),
            // Container(width: 10),
            att['data']['transfer']['success'] == null
              ? Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: Text(
                        "Biz Banking" + (att['data']['transfer']['bank'] != null ? " (${att['data']['transfer']['bank'].toString().toUpperCase()})" : " (Techcombank)"),
                        style: TextStyle(
                          fontSize: 16
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 150,
                          child: Text(
                            "Mã giao dịch:",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Color(0xffA6A6A6) : Color(0xff828282)
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            child: Text(
                              att['data']['transfer']['id'],
                              style: TextStyle(
                                color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E)
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 150,
                          child: Text(
                            "Thời gian:",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Color(0xffA6A6A6) : Color(0xff828282)
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            child: Text(
                              att['data']['transfer']['date'],
                              style: TextStyle(
                                color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E)
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 150,
                          child: Text(
                            "Nội dụng",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Color(0xffA6A6A6) : Color(0xff828282)
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            child: Text(
                              att['data']['transfer']['note'],
                              style: TextStyle(
                                color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E)
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 150,
                          child: Text(
                            "Số tiền giao dịch:",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Color(0xffA6A6A6) : Color(0xff828282)
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            child: Text(
                              att['data']['transfer']['amount'] + " VND",
                              style: TextStyle(
                                color: att['data']['transfer']['amount'].toString().contains("-") ? Color(0xffFF7875) : Color(0xff52C41A)
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 150,
                          child: Text(
                            "Số dư",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Color(0xffA6A6A6) : Color(0xff828282)
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            child: Text(
                              att['data']['transfer']['remain'] + " VND",
                              style: TextStyle(
                                color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E)
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            : Column(
              children: [
                Container(
                  child: Text(
                    "Biz Banking",
                    style: TextStyle(
                      fontSize: 16
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Container(
                  child: Text(
                    att['data']['transfer']['message'],
                    style: TextStyle(
                      color: isDark ? Color(0xffDBDBDB) : Color(0xff5E5E5E)
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}