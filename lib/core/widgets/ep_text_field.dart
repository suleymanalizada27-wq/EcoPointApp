import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/ep_colors.dart';
import '../../app/theme/tokens.dart';

/// Themed text field. Uses explicit decoration (no reliance on theme-level
/// InputDecorationTheme) so it looks identical across Flutter versions.
class EpTextField extends StatefulWidget {
  const EpTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  @override
  State<EpTextField> createState() => _EpTextFieldState();
}

class _EpTextFieldState extends State<EpTextField> {
  late bool _hidden = widget.obscure;

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: Rad.field,
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _hidden,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      textCapitalization: widget.textCapitalization,
      style: context.text.bodyLarge,
      cursorColor: c.emerald,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        counterText: '',
        filled: true,
        fillColor: c.surface,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: context.text.bodyMedium?.copyWith(color: c.textSecondary),
        hintStyle: context.text.bodyMedium?.copyWith(color: c.textTertiary),
        errorStyle: context.text.bodySmall?.copyWith(color: c.danger),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 16),
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(widget.prefixIcon, color: c.textSecondary, size: 20),
        suffixIcon: widget.obscure
            ? IconButton(
                tooltip: _hidden ? 'Show' : 'Hide',
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: c.textSecondary,
                  size: 20,
                ),
              )
            : widget.suffix,
        border: _border(c.outline),
        enabledBorder: _border(c.outline),
        focusedBorder: _border(c.emerald, 1.6),
        errorBorder: _border(c.danger),
        focusedErrorBorder: _border(c.danger, 1.6),
        disabledBorder: _border(c.outline.withValues(alpha: 0.5)),
      ),
    );
  }
}
