import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; // 需要引入 Uuid 生成ID
import 'models.dart';
import 'api_service.dart'; // 引入API服务

class StorageService {
  // ignore: constant_identifier_names
  static const String KEY_USERS = "users_data";
  // ignore: constant_identifier_names
  static const String KEY_LEADERBOARD = "leaderboard_data";
  // ignore: constant_identifier_names
  static const String KEY_SETTINGS = "quiz_settings";
  // ignore: constant_identifier_names
  static const String KEY_CURRENT_USER = "current_login_user";

  // ignore: constant_identifier_names
  static const String KEY_TODOS = "user_todos";
  // ignore: constant_identifier_names
  static const String KEY_COUNTDOWNS = "user_countdowns";

  // 防止并发同步的标志位
  static bool _isSyncing = false;

  // 注册用户
  static Future<bool> register(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> users = {};
    String? usersJson = prefs.getString(KEY_USERS);
    if (usersJson != null) users = jsonDecode(usersJson);
    if (users.containsKey(username)) return false;
    users[username] = password;
    await prefs.setString(KEY_USERS, jsonEncode(users));
    return true;
  }

  static Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    String? usersJson = prefs.getString(KEY_USERS);
    if (usersJson == null) return false;
    Map<String, dynamic> users = jsonDecode(usersJson);
    return users.containsKey(username) && users[username] == password;
  }

  static Future<void> saveLoginSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_CURRENT_USER, username);
  }

  static Future<String?> getLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_CURRENT_USER);
  }

  static Future<void> clearLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_CURRENT_USER);
  }

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_SETTINGS, jsonEncode(settings));
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonStr = prefs.getString(KEY_SETTINGS);
    if (jsonStr != null) return Map<String, dynamic>.from(jsonDecode(jsonStr));
    return {
      'operators': ['+', '-'],
      'min_num1': 0, 'max_num1': 50,
      'min_num2': 0, 'max_num2': 50,
      'max_result': 100,
    };
  }

  // --- 历史记录与统计 ---

  static Future<void> saveHistory(String username, int score, int duration, String details) async {
    final prefs = await SharedPreferences.getInstance();
    String key = "history_$username";
    List<String> history = prefs.getStringList(key) ?? [];

    Map<String, dynamic> recordMap = {
      'date': DateTime.now().toIso8601String(),
      'score': score,
      'duration': duration,
      'details': details
    };

    history.insert(0, jsonEncode(recordMap));
    await prefs.setStringList(key, history);
  }

  static Future<List<String>> getHistory(String username) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> rawList = prefs.getStringList("history_$username") ?? [];

    return rawList.map((item) {
      try {
        var map = jsonDecode(item);
        if (map is Map) {
          String timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(map['date']));
          return "时间: $timeStr\n得分: ${map['score']}\n用时: ${map['duration']}秒\n详情:\n${map['details']}\n-----------------";
        }
        return item;
      } catch (e) {
        return item;
      }
    }).toList();
  }

  static Future<Map<String, dynamic>> getMathStats(String username) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> rawList = prefs.getStringList("history_$username") ?? [];

    int totalQuestions = 0;
    int totalCorrect = 0;
    int bestTime = 999999;
    bool hasPerfectScore = false;
    int todayCount = 0; // 新增：今日完成次数
    DateTime now = DateTime.now();

    for (var item in rawList) {
      try {
        var map = jsonDecode(item);
        int score = map['score'];
        int duration = map['duration'];

        // 统计今日次数
        if (map['date'] != null) {
          DateTime date = DateTime.parse(map['date']);
          if (date.year == now.year && date.month == now.month && date.day == now.day) {
            todayCount++;
          }
        }

        totalQuestions += 10;
        totalCorrect += (score ~/ 10);

        if (score == 100) {
          hasPerfectScore = true;
          if (duration < bestTime) bestTime = duration;
        }
      } catch (e) {
        // 旧数据兼容处理
        RegExp scoreReg = RegExp(r"得分: (\d+)");
        var match = scoreReg.firstMatch(item);
        if (match != null) {
          int score = int.parse(match.group(1)!);
          totalQuestions += 10;
          totalCorrect += (score ~/ 10);
        }
      }
    }

    double accuracy = totalQuestions == 0 ? 0.0 : (totalCorrect / totalQuestions);

    return {
      'accuracy': accuracy,
      'bestTime': hasPerfectScore ? bestTime : null,
      'todayCount': todayCount, // 返回今日次数
    };
  }

  static Future<void> updateLeaderboard(String username, int score, int duration) async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> list = [];
    String? jsonStr = prefs.getString(KEY_LEADERBOARD);
    if (jsonStr != null) list = jsonDecode(jsonStr);
    list.add({'username': username, 'score': score, 'time': duration});
    list.sort((a, b) {
      if (a['score'] != b['score']) return b['score'].compareTo(a['score']);
      return a['time'].compareTo(b['time']);
    });
    if (list.length > 10) list = list.sublist(0, 10);
    await prefs.setString(KEY_LEADERBOARD, jsonEncode(list));

    // 触发数据同步 (自动上传最高分)
    syncData(username);
  }

  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonStr = prefs.getString(KEY_LEADERBOARD);
    if (jsonStr == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
  }

  // --- 待办事项与倒计时 ---

  // 保存倒计时，增加 sync 参数控制是否触发同步
  static Future<void> saveCountdowns(String username, List<CountdownItem> items, {bool sync = true}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonList = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList("${KEY_COUNTDOWNS}_$username", jsonList);

    // 如果启用了同步，触发后台同步
    if (sync) syncData(username);
  }

  static Future<List<CountdownItem>> getCountdowns(String username) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList("${KEY_COUNTDOWNS}_$username") ?? [];
    return list.map((e) => CountdownItem.fromJson(jsonDecode(e))).toList();
  }

  // 保存待办，增加 sync 参数控制是否触发同步
  static Future<void> saveTodos(String username, List<TodoItem> items, {bool sync = true}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonList = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList("${KEY_TODOS}_$username", jsonList);

    // 如果启用了同步，触发后台同步
    if (sync) syncData(username);
  }

  static Future<List<TodoItem>> getTodos(String username) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList("${KEY_TODOS}_$username") ?? [];
    List<TodoItem> todos = list.map((e) => TodoItem.fromJson(jsonDecode(e))).toList();

    DateTime now = DateTime.now();
    bool needSave = false;

    for (var todo in todos) {
      if (todo.recurrenceEndDate != null && now.isAfter(todo.recurrenceEndDate!)) {
        continue;
      }

      bool isNewDay = !_isSameDay(todo.lastUpdated, now);

      if (isNewDay) {
        if (todo.recurrence == RecurrenceType.daily) {
          todo.isDone = false;
          todo.lastUpdated = now;
          needSave = true;
        } else if (todo.recurrence == RecurrenceType.customDays && todo.customIntervalDays != null) {
          int diff = now.difference(todo.lastUpdated).inDays;
          if (diff >= todo.customIntervalDays!) {
            todo.isDone = false;
            todo.lastUpdated = now;
            needSave = true;
          }
        }
      }
    }

    if (needSave) {
      // 自动生成的日常重置也触发同步
      await saveTodos(username, todos, sync: true);
    }

    return todos;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // --- 核心同步功能 (修复版：基于 updated_at 的精确同步) ---
  // 返回值：是否执行了任何更新 (true: 有数据变更, false: 无变更或失败)
  static Future<bool> syncData(String username) async {
    if (_isSyncing) return false; // 避免并发同步
    _isSyncing = true;
    bool hasChanges = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('current_user_id');
      if (userId == null) return false; // 未登录云端不执行

      // 1. 同步最高分 (本地历史记录 -> 云端)
      List<String> historyList = prefs.getStringList("history_$username") ?? [];
      int bestScore = 0;
      int bestDuration = 9999;
      for (var item in historyList) {
        try {
          var map = jsonDecode(item);
          int s = map['score'];
          int d = map['duration'];
          if (s > bestScore) {
            bestScore = s;
            bestDuration = d;
          } else if (s == bestScore && d < bestDuration) {
            bestDuration = d;
          }
        } catch (_) {}
      }
      if (bestScore > 0) {
        await ApiService.uploadScore(
          userId: userId,
          username: username,
          score: bestScore,
          duration: bestDuration,
        );
      }

      // 2. 同步待办事项 (基于时间戳的双向同步)
      List<TodoItem> localTodos = await getTodos(username);
      List<dynamic> cloudTodos = await ApiService.fetchTodos(userId);
      bool localTodosChanged = false;

      // 构建映射以方便查找
      Map<String, dynamic> cloudMap = {}; // Content -> CloudItem
      for (var t in cloudTodos) {
        if (t['content'] != null) cloudMap[t['content']] = t;
      }

      // A. 遍历本地：上传缺失的 或 更新状态
      for (var localItem in localTodos) {
        if (cloudMap.containsKey(localItem.title)) {
          var cloudItem = cloudMap[localItem.title];
          bool cloudDone = cloudItem['is_completed'] == 1 || cloudItem['is_completed'] == true;
          int cloudId = cloudItem['id'];

          // 核心修复：解析云端时间戳
          // D1 返回的 CURRENT_TIMESTAMP 是 UTC 格式 (e.g. "2023-10-01 12:00:00") 但可能不带 'Z'
          // 为了正确比较，我们需要确保它被解析为 UTC，然后转为本地时间与 localItem.lastUpdated 比较
          String timeStr = cloudItem['updated_at'] ?? cloudItem['created_at'] ?? "";
          if (timeStr.isNotEmpty && !timeStr.endsWith('Z')) {
            timeStr += 'Z'; // 强制视为 UTC
          }
          DateTime cloudTime = DateTime.tryParse(timeStr)?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);

          // 状态不一致时，谁的时间晚（谁更新），听谁的
          if (localItem.isDone != cloudDone) {
            if (localItem.lastUpdated.isAfter(cloudTime)) {
              // 本地更新，推送到云端 (例如：刚点击了完成)
              await ApiService.toggleTodo(cloudId, localItem.isDone);
            } else {
              // 云端更新，拉取到本地 (例如：在其他设备点过完成了)
              localItem.isDone = cloudDone;
              localItem.lastUpdated = cloudTime; // 更新本地时间戳以保持一致
              localTodosChanged = true;
            }
          }
        } else {
          // 本地有，云端无 -> 上传 (仅限未完成的，避免上传已删除的历史)
          if (!localItem.isDone) {
            await ApiService.addTodo(userId, localItem.title);
          }
        }
      }

      // B. 遍历云端：下载本地缺失的
      for (var content in cloudMap.keys) {
        // 如果本地没有这个待办
        if (!localTodos.any((t) => t.title == content)) {
          var cloudItem = cloudMap[content];
          bool isCompleted = cloudItem['is_completed'] == 1 || cloudItem['is_completed'] == true;

          // 仅拉取未完成的任务进行恢复
          if (!isCompleted) {
            String timeStr = cloudItem['updated_at'] ?? cloudItem['created_at'] ?? "";
            if (timeStr.isNotEmpty && !timeStr.endsWith('Z')) timeStr += 'Z';

            localTodos.insert(0, TodoItem(
              id: const Uuid().v4(), // 生成新ID
              title: content,
              isDone: false,
              recurrence: RecurrenceType.none,
              lastUpdated: DateTime.tryParse(timeStr)?.toLocal() ?? DateTime.now(),
            ));
            localTodosChanged = true;
          }
        }
      }

      if (localTodosChanged) {
        // 保存本地更改，注意 sync: false 防止死循环
        localTodos.sort((a, b) {
          if (a.isDone == b.isDone) return 0;
          return a.isDone ? 1 : -1;
        });
        await saveTodos(username, localTodos, sync: false);
        hasChanges = true;
      }

      // 3. 同步倒计时 (双向合并)
      List<CountdownItem> localCountdowns = await getCountdowns(username);
      List<dynamic> cloudCountdowns = await ApiService.fetchCountdowns(userId);
      bool countdownsChanged = false;

      Set<String> cloudTitles = cloudCountdowns.map((e) => (e['title'] as String?) ?? "").toSet();
      Set<String> localTitles = localCountdowns.map((e) => e.title).toSet();

      // 本地 -> 云端
      for (var item in localCountdowns) {
        if (!cloudTitles.contains(item.title)) {
          await ApiService.addCountdown(userId, item.title, item.targetDate);
        }
      }

      // 云端 -> 本地
      for (var item in cloudCountdowns) {
        String title = item['title'] ?? "";
        // 如果云端有，本地没有
        if (title.isNotEmpty && !localTitles.contains(title)) {
          String dateStr = item['target_time'] ?? item['date'] ?? "";
          DateTime? target = DateTime.tryParse(dateStr);
          // 且未过期
          if (target != null && target.isAfter(DateTime.now())) {
            localCountdowns.add(CountdownItem(title: title, targetDate: target));
            countdownsChanged = true;
          }
        }
      }

      if (countdownsChanged) {
        localCountdowns.sort((a, b) => a.targetDate.compareTo(b.targetDate));
        await saveCountdowns(username, localCountdowns, sync: false);
        hasChanges = true;
      }

    } catch (e) {
      print("Auto-sync error: $e");
    } finally {
      _isSyncing = false;
    }

    return hasChanges;
  }
}