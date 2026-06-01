import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:html_unescape/html_unescape.dart';

final _unescape = HtmlUnescape();

//* Strip tags + decode entities to plain text (city/price/venue fields)
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

//* Nullable htmlToText (null when the result is empty)
String? htmlToTextOrNull(String? input) {
  if (input == null) return null;
  final cleaned = htmlToText(input);
  return cleaned.isEmpty ? null : cleaned;
}

//* Decode entities without stripping real tags, and turn newlines into <br>
String unescapeHtmlIfNeeded(String input) {
  if (input.isEmpty) return input;
  var out = input.contains('&') ? _unescape.convert(input) : input;
  //* Normalise literal "\n"/"\r" sequences (raw JSON dumps) to real newlines
  if (out.contains(r'\n') || out.contains(r'\r')) {
    out = out
        .replaceAll(r'\r\n', '\n')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\n');
  }
  if (out.contains('\n') || out.contains('\r')) {
    out = out
        .replaceAll('\r\n', '\n')
        .replaceAllMapped(
          RegExp(r'</(p|div|li|ul|ol|h[1-6])>\s*\n+'),
          (m) => m[0]!.replaceAll('\n', ''),
        )
        .replaceAll('\n', '<br>');
  }
  //* Trim trailing whitespace and stray <br>/<p></p>/&nbsp; artefacts
  final trailing = RegExp(
    r'(\s|<br\s*/?>|<p>\s*</p>|&nbsp;)+$',
    caseSensitive: false,
  );
  return out.replaceAll(trailing, '');
}

//* Convert limited inline HTML (b/i/u/br/p/li + entities) to a TextSpan
TextSpan htmlToSpan(String input, {TextStyle? baseStyle}) {
  if (input.isEmpty) return TextSpan(text: '', style: baseStyle);
  if (!input.contains('<') && !input.contains('&')) {
    return TextSpan(text: input, style: baseStyle);
  }
  //* Decode entity-encoded tags first so the parser sees real tags
  final src = unescapeHtmlIfNeeded(input);
  final fragment = html_parser.parseFragment(src);
  return TextSpan(style: baseStyle, children: _nodesToSpans(fragment.nodes));
}

//* Recursively map DOM nodes to styled InlineSpans
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
