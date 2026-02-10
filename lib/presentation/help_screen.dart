import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int _currentSegment = 0;

  final Map<int, Widget> _tabs = const {
    0: Text('얼마야?'),
    1: Text('1/N'),
    2: Text('여계부'),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("도움말", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Segmented Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _currentSegment,
                children: _tabs,
                onValueChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _currentSegment = value;
                    });
                  }
                },
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                thumbColor: isDark ? const Color(0xFF636366) : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildContentForSegment(
                _currentSegment,
                cardColor,
                isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentForSegment(int segment, Color cardColor, bool isDark) {
    switch (segment) {
      case 0: // 얼마야?
        return Column(
          children: [
            _buildHelpCard(
              cardColor,
              isDark,
              title: "실시간 환율 계산",
              content:
                  "메인 화면에서 여행할 국가의 통화를 선택하고 금액을 입력하세요. 실시간 환율을 적용하여 원화 금액을 즉시 확인할 수 있습니다.",
              icon: CupertinoIcons.money_dollar_circle,
            ),
            _buildHelpCard(
              cardColor,
              isDark,
              title: "음성 인식 입력",
              content:
                  "키패드 하단의 마이크 버튼을 누르고 금액을 말해보세요. '백 달러', '오천 엔' 처럼 말하면 자동으로 입력됩니다.",
              icon: CupertinoIcons.mic_circle,
            ),
            _buildHelpCard(
              cardColor,
              isDark,
              title: "쇼핑 헬퍼",
              content:
                  "계산된 금액을 물건 구매 시 바로 활용할 수 있습니다. 상인에게 보여주거나 간단한 회화 표현을 재생해보세요.",
              icon: CupertinoIcons.cart,
            ),
          ],
        );
      case 1: // 1/N
        return Column(
          children: [
            _buildHelpCard(
              cardColor,
              isDark,
              title: "간편한 더치페이",
              content: "지출 항목과 금액을 입력하고 인원 수를 설정하면 1인당 부담해야 할 금액을 자동으로 계산해줍니다.",
              icon: CupertinoIcons.person_2,
            ),
            _buildHelpCard(
              cardColor,
              isDark,
              title: "결과 공유",
              content: "우측 상단의 공유 버튼을 눌러 계산 결과를 텍스트나 이미지로 일행에게 전송할 수 있습니다.",
              icon: CupertinoIcons.share,
            ),
          ],
        );
      case 2: // 여계부
        return Column(
          children: [
            _buildHelpCard(
              cardColor,
              isDark,
              title: "여행 프로젝트 관리",
              content: "새로운 여행을 등록하고 예산을 설정하세요. 여러 여행을 목록으로 관리할 수 있습니다.",
              icon: CupertinoIcons.folder_badge_plus,
            ),
            _buildHelpCard(
              cardColor,
              isDark,
              title: "지출 상세 기록",
              content: "지출 내역을 날짜, 카테고리별로 상세하게 기록하고 영수증 사진을 첨부할 수 있습니다.",
              icon: CupertinoIcons.doc_text,
            ),
            _buildHelpCard(
              cardColor,
              isDark,
              title: "똑똑한 정산",
              content:
                  "'정산하기' 탭에서 멤버별 지출 내역과 최종 입금/송금해야 할 금액을 자동으로 계산해줍니다. 계좌번호와 함께 공유해보세요.",
              icon: CupertinoIcons.chart_pie,
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildHelpCard(
    Color cardColor,
    bool isDark, {
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isDark ? Colors.white : Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
