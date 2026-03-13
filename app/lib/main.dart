import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const _triggerCityName = 'Berlin';

  String _cityStatus = '';
  bool _loading = false;

  Future<void> _triggerCity() async {
    setState(() {
      _loading = true;
      _cityStatus = 'Contacting server…';
    });

    try {
      final response = await http.post(
        Uri.parse(AppConfig.triggerUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'city': _triggerCityName}),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;

        setState(() {
          _cityStatus = switch (body['status']) {
            'fresh' =>
              '✓ $_triggerCityName data is already fresh (${body['count']} events)',
            'triggered' => '⏳ Scrape started! Check back in ~2 minutes.',
            _ => 'Unknown status: ${body['status']}',
          };
        });
      } else {
        setState(() => _cityStatus = '✗ Error ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _cityStatus = '✗ Request failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Trigger event scrape',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _loading ? null : _triggerCity,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.location_city),
              label: Text(
                _loading ? 'Working…' : 'Fetch $_triggerCityName events',
              ),
            ),

            if (_cityStatus.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _cityStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _cityStatus.startsWith('✗')
                        ? Colors.red
                        : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
