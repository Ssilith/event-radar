import 'package:event_radar/core/utils/html_parsing.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

//* Renders limited inline HTML (b/i/u/br/p/li/a) as a Text.rich span
class HtmlText extends StatefulWidget {
  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final void Function(String url)? onTapLink;
  final Color? linkColor;

  const HtmlText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.onTapLink,
    this.linkColor,
  });

  @override
  State<HtmlText> createState() => _HtmlTextState();
}

class _HtmlTextState extends State<HtmlText> {
  //* Tap recognizers created per build; owned here so they can be disposed
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //* Drop the previous frame's recognizers before rebuilding the span
    _disposeRecognizers();
    final span = htmlToSpan(
      widget.data,
      baseStyle: widget.style,
      linkColor: widget.linkColor,
      onTapLink: widget.onTapLink,
      recognizers: widget.onTapLink == null ? null : _recognizers,
    );
    return Text.rich(
      span,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
    );
  }
}
