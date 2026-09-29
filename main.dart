import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'State Todo App',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xfff4f7f6), // 부드러운 배경색
      ),
      home: const TodoScreen(),
    );
  }
}

// 할 일 데이터 모델
class TodoItem {
  final String title;
  bool isCompleted;

  TodoItem({required this.title, this.isCompleted = false});
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  // 1. 초기 할 일 목록 상태 정의 (누르기 전 상태)
  final List<TodoItem> _todoList = [
    TodoItem(title: '5주차 강의 복습', isCompleted: false),
    TodoItem(title: '상태 흐름도 작성', isCompleted: false),
  ];

  // 2. 남은 할 일(완료되지 않은 항목) 개수 계산
  int get _remainingCount => _todoList.where((item) => !item.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 상단 메인 카드 레이아웃
              Container(
                width: 340,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: const Color(0xff112d4e), // 어두운 남색 테두리
                    width: 4.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 타이틀: 나의 할 일
                    const Text(
                      '나의 할 일',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 남은 할 일 수 카운터 표시
                    Row(
                      children: [
                        const Text(
                          '남은 할 일 ',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$_remainingCount',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff008080), // Teal 계열 포인트 컬러
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Color(0xffe0e0e0), thickness: 1),
                    const SizedBox(height: 12),

                    // 할 일 목록 빌더
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _todoList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _todoList[index];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            // 완료 시 연한 녹색 배경, 미완료 시 흰색 바탕에 옅은 회색 테두리
                            color: item.isCompleted 
                                ? const Color(0xffeff9f5) 
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: item.isCompleted 
                                  ? const Color(0xffd1ebd9) 
                                  : const Color(0xffe2e8f0),
                              width: 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          child: Row(
                            children: [
                              // 상태 아이콘 (체크마크 / 빈 원)
                              item.isCompleted
                                  ? const Icon(Icons.check, color: Color(0xff2ecc71), size: 18)
                                  : Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.grey.shade400, width: 1.5),
                                      ),
                                    ),
                              const SizedBox(width: 12),
                              
                              // 할 일 텍스트
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              
                              // 우측 액션 버튼 (완료 / 취소 상태 토글)
                              TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: const Color(0xfff8fafc),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    side: const BorderSide(color: Color(0xffe2e8f0), width: 1.0),
                                  ),
                                ),
                                onPressed: () {
                                  // 상태 스위칭 및 UI 리렌더링
                                  setState(() {
                                    item.isCompleted = !item.isCompleted;
                                  });
                                },
                                child: Text(
                                  item.isCompleted ? '취소' : '완료',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: item.isCompleted 
                                        ? const Color(0xff7f8c8d) // 취소 버튼은 회색조
                                        : const Color(0xff34495e), // 완료 버튼은 짙은 색
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
