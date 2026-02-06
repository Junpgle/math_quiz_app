import 'package:flutter/material.dart';
import '../storage_service.dart';
import 'home_dashboard.dart'; // 修改：引入新的 Dashboard

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    String user = _userController.text.trim();
    String pass = _passController.text.trim();
    if (user.isEmpty || pass.isEmpty) return;

    setState(() => _isLoading = true);

    bool success = await StorageService.login(user, pass);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      await StorageService.saveLoginSession(user);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        // 修改：跳转到新主页 HomeDashboard
        MaterialPageRoute(builder: (context) => HomeDashboard(username: user)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录失败：用户名不存在或密码错误')),
      );
    }
  }

  void _handleRegister() async {
    String user = _userController.text.trim();
    String pass = _passController.text.trim();
    if (user.isEmpty || pass.isEmpty) return;

    bool success = await StorageService.register(user, pass);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('注册成功，请登录')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('注册失败：用户名已存在')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('效率 & 数学 - 登录')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text("效率 & 数学助手", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: '用户名', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passController,
              decoration: const InputDecoration(labelText: '密码', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Row(
                children: [
                  Expanded(child: FilledButton(onPressed: _handleLogin, child: const Text("登录"))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton(onPressed: _handleRegister, child: const Text("注册"))),
                ],
              )
          ],
        ),
      ),
    );
  }
}