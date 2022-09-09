import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';

import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';

import 'package:mobile_vnpay/mobile_vnpay.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _paymentResultCodeCode = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Container(
            child: Column(
              children: [
                Text('Connect with vnpay payment, result code: $_paymentResultCodeCode'),
                const Spacer(),
                GestureDetector(
                  onTap: _onBuyCoinPressed,
                  child: Container(
                      height: 54,
                      width: 300,
                      alignment: Alignment.center,
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('Test Connect VNPay'.toUpperCase(),
                          textAlign: TextAlign.center)),
                )
              ],
            ),
          )
        ),
      ),
    );
  }

  _onBuyCoinPressed() async {
    String paymentResultCodeCode;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      String url = 'http://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
      String tmnCode = 'HASHTAG6'; // Get from VNPay
      String hashKey = 'PEHPOOBBINRNXQHCSYLEAJOYSMGPXEDY'; // Get from VNPay
      String vnp_CreateDate = DateFormat("yyyyMMddHHmmss").format(DateTime.now());
      String vnp_ExpireDate = DateFormat("yyyyMMddHHmmss").format(DateTime.now().add(const Duration(hours: 7)));

      final params = <String, dynamic>{
        'vnp_Command': 'pay',
        'vnp_Amount': '3000000',
        'vnp_CreateDate': vnp_CreateDate,
        'vnp_ExpireDate': vnp_ExpireDate,
        'vnp_OrderType': "billpayment",
        'vnp_CurrCode': 'VND',
        'vnp_IpAddr': '192.168.15.102',
        'vnp_Locale': 'vn',
        'vnp_OrderInfo': 'Vinh test pay coin 30000 VND',
        'vnp_ReturnUrl': 'https://hashtagecos.com/api/vnPayReturn', // Your Server https://sandbox.vnpayment.vn/apis/docs/huong-dan-tich-hop/#code-returnurl
        'vnp_TmnCode': tmnCode,
        'vnp_TxnRef': DateTime
            .now()
            .millisecondsSinceEpoch.toString(),
        'vnp_Version': '2.1.0'
      };

      final sortedParams = MobileVnpay.instance.sortParams(params);
      final hashDataBuffer = new StringBuffer();
      sortedParams.forEach((key, value) {
        hashDataBuffer.write(key);
        hashDataBuffer.write('=');
        hashDataBuffer.write(value);
        hashDataBuffer.write('&');
      });
      final hashData = hashDataBuffer.toString().substring(0, hashDataBuffer.length - 1);
      final query = Uri(queryParameters: sortedParams).query;
      print('hashData = $hashData');
      print('query = $query');

      var bytes = utf8.encode(hashKey + hashData.toString());
      final vnpSecureHash = sha512.convert(bytes);
      final paymentUrl = "$url?$query&vnp_SecureHashType=SHA512&vnp_SecureHash=$vnpSecureHash";
      print('paymentUrl = $paymentUrl');
      paymentResultCodeCode = (await MobileVnpay.instance.show(paymentUrl: paymentUrl, tmnCode: tmnCode, scheme: 'mobile_vnpay')).toString();
    } on PlatformException {
      paymentResultCodeCode = 'Failed to get payment result code';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _paymentResultCodeCode = paymentResultCodeCode;
    });
  }
}
