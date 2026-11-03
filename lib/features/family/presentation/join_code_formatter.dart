import 'package:flutter/services.dart';

const joinCodeLength = 6;

// Fixed by the backend: no I, O, 0 or 1.
const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

// Most phones in Kazakhstan type in the Russian layout, and these upper-case
// Cyrillic letters look identical to their Latin twins.
const _lookAlikes = {
  'А': 'A',
  'В': 'B',
  'С': 'C',
  'Е': 'E',
  'Н': 'H',
  'К': 'K',
  'М': 'M',
  'Р': 'P',
  'Т': 'T',
  'Х': 'X',
  'У': 'Y',
};

final _pastedCode = RegExp(
  '(?<![A-Z0-9])[A-HJ-NP-Z2-9]{$joinCodeLength}(?![A-Z0-9])',
);

String _normalize(String raw) {
  final upper = raw.toUpperCase();
  final buffer = StringBuffer();
  for (final rune in upper.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_lookAlikes[ch] ?? ch);
  }
  return buffer.toString();
}

/// Turns whatever the user types or pastes into a clean join code.
String cleanJoinCode(String raw, {required bool pasted}) {
  final text = _normalize(raw);
  if (pasted) {
    final matches = _pastedCode.allMatches(text);
    if (matches.isNotEmpty) return matches.last.group(0)!;
  }
  final kept = text.split('').where(_alphabet.contains).join();
  return kept.length > joinCodeLength
      ? kept.substring(0, joinCodeLength)
      : kept;
}

class JoinCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final pasted = newValue.text.length > oldValue.text.length + 1;
    final text = cleanJoinCode(newValue.text, pasted: pasted);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
