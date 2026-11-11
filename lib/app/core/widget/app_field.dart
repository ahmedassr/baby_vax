import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:flutter/services.dart';

/// The app's one text field: a visible label above an input, with optional
/// hint, helper, error, unit suffix and password-visibility toggle.
///
/// Replaces v1.0's `AppTextField` + `LabeledTextField` pair, which between
/// them hard-coded six colours, a 20dp radius and a label in
/// `headLineMedium` (26sp) that was then overridden at every call site.
///
/// The label sits *above* the field rather than floating inside it. A
/// floating label shrinks to ~12sp once the field has a value, which in
/// Cairo Arabic is hard to read, and it is the only description of the
/// field a screen reader has.
class AppField extends StatefulWidget {
  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.suffixText,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLength,
    this.maxLines = 1,
    this.inputFormatters,
    this.autofillHints,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.optional = false,
  });

  /// Visible label, read by TalkBack as the field's name.
  final String label;

  final TextEditingController controller;

  /// Placeholder shown while empty.
  final String? hint;

  /// Persistent help under the field. Hidden while [errorText] is shown.
  final String? helper;

  /// Validation message. Non-null marks the field invalid.
  final String? errorText;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  /// A password field. Adds a show/hide toggle.
  final bool obscureText;

  /// Not typeable; typically a date opened with [onTap].
  final bool readOnly;

  final bool enabled;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// A unit after the value: "kg", "cm".
  final String? suffixText;

  final IconData? prefixIcon;

  /// Replaces the default suffix (ignored for [obscureText] fields).
  final Widget? suffixIcon;

  final int? maxLength;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  /// Appends "(optional)" to the label.
  final bool optional;

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String label = widget.optional
        ? '${widget.label} ${"optional_suffix".tr}'
        : widget.label;

    Widget? suffix = widget.suffixIcon;
    if (widget.obscureText) {
      suffix = IconButton(
        // Labelled for screen readers; an unlabelled icon button is read
        // only as "button".
        tooltip: _obscured ? "show".tr : "hide".tr,
        icon: Icon(_obscured
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined),
        onPressed: () => setState(() => _obscured = !_obscured),
      );
    } else if (widget.readOnly && widget.onTap != null && suffix == null) {
      suffix = Icon(Icons.calendar_today_outlined,
          size: 20, color: scheme.onSurfaceVariant);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // The visible label is excluded from semantics and given to the
        // field itself below, so TalkBack announces "Email, edit box" once
        // instead of reading the label and then an unnamed edit box.
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.xxs, bottom: AppSpacing.xs),
            child: Text(label, style: theme.textTheme.titleSmall),
          ),
        ),
        Semantics(
          label: label,
          textField: true,
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: _obscured,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            maxLength: widget.maxLength,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            inputFormatters: widget.inputFormatters,
            autofillHints: widget.autofillHints,
            textCapitalization: widget.textCapitalization,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: widget.hint,
              helperText: widget.errorText == null ? widget.helper : null,
              errorText: widget.errorText,
              suffixText: widget.suffixText,
              suffixStyle: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
              prefixIcon: widget.prefixIcon == null
                  ? null
                  : Icon(widget.prefixIcon, size: 20),
              suffixIcon: suffix,
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}
