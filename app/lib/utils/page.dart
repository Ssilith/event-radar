import 'package:extension_utils/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

enum Page {
  discover,
  saved,
  map;

  static Page get initialPage => Page.discover;
}

const Map<Page, IconData> _pageIcons = {
  Page.discover: MdiIcons.compass,
  Page.saved: MdiIcons.heart,
  Page.map: MdiIcons.mapMarker,
};

extension PageExt on Page {
  String get value => name.capitalize();
  IconData get iconData => _pageIcons[this]!;
}
