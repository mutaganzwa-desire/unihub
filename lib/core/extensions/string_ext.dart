extension StringX on String {
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get initials {
    final parts = trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  /// Prefix list used for Firestore "starts-with" search.
  List<String> get searchTokens {
    final lower = toLowerCase().trim();
    final tokens = <String>{};
    for (final word in lower.split(RegExp(r'\s+'))) {
      for (var i = 1; i <= word.length && i <= 15; i++) {
        tokens.add(word.substring(0, i));
      }
    }
    return tokens.toList();
  }
}
