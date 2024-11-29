import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'forecast.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String apiKey = '4922a35d43db0e6e1568118a5c19f859';
  String cityName = 'Fetching...';
  String weatherDescription = 'Loading...';
  double temperature = 0.0;
  double feels_like = 0.0;
  double min_temp = 0.0;
  double max_temp = 0.0;
  String sunrise = '';
  String sunset = '';
  int humidity = 0;
  double windSpeed = 0.0;
  bool isFahrenheit = false;
  bool isLoading = false;
  String errorMessage = '';
  final TextEditingController _cityController = TextEditingController();
  List<String> favoriteCities = [];

  double _convertToFahrenheit(double celsius) {
    return (celsius * 9 / 5) + 32;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadFavorites();
    fetchWeatherData();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isFahrenheit = prefs.getBool('isFahrenheit') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isFahrenheit', isFahrenheit);
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteCities = prefs.getStringList('favoriteCities') ?? [];
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favoriteCities', favoriteCities);
  }

  Future<void> fetchWeatherData({String? city}) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      String apiUrl;

      if (city != null && city.isNotEmpty) {
        apiUrl =
            'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$apiKey';
      } else {
        Position position = await _determinePosition();
        apiUrl =
            'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$apiKey';
      }

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          cityName = data['name'];
          weatherDescription = data['weather'][0]['description'];
          double tempCelsius = (data['main']['temp'] as num).toDouble();
          double feelsLikeCelsius =
              (data['main']['feels_like'] as num).toDouble();

          temperature =
              isFahrenheit ? _convertToFahrenheit(tempCelsius) : tempCelsius;
          feels_like = isFahrenheit
              ? _convertToFahrenheit(feelsLikeCelsius)
              : feelsLikeCelsius;
          min_temp = (data['main']['temp_min'] as num).toDouble();
          max_temp = (data['main']['temp_max'] as num).toDouble();
          sunrise = _formatTime(data['sys']['sunrise']);
          sunset = _formatTime(data['sys']['sunset']);
          humidity = data['main']['humidity'];
          windSpeed = (data['wind']['speed'] as num).toDouble();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch weather data');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  String _formatTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _addToFavorites() {
    if (!favoriteCities.contains(cityName)) {
      setState(() {
        favoriteCities.add(cityName);
        _saveFavorites();
      });
    }
  }

  void _fetchWeatherForFavorite(String city) {
    Navigator.pop(context);
    fetchWeatherData(city: city);
  }

  void _toggleFahrenheit() async {
    setState(() {
      isFahrenheit = !isFahrenheit;
    });
    _saveSettings();
    fetchWeatherData(city: cityName);
  }
  void _navigateToForecast() async {
  Navigator.push(
    context,
      MaterialPageRoute(builder: (context) => const ForecastScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('मौसम App'),
        actions: [
          IconButton(
            icon: Icon(isFahrenheit ? Icons.thermostat : Icons.thermostat_auto),
            onPressed: _toggleFahrenheit,
            tooltip: isFahrenheit
                ? 'Switch to Celsius'
                : 'Switch to Fahrenheit',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Favorite Cities \nCreated by Suraj Ranjan\n22WJ1A05W2\nCSE-5, GNITC',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            ...favoriteCities.map((city) {
              return ListTile(
                title: Text(city),
                onTap: () => _fetchWeatherForFavorite(city),
              );
            }).toList(),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : SafeArea(
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _cityController,
                              decoration: InputDecoration(
                                hintText: 'Enter city name',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  fetchWeatherData(city: value.trim());
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            cityName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            weatherDescription.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _addToFavorites,
                            child: const Text('Save to Favorites'),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.1),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${temperature.toStringAsFixed(1)}°${isFahrenheit ? 'F' : 'C'}',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Feels like ${feels_like.toStringAsFixed(1)}°${isFahrenheit ? 'F' : 'C'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                WeatherDetail(
                                  label: 'Min Temp',
                                  value:
                                      '${min_temp.toStringAsFixed(1)}°${isFahrenheit ? 'F' : 'C'}',
                                  icon: Icons.thermostat,
                                ),
                                WeatherDetail(
                                  label: 'Max Temp',
                                  value:
                                      '${max_temp.toStringAsFixed(1)}°${isFahrenheit ? 'F' : 'C'}',
                                  icon: Icons.thermostat_auto,
                                ),
                                WeatherDetail(
                                  label: 'Humidity',
                                  value: '$humidity%',
                                  icon: Icons.water_drop,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                WeatherDetail(
                                  label: 'Wind Speed',
                                  value: '${windSpeed.toStringAsFixed(1)} km/h',
                                  icon: Icons.wind_power,
                                ),
                                WeatherDetail(
                                  label: 'Sunrise',
                                  value: sunrise,
                                  icon: Icons.wb_sunny,
                                ),
                                WeatherDetail(
                                  label: 'Sunset',
                                  value: sunset,
                                  icon: Icons.nights_stay,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 30,
                        left: 30,
                        child:
                      ElevatedButton(
                        onPressed: _navigateToForecast,
                        child: const Text('View Forecast'),
                      ),
                      ),
                      Positioned(
                        bottom: 30,
                        right: 30,
                        child: FloatingActionButton(
                          onPressed: fetchWeatherData,
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.refresh),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class WeatherDetail extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const WeatherDetail({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.black, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
      ],
    );
  }
}
