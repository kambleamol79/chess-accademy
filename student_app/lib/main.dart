import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/batch_controller.dart';
import 'controllers/home_controller.dart';
import 'controllers/payments_controller.dart';
import 'controllers/puzzle_controller.dart';
import 'controllers/reminders_controller.dart';
import 'controllers/support_controller.dart';
import 'controllers/batch_messages_controller.dart';
// FEATURE: live arena — enable when ready
// import 'controllers/arena_controller.dart';
import 'services/api_service.dart';
import 'services/push_notification_service.dart';
import 'services/stockfish_service.dart';
import 'services/storage_service.dart';
import 'views/login_view.dart';
import 'views/main_shell_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();
  final api = ApiService(storage);
  final push = PushNotificationService(api);
  final auth = AuthController(api, storage, push);
  await auth.bootstrap();
  final stockfish = StockfishService();

  runApp(StudentApp(storage: storage, api: api, auth: auth, stockfish: stockfish, push: push));
}

class StudentApp extends StatelessWidget {
  const StudentApp({
    super.key,
    required this.storage,
    required this.api,
    required this.auth,
    required this.stockfish,
    required this.push,
  });

  final StorageService storage;
  final ApiService api;
  final AuthController auth;
  final StockfishService stockfish;
  final PushNotificationService push;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<ApiService>.value(value: api),
        Provider<PushNotificationService>.value(value: push),
        ChangeNotifierProvider<AuthController>.value(value: auth),
        ChangeNotifierProvider(create: (_) => HomeController(api)),
        ChangeNotifierProvider(create: (_) => BatchController(api)),
        ChangeNotifierProvider(create: (_) => PaymentsController(api)),
        ChangeNotifierProvider(create: (_) => RemindersController(api)),
        ChangeNotifierProvider(create: (_) => SupportController(api)),
        ChangeNotifierProvider(create: (_) => BatchMessagesController(api)),
        ChangeNotifierProvider(create: (c) => PuzzleController(api, c.read<StorageService>())),
        // ChangeNotifierProvider(create: (_) => ArenaController(api)),
        ChangeNotifierProvider<StockfishService>.value(value: stockfish),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: auth.isAuthenticated ? '/home' : '/login',
        routes: {
          '/login': (_) => const LoginView(),
          '/home': (_) => const MainShellView(),
        },
      ),
    );
  }
}
