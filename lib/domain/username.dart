final _username = RegExp(r'^[a-z0-9_]{3,20}$');

/// The longest display name, in UTF-16 code units (Dart's `String.length`).
const displayNameMaxLength = 30;

/// The username to store for [input]: trimmed and lowercased
/// (`' Dan_M '` → `'dan_m'`), or null unless it's 3–20 of `a-z`, `0-9`, `_`.
String? parseUsername(String input) {
  final name = input.trim().toLowerCase();
  return _username.hasMatch(name) ? name : null;
}

/// The display name to store for [input]: trimmed, falling back to [username]
/// when blank, or null when longer than [displayNameMaxLength].
///
/// shortcut: an emoji counts as 2 of the 30 (UTF-16 units, never more than the
/// rules count). Count graphemes instead if people hit the limit with emoji.
String? parseDisplayName(String input, String username) {
  final name = input.trim();
  if (name.isEmpty) return username;
  return name.length <= displayNameMaxLength ? name : null;
}
