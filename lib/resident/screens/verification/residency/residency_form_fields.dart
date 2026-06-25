part of '../residency_verification_view.dart';

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: _kBrandTeal,
                size: 34,
              ),
            ),
          ),
          const Text(
            'Residency Verification',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _kBrandTeal,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.appInk,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}

class _ReadOnlyLineField extends StatelessWidget {
  const _ReadOnlyLineField({required this.value, this.isMuted = false});

  final String value;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _outline(context, alpha: 0.12)),
        ),
      ),
      padding: const EdgeInsets.only(left: 9, right: 9),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isMuted ? context.appMuted : context.appInk,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _UnitNumberFields extends StatelessWidget {
  const _UnitNumberFields({
    required this.blockController,
    required this.floorController,
    required this.unitController,
    required this.floorFocusNode,
    required this.unitFocusNode,
  });

  final TextEditingController blockController;
  final TextEditingController floorController;
  final TextEditingController unitController;
  final FocusNode floorFocusNode;
  final FocusNode unitFocusNode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _UnitNumberSegmentField(
            controller: blockController,
            label: 'Block',
            hintText: 'B',
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
              LengthLimitingTextInputFormatter(1),
              _UpperCaseTextFormatter(),
            ],
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => floorFocusNode.requestFocus(),
          ),
        ),
        const _UnitNumberSeparator(),
        Expanded(
          child: _UnitNumberSegmentField(
            controller: floorController,
            focusNode: floorFocusNode,
            label: 'Floor',
            hintText: '12',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => unitFocusNode.requestFocus(),
          ),
        ),
        const _UnitNumberSeparator(),
        Expanded(
          child: _UnitNumberSegmentField(
            controller: unitController,
            focusNode: unitFocusNode,
            label: 'Unit',
            hintText: '3',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
          ),
        ),
      ],
    );
  }
}

class _UnitNumberSeparator extends StatelessWidget {
  const _UnitNumberSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Text(
        '-',
        style: TextStyle(
          color: context.appMuted,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _UnitNumberSegmentField extends StatelessWidget {
  const _UnitNumberSegmentField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.keyboardType,
    required this.inputFormatters,
    required this.textInputAction,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hintText;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        onSubmitted: onSubmitted,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: context.appInk,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          counterText: '',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: TextStyle(
            color: context.appMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(
            color: context.appMuted.withValues(alpha: 0.72),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
          filled: true,
          fillColor: _surface(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _outline(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _outline(context)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: _kBrandTeal, width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class _LineSelectField extends StatelessWidget {
  const _LineSelectField({
    required this.value,
    required this.isPlaceholder,
    required this.onTap,
  });

  final String value;
  final bool isPlaceholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surface(context),
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: _outline(context, alpha: 0.12)),
            ),
          ),
          padding: const EdgeInsets.only(left: 9, right: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isPlaceholder
                        ? context.appMuted
                        : context.appInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 25),
            ],
          ),
        ),
      ),
    );
  }
}
