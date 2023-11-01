import 'package:flutter/material.dart';
import 'dart:math';

class OrderNumberScreen extends StatelessWidget {
  final Map<String, dynamic> customerInfo;
  final Random random = Random();

  OrderNumberScreen({required this.customerInfo});

  int generateRandomOrderNumber() {
    // 무작위 주문 번호 생성 (1에서 100 사이의 숫자)
    int orderNumber = 1 + random.nextInt(100);
    return orderNumber;
  }

  @override
  Widget build(BuildContext context) {
    final int orderNumber = generateRandomOrderNumber();

    return Scaffold(
      appBar: AppBar(
        title: Text('주문 번호 확인'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '주문번호 확인',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),          
            Text(
              '주문 번호: $orderNumber',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              '주문 번호로 알려드리겠습니다.',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '영수증을 뽑아주시기 바랍니다.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
