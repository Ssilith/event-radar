import 'dart:async';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:event_radar/models/city_item.dart';
import 'package:event_radar/services/city_service.dart';

const _useLocationItem = CityItem('__location__', '');

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
  bool _locating = false;

  Future<List<CityItem>> _loadItems(String filter, _) async {
    _debounce?.cancel();

    if (filter.trim().isEmpty) {
      final known = await _service.getItems('');
      return [
        if (known.isNotEmpty) known.first,
        _useLocationItem,
        ...known.skip(1),
      ];
    }

    final completer = Completer<List<CityItem>>();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final results = await _service.getItems(filter);
      if (!completer.isCompleted) completer.complete(results);
    });
    return completer.future;
  }

  Future<void> _handleLocationTap() async {
    setState(() => _locating = true);
    final ok = await _service.resolveLocation();
    if (!mounted) return;
    setState(() => _locating = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not get location. Please allow access in settings.',
          ),
        ),
      );
    }
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
      itemAsString: (item) => item == _useLocationItem ? '' : item.slug,
      compareFn: (a, b) => a == b,
      selectedItem: widget.initialValue,

      popupProps: PopupProps.bottomSheet(
        showSearchBox: true,
        title: const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            'Choose City',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        searchFieldProps: const TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search any city...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
        itemBuilder: (context, item, isSelected, isDisabled) {
          if (item == _useLocationItem) {
            return _LocationRow(loading: _locating, onTap: _handleLocationTap);
          }
          return _CityTile(
            item: item,
            isSelected: isSelected,
            isCurrent: item == _service.locationCity,
          );
        },
        disabledItemFn: (item) => item == _useLocationItem,
        emptyBuilder: (_, _) => const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No cities found'),
        ),
        loadingBuilder: (_, _) => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),

      decoratorProps: const DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: 'City',
          hintText: 'Select a city…',
          prefixIcon: Icon(Icons.location_city),
          border: OutlineInputBorder(),
        ),
      ),

      onChanged: (city) {
        if (city != null && city != _useLocationItem) {
          widget.onCitySelected(city);
        }
      },
    );
  }
}

class _LocationRow extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _LocationRow({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
        ),
        child: Row(
          children: [
            loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.my_location,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            const SizedBox(width: 12),
            Text(
              loading ? 'Getting location…' : 'Use my current location',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
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
    return ListTile(
      leading: isCurrent
          ? const Icon(Icons.location_on, size: 18, color: Colors.blue)
          : const SizedBox(width: 18),
      title: Text(
        item.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.countryCode.isNotEmpty)
            Text(
              item.countryCode,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.check,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
      selected: isSelected,
    );
  }
}
