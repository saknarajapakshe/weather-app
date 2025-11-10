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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5DB0E6),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF87CEEB),
              const Color(0xFFB0D9F5),
              const Color(0xFFE6F3FF),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated clouds in background
            const AnimatedClouds(),
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Custom app bar
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.wb_sunny,
                            color: Color(0xFFFFB347),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Weather Dashboard',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Student Index Input
                          _buildGlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Student Index',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _indexController,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    hintText: 'Enter your student index (e.g., 194174)',
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                    prefixIcon: const Icon(Icons.person, color: Color(0xFF5DB0E6)),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),

                          // Fetch Weather Button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF5DB0E6),
                                  Color(0xFF4A9AD4),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF5DB0E6).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _fetchWeather,
                              icon: const Icon(Icons.cloud_download, color: Colors.white),
                              label: const Text(
                                'Fetch Weather',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Loading Indicator
                          if (_isLoading)
                            _buildGlassCard(
                              child: const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Column(
                                    children: [
                                      CircularProgressIndicator(
                                        color: Color(0xFF5DB0E6),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Fetching weather data...',
                                        style: TextStyle(
                                          color: Color(0xFF2C3E50),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Error Message
                          if (_errorMessage != null && !_isLoading)
                            _buildGlassCard(
                              color: Colors.red[50]!.withOpacity(0.9),
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

                          // Coordinates Display
                          if (_latitude != null && _longitude != null)
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Computed Coordinates',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF5DB0E6).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.location_on,
                                          size: 20,
                                          color: Color(0xFF5DB0E6),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Latitude: ${_latitude!.toStringAsFixed(2)}°',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF5DB0E6).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.location_on,
                                          size: 20,
                                          color: Color(0xFF5DB0E6),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Longitude: ${_longitude!.toStringAsFixed(2)}°',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Weather Information
                          if (_temperature != null && !_isLoading)
                            _buildGlassCard(
                              color: _isCached
                                  ? Colors.orange[50]!.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.9),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Current Weather',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                      if (_isCached)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Colors.orange, Colors.deepOrange],
                                            ),
                                            borderRadius: BorderRadius.circular(20),
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
                                  const SizedBox(height: 16),
                                  _buildWeatherRow(
                                    Icons.thermostat,
                                    'Temperature',
                                    '$_temperature °C',
                                    const Color(0xFFFF6B6B),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildWeatherRow(
                                    Icons.air,
                                    'Wind Speed',
                                    '$_windSpeed km/h',
                                    const Color(0xFF4ECDC4),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildWeatherRow(
                                    Icons.wb_sunny,
                                    'Weather Code',
                                    _weatherCode!,
                                    const Color(0xFFFFB347),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildWeatherRow(
                                    Icons.access_time,
                                    'Last Updated',
                                    _lastUpdated!,
                                    const Color(0xFF95A5A6),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Request URL Display
                          if (_requestUrl != null)
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Request URL:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    _requestUrl!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildWeatherRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
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

// Animated Clouds Widget
class AnimatedClouds extends StatefulWidget {
  const AnimatedClouds({super.key});

  @override
  State<AnimatedClouds> createState() => _AnimatedCloudsState();
}

class _AnimatedCloudsState extends State<AnimatedClouds>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final int cloudCount = 5;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      cloudCount,
      (index) => AnimationController(
        duration: Duration(seconds: 20 + index * 5),
        vsync: this,
      )..repeat(),
    );

    _animations = _controllers
        .map((controller) => Tween<double>(begin: -0.3, end: 1.1).animate(
              CurvedAnimation(parent: controller, curve: Curves.linear),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: List.generate(cloudCount, (index) {
        final cloudSize = 80.0 + (index * 20);
        final topPosition = 50.0 + (index * 80);
        
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Positioned(
              left: _animations[index].value * size.width,
              top: topPosition,
              child: Opacity(
                opacity: 0.3 + (index * 0.1),
                child: CustomPaint(
                  size: Size(cloudSize, cloudSize * 0.6),
                  painter: CloudPainter(),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// Cloud Painter
class CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Main cloud body
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.6),
      size.width * 0.25,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.5),
      size.width * 0.3,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.6),
      size.width * 0.2,
      paint,
    );
    
    // Connect circles with oval
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.5,
        size.width * 0.6,
        size.height * 0.4,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
