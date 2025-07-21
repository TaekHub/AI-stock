import 'package:flutter/material.dart';

class IndicatorInfoDialog extends StatelessWidget {
  final String group;
  final double screenWidth;
  final double screenHeight;
  final Map<String, String> info;

  const IndicatorInfoDialog({
    super.key,
    required this.group,
    required this.screenWidth,
    required this.screenHeight,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info['title'] ?? group,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Text(
                '설명:',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                info['description'] ?? '설명이 없습니다',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: screenWidth * 0.04,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Text(
                '해석 기준:',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                info['interpretation'] ?? '해석 기준이 없습니다',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: screenWidth * 0.04,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.1,
                      vertical: screenHeight * 0.02,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '닫기',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}