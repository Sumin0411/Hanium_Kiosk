import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'order_number_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class OrderConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> customerInfo;

  OrderConfirmationScreen({required this.customerInfo});

  @override
  _OrderConfirmationScreenState createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  List<dynamic> cartItems = [];

  @override
  void initState() {
    super.initState();
    fetchShoppingCart();
  }

  Future<void> fetchShoppingCart() async {
    try {
      final customerId = widget.customerInfo['id'];
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/order_check/$customerId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> shoppingCartData =
            json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          cartItems = shoppingCartData['orders'];
        });
      } else {
        print('장바구니 정보를 가져오는 데 실패했습니다.');
      }
    } catch (e) {
      print('오류: $e');
    }
  }

  void onOptionSelected(int selectedOption) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/state/${widget.customerInfo['id']}'),
      body: jsonEncode({'state_name': selectedOption.toString()}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      final orderNumber = responseData['order_number'];
      final customerId = widget.customerInfo['id'];

      // OrderNumberScreen으로 화면을 전환합니다.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderNumberScreen(
            customerInfo: widget.customerInfo,
          ),
        ),
      );
    } else {
      print('상태 업데이트 실패');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('주문 확인'),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(height: 300),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '주문이 완료되었습니다!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (BuildContext context, int index) {
                final cartItem = cartItems[index];
                final menuName = cartItem['menu_name'];
                final price = cartItem['total_price'];

                return ListTile(
                  title: Text(menuName),
                  subtitle: Text('가격: \$${price.toStringAsFixed(2)}'),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SelectOptionPage(
                    customerInfo: widget.customerInfo,
                    onOptionSelected: onOptionSelected,
                  ),
                ),
              );
            },
            child: Text('매장 또는 포장 선택'),
          ),
        ],
      ),
    );
  }
}

class SelectOptionPage extends StatefulWidget {
  final Map<String, dynamic> customerInfo;
  final Function(int) onOptionSelected;

  SelectOptionPage({required this.customerInfo, required this.onOptionSelected});

  @override
  _SelectOptionPageState createState() => _SelectOptionPageState();
}

class _SelectOptionPageState extends State<SelectOptionPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _startListening() async {
    if (!_speech.isListening) {
      bool available = await _speech.initialize();
      if (available) {
        _speech.listen(
          onResult: (result) {
            if (result.recognizedWords.toLowerCase().contains('매장') && result.finalResult) {
              _speech.stop();
              setState(() {
                _isListening = false;
              });
              widget.onOptionSelected(0); // '매장' 버튼의 동작을 수행
            } else if (result.recognizedWords.toLowerCase().contains('포장') && result.finalResult) {
              _speech.stop();
              setState(() {
                _isListening = false;
              });
              widget.onOptionSelected(1); // '포장' 버튼의 동작을 수행
            }
          },
          listenFor: Duration(seconds: 3),
        );
        setState(() {
          _isListening = true;
        });
      }
    } else {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('매장 또는 포장 선택'),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 300.0), // 상단 공간 추가
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  widget.onOptionSelected(0);
                },
                style: ElevatedButton.styleFrom(
                  fixedSize: Size(200, 200), // 정사각형 크기 조절
                ),
                child: Text('매장', style: TextStyle(fontSize: 20.0),), // 버튼 텍스트 크기 조절
              ),
              SizedBox(width: 20.0), // 버튼 사이의 간격 조정
              ElevatedButton(
                onPressed: () {
                  widget.onOptionSelected(1);
                },
                style: ElevatedButton.styleFrom(
                  fixedSize: Size(200, 200), // 정사각형 크기 조절
                ),
                child: Text('포장', style: TextStyle(fontSize: 20.0),), // 버튼 텍스트 크기 조절
              ),
            ],
          ),
          SizedBox(height: 20.0), // 간격 조정
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            onPressed: _startListening,
          ),
        ],
      ),
    ),
  );
}
}