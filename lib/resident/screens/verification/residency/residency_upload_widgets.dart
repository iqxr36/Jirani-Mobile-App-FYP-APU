// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : residency_upload_widgets.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../residency_verification_view.dart';

class _UploadPanel extends StatelessWidget {
  const _UploadPanel({
    required this.fileName,
    required this.acceptedFormats,
    required this.onGalleryTap,
    required this.onFilesTap,
  });

  final String? fileName;
  final String acceptedFormats;
  final VoidCallback? onGalleryTap;
  final VoidCallback? onFilesTap;

  @override
  Widget build(BuildContext context) {
    final selected = fileName != null && fileName!.isNotEmpty;

    return Container(
      constraints: const BoxConstraints(minHeight: 124),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _outline(context, alpha: 0.20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.check_circle_outline_rounded : Icons.upload_file,
            color: selected ? _kBrandTeal : context.appInk,
            size: 24,
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              selected
                  ? fileName!
                  : 'Ensure the document is clear and shows your\nname and unit number.\n$acceptedFormats',
              maxLines: selected ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appInk,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _UploadActionButton(
                  label: selected ? 'Replace Photo' : 'Gallery',
                  icon: Icons.photo_library_outlined,
                  onPressed: onGalleryTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _UploadActionButton(
                  label: selected ? 'Replace File' : 'Files',
                  icon: Icons.file_present_outlined,
                  onPressed: onFilesTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadActionButton extends StatelessWidget {
  const _UploadActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 15),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor: _kBrandTeal,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          disabledBackgroundColor: _kBrandTeal.withValues(alpha: 0.55),
          minimumSize: const Size(0, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: TextField(
        controller: controller,
        maxLines: 3,
        style: TextStyle(
          color: context.appInk,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Any additional details...',
          hintStyle: TextStyle(
            color: context.appMuted.withValues(alpha: 0.72),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.fromLTRB(15, 12, 15, 10),
          filled: true,
          fillColor: _surface(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: _outline(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: _outline(context)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(color: _kBrandTeal, width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _kBrandTeal,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          disabledBackgroundColor: _kBrandTeal.withValues(alpha: 0.58),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          isLoading ? 'Submitting...' : 'Submit Verification',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
