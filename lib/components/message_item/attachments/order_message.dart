import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workcake/common/cached_image.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/models/models.dart';

class OrderAttachments extends StatefulWidget {
  final att;
  final id;

  const OrderAttachments({ Key? key, @required this.att, @required this.id }) : super(key: key);

  @override
  State<OrderAttachments> createState() => _OrderAttachmentsState();
}

class _OrderAttachmentsState extends State<OrderAttachments> {
  _createDirectMessageToSupportLeveraPay(String token) async {
    final data = {
      "users": [{"user_id": "0402cd81-7a28-48ce-bdf3-76335f7a138f"}],
      "name": "Levera Pay Support"
    };
    final userId = Provider.of<Auth>(context, listen: false).userId;
    await Provider.of<DirectMessage>(context, listen: false).createDirectMessage(token, data, context, userId);
  }

  _launchURL() async {
    const url = 'https://flutter.io';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  handleOrderToPos(key, orderId, shopId, messageId) async {
    final token = Provider.of<Auth>(context, listen: false).token;
    String url = "${Utils.apiUrl}business/handle_order_to_pos?token=$token";

    try {
      var response  =  await Dio().post(url, data: {
        "messageId": messageId,
        "id": orderId,
        "shopId": shopId,
        "leveraPay": {"status": key}
      });
      var resData = response.data;

      if(resData["success"] == false) {}
    } catch (e) {
      // sl.get<Auth>().showErrorDialog(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final att = widget.att;
    final id = widget.id;

    return Container(
      width: 400,
      margin: EdgeInsets.only(top: 10),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Palette.darkSelectedChannel : Palette.lightSelectedChannel.withOpacity(0.25),
            width: 1,
          ),
        ),
        color: isDark ? Palette.defaultBackgroundDark : Palette.defaultBackgroundLight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Container(
                height: 32, width: 32,
                decoration: BoxDecoration(
                  color: Color(0xffF6FFED),
                  border: Border.all(color: Color(0xff27AE60)),
                  borderRadius: BorderRadius.circular(50)
                ),
                child: Icon(CupertinoIcons.check_mark, color: Color(0xff27AE60), size: 16,)
              ),
              title: Text(
                'ORDER CONFIRMATION (ID: ${att['data']['order_id']})',
                style: TextStyle(
                  fontWeight: FontWeight.w600
                ),
              ),
            ),
            ListTile(
              leading: Text(""),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${att['data']['elements'].length} items/${NumberFormat.simpleCurrency(locale: 'vi').format(att["data"]["summary"]["total_cost"])}",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Ordered on: ${DateFormatter().renderTime(DateTime.parse(att["data"]["timestamp"]), type: 'kk:mm dd/MM')}",
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Phone number: ${att["data"]["phone_number"]}',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Paid with: ${att["data"]["payment_method"]}',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Ship to: ${att["data"]["address"]}',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  InkWell(
                    onTap: () {_showAlert(context, att["data"]);},
                    child: Text(
                      'Chi tiết đơn hàng',
                      style: TextStyle(fontSize: 14, color: Colors.blueAccent, decoration: TextDecoration.underline),
                    ),
                  ),
                  SizedBox(height: att['data']['levera_pay']?['status'] == 'pending' ? 10 : 0),
                  att['data']['levera_pay']?['status'] == 'pending' ? Divider() : SizedBox(),
                  SizedBox(height: att['data']['levera_pay']?['status'] == 'pending' ? 10 : 0),
                  att['data']['levera_pay']?['status'] == 'pending'
                      ? Row(
                        // mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TextButton(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Áp dụng'),
                            ),
                            style: TextButton.styleFrom(
                              primary: Colors.white,
                              backgroundColor: Color(0xff2A5298),
                              textStyle: TextStyle(
                                  color: Colors.black,
                              ),
                            ),
                            onPressed: () {
                              handleOrderToPos("apply", att["data"]["order_id"], att["data"]["shop_id"], id);
                            },
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Bỏ qua'),
                            ),
                            style: TextButton.styleFrom(
                              primary: Colors.white,
                              backgroundColor: Colors.red[500],
                              textStyle: TextStyle(
                                  color: Colors.black,
                              ),
                            ),
                            onPressed: () {
                              handleOrderToPos("ignore", att["data"]["order_id"], att["data"]["shop_id"], id);
                            },
                          ),
                        ],
                      ) : Container(),
                  SizedBox(height: 10),
                  Divider(),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(CupertinoIcons.ellipses_bubble, size: 16, color: Color(0xff616E7C)),
                              SizedBox(width: 8),
                              Text('Liên hệ hỗ trợ', style: TextStyle(color: Color(0xff616E7C), fontWeight: FontWeight.w400)),
                            ],
                          ),
                        ),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                              side: BorderSide(color: Color(0xff7B8794))
                            )
                          )
                        ),
                        onPressed: () {_createDirectMessageToSupportLeveraPay(auth.token);},
                      ),
                      SizedBox(width: 5),
                      TextButton(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(CupertinoIcons.star, size: 16, color: Color(0xff616E7C)),
                              SizedBox(width: 5),
                              Text('Tìm hiểu dịch vụ', style: TextStyle(color: Color(0xff616E7C), fontWeight: FontWeight.w400)),
                            ],
                          ),
                        ),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                              side: BorderSide(color: Color(0xff7B8794))
                            )
                          )
                        ),
                        onPressed: _launchURL,
                      ),
                    ]
                  ),
                  SizedBox(height: 10)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showAlert(BuildContext context, order) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32)
      ),
      content: ShowInfomationOrder(
        order: order
      )
    )
  );
}

