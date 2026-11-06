import 'package:baby_vax/app/core/imports/import_manger.dart';

/// Confirmation sheet for account deletion.
///
/// Deliberately requires the password rather than a plain "are you sure":
/// Firebase needs recent credentials to delete a user anyway, and it stops a
/// borrowed unlocked phone from wiping a child's whole vaccination history.
///
/// Returns the entered password via `Get.back(result: ...)`, or null if the
/// user backs out.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final TextEditingController _passwordController = TextEditingController();
  String? _error;
  bool _obscured = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final String password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = "DeleteAccount_empty_password_msg".tr);
      return;
    }
    Get.back<String>(result: password);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
          8.sbw,
          Expanded(
            child: Text(
              "DeleteAccount_title".tr,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "DeleteAccount_warning_msg".tr,
              style: theme.textTheme.bodyMedium,
            ),
            16.sbh,
            Text(
              "DeleteAccount_password_label".tr,
              style: theme.textTheme.labelLarge,
            ),
            8.sbh,
            TextField(
              controller: _passwordController,
              obscureText: _obscured,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: "DeleteAccount_password_hint".tr,
                errorText: _error,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  // Labelled for screen readers; an unlabelled icon button is
                  // announced only as "button".
                  tooltip: _obscured ? "show".tr : "hide".tr,
                  icon: Icon(
                      _obscured ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscured = !_obscured),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Get.back<String>(),
          child: Text("DeleteAccount_cancel_button".tr),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          onPressed: _submit,
          child: Text("DeleteAccount_confirm_button".tr),
        ),
      ],
    );
  }
}
