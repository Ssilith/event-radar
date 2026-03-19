import 'package:event_radar/screens/events_screen.dart';
import 'package:event_radar/services/city_service.dart';
import 'package:event_radar/utils/language.dart';
import 'package:event_radar/widgets/city_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:event_radar/models/city_item.dart';

class DiscoverScreen extends StatefulWidget {
  final CityItem? selectedCity;
  final ValueChanged<CityItem> onCitySelected;

  const DiscoverScreen({
    super.key,
    required this.selectedCity,
    required this.onCitySelected,
  });

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await CityService.instance.init();
    if (!mounted) return;
    setState(() => _loading = false);

    CityService.instance.resolveLocation(languageCode: deviceLanguageCode);
  }

  void _browse() {
    final city = widget.selectedCity;
    if (city == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EventsScreen(city: city.name, countryCode: city.countryCode),
      ),
    );
  }

  void _onCitySelected(CityItem city) {
    CityService.instance.markUsed(city);
    widget.onCitySelected(city);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Event Radar'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.event, size: 64, color: Colors.deepPurple),
            const SizedBox(height: 24),
            const Text(
              'Discover events near you',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            if (_loading)
              Center(
                child: SpinKitRipple(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            else
              CityPicker(
                initialValue: widget.selectedCity,
                onCitySelected: _onCitySelected,
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Find events'),
              onPressed: widget.selectedCity != null ? _browse : null,
            ),
          ],
        ),
      ),
    );
  }
}
