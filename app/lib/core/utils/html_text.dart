import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:html_unescape/html_unescape.dart';

final _unescape = HtmlUnescape();

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

// Decodes HTML entities (`&lt;`, `&gt;`, `&amp;`, `&hellip;`, numeric `&#39;`,
// `&#x27;`, …) without touching real tags, so any escape level the publisher
// emits ends up as renderable HTML for flutter_html / htmlToSpan.
//
// Examples:
//   "<p>Hello</p>"              → "<p>Hello</p>"               (no change)
//   "&lt;p&gt;Sylvie&hellip;&lt;/p&gt;" → "<p>Sylvie…</p>"     (tags revealed)
//   "<p>It&apos;s &amp; cool</p>"      → "<p>It's & cool</p>"  (entities decoded)
//
// We use html_unescape rather than html_parser.parseFragment(...).text because
// the latter strips tags as a side-effect — fine for tag-encoded-as-entity
// payloads, wrong for real HTML that happens to carry a couple of entities.
String unescapeHtmlIfNeeded(String input) {
  if (input.isEmpty) return input;
  var out = input.contains('&') ? _unescape.convert(input) : input;
  // HTML collapses newlines to whitespace, so a description like
  //   "Sylvie brings…\nLondon's finest…"
  // would render as one paragraph. Convert each `\n` (and `\r\n`) to a <br>
  // before handing off, but skip newlines that come right after a closing
  // block tag (`</p>\n<p>…`) — those are source-side cosmetic whitespace and
  // adding an extra <br> there opens a visible double gap.
  // Some publishers dump the description as a raw JSON string without escape
  // processing, so the field carries the literal two-character sequence \n
  // (backslash + 'n'), not the newline byte 0x0A. Normalise those to real
  // newlines first so the rest of the pipeline handles both flavours.
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
  // Strip trailing whitespace AND the trailing-line-break artefacts sources
  // love to emit (stray `<br>`, empty `<p>`, `&nbsp;`) so the rendered block
  // doesn't end with a phantom blank line. Leading content is left untouched.
  final trailing = RegExp(
    r'(\s|<br\s*/?>|<p>\s*</p>|&nbsp;)+$',
    caseSensitive: false,
  );
  return out.replaceAll(trailing, '');
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
  // Handle the entity-encoded-tags case before parsing — otherwise the parser
  // sees the decoded `<b>` as text, not a tag.
  final src = unescapeHtmlIfNeeded(input);
  final fragment = html_parser.parseFragment(src);
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
