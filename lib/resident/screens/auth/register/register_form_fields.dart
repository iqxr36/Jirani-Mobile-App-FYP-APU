// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : register_form_fields.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../register_view.dart';

Widget _buildRegisterFieldGroup({
  required BuildContext context,
  required String label,
  required TextEditingController controller,
  required String hint,
  TextInputType keyboardType = TextInputType.text,
  bool obscureText = false,
  Widget? suffixIcon,
  TextInputAction textInputAction = TextInputAction.next,
  VoidCallback? onFieldSubmitted,
  String? Function(String?)? validator,
  List<TextInputFormatter>? inputFormatters,
  bool enabled = true,
}) {
  return ResidentRegistrationField(
    label: label,
    controller: controller,
    hint: hint,
    keyboardType: keyboardType,
    obscureText: obscureText,
    suffixIcon: suffixIcon,
    textInputAction: textInputAction,
    onFieldSubmitted: onFieldSubmitted,
    validator: validator,
    inputFormatters: inputFormatters,
    enabled: enabled,
  );
}
