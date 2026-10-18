import 'package:flutter/material.dart';
import 'package:toktok/presentation/widgets/auth/auth_styles.dart';

// ─── Campo de texto con etiqueta ──────────────────────────────────────────────

class AuthTextField extends StatelessWidget {

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? suffix;
  final FormFieldValidator<String>? validator;
  final Iterable<String>? autofillHints;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AuthColors.label,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          autofillHints: autofillHints,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          style: textTheme.bodyLarge?.copyWith(fontSize: 15, color: AuthColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: textTheme.bodyLarge?.copyWith(fontSize: 15, color: AuthColors.placeholder),
            filled: true,
            fillColor: AuthColors.fieldFill,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            enabledBorder: border(AuthColors.fieldBorder),
            focusedBorder: border(AuthColors.accent, 1.6),
            errorBorder: border(AuthColors.error),
            focusedErrorBorder: border(AuthColors.error, 1.6),
            errorStyle: textTheme.bodySmall?.copyWith(color: AuthColors.error),
          ),
        ),
      ],
    );
  }
}


// ─── Botón para mostrar / ocultar contraseña ──────────────────────────────────

class PasswordToggle extends StatelessWidget {

  final bool isVisible;
  final VoidCallback onPressed;

  const PasswordToggle({
    super.key,
    required this.isVisible,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: isVisible ? 'Ocultar contraseña' : 'Mostrar contraseña',
      icon: Icon(
        isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AuthColors.icon,
        size: 20,
      ),
    );
  }
}


// ─── Botón principal (Iniciar sesión / Crear cuenta) ──────────────────────────

class AuthPrimaryButton extends StatelessWidget {

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AuthColors.accent,
          disabledBackgroundColor: AuthColors.accent.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            )
          : Text(label),
      ),
    );
  }
}


// ─── Enlace de texto ("Regístrate", "¿Olvidaste tu contraseña?") ─────────────

class AuthLink extends StatelessWidget {

  final String label;
  final VoidCallback onPressed;
  final FontWeight fontWeight;
  final double fontSize;

  const AuthLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.fontWeight = FontWeight.w600,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AuthColors.accent,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      child: Text(label),
    );
  }
}


// ─── Casilla con texto ────────────────────────────────────────────────────────

class AuthCheckbox extends StatelessWidget {

  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget label;
  final bool hasError;

  const AuthCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: (newValue) => onChanged(newValue ?? false),
                activeColor: AuthColors.accent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: BorderSide(
                  color: hasError ? AuthColors.error : AuthColors.icon,
                  width: 1.4,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  height: 1.4,
                  color: AuthColors.label,
                ),
                child: label,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Validaciones ─────────────────────────────────────────────────────────────

class AuthValidators {

  static final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Ingresa tu correo';
    if (!_emailRegExp.hasMatch(email)) return 'Ingresa un correo válido';
    return null;
  }

  static String? requiredPassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    return null;
  }

  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Crea una contraseña';
    if (value.length < 8) return 'Debe tener al menos 8 caracteres';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu nombre';
    return null;
  }

}
