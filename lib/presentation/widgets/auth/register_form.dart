import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/widgets/auth/auth_form_widgets.dart';
import 'package:toktok/presentation/widgets/auth/auth_header.dart';
import 'package:toktok/presentation/widgets/auth/auth_styles.dart';

class RegisterForm extends StatefulWidget {

  final VoidCallback onClose;
  final VoidCallback onGoToLogin;
  final VoidCallback onAuthenticated;

  const RegisterForm({
    super.key,
    required this.onClose,
    required this.onGoToLogin,
    required this.onAuthenticated,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _showPassword = false;
  bool _acceptedTerms = false;
  bool _termsError = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) return 'Repite tu contraseña';
    if (value != _passwordController.text) return 'Las contraseñas no coinciden';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final isFormValid = _formKey.currentState!.validate();
    setState(() => _termsError = !_acceptedTerms);
    if (!isFormValid || !_acceptedTerms) return;

    setState(() => _isLoading = true);
    await context.read<AuthProvider>().register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;

    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const linkStyle = TextStyle(color: AuthColors.accent, fontWeight: FontWeight.w500);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeader(
          title: 'Crea tu cuenta',
          isRegister: true,
          onClose: widget.onClose,
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 16),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    label: 'Nombre completo',
                    hint: 'Tu nombre',
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    autofillHints: const [AutofillHints.name],
                    validator: AuthValidators.name,
                  ),
                  const SizedBox(height: 10),
                  AuthTextField(
                    label: 'Correo electrónico',
                    hint: 'tu@correo.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: AuthValidators.email,
                  ),
                  const SizedBox(height: 10),
                  AuthTextField(
                    label: 'Contraseña',
                    hint: 'Mínimo 8 caracteres',
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: AuthValidators.newPassword,
                    suffix: PasswordToggle(
                      isVisible: _showPassword,
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AuthTextField(
                    label: 'Repite la contraseña',
                    hint: '••••••••',
                    controller: _confirmController,
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.done,
                    validator: _validateConfirmation,
                  ),
                  const SizedBox(height: 10),

                  AuthCheckbox(
                    value: _acceptedTerms,
                    hasError: _termsError,
                    onChanged: (value) => setState(() {
                      _acceptedTerms = value;
                      if (value) _termsError = false;
                    }),
                    label: const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: 'Acepto los '),
                          TextSpan(text: 'términos y condiciones', style: linkStyle),
                          TextSpan(text: ' y la política de privacidad.'),
                        ],
                      ),
                    ),
                  ),
                  if (_termsError)
                    Padding(
                      padding: const EdgeInsets.only(left: 29, top: 2),
                      child: Text(
                        'Debes aceptar los términos para continuar',
                        style: textTheme.bodySmall?.copyWith(color: AuthColors.error),
                      ),
                    ),
                  const SizedBox(height: 12),

                  AuthPrimaryButton(
                    label: 'Crear cuenta',
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 6),

                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes cuenta?',
                        style: textTheme.bodyMedium?.copyWith(color: AuthColors.label),
                      ),
                      AuthLink(label: 'Inicia sesión', onPressed: widget.onGoToLogin),
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
