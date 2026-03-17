import 'package:event_radar/utils/language.dart';
import 'package:flutter/material.dart';
import 'package:event_radar/models/city_item.dart';
import 'package:event_radar/screens/events_screen.dart';
import 'package:event_radar/services/city_service.dart';
import 'package:event_radar/widgets/city_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CityItem? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final service = CityService.instance;
    await service.init();

    if (!mounted) return;
    setState(() {
      _selected = service.defaultCity;
      _loading = false;
    });

    service.resolveLocation(languageCode: deviceLanguageCode);
  }

  void _browse() {
    final city = _selected;
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
    setState(() => _selected = city);
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
              const Center(child: CircularProgressIndicator())
            else
              CityPicker(
                initialValue: _selected,
                onCitySelected: _onCitySelected,
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Find events'),
              onPressed: _selected != null ? _browse : null,
            ),
          ],
        ),
      ),
    );
  }
}
