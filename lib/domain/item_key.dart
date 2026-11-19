const _accented = 'áàâäãåéèêëíìîïóòôöõúùûüñçýÿ';
const _plain = 'aaaaaaeeeeiiiiooooouuuuncyy';
final _combiningMarks = RegExp('[\u0300-\u036f]');
final _whitespace = RegExp(r'\s+');

/// The key that matches the same item across inventory, grocery list and
/// recipes: trimmed, lowercased, inner whitespace collapsed, Latin accents
/// stripped (`'CAFÉ  con  Leche'` → `'cafe con leche'`).
///
/// A blank name gives `''`, which callers must reject.
String itemKey(String name) {
  final lower = name
      .trim()
      .toLowerCase()
      .replaceAll(_whitespace, ' ')
      .replaceAll(_combiningMarks, '');
  return lower.split('').map((c) {
    final i = _accented.indexOf(c);
    return i < 0 ? c : _plain[i];
  }).join();
}
