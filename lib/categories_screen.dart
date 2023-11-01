import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'menu_options_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CategoriesScreen extends StatefulWidget {
  final dynamic customerInfo;
  CategoriesScreen({required this.customerInfo});
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<dynamic>> categories;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceInput = '';
  
  void _resetListening() {
    setState(() {
      _isListening = false;
    });
    _listen();
  }

  @override
  void initState() {
    super.initState();
    categories = fetchCategories();
    _speech = stt.SpeechToText();
    _listen();
  }

  Future<List<dynamic>> fetchCategories() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:8000/categories'));
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<List<dynamic>> fetchMenus(int categoryPk) async {
    final response = await http.get(Uri.parse('http://127.0.0.1:8000/menu/$categoryPk'));
    if (response.statusCode == 200) {
      final List<dynamic> menus = json.decode(utf8.decode(response.bodyBytes));
      menus.forEach((menu) {
        menu['menu_price'] = menu['menu_price'] as int;
      });
      return menus;
    } else {
      throw Exception('메뉴를 불러오지 못했습니다');
    }
  }

void showMenus(BuildContext context, int categoryPk) {
  fetchMenus(categoryPk).then((menus) {
    _listenForMenus(context, menus);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) => AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Menus'),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                  onPressed: () => _resetListening(),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width, // 화면 너비로 조정
              height: MediaQuery.of(context).size.height, // 화면 높이로 조정
              child: Column(
                mainAxisSize: MainAxisSize.min, // Column 크기를 최소화합니다.
                children: [
                  Container(
                    height: 290.0, // 원하는 높이로 조정
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 한 줄에 최대 3개의 아이템
                    ),
                    itemCount: menus.length,
                    itemBuilder: (BuildContext buildContext, int index) {
                      final menu = menus[index];
                      return ElevatedButton(
                        onPressed: () {
                          double menuPrice = menu['menu_price'];
                          List<dynamic> cartItems = [];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) => MenuOptionsScreen(
                                menu: menu,
                                customerInfo: widget.customerInfo,
                                menuPrice: menuPrice,
                                cartItems: cartItems,
                              ),
                            ),
                          );
                        },
                        child: ListTile(
                          title: Text(
                            "${menu['menu_name']}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.0 // 굵은 글꼴
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${menu['menu_price']}원", // menu_price를 밑에 추가
                                style: TextStyle(
                                  fontSize: 18.0, // 원하는 글꼴 크기로 조정
                                ),
                              ),
                              Text(
                                "${menu['menu_description']}", // menu_description 추가
                                style: TextStyle(
                                  fontSize: 14.0, // 원하는 글꼴 크기로 조정
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('뒤로가기'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  });
}




  _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(onStatus: (val) {
        setState(() => _isListening = val == 'listening');
      }, onError: (val) {
        setState(() {
          _isListening = false;
          _voiceInput = val.errorMsg;
        });
      });
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _voiceInput = val.recognizedWords;
            if (val.finalResult) {
              _executeCommand(_voiceInput);
            }
          }),
        );
        Future.delayed(Duration(seconds: 3), () {
          if (_isListening) {
            _speech.stop();
            setState(() => _isListening = false);
          }
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  _executeCommand(String voiceInput) async {
    final data = await categories;
    for (var category in data) {
      if (voiceInput.contains(category['category_name'])) {
        showMenus(context, category['category_pk']);
      }
    }
  }

  void _listenForMenus(BuildContext dialogContext, List<dynamic> menus) async {
    if (!_isListening) {
      bool available = await _speech.initialize(onStatus: (val) {
        this.setState(() => _isListening = val == 'listening');
      }, onError: (val) {
        this.setState(() {
          _isListening = false;
          _voiceInput = val.errorMsg;
        });
      });
      if (available) {
        this.setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => this.setState(() {
            _voiceInput = val.recognizedWords;
            if (val.finalResult) {
              _selectMenuByVoice(dialogContext, menus);
            }
          }),
        );
        Future.delayed(Duration(seconds: 3), () {
          if (_isListening) {
            _speech.stop();
            this.setState(() => _isListening = false);
          }
        });
      }
    } else {
      this.setState(() => _isListening = false);
      _speech.stop();
    }
  }

  _selectMenuByVoice(BuildContext context, List<dynamic> menus) {
    for (var menu in menus) {
      if (_voiceInput.contains(menu['menu_name'])) {
        double menuPrice = menu['menu_price'];
        List<dynamic> cartItems = [];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => MenuOptionsScreen(
              menu: menu,
              customerInfo: widget.customerInfo,
              menuPrice: menuPrice,
              cartItems: cartItems,
            ),
          ),
        );
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Categories'),
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
            onPressed: _listen,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: categories,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final itemCount = snapshot.data!.length;
            final halfItemCount = (itemCount / 2).ceil();

            return Column(
              children: [
                Expanded(
                  child: SizedBox(height: 300), // 상단 공간 차지
                ),
                Expanded(
                  flex: 2, // 남은 공간 차지 (하단에서 버튼 생성)
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 30.0, // 여백 조절
                      mainAxisSpacing: 30.0, // 여백 조절
                    ),
                    padding: EdgeInsets.all(50.0),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      return ElevatedButton(
                        onPressed: () {
                          showMenus(context, snapshot.data![index]['category_pk']);
                        },
                        child: Text(
                          snapshot.data![index]['category_name'],
                          style: TextStyle(
                            fontSize: 30, // 글씨 크기를 30으로 설정
                            fontWeight: FontWeight.bold, // 글씨 굵게 설정
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}