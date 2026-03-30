import 'package:event_radar/screens/discover_screen.dart';
import 'package:event_radar/screens/map_screen.dart';
import 'package:event_radar/services/city_service.dart';
import 'package:event_radar/widgets/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:event_radar/models/city_item.dart';
import 'package:motion_tab_bar_v2/motion-tab-controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  MotionTabBarController? _motionTabBarController;

  CityItem? _selectedCity;

  @override
  void initState() {
    super.initState();
    _motionTabBarController = MotionTabBarController(length: 3, vsync: this);
    _loadDefaultCity();
  }

  @override
  void dispose() {
    super.dispose();
    _motionTabBarController?.dispose();
  }

  Future<void> _loadDefaultCity() async {
    await CityService.instance.init();
    if (!mounted) return;
    setState(() => _selectedCity = CityService.instance.defaultCity);
  }

  void _onCitySelected(CityItem city) {
    setState(() => _selectedCity = city);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: TabBarView(
        controller: _motionTabBarController,
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
        controller: _motionTabBarController,
        onTap: (index) =>
            setState(() => _motionTabBarController?.index = index),
      ),
    );
  }
}
