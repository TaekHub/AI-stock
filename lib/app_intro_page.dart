import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';

class AppIntroPage extends StatefulWidget {
  const AppIntroPage({super.key});

  @override
  State<AppIntroPage> createState() => _AppIntroPageState();
}

class _AppIntroPageState extends State<AppIntroPage> {
  bool _isAgreed = false;
  bool _isStartButtonEnabled = false;
  bool _isFirebaseInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _checkAgreementStatus();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "YOUR_API_KEY",
          appId: "YOUR_APP_ID",
          messagingSenderId: "YOUR_SENDER_ID",
          projectId: "YOUR_PROJECT_ID",
          databaseURL: "YOUR_DATABASE_URL",
        ),
      );
      setState(() {
        _isFirebaseInitialized = true;
      });
    } catch (e) {
      print('Firebase initialization error: $e');
    }
  }

  Future<void> _checkAgreementStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final agreed = prefs.getBool('agreedToDisclaimer') ?? false;
    setState(() {
      _isAgreed = agreed;
      _isStartButtonEnabled = agreed && _isFirebaseInitialized;
    });
  }

  Future<void> _saveAgreementStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('agreedToDisclaimer', _isAgreed);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    if (!_isFirebaseInitialized) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.blueAccent),
              const SizedBox(height: 20),
              Text(
                '서비스 초기화 중...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.05,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.show_chart,
                  color: Colors.blueAccent,
                  size: screenWidth * 0.15,
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  '주식 투자 통합 분석 플랫폼',
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.03),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Colors.blueAccent,
                            size: screenWidth * 0.06,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Flexible(
                            child: Text(
                              '해외 및 국내 주식의 \n실시간 데이터를 제공',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_chart,
                            color: Colors.blueAccent,
                            size: screenWidth * 0.06,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Flexible(
                            child: Text(
                              'RSI, MACD 등 기술적 지표로 \n투자 기회 분석',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.newspaper,
                            color: Colors.blueAccent,
                            size: screenWidth * 0.06,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Flexible(
                            child: Text(
                              '최신 뉴스로 시장 동향과\n종목 정보 파악',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.blueAccent,
                            size: screenWidth * 0.06,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Flexible(
                            child: Text(
                              '관심 종목 관리로\n효율적인 투자 전략 수립',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      Text(
                        '빠르고 정확한 정보로\n성공적인 투자를 지원합니다!',
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.orange,
                        size: screenWidth * 0.06,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: Text(
                          '이 앱은 주식 투자의 도움을 주고자 \n지표 분석만 하며, \n투자의 책임은 본인에게 있습니다.',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.orange,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _isAgreed,
                      onChanged: (bool? value) {
                        setState(() {
                          _isAgreed = value ?? false;
                          _isStartButtonEnabled = _isAgreed && _isFirebaseInitialized;
                        });
                      },
                      activeColor: Colors.blueAccent,
                      checkColor: Colors.white,
                    ),
                    Text(
                      '위 내용을 이해하고 동의합니다.',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                ElevatedButton(
                  onPressed: _isAgreed
                      ? () {
                          setState(() {
                            _isStartButtonEnabled = true;
                          });
                          _saveAgreementStatus();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.1,
                      vertical: screenHeight * 0.015,
                    ),
                  ),
                  child: Text(
                    '동의',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                ElevatedButton(
                  onPressed: _isStartButtonEnabled
                      ? () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const StockListPage()),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isStartButtonEnabled ? Colors.blueAccent : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.1,
                      vertical: screenHeight * 0.015,
                    ),
                  ),
                  child: Text(
                    '시작하기',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}