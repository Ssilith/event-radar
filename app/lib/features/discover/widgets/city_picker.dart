import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/theme/app_shadows.dart';
import 'package:event_radar/core/utils/language.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:event_radar/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:event_radar/core/models/city_item.dart';
import 'package:event_radar/core/services/city_service.dart';
import 'package:google_fonts/google_fonts.dart';

//* Modal bottom-sheet city chooser: location row, search, and results list
class CityPickerSheet extends StatefulWidget {
  final CityItem? initialValue;
  const CityPickerSheet._({this.initialValue});

  //* Open the chooser; calls onCitySelected with the picked city (if any)
  static Future<void> show(
    BuildContext context, {
    CityItem? initialValue,
    required ValueChanged<CityItem> onCitySelected,
  }) async {
    final city = await showModalBottomSheet<CityItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CityPickerSheet._(initialValue: initialValue),
    );
    if (city != null) onCitySelected(city);
  }

  @override
  State<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<CityPickerSheet> {
  final _service = CityService.instance;
  final _searchController = TextEditingController();
  Timer? _debounce;
  late Future<List<CityItem>> _future;
  bool _locating = false;

  String get _langCode => deviceLanguageCode;

  @override
  void initState() {
    super.initState();
    _future = _service.getItems('', languageCode: _langCode);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  //* Debounced search; an empty query falls back to the default list
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _future = _service.getItems('', languageCode: _langCode));
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(
        () => _future = _service.getItems(query, languageCode: _langCode),
      );
    });
  }

  void _select(CityItem city) {
    _service.markUsed(city);
    Navigator.of(context).pop(city);
  }

  //* Resolve the user's city from GPS, or prompt to enable location
  Future<void> _useLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    final ok = await _service.resolveLocation(
      languageCode: _langCode,
      force: true,
    );
    if (!mounted) return;
    setState(() => _locating = false);
    final city = _service.locationCity;
    if (ok && city != null) {
      _select(city);
    } else {
      final l = AppL10n.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.couldNotGetLocation)));
      AppSettings.openAppSettings(type: AppSettingsType.location);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final media = MediaQuery.of(context);
    return Padding(
      //* Lift the sheet above the keyboard when the search field is focused
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: AppShadows.overlay,
        ),
        child: SafeArea(
          top: false,
          //* Transparent Material gives the ListTiles a paint surface above the
          //* sheet's coloured Container (Flutter asserts otherwise)
          child: Material(
            type: MaterialType.transparency,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.fromLTRB(0, 12, 0, 10),
                      decoration: BoxDecoration(
                        color: AppColors.borderStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l.chooseCityTitle,
                        style: GoogleFonts.syne(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  _LocationRow(loading: _locating, onTap: _useLocation),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: l.searchCity,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: FutureBuilder<List<CityItem>>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Loading(),
                          );
                        }
                        final cities = snapshot.data ?? const <CityItem>[];
                        if (cities.isEmpty) {
                          final primary = Theme.of(context).colorScheme.primary;
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 56,
                                  color: primary.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l.noCitiesFound,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.syne(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: cities.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppColors.border,
                          ),
                          itemBuilder: (_, i) {
                            final city = cities[i];
                            return _CityTile(
                              item: city,
                              isSelected: city == widget.initialValue,
                              isCurrent: city == _service.locationCity,
                              onTap: () => _select(city),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//* "Use my location" tappable row with a loading state
class _LocationRow extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _LocationRow({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
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
                  ? const Loading(size: 18)
                  : Icon(Icons.my_location, size: 18, color: primary),
            ),
            const SizedBox(width: 12),
            Text(
              loading ? l.gettingLocation : l.useMyLocation,
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//* One city row in the dropdown popup with its source badge
class _CityTile extends StatelessWidget {
  final CityItem item;
  final bool isSelected;
  final bool isCurrent;
  final VoidCallback? onTap;

  const _CityTile({
    required this.item,
    required this.isSelected,
    required this.isCurrent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final svc = CityService.instance;
    final l = AppL10n.of(context);
    //* One badge per row (recent > current > nearby > fetched)
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
      onTap: onTap,
    );
  }
}
