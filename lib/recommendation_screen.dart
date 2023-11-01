import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'categories_screen.dart'; // CategoriesScreen이 정의된 파일 경로

class RecommendationScreen extends StatefulWidget {
  final int customerId;

  RecommendationScreen({required this.customerId});

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  List<dynamic> recommendedMenus = [];

  Future<void> fetchRecommendedMenus() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:8000/recommendation/${widget.customerId}'));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        recommendedMenus = data['recommended_menus'];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRecommendedMenus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('추천 메뉴'),
      ),
      body: Column(
        children: [
          Expanded(
            child: recommendedMenus.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: recommendedMenus.length,
                    itemBuilder: (context, index) {
                      final menu = recommendedMenus[index];
                      double price = menu['menu_price'] != null ? double.parse(menu['menu_price'].toString()) : 0.0;
                      return ListTile(
                        title: Text('메뉴: ${menu['menu_name']}'),
                        subtitle: Text('설명: ${menu['menu_description']}'),
                        trailing: Text('가격: $price'),
                      );
                    },
                  ),
          ),
          Container(
            width: double.infinity,
            child: ElevatedButton(
              child: Text('주문하러 가기'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoriesScreen(
                      customerInfo: {'id': widget.customerId},
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
