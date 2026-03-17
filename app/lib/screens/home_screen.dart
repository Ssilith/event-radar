import 'package:event_radar/screens/events_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Event Radar'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event, size: 64, color: Colors.deepPurple),
            const SizedBox(height: 24),
            const Text('Pick a city to see upcoming events'),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.location_city),
              label: const Text('Browse Wrocław events'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const EventsScreen(city: 'Wrocław', countryCode: 'PL'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
