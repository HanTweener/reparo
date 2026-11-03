import 'package:flutter/material.dart';
import '../state/auth_state.dart';
import '../theme/reparo_theme.dart';
import '../widgets/reparo_button.dart';
import '../widgets/reparo_logo.dart';

class RegisterScreen extends StatefulWidget {
  final AuthState authState;
  final VoidCallback onGoToLogin;

  const RegisterScreen({
    super.key,
    required this.authState,
    required this.onGoToLogin,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.authState.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
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
            constraints: const BoxConstraints(maxWidth: 440),
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
                    child: ReparoLogo(size: 44),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Daftar Akun Pelanggan',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: ReparoTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Buat akun untuk mendaftarkan perangkat dan pesanan maintenance',
                    style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Staff policy notice (FEAT-001)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ReparoTheme.surfaceRaised,
                      borderRadius: BorderRadius.circular(ReparoTheme.radiusControl),
                      border: Border.all(color: ReparoTheme.border),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: ReparoTheme.accent),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pendaftaran publik hanya membuat akun Pelanggan. Akun staf (Teknisi & Admin) dibuat langsung oleh Administrator.',
                            style: TextStyle(fontSize: 12, color: ReparoTheme.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

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
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi.' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Alamat Email'),
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
                      helperText: 'Minimal 8 karakter',
                    ),
                    validator: (v) {
                      if (v == null || v.length < 8) return 'Kata sandi minimal 8 karakter.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Konfirmasi Kata Sandi'),
                    validator: (v) {
                      if (v != _passwordController.text) return 'Konfirmasi kata sandi tidak cocok.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  ReparoButton(
                    label: 'Daftar Sekarang',
                    onPressed: _submit,
                    isLoading: auth.isLoading,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah memiliki akun? ',
                        style: TextStyle(fontSize: 13, color: ReparoTheme.textMuted),
                      ),
                      TextButton(
                        onPressed: widget.onGoToLogin,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ReparoTheme.accent,
                          ),
                        ),
                      ),
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
}

