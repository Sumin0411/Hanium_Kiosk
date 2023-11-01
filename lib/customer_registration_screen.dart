import 'package:ang/camera.dart';

// import 'recommendation_screen.dart'; 
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CustomerRegistrationScreen extends StatefulWidget {
  @override
  _CustomerRegistrationScreenState createState() =>
      _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState
    extends State<CustomerRegistrationScreen> {
  List<dynamic> customers = [];
  

  Future<void> fetchCustomerInfo() async {
    try {
      final response =
          await http.get(Uri.parse('http://127.0.0.1:8000/orderer'));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          customers = data;
        });
      } else {
        print('Failed to fetch customer info');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCustomerInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('고객 정보'),
      ),
      body: customers.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return ListTile(
                  title: Text('ID: ${customer['id']}'),
                  subtitle: Text('이름: ${customer['name']}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>CameraPage(
      customerId: customer['id'],
      customerName: customer['name'],  // 여기에 고객 이름 추가
    ),
                        ),
                      );
                    },
                    child: Text('선택'),
                  ),
                );
              },
            ),
    );
  }
}
