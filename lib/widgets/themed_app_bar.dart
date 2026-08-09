import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';

class ThemedAppBar extends StatelessWidget
    implements PreferredSizeWidget {

  final String title;

  const ThemedAppBar({
    super.key,
    required this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ChatTheme.reloadNotifier,
      builder: (context, _, __) {
        final isDark = ChatTheme.isDarkMode;
        final textColor = isDark ? Colors.white : Colors.black;

        return AppBar(
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          centerTitle: true,
          backgroundColor: ChatTheme.backgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
        );
      },
    );
  }
}
