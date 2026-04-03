import 'package:flutter/widgets.dart';

String formatCompactDateTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month/$day ${local.year} $hour:$minute';
}

EdgeInsets screenListPadding(BuildContext context) {
  return EdgeInsets.fromLTRB(
    20,
    8,
    20,
    24 + MediaQuery.viewPaddingOf(context).bottom,
  );
}

Widget centeredContent({required Widget child, double maxWidth = 860}) {
  return Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
