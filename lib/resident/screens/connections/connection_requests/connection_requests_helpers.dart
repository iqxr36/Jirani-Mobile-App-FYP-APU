// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : connection_requests_helpers.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Friday,26-June-2026
// Last Edited on  : Saturday,18-July-2026

part of '../resident_connection_requests_view.dart';

String _neighborRole(AppUser user) {
  final community = user.communityName.trim();
  if (community.isNotEmpty) return 'Resident neighbor in $community';
  return 'Resident neighbor';
}

String _shortUserId(String uid) {
  if (uid.length <= 6) return uid;
  return 'ID ${uid.substring(0, 6)}...';
}

String _timeLabel(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
  return '${(diff.inDays / 30).floor()} months ago';
}
