import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jirani/resident/logic/resident_surface_tokens.dart';
import 'package:jirani/shared/models/community_model.dart';

const Color residentRegistrationBrandTeal = Color(0xFF006D77);
const double residentRegistrationCardRadius = 26;
const double residentRegistrationFieldRadius = 10;

TextStyle residentRegistrationLabelStyle(BuildContext context) =>
    TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.appInk);

InputDecoration residentRegistrationInputDecoration(
  BuildContext context, {
  required String hint,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: context.isDarkUi
        ? context.residentScheme.surfaceContainerHighest
        : Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    hintStyle: TextStyle(
      color: context.appMuted.withValues(alpha: 0.72),
      fontSize: 14,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(residentRegistrationFieldRadius),
      borderSide: BorderSide(color: context.residentOutline(lightAlpha: 0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(residentRegistrationFieldRadius),
      borderSide: const BorderSide(
        color: residentRegistrationBrandTeal,
        width: 1.3,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(residentRegistrationFieldRadius),
      borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.8)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(residentRegistrationFieldRadius),
      borderSide: const BorderSide(color: Colors.red, width: 1.3),
    ),
  );
}

class ResidentRegistrationHeader extends StatelessWidget {
  const ResidentRegistrationHeader({
    super.key,
    required this.title,
    required this.loading,
    required this.onBack,
  });

  final String title;
  final bool loading;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Back',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: residentRegistrationBrandTeal,
              ),
              onPressed: loading ? null : onBack,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style:
                  textTheme.titleMedium?.copyWith(
                    color: residentRegistrationBrandTeal,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ) ??
                  const TextStyle(
                    color: residentRegistrationBrandTeal,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResidentRegistrationFormCard extends StatelessWidget {
  const ResidentRegistrationFormCard({
    super.key,
    required this.formKey,
    required this.children,
  });

  final GlobalKey<FormState> formKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.glassFill(),
            borderRadius: BorderRadius.circular(residentRegistrationCardRadius),
            border: Border.all(
              color: context.residentOutline(lightAlpha: 0.12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResidentRegistrationField extends StatelessWidget {
  const ResidentRegistrationField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.validator,
    this.inputFormatters,
    this.enabled = true,
    this.readOnly = false,
    this.autofillHints,
    this.fieldKey,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputAction textInputAction;
  final VoidCallback? onFieldSubmitted;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool readOnly;
  final Iterable<String>? autofillHints;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: residentRegistrationLabelStyle(context)),
        const SizedBox(height: 6),
        TextFormField(
          key: fieldKey,
          controller: controller,
          enabled: enabled,
          readOnly: readOnly,
          keyboardType: keyboardType,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          style: TextStyle(fontSize: 15, color: context.appInk),
          onFieldSubmitted: onFieldSubmitted != null
              ? (_) => onFieldSubmitted!()
              : null,
          decoration: residentRegistrationInputDecoration(
            context,
            hint: hint,
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class ResidentCommunityPicker extends StatelessWidget {
  const ResidentCommunityPicker({
    super.key,
    required this.enabled,
    required this.communitiesLoading,
    required this.communitiesError,
    required this.activeCommunities,
    required this.selectedCommunity,
    required this.onSelectCommunity,
    this.emptyMessage =
        'You can select a community during location verification.',
    this.pickerKey,
  });

  final bool enabled;
  final bool communitiesLoading;
  final String? communitiesError;
  final List<CommunityModel> activeCommunities;
  final CommunityModel? selectedCommunity;
  final VoidCallback onSelectCommunity;
  final String emptyMessage;
  final Key? pickerKey;

  @override
  Widget build(BuildContext context) {
    final hasOptions = activeCommunities.isNotEmpty;
    final selectedName = selectedCommunity?.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community / Residence',
          style: residentRegistrationLabelStyle(context),
        ),
        const SizedBox(height: 6),
        if (communitiesLoading)
          const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          Material(
            color: Colors.transparent,
            child: InkWell(
              key:
                  pickerKey ??
                  const Key('resident-registration-community-picker'),
              onTap: enabled ? onSelectCommunity : null,
              borderRadius: BorderRadius.circular(
                residentRegistrationFieldRadius,
              ),
              child: InputDecorator(
                decoration: residentRegistrationInputDecoration(
                  context,
                  hint: hasOptions
                      ? 'Select your community'
                      : 'No active communities available',
                  suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
                isEmpty: selectedName == null || selectedName.isEmpty,
                child: Text(
                  selectedName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: enabled ? context.appInk : context.appMuted,
                  ),
                ),
              ),
            ),
          ),
        if (communitiesError != null || !hasOptions && !communitiesLoading)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              communitiesError ?? emptyMessage,
              style: TextStyle(fontSize: 11, color: context.appMuted),
            ),
          ),
      ],
    );
  }
}

class ResidentRegistrationPrimaryButton extends StatelessWidget {
  const ResidentRegistrationPrimaryButton({
    super.key,
    required this.loading,
    required this.label,
    required this.onPressed,
    this.buttonKey,
  });

  final bool loading;
  final String label;
  final Future<void> Function() onPressed;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        key: buttonKey,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: residentRegistrationBrandTeal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: residentRegistrationBrandTeal.withValues(
            alpha: 0.6,
          ),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
