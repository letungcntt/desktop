import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workcake/common/cache_avatar.dart';
import 'package:workcake/common/date_formatter.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/message_item/message_card_desktop.dart';
import 'package:workcake/components/widget_text.dart';
import 'package:workcake/providers/providers.dart';

class PosAppAttachments extends StatefulWidget {
  final att;
  const PosAppAttachments({ Key? key, @required this.att }) : super(key: key);

  @override
  State<PosAppAttachments> createState() => _PosAppAttachmentsState();
}

class _PosAppAttachmentsState extends State<PosAppAttachments> {

  TextSpan textSpan(data, orderType) {
    String text = "";
    if (orderType == "partner_status") {
      switch (data["changeset"]["partner_status"]) {
        case "out_for_delivery":
          text = "đã tới kho đích. Vui lòng kiểm trả lại.";
          break;
        case "undeliverable":
          text = "giao không thành công. Vui lòng kiểm trả lại.";
          break;
        case "canceled":
          text = "đã bị khách huỷ không nhận hàng. Vui lòng kiểm trả lại.";
          break;
        default:
      }
    } else if (orderType == "status") {
      text = "đã đổi sang trạng thái mới.";
    }

    return TextSpan(text: text);
  }

  void openLink(data) async {
    final shopId = data["shop_info"]["id"];
    final orderId = data["order_info"]["id"];
    final url = "https://pos.pages.fm/shop/$shopId/order?order_id=$orderId";

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $data';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<Auth>(context, listen: false);
    final isDark = auth.theme == ThemeType.DARK;
    final data = widget.att["data"];
    final orderType = data["order_type"];
    final color = Utils.statusOrder(data["order_info"]["status"])["color"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichTextWidget(
          TextSpan(
            style: TextStyle(fontSize: 14.5, height: 1.5),
            children: [
              TextSpan(text: "Đơn hàng"),
              WidgetSpan(
                child: Tooltip(
                  child: RichTextWidget(
                    TextSpan(
                      text: " ${data["order_info"]["display_id"]} ",
                      style: TextStyle(fontStyle: FontStyle.italic),
                      recognizer: TapGestureRecognizer()..onTapUp = (_) => openLink(data)
                    ),
                  ),
                  // child: Text(" ${data["order_info"]["display_id"]} ", style: TextStyle(fontStyle: FontStyle.italic)),
                  message: "Xem chi tiết đơn hàng bên POS",
                  decoration: ShapeDecoration(
                    shape: CustomBorder(),
                    color: isDark ? Palette.backgroundRightSiderLight : Palette.backgroundRightSiderDark
                  ),
                  preferBelow: false, verticalOffset: 10.0
              )),
              textSpan(data, orderType)
              // WidgetSpan(child: Container()),
            ]
          ),
        ),
        if (Utils.checkedTypeEmpty(data["inserted_at"])) InkWell(
          onTap: () => openLink(data),
          child: Container(
            width: 400,
            margin: EdgeInsets.only(top: 2),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(
                  color: isDark ? Palette.darkSelectedChannel : Palette.lightSelectedChannel.withOpacity(0.25),
                  width: 1,
                ),
              ),
              color: isDark ? Palette.defaultBackgroundDark : Palette.defaultBackgroundLight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8, top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${data["order_info"]["display_id"]}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500
                          ),
                        ),
                        Container(
                          child: Row(
                            children: [
                              CachedAvatar(
                                data["order_info"]["creator"]["avatar_url"] ?? "",
                                height: 26, width: 26,
                                isRound: true,
                                name: data["order_info"]["creator"]["name"],
                                isAvatar: true
                              ),
                              SizedBox(width: 5,),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data["order_info"]["creator"]["name"],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500
                                    ),
                                  ),
                                  SizedBox(height: 1),
                                  Text(
                                    "đã tạo lúc ${DateFormatter().renderTime(DateTime.parse(data["inserted_at"]), type: 'kk:mm dd/MM')}",
                                    style: TextStyle(
                                      fontSize: 10
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Divider(),
                  Padding(
                    padding: EdgeInsets.only(left: 16, right: 8, bottom: 4, top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Trạng thái đơn hàng",
                          style: TextStyle(
                            color: isDark ? Color(0xff7D7E7E) : Color(0xff9A9A9A)
                          ),
                        ),
                        SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                            color: Color(color ?? 0xff00a2ae)
                          ),
                          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Text("${Utils.statusOrder(data["order_info"]["status"])["text"]}"),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Người nhận:",
                          style: TextStyle(
                            color: isDark ? Color(0xff7D7E7E) : Color(0xff9A9A9A)
                          ),
                        ),
                        SizedBox(height: 4),
                        Text("${data["order_info"]["shipping_address"]["name"]}"),
                        SizedBox(height: 2),
                        Text("${data["order_info"]["shipping_address"]["address"]}"),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              "Số lượng sản phẩm:",
                              style: TextStyle(
                                color: isDark ? Color(0xff7D7E7E) : Color(0xff9A9A9A)
                              ),
                            ),
                            SizedBox(width: 6,),
                            Text("${data["order_info"]["total_quantity"] ?? 0}")
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              "Thanh toán:",
                              style: TextStyle(
                                color: isDark ? Color(0xff7D7E7E) : Color(0xff9A9A9A)
                              ),
                            ),
                            SizedBox(width: 6,),
                            Text(
                              Utils.checkedTypeEmpty(data["order_info"]["prepaid"])
                                ? data["order_info"]["prepaid"] > 0
                                  ? "Đã thanh toán 1 phần"
                                  : data["order_info"]["prepaid"] == data["order_info"]["cod"]
                                    ? "Đã thanh toán cả"
                                    : "Thanh toán khi giao hàng (COD)"
                                : "Thanh toán khi giao hàng (COD)"
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8, bottom: 16, top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Giá trị đơn hàng:",
                          style: TextStyle(
                            color: isDark ? Color(0xff7D7E7E) : Color(0xff9A9A9A)
                          ),
                        ),
                        Text(
                          "${NumberFormat.simpleCurrency(locale: 'vi').format(data["order_info"]["cod"])}"
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        )
      ]
    );
  }
}