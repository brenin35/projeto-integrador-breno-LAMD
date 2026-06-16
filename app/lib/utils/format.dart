String _two(int n) => n.toString().padLeft(2, '0');

String formatDateTime(DateTime dt) {
  final l = dt.toLocal();
  return '${_two(l.day)}/${_two(l.month)}/${l.year} ${_two(l.hour)}:${_two(l.minute)}';
}

/// Apenas a data: 15/06/2026.
String formatDate(DateTime dt) {
  final l = dt.toLocal();
  return '${_two(l.day)}/${_two(l.month)}/${l.year}';
}

/// Apenas o horário: 14:30.
String formatTime(DateTime dt) {
  final l = dt.toLocal();
  return '${_two(l.hour)}:${_two(l.minute)}';
}
