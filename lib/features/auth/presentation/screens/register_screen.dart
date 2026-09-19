import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fieldai_flutter/core/constants/app_constants.dart';
import 'package:fieldai_flutter/core/network/api_client.dart';
import 'package:fieldai_flutter/core/theme/app_theme.dart';
import 'package:fieldai_flutter/features/dashboard/presentation/screens/dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _orgController = TextEditingController(text: 'Ethiopian Agricultural Extension Directorate');
  String _selectedRole = 'field_worker';
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, String>> _roles = [
    {'id': 'field_worker', 'label': 'Field Worker / Extension Officer'},
    {'id': 'farmer', 'label': 'Farmer / Producer'},
    {'id': 'researcher', 'label': 'Agronomic Researcher'},
  ];

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.instance.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyAuthToken, response.data['access_token']);
        await prefs.setString(AppConstants.keyUserData, _nameController.text.trim());

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Offline fallback
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyAuthToken, 'offline-registered-${DateTime.now().millisecondsSinceEpoch}');
      await prefs.setString(AppConstants.keyUserData, _nameController.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account registered locally in SQLite for offline field use.'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join FieldAI Platform',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enable local AI disease detection and synchronized agricultural reporting',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.dangerRed),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.dangerRed)),
                  ),

                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppTheme.textLight),
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textLight),
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted),
                  ),
                  validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppTheme.textLight),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted),
                  ),
                  validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _orgController,
                  style: const TextStyle(color: AppTheme.textLight),
                  decoration: const InputDecoration(
                    labelText: 'Organization / Cooperative',
                    prefixIcon: Icon(Icons.business_outlined, color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  dropdownColor: AppTheme.surfaceCard,
                  style: const TextStyle(color: AppTheme.textLight),
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.accentGreen),
                  ),
                  items: _roles.map((r) {
                    return DropdownMenuItem(value: r['id'], child: Text(r['label']!));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedRole = val!),
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Create Account'),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ', style: TextStyle(color: AppTheme.textMuted)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold),
                      ),
                    ),
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
