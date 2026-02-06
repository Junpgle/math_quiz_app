import 'package:flutter/material.dart';
import 'quiz_screen.dart';
import 'other_screens.dart';
import 'settings_screen.dart';

class MathMenuScreen extends StatefulWidget {
  final String username;
  const MathMenuScreen({super.key, required this.username});

  @override
  State<MathMenuScreen> createState() => _MathMenuScreenState();
}

class _MathMenuScreenState extends State<MathMenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("数学测验中心"),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.lightBlue]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.calculate, size: 48, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      "保持大脑活跃！",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "每日坚持练习，提高计算速度",
                      style: TextStyle(color: Colors.white70),
                    )
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _MenuCard(
                  title: "开始答题",
                  subtitle: "进入测验",
                  colorStart: const Color(0xFF4facfe),
                  colorEnd: const Color(0xFF00f2fe),
                  icon: Icons.play_arrow_rounded,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(username: widget.username))),
                ),
                _MenuCard(
                  title: "题目设置",
                  subtitle: "调整难度",
                  colorStart: const Color(0xFF43e97b),
                  colorEnd: const Color(0xFF38f9d7),
                  icon: Icons.tune_rounded,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
                _MenuCard(
                  title: "排行榜",
                  subtitle: "查看排名",
                  colorStart: const Color(0xFFfa709a),
                  colorEnd: const Color(0xFFfee140),
                  icon: Icons.emoji_events_rounded,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                ),
                _MenuCard(
                  title: "历史记录",
                  subtitle: "过往成绩",
                  colorStart: const Color(0xFF667eea),
                  colorEnd: const Color(0xFF764ba2),
                  icon: Icons.history_edu_rounded,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen(username: widget.username))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color colorStart;
  final Color colorEnd;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuCard({required this.title, required this.subtitle, required this.colorStart, required this.colorEnd, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colorStart, colorEnd]),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: Colors.white, size: 28)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}