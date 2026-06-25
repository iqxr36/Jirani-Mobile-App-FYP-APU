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
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: _registerLabelStyle(context)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        obscureText: obscureText,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
        style: TextStyle(fontSize: 15, color: context.appInk),
        onFieldSubmitted: onFieldSubmitted != null
            ? (_) => onFieldSubmitted()
            : null,
        decoration: _registerInputDecoration(
          context,
          hint: hint,
          suffixIcon: suffixIcon,
        ),
        validator: validator,
      ),
    ],
  );
}
