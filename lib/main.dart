import 'package:flutter/foundation.dart'; // 引入 kIsWeb
import 'package:flutter/material.dart';
import 'dart:io'; // 用于 Platform Check
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart'; // Desktop 窗口管理

import 'screens/login_screen.dart';
import 'screens/home_dashboard.dart';
import 'storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初始化 Flutter Downloader (仅限 Android/iOS, 非Web)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
    } catch (e) {
      print("Downloader init failed: $e");
    }
  }

  // 2. 初始化 Window Manager (仅限 Desktop, 非Web)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // 3. 权限请求 (主要针对移动端)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    // 通知权限
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    // Android 安装包权限
    if (Platform.isAndroid && await Permission.requestInstallPackages.isDenied) {
      await Permission.requestInstallPackages.request();
    }
  }

  // 4. 检查登录状态
  String? loggedInUser = await StorageService.getLoginSession();

  runApp(MyApp(initialUser: loggedInUser));
}

class MyApp extends StatelessWidget {
  final String? initialUser;

  const MyApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '效率 & 数学',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // 国际化配置
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      // 路由判断
      home: initialUser != null && initialUser!.isNotEmpty
          ? HomeDashboard(username: initialUser!)
          : const LoginScreen(),
    );
  }
}