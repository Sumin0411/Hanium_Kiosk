import 'package:flutter/material.dart';
import 'categories_screen.dart';
import 'camera.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hanium coffee',
      home: Lock_screen(),
    );
  }
}

class Lock_screen extends StatefulWidget {
  @override
  _Lock_screenState createState() => _Lock_screenState();
}

class _Lock_screenState extends State<Lock_screen> {
  final _pageController = PageController(initialPage: 0);
  int selectedCustomerId = 1; // 임의로 초기화. 실제 값을 설정해야 함.
  String selectedCustomerName = "John Doe"; // 임의로 초기화. 실제 값을 설정해야 함.


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: [
          Stack(
            children: [
              _buildPageOne(context),
              Positioned(
                bottom: 20, 
                left: 0, 
                right: 0, 
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text("다음 화면"),
                  ),
                ),
              ),
            ],
          ),
           CameraPage(customerId: selectedCustomerId, customerName: selectedCustomerName) // 여기서 값을 제공
        ],
      ),
    );
  }

  Widget _buildPageOne(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        'assets/0_lock_screen.png',
        fit: BoxFit.cover,
      ),
    );
  }
}


class FirstPage extends StatefulWidget {
  final int customerId; // customerId 필드를 추가
  FirstPage({required this.customerId}); 
  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  final _pageController = PageController(initialPage: 0);
  

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      children: [
        Stack(
          children: [
            _buildPageImage('assets/1_First_screen.png'),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => CategoriesScreen(
      customerInfo: {'id': widget.customerId},
    ),
                          ),
                        );
                      },
                      child: Text('다음 화면'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        CategoriesScreen(
      customerInfo: {'id': widget.customerId},
    ),
      ],
    );
  }

  Widget _buildPageImage(String imagePath) {
    return Positioned.fill(
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
      ),
    );
  }
}
