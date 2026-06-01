import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/theme/app_shadows.dart';
import 'package:event_radar/core/utils/language.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:event_radar/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:event_radar/core/models/city_item.dart';
import 'package:event_radar/core/services/city_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class CityPicker extends StatefulWidget {
  final CityItem? initialValue;
  final ValueChanged<CityItem> onCitySelected;
  const CityPicker({
    super.key,
    this.initialValue,
    required this.onCitySelected,
  });

  @override
  State<CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<CityPicker> {
  final _service = CityService.instance;
  Timer? _debounce;

  String get _langCode => deviceLanguageCode;

  Future<List<CityItem>> _loadItems(String filter, _) async {
    _debounce?.cancel();
    if (filter.trim().isEmpty) {
      return _service.getItems('', languageCode: _langCode);
    }
    final completer = Completer<List<CityItem>>();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await _service.getItems(filter, languageCode: _langCode);
      if (!completer.isCompleted) completer.complete(results);
    });
    return completer.future;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<CityItem>(
      items: _loadItems,
      itemAsString: (item) => item.name,
      compareFn: (a, b) => a == b,
      selectedItem: widget.initialValue,

      popupProps: PopupProps.bottomSheet(
        showSearchBox: true,
        title: _PopupHeader(
          langCode: _langCode,
          onCityResolved: (city) {
            _service.markUsed(city);
            widget.onCitySelected(city);
          },
        ),
        searchFieldProps: const TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search any city...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
        itemBuilder: (context, item, isSelected, isDisabled) => _CityTile(
          item: item,
          isSelected: isSelected,
          isCurrent: item == _service.locationCity,
        ),
        emptyBuilder: (_, _) => const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No cities found'),
        ),
        loadingBuilder: (_, _) =>
            const Padding(padding: EdgeInsets.all(24), child: Loading()),
      ),

      decoratorProps: const DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: 'City',
          hintText: 'Select a city…',
          prefixIcon: Icon(Icons.location_city),
          border: OutlineInputBorder(),
        ),
      ),

      onSelected: (city) {
        if (city == null) return;
        _service.markUsed(city);
        widget.onCitySelected(city);
      },
    );
  }
}

class _PopupHeader extends StatefulWidget {
  final String langCode;
  final ValueChanged<CityItem> onCityResolved;

  const _PopupHeader({required this.langCode, required this.onCityResolved});

  @override
  State<_PopupHeader> createState() => _PopupHeaderState();
}

class _PopupHeaderState extends State<_PopupHeader> {
  bool _loading = false;

  Future<void> _handleTap() async {
    if (_loading) return;
    setState(() => _loading = true);

    final ok = await CityService.instance.resolveLocation(
      languageCode: widget.langCode,
      force: true,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    final city = CityService.instance.locationCity;
    if (ok && city != null) {
      Navigator.of(context).pop();
      widget.onCityResolved(city);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not get location. Please allow access in settings.',
          ),
        ),
      );
      AppSettings.openAppSettings(type: AppSettingsType.location);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            'Choose City',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        _LocationRow(loading: _loading, onTap: _handleTap),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _LocationRow({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: loading ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppShadows.subtle,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: loading
                  ? SpinKitRipple(color: primary)
                  : Icon(Icons.my_location, size: 18, color: primary),
            ),
            const SizedBox(width: 12),
            Text(
              loading ? 'Getting location…' : 'Use my current location',
              style: GoogleFonts.syne(
                textStyle: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityTile extends StatelessWidget {
  final CityItem item;
  final bool isSelected;
  final bool isCurrent;

  const _CityTile({
    required this.item,
    required this.isSelected,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final svc = CityService.instance;
    final l = AppL10n.of(context);
    // Resolve a single badge per row (recent > current > nearby > fetched)
    // so users can tell at a glance why each candidate is here without
    // pushing extra rows of metadata into the dense list.
    final ({String label, IconData icon, Color color})? badge;
    if (svc.isRecent(item)) {
      badge = (label: l.cityBadgeRecent, icon: Icons.history_rounded, color: primary);
    } else if (isCurrent) {
      badge = (label: l.cityBadgeNearby, icon: Icons.my_location_rounded, color: primary);
    } else if (svc.isNearby(item)) {
      badge = (label: l.cityBadgeNearby, icon: Icons.near_me_rounded, color: primary);
    } else if (svc.isFetched(item)) {
      badge = (
        label: l.cityBadgeFetched,
        icon: Icons.cloud_done_rounded,
        color: AppColors.textMuted,
      );
    } else {
      badge = null;
    }

    return ListTile(
      leading: isCurrent
          ? Icon(Icons.location_on, size: 18, color: primary)
          : const SizedBox(width: 18),
      title: Text(
        item.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: badge == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badge.icon, size: 12, color: badge.color),
                  const SizedBox(width: 4),
                  Text(
                    badge.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badge.color,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.countryCode.isNotEmpty)
            Text(
              item.countryCode,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            Icon(Icons.check, size: 16, color: primary),
          ],
        ],
      ),
      selected: isSelected,
    );
  }
}
