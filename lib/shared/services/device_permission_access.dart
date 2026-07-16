import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Feature-level permission guard for actions that require device hardware.
class DevicePermissionAccess {
  DevicePermissionAccess._();

  /// Requests camera access once after the user's action and explains blocked
  /// states without automatically retrying or reopening the OS prompt.
  static Future<bool> ensureCamera(BuildContext context) async {
    var status = await Permission.camera.status;
    if (status.isGranted || status.isLimited) return true;

    if (!status.isPermanentlyDenied && !status.isRestricted) {
      status = await Permission.camera.request();
      if (status.isGranted || status.isLimited) return true;
    }

    if (!context.mounted) return false;
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Camera Permission Needed'),
        content: Text(
          status.isPermanentlyDenied || status.isRestricted
              ? 'Camera access is disabled for Jirani. Enable it in app settings, then try again.'
              : 'Allow camera access to take this photo. You can try again when you are ready.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          if (status.isPermanentlyDenied || status.isRestricted)
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
    if (shouldOpenSettings == true) await openAppSettings();
    return false;
  }
}
