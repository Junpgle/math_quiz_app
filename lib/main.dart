import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/home_dashboard.dart';
import 'storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  } catch (e) {
    print("Downloader init failed: $e");
  }

  // 启动时请求关键权限
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  if (await Permission.requestInstallPackages.isDenied) {
    await Permission.requestInstallPackages.request();
  }

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