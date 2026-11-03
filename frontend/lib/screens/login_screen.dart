import 'package:flutter/material.dart';
import '../state/auth_state.dart';
import '../theme/reparo_theme.dart';
import '../widgets/reparo_button.dart';
import '../widgets/reparo_logo.dart';

class LoginScreen extends StatefulWidget {
  final AuthState authState;
  final VoidCallback onGoToRegister;

  const LoginScreen({
    super.key,
    required this.authState,
    required this.onGoToRegister,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.authState.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  void _quickFill(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.authState;

    return Scaffold(
      backgroundColor: ReparoTheme.frame,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: ReparoTheme.surface,
              borderRadius: BorderRadius.circular(ReparoTheme.radiusSheet),
              border: Border.all(color: ReparoTheme.border),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Center(
                    child: ReparoLogo(size: 48),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Reparo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: ReparoTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Masuk ke portal operasional perbaikan',
                    style: TextStyle(
                      fontSize: 14,
                      color: ReparoTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  if (auth.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ReparoTheme.statusErrorBg,
                        borderRadius: BorderRadius.circular(ReparoTheme.radiusControl),
                        border: Border.all(color: ReparoTheme.statusError.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        auth.errorMessage!,
                        style: const TextStyle(
                          color: ReparoTheme.statusError,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Email',
                      hintText: 'nama@example.com',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email wajib diisi.';
                      if (!v.contains('@')) return 'Format email tidak valid.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Kata Sandi',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Kata sandi wajib diisi.';
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),

                  ReparoButton(
                    label: 'Masuk',
                    onPressed: _submit,
                    isLoading: auth.isLoading,
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted),
                      ),
                      TextButton(
                        onPressed: widget.onGoToRegister,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text(
                          'Daftar Pelanggan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ReparoTheme.accent,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: ReparoTheme.rule),
                  const SizedBox(height: 16),

                  // Synthetic demo credentials quick fill
                  const Text(
                    'AKUN DEMO SINTETIS (Klik untuk coba)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ReparoTheme.textMuted,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildQuickDemoChip('Pelanggan', 'customer@reparo.test', 'Password123!'),
                      _buildQuickDemoChip('Teknisi', 'technician@reparo.test', 'Password123!'),
                      _buildQuickDemoChip('Admin', 'admin@reparo.test', 'Password123!'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDemoChip(String role, String email, String password) {
    return ActionChip(
      label: Text(
        role,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      backgroundColor: ReparoTheme.surfaceRaised,
      side: const BorderSide(color: ReparoTheme.border),
      onPressed: () => _quickFill(email, password),
    );
  }
}
