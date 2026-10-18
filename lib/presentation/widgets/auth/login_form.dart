import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/widgets/auth/auth_form_widgets.dart';
import 'package:toktok/presentation/widgets/auth/auth_header.dart';
import 'package:toktok/presentation/widgets/auth/auth_styles.dart';

class LoginForm extends StatefulWidget {

  final VoidCallback onClose;
  final VoidCallback onGoToRegister;
  final VoidCallback onAuthenticated;

  const LoginForm({
    super.key,
    required this.onClose,
    required this.onGoToRegister,
    required this.onAuthenticated,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
      return;
    }
    if (!mounted) return;

    widget.onAuthenticated();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature estará disponible pronto')));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeader(
          title: 'Inicia sesión',
          subtitle: 'Para seguir viendo, dar me gusta y comentar.',
          onClose: widget.onClose,
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    label: 'Correo electrónico',
                    hint: 'tu@correo.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: AuthValidators.email,
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    label: 'Contraseña',
                    hint: '••••••••',
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: AuthValidators.requiredPassword,
                    suffix: PasswordToggle(
                      isVisible: _showPassword,
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Wrap en vez de Row: con letra grande pasa a dos líneas
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AuthCheckbox(
                        value: _rememberMe,
                        onChanged: (value) => setState(() => _rememberMe = value),
                        label: const Text('Recordarme'),
                      ),
                      AuthLink(
                        label: '¿Olvidaste tu contraseña?',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        onPressed: () => _showComingSoon('Recuperar contraseña'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_errorMessage != null) ...[
                    AuthErrorMessage(message: _errorMessage!),
                    const SizedBox(height: 12),
                  ],

                  AuthPrimaryButton(
                    label: 'Iniciar sesión',
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Expanded(child: Divider(color: AuthColors.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'o continúa con',
                          style: textTheme.bodySmall?.copyWith(color: AuthColors.muted),
                        ),
                      ),
                      const Expanded(child: Divider(color: AuthColors.divider)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          label: 'Google',
                          onPressed: () => _showComingSoon('Inicio con Google'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SocialButton(
                          label: 'Facebook',
                          onPressed: () => _showComingSoon('Inicio con Facebook'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '¿No tienes cuenta?',
                        style: textTheme.bodyMedium?.copyWith(color: AuthColors.label),
                      ),
                      AuthLink(label: 'Regístrate', onPressed: widget.onGoToRegister),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class _SocialButton extends StatelessWidget {

  final String label;
  final VoidCallback onPressed;

  const _SocialButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AuthColors.text,
          side: const BorderSide(color: AuthColors.fieldBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
