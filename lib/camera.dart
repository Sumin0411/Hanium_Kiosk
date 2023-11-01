import 'package:flutter/material.dart';
import 'package:ang/main.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';

Future<void> sendVideoToServer(html.Blob videoBlob, String customerName) async {
  final url = "http://127.0.0.1:8000/analyze_video";

  final reader = html.FileReader();
  reader.readAsDataUrl(videoBlob);
  await reader.onLoad.first;

  String base64String = reader.result as String;
  base64String = base64String.split(',').last;

  Uint8List uint8list = base64.decode(base64String);

  final request = http.MultipartRequest("POST", Uri.parse(url))
    ..fields['customer_name'] = customerName
    ..files.add(http.MultipartFile.fromBytes('file', uint8list, filename: 'video.mp4'));

  final response = await request.send();

  if (response.statusCode == 200) {
    print('Video uploaded successfully!');
  } else {
    print('Failed to upload video!');
  }
}

class CameraPage extends StatefulWidget {
  final int customerId;  // customerId 필드 추가
  final String customerName;  // customerName 변수 추가
  CameraPage({required this.customerId, required this.customerName});  // 생성자 수정

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  // final _pageController = PageController(initialPage: 0);
  final _videoElement = html.VideoElement()..id = 'videoElement';

  late html.MediaStream _mediaStream;
  bool isReady = false;
  bool isRecording = false; // 추가: 녹화 중인지를 나타내는 상태 변수 추가

 @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _mediaStream = await html.window.navigator.getUserMedia(video: true);
      _videoElement.srcObject = _mediaStream;
      _videoElement.autoplay = true;
      _videoElement.play();
      setState(() {
        isReady = true;
      });
      _startRecording();
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> _startRecording() async {
  if (isRecording) return; // 녹화 중이면 중복 호출 방지

  isRecording = true; // 녹화 시작

  try {
    final recorder = html.MediaRecorder(_mediaStream);
    final chunks = <html.Blob>[];

    recorder.addEventListener("dataavailable", (event) {
      final data = (event as html.BlobEvent).data;
      if (data != null) {
        chunks.add(data);
      }
    });

    // 이곳에 recorder.addEventListener("stop", ...) 이벤트를 추가합니다.
    recorder.addEventListener("stop", (_) async {
      final blob = html.Blob(chunks);
      // 백엔드로 동영상 전송
      await sendVideoToServer(blob, widget.customerName); // CUSTOMER_NAME_HERE 대신 widget.customerName 사용

      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..target = 'blank'
        ..download = 'recorded_video.webm'
        ..click();
      html.Url.revokeObjectUrl(url);
      isRecording = false;
    });

    recorder.start();

    await Future.delayed(Duration(seconds: 2)); // 2초 후에 동영상 중지
    recorder.stop();

  } catch (e) {
    print("Error recording video: $e");
    isRecording = false; // 녹화 종료 (오류 발생 시)
  }
}


   @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // 배경으로 이미지를 설정합니다.
          Image.asset('assets/1-1 얼굴인식 시작.png', fit: BoxFit.cover),
          // 중앙에 버튼을 배치합니다.
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) =>FirstPage(customerId: widget.customerId)), // widget.customerId 사용, // provide the customerId value her,
                );
              },
              child: Text("녹화 완료"),
            ),
          ),
        ],
      ),
    );
  }



  @override
  void dispose() {
    _mediaStream.getVideoTracks().first.stop();
    super.dispose();
  }
}