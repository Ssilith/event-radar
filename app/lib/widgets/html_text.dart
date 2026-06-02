import 'package:event_radar/core/utils/html_parsing.dart';
import 'package:flutter/material.dart';

//* Renders limited inline HTML (b/i/u/br/p/li) as a Text.rich span
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
      htmlToSpan(data, baseStyle: style),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
