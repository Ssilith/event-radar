import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

// ── Plain-text helpers ─────────────────────────────────────────────────────
// Used at parse time for fields where rich formatting doesn't fit (city,
// price, venue). Strips tags AND decodes entities in one pass via the html
// package's parser.

String htmlToText(String input) {
  if (input.isEmpty) return input;
  if (!input.contains('<') && !input.contains('&')) return input;
  final fragment = html_parser.parseFragment(input);
  final decoded = fragment.text ?? '';
  return decoded
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\s*\n\s*'), '\n')
      .trim();
}

String? htmlToTextOrNull(String? input) {
  if (input == null) return null;
  final cleaned = htmlToText(input);
  return cleaned.isEmpty ? null : cleaned;
}

// ── Inline rich-text helper ────────────────────────────────────────────────
// Returns a TextSpan that Text.rich can render. Preserves <b>/<strong>,
// <i>/<em>, <u>, <br>, <p>, <li>, and decodes entities. Unknown tags pass
// their text through unstyled. Used by the HtmlText widget — see widgets/
// html_text.dart. We map the parsed DOM ourselves (instead of pulling in a
// flutter-specific HTML-to-span package) because the popular ones either
// build block widgets (flutter_html) or reference deprecated Material APIs
// (simple_html_css references TextTheme.headline5).
TextSpan htmlToSpan(String input, {TextStyle? baseStyle}) {
  if (input.isEmpty) return TextSpan(text: '', style: baseStyle);
  if (!input.contains('<') && !input.contains('&')) {
    return TextSpan(text: input, style: baseStyle);
  }
  final fragment = html_parser.parseFragment(input);
  return TextSpan(style: baseStyle, children: _nodesToSpans(fragment.nodes));
}

List<InlineSpan> _nodesToSpans(List<dom.Node> nodes) {
  final spans = <InlineSpan>[];
  for (final node in nodes) {
    if (node is dom.Text) {
      if (node.text.isNotEmpty) spans.add(TextSpan(text: node.text));
      continue;
    }
    if (node is! dom.Element) continue;
    switch (node.localName?.toLowerCase()) {
      case 'br':
        spans.add(const TextSpan(text: '\n'));
        break;
      case 'p':
      case 'div':
        spans.addAll(_nodesToSpans(node.nodes));
        spans.add(const TextSpan(text: '\n\n'));
        break;
      case 'b':
      case 'strong':
        spans.add(TextSpan(
          style: const TextStyle(fontWeight: FontWeight.bold),
          children: _nodesToSpans(node.nodes),
        ));
        break;
      case 'i':
      case 'em':
        spans.add(TextSpan(
          style: const TextStyle(fontStyle: FontStyle.italic),
          children: _nodesToSpans(node.nodes),
        ));
        break;
      case 'u':
        spans.add(TextSpan(
          style: const TextStyle(decoration: TextDecoration.underline),
          children: _nodesToSpans(node.nodes),
        ));
        break;
      case 'li':
        spans.add(const TextSpan(text: '• '));
        spans.addAll(_nodesToSpans(node.nodes));
        spans.add(const TextSpan(text: '\n'));
        break;
      default:
        spans.addAll(_nodesToSpans(node.nodes));
    }
  }
  return spans;
}
