import 'dart:convert';

extension StringExtension on String {
  String decodeUnicodeEscapes() {
    if (!contains(r'\u') && !contains(r'\x')) return this;

    try {
      return jsonDecode('"$this"');
    } catch (e) {
      return this;
    }
  }
}