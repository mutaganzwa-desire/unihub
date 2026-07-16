import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  /// "2h ago", "3d ago", "Posted 12 Mar" style relative labels.
  String get relative {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM yyyy').format(this);
  }

  String get shortDate => DateFormat('d MMM yyyy').format(this);
  String get time => DateFormat('HH:mm').format(this);

  bool get isPast => isBefore(DateTime.now());
}
