import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:valet_parkomate/services/notification_service.dart';
import 'package:valet_parkomate/services/auth_service.dart';
import 'package:valet_parkomate/screens/login_screen.dart';
import 'package:valet_parkomate/screens/superadmin/superadmin_screen.dart';
import 'package:valet_parkomate/screens/site_home_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService().init();

  // Create AuthService and wait for it to load the stored session
  final authService = AuthService();
  await authService.loadFromStorage();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
      ],
      child: const ValetApp(),
    ),
  );
}

class ValetApp extends StatelessWidget {
  const ValetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parkomate Valet',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const RootDecider(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/superadmin': (_) => const SuperadminScreen(),
      },
    );
  }
}

class RootDecider extends StatelessWidget {
  const RootDecider({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    // If session is still loading
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // If user is not logged in, show login screen
    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    // Superadmin route
    if (auth.userSession?.siteNo == 0) {
      return const SuperadminScreen();
    }

    // Site-specific roles
    return SiteHomeRouter(
      siteNo: auth.userSession!.siteNo,
      role: auth.userSession!.role,
      driverId: auth.userSession!.id, // Pass the user ID for Driver screen
    );
  }
}