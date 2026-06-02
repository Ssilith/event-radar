import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

//* The three bottom-nav tabs
enum Page {
  discover,
  saved,
  map;

  //* Tab shown on launch
  static Page get initialPage => Page.discover;
}

//* Per-tab icon
const Map<Page, IconData> _pageIcons = {
  Page.discover: MdiIcons.compass,
  Page.saved: MdiIcons.heart,
  Page.map: MdiIcons.mapMarker,
};

extension PageExt on Page {
  //* This tab's icon
  IconData get iconData => _pageIcons[this]!;

  //* Localized tab name
  String label(AppL10n l) => switch (this) {
    Page.discover => l.pageDiscover,
    Page.saved => l.pageSaved,
    Page.map => l.pageMap,
  };
}
