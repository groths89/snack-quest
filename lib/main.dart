import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/pantry_provider.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  final pantry = PantryProvider();
  await pantry.load();
  runApp(ChangeNotifierProvider.value(value: pantry, child: const SnackQuestApp()));
}

class SnackQuestApp extends StatelessWidget {
  const SnackQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'SnackQuest',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.coral,
        scaffoldBackgroundColor: AppColors.bg,
      ),
      home: HomeScreen(),
    );
  }
}
