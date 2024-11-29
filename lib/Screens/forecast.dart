import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({Key? key}) : super(key: key);

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  String apiKey = '4922a35d43db0e6e1568118a5c19f859';
  Map<String, List<dynamic>> groupedForecasts = {};
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchForecastData();
  }

  Future<void> fetchForecastData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      String apiUrl =
          'https://api.openweathermap.org/data/2.5/forecast?q=Imphal&units=metric&appid=$apiKey';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> forecasts = data['list'];

        // Group forecasts by date
        Map<String, List<dynamic>> grouped = {};
        for (var item in forecasts) {
          String date = item['dt_txt'].split(' ')[0]; // Extract date
          if (!grouped.containsKey(date)) {
            grouped[date] = [];
          }
          grouped[date]?.add(item);
        }

        setState(() {
          groupedForecasts = grouped;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch forecast data');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('5-Day Forecast')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : ListView.builder(
                  itemCount: groupedForecasts.keys.length,
                  itemBuilder: (context, index) {
                    String date = groupedForecasts.keys.elementAt(index);
                    List<dynamic> forecasts = groupedForecasts[date] ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            date, // Display the date as a header
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 150, // Set a fixed height for the horizontal list
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: forecasts.length,
                            itemBuilder: (context, i) {
                              final item = forecasts[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 5),
                                child: Container(
                                  width: 200, // Fixed width for each card
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item['dt_txt'].split(' ')[1], // Time
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Temp: ${item['main']['temp']}°C',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        'Feels Like: ${item['main']['feels_like']}°C',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Weather: ${item['weather'][0]['description']}',
                                        style: const TextStyle(fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