class ShowInfomationOrder extends StatefulWidget {
  final order;
  const ShowInfomationOrder({ Key? key, this.order }) : super(key: key);

  @override
  _ShowInfomationOrderState createState() => _ShowInfomationOrderState();
}

class _ShowInfomationOrderState extends State<ShowInfomationOrder> {
  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Container(
      width: 450,
      height: 550,
      child: Column(
        children: [
          Container(
            height: 40,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xff52606D),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))
            ),
            child: Center(
              child: Text(
                'ORDER CONFIRMATION (ID: ${order["order_id"]})',
                style: TextStyle(color: Colors.white, fontSize: 13)
              )
            )
          ),
          Container(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Ordered on", style: TextStyle(fontSize: 13, color: Color(0xff52606D))),
                          SizedBox(height: 8),
                          Text(
                            DateFormatter().renderTime(DateTime.parse(order["timestamp"]), type: 'kk:mm dd/MM'),
                            style: TextStyle(
                              color: Color(0xff1F2933),
                              fontSize: 14
                            )
                          ),
                        ],
                      )
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Paid with on", style: TextStyle(fontSize: 13, color: Color(0xff52606D))),
                          SizedBox(height: 8),
                          Text(
                            order["payment_method"],
                            style: TextStyle(
                              color: Color(0xff1F2933),
                              fontSize: 14
                            )
                          ),
                        ],
                      )
                    ),
                  ]
                ),
                SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Phone number", style: TextStyle(fontSize: 13, color: Color(0xff52606D))),
                          SizedBox(height: 8),
                          Text(
                            order["phone_number"],
                            style: TextStyle(
                              color: Color(0xff1F2933),
                              fontSize: 14
                            )
                          ),
                        ],
                      )
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Ship to", style: TextStyle(fontSize: 13, color: Color(0xff52606D))),
                          SizedBox(height: 8),
                          Text(
                            order["address"],
                            style: TextStyle(
                              color: Color(0xff1F2933),
                              fontSize: 14
                            )
                          ),
                        ],
                      )
                    ),
                  ]
                ),
                SizedBox(height: 24),
                Align(alignment: Alignment.topLeft, child: Text('Items', style: TextStyle(fontSize: 14, color: Color(0xff52606D)))),
                SizedBox(height: 16),
                SingleChildScrollView(
                  child: Container(
                    height: 200,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: order["elements"].length,
                      itemBuilder: (BuildContext context, int idx) {
                        final quantity = order["elements"][idx]["quantity"];
                        final imageUrl = order["elements"][idx]["image_url"];
                        final title = order["elements"][idx]["title"];
                        final subtitle = order["elements"][idx]["subtitle"];
                        final price = NumberFormat.simpleCurrency(locale: 'vi').format(order["elements"][idx]["price"]);
                
                        return Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: ListTile(
                                contentPadding: EdgeInsets.only(left: 0),
                                leading: imageUrl != ""
                                  ? Container(
                                    height: 40, width: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8)
                                    ),
                                    child: CachedImage(imageUrl, fit: BoxFit.contain))
                                  : Container(
                                    child: Icon(Icons.image),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8)
                                    ),
                                    width: 40, height: 40
                                  ),
                                title: Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xff1F2933), fontSize: 14, fontWeight: FontWeight.w500),),
                                ),
                                subtitle: Text(
                                  subtitle != ""
                                      ? subtitle
                                      : "No variation data",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Color(0xff52606D), fontSize: 13)),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Text("$quantity", style: TextStyle(fontSize: 14, color: Color(0xff52606D)))
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Text(price, style: TextStyle(fontSize: 14, color: Color(0xff52606D)))
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Divider(height: 1, thickness: 1),
                SizedBox(height: 16),
                Container(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text("Total", style: TextStyle(fontSize: 14, color: Color(0xff1F2933), fontWeight: FontWeight.w500))
                        )
                      ),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            "${order['elements'].length}",
                            style: TextStyle(fontSize: 14, color: Color(0xff1F2933), fontWeight: FontWeight.w500)
                          )
                        )
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            "${NumberFormat.simpleCurrency(locale: 'vi').format(order['summary']['total_cost'])}",
                            style: TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.w500)
                          )
                        )
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      )
    );
  }
}