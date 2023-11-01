import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'shopping_cart_screen.dart';

class MenuOptionsScreen extends StatefulWidget {
  final dynamic menu;
  final dynamic customerInfo;
  final dynamic menuPrice;
  final List<dynamic> cartItems;

  MenuOptionsScreen({
    required this.menu,
    required this.customerInfo,
    required this.menuPrice,
    required this.cartItems,
  });

  @override
  _MenuOptionsScreenState createState() => _MenuOptionsScreenState();
}

class _MenuOptionsScreenState extends State<MenuOptionsScreen> {
  Set<dynamic> selectedOptions = {};
  num totalPrice = 0;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    totalPrice = widget.menuPrice;
    _speech = stt.SpeechToText();
  }

  Future<void> addToCart(BuildContext context) async {
    final customerId = widget.customerInfo['id'];
    final menuId = widget.menu['menu_pk'];
    final options = selectedOptions.map((option) => option['option_pk']).toList();
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/order/$customerId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'menu_pk': menuId,
        'options': options,
        'customer_id': customerId,
        'menu_name': widget.menu['menu_name'],
        'menu_price': widget.menuPrice,
        'price': totalPrice,
        'options_data': [
          for (var option in selectedOptions)
            {
              "option_name": option['option_name'],
              "option_price": option['option_price']
            }
        ],
      }),
    );

    if (response.statusCode == 200) {
      List<dynamic> cartItems = [];
      cartItems.add({
        'menu_name': widget.menu['menu_name'],
        'options': selectedOptions.toList(),
        'total_price': totalPrice,
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => ShoppingCartScreen(
            customerInfo: widget.customerInfo,
            cartItems: cartItems,
            menuPrice: widget.menuPrice,
          ),
        ),
      );
    }
  }

  Future<List<dynamic>> fetchOptions(int menuPk) async {
    final response = await http.get(Uri.parse('http://127.0.0.1:8000/option'));
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes)) ?? [];
    } else {
      throw Exception();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.menu['menu_name']),
      ),
      body: Column(
        children: [
          SizedBox(height: 300),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: fetchOptions(widget.menu['menu_pk']),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView(
                    children: <Widget>[
                      GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 30.0,
                          mainAxisSpacing: 30.0,
                          childAspectRatio: 2.5,
                        ),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (BuildContext buildContext, int index) {
                          final option = snapshot.data![index];
                          bool isSelected = selectedOptions.contains(option);

                          return ElevatedButton(
                            onPressed: () {
                              setState(() {
                                if (isSelected) {
                                  selectedOptions.remove(option);
                                } else {
                                  selectedOptions.add(option);
                                }
                                totalPrice = widget.menuPrice;
                                for (var selectedOption in selectedOptions) {
                                  totalPrice += selectedOption['option_price'];
                                }
                              });
                            },
                            style: ButtonStyle(
                              padding: MaterialStateProperty.all(
                                EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              ),
                              backgroundColor: isSelected
                                  ? MaterialStateProperty.all(Colors.blue)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  option['option_name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '\$${option['option_price']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error'));
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Price: \$${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    addToCart(context);
                  },
                  child: Text('Add to Cart'),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }

  _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(onStatus: (val) {
        setState(() => _isListening = val == 'listening');
      });
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            if (val.finalResult) {
              _executeCommand(val.recognizedWords);
            }
          }),
        );
        Future.delayed(Duration(seconds: 7), () {
          if (_isListening) {
            setState(() => _isListening = false);
            _speech.stop();
          }
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  _executeCommand(String voiceInput) async {
    List<dynamic> options = await fetchOptions(widget.menu['menu_pk']);
    bool optionApplied = false;

    for (var option in options) {
      if (voiceInput.contains(option['option_name'])) {
        optionApplied = true;
        setState(() {
          bool isSelected = selectedOptions.contains(option);
          if (isSelected) {
            selectedOptions.remove(option);
          } else {
            selectedOptions.add(option);
          }
          totalPrice = widget.menuPrice;
          for (var selectedOption in selectedOptions) {
            totalPrice += selectedOption['option_price'];
          }
        });
      }
    }
    if (optionApplied) {
      addToCart(context);
    }
  }
}
