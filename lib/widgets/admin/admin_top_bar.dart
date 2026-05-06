import 'package:flutter/material.dart';

class AdminTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF3E494A)),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.help_outline, color: Color(0xFF3E494A)),
                const SizedBox(width: 12),
                const Icon(Icons.notifications_none, color: Color(0xFF3E494A)),
                const SizedBox(width: 12),
                if (trailing != null) trailing!,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
