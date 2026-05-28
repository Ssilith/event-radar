import 'package:event_radar/core/utils/html_text.dart' as html_text;
import 'package:flutter/material.dart';

// Drop-in for `Text` that renders inline HTML formatting (<b>/<strong>,
// <i>/<em>, <u>, <br>, <p>, <li>) and decodes entities (&amp;, &nbsp;, &#39;).
// Falls back to a regular Text fast-path when the source has no markup.
//
// Use this when a field may carry markup AND needs the constraint props that
// `flutter_html.Html` doesn't support: maxLines + overflow ellipsis in lists,
// cards, and headers.
class HtmlText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const HtmlText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      html_text.htmlToSpan(data, baseStyle: style),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
