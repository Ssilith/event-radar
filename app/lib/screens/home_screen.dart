import 'package:event_radar/screens/discover_screen.dart';
import 'package:event_radar/screens/map_screen.dart';
import 'package:event_radar/services/city_service.dart';
import 'package:event_radar/widgets/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:event_radar/models/city_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  CityItem? _selectedCity;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadDefaultCity();
  }

  Future<void> _loadDefaultCity() async {
    await CityService.instance.init();
    if (!mounted) return;
    setState(() {
      _selectedCity = CityService.instance.defaultCity;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCitySelected(CityItem city) {
    setState(() => _selectedCity = city);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          DiscoverScreen(
            selectedCity: _selectedCity,
            onCitySelected: _onCitySelected,
          ),
          const Placeholder(),
          MapScreen(city: _selectedCity),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onTap: (idx) => setState(() {
          _selectedIndex = idx;
          _pageController.jumpToPage(idx);
        }),
      ),
    );
  }
}
