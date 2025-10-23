import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:valet_parkomate/services/auth_service.dart';
import 'package:valet_parkomate/services/notification_service.dart';
import 'package:valet_parkomate/screens/site_home_router.dart';
import 'package:valet_parkomate/ui/shared/toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _siteController = TextEditingController(text: '1');
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _siteController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthService>(context, listen: false);

    try {
      final session = await auth.login(
        _siteController.text.trim(),
        _idController.text.trim(),
        _passwordController.text,
      );

      // Show success toast instead of a beep sound from the login screen
      Toast.show(context, 'Login successful!', isSuccess: true);
      await NotificationService().notifyWithSound(
          title: 'Welcome', body: 'Logged in as ${session.role}');

      // Navigate to the appropriate home screen based on the session
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SiteHomeRouter(
            siteNo: session.siteNo,
            role: session.role,
            driverId: session.id, // Pass the user ID for Driver screen
          ),
        ),
      );
    } catch (e) {
      // Show failure toast
      Toast.show(context, 'Login failed: ${e.toString().split(':').last}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Parkomate Valet',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign In',
                style: GoogleFonts.poppins(
                    fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _siteController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Site No',
                  hintText: 'e.g., 1 or 2 (0 = superadmin)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: 'User ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Sign In',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}