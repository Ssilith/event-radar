import 'package:flutter/gestures.dart';
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
  //* Trim trailing whitespace and stray <br>/<p></p>/&nbsp; artefact
  final trailing = RegExp(
    r'(\s|<br\s*/?>|<p>\s*</p>|&nbsp;)+$',
    caseSensitive: false,
  );
  return out.replaceAll(trailing, '');
}

//* Bare URLs (http/https or www.) to linkify in plain text. Stops at
//* whitespace and a few wrapping chars; trailing punctuation is trimmed below.
final _urlPattern = RegExp(
  r'(?:https?://|www\.)[^\s<>()\[\]]+',
  caseSensitive: false,
);

//* Trailing chars that shouldn't be swallowed into a detected URL
const _urlTrailingPunct = '.,;:!?\'")]}>';

//* Carries the link-rendering config through the recursive walk
class _LinkContext {
  final Color? linkColor;
  final void Function(String url)? onTapLink;
  final List<TapGestureRecognizer>? recognizers;
  const _LinkContext({this.linkColor, this.onTapLink, this.recognizers});
  bool get enabled => onTapLink != null;
}

//* Add https:// to scheme-less www. URLs; leave everything else untouched
String _normalizeUrl(String url) {
  final lower = url.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) return url;
  if (lower.startsWith('www.')) return 'https://$url';
  return url;
}

//* A tappable, underlined link span; the recognizer is parked in [ctx] so the
//* owning widget can dispose it.
TextSpan _linkSpan(String label, String url, _LinkContext ctx) {
  final recognizer = TapGestureRecognizer()..onTap = () => ctx.onTapLink!(url);
  ctx.recognizers?.add(recognizer);
  return TextSpan(
    text: label,
    style: TextStyle(
      color: ctx.linkColor,
      decoration: TextDecoration.underline,
      decorationColor: ctx.linkColor,
    ),
    recognizer: recognizer,
  );
}

//* Split a plain-text run into alternating text and link spans
List<InlineSpan> _linkify(String text, _LinkContext ctx) {
  if (!ctx.enabled || text.isEmpty) return [TextSpan(text: text)];
  final spans = <InlineSpan>[];
  var last = 0;
  for (final m in _urlPattern.allMatches(text)) {
    var url = m.group(0)!;
    var end = m.end;
    //* Don't let a sentence's "." or a closing ")" become part of the link
    while (url.isNotEmpty && _urlTrailingPunct.contains(url[url.length - 1])) {
      url = url.substring(0, url.length - 1);
      end--;
    }
    if (url.isEmpty) continue;
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start)));
    }
    spans.add(_linkSpan(url, _normalizeUrl(url), ctx));
    last = end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return spans.isEmpty ? [TextSpan(text: text)] : spans;
}

//* Convert limited inline HTML (b/i/u/br/p/li/a + entities) to a TextSpan
TextSpan htmlToSpan(
  String input, {
  TextStyle? baseStyle,
  Color? linkColor,
  void Function(String url)? onTapLink,
  List<TapGestureRecognizer>? recognizers,
}) {
  final ctx = _LinkContext(
    linkColor: linkColor,
    onTapLink: onTapLink,
    recognizers: recognizers,
  );
  if (input.isEmpty) return TextSpan(text: '', style: baseStyle);
  if (!input.contains('<') && !input.contains('&')) {
    //* No markup — but still linkify any bare URLs in the plain text
    return TextSpan(style: baseStyle, children: _linkify(input, ctx));
  }
  //* Decode entity-encoded tags first so the parser sees real tags
  final src = unescapeHtmlIfNeeded(input);
  final fragment = html_parser.parseFragment(src);
  return TextSpan(
    style: baseStyle,
    children: _nodesToSpans(fragment.nodes, ctx),
  );
}

//* Recursively map DOM nodes to styled InlineSpans
List<InlineSpan> _nodesToSpans(List<dom.Node> nodes, _LinkContext ctx) {
  final spans = <InlineSpan>[];
  for (final node in nodes) {
    if (node is dom.Text) {
      if (node.text.isNotEmpty) spans.addAll(_linkify(node.text, ctx));
      continue;
    }
    if (node is! dom.Element) continue;
    switch (node.localName?.toLowerCase()) {
      case 'br':
        spans.add(const TextSpan(text: '\n'));
        break;
      case 'p':
      case 'div':
        spans.addAll(_nodesToSpans(node.nodes, ctx));
        spans.add(const TextSpan(text: '\n\n'));
        break;
      case 'b':
      case 'strong':
        spans.add(
          TextSpan(
            style: const TextStyle(fontWeight: FontWeight.bold),
            children: _nodesToSpans(node.nodes, ctx),
          ),
        );
        break;
      case 'i':
      case 'em':
        spans.add(
          TextSpan(
            style: const TextStyle(fontStyle: FontStyle.italic),
            children: _nodesToSpans(node.nodes, ctx),
          ),
        );
        break;
      case 'u':
        spans.add(
          TextSpan(
            style: const TextStyle(decoration: TextDecoration.underline),
            children: _nodesToSpans(node.nodes, ctx),
          ),
        );
        break;
      case 'a':
        final href = node.attributes['href']?.trim();
        final label = node.text;
        if (ctx.enabled &&
            href != null &&
            href.isNotEmpty &&
            label.isNotEmpty) {
          spans.add(_linkSpan(label, _normalizeUrl(href), ctx));
        } else {
          spans.addAll(_nodesToSpans(node.nodes, ctx));
        }
        break;
      case 'li':
        spans.add(const TextSpan(text: '• '));
        spans.addAll(_nodesToSpans(node.nodes, ctx));
        spans.add(const TextSpan(text: '\n'));
        break;
      default:
        spans.addAll(_nodesToSpans(node.nodes, ctx));
    }
  }
  return spans;
}
