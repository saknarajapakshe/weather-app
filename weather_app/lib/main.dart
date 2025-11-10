import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WeatherDashboard(),
    );
  }
}

class WeatherDashboard extends StatefulWidget {
  const WeatherDashboard({super.key});

  @override
  State<WeatherDashboard> createState() => _WeatherDashboardState();
}

class _WeatherDashboardState extends State<WeatherDashboard> {
  final TextEditingController _indexController = TextEditingController(text: '194174');
  
  double? _latitude;
  double? _longitude;
  String? _requestUrl;
  String? _temperature;
  String? _windSpeed;
  String? _weatherCode;
  String? _lastUpdated;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCached = false;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  // Derive coordinates from student index
  void _calculateCoordinates(String index) {
    if (index.length < 4) {
      setState(() {
        _errorMessage = 'Index must be at least 4 digits';
        _latitude = null;
        _longitude = null;
      });
      return;
    }

    try {
      int firstTwo = int.parse(index.substring(0, 2));
      int nextTwo = int.parse(index.substring(2, 4));
      
      setState(() {
        _latitude = 5 + (firstTwo / 10.0);
        _longitude = 79 + (nextTwo / 10.0);
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid index format';
        _latitude = null;
        _longitude = null;
      });
    }
  }

  // Load cached weather data
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('weather_data');
      
      if (cachedData != null) {
        final data = json.decode(cachedData);
        setState(() {
          _temperature = data['temperature'];
          _windSpeed = data['windSpeed'];
          _weatherCode = data['weatherCode'];
          _lastUpdated = data['lastUpdated'];
          _latitude = data['latitude'];
          _longitude = data['longitude'];
          _requestUrl = data['requestUrl'];
          _isCached = true;
        });
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Save weather data to cache
  Future<void> _saveCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'temperature': _temperature,
        'windSpeed': _windSpeed,
        'weatherCode': _weatherCode,
        'lastUpdated': _lastUpdated,
        'latitude': _latitude,
        'longitude': _longitude,
        'requestUrl': _requestUrl,
      };
      await prefs.setString('weather_data', json.encode(data));
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Fetch weather from API
  Future<void> _fetchWeather() async {
    final index = _indexController.text.trim();
    
    if (index.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your student index';
      });
      return;
    }

    _calculateCoordinates(index);
    
    if (_latitude == null || _longitude == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isCached = false;
    });

    final url = 'https://api.open-meteo.com/v1/forecast?latitude=${_latitude!.toStringAsFixed(1)}&longitude=${_longitude!.toStringAsFixed(1)}&current_weather=true';
    
    setState(() {
      _requestUrl = url;
    });

    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final currentWeather = data['current_weather'];
        
        final now = DateTime.now();
        final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
        
        setState(() {
          _temperature = currentWeather['temperature'].toString();
          _windSpeed = currentWeather['windspeed'].toString();
          _weatherCode = currentWeather['weathercode'].toString();
          _lastUpdated = formatter.format(now);
          _isLoading = false;
          _errorMessage = null;
        });

        // Save to cache
        await _saveCachedData();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch weather (Status: ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error: ${e.toString()}';
      });
      
      // Try to load cached data on error
      await _loadCachedData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Personalized Weather Dashboard'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Student Index Input
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Index',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _indexController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter your student index (e.g., 194174)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Fetch Weather Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _fetchWeather,
              icon: const Icon(Icons.cloud_download),
              label: const Text('Fetch Weather'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 16),

            // Loading Indicator
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              ),

            // Error Message
            if (_errorMessage != null && !_isLoading)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Coordinates Display
            if (_latitude != null && _longitude != null)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Computed Coordinates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Latitude: ${_latitude!.toStringAsFixed(2)}°',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Longitude: ${_longitude!.toStringAsFixed(2)}°',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Weather Information
            if (_temperature != null && !_isLoading)
              Card(
                elevation: 2,
                color: _isCached ? Colors.orange[50] : Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Current Weather',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_isCached)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'CACHED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildWeatherRow(
                        Icons.thermostat,
                        'Temperature',
                        '$_temperature °C',
                      ),
                      const SizedBox(height: 8),
                      _buildWeatherRow(
                        Icons.air,
                        'Wind Speed',
                        '$_windSpeed km/h',
                      ),
                      const SizedBox(height: 8),
                      _buildWeatherRow(
                        Icons.wb_sunny,
                        'Weather Code',
                        _weatherCode!,
                      ),
                      const SizedBox(height: 8),
                      _buildWeatherRow(
                        Icons.access_time,
                        'Last Updated',
                        _lastUpdated!,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Request URL Display
            if (_requestUrl != null)
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Request URL:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _requestUrl!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _indexController.dispose();
    super.dispose();
  }
}
