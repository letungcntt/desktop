import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/palette.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/common/validators.dart';
import 'package:workcake/models/models.dart';

class CheckVerifyPhoneNumber extends StatefulWidget {
  final String? verificationType;
  final String? type;
  CheckVerifyPhoneNumber({ Key? key, this.verificationType, this.type }) : super(key: key);

  @override
  _CheckVerifyPhoneNumberState createState() => _CheckVerifyPhoneNumberState();
}

class _CheckVerifyPhoneNumberState extends State<CheckVerifyPhoneNumber> {
  bool isLoadingCreateOTP = false;
  bool isFirstSendOTP = true;
  int nextViewOTP = 1;
  var errorMessage;
  TextEditingController _phoneController = TextEditingController();
  var _debounce;
  Timer? _timer;
  int _start = 180;
  String? countdownOTP;

  @override
  void initState() {
    super.initState();
    setState(() {
      _phoneController.text = widget.type!;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  createVerifyPhoneNumber(token) async {
    print(widget.verificationType);
    setState(() {
      _start = 180;
      isLoadingCreateOTP = true;
      isFirstSendOTP = false;
    });
    final url = "${Utils.apiUrl}/users/create_otp_with_phone_number?token=$token";

    try {
      final body = widget.verificationType == "email" ? {"email": _phoneController.text} : {"phone_number": _phoneController.text};
      final request = await http.post(
        Uri.parse(url),
        headers: Utils.headers,
        body: json.encode(body)
      );
      final response = json.decode(request.body);

      if (response["success"]) {
        setState(() {
          nextViewOTP = 2;
          errorMessage = "";
          countdownOTP = "ok";
        });
      } else {
        setState(() {
          errorMessage = response["message"];
        });
        Timer(const Duration(milliseconds: 5000), () {
          setState(() {
            errorMessage = "";
          });
        });
      }
      setState(() {
        isLoadingCreateOTP = false;
      });

      if (_timer != null) {
        _timer?.cancel();
        _timer = null;
        } else {
          _timer = new Timer.periodic(
            const Duration(seconds: 1),
            (Timer timer) => setState(
              () {
                if (_start < 1) {
                  timer.cancel();
                  countdownOTP = "";
                  nextViewOTP = 1;
                } else {
                  _start = _start - 1;
                }
              },
            ),
          );
        }

    } catch (e) {
      print(e);
      setState(() {
        isLoadingCreateOTP = false;
      });
    }
  }

  verifyPhoneNumber(token, pin) async {
    final url = "${Utils.apiUrl}/users/verify_otp_with_phone_number?token=$token";

    try {
      final body = widget.verificationType == "email"
          ? {"email": _phoneController.text, "otp": pin}
          : { "phone_number": _phoneController.text, "otp": pin};

      final request = await http.post(
        Uri.parse(url),
        headers: Utils.headers,
        body: json.encode(body)
      );
      final response = json.decode(request.body);
      if (response["success"]) {
        setState(() {
          nextViewOTP = 3;
        });
        Provider.of<User>(context, listen: false).fetchAndGetMe(token);
        Timer(const Duration(milliseconds: 5000), () {
          Navigator.pop(context);
        });
      } else {
        setState(() {
          nextViewOTP = 1;
          errorMessage = response["message"];
          countdownOTP = "";
        });
        if (_timer != null) {
          _timer?.cancel();
          _timer = null;
          } else {
            _timer = new Timer.periodic(
              const Duration(seconds: 1),
              (Timer timer) => setState(
                () {
                  _start = 180;
                  timer.cancel();
                },
              ),
            );
          }
      }
    } catch (e) {
      print(e);
    }
  }

  Widget prevPageOTP() {
    final token = Provider.of<Auth>(context, listen: false).token;
    final isDark = Provider.of<Auth>(context, listen: false).theme == ThemeType.DARK;

    return Container(
      width: 400,
      height: nextViewOTP == 2 ? 200 : 120,
      child: nextViewOTP == 3
        ? Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, color: Colors.green),
            SizedBox(height: 5),
            Text(widget.verificationType == "email" ? "Email has been successfully verified!" : "Phone number has been successfully verified!")
          ],
        ),)
        : Column(
        children: [
          Container(
            child: TextField(
              readOnly: widget.verificationType == "email",
              keyboardType: widget.verificationType == "email" ? TextInputType.emailAddress : TextInputType.number,
              // inputFormatters: <TextInputFormatter>[
              //     FilteringTextInputFormatter.digitsOnly
              // ],
              controller: _phoneController,
              decoration: InputDecoration(
                suffixIcon: isLoadingCreateOTP
                  ? CircularProgressIndicator(strokeWidth: 2,)
                  : Container(
                    padding: EdgeInsets.only(right: 10),
                    child: TextButton(
                    child: Text(isFirstSendOTP ? 'Send' : 'Resend'),
                    onPressed: (_start > 0 && _start < 180)
                      ? null
                      : (Validators.validatePhoneNumber(_phoneController.text) || Validators.validateEmail(_phoneController.text))
                        ? () {
                          createVerifyPhoneNumber(token);
                          }
                        : null,
                ),
                  ),
                filled: true,
                fillColor: isDark ? Palette.darkSelectedChannel.withOpacity(0.5) : Palette.lightSelectedChannel.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                hintText: widget.verificationType == "email" ? "Enter your email" : "Enter your phone number",
                hintStyle: TextStyle(fontSize: 14.0, color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight),
                errorText: Utils.checkedTypeEmpty(errorMessage) ? errorMessage : null
              ),
              style: TextStyle(
                color: isDark ? Palette.defaultTextDark : Palette.defaultTextLight,
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  if (widget.verificationType == "email") {
                    if (Validators.validateEmail(value) || value == "") {
                      setState(() {
                        errorMessage = "";
                      });
                    } else {
                      setState(() {
                        errorMessage = "Email không hợp lệ";
                      });
                    }
                  } else {
                    if (Validators.validatePhoneNumber(value) || value == "") {
                      setState(() {
                        errorMessage = "";
                      });
                    } else {
                      setState(() {
                        errorMessage = "Số điện thoại không hợp lệ";
                      });
                    }
                  }
                });
              }
            ),
          ),
          SizedBox(height: 10),
          Utils.checkedTypeEmpty(countdownOTP)
              ? widget.verificationType == "email"
                  ? Text("OTP đã được gửi đến email ${_phoneController.text}. OTP sẽ hết hạn trong vòng ${_start}s", style: TextStyle(fontSize: 12, color: Colors.blue),)
                  : Text("OTP đã được gửi đến sđt ${_phoneController.text}. OTP sẽ hết hạn trong vòng ${_start}s", style: TextStyle(fontSize: 12, color: Colors.blue),)
              : Container(),
          SizedBox(height: 20),
          nextViewOTP == 2 ? OTPTextField(
            keyboardType: TextInputType.number,
            length: 4,
            width: MediaQuery.of(context).size.width,
            fieldWidth: 60,
            style: TextStyle(
              fontSize: 17
            ),
            textFieldAlignment: MainAxisAlignment.spaceAround,
            fieldStyle: FieldStyle.underline,
            onCompleted: (pin) {
              print("Completed: " + pin);
              verifyPhoneNumber(token, pin);
            },
          ) : Container(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      child: prevPageOTP()
    );
  }
}